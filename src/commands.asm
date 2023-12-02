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
    ; Convert arguments from hex and store in dapack
    pop bx
    call hex2word
    mov word [dapack_offset], ax
    pop bx
    call hex2word
    mov word [dapack_lba], ax
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
; trashes cx
hex2word:
    xor ax, ax
  .loop:
    mov cl, byte [bx]
    test cl, cl
    jz .end
    bt cx, 6
    jnc .thisdone
    add cl, 9
  .thisdone:
    and cl, 0xF
    shl ax, 4
    or al, cl
    inc bx
    jmp short .loop
  .end: ret
