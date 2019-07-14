//------------------------------------------------------------------------------
//  ANDOUILLE Artifact, MAGOUILLES Project, Distributed under The MIT License.
//  Copyright (c) 2019 Hubert Montas
//------------------------------------------------------------------------------

// include 64-bit constants and common macros
.include	"aps_constants64.s"
.include	"aps_macros.s"

// set size of aps code to copy (eg. based on destination RAM size)
copy_size	= 0x1000		// 4KB of code to copy from flash

// include common boot code
.include	"boot.s"



