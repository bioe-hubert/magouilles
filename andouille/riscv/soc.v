//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

//==============================================================
// andouille soc		(magouilles project)
//==============================================================

module soc (
	input		clk,
	inout	[1:0]	uart0_io,
	inout	[7:0]	gpio0_io,
	inout	[2:0]	spi0_io
	);


	//----------------------------------------------------------------------
	// Reset (countdown to de-assertion)
	//----------------------------------------------------------------------

	reg	[5:0]	reset_cnt = 0;
	wire		resetn = &reset_cnt;

	always @(posedge clka) begin
	  reset_cnt <= reset_cnt + !resetn;
	end

	//----------------------------------------------------------------------
	// clocks
	//----------------------------------------------------------------------

	wire		clka;
	wire		clkn;

	clocks clks(.ref_clk(clk),.cpu_clk(clka),.mem_clk(clkn));

	//----------------------------------------------------------------------
	// code and data memory access, and interrupts (signals & dispatch)
	//----------------------------------------------------------------------
	// signals
	wire	[`X1:0]	code_adrs;				// code read address,    from cpu
	reg	[`X1:0]	data_adrs;				// data r/w  address,    from cpu
	wire		data_rd;				// data read  signal,    from cpu
	wire		data_we;				// data write signal,    from cpu
	reg	[`X1:0]	data_wdata;				// data to write to mem, from cpu
	wire	[`WS:0]	data_wst;				// bytewise write stobe, from cpu
	wire	[`X1:0]	mem_rcode = mem_vdata[code_adrs[`AU:`AL]];// code read from mem,     to cpu
	wire	[`X1:0]	mem_rdata = mem_vdata[data_adrs[`AU:`AL]];// data read from mem/per, to cpu
	wire	[ 15:0]	mem_virq;				// mem/periph irq vector,  to cpu

	// dispatch
	reg	[`X1:0]	mem_vdata[0:15];			// vector of data from all mem/periph
	wire	[ 15:0]	code_cs   = 8'h01 << code_adrs[`AU:`AL];	// code chip-select (0-15)
	wire	[ 15:0]	data_cs   = 8'h01 << data_adrs[`AU:`AL];	// data chip-select (0-15)

	//----------------------------------------------------------------------
	// cpu
	//----------------------------------------------------------------------
	cpu cpu0
	(.clk(clka),.rstn(resetn),.F_insn_adrs(code_adrs),.E_LS_adrs(data_adrs),.E_out(data_wdata),
	 .M_mem_load(data_rd),.M_mem_store(data_we),.M_wstrb(data_wst),
	 .mem_rcode(mem_rcode),.mem_rdata(mem_rdata),.mem_virq(mem_virq));

	//----------------------------------------------------------------------
	// code RAM (cram), SPRAM			0x00000000 (64 KB)
	//----------------------------------------------------------------------
  `ifdef rv32
	spram
  `else
	bram4k
  `endif
	cram	(.clk(clkn),.rstn(resetn),.irq(mem_virq[4'h00]),.ccs(code_cs[4'h00]),
		 .dcs(data_cs[4'h00]),.drd(data_rd),.dwe(data_we),.dwst(data_wst),
		 .cadrs(code_adrs),.dadrs(data_adrs),.din(data_wdata),.dout(mem_vdata[4'h00]));

	//----------------------------------------------------------------------
	// data RAM (dram), SPRAM			0x10000000 (64 KB)
	//----------------------------------------------------------------------
  `ifdef rv32
	spram
  `else
	bram4k
  `endif
	dram 	(.clk(clkn),.rstn(resetn),.irq(mem_virq[4'h01]),.ccs(code_cs[4'h01]),
		 .dcs(data_cs[4'h01]),.drd(data_rd),.dwe(data_we),.dwst(data_wst),
		 .cadrs(code_adrs),.dadrs(data_adrs),.din(data_wdata),.dout(mem_vdata[4'h01]));

	//----------------------------------------------------------------------
	// extra RAM or dummy		base:		0x20000000
	//----------------------------------------------------------------------
  `ifdef rv32
	bram8k
	eram 	(.clk(clkn),.rstn(resetn),.irq(mem_virq[4'h02]),.ccs(code_cs[4'h02]),
		 .dcs(data_cs[4'h02]),.drd(data_rd),.dwe(data_we),.dwst(data_wst),
		 .cadrs(code_adrs),.dadrs(data_adrs),.din(data_wdata),.dout(mem_vdata[4'h02]));
  `else
	dummy dummy2  (.clk(clkn),.irq(mem_virq[4'h02]),.dout(mem_vdata[4'h02]));
  `endif

	//----------------------------------------------------------------------
	// LEDs and/or GPIO		base:		0x30000000
	//				data:		0x00
	//----------------------------------------------------------------------
	gpio gpio0
	(.clk(clkn),.rstn(resetn),.irq(mem_virq[4'h03]),.dcs(data_cs[4'h03]),
	 .drd(data_rd),.dwe(data_we),.dwst(data_wst),
	 .dadrs(data_adrs),.din(data_wdata),.dout(mem_vdata[4'h03]),.io(gpio0_io));

	//----------------------------------------------------------------------
	// UART				base:		0x40000000
	//				rhr/thr:	0x00
	//				status:		0x04
	//				div:		0x08
	//				config:		0x0c
	//----------------------------------------------------------------------
	uart uart0
	(.clk(clkn),.rstn(resetn),.irq(mem_virq[4'h04]),.dcs(data_cs[4'h04]),
	 .drd(data_rd),.dwe(data_we),.dwst(data_wst),
	 .dadrs(data_adrs),.din(data_wdata),.dout(mem_vdata[4'h04]),.io(uart0_io));

	//----------------------------------------------------------------------
	// SPI				base:		0x50000000
	//				thr/rhr:	0x00
	//				Status:		0x04	(bit0 = idle)
	//				Log 2 Divider:	0x08	(1=div2, 2=div4, 3=div8...)
	//----------------------------------------------------------------------
	spi spi0
	(.clk(clkn),.rstn(resetn),.irq(mem_virq[4'h05]),.dcs(data_cs[4'h05]),
	 .drd(data_rd),.dwe(data_we),.dwst(data_wst),
	 .dadrs(data_adrs),.din(data_wdata),.dout(mem_vdata[4'h05]),.io(spi0_io));

	//----------------------------------------------------------------------
	// dummies			base:		0x60000000-0xe0000000
	//----------------------------------------------------------------------
	dummy dummy6  (.clk(clkn),.irq(mem_virq[4'h06]),.dout(mem_vdata[4'h06]));
	dummy dummy7  (.clk(clkn),.irq(mem_virq[4'h07]),.dout(mem_vdata[4'h07]));
	dummy dummy8  (.clk(clkn),.irq(mem_virq[4'h08]),.dout(mem_vdata[4'h08]));
	dummy dummy9  (.clk(clkn),.irq(mem_virq[4'h09]),.dout(mem_vdata[4'h09]));
	dummy dummy10 (.clk(clkn),.irq(mem_virq[4'h0a]),.dout(mem_vdata[4'h0a]));
	dummy dummy11 (.clk(clkn),.irq(mem_virq[4'h0b]),.dout(mem_vdata[4'h0b]));
	dummy dummy12 (.clk(clkn),.irq(mem_virq[4'h0c]),.dout(mem_vdata[4'h0c]));
	dummy dummy13 (.clk(clkn),.irq(mem_virq[4'h0d]),.dout(mem_vdata[4'h0d]));
//	dummy dummy14 (.clk(clkn),.irq(mem_virq[4'h0e]),.dout(mem_vdata[4'h0e]));

	// Yosys or ABC bug? it seems that at least one instance of setting
	// mem_vdata[] to a value should occur outside of a module (otherwise
	// a great many cells are deleted during synthesis).
	assign	mem_virq[4'h0e] = 1'b 0;
	always @(posedge clkn) begin
	  mem_vdata[4'h0e] <= 0;
	end

	//----------------------------------------------------------------------
	// boot RAM (bram), Block RAM			0xf0000000 (2 KB)
	//----------------------------------------------------------------------
	bram
	bootram	(.clk(clkn),.rstn(resetn),.irq(mem_virq[4'h0f]),.ccs(code_cs[4'h0f]),
		 .dcs(data_cs[4'h0f]),.drd(data_rd),.dwe(data_we),.dwst(data_wst),
		 .cadrs(code_adrs),.dadrs(data_adrs),.din(data_wdata),.dout(mem_vdata[4'h0f]));

endmodule



