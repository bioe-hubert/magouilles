//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

.global	_start

.text

_start:	// first instruction
	write	0x01, io0_base, io_dir		// set flash CSn gpio pin to output
	// send command 0xff
	bl	spisel				// select spi chip
	set	rvb, 0xff
	bl	spidat				// send command 0xff
	bl	spidsl				// de-select spi chip
	// send command 0xab
	bl	spisel				// select spi chip
	set	rvb, 0xab
	bl	spidat				// send command 0xab
	bl	spidsl				// de-select spi chip
	// send command 0x03
	bl	spisel				// select spi chip
	set	rvb, 0x03
	bl	spidat				// send command 0x03 = read
	set	rvb, 0x10
	bl	spidat				// send read-address top    byte
	bl	spiwr0				// send read-address middle byte (zero)
	bl	spiwr0				// send read-address low    byte (zero)
	// copy app from flash to code and data RAM
	setobj	sv2, cram_base, imm		// sv2 <- dest in code ram
	setobj	sv4, dram_base, imm		// sv4 <- dest in data ram
	setobj	sv3, copy_size, imm		// sv3 <- num bytes to copy
	set	sv5, zro			// sv5 <- start offset
cploop:	// copy loop
	bl	spiwr0				// rvb <- data byte read-in
	write8	rvb, sv2, sv5
	write8	rvb, sv4, sv5
	add	sv5, sv5, 1
	blt	sv5, sv3, cploop
	bl	spidsl				// de-select spi chip
	// jump to copied code
	set	lnk, 0
	ret

spiwr0:	// write 0 to spi (eg. to read data)
	set	rvb, zro
spidat:	// in:	 rvb <- byte to write to spi chip
	// out: rvb <-	byte read back from spi chip
	write	rvb, spi0_base, spi_thr
spidwt:	read	rvb, spi0_base, spi_status
	beqz	rvb, spidwt
	read	rvb, spi0_base, spi_rhr
	ret

spisel:	// set CSn low (select chip)
	write	0x01, io0_base, io_clear
	ret

spidsl:	// set CSn high (de-select chip)
	write	0x01, io0_base, io_set
	ret

.end



