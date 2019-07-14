//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Gnarly Grey UPDuino V2.0
// iCE40UP5K-SG48
//------------------------------------------------------------------------------

// 32-bit soc definitions (reset address, bit field limits,...)
`include	"soc32.vh"

// PLL module type and name of input cock signal (for clocks.v)
`define		PLL_MODULE	SB_PLL40_PAD
`define		PLL_REFCLK	.PACKAGEPIN

// connection to outside pins (upduino.pcf) and soc instantiation
module top (
	input		p35,		// clk
	inout		p15,		// flash_clk_uart_rx,	spi0/uart0_io[0]
	output		p14,		// flash_mosi_uart_tx,	spi0/uart0_io[1]
	input		p17,		// flash_miso,		spi0_io[2]
	inout		p16,		// flash_csn,		gpio0_io[0]
	inout		p41,		// red,			gpio0_io[1]
	inout		p39,		// green,		gpio0_io[2]
	inout		p40,		// blue,		gpio0_io[3]
	inout		p12,		// 			gpio0_io[4]
	inout		p21,		// 			gpio0_io[5]
	inout		p13,		// 			gpio0_io[6]
	inout		p20		// 			gpio0_io[7]
	);

	// flash vs uart pin multiplexing
	wire		uart_tx;
	wire		uart_rx;
	wire		flash_mosi;
	wire		flash_clk;
	assign		p14     = !p16 ? flash_mosi : uart_tx;
	assign		p15     = !p16 ? flash_clk  : 1'bz;
	assign		uart_rx = p15;

	// soc instantiation
	soc rvsoc(
		.clk(p35),
		.uart0_io({uart_tx,uart_rx}),			// {uart_tx,uart_rx}
		.gpio0_io({p20,p13,p21,p12,p40,p39,p41,p16}),	// {4xio-pins,blue,green,red,flash_csn}
		.spi0_io({p17,flash_mosi,flash_clk})		// {flash_miso,flash_mosi,flash_clk}
	);

endmodule



