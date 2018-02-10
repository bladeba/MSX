;Salamander help

;*** FLP.COM v1.65 for MSX

;*** ROM Loader for MegaflashROM mapped Konami SCC

; Assembled with zasm cross assembler
; http://sourceforge.net/projects/zasm/


WRTVDP	equ	00047h
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
	
	




SCC_voices	equ	0DA80h

bad_ending 	equ	0f500h
line_interrupt 	equ	0f501h	;emulator 165	MSX: 166
voices 		equ	0f502h
lenguage_txt	equ	0f504h

cool_colors	equ	0f506h
speed_game	equ	0D0F2h

p_pressed	equ	0f507h
s_pressed	equ	0f508h
;equs voice set

slot_salamander		equ	0D9F0h
slot_other_SCC		equ	0D9F1h
mapper_salamander	equ	0D9F2h
mapper_other_SCC	equ	0D9F3h

STACK			equ	0F264h
BLOCK16			equ	0F266h

nochangeMAP	equ	0f530h
	
	
	
	
	org	06000h

;----------------------------------------------------------------------------------------------

	ld	sp,0f0f0h

	call	help_key

slotvar		equ	0f4f0h

slotram		equ	0f4f1h

	
	ld	hl,04000h		;clear VRAM 4000h-8000h
	ld	bc,04000h
	xor	a
	call	016bh

	ld	hl,0f500h		;clear a part of RAM (config...)
	ld	de,0f501h
	ld	bc,00050h

	ld	(hl),0
	ldir

	halt

	call	138h
	rrca
	rrca
	and	3
	ld	c,a
	ld	b,0
	ld	hl,0fcc1h
	add	hl,bc
	ld	a,(hl)
	and	80h
	or	c
	ld	c,a
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a,(hl)
	and	0ch
	or	c
	ld	(slotvar),a

	ei

	halt


	di
	call	138h
	rlca
	rlca
	and	3
	ld	c,a
	ld	b,0
	ld	hl,0fcc1h
	add	hl,bc
	ld	a,(hl)
	and	80h
	jr	z,no_expand1
	or	c
	ld	c,a
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a,(hl)
	rlca
	rlca
	rlca
	rlca
	and	0ch
no_expand1:
	or	c
	ld	(slotram),a

	
	ei

	halt


	di


	call	setrampage2
	
	

	ld	hl,0
	ld	de,8000h
	ld	bc,04000h
	ldir

	call	setrampage0

	ld	hl,8000h
	ld	de,0h
	ld	bc,04000h
	ldir

	call	setrompage2

	;halt
;-----------------------------------------------------------
;Copy routines in RAM

	ld	a,015h
	ld	(05000h),a
	
	ld	hl,04050h
	ld	de,0D200h
	ld	bc,00dffh
	ldir

	call	VDP_GetVersion	; check VDP version
				
	
	cp	1
	jp	nz,noMSX2
	ld	hl,05000h
	ld	de,0d200h
	ld	bc,0800h
	ldir

noMSX2:
	
	call	0DEA1h		;Check keys for voice 2nd Player (Voice Set)
	
	ld	a,(slotvar)
	ld	(slot_salamander),a

	in	a,(0a8h)
	ld	(mapper_salamander),a

	call	scc_for_voicetset

	call	check_keys		;check config keys pressed

	


	ld	a,(slot_other_SCC)
	cp	0FFh
	
	jr	z,SCC_notfound

	ld	a,(voices)
	or	a
	jr	nz,V_pressed

	in	a,(0a8h)
	ld	(mapper_other_SCC),a


end_set_SCC:
	ld	a,(mapper_salamander)
	out	(0a8h),a

	ld	hl,fastblock
	ld	de,0f200h
	ld	bc,help_key-fastblock
	ldir
	
	xor	a
	ld	(05000h),a

	jp	040DAh

SCC_notfound:		
	
	call	GR8NET
	
	jr	nz,end_set_SCC
V_pressed:

	
	
	call	VDP_GetVersion	; check VDP version
				
	ld	hl,0d60Ch	;d60E in MSX2
	cp	1
	jr	nz,noMSX2_2
	

	ld	hl,0d60Eh

noMSX2_2:

	ld	(hl),0
	inc	hl
	ld	(hl),0
	inc	hl
	ld	(hl),0

	ld	a,1		;set that voices are disabled
	ld	(voices),a

	jr	end_set_SCC

