
;USAS Turbo FIX


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
WRTPSG	equ	00093h
RDPSG	equ	00096h
GTTRIG	equ	000D8h
RAMAD1	equ	0f342h
RAMAD2	equ	0f343h
BUFTOP	equ	08000h
CHGET	equ	0009fh
MNROM	equ	0FCC1h	; Main-ROM Slot number & Secondary slot flags table
DRVINV	equ	0FB22H	; Installed Disk-ROM
SNSMAT	equ	00141H	;key pressed CALL 
			;Input    : A  - for the specified line
			;Output   : A  - for data (the bit corresponding to the pressed key will be 0)
			
	incbin	"Usas(1987)_mapper_SCC.rom"
	

;--------------------------------------------------------
;--------------------------------------------------------
;--------------------------------------------------------
;--------------------------------------------------------
;Part 010h
;patched in 040BBh

		org	008000h	;in 0F page of ROM
Part_10:		
	
	ld	a,(ROM_started)
	cp	041h
	jr	z,skip_boot
	
	
	ld	hl,variables_in_RAM-DIS_inc
	ld	de,0F800h
	ld	bc,variables_in_RAM_end-variables_in_RAM
	ldir
	
	ld	a,(002Bh) ;MSX japanese or international??
	ld	(lenguage_txt),a
	
	
	call	VDP_GetVersion
	
	call	Check_MFR_SD
	
	call	help_key
	
	;
	call	check_keys
	
	ld	a,41h
	ld	(ROM_started),a

skip_boot:
	di
	
	ld	a,0C9h	;RET in INT
	ld	(0FD9Ah),a

	;Clear RAM
	ld	hl,0C000h	
	ld	de,0C001h
	ld	bc,03000h
	ld	(hl),0
	ldir
	;put screen 5
	ld a,5
	call	005Fh

	;copy rotines in RAM
	
	ld	hl,routines_in_RAM-DIS_inc
	ld	de,0F800h+(variables_in_RAM_end-variables_in_RAM)
	ld	bc,routines_in_RAM_END-routines_in_RAM
	ldir
	
	ld	hl,OUTIS_RAM-DIS_inc
	ld	de,0FD00h
	ld	bc,OUTIS_RAM_END-OUTIS_RAM
	ldir

	call	putTURBO
	
	
	ld	a,(0007h); VDP port read in BIOS
	inc	a
	
	ld	(OUT_VDP_REG1+1),a
	ld	(OUT_VDP_REG2+1),a
	ld	(INVDP_1+1),a
	ld	(INVDP_2+1),a

	ld	a,(PSG_forced)
	or	a
	jr	z,no_put0_pagePSG

	xor	a
	ld	(MGS_INT),a
	ld	(MGS_INT+1),a
	ld	(MGS_INT+2),a

	
	
	ld	a,Part0_PSG_page
	ld	(05000h),a
	
no_put0_pagePSG:	
	ld	a,(MFR_SD_found)
	or	a
	jr	z,no_skip_mute
	
	
	
	
	ld	hl,CHANNEL_state
	xor	a
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
	

no_skip_mute:	
	
	call	Read_Slot_ROM
	call	Read_Slot_RAM

	
	ld	a,(PSG_forced)
	or	a
		;no change song in PSG mode
	call	z,put_MGSDRV_in_RAM

	
	
	
	
	
	ret
;--------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------

help_key:

	;ld	a,03h
	;call	SNSMAT
	;bit 5,a	;"H" key	Help
	;ld	a,3
	;ret	nz

	
	
	
	
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

	
	ld	bc,43	;write MFRSD found or not in HELP screen
	ld	de,0602h
	ld	hl,MFR_SD_found_txt
	ld	a,(MFR_SD_found)
	cp	1
	jr	z,put_MFRSD
	ld	hl,MFR_SD_not_found_txt
put_MFRSD:	
	call	05Ch



	ld	bc,5	;write VDP version in HELP screen
	ld	de,06BAh
	ld	hl,VDP_9938
	ld	a,(VDP_type)
	cp	1
	jr	z,put_VDP_version
	ld	hl,VDP_9958
put_VDP_version:	
	call	05Ch

	ld	bc,4	;write VDP version in HELP screen
	ld	de,06C0h
	ld	hl,VDP_60hz
	ld	a,(0ffe8h)	;VDP freq???
	and	2
	jr	z,put_VDP_freq
	ld	hl,VDP_50hz
put_VDP_freq:	
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
	
	ld	c,098h
	out	(c),a
	nop
	out	(c),a
	nop
	out	(c),a
	ld	a,080h
	out	(c),a







nospace:
	
	ld	a,08h
	call	SNSMAT
	bit 0,a			;"Space key" key no presed stop
	ld	a,3
	jr	z,launch_game
	
	ld	a,1	;trigger A of Port 1
	call	GTTRIG
	or	a
	jr	nz,launch_game
	jr	nospace

