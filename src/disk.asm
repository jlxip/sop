; ch <- cylinder
; dh <- head
; cl <- sector
; bx <- address
; Trashes: si, ax, dl
readsect:
    ; Try to read five times
    mov si, 5
    ; Read
    mov dl, byte [BOOTDRIVE]
    mov al, 1 ; 1 sector
.try:
    mov ah, 02h
    int 13h
    jc .retry
    ret
    ; Retry
.retry:
    ; Reset disk
    xor ah, ah
    int 13h

    dec si
    mov dh, '!'
    call print_char
    jmp cmd
