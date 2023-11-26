#!/usr/bin/env python3

import sys

with open(sys.argv[1], 'rb') as f:
	raw = f.read()

entries = {}
while raw[0]:
	# Get the name
	idx = 1
	while raw[idx]: idx += 1
	name = raw[:idx].decode()
	raw = raw[idx+1:]

	# Get actual data
	datasize = raw[0]
	data = raw[1:1+datasize]
	raw = raw[1+datasize:]

	# Switch endianess
	data = bytes(list(data)[::-1])

	entries[name] = data.hex()

data = '; symbols.txt for sop %s\n' % chr(bytes.fromhex(entries['RELEASE'])[0])
for i in sorted(entries.keys()):
	entry = entries[i]
	data += 'SOP_%s equ 0x%s\n' % (i, entry)

data += '''
; Compare versions at runtime
cmp byte [SOP_release], SOP_RELEASE
jz SOP_release_check_good

; Assuming es=0xB800 (default value at command entry)
mov al, byte [SOP_release]
mov byte [es:0], al
mov byte [es:1], 0xCF
mov byte [es:2], SOP_RELEASE
mov byte [es:3], 0xCF
jmp $

SOP_release_check_good:
'''

with open(sys.argv[2], 'w') as f:
	f.write(data)
