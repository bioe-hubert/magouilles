//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Various assembler/linker parameters
//------------------------------------------------------------------------------

.global _text_sect_adrs_			// code address in "FLASH"
.global	_text_link_adrs_			// code address when system runs
.global _data_sect_adrs_			// data address in "FLASH"
.global	_data_link_adrs_			// data address when system runs

//------------------------------------------------------------------------------
// Code instructions section (.text) (start)
//------------------------------------------------------------------------------

.text						// code start
start_of_code:

//------------------------------------------------------------------------------
// data section (start)
//------------------------------------------------------------------------------

.data
start_of_data:					// data start

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


.global	isren					// may check address: 0x20, in .map file

.text

reset:	// first instruction
	b	start

.balign	bytpwd
	VCTR_item	_data_sect_adrs_	// data sect relative start pos
	VCTR_item	start_of_data		// data sect adrs start (target)
	VCTR_item	end_of_data		// data sect adrs end   (target)

	// symbols used for irq/exception handling
	SMBL	"ecall",	ecaster		// exception
	SMBL	"uart",		uarster		// irq = 4
	SMBL	"unknown",	unkster		// irq not treated

.balign 0x20
isren:	// IRQ treatment

	// save some user registers
	set	ir0, lnk			// ir0 <- lnk, saved
	set	ir1, sv1			// ir1 <- sv1, saved
	set	ir2, rva			// ir2 <- rva, saved
	set	ir3, rvb			// ir3 <- rvb, saved
	set	ir4, rvc			// ir4 <- rvc, saved
	// check irq vs exception
	csrr	sv1, mcause
	and	sv1, sv1, 1
	beqz	sv1, isrirq
	// exception (ecall)
	setobj	sv1, ecaster
	bl	ua0wst
	bl	ua0spc
	csrr	sv1, mepc
	bl	ua0whx
	bl	ua0nln
	b	isrxit				// jump to ISR exit
isrirq:	// irq
	csrr	rva, mie			// rva <- enables IRQs
	csrr	rvb, mip			// rvb <- pending IRQs
	and	rva, rva, rvb			// rva <- IRQs to treat
	set	rvb, 1<<(16+0x04)		// rvb <- bit for uart IRQ
	and	rvb, rvb, rva			// rvb <- is uart IRQ asserted?
	beqz	rvb, unkirq			//	if not, jump to unknown
uarirq:	// uart irq
	setobj	sv1, uarster
	bl	ua0wst
	bl	ua0spc
	csrr	sv1, mepc
	bl	ua0whx
	read	rvb, uart0_base, uart_rhr	// rvb <- byte from uart
	bl	ua0wrt				// write byte out
	bl	ua0nln
	b	isrxit				// jump to ISR exit
unkirq: // unknown irq
	setobj	sv1, unkster
	bl	ua0wst
	bl	ua0spc
	csrr	sv1, mepc
	bl	ua0whx
	bl	ua0nln
isrxit:	// exit isr (simple or normal)
	// restore user registers
	set	lnk, ir0			// lnk <- ir0, restored
	set	sv1, ir1			// sv1 <- ir1, restored
	set	rva, ir2			// rva <- ir2, restored
	set	rvb, ir3			// rvb <- ir3, restored
	set	rvc, ir4			// rvc <- ir4, restored
	// return
	mret


start:	// normal starting point

  .if bitpwd == 64
	// set-up global pointer for access to .data section (64-bit only)
	setobj	gp, _data_link_adrs_, imm
  .endif

	// set-up address of interrupt-service routine (isr)
	set	rva, 0x20
	csrw	mtvec, rva

	// copy .data section to start of data ram
	setobj	sv3, dram_base, imm		// sv3 <- data ram start address
	read	sv1, sv3, 1*bytpwd		// sv1 <- offset to data section
	ubfx	sv1, sv1, 0, 16
	add	sv1, sv1, sv3			// sv1 <- source start
	read	sv2, sv3, 2*bytpwd		// sv2 <- destination start
	read	sv5, sv3, 3*bytpwd		// sv5 <- destination end
	sub	sv5, sv5, sv2
	set	sv3, zro
