//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

// set to non-zero if you want to get feedback on some macro expansions
debug_macros	= 0

// compatibility

.macro	b label
	j	\label
.endm

.macro	bl label
	jal	\label
.endm

.macro	br reg
	jr	\reg
.endm

.macro	getpc reg
	auipc	\reg,     0		// reg <- pc + 0 (in upper 20-bits)
.endm

.macro	lsl	args:vararg
	sll	\args
.endm

.macro	lsr	args:vararg
	srl	\args
.endm

.macro	asr	args:vararg
	sra	\args
.endm

.macro	orr	args:vararg
	or	\args
.endm

.macro	eor	args:vararg
	xor	\args
.endm

.macro	ldr	args:vararg
	read	\args
.endm

.macro	ldrh	args:vararg
	read16	\args
.endm

.macro	ldrb	args:vararg
	read8	\args
.endm

.macro	str	args:vararg
	write	\args
.endm

.macro	strh	args:vararg
	write16	\args
.endm

.macro	strb	args:vararg
	write8	\args
.endm

// scheme vector

.macro	VCTR	target, items:vararg
	STARTVCTR \target
  .ifnb	\items
	VCTR_item \items
  .endif
	ENDsized
.endm

.macro	STARTVCTR target
	.data	0
	.balign	2*bytpwd, 0
  .if bitpwd == 32
	VCTR_item ((13f - utg_\target) << 6) | vector_tag
  .else
	VCTR_item (((13f - utg_\target) >> 3) << 2) | i0
  .endif
	utg_\target	 = .
	\target		 = utg_\target + vector_ptag
	utg_ofst_\target = utg_\target - start_of_data
	ofst_\target	 = (utg_\target - start_of_data) + vector_ptag
.endm


.macro	VCTR_item item1, items:vararg
  .if bitpwd == 32
	.word	\item1
  .else
	.8byte	\item1
  .endif
  .ifnb	\items
	VCTR_item \items
  .endif
.endm

.macro	ENDsized
	13:
	.balign	bytpwd, 0x31	// alignment with gc-safe filler
	.text
.endm


// scheme symbol -- utf-8

.macro	SMBL strng, address
	STARTSMBL \address
	.ascii	"\strng"
	ENDsized
.endm

.macro	STARTSMBL target
	.data	0
	.balign	2*bytpwd, 0
	VCTR_item ((13f - utg_\target) << 8) | symbol_sztg
	utg_\target	 = .
	\target		 = utg_\target + symbol_ptag
	utg_ofst_\target = utg_\target - start_of_data
	ofst_\target	 = (utg_\target - start_of_data) + symbol_ptag
.endm

// scheme string -- unicode MCS2 (16-bit)

.macro	STRNG strng, address
	STARTSTRNG \address
	.string16 "\strng"		// ends with two 0-bytes
	ENDsized
.endm

.macro	STARTSTRNG target
	.data	0
	.balign	2*bytpwd, 0
	VCTR_item ((13f - utg_\target - 2) << 7) | string_sztg
	utg_\target = .
	\target = utg_\target + string_ptag
	utg_ofst_\target = utg_\target - start_of_data
	ofst_\target = (utg_\target - start_of_data) + string_ptag
.endm

.macro	check_if_member item, arg1, args:vararg
	.set	item_is_member_flag, 0
   .ifeqs "\item","\arg1"
	.set	item_is_member_flag, 1
  .else
    .ifnb \args
	check_if_member \item, \args
    .endif
  .endif
.endm

.macro	check_if_reg item
	.set	item_is_reg_flag, 0
	check_if_member \item,  con,rva,rvb,rvc,sv1,sv2,sv3,sv4,sv5,env,dts,fre,hlm,lnk,stp,zro
  .ifeq item_is_member_flag
	check_if_member \item, x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15
   .ifeq item_is_member_flag
	check_if_member \item, x16,x17,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31
    .ifeq item_is_member_flag
	check_if_member \item, zero,ra,sp,gp,tp,t0,t1,t2,t3,t4,t5,t6,a0,a1,a2,a3,a4,a5,a6,a7
     .ifeq item_is_member_flag
	check_if_member \item, ira,irm,ir0,ir1,ir2,ir3,ir4,ir5,ir6,ir7
      .ifeq item_is_member_flag
	check_if_member \item, 	s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11
      .endif
     .endif
    .endif
   .endif
  .endif
	.set	item_is_reg_flag, item_is_member_flag
  .if debug_macros
    .if item_is_reg_flag
	.print "\item is reg"
    .else
	.print "\item is not reg"
    .endif
  .endif
