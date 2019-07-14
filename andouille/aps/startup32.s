//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

_text_sect_adrs_	= 0x00
_text_link_adrs_	= 0x00
_data_sect_adrs_	= _text_sect_adrs_+(((end_of_code+15-start_of_code)>>4)<<4)+64+64

//_data_link_adrs_	= _text_link_adrs_+(((end_of_code+15-start_of_code)>>4)<<4)+64+64
//_data_link_adrs_	= 0x10000000	// data  SPRAM (64KB)
_data_link_adrs_	= 0x20000000	// extra RAM   (8KB)
//_data_link_adrs_	= 0xf0000000	// boot  RAM   (2KB)


// include 32-bit constants and common macros
.include	"aps_constants32.s"
.include	"aps_macros.s"

// include common startup (aps) code
.include	"startup.s"



