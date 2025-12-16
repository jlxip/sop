; sop - Sector OPerations release 2
; by @jlxip, 2025-12-16
; All the code in src/ is under GPLv3.

; --- sop memory map ---
;  ...  -0x7BF7         <- stack
; 0x7BF8-0x7BFF (0x002) <- boot drive (first push)
; 0x7C00-0x7DFF (0x200) <- sop
; 0x7E00-0x7EFF (0x100) <- kbd line buffer
; 0x8000-0x8100 (0x100) <- autoloader buffer

; --- Constants you might want to change ---
DEFAULTCOLOR   equ 0x0F   ; white on black (Darwin-like)
CURSOR_SHAPE   equ 0x0E0F ; underscore-like appearance
; --- Actual constants ---
RELEASE        equ "2"

BOOTDRIVE      equ 0x7BFE
ENTRYPOINT     equ 0x7C00
KBD_BUFF       equ 0x7E00
AUTOLOAD_ADDR  equ 0x8000
FRAMEBUFFER    equ 0xB800

AUTOLOAD_MARK  equ 0x69

NEWLINE        equ 0x0A
BACKSPACE      equ 0x08
ROWS           equ 25     ; Asserted
COLS           equ 80     ; Asserted
CURSOR_DISABLE equ 0x1000 ; bit 5 disables cursor

; ------------------------------------------------------------------------------

CPU 8086
ORG 0x7C00
BITS 16

start:
    cli ; No interrupts for vanilla sop
    xor ax, ax ; used below, the code is fractioned
    jmp 0x0000:_init_cs ; Assert CS selector

%include "disk.asm"

_init_cs:
    cld ; String operations always up
    ; Assert sane rest of selectors
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ENTRYPOINT ; Stack above this code
    ; We now have a stack
    push dx ; dl has boot drive
    ; sp right now is BOOTDRIVE

    ; Assert video mode 3
    mov al, 03h ; Note that ah=0
    int 10h

    ; Welcome!
    call clear
    mov di, project
    call printz

    ; Autoloader
    mov cx, 2
    xor dh, dh
    mov bx, AUTOLOAD_ADDR
    call readsect
    cmp byte [bx], AUTOLOAD_MARK
    jz AUTOLOAD_ADDR + 1

cmd:
    ; Prompt
    mov dh, '>'
    call print_char
    call get_line ; bx = line size
    ; fallthrough to split

_split:
    ; Split command into space-separated parts
    ; We go backwards
    xor ax, ax
    push ax ; Terminate list of separations
  .next:
    dec bx ; Start at the last character
    js .afterzero ; Overflown, go to last step
  .loop:
    mov al, byte [KBD_BUFF + bx] ; Get the character
    cmp al, ' '
    jnz .next ; Regular character, keep going
    ; At this point, character is a space
    mov byte [KBD_BUFF + bx], 0 ; Null-terminate it
    ; If next character is not null, then it's the beginning
    ; of a part
    lea si, [KBD_BUFF + bx + 1]
    cmp byte [si], 0
    jz .next ; Not a good part
    ; Nice
    push si
    ; And we keep going
    jmp short .next
  .afterzero:
    ; If the first character is not a space, it's the
    ; beginning of a part
    cmp byte [KBD_BUFF], 0
    jz _execute
    mov ax, KBD_BUFF
    push ax

_execute:
    ; Command has been split
    pop bp
    test bp, bp ; no command? :(
    jz cmd

    ; Get the length
    mov di, bp
    xor al, al ; compare to \0
    mov cl, 255
    repnz scasb
    mov dx, di ; byte after \0
    sub dx, bp ; length
    ; command @ bp

    ; Iterate through commands, comparing
    ; Load the commands array into bx, do it saving the symbol
    ; for the address of the array, so it can be monkeypatched
    db 0xBB ; mov bx, 16-bit immediate
    commands: dw commands_ptr
  .loop:
    mov di, word [bx]
    test di, di
    jz .fail

    mov cx, dx
    mov si, bp
    repe cmpsb ; Gotta love CISC
    jne .next ; failed

    ; Match! Considering no state has to be saved but the stack,
    ; this leaves virtually all registers free to be trashed,
    ; which gives a lot of initial flexibility to the command,
    ; almost as if it was an actual main()
    call di ; ✨
    ; Clean up stack and that's it
    jmp short popper
  .next:
    ; add 2 for being a word
    inc bx
    inc bx
    jmp short .loop
  .fail:
    mov dh, '?'
    call print_char

popper:
    ; Pop arguments from the stack
    ; This is the other end of "split", it's called when
    ; the execution of the command is finished
    pop ax
    test ax, ax
    jnz popper
    ; Here we go again
    jmp short cmd

; Auxiliary files
%include "screen.asm"
%include "kbd.asm"
%include "commands.asm"

; End
times 510-8-($-$$) db 0
project: db "sop "
release: db RELEASE ; This address is fixed
db 0x0A, 0x0A, 0
times 510-($-$$) db 0 ; Pad to 510 bytes
dw 0xAA55 ; Boot signature

%include "symbols.asm"
