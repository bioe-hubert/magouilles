//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

// 32-bit definitions
bytpwd		=  4			// bytes per word
bitpwd		=  8 * bytpwd		// bits  per word

// memory segment addresses
cram_base	= 0x00000000		// code  RAM (64 KB)
dram_base	= 0x10000000		// data  RAM (64 KB)
eram_base	= 0x20000000		// extra RAM (8 KB)
bram_base	= 0xf0000000		// boot  RAM (2 KB)

// gpio (leds)
io0_base	= 0x30000000
io_data		= 0x00
io_state	= 0x00
io_set		= 0x04
io_clear	= 0x08
io_dir		= 0x0c

// uart
uart0_base	= 0x40000000
uart_thr	= 0x00
uart_rhr	= 0x00
uart_status	= 0x04
uart_div	= 0x08
uart_cfg	= 0x0c
uart_txrdy_bit	= 0
uart_rxrdy_bit	= 8

// spi
spi0_base	= 0x50000000
spi_thr		= 0x00
spi_rhr		= 0x00
spi_status	= 0x04			// bit[0] = idle (1=yes,0=no)
spi_div		= 0x08			// log2 divider  (1=div2, 2=div4...)
spi_rxrdy	= 1<<0
spi_txrdy	= 1<<0

// object tags
symbol_tag	= 0x7F			// #x30 mask used in gc to id non-gceable
string_tag	= 0x5F			// #x20 mask used in gc to id string
vector_tag	= 0x4F			// vector
string_sztg	= string_tag
symbol_sztg	= symbol_tag
vector_sztg	= vector_tag
symbol_ptag	= 0			// no tagged pointers in 32-bit
string_ptag	= 0			// no tagged pointers in 32-bit
vector_ptag	= 0			// no tagged pointers in 32-bit


//------------------------------------------------------------------------------
//
//		REGISTER RENAMING for SCHEME
//
//------------------------------------------------------------------------------

.req	zro, x0		// zero					 x0 = zero
.req	lnk, x1		// jump link				 x1 = ra
.req	stp, x2		// stack pointer			 x2 = sp

.req	ira, x3		// interrupted instruction address	 x3 = gp
.req	irm, x4		// active interrupt bits (during isr)	 x4 = tp
.req	ir0, x5		// isr temp register 0			 x5 = t0
.req	ir1, x6		// isr temp register 1			 x6 = t1
.req	ir2, x7		// isr temp register 2			 x7 = t2
.req	ir3, x8		// isr temp register 3			 x8 = s0
.req	ir4, x9		// isr temp register 4			 x9 = s1

.req	rva, x10	// raw value a				x10 = a0
.req	sv1, x11	// scheme value 1			x11 = a1
.req	sv2, x12	// scheme value 2			x12 = a2
.req	sv3, x13	// scheme value 3			x13 = a3
.req	sv4, x14	// scheme value 4			x14 = a4
.req	sv5, x15	// scheme value 5			x15 = a5
.req	dts, x16	// data stack				x16 = a6
.req	rvb, x17	// raw value b				x17 = a7
.req	con, x18	// continuation (return address)	x18 = s2
.req	env, x19	// default environment			x19 = s3
.req	hlm, x20	// heap bottom limit -- to trigger gc	x20 = s4
.req	fre, x21	// free pointer for dts/nursery space	x21 = s5
.req	rvc, x22	// raw value c				x22 = s6

.req	ir5, x23	// isr temp register 5			x23 = s7
.req	ir6, x24	// isr temp register 6			x24 = s8
.req	ir7, x25	// isr temp register 7			x25 = s9

// also: x26=s10, x27=s11, x28=t3, x29=t4, x30=t5, x31=t6