.endm

.macro	check_if_nongc_reg item
	.set	item_is_nongc_reg_flag, 0
	check_if_member \item, rva,rvb,rvc
	.set	item_is_nongc_reg_flag, item_is_member_flag
  .if debug_macros
    .if item_is_nongc_reg_flag
	.print "\item is nongc reg"
    .else
	.print "\item is not nongc reg"
    .endif
  .endif
.endm


.macro	gettag dest, obj
	read	\dest, \obj, -bytpwd
.endm

.macro	ubfx dest, src, start, size
  .if ((\start)+(\size)) >= bitpwd
	lsr	\dest, \src, \start
  .else
	lsl	\dest, \src,  bitpwd - ((\start)+(\size))
	lsr	\dest, \dest, bitpwd-(\size)
  .endif
.endm

// read from register

.macro	read	args:vararg
  .if bitpwd == 32
	read_aux lw, \args
  .else
	read_aux ld, \args
  .endif
.endm

.macro	read8	dest, args:vararg
	read_aux lbu, \dest, \args
.endm

.macro	read16	dest, args:vararg
	read_aux lhu, \dest, \args
.endm

.macro	read32	dest, args:vararg
	read_aux lw, \dest, \args
.endm

.macro	read64	dest, args:vararg
	read_aux ld, \dest, \args
.endm

.macro	read_aux rfun, dest, src, ofst
	// in:	rfun	<- read function		(ldr, ldrh or ldrb)
	// in:	dest	<- destination			(register)
	// in:	src	<- source			(register or address)
	// in:	ofst    <- source offset		(immediate only?)
  check_if_reg \src
  .ifeq item_is_reg_flag
	set	rva, \src
	read_aux \rfun, \dest, rva, \ofst
  .else
      check_if_reg \ofst
      .ifeq item_is_reg_flag
	\rfun \dest, \ofst(\src)
      .else
	\rfun\()_r \dest, \src, \ofst
      .endif
  .endif
.endm

// write to register

.macro	write	args:vararg
  .if bitpwd == 32
	write_aux sw, \args
  .else
	write_aux sd, \args
  .endif
.endm

.macro	write8	args:vararg
	write_aux sb, \args
.endm

.macro	write16	args:vararg
	write_aux sh, \args
.endm

.macro	write32	args:vararg
	write_aux sw, \args
.endm

.macro	write_aux wfun, item, dest, ofst
	// in:	wfun	<- write function	(str, strh or strb)
	// in:	item	<- item to write	(register or immediate)
	// in:	dest	<- destination		(register or address)
	// in:	ofst    <- destination offset	(immediate only?)
  check_if_reg \dest
  .ifeq item_is_reg_flag
	set	rva, \dest		// rva <- dest
	write_aux \wfun, \item, rva, \ofst
  .else
    check_if_reg \item
    .ifeq item_is_reg_flag
	set	rvb, \item		// rvb <- item
	write_aux \wfun, rvb, \dest, \ofst
    .else
      check_if_reg \ofst
      .ifeq item_is_reg_flag
	\wfun	\item, \ofst(\dest)
      .else
	\wfun\()_r \item, \dest, \ofst
      .endif
    .endif
  .endif
.endm


.macro	set dest, src
  check_if_reg \src
  .if item_is_reg_flag
	mv	\dest, \src
  .else
    check_if_nongc_reg \dest
    .if item_is_nongc_reg_flag
	li	\dest, \src
    .else
      .if  \src >= -2048 && \src <= 2047
	addi	\dest, zro, \src
      .else
	.warning "possible gc conflict (lui/addi). Try: setobj \dest,\src,imm"
       .if bitpwd == 32
	lui	\dest, %hi(\src)
	addi	\dest, \dest, %lo(\src)
       .else
	li	\dest, \src
       .endif
      .endif
    .endif
  .endif
.endm

.macro	setobj reg, arg1, optarg=rva, tmp=rva
  .ifeqs "\optarg","imm"
	setvarval \reg, \arg1, \tmp
  .else
	setlabel \reg, \arg1, \optarg, \tmp
  .endif
