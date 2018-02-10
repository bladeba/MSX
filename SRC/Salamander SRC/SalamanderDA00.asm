;Salamander in DDA0h

;*** FLP.COM v1.65 for MSX

;*** ROM Loader for MegaflashROM mapped Konami SCC

; Assembled with zasm cross assembler
; http://sourceforge.net/projects/zasm/


WRTVDP	equ	0D23Ch		;my routine
SETRD	equ	00050h
SETWRT	equ	00053h


VDP_REGISTER_0	equ	0f3dfh
iniline	equ	0FB00h

BDOSADR	equ	05h
RDSLT	equ	0Ch
CALSTL	equ	01Ch

EXPTBL	equ	0FCC1h
CSRSW	equ	0FCA9h

CPU_type equ	0002Dh
VARBASIC equ	0F7F8h
EXTVDP	equ	0FFE7h
R_MROM	equ	0F9a8h
LF	equ	0ah
CR	equ	0dh
BDOS	equ	00005h
WRSLT	equ	00014h
CALSLT	equ	0001Ch
ENASLT	equ	00024h
FCB	equ	0005ch
DMA	equ	00080h
RAMAD1	equ	0f342h
RAMAD2	equ	0f343h
BUFTOP	equ	08000h
CHGET	equ	0009fh
MNROM	equ	0FCC1h	; Main-ROM Slot number & Secondary slot flags table
DRVINV	equ	0FB22H	; Installed Disk-ROM
SNSMAT	equ	00141H	;key pressed CALL 
			;Input    : A  - for the specified line
			;Output   : A  - for data (the bit corresponding to the pressed key will be 0)
	
	
bad_ending 	equ	0f500h

voices 		equ	0f502h
lenguage_txt	equ	0f504h
cool_colors	equ	0f506h
line_interrupt 	equ	0f501h	;emulator 165	MSX: 166
nochangeMAP	equ	0f530h

	
	
	
	
	
	
	org	0DDBBh


	

S_ORIGEN	equ	origenIX+2
S_DESTINO	equ	origenIY+2






fastblock:	
		DI
origenIY:	LD	IY,0000		;DESTINO FONDO STARFIELD
origenIX:	LD	IX,0000		;ORIGEN
		LD	(STACK),SP			;GUARDA PILA
		LD	A,0300h/020h			;$300 BYTES		
		LD	(BLOCK16),A
FASTBLOCKBC0:	DI
		LD	SP,IX
		POP	AF
		POP	BC
		POP	DE
		POP	HL
		EXX
		EX	AF,AF'
		POP	AF
		POP	BC
		POP	DE
		POP	HL
		LD	SP,IY
		PUSH	HL
		PUSH	DE
		PUSH	BC
		PUSH	AF
		EX	AF,AF'
		EXX
		PUSH	HL
		PUSH	DE
		PUSH	BC
		PUSH	AF
		LD	BC,+010h
		ADD	IY,BC
		ADD	IX,BC
		
		LD	SP,IX
		POP	AF
		POP	BC
		POP	DE
		POP	HL
		EXX
		EX	AF,AF'
		POP	AF
		POP	BC
		POP	DE
		POP	HL
		LD	SP,IY
		PUSH	HL
		PUSH	DE
		PUSH	BC
		PUSH	AF
		EX	AF,AF'
		EXX
		PUSH	HL
		PUSH	DE
		PUSH	BC
		PUSH	AF
		LD	BC,-050h
		ADD	IY,BC
		ADD	IX,BC



		LD	HL,BLOCK16
		DEC	(HL)
		EI
		LD	SP,(STACK)
		
		JR	NZ,FASTBLOCKBC0
		
		RET

;---------------------------------------------------------------------------------------------

	
	nop

more_outis:
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ex	de,hl

	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi

	ex	de,hl
	dec	a
	jr	nz,more_outis
	ret
;-----------------------------------------------------------------------------------------------



writeinSCC:

	
	ld	a,03fh
	ld	(09000h),a
	xor	a
	ld	(0988fh),a
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ld	a,(0e1e9h)
	ld	(0988fh),a
	ld	a,5
	ld	(09000h),a
	ret

sounds_enter:

	
	ld	(nochangeMAP),a
	ei
	call	6472h		;put souns
	di
	xor	a
	ld	(nochangeMAP),a
	ret


