//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

	//----------------------------------------------------------------------
	// boot RAM (bram), Block RAM			0xf0000000 (2 KB)
	//----------------------------------------------------------------------

module bram (
	input			clk,	// clock input
	input			rstn,	// reset (negated, lo=reset)
	input			ccs,	// code access chip-select
	input		[`X1:0]	cadrs,	// code access read address
	input			dcs,	// data access chip-select
	input			drd,	// data read  enable (if used)
	input			dwe,	// data write enable
	input		[`WS:0]	dwst,	// data write strobe (byte-based)
	input		[`X1:0]	dadrs,	// data access read/write address
	input		[`X1:0]	din,	// data to write to peripheral
	output	reg	[`X1:0]	dout,	// data or code from peripheral
	output			irq	// irq output
	);

	wire		cs   = ccs | dcs & (drd | dwe);
	wire		we   = ccs ? 1'b0 : dcs & dwe;
	wire	[`T2:0]	adrs = ccs ? cadrs[(`XRL+`T2):`XRL] : dadrs[(`XRL+`T2):`XRL];

	assign		irq  = ccs & |cadrs[`X5:`XROVR2] | dcs & (drd | dwe) & |dadrs[`X5:`XROVR2];

	reg	[`X1:0]	bram_mem[0:`BT2K];		//  2 KB

  `ifdef rv32
	initial $readmemh("bin/boot32ph.hex", bram_mem);	// boot code place-holder
  `else
	initial $readmemh("bin/boot64ph.hex", bram_mem);	// boot code place-holder
  `endif

	always @(posedge clk) begin
	  dout <= bram_mem[adrs];
	  if (we) begin
	    if (dwst[0]) bram_mem[adrs][ 7: 0] <= din[ 7: 0];
	    if (dwst[1]) bram_mem[adrs][15: 8] <= din[15: 8];
	    if (dwst[2]) bram_mem[adrs][23:16] <= din[23:16];
	    if (dwst[3]) bram_mem[adrs][31:24] <= din[31:24];
  `ifdef rv64
	    if (dwst[4]) bram_mem[adrs][39:32] <= din[39:32];
	    if (dwst[5]) bram_mem[adrs][47:40] <= din[47:40];
	    if (dwst[6]) bram_mem[adrs][55:48] <= din[55:48];
	    if (dwst[7]) bram_mem[adrs][63:56] <= din[63:56];
  `endif
	  end
	end

endmodule

	//----------------------------------------------------------------------
	// code/data RAM (cram), Block RAM, 4 KB
	//----------------------------------------------------------------------

module bram4k (
	input			clk,	// clock input
	input			rstn,	// reset (negated, lo=reset)
	input			ccs,	// code access chip-select
	input		[`X1:0]	cadrs,	// code access read address
	input			dcs,	// data access chip-select
	input			drd,	// data read  enable (if used)
	input			dwe,	// data write enable
	input		[`WS:0]	dwst,	// data write strobe (byte-based)
	input		[`X1:0]	dadrs,	// data access read/write address
	input		[`X1:0]	din,	// data to write to peripheral
	output	reg	[`X1:0]	dout,	// data or code from peripheral
	output			irq	// irq output
	);

	wire		cs   = ccs | dcs & (drd | dwe);
	wire		we   = ccs ? 1'b0 : dcs & dwe;
	wire	[`T4:0]	adrs = ccs ? cadrs[(`XRL+`T4):`XRL] : dadrs[(`XRL+`T4):`XRL];

	assign		irq  = ccs & |cadrs[`X5:`XROVR4] | dcs & (drd | dwe) & |dadrs[`X5:`XROVR4];

	reg	[`X1:0]	bram_mem[0:`BT4K];	//  4 KB

	always @(posedge clk) begin
	  dout <= bram_mem[adrs];
	  if (we) begin
	    if (dwst[0]) bram_mem[adrs][ 7: 0] <= din[ 7: 0];
	    if (dwst[1]) bram_mem[adrs][15: 8] <= din[15: 8];
	    if (dwst[2]) bram_mem[adrs][23:16] <= din[23:16];
	    if (dwst[3]) bram_mem[adrs][31:24] <= din[31:24];
  `ifdef rv64
	    if (dwst[4]) bram_mem[adrs][39:32] <= din[39:32];
	    if (dwst[5]) bram_mem[adrs][47:40] <= din[47:40];
	    if (dwst[6]) bram_mem[adrs][55:48] <= din[55:48];
	    if (dwst[7]) bram_mem[adrs][63:56] <= din[63:56];
  `endif
	  end
	end

endmodule

	//----------------------------------------------------------------------
	// code/data RAM (cram), Block RAM, 8 KB
	//----------------------------------------------------------------------

module bram8k (
	input			clk,	// clock input
	input			rstn,	// reset (negated, lo=reset)
	input			ccs,	// code access chip-select
	input		[`X1:0]	cadrs,	// code access read address
	input			dcs,	// data access chip-select
	input			drd,	// data read  enable (if used)
	input			dwe,	// data write enable
	input		[`WS:0]	dwst,	// data write strobe (byte-based)
	input		[`X1:0]	dadrs,	// data access read/write address
	input		[`X1:0]	din,	// data to write to peripheral
	output	reg	[`X1:0]	dout,	// data or code from peripheral
	output			irq	// irq output
	);

	wire		cs   = ccs | dcs & (drd | dwe);
	wire		we   = ccs ? 1'b0 : dcs & dwe;
	wire	[`T8:0]	adrs = ccs ? cadrs[(`XRL+`T8):`XRL] : dadrs[(`XRL+`T8):`XRL];

	assign		irq  = ccs & |cadrs[`X5:`XROVR8] | dcs & (drd | dwe) & |dadrs[`X5:`XROVR8];

	reg	[`X1:0]	bram_mem[0:`BT8K];	//  8 KB

	always @(posedge clk) begin
	  dout <= bram_mem[adrs];
	  if (we) begin
	    if (dwst[0]) bram_mem[adrs][ 7: 0] <= din[ 7: 0];
	    if (dwst[1]) bram_mem[adrs][15: 8] <= din[15: 8];
	    if (dwst[2]) bram_mem[adrs][23:16] <= din[23:16];
	    if (dwst[3]) bram_mem[adrs][31:24] <= din[31:24];
  `ifdef rv64
	    if (dwst[4]) bram_mem[adrs][39:32] <= din[39:32];
	    if (dwst[5]) bram_mem[adrs][47:40] <= din[47:40];
	    if (dwst[6]) bram_mem[adrs][55:48] <= din[55:48];
	    if (dwst[7]) bram_mem[adrs][63:56] <= din[63:56];
  `endif
	  end
	end

endmodule



