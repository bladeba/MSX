
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
SNSMAT	equ	0141H	;key pressed CALL 
			;Input    : A  - for the specified line
			;Output   : A  - for data (the bit corresponding to the pressed key will be 0)

SCC_voices	equ	0DA80h
voice_set_enter equ	0f306h

bad_ending 	equ	0f500h
line_interrupt 	equ	0f501h	;emulator 165	MSX: 166
voices 		equ	0f502h
lenguage_txt	equ	0f504h

cool_colors	equ	0f506h
speed_game	equ	0D0F2h

p_pressed	equ	0f507h
s_pressed	equ	0f508h

nochangeMAP	equ	0f530h
SET_SAMPLE	equ	0DED3h  ;Input A= Sample 

	org	0D200h
scroll_type:
	db	0
change_SAT:	db	0	
new_scroll:	db	0

	jp	INT_rutine	;2103d4
	jp	scroll_value	;
	jp	put_palete	;
	jp	copy_VRAM	;no esta!
	jp	laststage	;cd
	jp	scroll_valuehV	;cd
	jp	resetscroll	;cd
	jp	changescrollH	;c3
	jp	change_scrollV	;cd	
	jp	putsprite	;
	jp	SetVdp_Write	;CALL 0053h
	jp	SetVdp_Read	;
	jp	Vdp_Write	;CALL 004Dh
	jp	palette_stage1	;
	jp	repairsprite	;
	jp	finish_scrollH	;
	jp	finish_scrollVh	;
	jp	lavinia_dark	;
	jp	block_VRAM	;CALL 005Ch
	jp	Wrt_vdpREG	;CALL 0047h
	jp	VRAM_PLT
	jp	pause_keys
	jp	VDP_update
	jp	restore_palete
	jp	put_RST38
	jp	LDIsX20H

			;free space for future Jumps
	db	0,0,0
	db	0,0,0
	db	0,0,0
;--------------------------------------------------------------------------------

block_VRAM:
	;IN: HL= RAM source
	; DE = VRAM	destination
	; BC =bytes to transfer	
	ex	de,hl
	call	SetVdp_Write
	ex	de,hl
	ld	a,c
	or	a
	ld	a,b
	ld	b,c
	jr	z,blk_VRAM_0
	inc	a
blk_VRAM_0:
	ld	c,098h
blk_VRAM_Loop:
	otir
	dec	a
	jr	nz,blk_VRAM_Loop
	ex	de,hl
	ret

Wrt_vdpREG:

	ld	a,b
	di
	out	(099h),a
	ld	a,c
	add	a,128
	ei
	out	(099h),a
	ret


;--------------------------------------------------------------------------

VRAM_PLT:

	ld	a,(VPLT+1)
	and	10h
	ld	h,78h
	jr	z,putnewVRAM_PLT
	ld	h,38h
	
putnewVRAM_PLT:
	ld	l,00
	ret
;---------------------------------------------------------------------------------------


;            [A]: Nº Sample

 ;           00h:DED3h SET_SAMPLE


;por ejemplo:

 ;                  LD	A,6			
 ;   	CALL	SET_SAMPLE

;Esta es la tabla de SAMPLES por orden, el nº que debes poner en el reg. A


;TABLA_SAMPLES:		DW	SPEEDUP,MISSILE,RIPPLE,LASER,MULTIPLE,FORCE_FIELD,GOUP		;0-6
;			DW	FSPEEDUP,FMISSILE,FRIPPLE,FLASER,FOPTION,FFORCE_FIELD,FOK	;7-13
;			DW	MSPEEDUP,MMISSILE,MRIPPLE,MLASER,MOPTION,MFORCE_FIELD,MOK	;14-20
;			DW	DESTROY,INTRUDER,CONTINUE,DANGER,AGAIN,FOK			;21-26
;			DW	ZERO,ONE,TWO,THREE						;27-30
;			DW	FONE,FTWO,FTHREE						;31-33
;			DW	CONFIRM,BOOTING,GRAVITY,CANNOTFAIL,HAHAHA,ALERT,VANISHED	;34-40
;			DW	LOOSER,ILLBEBACK,PLANET						;41-43
;---------------------------------------------------------------------------------------