GR8NET:		

		ld	a,1		;search GR8NET
		out	(05Eh),a
		in	a,(05fh)
		cp	0ffh
		ret	z		;GR8NET Not found

		ld	b,a
		ld	a,(slot_salamander)
		cp	b
		ret	z	;GR8NET with game

		
		
		ld	a,2		
		out	(05Eh),a	
		ld	a,3		;select SCC mapper type in GR8NET
		out	(05fh),a
		

		ld	a,b

		ld	(slot_other_SCC),a

		ld	h,80h
		call	ENASLT
		
		ld	a,03fh
		ld	(09000h),a

		in	a,(0a8h)
		ld	(mapper_other_SCC),a
		
		ld	a,(mapper_salamander)
		out	(0A8h),a

		
		
		or	a
		
		ret
	
;----------------------------------------------------------------

setrompage0:
	ld		a,(slotvar)
	jp		setslotpage0

setrampage0:
	ld		a,(slotram)
	jp		setslotpage0

setrompage2:
	ld		a,(slotvar)
	jp		setslotpage2

setrampage2:
	ld		a,(slotram)
	jp		setslotpage2

; ---------------------------
; SETSLOTPAGE0
; Set the slot passed in A
; at page 0 in the Z80 address space
; A: Format FxxxSSPP
; ----------------------------

setslotpage0:
	di
	ld		b,a					; B = Slot param in FxxxSSPP format
	in		a,(0A8h)
	and		0fch
	ld		d,a					; D = Primary slot value
	ld		a,b
	and		3
	or		d
	ld		d,a		; D = Final Value for primary slot
	ld		a,b		; Check if expanded
	bit		7,a
	jr		z,exp0	; Not Expanded
	and		3
	rrca
	rrca
	and		0c0h
	ld		c,a
	ld		a,d
	and		3fh
	or		c
	ld		c,a
	ld		a,b
	and		0ch
	rrca
	rrca
	and		3
	ld		b,a
	ld		a,c
	out		(0a8h),a
	ld		a,(0ffffh)
	cpl
	
	and		0fch
	or		b
	
	ld		(0ffffh),a
	
	ld	b,a
exp0:	ld		a,d				; A = Final value
	out		(0A8h),a		; Slot Final. Ram, rom c, rom c, Main
	ret



; ---------------------------
; SETSLOTPAGE2
; Set the slot passed in A
; at page 2 in the Z80 address space
; A: Format FxxxSSPP
; ----------------------------

setslotpage2:
	di
	ld		b,a					; B = Slot param in FxxxSSPP format
	in		a,(0A8h)
	rlca
	rlca
	rlca
	rlca
	and		0FCh
	ld		d,a					; D = Primary slot value
	ld		a,b
	and		3
	or		d
	rrca
	rrca
	rrca
	rrca
	ld		d,a		; D = Final Value for primary slot
	ld		a,b		; Check if expanded
	bit		7,a
	jr		z,exp2	; Not Expanded
	and		3
	rrca
	rrca
	and		0c0h
	ld		c,a
	ld		a,d
	and		3fh
	or		c
	ld		c,a
	ld		a,b
	and		0ch
	rrca
	rrca
	and		3
	ld		b,a
	ld		a,c
	out		(0a8h),a
	ld		a,(0ffffh)
	cpl
	rlca
	rlca
	rlca
	rlca
	and		0fch
	or		b
	rrca
	rrca
	rrca
	rrca
	ld		(0ffffh),a
	
	ld	b,a
exp2:	ld		a,d				; A = Final value
	out		(0A8h),a		; Slot Final. Ram, rom c, rom c, Main
	ret
	
;-------------------------------------------------------------

;--------------------------------------------------------------------------------------------
;search other SCC for Voice SET!!!
scc_for_voicetset:

	ld	bc,00400h
	ld	hl,0fcc1h
next_slot:
	push	bc
	push	hl
	ld	a,(hl)
	bit	7,a
	jr	nz,exp1
	ld	a,c
	call	check_no_expand
	jr	next_slot3
exp1:
	call	expanded

next_slot3:

	pop	hl
	pop	bc
	ret	c
	inc	hl
	inc	c
	djnz	next_slot
	ld	a,0ffh
	ld	(slot_other_SCC),a
	ret
expanded:

	and	080h
	or	c
	ld	b,4
next_slt4:
	push	bc
	call	check_no_expand
	pop	bc
	ret	c
	add	a,04
	djnz	next_slt4
	ret


SCC_subslot:

	call	checkSCC
	pop	hl
	pop	bc
	ret	c
	inc	hl
	inc	c
	djnz	next_slot
	ld	a,0ffh
	ld	(slot_other_SCC),a
	ret

	


check_no_expand:

	ld	(slot_other_SCC),a
	call	putslotSCC
	jr	nc,next_slot2
	ld	a,(slot_other_SCC)
	scf
	ret
