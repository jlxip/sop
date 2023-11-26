; This is an example program for sop
; Compile it, join it with sop, and run:
; l 8000, 1
; c 8000

ORG 0x8000
BITS 16

%include "symbols.txt"

mov di, helloworld
jmp SOP_printz ; or "call SOP_printz" and "ret"

helloworld db "Hello world!", 0x0A, 0