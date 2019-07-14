//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

	//----------------------------------------------------------------------
	// code RAM (cram), SPRAM			0x00000000 (64 KB)
	//----------------------------------------------------------------------

module spram (
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

  `ifdef rv32

	wire	[13:0]	adrs = ccs ? cadrs[15:2] : dadrs[15:2];

	assign		irq  = ccs & |cadrs[`X5:16] | dcs & (drd | dwe) & |dadrs[`X5:16];

	SB_SPRAM256KA ram_lo16
	  (.ADDRESS(adrs),.DATAIN(din[15:0]),.DATAOUT(dout[15:0]),
	   .WREN(we),.MASKWREN({dwst[1],dwst[1],dwst[0],dwst[0]}),
	   .CHIPSELECT(cs),.CLOCK(clk),.POWEROFF(1'b1));

	SB_SPRAM256KA ram_hi16
	  (.ADDRESS(adrs),.DATAIN(din[31:16]),.DATAOUT(dout[31:16]),
	   .WREN(we),.MASKWREN({dwst[3],dwst[3],dwst[2],dwst[2]}),
	   .CHIPSELECT(cs),.CLOCK(clk),.POWEROFF(1'b1));

  `else

	wire	[13:0]	adrs = ccs ? cadrs[16:3] : dadrs[16:3];

	assign		irq  = ccs & |cadrs[`X5:17] | dcs & (drd | dwe) & |dadrs[`X5:17];

	SB_SPRAM256KA ram_15
	  (.ADDRESS(adrs),.DATAIN(din[15:0]),.DATAOUT(dout[15:0]),
	   .WREN(we),.MASKWREN({dwst[1],dwst[1],dwst[0],dwst[0]}),
	   .CHIPSELECT(cs),.CLOCK(clk),.POWEROFF(1'b1));

	SB_SPRAM256KA ram_31
	  (.ADDRESS(adrs),.DATAIN(din[31:16]),.DATAOUT(dout[31:16]),
	   .WREN(we),.MASKWREN({dwst[3],dwst[3],dwst[2],dwst[2]}),
	   .CHIPSELECT(cs),.CLOCK(clk),.POWEROFF(1'b1));

	SB_SPRAM256KA ram_47
	  (.ADDRESS(adrs),.DATAIN(din[47:32]),.DATAOUT(dout[47:32]),
	   .WREN(we),.MASKWREN({dwst[5],dwst[5],dwst[4],dwst[4]}),
	   .CHIPSELECT(cs),.CLOCK(clk),.POWEROFF(1'b1));

	SB_SPRAM256KA ram_63
	  (.ADDRESS(adrs),.DATAIN(din[63:48]),.DATAOUT(dout[63:48]),
	   .WREN(we),.MASKWREN({dwst[7],dwst[7],dwst[6],dwst[6]}),
	   .CHIPSELECT(cs),.CLOCK(clk),.POWEROFF(1'b1));

  `endif
  

endmodule



