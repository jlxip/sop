; sop is done, this is the beginning of another file.
; It's compiled together for simplicity, but it will
;   be split later by the Makefile

; This is made as comfortable as possible to use
; Just "%include symbols.txt" and you have the API

; Unfortunately, it appears that it's not possible to
; convert addresses to hex. Not even with macros, since
; bit operations cannot be applied to compile-time addresses
; Therefore, this needs a python script to be converted

%macro addrsymbol 1
    db %str(%1), 0, 2
    dw %1
%endmacro

; --- Strings and such
db "RELEASE", 0, 1, RELEASE
; --- Fixed addresses
addrsymbol BOOTDRIVE
addrsymbol KBD_BUFF
; --- Compile-time addresses
; sop.asm
addrsymbol BOOTDRIVE
addrsymbol ENTRYPOINT
addrsymbol KBD_BUFF
addrsymbol AUTOLOAD_ADDR
addrsymbol start
addrsymbol readsect
addrsymbol _init_cs
addrsymbol cmd
addrsymbol _split
addrsymbol _execute
addrsymbol commands
addrsymbol popper
addrsymbol release
; screen.asm
addrsymbol _fbwrite
addrsymbol print_char
addrsymbol _update_cur
addrsymbol _scroll
addrsymbol printz
addrsymbol clear
addrsymbol color
; kbd.asm
addrsymbol get_char
addrsymbol get_line
; commands.asm
addrsymbol cmd_load
addrsymbol _cmd_load
addrsymbol cmd_call
addrsymbol _cmd_call
addrsymbol hex2word

db 0 ; Terminator