dtcplp:	// loop
	read	rva, sv1, sv3
	write	rva, sv2, sv3
	add	sv3, sv3, bytpwd
	blt	sv3, sv5, dtcplp

	// config LED/gpio pins, set LED pattern
	write	0xff, io0_base, io_dir		// io0[7:1]=out (LEDs), io0[0]=out (flash CSn)
	write	0xaa, io0_base, io_set
	write	0x54, io0_base, io_clear

	// enable uart Rx interrupt
	write	0x100, uart0_base, uart_cfg

	// enable uart interrupt in core
	set	rvb, 1<<(16+0x04)		// based on address of peripheral (here 0x40000000)
	csrs	mie, rvb

	// write-out a newline
	bl	ua0nln

  .if bitpwd == 64
	// check setting of 64-bit constants
	setobj	sv1, 0x1234567890abcdef, imm
	bl	ua0whx
	set	sv1, -1
	bl	ua0whx
	set	sv1, -16
	bl	ua0whx
	bl	ua0nln
  .endif

	// check lui-addi and li
	lui	sv1, %hi(0xcafef00d)		// load upper 20-bits into reg
	addi	sv1, sv1, %lo(0xcafef00d)	// add  lower 12-bits (signed)
	bl	ua0whx
	setobj	sv1, 0xfa11f00d, imm
	bl	ua0whx
	bl	ua0nln

	// show value of cycle counter (4 times)
	rdcycle	sv1
	bl	ua0whx
	rdcycle	sv1
	bl	ua0whx
	rdcycle	sv1
	bl	ua0whx
	rdcycle	sv1
	bl	ua0whx
	bl	ua0nln

	// write single chars to uart and wait in-between
	set	rvb, 'B
	bl	ua0wrt
	wait	10000
	set	rvb, 'a
	bl	ua0wrt
	wait	10000
	bl	ua0nln

	// write a symbol
	setobj	sv1, unkster
	bl	ua0wst
	bl	ua0nln

	// check add & sub
	// cases:	2 +/- 3, 2 +/- -3, -2 +/- 3, -2 +/- -3
	// 0x00000002 + 0x00000003 = 0x00000005 0x00000002 - 0x00000003 = 0xffffffff
	// 0x00000002 + 0xfffffffd = 0xffffffff 0x00000002 - 0xfffffffd = 0x00000005
	// 0xfffffffe + 0x00000003 = 0x00000001 0xfffffffe - 0x00000003 = 0xfffffffb
	// 0xfffffffe + 0xfffffffd = 0xfffffffb 0xfffffffe - 0xfffffffd = 0x00000001
	set	sv3,  2
	set	sv4,  3
	add	sv2, sv3, sv4
	bl	shosum
	bl	ua0nln
	sub	sv2, sv3, sv4
	bl	shosub
	bl	ua0nln
	set	sv3,  2
	set	sv4, -3
	add	sv2, sv3, sv4
	bl	shosum
	bl	ua0nln
	sub	sv2, sv3, sv4
	bl	shosub
	bl	ua0nln
	set	sv3, -2
	set	sv4,  3
	add	sv2, sv3, sv4
	bl	shosum
	bl	ua0nln
	sub	sv2, sv3, sv4
	bl	shosub
	bl	ua0nln
	set	sv3, -2
	set	sv4, -3
	add	sv2, sv3, sv4
	bl	shosum
	bl	ua0nln
	sub	sv2, sv3, sv4
	bl	shosub
	bl	ua0nln

  .if bitpwd == 32
	// check mul, mulh, mulhu and mulhsu
	// multiplication tests:  +/-2 * +/-2
	// 0x00000002 * 0x00000002 = 0x00000004 mul 0x00000000 mulh 0x00000000 mulhu 0x00000000 mulhsu
	// 0x00000002 * 0xfffffffe = 0xfffffffc mul 0xffffffff mulh 0x00000001 mulhu 0x00000001 mulhsu
	// 0xfffffffe * 0x00000002 = 0xfffffffc mul 0xffffffff mulh 0x00000001 mulhu 0xffffffff mulhsu
	// 0xfffffffe * 0xfffffffe = 0x00000004 mul 0x00000000 mulh 0xfffffffc mulhu 0xfffffffe mulhsu
	// case 1:	2 * 2
	set	x27,  2
	set	x28,  2
	mul	x26, x27, x28
	bl	shomul
	setobj	sv1, mulstr
	bl	ua0wst
	bl	ua0spc
	mulh	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhstr
	bl	ua0wst
	bl	ua0spc
	mulhu	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhustr
	bl	ua0wst
	bl	ua0spc
	mulhsu	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhsustr
	bl	ua0wst
	bl	ua0nln
	// case 2:	2 * -2
	set	x27,  2
	set	x28, -2
	mul	x26, x27, x28
	bl	shomul
	setobj	sv1, mulstr
	bl	ua0wst
	bl	ua0spc
	mulh	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhstr
	bl	ua0wst
	bl	ua0spc
	mulhu	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhustr
	bl	ua0wst
	bl	ua0spc
	mulhsu	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhsustr
	bl	ua0wst
	bl	ua0nln
	// case 3:	-2 * 2
	set	x27, -2
	set	x28,  2
	mul	x26, x27, x28
	bl	shomul
	setobj	sv1, mulstr
	bl	ua0wst
	bl	ua0spc
	mulh	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhstr
	bl	ua0wst
	bl	ua0spc
	mulhu	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhustr
	bl	ua0wst
	bl	ua0spc
	mulhsu	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhsustr
	bl	ua0wst
	bl	ua0nln
	// case 4:	-2 * -2
	set	x27, -2
	set	x28, -2
	mul	x26, x27, x28
	bl	shomul
	setobj	sv1, mulstr
	bl	ua0wst
	bl	ua0spc
	mulh	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhstr
	bl	ua0wst
	bl	ua0spc
	mulhu	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhustr
	bl	ua0wst
	bl	ua0spc
	mulhsu	sv1, x27, x28
	bl	ua0whx
	setobj	sv1, mulhsustr
	bl	ua0wst
	bl	ua0nln
  .endif

	// wait for keypress (check wfi)
	wfi

	// test ecall
	ecall

	// toggle LEDs (but not flash CSn)
	read	rvb, io0_base, io_state
	and	rvb, rvb, 0x0e
	write	rvb, io0_base, io_clear
	not	rvb, rvb
	and	rvb, rvb, 0x0e
	write	rvb, io0_base, io_set