VDP_update:

	


	call	511fh
	
	nop

	xor	a
	di
	out	(099h),a
	ld	a,27+128
	out	(099h),a

	xor	a
	
	out	(099h),a
	ld	a,090h
	ei
	out	(099h),a
	

	


	ld a,165	;interrupt line in 165
	out (#99),a
	ld a,19+128
	out (#99),a

	ld	bc,00619h	;activate horizontal scroll
	call	WRTVDP

	ld	bc,08005h	;SAT in 4000h
	call	WRTVDP

	ld	bc,000906h	;SPT in 4800h
	call	WRTVDP
	
	ld	bc,00009h	;put in 192 lines mode
	call	WRTVDP
	

	ld	a,5		;necesary for block transer to full VRAM!!!
	ld	(0fcafh),a

	
	ld	a,12h		; activate line interrupts
	out	(099h),a
	ld	a,0+128
	out	(099h),a


	xor	a		;read S#0 or it fails
	out	(099h),a
	ld	a,15+128
	out	(099h),a
	
	call	check_keys
	
	ret


;----------------------------------------


;--------------------------------------------------------------------------------------------------------------

check_keys:

	ld	a,(002bh)		;default lenguage
	ld	(lenguage_txt),a
	

	ld	a,02h
	call	SNSMAT
	bit 7,a	;"B" key	Bad ending
	ld	a,3
	jr	nz,K_bad
	xor	a
K_bad:	
	ld	(bad_ending),a
	ld	(0f0f5h),a


	ld	a,05h
	call	SNSMAT
	bit 7,a	;"V" key	Voice Set Disable
	ld	a,1
	jr	nz,K_voice
	xor	a
K_voice:	
	ld	(voices),a

	
	ld	a,03h
	call	SNSMAT
	ld	b,a

	bit	6,b	;"I" key	Invincible
	ld	a,0c0h
	jr	nz,K_invin
	ld	a,0c9h
K_invin:
	ld	(invincible),a
	
	push	bc
	
	ld	hl,inv_rutine
	ld	de,0f520h
	ld	bc,00008h
	ldir
	
	
	pop	bc


	ld	a,166
	ld	(line_interrupt),a

	
	push	bc
	bit	3,b	;"F" key	Frequency
	ld	a,1
	jr	nz,K_freq
	
	ld	hl,0ffe8h
	ld	a,(hl)
	xor	2
	ld	(hl),a


	
	ld	c,9
	ld	b,a
	call	WRTVDP
	


	

K_freq:	
	
	pop	bc

	bit	2,b	;"E" key	English text
	
	jr	nz,K_no_int
	ld	a,0FFh
	ld	(lenguage_txt),a

K_no_int:

	bit	7,b	;"J" key	Japanese text
	
	jr	nz,K_no_jap
	xor	a
	ld	(lenguage_txt),a

	
K_no_jap:	

	ld	a,(cool_colors)
	or	a
	jr	nz,noCCOL
	bit	0,b	;"C" key	cool colors disabled	
	jr	z,noCCOL		;pressed ?? no put cool colors 
	
	

	xor	a
	di
	out	(099h),a		;put Cool Colors
	ld	a,090h
	ei
	out	(099h),a
	ld	hl,palette
	ld	bc,0209ah
	otir

	ret
noCCOL:
	ld	a,1
	ld	(cool_colors),a

	ret

palette:
	db	00,00
	db	00,00
	db	23h,05h
	db	34h,06h
	db	15h,02h
	db	26h,03h
	db	51h,02h
	db	37h,05h
	db	62h,03h
	db	72h,04h
	db	72h,06h
	db	74h,07h
	db	12h,04h
	db	54h,02h
	db	55h,05h
	db	77h,07h

;----------------------------------------------------------------
inv_rutine:

	ld	a,(0e6c0h)
	or	a
invincible:	ret	nz		;self!!! invincible RET
	jp	09699h
	

;---------------------------------

	
	ld	a,011h
	ld	(05000h),a
	inc	a
	ld	(07000h),a
	call	0d890h
	ld	a,(0d802h)
	out	(0a8h),a
	ret
;--------------------------------------------------------------------------------------

