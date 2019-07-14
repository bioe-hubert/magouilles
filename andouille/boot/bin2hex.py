#!/usr/bin/env python3

import struct
import sys


def main(argv0, nbits, in_name, out_name):
	with open(in_name, 'rb') as in_fh, open(out_name, 'w') as out_fh:
		while True:
			b = in_fh.read(4)
			if len(b) < 4:
				return
			if nbits == '64':
				c = in_fh.read(4)
				if len(c) < 4:
					out_fh.write('00000000%08x\n' % struct.unpack('<I', b))
					return
				out_fh.write('%08x' % struct.unpack('<I', c))
			out_fh.write('%08x\n' % struct.unpack('<I', b))

if __name__ == '__main__':
	main(*sys.argv)