next_slot2:
	ld	a,(slot_other_SCC)
	and	a
	ret


putslotSCC:
	ld	h,80h
	call	ENASLT
	call	checkSCC
	ret

checkSCC:	
		

		LD      A,02		;is ROM??
                LD      (09000h),A
                
	        LD      HL,9800h
                LD      A,(HL)
                CPL
                LD      (HL),A
                CP      (HL)
                JR      Z,isRAM
                
                LD      A,03Fh
                LD      (09000h),A
		LD      A,(HL)
                CPL
                LD      (HL),A
                CP      (HL)
                JR      nz,isRAM
		
		ld	a,(slot_other_SCC)
		ld	hl,slot_salamander
		
		cp	(hl)
		jr	z,isRAM
		scf
		ret

	;	jr	isRAM

isRAM:		
		
		or	a
		ret				

;-------------------------------------------------------------	


S_ORIGEN	equ	origenIX+2
S_DESTINO	equ	origenIY+2






fastblock:


		DI
origenIY:	LD	IY,0000		;DESTINO FONDO STARFIELD
origenIX:	LD	IX,0000		;ORIGEN
		LD	(STACK),SP			;GUARDA PILA
		LD	A,015h	;A,0300h/020h			;$300 BYTES		
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

		db	0,0	;STACK
		db	0	;BLOCK16
		nop
		nop
		nop
		nop
		nop
		nop
		nop


fastblock_end:
;---------------------------------------------------------------------------------------------

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

;---------------------------------

voice_set_enter:
	
	ld	a,011h		;here!! change this byte 011h or 013h!!
	ld	(05000h),a
	inc	a
	ld	(07000h),a
	call	SCC_voices
	ld	a,(mapper_salamander)
	out	(0a8h),a
	ret
;------------------------------------------------

sounds_enter:

	
	ld	(nochangeMAP),a
	ei
	call	6472h		;put souns
	di
	xor	a
	ld	(nochangeMAP),a
	ret




;----------------------------------------------------------------------------------------------

help_key:

	ld	a,03h
	call	SNSMAT
	bit 5,a	;"H" key	Help
	ld	a,3
	ret	nz

	xor	a
	ld	hl,00000h
	ld	bc,04000h
	call	00056h		;Change to screen 0 40*24 and clear screen
	
	

	ld	a,80
	ld	(0f3aeh),a
	ld	a,0fh
	ld	(0f3e9h),a
	ld	a,0
	ld	(0f3eah),a
	ld	a,07
	ld	(0f3ebh),a

	;ld	(0f3b0h),a	;width	80

	xor	a
	call	005fh		;screen 0
	
	ld	a,027h		;Colour Table
	out	(099h),a
	ld	a,3+128
	out	(099h),a

	ld	a,0F0h		;Colour Register
	out	(099h),a
	ld	a,7+128
	out	(099h),a

	; borra patrones flash
	ld	hl,2048
	xor	a
	call VPOKE
	ld	b,10*24-1
	xor	a
b_clrFL: out	(098h),a
	djnz	b_clrFL


	ld	hl,pant
	ld	de,0
	ld	bc,80*24
	call	05Ch

	;VDP(7)=&HF1:VDP(13)=&HF4:VDP(14)=&HF0



	ld	a,0F4h		;Blink color
	out	(099h),a
	ld	a,12+128
	out	(099h),a

	
	ld	a,055h		;Blink Period
	out	(099h),a
	ld	a,13+128
	out	(099h),a

	ld	hl,08e9h
	ld	a,0FFh
	call	VPOKE
	out	(098h),a
	out	(098h),a
	out	(098h),a
	ld	a,080h
	out	(098h),a







nospace:
	ld	a,08h
	call	SNSMAT
	bit 0,a			;"Space key" key no presed stop
	ld	a,3
	jr	nz,nospace
	
	ret

;----------------------------------------------------------

VPOKE:	
	push	af
	xor	a
	di
	out	(099h),a
	ld	a,08Eh
	out	(099h),a
	ld	a,l
	out	(099h),a
	ld	a,h
	and	03Fh
	or	040h
	out	(099h),a
	ei
	ex	(sp),hl
	ex	(sp),hl
	pop	af
	out	(098h),a
	ret
;----------------------------------------------------------------------------------------------------------------

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
	bit 3,a	;"V" key	Voice Set Disable
	ld	a,0
	jr	nz,K_voice
	ld	a,1
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
	
	
	push	bc
	
	ld	hl,inv_rutine
	ld	de,0f520h
	ld	bc,00008h
	ldir
	ld	(0f524h),a
	
	pop	bc



	
	push	bc
	bit	3,b	;"F" key	Frequency
	ld	a,1
	jr	nz,K_freq
	
	ld	hl,0ffe8h
	ld	a,(hl)
	xor	2
	ld	(hl),a

	out	(99h),a		;Set VDP Frequency
	ld	a,9+128
	out	(099h),a
	
	
	


	

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
		
	ret
