//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

// set data link address to agree with low_peripherals in aps_constants64.s
// and with peripherals address space (low or high) uncommented in riscv/soc64.vh

_text_sect_adrs_	= 0x00
_text_link_adrs_	= 0x00
_data_sect_adrs_	= _text_sect_adrs_+(((end_of_code+15-start_of_code)>>4)<<4)+64+64

//_data_link_adrs_	= _text_link_adrs_+(((end_of_code+15-start_of_code)>>4)<<4)+64+64
//_data_link_adrs_	= 0x10000000		// data RAM-lo (4KB)
//_data_link_adrs_	= 0xf0000000		// boot RAM-lo (2KB)
_data_link_adrs_	= 0x1000000000000000	// data RAM-hi (4KB)
//_data_link_adrs_	= 0xf000000000000000	// boot RAM-hi (2KB)


// include 64-bit constants and common macros
.include	"aps_constants64.s"
.include	"aps_macros.s"

// include common startup (aps) code
.include	"startup.s"



