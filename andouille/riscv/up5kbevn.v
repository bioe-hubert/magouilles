//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// iCE40 UltraPlus Breakout Board, Rev. A, iCE40UP5K-B-EVN
// iCE40UP5K-SG48
//------------------------------------------------------------------------------

// 32-bit soc definitions (reset address, bit field limits,...)
`include	"soc32.vh"

// PLL module type and name of input cock signal (for clocks.v)
`define		PLL_MODULE	SB_PLL40_PAD
`define		PLL_REFCLK	.PACKAGEPIN

// connection to outside pins (up5kbevn.pcf) and soc instantiation
module top (
	input		p35,		// clk, 12 MHz from FTDI osc
	input		p06,		// uart_rx,		uart0_io[0]
	output		p09,		// uart_tx,		uart0_io[1]
	output		p15,		// flash_clk,		spio0_io[0]
	output		p14,		// flash_mosi,		spio0_io[1]
	input		p17,		// flash_miso,		spio0_io[2]
	inout		p16,		// flash_csn,		gpio0_io[0]
	inout		p41,		// red   LED,		gpio0_io[1]
	inout		p40,		// green LED,		gpio0_io[2]
	inout		p39,		// blue  LED,		gpio0_io[3]
	inout		p12,		//			gpio0_io[4]
	inout		p21,		//			gpio0_io[5]
	inout		p13,		//			gpio0_io[6]
	inout		p20		//			gpio0_io[7]
	);

	// soc instantiation
	soc rvsoc(
		.clk(p35),
		.uart0_io({p09,p06}),				// {uart_tx,uart_rx}
		.gpio0_io({p20,p13,p21,p12,p39,p40,p41,p16}),	// {4xio-pins,blue,green,red,flash_csn}
		.spi0_io({p17,p14,p15})				// {flash_miso,flash_mosi,flash_clk}
	);

endmodule



