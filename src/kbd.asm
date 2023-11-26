; --- READ CHARACTER ---
; output in al, trashes ah
get_char:
    ; int 16h/ah=00h - keyboard - get keystroke
    xor ax, ax
    int 16h
    ; Translate 0x0D (return) to 0x0A (\n)
    cmp al, 0x0D
    jne .out
    mov ax, 0x0A
  .out: ret

; --- READ LINE ---
; Sets bx to the used size of the buffer
; Destroys cx
get_line:
    push ax
    push dx
    ;------
    enable_cur
    xor bx, bx ; bl <- line buffer size
  .loop:
    call get_char
    mov dh, al ; for print_char
    ; Backspace?
    cmp al, BACKSPACE
    jz .backspace
    ; Return?
    cmp al, NEWLINE
    jz .out
    ; It's a regular character
    ; Full buffer?
    cmp bl, 255
    jae .loop ; ignore keypress
    ; Alright go ahead
    call print_char
    mov byte [KBD_BUFF + bx], al
    inc bl
    jmp short .loop
  .backspace:
    test bl, bl
    jz .loop ; nothing to delete!
    call print_char
    dec bl
    jmp short .loop
  .out:
    ; Print newline (only way to get here)
    call print_char
    ; Null-terminate it
    mov byte [KBD_BUFF + bx], 0
    disable_cur
    ;-----
    pop dx
    pop ax
    ret
