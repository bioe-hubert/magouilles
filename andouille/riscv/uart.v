//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

	//----------------------------------------------------------------------
	// UART				rhr/thr:	0x00
	//				status:		0x04
	//				div:		0x08
	//				config:		0x0c
	//----------------------------------------------------------------------

module uart (
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
	inout		[  1:0]	io	// [1]-tx, [0]-rx
	);

	wire		cs   = dcs & (drd | dwe);
	wire		rd   = dcs & drd;
	wire		we   = dcs & dwe;
	wire	[1:0]	adrs = dadrs[`XRU:`XRL];

	assign		irq   = cfg[8] & status[8];
	assign		io[1] = txbfr[0];		// send data (or 0b1 = not start bit)

	reg	[`X1:0]	status, div, cfg;
	reg	[  7:0]	rxbfr;
	reg	[  8:0]	txbfr;				//  9-bit pattern
	reg	[`X1:0]	tx_divcnt, rx_divcnt;
	reg	[  3:0]	tx_bitcnt, rx_bitcnt;

	always @(posedge clk) begin
	  if (!rstn) begin
	    status    <= `uart_status_0;
	    div	      <= `uart_div_0;		// 115200 at PLL=31.875 MHz, CPU=15.9 MHz
	    txbfr     <=  9'b 111111111;	//  9-bit pattern
	    rx_bitcnt <=  0;
	    rx_divcnt <=  0;
	  end else begin
	    // uart register read/write
	    if (cs) begin
	      case (adrs)
	        0: begin				// UART data register
		    dout <= {`X8'b0,rxbfr};
		    if (rd) status[8] <= 0;
		    else if (status[0]) begin
		      txbfr     <= {din[7:0],1'b0};
		      status[0] <= 0;
		    end
		  end
		1: dout <= status;			// status register (read only)
		2: begin				// baud rate divisor
		    dout <= div;
		    if (we) div <= din;
	          end
		3: begin				// configuration reg
		    dout <= cfg;
		    if (we) cfg <= din;
		  end
	      endcase
	    end
	    // uart Tx
	    if (status[0]) begin			// Tx idle
	      tx_bitcnt <= 10;
	      tx_divcnt <=  0;
	    end else begin				// Tx active
	      tx_divcnt <= tx_divcnt + 1;		// update uart_tx_divcnt
	      if (tx_divcnt > div) begin
		txbfr     <= {1'b1, txbfr[8:1]};	// upd send patn to 0b111..rmn_dat_bits
		tx_bitcnt <= tx_bitcnt - 1;
		tx_divcnt <= 0;
	      end
	      status[0] <= !tx_bitcnt;
	    end
	    // uart Rx
	    rx_divcnt <= rx_divcnt + 1;
	    case (rx_bitcnt)
	      0: begin	// wait for start bit (Rx lo)
		  rx_bitcnt   <= !io[0];
		  rx_divcnt   <= 0;
		end
	      1: begin	// go to middle of start bit
		  if (2*rx_divcnt > div) begin
		    rx_bitcnt <= io[0] ? 0 : 2;
		    rx_divcnt <= 0;
		  end
		end
	    10: begin	// wait for stop bit (Rx hi, discarded)
		  status[8]   <= 1;
	          rx_bitcnt   <= 0;
		end
	    default: begin // get 8-bit data
		  if (rx_divcnt > div) begin
		    rxbfr     <= {io[0], rxbfr[7:1]};	// acc Rx dat LSB 1st shft dn
		    rx_bitcnt <= rx_bitcnt + 1;
		    rx_divcnt <= 0;
		  end
		end
	    endcase
	  end
	end

endmodule



