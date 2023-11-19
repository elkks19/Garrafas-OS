org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A


start:
	jmp main


;prints a string to the screen 
;Params: 
;	DS:SI - pointer to string
puts:
	;save registers
	push si
	push ax

.loop
	lodsb			;load next char into al
	or al, al		;check if next char is null
	jz .done		;if null, we're done

	mov ah, 0x0E		;print char, calling BIOS interrupt
	mov bh, 0x00		;page number
	int 0x10
	jmp .loop

.done:
	pop ax
	pop si
	ret



main:
	;setup data segments
	mov ax, 0 	    ;no se puede escribir en ds/es directamente
	mov ds, ax
	mov es, ax

	;setup stack
	mov ss, ax
	mov sp, 0x7C00	;el stack crece hacia atras, asi que lo ponemos al inicio del OS

	;print message
	mov si, msg
	call puts
	
	hlt


.halt:
	jmp .halt


msg: db'Hello World!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
