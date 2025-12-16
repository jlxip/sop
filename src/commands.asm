; This file implements a heavily optimized (memory-wise) command array
; The entries are pointers; NULL ends the array
; The pointer points to a NULL-terminated string with the name of the command
; After the NULL byte, the implementation starts

commands_ptr:
    dw cmd_load
    dw cmd_call
    dw 0

cmd_load: db "l", 0
_cmd_load:
    pop bp
    pop bx ; addr
    call hex2word
    mov si, ax
    pop bx ; cylinder
    call hex2word
    mov ch, al
    pop bx ; head
    call hex2word
    mov dh, al
    pop bx ; sector
    call hex2word
    mov cl, al

    mov bx, si
    push bp
    jmp readsect

cmd_call: db "c", 0
_cmd_call:
    pop bp
    pop bx
    push bp ; return point
    call hex2word
    jmp ax ; ✨

; --- HEX TO WORD ---
; bx <- ptr to hex in big-endian caps (trashed)
; ax is output
; trashes: cl, dl
hex2word:
    xor ax, ax
  .loop:
    mov dl, byte [bx]
    test dl, dl
    jz .end
    cmp dl, '9'
    jbe .digit
    sub dl, 7
  .digit:
    sub dl, '0'
    mov cl, 4
    shl ax, cl
    or al, dl
    inc bx
    jmp short .loop
  .end:
    ret