pause_keys:

	

	ld	a,04h
	call	SNSMAT
	bit 5,a			;"P" key	Change palette
	jr	nz,no_P_pressed
	
	ld	a,(p_pressed)
	or	a
	jr	nz,no_change_palette

	ld	a,1
	ld	(p_pressed),a


	ld	a,(cool_colors)		;0:arcade pallete 1:MSX1 colors 2:FRS Cool Colors
	inc	a
	cp	3
	jr	nz,no_3
	xor	a

no_3:
	
	ld	(cool_colors),a
	push	bc

	cp	2
	ld	b,0
	jr	z,ok_newpalette
	cp	1
	ld	b,8
	jr	z,ok_newpalette

	ld	a,(0e301h)
	ld	b,a
	
ok_newpalette:

	ld	a,b
	pop	bc
	
	call	change_palette
	
	ld	a,(voices)
	or	a
	jr	nz,no_change_palette

	ld	a,(cool_colors)	;Voice Male One, Two, Three
	add	a,28

	call	SET_SAMPLE
	jr	no_change_palette
no_P_pressed:
	xor	a
	ld	(p_pressed),a

no_change_palette:	

	
	ld	a,05h
	call	SNSMAT
	bit 0,a			;"S" key	Change speed gameplay
	jr	nz,no_S_pressed
	

	ld	a,(s_pressed)
	or	a
	jr	nz,no_pause_keys

	ld	a,1
	ld	(s_pressed),a

	ld	a,(speed_game)		;0:arcade pallete 1:MSX1 colors 2:FRS Cool Colors
	inc	a
	cp	3
	jr	nz,no_3_speed
	xor	a
no_3_speed:
	ld	(speed_game),a

	ld	a,(voices)
	or	a
	jr	nz,no_pause_keys

	ld	a,(speed_game)
	add	a,31
	call	SET_SAMPLE
	
	
	jr	no_pause_keys
no_S_pressed:
	xor	a
	ld	(s_pressed),a

no_pause_keys:


	ld	a,7		;check fUNKCTION KEYS
	jp	SNSMAT


;---------------------------------------------------------------------------------------
palette_stage1:

	inc	a		;palette stage 1 in gameplay!!
	
put_palete:
	
	ld	(0e301h),a

	ld	a,(cool_colors)
	or	a
	ld	a,(0e301h)
	ret	nz
change_palette:			;in: a=1 to 7 stages arcade palettes. 
				;in: a=0 FRS Cool Colors
				;in: a=8 MSX 1 Colors
	di
	push	af
	push	hl
	push	de
	push	bc

	and	a

	rla
	rla
	rla
	rla
	rla

	ld	l,a
	
	ld	h,050h/2
	rl	h

	ld	a,10h		;put HELP page in 4000h-6000h
	ld	(5000h),a

	push	hl		;save green color for VBLANK!!
	ld	a,l
	or	16h
	ld	l,a
	ld	a,(hl)		
	ld	(CLR0b1+1),a
	inc	hl
	ld	a,(hl)
	ld	(CLR0b2+1),a
	pop	hl


	xor	a
	out	(099h),a		;put palette!!!
	ld	a,090h
	out	(099h),a
	ld	bc,0209ah
	otir

	xor	a		;restore game in 4000h-6000h
	ld	(5000h),a	

	pop	bc
	pop	de
	pop	hl
	pop	af

	ei
	ret

	
;------------------------------------------------------------------------

copy_VRAM:
	
	


	;halt
	
	

	ld	de,0020h
	ld	a,015h
	
	
	
	
cont:	outi
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
	add	hl,de
	dec	a
	jp	nz,cont

	

scroll_amount1: ld a,00	;self!!
	ld	(scroll_amount2+1),a
	
		
	ld	a,(VPLT+1)

	xor	10h
	ld	(VPLT+1),a
	ld	(change_SAT_OK+1),a

	ret
	
;---------------------------------------------------------------------------------
S_ORIGEN	 equ	0F207h
S_DESTINO	equ	0F203h





	db 0,0,0,0
	db 0


;------------------------------------------------------------------------


resetscroll:

	ld	a,0
	ld	(scroll_amount2+1),a
	 	
	call	04199h
	ret

;----------------------------------------


