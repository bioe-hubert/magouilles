//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

	//----------------------------------------------------------------------
	// LEDs and/or GPIO		data:		0x00
	//				set:		0x04
	//				clear:		0x08
	//				dir:		0x0c
	//----------------------------------------------------------------------

module gpio (
	input			clk,	// clock input
	input			rstn,	// reset (negated, lo=reset)
	input			dcs,	// data access chip-select
	input			drd,	// data read  enable (if used)
	input			dwe,	// data write enable
	input		[`WS:0]	dwst,	// data write strobe (byte-based)
	input		[`X1:0]	dadrs,	// data access read/write address
	input		[`X1:0]	din,	// data to write to peripheral
	output	reg	[`X1:0]	dout,	// data or code from peripheral
	output			irq,	// irq output
	inout		[  7:0]	io
	);

	wire		cs   = dcs & (drd | dwe);
	wire		rd   = dcs & drd;
	wire		we   = dcs & dwe;
	wire	[1:0]	adrs = dadrs[`XRU:`XRL];

	assign		irq   = 1'b0;
	assign		io[0] = dir[0] ? data[0] : 1'bz;
	assign		io[1] = dir[1] ? data[1] : 1'bz;
	assign		io[2] = dir[2] ? data[2] : 1'bz;
	assign		io[3] = dir[3] ? data[3] : 1'bz;
	assign		io[4] = dir[4] ? data[4] : 1'bz;
	assign		io[5] = dir[5] ? data[5] : 1'bz;
	assign		io[6] = dir[6] ? data[6] : 1'bz;
	assign		io[7] = dir[7] ? data[7] : 1'bz;

	reg	[7:0]	data, dir;
	wire	[7:0]	io_dat = dir & data | ~dir & io;

	always @(posedge clk) begin
	  if (!rstn) begin
	    dir <= 8'h 00;			// all gpio are inputs (default)
	  end else if (cs) begin		// read/write GPIO registers
	    case (adrs)
	      0: begin				// GPIO data out register
		dout <= {`X8'h000000,io_dat};
		if (we) data <= din[7:0] & dir;
	      end
	      1: begin				// GPIO set
		dout <= {`X8'h000000,io_dat};
		if (we) data <= data | din[7:0] & dir;
	      end
	      2: begin				// GPIO clear
		dout <= {`X8'h000000,io_dat};
		if (we) data <= data & ~(din[7:0] & dir);
	      end
	      3: begin				// GPIO direction register (0=in, 1=out)
		dout <= {`X8'h000000,dir};
		if (we) dir <= din[7:0];
	      end
	    endcase
	  end
	end

endmodule