launch_game:

	in	a,(0aah)	;game master??
	or	040h
	out	(0aah),a
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
;---------------------------------------------------------------------------------------------------------------------
;
; Detect VDP version
;
; a <- 0: TMS9918A, 1: V9938, 2: V9958, x: VDP ID
; f <- z: TMS9918A, nz: other
;
VDP_GetVersion:
    
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



;---------------------------------------------------------------------------------------------------------------------

check_keys:

	
	call	check_P_key	;force PSG
	call	check_F_key	;VDP frequency
	call	check_lenguage	;english or japanese
	call	check_Numbers	;RCs combinations
	ret
;-------------------
check_P_key:

	ld	a,4
	call	SNSMAT
	
	bit	5,a	;"P" key force PSG sound
	jr	nz,no_PSG_forced
	ld	a,1
	ld	(PSG_forced),a
	ret
	
no_PSG_forced:	
	
	
	xor	a
	ld	(PSG_forced),a

	ret
;--------------------	
	
check_F_key:	
	
	ld	a,03h	
	call	SNSMAT
	bit	3,a	;"F" key	Frequency
	ld	a,1
	ret	nz
	
	ld	hl,0ffe8h
	ld	a,(hl)
	xor	2
	ld	(hl),a

	out	(99h),a		;Set VDP Frequency
	ld	a,9+128
	out	(099h),a
	ret

;----------------------
	
check_lenguage:

	ld	a,3
	call	SNSMAT
	
	bit	2,a	;"E" key	Force English
	jr	nz,K_japanese
	ld	a,0FFh
	ld	(lenguage_txt),a
	ret
	
K_japanese:	
	
	bit	7,a	;"J" key	Force Japanese
	ret	nz
	xor	a
	ld	(lenguage_txt),a

	ret

check_Numbers:

	ld	a,0
	call	SNSMAT
	cpl
	rra
	and	01111b
	ld	(RCs_combination),a
	ret


;----------------------------------------------------------------------------------------------------------------------
pant:
	db	"                      USAS(RC-753) enhanced Version 1.03                        "
	db	"                                 "
	db	"                          only for MSX 2 or higher                              "
	db	"                                                                                "
	db	" Credits:                                                                       "
	db	"                                                                                "
	db	"   - SCC Music Arrangement by Koichiro                                          "
	db	"   - Original TurboFix Routine by FRS                                           "
	db	"   - Programmed by Victor Martinez                                              "
	db	"                                                                                "
	db	"                                                                                "
	db	" Access these extra options by keeping pressed the following keys:              "
	db	"                                                                                "
	db	"   [F] Toggle VDP freq.(50Hz<->60Hz)      [1] +RC749: 100 Coins at the start    "
	db	"   [P] PSG original sound forced          [2] +RC750: Loose half the energy     "
	db	"   [E] English texts in game forced       [3] +RC751: <F5> to continue          "
	db	"   [J] Japanese texts in game forced      [4] +RC752: Always Special power      "
	db	"                                                                                "
	db	"                                                                                "
	db	"                                                                                "
	db	"                                                                                "
	db	"                            VDP detected:                                       "
	db	"                                                                                "
	db	"                        Push [SPACE KEY] or [TRIGGER A]                         "

	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;--------------------------------------------------------------------------------------------------------------

VDP_9938:		db	"9938,"
VDP_9958:		db	"9958,"
VDP_60hz:		db	"60Hz"
VDP_50hz:		db	"50Hz"
MFR_SD_found_txt:	db	"    MegaflashROM SD found -> Double PSG    "
MFR_SD_not_found_txt:	db	"MegaflashROM SD not found - > No double PSG"
;-----------------------------------------------------
putTURBO:
	
CHGTURCIEL	equ	01387h	; CIEL Expert3 bizarre turbo routine


_TURBO3:
;	; Expert 3 CIEL	
;	; Test if the CIEL change-turbo routine signature is in ROM
	ld	hl,CHGTURCIEL
	ld	de,CIELSIGN
	ld	c,2

_CIEL1:	ld	b,3
_CIEL2: ld	a,(hl)
	ld	ixh,a
	ld	a,(de)
	cp	ixh
	jr	nz,NOTCIEL
	inc	hl
	inc	de
	djnz	_CIEL2
	ld	hl,CHGTURCIEL+0Ch
	dec	c
	ld	a,c
	or	a
	jr	nz,_CIEL2
	call	CHGTURCIEL
	db	1	; Padding to make the CIELSIGN inert
CIELSIGN:	DEFB	0A7h,0FAh,093h,013h,0DBh,0B6h

NOTCIEL:			
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				;Si es un Panasonic 2+, activamos Turbo
	LD	A,8
	OUT 	(040H),A	;out the manufacturer code 8 (Panasonic) to I/O port 40h
	IN	A,(040H)	;read the value you have just written
	CPL			;complement all bits of the value
	CP	8		;if it does not match the value you originally wrote,
	JR	NZ,Not_WX	;it is not a WX/WSX/FX.
	XOR	A		;write 0 to I/O port 41h
	OUT	(041H),A	;and the mode changes to high-speed clock
	jr	end_turbo

