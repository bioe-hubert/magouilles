//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// iCE40-HX8K Breakout Board, Rev. A, iCE40HX8K-B-EVN
// iCE40HX8K-CT256
//------------------------------------------------------------------------------

// 64-bit soc definitions (reset address, bit field limits,...)
`include	"soc64.vh"

// PLL module type and name of input cock signal (for clocks.v)
`define		PLL_MODULE	SB_PLL40_CORE
`define		PLL_REFCLK	.REFERENCECLK

// connection to outside pins (hx8kbevn.pcf) and soc instantiation
module top (
	input		t26,		// clk, 12 MHz from FTDI osc
	input		p14,		// uart_rx,		uart0_io[0]
	output		p13,		// uart_tx,		uart0_io[1]
	output		s02,		// flash_clk,		spio0_io[0]
	output		s00,		// flash_mosi,		spio0_io[1]
	input		s01,		// flash_miso,		spio0_io[2]
	inout		s03,		// flash_ss,		gpio0_io[0]
	inout		p41,		// LED1, D8		gpio0_io[1]
	inout		p42,		// LED2, D7		gpio0_io[2]
	inout		p44,		// LED3, D6		gpio0_io[3]
	inout		p45,		// LED4, D5		gpio0_io[4]
	inout		p46,		// LED5, D4		gpio0_io[5]
	inout		p47,		// LED6, D3		gpio0_io[6]
	inout		p51		// LED7, D2		gpio0_io[7]
	);

	// soc instantiation
	soc rvsoc(
		.clk(t26),
		.uart0_io({p13,p14}),				// {uart_tx,uart_rx}
		.gpio0_io({p51,p47,p46,p45,p44,p42,p41,s03}),	// {7xLED,flash_csn}
		.spi0_io({s01,s00,s02})				// {flash_miso,flash_mosi,flash_clk}
	);

endmodule



