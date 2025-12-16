; Screen operations

curword equ $ ; neat hack
curx    db  0 ; screen column
cury    db  0 ; screen row

; 8086-safe save/restore for some registers
%macro pushall 0
    push ax
    push bx
    push di
%endmacro

%macro popall 0
    pop di
    pop bx
    pop ax
%endmacro

; --- internal: write char to framebuffer ---
; assumes es is set to FRAMEBUFFER
; dh <- char
; ch <- row
; cl <- column
; trashes: ax, bx
_fbwrite:
    ; [es:2*(COLS*row + column)] = character
    mov al, ch
    mov bl, COLS
    mul bl
    mov bx, ax
    xor ah, ah
    mov al, cl
    add bx, ax
    shl bx, 1
    mov byte [es:bx], dh
    ret

; --- PRINT ONE CHARACTER ---
; dh <- char
print_char:
    pushall
    push es
    ;------
    mov ax, FRAMEBUFFER
    mov es, ax
    ; Get cursor position
    mov cx, word [curword] ; ch=row, cl=col
    ; Backspace?
    cmp dh, BACKSPACE
    jz .backspace
    ; Needs scroll?
    cmp ch, ROWS
    jb .noscroll
    call _scroll
    xor cl, cl
    dec ch
  .noscroll:
    ; \n?
    cmp dh, NEWLINE
    jz .nextline
    ; Write
    call _fbwrite
    ; Next line?
    cmp cl, COLS-1
    jae .nextline
    inc cl
    jmp short .out
  .backspace:
    dec cl
    jno .remove
    ; Overflow, so go to previous line
    mov cl, COLS-1
    dec ch
    ; No scroll up implemented 🥸
  .remove:
    ; Write null byte
    xor dh, dh
    call _fbwrite
    jmp short .out
  .nextline:
    inc ch
    xor cl, cl
  .out:
    mov word [curword], cx ; writeout
    ;-----
    pop es
    call _update_cur
    popall
    ret

; --- internal: UPDATE CURSOR ---
_update_cur:
    ; int 10/ah=02h - video - set cursor position
    mov ah, 0x02
    xor bh, bh
    mov dx, word [curword]
    int 10h
    ret

; --- internal: scroll screen ---
; assumes es is set to FRAMEBUFFER
; does not touch cury or curx
_scroll:
    push ds
    ;------
    mov ax, word [color-1] ; Load color before ds change
    mov bx, FRAMEBUFFER
    push bx
    pop ds
    ; Move up
    mov si, 2 * COLS
    xor di, di
    mov cx, 2 * (ROWS-1) * COLS ; *2 needed here because:
    rep movsb ; movsb instead of movsw for FSO
    ; Clear last line
    mov di, 2 * (ROWS-1) * COLS
    mov cx, COLS
    rep stosw ; same as below, it's fine
    ;------
    pop ds
    ret

; --- PRINT ---
; di <- message (trashes it)
; trashes: dh
printz:
  .loop:
    mov dh, byte [di]
    test dh, dh
    jz .out
    call print_char

    inc di
    jmp short .loop
  .out:
    ret

; --- CLEAR ---
clear:
    push es
    ;------
    mov ax, FRAMEBUFFER
    mov es, ax
    xor di, di
    db 0xB8 ; mov ax, 16-bit immediate
    db 0x00 ; LSB
    color: db DEFAULTCOLOR
    mov cx, ROWS * COLS
    rep stosw ; this does cx-=1 and di+=2
    xor ax, ax
    mov word [curword], ax
    ;-----
    pop es
    jmp short _update_cur