Not_WX:  ld	a,(0180h)
	cp	0c3h
		;no_turbo
	jr	nz,end_turbo
	ld	a,082h
	call	0180h

end_turbo:

	ret
;-----------------------------------

Read_Slot_ROM:

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
	ld	(slot_ROM),a
	ret

;-----------------------------------
Read_Slot_RAM:

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
	ld	(slot_RAM),a
	ret
;-----------------------------------
put_MGSDRV_in_RAM:

	;read values with ROM enabled in page 1
	call	0138h	;read A8h
	ld	(value_OUT_A8_ROM),a
	ld	a,(0FFFFh)
	cpl
	ld	(value_FFFF_ROM),a
	
	
	
	ld	a,(slot_RAM)
	ld	h,040h	;in page 0
	call	ENASLT

	ld	a,(MFR_SD_found)
	or	a
	ld	a,page_MGSDRV
	jr	z,set_MGS_page
	inc	a	;MGS for MFR SD
set_MGS_page:	
	ld	(0B000h),a

	ld	hl,0A000h	
	ld	de,06000h
	ld	bc,02000h
	ldir

	
	ld	a,(slot_ROM)	;put ROM slot in INI SCC routine
	ld	(INI_SCC_slot),a

	ld	a,010h	;actual page selected in (08000h-0A000h)
	ld	(ROM_page_in_MGS_ini),a

	call	INIT_MGSDRV



	
	call	setrampage0

	
	;read values with RAM enabled in page 1
	in	a,(0A8h)	;read A8h
	ld	(value_OUT_A8_RAM),a
	ld	a,(0FFFFh)
	cpl
	ld	(value_FFFF_RAM),a
	
	
	
		

	call	enable_ROM_page1
	ret
;--------------------------------------
setrampage0:
	ld		a,(slot_RAM)
	jp		setslotpage0
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
;-----------------------------------
Check_MFR_SD:

	ld	hl,0FCC1h
	ld	de,txt_chain_MFR_SD
	ld	c,00	; slot
check_expanded:	
	bit	7,(hl)
	inc	hl
	jr	z,no_expanded

	ld	a,c	;slot
	
	exx
	di
	
	call	check_character
	exx
	jr	z,found_MFRSD
	inc	de

no_expanded:
	
	inc	c
	ld	a,c	;slot
	cp	4
	
	jr	z,not_found_MFRSD
	
	jr	check_expanded
found_MFRSD:	
	ld	a,1
	ld	(MFR_SD_found),a
	ret

not_found_MFRSD:
	xor	a
	ld	(MFR_SD_found),a
	ret


txt_chain_MFR_SD:	db "MFRSD"


check_character:

	ld	hl,04010h
	ld	de,txt_chain_MFR_SD
	ld	c,a
	ld	b,5	;number of charactersto check

next_character_MFR_SD:	
	push	de
	push	bc
	ld	a,c
	or	080h	;expanded
	call	000Ch	;read value of other slot
	pop	bc
	pop	de
	ex	de,hl
	cp	(hl)
	ex	de,hl
	ret	nz
	inc	hl
	inc	de
	djnz	next_character_MFR_SD
	ld	a,c
	ret

end_block:


;-----------------------------------------------------------------------
;------------------------------------------------------------------------

ini:
	
	
	org	0F800h

variables_in_RAM:	

slot_ROM:		db	0	;for Call ENASLT
slot_RAM:		db	0	;for Call ENASLT
value_OUT_A8_ROM:	db	0
value_OUT_A8_RAM:	db	0
value_FFFF_ROM:		db	0
value_FFFF_RAM:		db	0
current_song:		db	0FFh
VDP_type:		db	0
lenguage_txt:		db	0	;F808h
MFR_SD_found:		db	0	;F809h	0->not found	1->found
PSG_forced:		db	0	;0F80Ah	1-> forced
RCs_combination:	db	0
VPLT_actual:		db	0
ROM_started:		db	0
	db	0
	db	0
variables_in_RAM_end:
;-------------------------------------
routines_in_RAM:
	
	
	jp	INT_routine	;F810h		
	jp	Turbo_FIX	;F813h
	jp	put_wait_state	;F816h
	jp	0FD1Ah;block_OUTIS_1	;F819h	
	jp	0FD3Bh;block_OUTIS_2	;F81Ch
	jp	music_START	;F81Fh
	jp	music_STOP	;F822h
	jp	music_PLAY_INT	;F825h
	jp	Wrt_vdpREG	;F828h	;call 0047h in BIOS
	jp	music_STOP_noise;F82Bh
	jp	0FD00h;set_VRAM_sprite1;F82Eh
	jp	0FD0Dh;set_VRAM_sprite2;F831h
	jp	PSG_internal_ini;F834h
	jp	SLCT_SONG_intro_JAP	;F837h
	jp	RCs_combi	;F83Ah
	jp	SLCT_SONG_intro_ENG	;F83Dh
	jp	joymega_START_BUTTON	;F840h
	
	


