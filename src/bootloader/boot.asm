org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;
; FAT12 header
;

jmp short start
nop

bdb_oem:						db "MSWIN4.1"			;8 bytes
bdb_bytes_per_sector:			dw 512
bdb_sectors_per_cluster:		db 1
bdb_reserved_sectors:			dw 1
bdb_fat_count:					db 2
bdb_dir_entries:				dw 0E0h
bdb_total_sectors:				dw 2880					;2880 * 512 = 1.44MB
bdb_media_descriptor_type:		db 0F0h
bdb_sectors_per_fat:			dw 9
bdb_sectors_per_track:			dw 18
bdb_heads:						dw 2
bdb_hidden_sectors:				dd 0
bdb_large_sector_count:			dd 0


; extended boot record
ebr_drive_number:				db 0
								db 0					;reserved
ebr_ext_boot_signature:			db 29h					;can be 28h or 29h
ebr_volume_id:					dd 12h, 34h, 56h, 78h	;serial number, value doesn't matter
ebr_volume_label:				db "RAFAEL XDDD"		;11 bytes
ebr_system_id:					db "FAT12   "			;8 bytes

;
; de aqui en adelante, el codigo
;



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

	; leer de un floppy
	; la BIOS deberia setear DL con el numero de drive
	mov [ebr_drive_number], dl

	mov ax, 1 		; LBA = 1, segundo sector del disco
	mov cl, 1		; leer un sector
	mov bx, 0x7E00	; los datos deberian estar despues del bootloader
	call disk_read

	;print message
	mov si, msg
	call puts
	
	hlt


;
; Error handling
;

floppy_error:
	mov si, floppy_error_msg
	call puts
	jmp wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 16h							; espera a que se presione una tecla
	jmp 0FFFFh:0					; reinicia el sistema


.halt:
	cli								; deshabilita interrupciones, así el sistema no puede salir de halt
	hlt



;
; Disk routine
;


;
; Convierte una direccion LBA a CHS
;
; Params: 
; 	ax - dirección LBA
; Returns:
; 	cx (bits 0-5): sector number
; 	cx (bits 6-15): cylinder
;   dh: head

lba_to_chs:

	push ax
	push bx

	xor dx, dx							; dx = 0
	div word [bdb_sectors_per_track]	; ax = LBA / sectors_per_track
										; dx = LBA % sectors_per_track

	inc dx								; dx = (LBA % sectors_per_track) + 1 = sector
	mov cx, dx							; cx = sector

	xor dx, dx							; dx = 0
	div word [bdb_heads]				; ax = LBA / sectors_per_track / heads = cylinder
										; dx = LBA / sectors_per_track % heads = head

	mov dh, dl							; dh = head
	mov ch, al							; ch = cylinder (primeros 8 bits)
	shl ah, 6
	or cl, ah							; cl = cylinder (ultimos 2 bits) + sector

	pop ax
	mov dl, al							; restore dl
	pop ax
	ret
	

;
; Lee un sector del disco
; 
; Params:
;   ax = direccion LBA
;	cl = numero de sectores a leer (max 128)
;   dl = drive number
;	es:bx = direccion de memoria donde se guardan y leen datos
;

disk_read:

	push ax
	push bx
	push cx								; guardamos los registros que vamos a cambiar
	push dx
	push di

	push cx								; guarda temporalmente cl (numero de sectores a leer) 
	call lba_to_chs						; calcula CHS
	pop ax								; al = numero de sectores a leer

	mov ah, 02h
	mov di, 3							; intentos para leer

.retry:
	pusha								; guarda todos los registros, no se sabe que hace la BIOS xd
	stc									; setea el carry flag para indicar error, algunos BIOS no lo hacen
	int 13h								; si el carry flag esta limpio, se leyo correctamente
	jnc .done

	; la lectura falla
	popa
	call disk_reset						; si no, resetea el disco y vuelve a intentar

	dec di								; decrementa el contador de intentos
	test di, di							; si el contador es 0, se acabaron los intentos
	jnz .retry							; si no, vuelve a intentar

.fail:
	; si despues de los intentos no se pudo leer, se muestra un error
	jmp floppy_error


.done:
	popa
	push di
	push dx
	push cx								; restauramos los registros modificados
	push bx
	push ax
	ret

;
; Resetea el controlador del disco
;
; Params:
;	dl = drive number
;
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc floppy_error
	popa
	ret


	





msg: db'Hello World!', ENDL, 0
floppy_error_msg: db 'Error al leer el disco', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
