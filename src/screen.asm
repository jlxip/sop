; Screen operations

curword equ $ ; neat hack
curx    db  0 ; screen column
cury    db  0 ; screen row

; --- internal: write char to framebuffer ---
; assumes es is set to FRAMEBUFFER
; dh <- char
; ch <- row
; cl <- column
_fbwrite:
    pusha
    ;----
    ; [es:2*(COLS*row + column)] = character
    xor ah, ah
    mov al, ch
    mov bl, COLS
    mul bl
    mov bx, ax
    xor ah, ah
    mov al, cl
    add bx, ax
    shl bx, 1
    mov byte [es:bx], dh
    ;---
    popa
    ret

; --- PRINT ONE CHARACTER ---
; dh <- char
print_char:
    pusha
    push es
    ;------
    push FRAMEBUFFER
    pop es
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
    ; Fallthrough to _update_cur

; --- internal: UPDATE CURSOR ---
; Expects pusha (so jmp only, no call) because it does popa
_update_cur:
    ; int 10/ah=02h - video - set cursor position
    mov ah, 0x02
    xor bh, bh
    mov dx, word [curword]
    int 10h
    popa ; !!
    ret

; --- internal: scroll screen ---
; assumes es is set to FRAMEBUFFER
; does not touch cury or curx
_scroll:
    pusha
    push ds
    ;------
    mov ax, word [color-1] ; Load color before ds change
    push FRAMEBUFFER
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
    popa
    ret

; --- PRINT ---
; di <- message (trashes it)
printz:
    push dx
    ;------
  .loop:
    mov dh, byte [di]
    test dh, dh
    jz .out
    call print_char

    inc di
    jmp short .loop
  .out:
    ;-----
    pop dx
    ret

; --- CLEAR ---
clear:
    pusha
    push es
    ;------
    push FRAMEBUFFER
    pop es
    xor di, di
    db 0xB8 ; mov ax, 16-bit immediate
    db 0x00 ; LSB
    color: db DEFAULTCOLOR
    mov cx, ROWS * COLS
    rep stosw ; this does cx-=1 and di+=2
    mov word [curword], 0
    ;-----
    pop es
    jmp short _update_cur ; this does popa

; --- macro: ENABLE CURSOR ---
; destroys ah, cx
%macro enable_cur 0
    mov cx, CURSOR_SHAPE
    reshape_cur
%endmacro

; --- macro: DISABLE CURSOR ---
; destroys ah, cx
%macro disable_cur 0
    mov cx, CURSOR_DISABLE
    reshape_cur
%endmacro

; --- internal macro: reshape cursor ---
; cx <- cursor shape
; destroys ah
%macro reshape_cur 0
    ; int 10/ah=01h - video - set text-mode cursor shape
    mov ah, 0x01
    int 10h
%endmacro