INT_routine:	;in 0FD9Ah
	
	
	
	;call 013eh	;read VDP state
INVDP_1:	in	a,(099h)

	ld	a,(game_state)
	cp	STA1GAME
	jr	z,VPLT
	cp	STA1DEMO
	jr	z,VPLT
	
no_change_VPLT:
	
	ld	a,01h
	jr	VPLT+3

VPLT:	ld	a,(VPLT_actual)	;self!!
	out (099h),a
	ld a,128+11
	out (099h),a

	
			
MGS_INT:	call	music_PLAY_INT	;CALL to MGS music

	call	403Dh	;INT in game
	
	;call	013eh	;read VDP state
INVDP_2:	in	a,(099h)	
	ret
	
DIS_inc:	equ	variables_in_RAM-ini

;----------------------------------------------------------------------
game_state: equ 0C000h
		;0:KONAMI Logo
		;1:Game Title
		;2:Demo
		;3:Start game
		;4:Select Stage
		;5:Gameplay
		
	


Turbo_FIX:	
	
	xor	a
	ld	(0F3dbh),a
	
	
	
	
	dec	a
	
ini_loop:
	ld	hl,0c005h
	jr	c,peripherical_read
	neg
	ld	b,a

restart_wait:
	res	0,(hl)
wait:	halt
	ld	a,(hl)
	and	a
	jr	z,wait
	djnz	restart_wait
	
peripherical_read:	
	in	a,(0aah)	;game master??
	and	040h
	jr	z,peripherical_read
	call	main_loop
	jr	ini_loop

main_loop:

	;call	04c45h		;read keys
	call	040e0h		;game loop

	call	check_state

	ld	hl,state
	ld	a,(hl)
	inc	b
	sub	b
	ld	b,a
	jr	nc,no_rest_b
	ld	b,0

no_rest_b:
	ld	(hl),b
	ccf
	ret

check_state:
	ld	b,00

	ld	a,(game_state) 	; get the game main-state
	
	cp	STA1GAME	; playing the game?
	ret	z		; return frameskip=1
	cp	SLCTGAME	;select Stage??
	jr	z,in_SELECT_STAGE
	cp	INTERLUDE
	jr	z,in_INTERLUDE
	
	cp	STA1DEMO	; playing some part of the demo?
	ret	z		; return frameskip=1
	;dec	b		; set frameskip 0 on anything else
	ret
	
in_SELECT_STAGE:

	ld	a,(game_state+1)
	cp	3
	jr	z,inc_WAIT+1
	cp	9
	jr	z,inc_WAIT
	ret	nz
inc_WAIT:	
	inc	b
	inc	b
	inc	b
	inc	b
	ret
in_INTERLUDE:	

	ld	a,(game_state+1)
	cp	2	;ending!!
	jr	nz,inc_WAIT
	ret

	
STA1GAME:	equ 05h
STA1DEMO:	equ 02h
SLCTGAME:	equ 04h
INTERLUDE:	equ 0ah	

in_menu:

	
	ld	a,(game_state+1)
	ld	b,0
	cp	1
	ret	z
	
	
	
	ret


peripherical:	
	ld	a,(hl)
	and	2
	ret	nz
	set	1,(hl)
	push	hl
	call	main_loop
	pop	hl
	res	1,(hl)
	ret
	
put_wait_state:	

	ld	a,(hl)
	and	a
	jr	z,inc_wait_state
	ld	hl,state
	ld	a,(hl)
	inc	a
	cp	5
	ret	nc
	ld	(hl),a
	ret
inc_wait_state:
	inc	(hl)
	ret

state:	db	0
;-------------------------------------------------------

RG0SAV  equ 0F3DFh

Wrt_vdpREG:

	di
	push	hl
	push	bc

	
	ld	a,b
OUT_VDP_REG1:	out	(099h),a
	ld	a,c
	add	a,128	;for register
	ei
OUT_VDP_REG2:	out	(099h),a
	
	
	ld	b,0
	ld	hl,RG0SAV
	and	a	;quit carry
	adc	hl,bc
	pop	bc
	ld	(hl),b	;save NEW value in RAM

	
	pop	hl
	ret
;-----------------------------------

RCs_combi:

	call	0B751h	;check RCs in game
	ld	hl,0C205h
	ld	a,(RCs_combination)
	or	(hl)
	ld	(hl),a
	ret






;-----------------------------------
enable_ROM_page1:
	
	push	af
	ld	a,(value_OUT_A8_ROM)
	out	(0A8h),a
	ld	a,(value_FFFF_ROM)
	ld	(0FFFFh),a
	pop	af
	ret
	
;-----------------------------------
enable_RAM_page1:

	push	af
	ld	a,(value_OUT_A8_RAM)
	out	(0A8h),a
	ld	a,(value_FFFF_RAM)
	ld	(0FFFFh),a
	pop	af
	ret
;-----------------------------------

PSG_internal_ini:
	
	push	af
	ld	a,(MFR_SD_found)
	or	a
	jr	z,no_ini_internal_PSG
	pop	af
	jp	0093h