.endm

.macro	setvarval reg, varval, tmp=rva
	// Note: tmp must be non-gc reg (dflt: rva == x10)
	// li is multistep pseudo instruction
  check_if_nongc_reg \reg
  .if item_is_nongc_reg_flag
	li	\reg, \varval
  .else
    .if  \varval >= -2048 && \varval <= 2047
	addi	\reg, zro, \varval
    .else
      .if bitpwd == 32
	lui	\tmp, %hi(\varval)
	addi	\reg, \tmp, %lo(\varval)
      .else
	li	\tmp, \varval
	set	\reg, \tmp
      .endif
    .endif
  .endif
.endm

.macro	setlabel reg, label, optarg=rva, tmp=rva
	// Note: tmp must be non-gc reg (dflt: rva == x10)
	// if reg is gceable, the 1st step below can cause problems,
	// it might be necessary to use a temp reg ... although
	// top 20-bits would indicate label is not in heap so gc hazard
	// should not occur ...
	// BUT, the 20-bit offset is added to PC (step 1) and then
	// a signed 12-bit value is added to the result
  .if bitpwd == 32
    check_if_nongc_reg \reg
    .if item_is_nongc_reg_flag
323:	auipc	\reg, %pcrel_hi(\label)		// reg <- high 20-bit unsigned relative to pc
	addi	\reg, \reg, %pcrel_lo(323b)	// reg <- completed address
     .else
323:	auipc	\tmp, %pcrel_hi(\label)		// tmp <- high 20-bit unsigned relative to pc
	addi	\reg, \tmp, %pcrel_lo(323b)	// reg <- completed address
     .endif
  .else
    check_if_nongc_reg \reg
    .if item_is_nongc_reg_flag
	la	\reg, ofst_\label
	add	\reg, \reg, gp
    .else
	la	\tmp, ofst_\label
	add	\reg, \tmp, gp
    .endif
  .endif
.endm

//------------------------------------------------------------------------------
// wait for countdown
//------------------------------------------------------------------------------

.macro	wait	arg1, arg2:vararg
  .ifb \arg2
	wait	rvb, \arg1
  .else
	set	\arg1, \arg2
100:	add	\arg1, \arg1, -1
	bnez	\arg1, 100b
  .endif
.endm

//------------------------------------------------------------------------------
// special instructions for RISC-V (custom-0, custom-1)
//------------------------------------------------------------------------------

	// custom-0 instructions
.macro	lb_r rd, rs1, rs3	// R4-type, rs3 is offset register
	.insn	r 0x0b, 0x00, 0x00, \rd, \rs1,zro,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

.macro	lh_r rd, rs1, rs3
	.insn	r 0x0b, 0x01, 0x00, \rd, \rs1,zro,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

.macro	lw_r rd, rs1, rs3
	.insn	r 0x0b, 0x02, 0x00, \rd, \rs1,zro,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

.macro	ld_r rd, rs1, rs3
	.insn	r 0x0b, 0x03, 0x00, \rd, \rs1,zro,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

.macro	lbu_r rd, rs1, rs3
	.insn	r 0x0b, 0x04, 0x00, \rd, \rs1,zro,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

.macro	lhu_r rd, rs1, rs3
	.insn	r 0x0b, 0x05, 0x00, \rd, \rs1,zro,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

.macro	lwu_r rd, rs1, rs3
	.insn	r 0x0b, 0x06, 0x00, \rd, \rs1,zro,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

	// custom-1 instructions

.macro	sb_r rs2, rs1, rs3	// R4-type, rs3 is offset register
	.insn	r 0x2b, 0x00, 0x00, zro, \rs1,\rs2,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

.macro	sh_r rs2, rs1, rs3	// R4-type, rs3 is offset register
	.insn	r 0x2b, 0x01, 0x00, zro, \rs1,\rs2,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

.macro	sw_r rs2, rs1, rs3	// R4-type, rs3 is offset register
	.insn	r 0x2b, 0x02, 0x00, zro, \rs1,\rs2,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm

.macro	sd_r rs2, rs1, rs3	// R4-type, rs3 is offset register
	.insn	r 0x2b, 0x03, 0x00, zro, \rs1,\rs2,\rs3	// op,f3,f2,rd,rs1,rs2,rs3
.endm



