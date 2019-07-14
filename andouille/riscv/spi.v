//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------
//  Adapted in part from SPU32 spicontroller.v, Distributed under The MIT License.
//  Copyright (c) 2018 maikmerten
//------------------------------------------------------------------------------

	//----------------------------------------------------------------------
	// SPI	master			thr/rhr:	0x00
	//				Status:		0x04	(bit0 = idle)
	//				Log 2 Divider:	0x08	(1=div2, 2=div4, 3=div8...)
	//----------------------------------------------------------------------

module spi (
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
	inout		[  2:0]	io	// [0]-clk, [1]-mosi, [2]-miso
	);

	wire		cs   = dcs & (drd | dwe);
	wire		rd   = dcs & drd;
	wire		we   = dcs & dwe;
	wire	[1:0]	adrs = dadrs[`XRU:`XRL];

	assign		irq     = 1'b0;
	assign		io[1:0] = {txbfr[7],tx_clk};

	reg	[`X1:0]	status;
	reg	[  7:0]	txbfr, rxbfr;
	reg	[  1:0]	clkcount;
	reg	[  4:0]	log2div;
	reg		tx_clk, tx_prevclk;
	reg	[  3:0]	bitcount;

	always @(posedge clk) begin
	  if (!rstn) begin
	    status   <=  `spi_status_0;
	    clkcount <=  2'b 00;
	    log2div  <=  5'b 00001;
	    bitcount <=  0;
	  end else begin
	    // spi register read/write
	    if (cs) begin				// read/write SPI registers
	      case (adrs)
		0: begin				// Tx/Rx data register
		    dout <= {`X8'b0,rxbfr};
		    if (we & status[0]) begin
		      txbfr     <= din[7:0];
		      status[0] <= 0;
		    end
		  end
		1: dout <= status;			// status register (read only)
		2: begin				// log 2 divisor register
		    dout <= {`X5'b0,log2div};
		    if (we) log2div <= din[4:0];
	          end
	      endcase
	    end
	    // spi data transfer Tx/Rx
	    if (status[0]) begin
	      tx_prevclk <= 0;
	      tx_clk     <= 0;
	      clkcount   <= 2'b00;
	      bitcount   <= 8;
	    end else begin
	      tx_prevclk <= tx_clk;
	      clkcount   <= clkcount + 1;
	      tx_clk     <= clkcount[log2div];
	      if (tx_clk & ~tx_prevclk) begin		// shift data in on rising edge
		rxbfr    <= {rxbfr[6:0],io[2]};
		bitcount <= bitcount - 1;
	      end
	      if (tx_prevclk & ~tx_clk) begin		// shift data out on falling edge
		txbfr     <= {txbfr[6:0],1'b0};
		status[0] <= !bitcount;
	      end
	    end
	  end
	end

endmodule