no_ini_internal_PSG:

	pop	af
	ret

PSG_internal_MUTE:

	ld	a,8	;register 8:first channel VOLUME
	ld	b,3	;3 channels
	ld	e,0	;volume
mute_more_PSG_channels:	
	call	PSG_write_in_RAM
	inc	a
	djnz	mute_more_PSG_channels
	ret
PSG_write_in_RAM:

	out	(0A0h),a
	push	af
	ld	a,e
	out	(0A1h),a
	pop	af
	ret


;-------------------------------------------------------------
;MGSDRV jumps
INIT_MGSDRV	EQU	6010H	;Init devices and driver
INITM		EQU	6013H	;Reset values Music ;No parameters
PLYST		EQU	6016H	;Start Song
		;DE:Song start Adress
		;HL:0FFFFh ->sound in all channels
		;BC:0FF9Bh ->??

TMST1		EQU	6019H	;mute or no mute channels
TMST2		EQU	601CH
PLAY_INT	EQU	601FH	;no parameters	
MSVST		EQU	6022H	;volume a:volumen 00->maximo 10h->mute
WRTFM		EQU	6025H
SLOT_SCC_SAVED	EQU	76F5H

INI_SCC_slot		EQU	60EAh
ROM_page_in_MGS_ini	EQU	6257h
;-----------------------------------------------------------------

;-------------------------------------------------------------
SLCT_SONG_intro_JAP:
	
	ld	a,(PSG_forced)
	or	a
	jp	nz,06698h	;no change song in PSG mode
	
	ld	a,(lenguage_txt)
	and	0Fh
	jp	nz,06698h	;no change in English mode

	call	change_SONG_INTRO
	jp	06698h	;back to game

SLCT_SONG_intro_ENG:
	
		
	ld	a,(PSG_forced)
	or	a
	jr	nz,no_change_intro	;no change song in PSG mode
	
	ld	a,(lenguage_txt)
	and	0Fh
	jr	z,no_change_intro	;no change in English mode


	call	change_SONG_INTRO
no_change_intro:
	ld	a,(lenguage_txt)
	jp	0611Ah	;bzck to game

change_SONG_INTRO:

	ld	a,080h	;simulate other song
	ld	(0C11fh),a
	
	ld	a,89h
	call	056E3h	;put song
	di
	ld	a,08ah	;remember intro song playing
	ld	(0C11fh),a

	call	0547fh	;put correct pages
	ret

music_STOP:

	

	ld	a,(MFR_SD_found)
	or	a
	call	nz,PSG_internal_MUTE

	call	stop_music
	jp	058b4h

stop_music:	
	ld	a,03Fh
	ld	(09000h),a
	call	enable_RAM_page1
	ld	bc,0000h
	call	INITM
	call	enable_ROM_page1
	ret

music_STOP_noise:

	push	af
	call	stop_music
	pop	af

	ld	de,0C01ch
	ret
	
music_START:


emoticon:	equ	0C122h
		;00h:Happy (Normal)
		;20h:Joy
		;40h:Angry
		;80h:Sad
	
	
	
	push	af
	
	
	;
	ld	a,(MFR_SD_found)
	or	a
	call	nz,PSG_internal_MUTE
	;
	
	
	call	enable_RAM_page1	;and page 0
	
	ld	a,03fh
	ld	(09000h),a

	;call	INITM

	

	pop	af
	push	af	;song number
	ld	e,a
	cp	05h
	jr	nc,normal_table
	
	ld	a,(emoticon)
	
	or	a
	jr	z,normal_table
	ld	d,a
	ld	a,total_normal_songs	;number of songs
loop_emoticons_song:

	rl	d	;rotate left D
	jr	c,select_song_emoticon
	add	a,5
	jr	loop_emoticons_song
select_song_emoticon:
	add	a,e	;add stage (0-4)

	jr	normal_table_2	;skip push-pop
	
	
normal_table:
	pop	af
	push	af	;song number

normal_table_2:	
	
	ld	e,a
	sla	a
	add	a,e

	ld	hl,songs_table
	add	a,l
	ld	l,a

	jr	nc,no_carry_table

	inc	h

no_carry_table:	



	ld	a,(hl)	;page in ROM of song
	ld	(0B000h),a	;put song page in ROM	
	

	inc	hl

	ld	e,(hl)
	inc	hl
	ld	d,(hl)

	ex	de,hl
	
	ld	c,(hl)	;get size
	inc	hl
	ld	b,(hl)
	inc	hl


	ld	de,00000h
	
	ldir


	ld	a,03Fh
	ld	(09000h),a
	
	;parameters
	
	xor	a	;put max volume!!
	ld	bc,00000h
	call	MSVST
	
