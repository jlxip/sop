; Again, this address is aligned to 8 bytes
; dapack structure, defaults are for autoload
align 8
dapack:
    db 0x10 ; structure size
    db 0x00 ; mbz
    dw 0x01 ; number of blocks
    dapack_offset: dw AUTOLOAD_ADDR
    dw AUTOLOAD_SECT ; segment
    dapack_lba: dq AUTOLOAD_LBA ; sector

; Now that we're at it, let's put here the int 13h routine
; Expects dapack to be filled
; trashes: dl, si, ah, carry
readsect:
    ; int 13h/ah=42h - extended read
    mov dl, byte [BOOTDRIVE]
    mov si, dapack
    mov ah, 42h
    int 13h
    ret
