//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

// 64-bit definitions

`define		rv64			// type of RISC-V (alt. is rv32)

//`define		include_multiplier	// include the multipler (ok for 32-bit only)

/* uncomment for peripherals in 32-bit address space (see aps_contants64.s also) * /
`define		AL	28		// peripheral-select address lsb
`define		AU	(`AL + 3)	// peripheral-select address msb
`define		reset_address		64'h0000_0000_f000_0000
`define		default_E_LS_adrs	64'h0000_0000_e000_0000
/* uncomment for peripherals at top of 64-bit address space (see aps_contants64.s also) */
`define		AL	60		// peripheral-select address lsb
`define		AU	(`AL + 3)	// peripheral-select address msb
`define		reset_address		64'hf000_0000_0000_0000
`define		default_E_LS_adrs	64'he000_0000_0000_0000
/* end of comment/uncomment for peripheral address space */

`define		XRL	3		// lsb for peripheral-register/mem address (log2(XB))
`define		XRU	(`XRL+1)	// msb for peripheral-register address
`define		BT2K	255
`define		T2	7		// address msb for 2KB of 64-bit BRAM
`define		XROVR2	(`XRL+`T2+1)	// lsb above top address for 2KB at 8-bit
`define		BT4K	511
`define		T4	8		// address msb for 4KB of 64-bit BRAM
`define		XROVR4	(`XRL+`T4+1)	// lsb above top address for 4KB at 8-bit
`define		BT8K	1023
`define		T8	9		// address msb for 8KB of 64-bit BRAM
`define		XROVR8	(`XRL+`T8+1)	// lsb above top address for 8KB at 8-bit

// field lengths
`define		XLEN	64		// XLEN		-- word size = 64-bit
`define		X1	(`XLEN -  1)	// XLEN -  1
`define		X2	(`XLEN -  2)	// XLEN -  2
`define		X4	(`XLEN -  4)	// XLEN -  4
`define		X5	(`XLEN -  5)	// XLEN -  5
`define		X6	(`XLEN -  6)	// XLEN -  6
`define		X7	(`XLEN -  7)	// XLEN -  7
`define		X8	(`XLEN -  8)	// XLEN -  8
`define		X9	(`XLEN -  9)	// XLEN -  9
`define		X11	(`XLEN - 11)	// XLEN - 11
`define		X12	(`XLEN - 12)	// XLEN - 12
`define		X15	(`XLEN - 15)	// XLEN - 15
`define		X16	(`XLEN - 16)	// XLEN - 16
`define		X17	(`XLEN - 17)	// XLEN - 17
`define		X24	(`XLEN - 24)	// XLEN - 24
`define		X25	(`XLEN - 25)	// XLEN - 25
`define		X31	(`XLEN - 31)	// XLEN - 31
`define		X32	(`XLEN - 32)	// XLEN - 32
`define		X33	(`XLEN - 33)	// XLEN - 33

`define		XB	(`XLEN /  8)	// num bytes        in 32-bit word
`define		XH	(`XLEN / 16)	// num double-bytes in 32-bit word
`define		XW	(`XLEN / 32)	// num quad-bytes   in 32-bit word

`define 	WS	(`XB - 1)	// MSB of write strobe (3 for 32-bit, 7 for 64-bit)
`define		WS_ff	8'hff		// write strobe mask for word (4'h0f for 32b, 8'hff for 64b)

// PLL: (icepll -i 12 -o 32) DIVR=0, DIVF=84, DIVQ=5 -> 31.875 MHz, CPU at PLL/2=15.9 MHz
`define		pll_div_r	4'b0000
`define		pll_div_f	7'b1010100
`define		pll_div_q	3'b101

// uart
`define		uart_status_0	64'h 0000_0000_0000_0001
`define		uart_div_0	64'h 0000_0000_0000_008a	// 115200 at CPU=15.9 MHz

// spi
`define		spi_status_0	64'h 0000_0000_0000_0001

// zero
`define		XZ0		64'h 0000_0000_0000_0000	// zero