same_song:

	ld	hl,0FFFFh
	ld	de,0000h	;adress song in RAM
	ld	bc,0FF9Bh
	
	call	PLYST
	
	pop	af
	push	af

	ld	(current_song),a

	ld	b,20h
	cp	0Ah	;Intro song
	jr	z,wait_start_song
	ld	b,30h
	cp	09h	;Select Stage
	jr	z,wait_start_song

	
	cp	04	;Stage 4 Mohenjo Daro
	jr	z,no_wait_start_song
	ld	b,15

wait_start_song:	
	
	push	bc
	call	PLAY_INT
	pop	bc


	djnz	wait_start_song
no_wait_start_song:	
	call	enable_ROM_page1
	
	ld	a,0Eh
	ld	(09000h),a
	inc	a
	ld	(0B000h),a
	
	pop	af
	
	
PSG_mode_put_song:	
	rlca
	ld	e,a
	rlca

	ret

music_PLAY_INT:

PSG_volume:	equ	0C11Ch	;00->max F0h->mute
	
	call	enable_RAM_page1
	ld	a,03Fh
	ld	(09000h),a


	ld	a,(0C017h)
	cp	060h
CHANNEL_state:	call	nz,mute_channel_3_PSG	;self!!	0C4h ->waiting for mute 0CCh->waiting for NO mute
	;self!! CALL NZ	or CALL Z
	
	
	
	ld	a,(PSG_volume)
	or	a
	call	nz,music_CHANGE_VOLUME
	
	
	call	PLAY_INT
	call	enable_ROM_page1
	ret

mute_channel_3_PSG:

	ld	h,00
channel:	ld	l,0FBh	;self!!
	ld	bc,0002h
	ld	a,(channel+1)	;invert mute state for next
	xor	4	;FBh or FFh
	ld	(channel+1),a
	ld	a,(CHANNEL_state)
	xor	8	;0C4h	or 0CCh for next check
	ld	(CHANNEL_state),a
	
	jp	TMST1	;mute CALL

;-----------------------------------------------------
music_CHANGE_VOLUME:

		;complementary vaue to volumen in MGSDRV
	ld	b,a
	xor	a
	sub	b
	;rla
	ld	bc,00000h
	jp	MSVST

;------------------------------------------------

