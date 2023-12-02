; This is an example program for sop: color
; Compile it and join it with sop

ORG 0x8000
BITS 16

; This is the autoload mark. Lets sop know that it
; should automatically run "l" and "c" on it.
db 0x69

%include "symbols.txt"

; Monkeypatch the commands array pointer
mov word [SOP_commands], commands_ptr
; This is an autoload, there's nothing on the stack
; Instead of ret, one must do:
jmp SOP_cmd

; New commands array. This should be done dynamically so
;   this operation does not interfere with other commands
;   from other extensions. This approach is simpler though,
;   which is fine for an example.
commands_ptr:
	dw SOP_cmd_load
	dw SOP_cmd_call
	dw cmd_color
	dw 0

; color command
cmd_color: db "color", 0
_cmd_color:
	pop bp ; return
	pop bx ; first argument
	; Here I'm reusing sop's hex2word in order to avoid
	;   a hex2bytes implementation. However, this does
	;   mean that the user needs to enter four characters.
	; A better one could be easily implemented.
	call SOP_hex2word
	; Monkeypatch SOP_color
	mov byte [SOP_color], al
	; Finally, clear the window so this applies. You could
	; also reboot sop by jumping to SOP_start (or SOP_ENTRYPOINT)
	push bp
	jmp SOP_clear
	; Naive but simpler way to do it:
	;   call SOP_clear
	;   push bp
	;   ret