endlop:	// do nothing, except respond to keypress
	b	endlop


	// uart output macros and functions

.macro	ua0twt
	// wait for uart0 tx-ready
	// mod:	rva=x10
701:	// wait loop
	read	rva, uart0_base, uart_status
	ubfx	rva, rva, uart_txrdy_bit, 1
	beqz	rva, 701b
.endm

.macro	ua0tx val
	// write val to uart0 (assumed tx-ready already)
	// mod: rva=x10, rvb=x17 is val is not reg
	write	\val, uart0_base, uart_thr
.endm

.macro	ua0wrt val
	// write byte (val) to uart0
	// mod: rva=x10, rvb=x17 (if val is not reg)
	// mod: rvc=x22 if val is reg (T0 mod)
  check_if_reg \val
  .ifeq item_is_reg_flag
	ua0twt
	ua0tx	\val
  .else
    .ifeqs "\val","rva"
	set	rvc, \val
    .endif
	ua0twt
    .ifeqs "\val","rva"
	set	\val, rvc
    .endif
	ua0tx	\val
  .endif
.endm

ua0wrt:	// write byte in rvb=x17 to uart0
	// mod:	rva=x10, rvc=x22
	// ret:	lnk=x2
	ua0wrt	rvb
	ret

ua0whx:	// write item in sv1=sv1, in hex form, to uart0
	// mod:	rva=x10, rvb=x17, rvc=x22, x30
	// ret:	lnk=x2
	ua0wrt	'0
	ua0wrt	'x
	set	rvc, bitpwd
ua0wh0:	// loop
	add	rvc, rvc, -4
	ua0twt
	srl	rvb, sv1, rvc
	and	rvb, rvb, 0x0f
	add	rvb, rvb, 0x30
	set	rva, 0x3a
	blt	rvb, rva, ua0wh1
	add	rvb, rvb, 0x27
ua0wh1:	// continue
	ua0tx	rvb
	bnez	rvc, ua0wh0
	b	ua0spc

ua0wst:	// write string, or symbol, in sv1=sv1, as a sequence of chars, to uart0
	// (maximum of 64000 bytes)
	// mod:	rva=x10, rvb=x17, rvc=x22
	// ret:	lnk
	gettag	rvb, sv1
	and	rva, rvb, 0xff
	lsr	rvb, rvb, 8
	set	rvc, string_sztg
	bne	rva, rvc, ua0ws0
	lsl	rvb, rvb, 1
ua0ws0:	// loop
	set	rvc, rvb
	ua0twt
	set	rvb, rvc
	lsl	rva, rvb, bitpwd/2
	lsr	rvb, rvb, bitpwd/2
	orr	rvb, rvb, rva
	set	rva, rvc
	beq	rva, rvb, ua0wsx
	lsr	rva, rva, bitpwd/2
	add	rvb, sv1, rva
	read8	rvb, rvb, 0
	ua0tx	rvb
	set	rvb, 1<<(bitpwd/2)
	add	rvb, rvb, rvc
	b	ua0ws0
ua0wsx:	ret

ua0spc:	// write space to uart0
	// mod:	rva
	// ret:	lnk
	ua0wrt	32
	ret

ua0nln:	// write newline to uart0
	// mod:	rva=x10
	// ret:	lnk
	ua0wrt	'\r
	ret

shomul:	// in sv3 <- op1
	// in sv4 <- op2
	// in sv2 <- result
	set	sv5, lnk
	set	sv1, sv3
	bl	ua0whx
	ua0wrt	'*
	b	sho_en

shosum:	// in sv3 <- op1
	// in sv4 <- op2
	// in sv2 <- result
	set	sv5, lnk
	set	sv1, sv3
	bl	ua0whx
	ua0wrt	'+
	b	sho_en

shosub:	// in sv3 <- op1
	// in sv4 <- op2
	// in sv2 <- result
	set	sv5, lnk
	set	sv1, sv3
	bl	ua0whx
	ua0wrt	'-
sho_en:	// [internal entry]
	ua0wrt	' 
	set	sv1, sv4
	bl	ua0whx
	ua0wrt	'=
	ua0wrt	' 
	set	sv1, sv2
	bl	ua0whx
	set	lnk, sv5
	ret

	// symbols used for testing of multiplier (32-bits only)
	SMBL	"mul",		mulstr
	SMBL	"mulh",		mulhstr
	SMBL	"mulhu",	mulhustr
	SMBL	"mulhsu",	mulhsustr

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

.text; .balign 64, 0

end_of_code:

// empty vector
VCTR	empty_vector			// empty vector (for boot)

//------------------------------------------------------------------------------
// data section (ending)
//------------------------------------------------------------------------------

.data	0; .balign 16, 0
.data	1; .balign 16, 0
.data	2; .balign 64, 0

end_of_data:

.end