joymega_START_BUTTON:

	;before jp here:
	;cpl
	;rlca
	;rlca
	;rlca
	;and	07h
	;jp	....

	rlca
	and	07H	;1??-> F1 pressed
	jp	nz,05054h

	
	di
	ld      a, 15   ; Lee el puerto de joystick y almacena
        out     (#A0), a        ; los estados en las variables.
        in      a, (#A2)
        and     10101111b

        push    af
        out     (#A1), a
        ld      a, 14
        out     (#A0), a
        in      a, (#A2)
;        and     00111111b
        or      11000000b               ;Arreglo del fallo que da en algunos MSX o en OpenMSX

        ld      e, 0FFh
        cp      0F0h
        jr      z, .sigue               ;Si se detecta un raton, salta sin detectar pulsacion

        ld      e, a                    ;Si no hay pulsado nada, es FFh
                                        ;Carga en E si hay direcciones pulsadas o B o C
.sigue:
        ld      a, 15
        out     (#A0), a
        pop     af
        push    af
        or      00010000b
        out     (#A1), a
        ld      a, 14
        out     (#A0), a
        in      a, (#A2)
        ld      d, a
        ld      a, 15
        out     (#A0), a
        pop     af
        or      00010000b
        out     (#A1), a
        and     11101111b
        out     (#A1), a

        ld      a, d
        and     00100000b
        ld      a, 0
	jr	nz,no_pressed_START
        ld      a, 1
   
	
no_pressed_START:

	ei
	jp	05054h



;----------------------------------------------
songs_table:

	db	song1
	dw	song1_adress
	db	song2
	dw	song2_adress
	db	song3
	dw	song3_adress
	db	song4
	dw	song4_adress
	db	song5
	dw	song5_adress

	db	song2
	dw	song2_adress

	db	song6
	dw	song6_adress
	db	song7
	dw	song7_adress

	db	song7
	dw	song7_adress

	db	song8
	dw	song8_adress
	db	song9
	dw	song9_adress
	db	song10
	dw	song10_adress
	db	song11
	dw	song11_adress
	db	song12
	dw	song12_adress
	db	song13
	dw	song13_adress
	
total_normal_songs:	equ	015

	db	song_SAD1
	dw	song_SAD1_adress
	db	song_SAD2
	dw	song_SAD2_adress
	db	song_SAD3
	dw	song_SAD3_adress
	db	song_SAD4
	dw	song_SAD4_adress
	db	song_SAD5
	dw	song_SAD5_adress


	db	song_ANGRY1
	dw	song_ANGRY1_adress
	db	song_ANGRY2
	dw	song_ANGRY2_adress
	db	song_ANGRY3
	dw	song_ANGRY3_adress
	db	song_ANGRY4
	dw	song_ANGRY4_adress
	db	song_ANGRY5
	dw	song_ANGRY5_adress

	db	song_JOY1
	dw	song_JOY1_adress
	db	song_JOY2
	dw	song_JOY2_adress
	db	song_JOY3
	dw	song_JOY3_adress
	db	song_JOY4
	dw	song_JOY4_adress
	db	song_JOY5
	dw	song_JOY5_adress

;-------------------------------------------------------------
routines_in_RAM_END:
		;
		;
;--------------------------------------------------------------

OUTIS_RAM:


set_VRAM_sprite1:
	
	ld	l,00h
	ld	a,(VPLT_actual)
	xor	01h
	;and	01h
	
	ld	h,74h
	ret	z
	ld	h,0f4h	
	ret
set_VRAM_sprite2:
	ld	l,00h
	ld	a,(VPLT_actual)
	xor	01h
	;and	01h
	
	ld	h,76h
	ret	z
	ld	h,0f6h	
	ret	
	
	

block_OUTIS_1:	;0166Bh in ROM;0162h in ROM

	;ld	b,8
more_OUTIS_1:	
	
	ld	l,a
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	add	a,048h
	and	078h
	dec	d
	jr	nz,more_OUTIS_1
	
	
	;change VPLT in next VBLANK
	ld	a,(VPLT_actual)
	xor	01h
	;and	01h
	ld	(VPLT_actual),a;remember new VPLT
	
	
	ret






block_OUTIS_2: ;01682h in ROM

more_OUTIS_2:

	ld	h,06Eh
	ld	l,a
	add	hl,hl

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
	add	a,090h
	dec	d
	jr	nz,more_OUTIS_2
	ret	
	
OUTIS_RAM_END:	
	
	
	
	
	
	
	
	ds	011800h-$-(end_block-Part_10)


;--------------------------------------------------------
;--------------------------------------------------------
;--------------------------------------------------------
;--------------------------------------------------------
;Part 011h
page_MGSDRV:	equ	011h
	incbin	"MGSEL_driver_in_RAM.rom"

;--------------------------------------------------------
;--------------------------------------------------------
;--------------------------------------------------------
;--------------------------------------------------------
;Part 012h

page_MGSDRV_MFRSD:	equ	012h

	incbin	"MGSEL_driver_in_RAM_MFRSD.rom"

;------------------------------------------------
;Lista canciones(13 diferentes)	Call 56E3h valor en A
;Part 013h
song1:	equ	013h
song1_adress:	equ 0A000h

	
	org	0
	dw	song1_E-2
	incbin	"USAS_SCC\USTAGE1S.MGS"
	;incbin	"YS1FI.MGS"
song1_E:	



	ds	02000h-$

;Part 014h
song2:	equ	014h
song2_adress:	equ 0A000h
	org	0
	dw	song2_E-2
	incbin	"USAS_SCC\USTAGE2S.MGS"

song2_E:	ds	02000h-$
;Part 015h
song3:	equ	015h
song3_adress:	equ 0A000h
	org	0
	dw	song3_E-2
	incbin	"USAS_SCC\USTAGE3S.MGS"

song3_E:	ds	02000h-$
;Part 016h
song4:	equ	016h
song4_adress:	equ 0A000h
	org	0
	dw	song4_E-2
	incbin	"USAS_SCC\USTAGE4S.MGS"

song4_E:	ds	02000h-$
;Part 017h
song5:	equ	017h
song5_adress:	equ 0A000h
	org	0
	dw	song5_E-2
	incbin	"USAS_SCC\USTAGE5S.MGS"

song5_E:	ds	02000h-$

;Part 018h
song6:	equ	018h
song6_adress:	equ 0A000h
	org	0
	dw	song6_E-2
	incbin	"USAS_SCC\UTEMPLES.MGS"
song6_E:

song7:	equ	018h
song7_adress:	equ 0a000h+$
	dw	song7_E-2
	incbin	"USAS_SCC\UBOSSS.MGS"
song7_E:


song8:	equ	018h
song8_adress:	equ 0a000h+$
	dw	song8_E-2
	incbin	"USAS_SCC\USELECTS.MGS"
song8_E:


	ds	02000h-$

;Part 019h
song9:	equ	019h
song9_adress:	equ 0A000h
	org	0
	dw	song9_E-2
	incbin	"USAS_SCC\UINTROS.MGS"
song9_E:
	
song10:	equ	019h
song10_adress:	equ 0a000h+$
	dw	song10_E-2
	incbin	"USAS_SCC\UINTERS.MGS"
song10_E:	
			
	ds	02000h-$

;Part 01ah
song11:	equ	01ah
song11_adress:	equ 0A000h
	org	0
	dw	song11_E-2
	incbin	"USAS_SCC\UENDS.MGS"
song11_E:
	
song12:	equ	01ah
song12_adress:	equ 0a000h+$
	dw	song12_E-2
	incbin	"USAS_SCC\UMISSS.MGS"
song12_E:	
		
song13:	equ	01ah
song13_adress:	equ 0a000h+$
	dw	song13_E-2
	incbin	"USAS_SCC\UGOVERS.MGS"
song13_E:	
		
	ds	02000h-$
;Part 01Bh
;-----------------------------------------------------------
;SAD EMOTICON

song_SAD1:	equ	01Bh
song_SAD1_adress:	equ 0a000h
	org	0
	dw	song_SAD1_E-2
	incbin	"USAS_SCC\USAS1SAD.MGS"
song_SAD1_E:	
		
	ds	02000h-$

song_SAD2:	equ	01ch
song_SAD2_adress:	equ 0a000h
	org	0
	dw	song_SAD2_E-2
	incbin	"USAS_SCC\USAS2ANG.MGS"
song_SAD2_E:	
		
	ds	02000h-$


song_SAD3:	equ	01Dh
song_SAD3_adress:	equ 0a000h
	org	0
	dw	song_SAD3_E-2
	incbin	"USAS_SCC\USAS3SAD.MGS"
song_SAD3_E:	
		
	ds	02000h-$

song_SAD4:	equ	01eh
song_SAD4_adress:	equ 0a000h
	org	0
	dw	song_SAD4_E-2
	incbin	"USAS_SCC\USAS4ANG.MGS"
song_SAD4_E:	
		
	ds	02000h-$

song_SAD5:	equ	01Fh
song_SAD5_adress:	equ 0a000h
	org	0
	dw	song_SAD5_E-2
	incbin	"USAS_SCC\USAS5ANG.MGS"
song_SAD5_E:	
		
	ds	02000h-$
;---------------------------------------------------
;-----------------------------------------------------------
;ANGRY EMOTICON

song_ANGRY1:	equ	020h
song_ANGRY1_adress:	equ 0a000h
	org	0
	dw	song_ANGRY1_E-2
	incbin	"USAS_SCC\USAS1ANG.MGS"
song_ANGRY1_E:	
		
	ds	02000h-$

song_ANGRY2:	equ	021h
song_ANGRY2_adress:	equ 0a000h
	org	0
	dw	song_ANGRY2_E-2
	incbin	"USAS_SCC\USAS2SAD.MGS"
song_ANGRY2_E:	
		
	ds	02000h-$


song_ANGRY3:	equ	022h
song_ANGRY3_adress:	equ 0a000h
	org	0
	dw	song_ANGRY3_E-2
	incbin	"USAS_SCC\USAS3ANG.MGS"
song_ANGRY3_E:	
		
	ds	02000h-$

song_ANGRY4:	equ	023h
song_ANGRY4_adress:	equ 0a000h
	org	0
	dw	song_ANGRY4_E-2
	incbin	"USAS_SCC\USAS4SAD.MGS"
song_ANGRY4_E:	
		
	ds	02000h-$

song_ANGRY5:	equ	024h
song_ANGRY5_adress:	equ 0a000h
	org	0
	dw	song_ANGRY5_E-2
	incbin	"USAS_SCC\USAS5SAD.MGS"
song_ANGRY5_E:	
		
	ds	02000h-$
;---------------------------------------------------
;-----------------------------------------------------------
;JOY EMOTICON

song_JOY1:	equ	025h
song_JOY1_adress:	equ 0a000h
	org	0
	dw	song_JOY1_E-2
	incbin	"USAS_SCC\USAS1JOY.MGS"
song_JOY1_E:	
		
	ds	02000h-$

song_JOY2:	equ	026h
song_JOY2_adress:	equ 0a000h
	org	0
	dw	song_JOY2_E-2
	incbin	"USAS_SCC\USAS2JOY.MGS"
song_JOY2_E:	
		
	ds	02000h-$


song_JOY3:	equ	027h
song_JOY3_adress:	equ 0a000h
	org	0
	dw	song_JOY3_E-2
	incbin	"USAS_SCC\USAS3JOY.MGS"
song_JOY3_E:	
		
	ds	02000h-$

song_JOY4:	equ	028h
song_JOY4_adress:	equ 0a000h
	org	0
	dw	song_JOY4_E-2
	incbin	"USAS_SCC\USAS4JOY.MGS"
song_JOY4_E:	
		
	ds	02000h-$

song_JOY5:	equ	029h
song_JOY5_adress:	equ 0a000h
	org	0
	dw	song_JOY5_E-2
	incbin	"USAS_SCC\USAS5JOY.MGS"
song_JOY5_E:	
		
	ds	02000h-$
;---------------------------------------------------
;---------------------------------------------------

;Part	01Ch
;0 part for PSG
Part0_PSG_page:	equ 02Ah
	incbin	"USAS_part0_PSG.rom"

;Part	01Dh
;0 part for PSG
Part8_PSG_page:	equ 02Bh
	incbin	"USAS_part8_PSG.rom"
	
;Part 01Eh and 01Fh

	
	
	
	
	
	
	ds	02000h * (30H-2cH)
;
;80: Stage 1
;81: Stage 2
;82: Stage 3
;83: Stage 4
;84: Stage 5
;85: Stage 2??
;86: Temple
;87: Boss
;88: Boss??
;89: Select Stage
;8A: Intro - Start
;8B: Interlude
;8C: Ending
;8D: Dead
;8E: Game Over