;
;Set VDP address counter to write from address AHL (17-bit)
;Enables the interrupts
;
SetVdp_Write:
	push	af
	push	hl
	xor	a
	and	a
	rlc	h
	rla
	rlc	h
	rla
	srl	h
	srl	h
	di
	out	(#99),a
	ld	a,14+128
	out	(#99),a
	ld	a,l
	nop
	out	(#99),a
	ld	a,h
	or	64
	ei
	out	(#99),a
	pop	hl
	pop	af
	ret

;
;Set VDP address counter to read from address AHL (17-bit)
;Enables the interrupts
;
SetVdp_Read:
	;push	af
	;push	hl
	;xor	a
	;and	a
	
	;rlc	h
	;rla
	;rlc	h
	;rla
	;srl	h
	;srl	h
	;di
	;out	(#99),a
	;ld	a,14+128
	;out	(#99),a
	;ld	a,l
	;nop
	;out	(#99),a
	;ld	a,h
	;ei
	;out	(#99),a
	;pop	hl
	;pop	af
	;ret

Vdp_Write:

	call	SetVdp_Write
	out	(098h),a
	ret
;------------------------------------------------------------------------------------------

lavinia_dark:

	
	ld	a,(scroll_amount1+1)
	ld	(scroll_amount2+1),a
	
		
	ld	a,(VPLT+1)

	xor	10h
	ld	(VPLT+1),a
	ld	(change_SAT_OK+1),a

	ret
;--------------------------------------------------------------------------------------------------
restore_palete:

	ld	(0E200h),a	;state of the game... restore palette???
	cp	08		;select stage
	jr	z,res_palette
	cp	0ah		;ending
	jr	z,res_palette
	ret

res_palette:
	
	ld	a,(cool_colors)
	or	a
	ret	nz
	call	change_palette
	ret


;--------------------------------------------------

		;horizontal 03h
		;vertical   6fh	
repairsprite:


	;ld	a,(scroll_type)
	;or	a
	;jp	z,068c2h
	;call	06a03h
	;jp	68c5h
	
	ld	a,(ix+00)
	or	a
	jp	z,68dah

	;cp	0ah
	;jp	z,068c7h



	ld	a,(0e630h)
	or	a
	jr	z,nonstop
	ld	a,(ix+0Bh)
	cp	81h
	jp	nz,068bdh	;no scroll


nonstop:
	ld	a,(ix+0Bh)
	cp	81h
	jr	z,correct_sprite
checksp:
	call	06a03h		;self!!
	jp	68c5h

correct_sprite:

	ld	a,(ix+10h)
	and	8
	jp	z,68c7h

XorY1:	ld	a,(ix+6)	;vertical scroll ix+4!!!
	
incORdec:	dec	a

XorY2:	ld	(ix+6),a

outSCR:	nop
	nop
	nop	;vertical out of the screen
	



	
	jp	nc,068c7h

	call	06b62h
	
	scf

	jp	c,68dah
	jp	68c7h

;----------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------

VDP_update:

	


	call	511fh	;VDP Register update in game (0 to 8)
	
	
	xor	a	;reset horizontal scroll MSX2+
	di
	out	(099h),a
	ld	a,27+128
	out	(099h),a

	xor	a	;reset horizontal scroll MSX2
	out	(099h),a
	ld	a,18+128
	out	(099h),a
	


	ld a,166	;interrupt line in 166
	out (#99),a
	ld a,19+128
	out (#99),a
	
	ld a,02		;MSX2+ scroll VDP register config
	out (#99),a
	ld a,25+128
	out (#99),a
	

	ld	a,5		;necesary for block transer to full VRAM!!!
	ld	(0fcafh),a

	
	ld	a,(cool_colors)
	cp	1
	ret	z

	xor	a
	call	change_palette
	
	ret

;------------------------------------------

put_RST38:

	inc	hl
	ld	a,(hl)
	ld	(00039h),a
	inc	hl
	ld	a,(hl)
	ld	(0003ah),a

;put RST28

	ld	hl,0029h		;put in RST 28 jp D070h LDIs for BOSSES
	ld	(hl),070h
	inc	hl
	ld	(hl),0D0h
	

;put RST18			;for LDIs X20h

	ld	hl,0D24fh
	ld	a,(hl)
	ld	(00019h),a
	inc	hl
	ld	a,(hl)
	ld	(0001ah),a

	ret

;-------------------------------------------

LDIsX20H:	;RST 18h for LDIs x20H

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
	jp	pe,LDIsX20H
	ret
	

;==============================================================

;different routines in MSX2 and MSX2+
	
;==============================================================	


scroll_value:

Jump_scroll:	jp	scroll_valueH

scroll_valueH:
	;ld	a,(0e610h)	;if a<>0 vertical scroll down
	;or	a
	;jr	nz,scroll_valuehV

	;ld	a,(0e620h)	;if a<>0 vertical scroll down
	;or	a
	;jr	nz,scroll_valuehVd

	ld	a,(scroll_amount1+1)
	dec	a
	and	7
	cp	7
	ld	(scroll_amount1+1),a
	
	ld	a,8
	ret



scroll_valuehV:

	
	ld	a,(scroll_amount1+1)
	inc	a
	cp	01
	jr	nz,nocp1
	ld	a,0f9h
nocp1:	ld	(scroll_amount1+1),a
	
	ld	(incY+1),a
	
	

	ld	a,8
	
	ret

scroll_valuehVd:

	
	ld	a,(scroll_amount1+1)
	dec	a
	or	0f8h
	cp	0f8h
	jr	nz,nof8
	ld	a,0
nof8:
	ld	(scroll_amount1+1),a

	ld	(incY+1),a
	
	

	ld	a,8
	ret
;---------------------------------------------------------------	

green_color:	db	0


INT_rutine:

	
	push	af

	in	a,(099h)		;Read S#1 (HBLANK or VBLANK)
	rrca
	jp	c,lint
	
	xor	a 			; read S#0
	out (099h),a
	ld a,128+15
	out (099h),a
		 
	in	a,(099h)
	rlca
	jp	c,VBLANK
	
	jp	end_VBLANK
	
	
lint:
	

	

	ld	a,2   ; read S#2 
	out (#99),a
	ld a,128+15
	out (#99),a

	
	
	
	
	
Poll_1:	in	a,(099h)		;wait until start of HBLANK
	and	%00100000
	jp	nz,Poll_1
Poll_2:	in	a,(099h)		;wait until end of HBLANK
	and	%00100000
	jp	z,Poll_2
	
	;------------------------------------------PLT 3800h
	
	ld	a,0eh	;put PLT in 03800h after line interrupt
	out (099h),a
	ld a,128+2
	out (099h),a
	

	xor	a	;disable horizontal scroll		
	out (099h),a
	ld a,128+27
	out (099h),a
	
	
	
	xor	a	;disable vertical scroll		
	out (099h),a
	ld a,128+23
	out (099h),a
	

	

	
	ld	a,0ah	;disable sprites
	out (#99),a
	ld a,8+128
	out (#99),a
	
	

	

				;no change PLT in next VBLANK

	ld	a,(0e200h)		;is in game???
	cp	5
	jr	nz,no_changeGREEN


	ld	a,0bh
				;change green color		
	out (099h),a
	ld a,128+16
	out (099h),a

	ld	a,74h
	out	(09ah),a

	ld	a,(green_color)
	inc	a
	and	01fh
	ld	(green_color),a			;R B		;74 default
	rra
	rra
	out	(09ah),a
	


	



no_changeGREEN:

		
	xor	a 			; read S#0
	out (099h),a
	ld a,128+15
	out (099h),a
		 
	in	a,(099h)
	
	ld	a,01h		;VBLANK or HBLANK??
	out	(99h),a
	ld	a,15+128
	out	(099h),a
	
	pop	af
	ei
	ret

VBLANK:
	
	
	push   hl         
	push   de         
	push   bc         
	exx               
	ex     af,af'     
	push   hl         
	push   de         
	push   bc         
	push   af         
	push   iy         
	push   ix     
	
	;ld	a,2   ; disable line interrupt
	;out (#99),a
	;ld a,128+0
	;out (#99),a 


	
change_SAT_OK:
	ld	a,00	;self!!
	or	a
	jr	z,no_put_SAT

	ld	a,(0e208h)	;change SAT
	rra
	ld	a,080h
	jr	nc,putnew_SAT
	inc	a


putnew_SAT:
				;change SAT
	out	(099h),a
	ld	a,5+128
	out	(099h),a
	
	xor	a			;no change PLT in next VBLANK
	ld	(change_SAT_OK+1),a

no_put_SAT:

	ld	a,(0e200h)		;is in game???
	cp	5
	jr	z,VPLT
	cp	2
	jr	z,VPLT			;is in demo??
	ld	a,0eh
	ld	(VPLT+1),a


VPLT:	ld	a,0Eh	;self
	out (099h),a
	ld a,128+2
	out (099h),a
	
	ld	c,99h
scroll_amount2:	ld	b,00	;self!!	
	
	
	ld	a,(scroll_type)
	or	a
	jr	z,horizl2
	ld	e,27+128		;horizontal scroll
	jp	hblankloop2

horizl2:  ld	e,23+128	;vertical scroll
	
	

	ld	a,166
	add	a,b
				;interrupt line modify
	out (#99),a
	ld a,19+128
	out (#99),a
hblankloop2:
	
	nop
	

	out	(c),b
	out	(c),e
	

	
	
	ld	a,08h	;enable sprites
	out (#99),a
	ld a,8+128
	out (#99),a

	
	
noscroll:	

	;------------------------------------------PLT 3800h




	;ld	a,(change_PLT)
	;or	a
	;jr	z,default_Green

	;ld	a,(0e208h)
	;rra
	;ld	a,0Eh
	;jr	c,putnew_PLT
	;or	10h
	





default_Green:

	ld	a,0bh
					;default green color		
	out (099h),a
	ld a,128+16
	out (099h),a

CLR0b1:	ld	a,74h
	out	(09ah),a
CLR0b2:	ld	a,07h
	out	(09ah),a


	;xor a   ; read S#0 (otherwise, the program hangs)
	;out (#99),a
	;ld a,128+15
	;out (#99),a 
	;in a,(#99)

quit_VOICES:
	call	voice_set_enter	;voice  set!!


	xor	a
	ld	(05000h),a

	call	0406Dh

	
	

	

	pop    ix         
	pop    iy         
	pop    af         
	pop    bc         
	pop    de         
	pop    hl         
	ex     af,af'     
	exx               
	pop    bc         
	pop    de         
	pop    hl         

	;ld	a,12h	; enable line interrupt
	;out (#99),a
	;ld a,128+0
	;out (#99),a

end_VBLANK:

	ld	a,01h		;VBLANK or HBLANK??
	out	(99h),a
	ld	a,15+128
	out	(099h),a
	
	pop	af
	ei
	ret

		

;---------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------


changescrollH:

	

	ld	(new_scroll),a	;if a<>0 vertical scroll down
	ret
change_scrollH2:	
	ld	a,1
	ld	(scroll_type),a
	
	;horizontal 03h
		;vertical   6fh	

	ld	a,003h
	ld	(checksp+1),a

	ld	a,06h		;6 ->X   4 ->Y
	ld	(XorY1+2),a
	ld	(XorY2+2),a

	ld	a,03dh	; dec a
	ld	(incORdec),a

	
	xor	a
	ld	(incY+1),a
	ld	(scroll_amount1+1),a

	
	
	ld	(outSCR),a	;quit out of the screen vertical
	ld	(outSCR+1),a
	ld	(outSCR+2),a

	push	hl


	ld	hl,scroll_valueH
	ld	(Jump_scroll+1),hl

	ld	hl,0cf01h
	ld	(S_ORIGEN),hl
	ld	hl,0cf10h
	ld	(S_DESTINO),hl

	pop	hl

	di
	xor	a	;reset vertical scroll
	out (#99),a
	ld a,128+23
	out (#99),a
		
	ld a,166	;interrupt line in 166 for horizontal
	out (#99),a
	ld a,19+128
	ei
	out (#99),a


	ret

change_scrollVh:
	

	xor	a
	ld	(scroll_type),a
	
	ld	(scroll_amount1+1),a
	
	;horizontal 03h
	;vertical   6fh	

	ld	a,06fh
	ld	(checksp+1),a
	

	ld	a,04h
	ld	(XorY1+2),a
	ld	(XorY2+2),a

	ld	a,03ch	; inc a
	ld	(incORdec),a

	ld	a,0feh
	ld	(outSCR),a	;quit out of the screen vertical

	ld	a,0a8h
	ld	(outSCR+1),a

	ld	a,03fh
	ld	(outSCR+2),a


	push	hl


	ld	hl,scroll_valuehVd
	ld	(Jump_scroll+1),hl


	ld	hl,0cec0h
	ld	(S_ORIGEN),hl
	ld	hl,0cf10h
	ld	(S_DESTINO),hl

	pop	hl

	di
	out (#99),a	;reset horizontal scroll
	ld a,128+27
	ei
	out (#99),a



	ret

change_scrollV:	

	;di
	ld	(0e620h),a	;if a<>0 vertical scroll down
	or	a
	jr	nz,change_scrollVh
	jp	change_scrollH2
	

;------------------------------------------------------------------------------

putsprite:
	
	ld	c,0e0h
	ld	a,e
	ld	hl,0ef80h
	add	a,l
	ld	l,a
	ld	a,(hl)
incY:	add	a,0		;self!!
	
	out	(098h),a
	ld	(hl),c
	inc	l
	ld	a,(hl)
	out	(098h),a
	ld	(hl),c
	inc	l
	ld	a,(hl)
	out	(098h),a
	ld	(hl),c
	inc	l
	ld	a,(hl)
	out	(098h),a
	ld	(hl),c
	inc	l
	
	ld	a,e
	add	a,0ch
	and	07ch
	ld	e,a
	dec	d
	jr	nz,putsprite+3
	
	ret

;----------------------------------------------------------------------------------------------

clear_sprite:


;------------------------------------------------------------------------
finish_scrollH:

	rst	20h
	jp	c,4979h

	ld	a,(new_scroll)
	ld	b,a
	ld	a,(0e610h)
	cp	b
	jr	nz,nosame_SCROLL	;no change scroll

	ld	a,0	;   no move sprites with no scroll!!
	ld	(incORdec),a
	
	
	ld	a,(scroll_amount1+1)
	or	a
	call	nz,4950h
	jp	0494ah

nosame_SCROLL:
	call	4950h
	
	ld	a,(scroll_amount1+1)
	or	a
	ret	nz
	

	
	ld	a,(new_scroll)
	ld	(0e610h),a
	
	ld	a,0
	ld	(scroll_type),a
	
	push	hl
	
	ld	hl,scroll_valuehV
	ld	(Jump_scroll+1),hl
	
	
	
	pop	hl




	;horizontal 03h
		;vertical   6fh	

	ld	a,06fh
	ld	(checksp+1),a

	ld	a,04h
	ld	(XorY1+2),a
	ld	(XorY2+2),a
	
	ld	a,03dh	; dec a
	ld	(incORdec),a
	

	ret
finish_scrollVh:

	rst	20h
	jp	nz,4bf0h

	ld	a,(new_scroll)
	ld	b,a
	ld	a,(0e610h)
	cp	b
	jp	z,0494ah	;no change scroll

	call	4950h
	
	ld	a,(scroll_amount1+1)
	cp	0f9h
quitnz:	ret	nz
	
	xor	a
	ld	(incY+1),a

	ld	(outSCR),a	;quit out of the screen vertical
	ld	(outSCR+1),a
	ld	(outSCR+2),a
		
	ld	a,(new_scroll)
	ld	(0e610h),a
	
	ld	a,1
	ld	(scroll_type),a

	;horizontal 03h
		;vertical   6fh	

	ld	a,003h
	ld	(checksp+1),a

	ld	a,06h
	ld	(XorY1+2),a
	ld	(XorY2+2),a

	ld	a,03dh	; dec a
	ld	(incORdec),a

	di
	ld a,166	;interrupt line in 166 for horizontal
	out (#99),a
	ld a,19+128
	ei
	out (#99),a

	push	hl
	
	ld	hl,scroll_valueH
	ld	(Jump_scroll+1),hl
	
	
	
	pop	hl
	ret


	




;------------------------------------------------------------------------

laststage:
	
	cp	3
	jr	z,change_scrollHL

	cp	4
	ld	(0e610h),a
	jp	z,change_scrollHR
				;a=0 vertical scroll

	ld	a,0c0h		;put ret nz in finishscrollVh
	ld	(quitnz),a
	
	jp	change_scrollVh  



change_scrollHL:
	ld	(0e610h),a
	
	xor	a		;quit ret nz in finishscrollVh
	ld	(quitnz),a

	call	change_scrollH2
	
	ld	hl,scroll_valueL
	ld	(Jump_scroll+1),hl

	ret
change_scrollHR:

	xor	a		;quit ret nz in finishscrollVh
	ld	(quitnz),a
	
	jp	change_scrollH2

	

scroll_valueL:

	
	ld	a,(scroll_amount1+1)
	inc	a
	and	7
	or	a
	ld	(scroll_amount1+1),a

	
	ld	a,8
	ret