noCCOL:
	ld	a,1
	ld	(cool_colors),a

	ret
;--------------------------------------------------------------------
inv_rutine:

	ld	a,(0e6c0h)
	or	a
invincible:	ret	nz		;self!!! invincible RET
	jp	09699h
	
;---------------------------------------------------------------------------------------------------------------------
;
; Detect VDP version
;
; a <- 0: TMS9918A, 1: V9938, 2: V9958, x: VDP ID
; f <- z: TMS9918A, nz: other
;
VDP_GetVersion:
    call VDP_IsTMS9918A  ; use a different way to detect TMS9918A
    ret z
    ld a,1               ; select s#1
    di
    out (99H),a
    ld a,15 + 128
    out (99H),a
    nop
    nop
    in a,(99H)           ; read s#1
    and 00111110B        ; get VDP ID
    rrca
    ex af,af'
    xor a                ; select s#0 as required by BIOS
    out (99H),a
    ld a,15 + 128
    ei
    out (99H),a
    ex af,af'
    ret nz               ; return VDP ID for V9958 or higher
    inc a                ; return 1 for V9938
    ret

;The TMS9918A has no VDP ID, so we use a different way to detect it…

;
; Test if the VDP is a TMS9918A.
;
; The VDP ID number was only introduced in the V9938, so we have to use a
; different method to detect the TMS9918A. We wait for the vertical blanking
; interrupt flag, and then quickly read status register 2 and expect bit 6
; (VR, vertical retrace flag) to be set as well. The TMS9918A has only one
; status register, so bit 6 (5S, 5th sprite flag) will return 0 in stead.
;
; f <- z: TMS9918A, nz: V99X8
;
VDP_IsTMS9918A:
    in a,(99H)           ; read s#0, make sure interrupt flag is reset
    di
VDP_IsTMS9918A_Wait:
    in a,(99H)           ; read s#0
    and a                ; wait until interrupt flag is set
    jp p,VDP_IsTMS9918A_Wait
    ld a,2               ; select s#2 on V9938
    out (99H),a
    ld a,15 + 128
    out (99H),a
    nop
    nop
    in a,(99H)           ; read s#2 / s#0
    ex af,af'
    xor a                ; select s#0 as required by BIOS
    out (99H),a
    ld a,15 + 128
    ei
    out (99H),a
    ex af,af'
    and 01000000B        ; check if bit 6 was 0 (s#0 5S) or 1 (s#2 VR)
    ret
;----------------------------------------------------------------------------------------------------------------------
pant:
	db	"                     SALAMANDER SMOOTH SCROLL Version 1.00                      "
	db	"                               "
	db	"               only for MSX 2 or higher  (recommended Turbo CPU)                "
	db	"                                                                                "
	db	" This version includes:                                                         "
	db	"                                                                                "
	db	"   - Turbo FIX,Dynamic Vsync,Ripple Laser FIX, Cool Colors, invincible  by FRS  "
	db	"   - Voice SET (with other SCC) by WYZ & ARTRAG                                 "
	db	"   - Gradius 2 included in the same ROM (for good ending) by Manuel Pazos       "
	db	"   - New color flavour by Toni Galvez                                           "
	db	"   - Smooth Scroll by Victor Martinez (inspired on Gradius 2 by FRS)            "
	db	"                                                                                "
	db	" Access these extra options by pressing the following keys on boot (or now):    "
	db	"    [F] Toggle VDP frequency             [C] Cool Colors disabled               "
	db	"    [E] English texts in game forced     [J] Japanese texts in game forced      "
	db	"    [V] Voice Set disabled               [I] Invincible (for cowards)           "
	db	"    [B] Bad ending forced, Gradius 2 disabled (no Venom Stage)                  "
	db	"    [CTRL] Female Voice Set(G-Gaiden)    [CTRL+SHIFT] Male Voice Set(G-Gaiden)  "
	db	"                                                                                "
	db	" In gameplay paused (with F1 key):                                              "
	db	"    [S] Change gameplay SPEED (3 levels) [P] Change colors PALETTE (3 levels)   "
	db	"    Player 1 Voice Set:[F2] Default voice,[F3] Zowie Scoot,[F4]Iggy Rock        "
	db	"                                                                                "
	db	"                         Push [SPACE KEY] to launch game                        "