
	output"GR8FL.COM"
;*** FLPGR8.COM by Victor Martinez

;*** ROM Loader for GR8NET Cartridge

; Assembled with zasm cross assembler
; http://sourceforge.net/projects/zasm/


RUTrutin equ	07B00h

iniline	equ	0FB00h


GR8PG0	equ	05FE0h
GR8PG1	equ	05FE1h
GR8PG2	equ	05FE2h
GR8PG3	equ	05FE3h

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
	org	0100h

START:
	jp	Main



DosErr:
	db	"File reading error!",CR,LF,"$"
FlsEra:
	db	"Flash erasing...$"
FlsEok:
	db	"OK",CR,LF,CR,LF,"$"
FlsErr:
	db	"Flash writing error!",CR,LF,"$"

RCnumErr:
	db	"KONAMI RC number error!  Example: GR8FL GRADIUS2.ROM /K746",CR,LF,"$"
MAPnumErr:
	db	"Mapper type error!  Example: GR8FL GRADIUS2.ROM /M3 (from 1 to 6)",CR,LF,"$"
DonMes:
	db	CR,LF,CR,LF,"Load complete. Thank you.",CR,LF,"$"
GR8FND:
	db	"GR8NET Cartridge found in Slot $"
NO_FLSH:
	db	"GR8NET Cartridge not found!",CR,LF,"$"
WarnMess:
	db	"You have selected a slot that",CR,LF
	db	"contains a DISK-ROM!",CR,LF,"$"
ConfirmMess:
	db	"Do you want to erase it? (Y/N)",CR,LF,"$"
CancelMess:
	db	"Canceled.",CR,LF,"$"

default_mapper:	db	0

Main:
	ld	de,MESVER
	ld	c,9
	call	BDOS		; Print MESVER message (FL info)

; *** Auto-detection routine

	ld	a,1
	out	(05Eh),a
	in	a,(05fh)
	ld	(ERMSlt),a
	cp	0ffh
	jr	z,NO_FND
	or	a
	jr	nz,primSlt
	
NO_FND:
	ld	de,NO_FLSH	; Pointer to NO_FLSH message
	jp	Done


primSlt:
	ld	a,2		;read default mapper type... nextor+512 kbytes RAM??
	out	(05Eh),a
	in	a,(05fh)
	ld	(default_mapper),a
	
	
FLH_FND:
	ld	a,(RAMAD1)
	ld	h,40h
	call	ENASLT		; Select Main-RAM in MSX"s Bank 1

	ld	de,GR8FND	; Pointer to AM29F0xx message
	ld	c,9
	call	BDOS		; Print AM29F0xx message
	
	ld	a,(ERMSlt)
	and	3
	add	a,30h
	ld	e,a
	ld	c,2
	call	BDOS		; Print primary Slot number

	ld	e,02Dh
	ld	c,2
	call	BDOS		; Print "-" character

	ld	a,(ERMSlt)
	and	0Ch
	srl	a
	srl	a
	add	a,30h
	ld	e,a
	ld	c,2
	call	BDOS		; Print secondary Slot number	

	ld	de,MESend
	ld	c,9
	call	BDOS		; Print 2x CR & LF character

; *** End of Auto-detection routine


	ld	hl,DMA
	ld	b,(HL)
	inc	b
	dec	b
	jr	nz,Parameters
	ld	de,HlpMes
	ld	c,9
	call	BDOS
	ret			; Jump if no parameter

Parameters:




; Check parameter /R
checkR:	
	ld	hl,DMA
	ld	b,(HL)
	ld	c,052h		; 'R' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if Megaflashrom not detected
	ld	(RESET),a


; Check parameter /P

	ld	hl,DMA
	ld	b,(HL)
	ld	c,050h		; 'P' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(PAL),a
	
; Check parameter /N

	ld	hl,DMA
	ld	b,(HL)
	ld	c,04Eh		; 'N' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(NTSC),a
	

; Check parameter /I

	ld	hl,DMA
	ld	b,(HL)
	ld	c,049h		; 'I' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(INT),a
	

; Check parameter /J

	ld	hl,DMA
	ld	b,(HL)
	ld	c,04Ah		; 'J' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(JAP),a
	


; Check parameter /C

	ld	hl,DMA
	ld	b,(HL)
	ld	c,043h		; 'C' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(CCOL),a
	

	

; Check parameter /T

	ld	hl,DMA
	ld	b,(HL)
	ld	c,054h		; 'T' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(TURBO),a


; Check parameter /K7xx
	
	ld	hl,DMA
	ld	b,(HL)
	ld	c,04Bh		; 'K' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	
	or	a
	jr	z,nok77

	call	GetRC		; Get the slot number from parameter
	or	a
	ld	de,RCnumErr
	jp	z,Done		;Jump if RC number error

	ld	(RC),a	; ERMSlt = Slot number from option S	

nok77:

; Check parameter /Mx
	
	ld	hl,DMA
	ld	b,(HL)
	ld	c,04Dh		; 'M' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	
	or	a
	jr	z,noM

	call	GetMAP		; Get the mapper number
	or	a
	ld	de,MAPnumErr
	jp	z,Done		;Jump if RC number error

	ld	(Mapper_forced),a	; ERMSlt = Slot number from option S	
	
noM:


; Check parameter /X

	ld	hl,DMA
	ld	b,(HL)
	ld	c,058h		; 'X' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(NO_EXECUTE),a

; ------------------------------------------- Type of Mapper in file

	ld	bc,24		; Prepare the FCB
	ld	de,FCB+13
	ld	hl,FCB+12
	ld	(hl),b
	ldir			; Initialize the second half with zero

	ld	c,0fh
	ld	de,FCB
	call	BDOS		; Open file
	ld	hl,1
	ld	(FCB+14),hl	; Record size = 1 byte
	or	a
	ld	de,DosErr
	jp	nz,Done


	;------------------------- calculate numbre of pages

				;-----  longitud
		;+
	ld	hl,FCB+17

	 ld	c,(hl)
	 inc	hl
	 ld	a,(hl)
	
	ld	b,3
b_size1: rl	c
	rla
	djnz	b_size1
	

	ld	c,1ah
	ld	de,BUFTOP
	call	BDOS		; Set disk transfer address (buffer start at 8000H)
	
	ld	c,27h
	ld	de,FCB
	ld	hl,4000h	; Number of records to read
	call	BDOS		; Read a block from file
	
	;--------------------------------- Search ROM Type

nortexe:
	push	af
	push	hl
	push	de
	push	bc
	
	
	
	
	call	bus_tipo
	

	cp	01
	jr nz,noNOMA
	
	ld	de,NOMA
	jp	printtype

noNOMA:	cp	02
	jr nz,noNOK4
	ld	de,K4
	jp	printtype
	
noNOK4:	cp	03
	jr nz,noNOK8
	ld	de,K8
	jp	printtype
	
noNOK8:	cp	04
	jr nz,noNOAS8
	ld	de,AS8
	jp	printtype
	
noNOAS8:	
	cp	086h
	jr nz,noNOLODE
	ld	de,SLRUN
	jp	printtype

noNOLODE:
	
	cp	087h
	jr nz,noRTYPE
	ld	de,RTYPE
	jp	printtype

noRTYPE:	
	cp	06h
	ld	de,MIRRORED
	jr	nz,NO_MIRRORED
	jp	printtype

NO_MIRRORED:
	ld	de,AS16

printtype:
	
	ld	c,9
	call	BDOS

	ld	c,10h
	ld	de,FCB
	call	BDOS		; Open file

	pop	bc
	pop	de
	pop	hl
	pop	af


	jp	PreFCB

; Seek Parameter Routine
; In: B = Length of parameters zone, C = Character, HL = Pointer address
; Out: A = 0 if Parameter not found or 255 if syntax error, DE = HlpMes if syntax error
; Modify AF, BC, HL

SeekParameter:
	inc	hl
	ld	a,(hl)
	cp	02Fh		; Seek '/' character
	jr	nz,ParamBCL
	inc	hl
	ld	a,(hl)
	and	0dfh
	cp	c		; Compare found character with the input character
	ret	z
	call	SyntaxCheck
	cp	255
	ret	z
ParamBCL:
	djnz	SeekParameter
	xor	a
	ret
SyntaxCheck:
	push	hl
	push	bc
	cp	049h		; 'I' character
	jr	z,SyntaxOK
	cp	04Ah		; 'J' character
	jr	z,SyntaxOK

	cp	052h		; 'R' character
	jr	z,SyntaxOK
	cp	053h		; 'S' character
	jr	z,SyntaxOK
	cp	054h		; 'T' character
	jr	z,SyntaxOK
	cp	043h		; 'C' character
	jr	z,SyntaxOK
	cp	050h		; 'P' character
	jr	z,SyntaxOK
	cp	04Eh		; 'N' character
	jr	z,SyntaxOK
	cp	04Bh		; 'K' character
	jr	z,SyntaxOK
	cp	04Dh		; 'M' character
	jr	z,SyntaxOK
	cp	058h		; 'X' character
	jr	z,SyntaxOK

BadSynt:
	ld	de,HlpMes
	ld	a,255		; Syntax error
SyntaxOK:
	pop	bc
	pop	hl
	ret

PreFCB:
; ----
	
	
	ld	bc,24		; Prepare the FCB
	ld	de,FCB+13
	ld	hl,FCB+12
	ld	(hl),b
	ldir			; Initialize the second half with zero

	ld	c,0fh
	ld	de,FCB
	call	BDOS		; Open file
	ld	hl,1
	ld	(FCB+14),hl	; Record size = 1 byte
	or	a
	ld	de,DosErr
	jp	nz,Done

	ld	c,1ah
	ld	de,BUFTOP
	call	BDOS		; Set disk transfer address (buffer start at 8000H)


 
SKIP:


	ld	a,(RAMAD1)
	ld	h,40h
	call	ENASLT		; Select Main-RAM at bank 4000h~7FFFh

_8kL01:
	ld	c,27h
	ld	de,FCB
	ld	hl,2000h	; Number of records to read
	call	BDOS		; Read a block from file

	push	hl
	
	
	ld	hl,FCB+16




	xor	a
	or	(hl)
	inc	hl
	or	(hl)
	inc	hl
	or	(hl)
	inc	hl
	or	(hl)
	ld	(FileSize),a	; Get a simple value to test file size 
	

	pop	hl


	ld	a,(PreBnk)		;>1024 Kbytes!!!
	cp	80h
	ld	de,DonMes
	jp	z,Done
	
	
	

	ld	a,h
	or	l
	ld	de,DonMes
	jp	nz,CONTloading	; Jump if record is readed

	
	
	ld	a,(PreBnk)
	cp	1
	jr	z,MakeMirror
	cp	2
	jr	z,MakeMirror
	cp	3
	jp	z,FLashPage	; FLash Page 1 again to page 3
	jp	Launch			; Jump if any record is readed

	
MakeMirror:
	ld	a,(FileSize)
	cp	20h
	jp	z,FLashPage	; Jump if 8KB rom

Make16KMirror:
	ld	a,(ERMSlt)
	ld	h,40h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh

	ld	a,(PreBnk)
	ld	(GR8PG1),a	; Select Flashrom page at Bank 4000h~7FFFh for SCC mapper

	ld	bc,2000h	; Length
	ld	de,6000h	; Destination
	ld	hl,0A000h	; Source
	jp	Loop

CONTloading:
	ld	a,h
	cp	20h
	ld	de,DosErr
	jp	nz,Done		; Jump if readed records number is not 2000h

	;ld	a,(PreBnk)
	;or	a
	;jr	nz,SKIP_PatchRomHeader

noEnd:	
	ld	a,(INT)
	or	a
	call	nz,putINT
	ld	a,(JAP)
	or	a
	call	nz,putJAP

	
	
	
	ld	a,(tipo_detec)
	cp	1
	jr	nz,noMIRROR
	
	
	jr	noFSCC
	
noMIRROR:	
	

	;cp	7
	;jp	z,patchrtype

noFSCC:	ld	a,(BUFTOP)
	cp	41h
	jr	nz,SKIP_PatchRomHeader
	ld	a,(BUFTOP+1)
	cp	42h
	jr	nz,SKIP_PatchRomHeader

	ld	a,(FileSize)
	cp	40h
	jr	nz,SKIP_PatchRomHeader

;-------------------------------------------------------------------------

	
	






nochange:


	ld	hl,BUFTOP
	ld	de,0A000h
	ld	bc,2000h
	ldir			; backup of page 0 for 16KB Rom

PatchHead:
	ld	hl,(BUFTOP+2)
	ld	a,h
	cp	80h
	jr	c,SKIP_PatchRomHeader	; Jump Start address is > 7FFFh

	ld	a,(BUFTOP+2)		;Choro Q!!!!!!
	cp	04h
	jr	z,SKIP_PatchRomHeader


	ld	hl,BUFTOP+8h
	ld	(hl),0			; Remove pointer for Basic
	inc	hl
	ld	(hl),0			; Remove pointer for Basic
SKIP_PatchRomHeader:



FLashPage:	
	ld	a,(ERMSlt)
	ld	h,40h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh

	ld	a,(PreBnk)
	ld	(GR8PG1),a	; Select Flashrom page at Bank 4000h~7FFFh for SCC mapper

	
	cp	04h
	call	z,rc725
			

	ld	bc,2000h	; Length
	ld	de,6000h	; Destination
	ld	hl,BUFTOP	; Source
	
Loop:
	ldir
	;push	af		;restore GR8NET page FF
	;ld	a,0FFh
	;ld	(GR8PG1),a
	;pop	af


	ei
	ld	a,(RAMAD1)
	ld	h,40h
	call	ENASLT		; Select Main-RAM at bank 4000h~7FFFh

	ld	a,(PreBnk)
	inc	a
	ld	(PreBnk),a	; Increments Rom mapper page

	
	;------------------------------------  RType??????
	
	
	

	
noMIRR:	
	ld	a,(PreBnk)
	dec	a

	and	0fh
	cp	10
	jr	c,_8kR01
	add	a,7		; add	a,'A'-'0'-10
_8kR01:
	add	a,030h		; add	a,'0'
	ld	e,a
	ld	c,2
	call	BDOS		; Print current mapper page number
 
	ld	a,(PreBnk)
	and	0fh
	jp	nz,_8kL01
	ld	e,CR
	ld	c,2
	call	BDOS		; Print CR character
	ld	e,LF
	ld	c,2
	call	BDOS		; Print LF character
	jp	_8kL01



; ~~~ Routine that check if Megaflash is insered in /Sxx Slot


Launch:
	
	ld	hl,rutExeC000
	ld	de,0C000h
	ld	bc,fin_rutEXE-rutExeC000
	ldir
	
	

	ld	a,(RESET)
	cp	052h		; Seek 'R' character
	jr	z,ResetRoutine
	
	ld	a,(tipo_detec)	;Is a Mirrored ROM?? Then RESET
	cp	086h
	jr	z,ResetRoutine

	ld	a,(NO_EXECUTE)
	or	a
	jr	z,no_X_selected

				;save mapper type and launch adress and RET to DOS

	ld	hl,(4002h)
	ld	(0F600h),hl

	ld	a,(tipo_detec)
	ld	(0F602h),a

	RET	;No execute and RET to DOS



no_X_selected:

	di

	call	putPARAMS
NoReset:
	ld	a,(ERMSlt)	;slot GR8NET
	ld	h,040h
	call	ENASLT
	
		
	ld	a,(tipo_detec)
	cp	01
	jr	nz,exe1
	ld	a,(ERMSlt)
	ld	h,080h
	call	ENASLT


exe1:	ld	hl,0FEDAh
	push	hl
	
	ei
	halt
	
	ld	a,2		;select mapper type in GR8NET
	out	(05Eh),a	
	ld	a,(tipo_detec)
	and	0Fh
	ld	b,a

	ld	a,(default_mapper)
	cp	24
	ld	a,b
	jr	nz,no_nextor1

	
	add	a,16	;mapper type+RAM 512



no_nextor1:
	
	
	
	
	out	(05fh),a
	
	ld	a,(4003h)
	cp	057h
	jr	nz,noDSK
	ld	a,(4004h)
	cp	0aah
	jr	nz,noDSK
	jr	ResetRoutine
	
noDSK:	jp	0C000h
	; selecciona BIOS en pagina 0
	; y ejecuta.

	
	
	

rutExeC000:


	

	in	a,(0a8h)
	and	0FCh
	out	(0a8h),a

	ld	a,0c9h
	ld	(0fd9ah),a
	ld	(0fd9fh),a

	



	ld	hl,(4002h)
	jp	hl
	
saveexe:
	jp 00000h ;self----

fin_rutEXE:





ResetRoutine:
	ld	a,2		;select mapper type in GR8NET
	out	(05Eh),a	
	
	

	
	ld	a,(tipo_detec)
	and	0Fh
	ld	b,a

	ld	a,(default_mapper)
	cp	24
	ld	a,b
	jr	nz,no_nextor2

	
	add	a,16	;mapper type+RAM 512



no_nextor2:
	
	out	(05fh),a
	rst	030h
	db	0
	dw	0000h
			; msx reset
;----------------------------------------------------------------------------------------
putPARAMS:
	rst	030h		;Inicialize VDP & SCREEN 2
	db	0
	dw	0072h
	


MSX_VER:
	
	ld	a,080h	;slot 0-0
	ld	hl,002dh
	call	000ch		;rdslt
	
	ld	(MSXV+1),a
	or	a		;MSX1???
	ret	z


	ld	a,(PAL)
	or	a
	jr	z,noputPAL

putPAL:	
	ld	hl,0ffe8h
	ld	a,(hl)
	or	2
	ld	(hl),a
	ld	c,9
	ld	b,a
	rst	030h
	db	0
	dw	047h

	jr	coolcolors

noputPAL:
	
	ld	a,(NTSC)
	or	a
	jr	z,noputNTSC

putNTSC:	
	ld	hl,0ffe8h
	ld	a,(hl)
	and	0FCh
	ld	(hl),a
	ld	c,9
	ld	b,a
	rst	030h
	db	0
	dw	047h


noputNTSC:
coolcolors:
	
	
	ld	a,(CCOL)
	or	a
	jr	nz,noCCOL

	xor	a
	di
	out	(099h),a		;put Cool Colors
	ld	a,090h
	ei
	out	(099h),a
	ld	hl,palette
	ld	bc,0209ah
	otir
	di

noCCOL:

	
	ld	a,(TURBO)
	or	a
	jr	nz,putTURBO
	ld	a,080h
	ld	(turb1+1),a
	ld	(turb2+1),a
	
	

putTURBO:
				;Si es un Panasonic 2+, activamos Turbo
	LD	A,8
	OUT 	(040H),A	;out the manufacturer code 8 (Panasonic) to I/O port 40h
	IN	A,(040H)	;read the value you have just written
	CPL			;complement all bits of the value
	CP	8		;if it does not match the value you originally wrote,
	JR	NZ,Not_WX	;it is not a WX/WSX/FX.
turb1:	ld	a,00  ;self!!		;write 0 to I/O port 41h
	OUT	(041H),A	;and the mode changes to high-speed clock
	jr	endturbo

Not_WX: 
MSXV:	ld	a,00	;self !! MSX version
	cp	3
	jr	nz,endturbo
turb2:	ld	a,081h    ;self!!
	rst	030h
	db	0
	dw	00180h
;----------------------------------------------- put RC

endturbo:	

	ld	a,(RC)
	ld	(RCnum+1),a
	or	a
	call	nz,putRC

	ret



putRC:
	ld	a,2
	out	(0FEh),a
	ld	hl,04443h
	ld	(8010h),hl
	ld	a,07h
	ld	(8012h),a
RCnum:	ld	a,00	;KONAMI RC number
	ld	(8013h),a
	
	cp	040h
	jr	z,RCTWINBEE
	cp	035h
	jr	z,RCGAME
	cp	046h
	jr	z,RCQBERT
	cp	039h
	jr	z,RCKNIGH
	ret	nz

RCTWINBEE:
	ld	hl,twinbeepatch
	jr	patchrc
	
RCGAME:
	ld	hl,gmasterpatch
	jr	patchrc
	
RCQBERT:
	ld	hl,qbertpatch
	jr	patchrc
RCKNIGH:
	ld	hl,knightpatch
	jr	patchrc

patchrc:
	ld	de,rcrom
	ld	bc,0006h
	ldir
	


nok7:	ld	hl,rcrom
	ld	de,0bffah
	ld	bc,0006h
	ldir
	
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



rcrom:		db	000h,000h,000h,000h,000h,000h

;--------------------------------------------------------------------



twinbeepatch:	db	0Ach,081h,091h,006h,040h,0aah
gmasterpatch:	db	000h,030h,031h,013h,035h,0aah
qbertpatch:	db	0bah,0b2h,086h,007h,046h,0aah
knightpatch:	db	0b7h,08bh,09eh,00ah,039h,0aah













;----------------------------------------------------------------------------------
Done:

	ei
	push	de
	ld	a,(RAMAD1)
	ld	h,40h
	call	ENASLT		; Select Main-RAM at bank 4000h~7FFFh
	ld	a,(RAMAD2)
	ld	h,80h
	call	ENASLT		; Select Main-RAM at bank 8000h~BFFFh
	pop	de

	ld	c,9
	call	BDOS		; Print final message

;	ld	de,HlpMes	; Pointer to Help message
;	ld	c,9
;	call	BDOS		; Print final message

	rst	0

;-------------------------------------------------------------------------------------------



GetNum:
	ld	de,0
GetL01:
	inc	hl
	ld	a,(hl)
	sub	030h		; sub	'0'
	ret	c
	cp	10
	jr	c,GetR01
	and	0dfh
	sub	7		; sub	'A'-'0'-10
	ret	c
	cp	16
	ccf
	ret	c
GetR01:
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	add	a,e
	ld	e,a
	jr	GetL01
;-------------------------------------------------------

;KONAMI RCs in the other slot!!

GetRC:
	
	push	hl
	push	de

	
	ld	de,0

	inc	hl
	ld	a,(hl)
	cp	37h		;check 7 number
	jr	z,yes7

errRC:	pop	de
	pop	hl

	xor	a
	ret
	
yes7:
	inc	hl
	ld	a,(hl)
	
	cp	030h
	jr	c,errRC

	cp	03Ah		;bigger than "9" character?? Error!!
	jr	nc,errRC

	sub	030h		; sub	'0'
	
	
	and	a
	rla
	rla
	rla
	rla

	ld	d,a

	inc	hl
	ld	a,(hl)
	cp	030h
	jr	c,errRC

	cp	03Ah		;bigger than "9" character?? Error!!
	jr	nc,errRC

	sub	030h		; sub	'0'
	
	ld	e,a

	ld	a,d
	add	a,e
	
	pop	de
	pop	hl

	ret

;-------------------------------------------------------

;FOrce Mapper Type!!

GetMAP:
	push	hl
	
	inc	hl
	ld	a,(hl)
	
	cp	031h
	jr	c,errMAP

	cp	037h		;bigger than "6" character?? Error!!
	jr	nc,errMAP

	sub	030h		; sub	'0'
	
	pop	hl
	ret

errMAP:	
	pop	hl

	xor	a
	ret
;----------------------------------------------------
; Routine to patch Megaroms

MEGpatch:
	ld	a,(PreBnk)
	cp	(hl)		; compare page number
	ret	nz		; Back if page number differs
	inc	hl
	ld	a,(hl)
	ld	(patchID),a	; Change patch ID
	inc	hl
	ld	b,(hl)		; B = Number of patch
	push	hl
VERdata:
	inc	hl
	ld	c,(hl)		; C = Original value
	inc	hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl		; hl = address to apply patch
	ld	a,c
	cp	(hl)
	jr	nz,NOpatch	; Jump if a data differs
	ex	de,hl
	djnz	VERdata
	pop	hl
	ld	b,(hl)
BCLpatch:
	inc	hl
	inc	hl
	ld	c,(hl)		; B = New value
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl		; hl = address to apply patch
	ld	(hl),c		; change select page address
	ex	de,hl
	djnz	BCLpatch
	ld	a,(patchID)
	ld	(CURRpatchID),a	; Write current patch ID 
	ret
NOpatch:
	pop	hl
	ret

;---------------------------------------------------
	

	
	
	
	
	
		

	
	



	
;--------------------------------------------------------------------
PAL:	db	0
NTSC:	db	0
INT:	db	0
JAP:	db	0
CCOL:	db	0
FSCC:	db	0
TURBO:	db	0
EXEC:	db	0
MAPPER:	db	0
SPECIAL: db	0
DISK:	db	0
RC:	db	0
GMAST1:	db	0


bus_tipo:
	
	ld	a,(Mapper_forced)
	or	a
	jp	nz,fin_detec
	
	
	and a
	ld	hl,(08127h)		;Super Lode Runner
	ld	bc,0C5A8h
	sbc	hl,bc
	jr	nz,noSLODERU
	
	
	ld	a,86h
	jp	fin_detec
	
noSLODERU:	
	
	and a
	ld	hl,(08000h)
	ld	bc,08008h	;R-Type
	sbc	hl,bc
	jr	nz,nortypem
	ld	a,87h
	jp	fin_detec

nortypem:

	and a
	ld	hl,(08046h)
	ld	bc,0414Bh	;Hydlide 3 MSX2
	sbc	hl,bc
	jr	nz,noHYD32
	ld	a,4
	jp	fin_detec

noHYD32:

	and a
	ld	hl,(08046h)
	ld	bc,0414Dh	;Hydlide 3 MSX
	sbc	hl,bc
	jr	nz,noHYD3
	ld	a,4
	jp	fin_detec

noHYD3:


	and a
	ld	hl,(08036h)
	ld	bc,0FC4Ch	;Andorogynus
	sbc	hl,bc
	jr	nz,noANDO
	ld	a,5
	jp	fin_detec

noANDO:
	
	and a
	ld	hl,(08036h)
	ld	bc,0CD23h	;Bomber King
	sbc	hl,bc
	jr	nz,noBOMBER
	ld	a,4
	jp	fin_detec

noBOMBER:
	
	and a
	ld	hl,(08036h)
	ld	bc,0C64Fh	;Fleet Commander
	sbc	hl,bc
	jr	nz,noFLEET
	ld	a,4
	jp	fin_detec

noFLEET:
	
	
	and a
	ld	hl,(08036h)		;Peng Wars 2
	ld	bc,0C03Fh
	sbc	hl,bc
	jr	nz,noPENWARS2
	ld	a,5
	jp	fin_detec

noPENWARS2:

;----------------------------------------

;check if is a Mirrored ROM (0000-FFFFh)

	ld	hl,(08002h)
	ld	de,04000h
	and	a
	sbc	hl,de
	jr	c,SETMAP_6
	and	a
	sbc	hl,de
	jr	nc,SETMAP_6
	jr	nopatc

	
SETMAP_6:

	ld	a,06h
	jp	fin_detec


nopatc:
	ld	hl,08000h
	ld	bc,04000h
b_look2: ld	a,(hl)
	cp	032h	;<<1
	jp	nz,no_11
	inc	hl
	ld	a,(hl)

	cp	00h	;<<2
	jr	z,si_00
	cp	41h	;<<2
	jr	z,si_00
	cp	0ffh	;<<2b   ISHITAR!!
	jr	z,si_00
	cp	0f8h	;<<2b	BUBBLE!!
	jr	z,si_00
	jr	nz,no_22

si_00:	inc hl
	ld a,(hl)
	cp	078h
	jr z,es_tipo_CC
	cp	06fh
	jr z,es_tipo_CC
	cp	068h
	jr z,es_tipo_CC
	cp	0A0h
	jr z,es_tipoK8
	cp	090h
	jr z,es_tipoK8S
	
	

no_11:	inc	hl
no_22:	dec	bc
	ld	a,b
	or	c
	jp	nz,b_look2
	
	;es un ASCII 16k  o un Mirrored???
	
	
	
	
	
	
	ld	hl,08000h
	ld	bc,04000h
b_look22:
	ld	a,(hl)
	cp	032h	;<<1
	jp	nz,no_111
	inc	hl
	ld	a,(hl)
	cp	00h	;<<2
	jr	z,si_000
	jr	nz,no_222

si_000:	
	inc hl
	ld a,(hl)
	cp	070h
	jr z,es_tipo_AS16
	cp	060h
	jr z,es_tipo_AS16
	cp	080h
	jr z,es_tipo_AS16

no_111:	inc	hl
no_222:	dec	bc
	ld	a,b
	or	c
	jp	nz,b_look22
	
	ld	a,1
	jr fin_detec


es_tipo_CC:
	ld	a,4
	jr fin_detec

es_tipoK8:
	ld	a,2
	jr fin_detec
es_tipoK8S:
	ld	a,3
	jr fin_detec

es_tipo_AS16:

	ld	a,5
	jr fin_detec


	;------------------------

fin_detec:
	ld (tipo_detec),a
	ld  (MAPPER),a

	and	a
	
	ret



;-----------------------------Patchs!!!!!

putINT:	ld	a,0FFh
	ld	(leg+1),a
	jr	patchLNG


putJAP:	ld	a,00h
	ld	(leg+1),a
	


patchLNG:
	
	
	ld	hl,08000h
	ld	bc,02000h
	
	

b_lookLNG:	ld	a,(hl)
	cp	03Ah
	jp	nz,sigBUSLNG
	inc	hl
	ld	a,(hl)
	cp	02Bh
	jp	z,yesLENGLNG
	dec	hl
	jp	sigBUSLNG

yesLENGLNG:
	inc	hl
	ld	a,(hl)
	dec	hl
	dec	hl
	or	a
	jr	nz,sigBUSLNG


yesLENG2LNG:
	
	ld	(hl),03eh
	inc	hl
leg:	ld	(hl),00	;self!! put INT (ff) or JAP (00)
	inc	hl
	ld	(hl),00
	dec	hl
	dec	hl
	dec	hl
	
sigBUSLNG:	inc	hl
no_2LNG:	dec	bc
	ld	a,b
	or	c
	jp	nz,b_lookLNG

	ret
;--------------------------------------------------------



	
;------------------------------------------------------------------------------------
salamander:
	
	
	
	push	af
	push	hl



oksalam:	ld	a,0	;self!!
	cp	058h
	jr	nz,nosalamander
	
	ld	a,(RC)
	cp	051h
	jr	nz,nosalamander

	ld	a,(hl)
	cp	0BEh		;patch SALAMANDER + GRADIUS 2!!
	jr	nz,nosalamander
	
	inc	hl
	ld	a,(hl)
	cp	0EBh
	jr	nz,nosalamander
	
	inc	hl
	ld	a,(hl)
	cp	20h
	jr	nz,nosalamander
	
	ld	(hl),28h

	
	

nosalamander:
	pop	hl
	pop	af
	ret



;------------------------------------------------------------------------------------
;	change ini execution in page 0






	
rc725:
	push	af
	ld	a,(RC)
	cp	25h
	jr	nz,noRC25
	ld	a,28h
	ld	(09FC7h),a
	ld	(09FCBh),a
noRC25:	pop af
	ret





;---------------------------------  


tipo_detec: db 0; self!

NOMA:	db	"ROM File:  Plain Mapper Type",CR,LF,"$"
K4:	db	"ROM File:  Konami Mapper Type",CR,LF,"$"
K8:	db	"ROM File:  Konami SCC Mapper Type",CR,LF,"$"
AS8:	db	"ROM File:  ASCII 8k Mapper Type",CR,LF,"$"
AS16:	db	"ROM File:  ASCII 16k Mapper Type",CR,LF,"$"
SLRUN:	db	"ROM File:  Super Lode Runner Mapper Type",CR,LF,"$"
RTYPE:	db	"ROM File:  R-Type Mapper Type",CR,LF,"$"
MIRRORED:	db	"ROM File:  Mirrored Mapper Type",CR,LF,"$"	


;------------------------------------



ERMSlt:
	db	0
RAMtyp:
	db	0
PreBnk:
	db	0
FLerase:
	db	0
MAN_ID:
	db	0
DEV_ID:
	db	0
;SEC_PROT:
;	db	0
patchID:
	db	0
CURRpatchID:
	db	0
FileSize:
	db	0
RESET:
	db	0
OverWR:
	db	"Y"
Mapper_forced:
	db	0
NO_EXECUTE:
	db	0

;--------------------------------------------------

MESVER:
	db	CR,LF,"GR8FL.COM v1.67 by Victor Martinez",CR,LF
	db	"Read and patch ROMs from LOCAL STORAGE DEVICE.",CR,LF
	db	"for GR8NET Cartridge by Eugeny Brychkov.",CR,LF
	db	"Based on FLLOAD by K.Tsujikawa."
MESend:
	db	CR,LF,CR,LF,"$"
HlpMes:
	
	
	db	"  /R  Reset Computer when game loaded                      ",CR,LF
	db	"  /I  Force International       /J  Force Japanese         ",CR,LF
	db	"  /P  Force PAL (50Hz)          /N  Force NTSC (60Hz)      ",CR,LF 
	db	"  /C  No change color palette to 'Cool Colors'             ",CR,LF
	db	"  /T  Force Turbo Mode (only for Turbo R and Panasonic 2+) ",CR,LF
	db	"  /K7xx Simulate KONAMI RC7xx inserted in the other slot   ",CR,LF
	db	"  /X  No Execute ROM after LOAD-> Back to DOS",CR,LF
	db	"  /Mx Force Mapper Type (1-6)",CR,LF
	db	CR,LF

	
	db	"   Usage: GR8FL filename[.ext] [/options]",CR,LF,"$"
	db	CR,"(^_^)/~",CR,LF,1ah



; --------
Anty_P1:
	db	1,0,8
	db	03Eh,03Eh,030h,8Ah, 007h,007h,031h,8Ah, 00Eh,00Eh,032h,8Ah, 0F8h,0B8h,033h,8Ah
	db	0D3h,0D3h,034h,8Ah, 0A0h,0A0h,035h,8Ah, 008h,008h,036h,8Ah, 079h,079h,037h,8Ah
; --------
AthleticBall:
	db	0,0,18
	db	0F0h,0B0h,056h,8Eh, 0F8h,0B8h,072h,8Eh, 0F0h,0B0h,080h,8Eh, 0FCh,0BCh,08Eh,8Eh
	db	0F8h,0B8h,09Ch,8Eh, 0FEh,0BEh,0A5h,92h, 0FEh,0BEh,088h,9Bh, 0F0h,0B0h,096h,9Bh
	db	0FEh,0BEh,0A4h,9Bh, 0FEh,0BEh,0B2h,9Bh, 0FEh,0BEh,0C0h,9Bh, 0FEh,0BEh,0CEh,9Bh
	db	0FEh,0BEh,0DCh,9Bh, 0FEh,0BEh,0EAh,9Bh, 0FEh,0BEh,0F8h,9Bh, 0FEh,0BEh,006h,9Ch
	db	0FEh,0BEh,014h,9Ch, 0FEh,0BEh,022h,9Ch


; --------
CarRace:
	db	0,0,33
	db	0FAh,0BAh,066h,8Eh, 0DEh,09Eh,005h,8Fh, 0FAh,0BAh,014h,8Fh, 016h,000h,046h,92h
	db	053h,058h,047h,92h, 0FFh,0E5h,000h,98h, 0FFh,03Ah,001h,98h, 0FFh,069h,002h,98h
	db	0FFh,0E0h,003h,98h, 0FFh,0FEh,004h,98h, 0FFh,041h,005h,98h, 0FFh,02Ah,006h,98h
	db	0FFh,063h,007h,98h, 0FFh,0E0h,008h,98h, 0FFh,028h,009h,98h, 0FFh,00Ah,00Ah,98h
	db	0FFh,0FEh,00Bh,98h, 0FFh,042h,00Ch,98h, 0FFh,02Ah,00Dh,98h, 0FFh,065h,00Eh,98h
	db	0FFh,0E0h,00Fh,98h, 0FFh,028h,010h,98h, 0FFh,003h,011h,98h, 0FFh,02Ah,012h,98h
	db	0FFh,067h,013h,98h, 0FFh,0E0h,014h,98h, 0FFh,07Eh,015h,98h, 0FFh,0E6h,016h,98h
	db	0FFh,03Fh,017h,98h, 0FFh,0F6h,018h,98h, 0FFh,080h,019h,98h, 0FFh,0E1h,01Ah,98h
	db	0FFh,0C9h,01Bh,98h
; --------
CrazyBuggy:
	db	0,13,8
	db	0C5h,076h,07Eh,81h, 076h,03Eh,07Fh,81h, 0AFh,001h,080h,81h, 0C1h,000h,086h,81h
	db	020h,0B7h,03Bh,83h, 005h,020h,03Ch,83h, 03Eh,004h,03Dh,83h, 001h,03Ch,03Eh,83h
CrazyBuggy_P1:
	db	1,13,12
	db	093h,0F4h,08Dh,93h, 000h,07Fh,08Eh,93h, 000h,0FEh,0F4h,9Fh, 000h,007h,0F5h,9Fh
	db	000h,0C2h,0F6h,9Fh, 000h,093h,0F7h,9Fh, 000h,0CBh,0F9h,9Fh, 000h,0FBh,0FAh,9Fh
	db	000h,0CBh,0FBh,9Fh, 000h,0B3h,0FCh,9Fh, 000h,0C3h,0FDh,9Fh, 000h,093h,0FEh,9Fh

; --------
Galaxian:
	db	0,0,8
	db	031h,031h,010h,80h, 000h,0FDh,011h,80h, 000h,0FFh,012h,80h, 0F3h,0F3h,013h,80h
	db	031h,031h,044h,80h, 000h,0FDh,045h,80h, 000h,0FFh,046h,80h, 0CDh,0CDh,047h,80h
; --------
Game80zemina:
	db	0,0,32
	db	040h,050h,036h,90h, 040h,050h,07Fh,94h, 040h,050h,0A1h,94h, 040h,050h,04Eh,9Fh
	db	001h,000h,039h,90h, 040h,070h,03Ah,90h, 001h,000h,082h,94h, 040h,070h,083h,94h
	db	001h,000h,051h,9Fh, 040h,070h,052h,9Fh, 002h,000h,066h,91h, 040h,090h,067h,91h
	db	002h,000h,086h,94h, 040h,090h,087h,94h, 002h,000h,093h,94h, 040h,090h,094h,94h
	db	002h,000h,0A4h,94h, 040h,090h,0A5h,94h, 003h,000h,06Bh,91h, 040h,0B0h,06Ch,91h
	db	003h,000h,0C0h,92h, 040h,0B0h,0C1h,92h, 003h,000h,0DAh,92h, 040h,0B0h,0DBh,92h
	db	003h,000h,0E4h,92h, 040h,0B0h,0E5h,92h, 003h,000h,0EEh,92h, 040h,0B0h,0EFh,92h
	db	003h,000h,08Ah,94h, 040h,0B0h,08Bh,94h, 003h,000h,097h,94h, 040h,0B0h,098h,94h
; --------

; --------


; --------
GoonR:
	db	0,7,21
	db	030h,038h,0C0h,84h, 010h,0A0h,021h,91h, 010h,0A0h,0C3h,91h, 011h,0A1h,0CBh,91h
	db	010h,0A0h,0EAh,91h, 011h,0A1h,0F8h,91h, 010h,0A0h,074h,95h, 010h,0A0h,08Fh,95h
	db	011h,0A1h,0C0h,95h, 010h,0A0h,0EEh,96h, 011h,0A1h,022h,97h, 010h,0A0h,07Bh,97h
	db	011h,0A1h,080h,97h, 010h,0A0h,084h,97h, 011h,0A1h,089h,97h, 010h,0A0h,08Dh,97h
	db	011h,0A1h,092h,97h, 010h,0A0h,096h,97h, 011h,0A1h,09Bh,97h, 010h,0A0h,09Fh,97h
	db	011h,0A1h,0A4h,97h
GoonR_P3:
	db	3,7,1
	db	021h,0C9h,01Dh,9Fh
GoonR_P4:
	db	4,7,2
	db	038h,030h,055h,82h, 038h,030h,059h,8Bh

; --------
Labyrinth:
	db	0,0,14
	db	068h,070h,0C9h,81h, 068h,070h,006h,85h, 068h,070h,017h,85h, 068h,070h,024h,85h
	db	070h,090h,0CEh,81h, 070h,090h,00Bh,85h, 070h,090h,01Ch,85h, 070h,090h,02Ah,85h
	db	078h,0B0h,010h,85h, 078h,0B0h,030h,85h, 060h,050h,0F8h,97h, 068h,070h,0F9h,97h
	db	070h,090h,0FAh,97h, 078h,0B0h,0FBh,97h
; --------
Manb2:
	db	0,0,8
	db	010h,0A0h,0DAh,87h, 011h,0A1h,0DDh,87h, 012h,0A2h,0EEh,87h, 011h,0A1h,025h,88h
	db	0BFh,0BFh,0C0h,91h, 034h,034h,0C5h,91h, 0DBh,0DBh,0EDh,87h, 00Eh,00Eh,024h,88h
 ;--------
Manb2v2:	; Patch not available
	db	0,0,8
	db	010h,0A0h,0DAh,87h, 011h,0A1h,0DDh,87h, 012h,0A2h,0EEh,87h, 011h,0A1h,025h,88h
	db	010h,0A0h,0C0h,91h, 011h,0A1h,0C5h,91h, 0DBh,0DBh,0EDh,87h, 00Eh,00Eh,024h,88h
; --------


; --------

; --------
Nausicaa:
	db	0,0,10
	db	0FFh,0BFh,013h,85h, 0E9h,0A9h,023h,85h, 0E0h,0A0h,0D7h,8Bh, 0E8h,0A8h,077h,8Dh
	db	0E8h,0A8h,06Eh,8Eh, 0FFh,0BFh,013h,95h, 0E9h,0A9h,023h,95h, 0E0h,0A0h,0D7h,9Bh
	db	0E8h,0A8h,077h,9Dh, 0E8h,0A8h,06Eh,9Eh
Nausicaa_P1:
	db	1,0,8
	db	0E1h,0A1h,071h,8Ah, 0E0h,0A0h,098h,8Ah, 0F8h,0B8h,0F8h,8Fh, 0E8h,0A8h,013h,91h
	db	0E8h,0A8h,033h,92h, 0E0h,0A0h,09Fh,94h, 03Eh,03Eh,0A0h,94h, 007h,007h,0A1h,94h
; --------

Robocop:
	db	0,14,4
	db	060h,070h,03Dh,80h, 032h,032h,040h,80h, 0AFh,0AFh,041h,80h, 0FCh,0FCh,042h,80h
Robocop_P1:	
	db	1,14,5
	db	080h,090h,070h,99h, 0A0h,0B0h,075h,99h, 080h,090h,084h,99h, 0A0h,0B0h,089h,99h
	db	080h,090h,098h,99h
; --------

SupLodeRunner:
	db	0,6,54
	db	004h,004h,002h,80h, 040h,040h,003h,80h, 000h,0F3h,080h,80h, 000h,0F5h,081h,80h
	db	000h,087h,082h,80h, 000h,032h,083h,80h, 000h,090h,085h,80h, 000h,03Ch,086h,80h
	db	000h,032h,087h,80h, 000h,0B0h,089h,80h, 000h,0F1h,08Ah,80h, 000h,0FBh,08Bh,80h
	db	000h,0C9h,08Ch,80h, 000h,0EDh,08Dh,80h, 000h,073h,08Eh,80h, 000h,0C0h,090h,80h
	db	000h,021h,091h,80h, 000h,00Ah,092h,80h, 000h,039h,094h,80h, 000h,0F9h,095h,80h
	db	000h,0E3h,096h,80h, 000h,07Ch,097h,80h, 000h,0FEh,098h,80h, 000h,0FCh,099h,80h
	db	000h,020h,09Ah,80h, 000h,015h,09Bh,80h, 000h,02Bh,09Ch,80h, 000h,02Bh,09Dh,80h
	db	000h,07Dh,09Eh,80h, 000h,023h,09Fh,80h, 000h,0E6h,0A0h,80h, 000h,003h,0A1h,80h
	db	000h,0FEh,0A2h,80h, 000h,001h,0A3h,80h, 000h,0CBh,0A4h,80h, 000h,07Eh,0A5h,80h
	db	000h,028h,0A6h,80h, 000h,002h,0A7h,80h, 000h,0CBh,0A8h,80h, 000h,0BEh,0A9h,80h
	db	000h,023h,0AAh,80h, 000h,0E3h,0ABh,80h, 000h,0EDh,0ACh,80h, 000h,07Bh,0ADh,80h
	db	000h,0C0h,0AFh,80h, 000h,0C9h,0B0h,80h, 000h,0CDh,0B1h,80h, 000h,0ABh,0B2h,80h
	db	000h,080h,0B3h,80h, 000h,0C3h,0B4h,80h, 000h,081h,0B6h,80h, 032h,0CDh,01Ch,81h
	db	000h,080h,01Dh,81h, 000h,080h,01Eh,81h
SupLodeRunner_P1:
	db	1,6,21
	db	032h,0CDh,09Ah,83h, 000h,080h,09Bh,83h, 000h,080h,09Ch,83h, 032h,0CDh,0A4h,83h
	db	000h,080h,0A5h,83h, 000h,080h,0A6h,83h, 032h,0CDh,0AFh,83h, 000h,080h,0B0h,83h
	db	000h,080h,0B1h,83h, 032h,0CDh,0B9h,83h, 000h,080h,0BAh,83h, 000h,080h,0BBh,83h
	db	032h,0CDh,0CCh,83h, 000h,080h,0CDh,83h, 000h,080h,0CEh,83h, 032h,0CDh,0D6h,83h
	db	000h,080h,0D7h,83h, 000h,080h,0D8h,83h, 032h,0CDh,0E2h,83h, 000h,080h,0E3h,83h
	db	000h,080h,0E4h,83h
SupLodeRunner_P2:
	db	2,6,54
	db	000h,08Dh,002h,80h, 000h,080h,003h,80h, 000h,0F3h,080h,80h, 000h,0F5h,081h,80h
	db	000h,087h,082h,80h, 000h,032h,083h,80h, 000h,090h,085h,80h, 000h,03Ch,086h,80h
	db	000h,032h,087h,80h, 000h,0B0h,089h,80h, 000h,0F1h,08Ah,80h, 000h,0FBh,08Bh,80h
	db	000h,0C9h,08Ch,80h, 000h,0EDh,08Dh,80h, 000h,073h,08Eh,80h, 000h,0C0h,090h,80h
	db	000h,021h,091h,80h, 000h,00Ah,092h,80h, 000h,039h,094h,80h, 000h,0F9h,095h,80h
	db	000h,0E3h,096h,80h, 000h,07Ch,097h,80h, 000h,0FEh,098h,80h, 000h,0FCh,099h,80h
	db	000h,020h,09Ah,80h, 000h,015h,09Bh,80h, 000h,02Bh,09Ch,80h, 000h,02Bh,09Dh,80h
	db	000h,07Dh,09Eh,80h, 000h,023h,09Fh,80h, 000h,0E6h,0A0h,80h, 000h,003h,0A1h,80h
	db	000h,0FEh,0A2h,80h, 000h,001h,0A3h,80h, 000h,0CBh,0A4h,80h, 000h,07Eh,0A5h,80h
	db	000h,028h,0A6h,80h, 000h,002h,0A7h,80h, 000h,0CBh,0A8h,80h, 000h,0BEh,0A9h,80h
	db	000h,023h,0AAh,80h, 000h,0E3h,0ABh,80h, 000h,0EDh,0ACh,80h, 000h,07Bh,0ADh,80h
	db	000h,0C0h,0AFh,80h, 000h,0C9h,0B0h,80h, 000h,0CDh,0B1h,80h, 000h,0ABh,0B2h,80h
	db	000h,080h,0B3h,80h, 000h,0C3h,0B4h,80h, 000h,081h,0B6h,80h, 032h,0CDh,02Eh,81h
	db	000h,080h,02Fh,81h, 000h,080h,030h,81h
SupLodeRunner_P3:
	db	3,6,3
	db	032h,0CDh,0E5h,96h, 000h,080h,0E6h,96h, 000h,080h,0E7h,96h
SupLodeRunner_P4:
	db	4,6,51
	db	000h,08Dh,002h,80h, 000h,080h,003h,80h, 000h,0F3h,080h,80h, 000h,0F5h,081h,80h
	db	000h,087h,082h,80h, 000h,032h,083h,80h, 000h,090h,085h,80h, 000h,03Ch,086h,80h
	db	000h,032h,087h,80h, 000h,0B0h,089h,80h, 000h,0F1h,08Ah,80h, 000h,0FBh,08Bh,80h
	db	000h,0C9h,08Ch,80h, 000h,0EDh,08Dh,80h, 000h,073h,08Eh,80h, 000h,0C0h,090h,80h
	db	000h,021h,091h,80h, 000h,00Ah,092h,80h, 000h,039h,094h,80h, 000h,0F9h,095h,80h
	db	000h,0E3h,096h,80h, 000h,07Ch,097h,80h, 000h,0FEh,098h,80h, 000h,0FCh,099h,80h
	db	000h,020h,09Ah,80h, 000h,015h,09Bh,80h, 000h,02Bh,09Ch,80h, 000h,02Bh,09Dh,80h
	db	000h,07Dh,09Eh,80h, 000h,023h,09Fh,80h, 000h,0E6h,0A0h,80h, 000h,003h,0A1h,80h
	db	000h,0FEh,0A2h,80h, 000h,001h,0A3h,80h, 000h,0CBh,0A4h,80h, 000h,07Eh,0A5h,80h
	db	000h,028h,0A6h,80h, 000h,002h,0A7h,80h, 000h,0CBh,0A8h,80h, 000h,0BEh,0A9h,80h
	db	000h,023h,0AAh,80h, 000h,0E3h,0ABh,80h, 000h,0EDh,0ACh,80h, 000h,07Bh,0ADh,80h
	db	000h,0C0h,0AFh,80h, 000h,0C9h,0B0h,80h, 000h,0CDh,0B1h,80h, 000h,0ABh,0B2h,80h
	db	000h,080h,0B3h,80h, 000h,0C3h,0B4h,80h, 000h,081h,0B6h,80h
SupLodeRunner_P5:
	db	5,6,21
	db	032h,0CDh,09Ah,83h, 000h,080h,09Bh,83h, 000h,080h,09Ch,83h, 032h,0CDh,0A4h,83h
	db	000h,080h,0A5h,83h, 000h,080h,0A6h,83h, 032h,0CDh,0AFh,83h, 000h,080h,0B0h,83h
	db	000h,080h,0B1h,83h, 032h,0CDh,0B9h,83h, 000h,080h,0BAh,83h, 000h,080h,0BBh,83h
	db	032h,0CDh,0CCh,83h, 000h,080h,0CDh,83h, 000h,080h,0CEh,83h, 032h,0CDh,0D6h,83h
	db	000h,080h,0D7h,83h, 000h,080h,0D8h,83h, 032h,0CDh,0E2h,83h, 000h,080h,0E3h,83h
	db	000h,080h,0E4h,83h
SupLodeRunner_P6:
	db	6,6,54
	db	000h,08Dh,002h,80h, 000h,080h,003h,80h, 000h,0F3h,080h,80h, 000h,0F5h,081h,80h
	db	000h,087h,082h,80h, 000h,032h,083h,80h, 000h,090h,085h,80h, 000h,03Ch,086h,80h
	db	000h,032h,087h,80h, 000h,0B0h,089h,80h, 000h,0F1h,08Ah,80h, 000h,0FBh,08Bh,80h
	db	000h,0C9h,08Ch,80h, 000h,0EDh,08Dh,80h, 000h,073h,08Eh,80h, 000h,0C0h,090h,80h
	db	000h,021h,091h,80h, 000h,00Ah,092h,80h, 000h,039h,094h,80h, 000h,0F9h,095h,80h
	db	000h,0E3h,096h,80h, 000h,07Ch,097h,80h, 000h,0FEh,098h,80h, 000h,0FCh,099h,80h
	db	000h,020h,09Ah,80h, 000h,015h,09Bh,80h, 000h,02Bh,09Ch,80h, 000h,02Bh,09Dh,80h
	db	000h,07Dh,09Eh,80h, 000h,023h,09Fh,80h, 000h,0E6h,0A0h,80h, 000h,003h,0A1h,80h
	db	000h,0FEh,0A2h,80h, 000h,001h,0A3h,80h, 000h,0CBh,0A4h,80h, 000h,07Eh,0A5h,80h
	db	000h,028h,0A6h,80h, 000h,002h,0A7h,80h, 000h,0CBh,0A8h,80h, 000h,0BEh,0A9h,80h
	db	000h,023h,0AAh,80h, 000h,0E3h,0ABh,80h, 000h,0EDh,0ACh,80h, 000h,07Bh,0ADh,80h
	db	000h,0C0h,0AFh,80h, 000h,0C9h,0B0h,80h, 000h,0CDh,0B1h,80h, 000h,0ABh,0B2h,80h
	db	000h,080h,0B3h,80h, 000h,0C3h,0B4h,80h, 000h,081h,0B6h,80h, 032h,0CDh,02Eh,81h
	db	000h,080h,02Fh,81h, 000h,080h,030h,81h
SupLodeRunner_P8:
	db	8,6,54
	db	000h,08Dh,002h,80h, 000h,080h,003h,80h, 000h,0F3h,080h,80h, 000h,0F5h,081h,80h
	db	000h,087h,082h,80h, 000h,032h,083h,80h, 000h,090h,085h,80h, 000h,03Ch,086h,80h
	db	000h,032h,087h,80h, 000h,0B0h,089h,80h, 000h,0F1h,08Ah,80h, 000h,0FBh,08Bh,80h
	db	000h,0C9h,08Ch,80h, 000h,0EDh,08Dh,80h, 000h,073h,08Eh,80h, 000h,0C0h,090h,80h
	db	000h,021h,091h,80h, 000h,00Ah,092h,80h, 000h,039h,094h,80h, 000h,0F9h,095h,80h
	db	000h,0E3h,096h,80h, 000h,07Ch,097h,80h, 000h,0FEh,098h,80h, 000h,0FCh,099h,80h
	db	000h,020h,09Ah,80h, 000h,015h,09Bh,80h, 000h,02Bh,09Ch,80h, 000h,02Bh,09Dh,80h
	db	000h,07Dh,09Eh,80h, 000h,023h,09Fh,80h, 000h,0E6h,0A0h,80h, 000h,003h,0A1h,80h
	db	000h,0FEh,0A2h,80h, 000h,001h,0A3h,80h, 000h,0CBh,0A4h,80h, 000h,07Eh,0A5h,80h
	db	000h,028h,0A6h,80h, 000h,002h,0A7h,80h, 000h,0CBh,0A8h,80h, 000h,0BEh,0A9h,80h
	db	000h,023h,0AAh,80h, 000h,0E3h,0ABh,80h, 000h,0EDh,0ACh,80h, 000h,07Bh,0ADh,80h
	db	000h,0C0h,0AFh,80h, 000h,0C9h,0B0h,80h, 000h,0CDh,0B1h,80h, 000h,0ABh,0B2h,80h
	db	000h,080h,0B3h,80h, 000h,0C3h,0B4h,80h, 000h,081h,0B6h,80h, 032h,0CDh,02Eh,81h
	db	000h,080h,02Fh,81h, 000h,080h,030h,81h
SupLodeRunner_PA:
	db	10,6,54
	db	000h,08Dh,002h,80h, 000h,080h,003h,80h, 000h,0F3h,080h,80h, 000h,0F5h,081h,80h
	db	000h,087h,082h,80h, 000h,032h,083h,80h, 000h,090h,085h,80h, 000h,03Ch,086h,80h
	db	000h,032h,087h,80h, 000h,0B0h,089h,80h, 000h,0F1h,08Ah,80h, 000h,0FBh,08Bh,80h
	db	000h,0C9h,08Ch,80h, 000h,0EDh,08Dh,80h, 000h,073h,08Eh,80h, 000h,0C0h,090h,80h
	db	000h,021h,091h,80h, 000h,00Ah,092h,80h, 000h,039h,094h,80h, 000h,0F9h,095h,80h
	db	000h,0E3h,096h,80h, 000h,07Ch,097h,80h, 000h,0FEh,098h,80h, 000h,0FCh,099h,80h
	db	000h,020h,09Ah,80h, 000h,015h,09Bh,80h, 000h,02Bh,09Ch,80h, 000h,02Bh,09Dh,80h
	db	000h,07Dh,09Eh,80h, 000h,023h,09Fh,80h, 000h,0E6h,0A0h,80h, 000h,003h,0A1h,80h
	db	000h,0FEh,0A2h,80h, 000h,001h,0A3h,80h, 000h,0CBh,0A4h,80h, 000h,07Eh,0A5h,80h
	db	000h,028h,0A6h,80h, 000h,002h,0A7h,80h, 000h,0CBh,0A8h,80h, 000h,0BEh,0A9h,80h
	db	000h,023h,0AAh,80h, 000h,0E3h,0ABh,80h, 000h,0EDh,0ACh,80h, 000h,07Bh,0ADh,80h
	db	000h,0C0h,0AFh,80h, 000h,0C9h,0B0h,80h, 000h,0CDh,0B1h,80h, 000h,0ABh,0B2h,80h
	db	000h,080h,0B3h,80h, 000h,0C3h,0B4h,80h, 000h,081h,0B6h,80h, 032h,0CDh,02Eh,81h
	db	000h,080h,02Fh,81h, 000h,080h,030h,81h
SupLodeRunner_PC:
	db	12,6,54
	db	000h,08Dh,002h,80h, 000h,080h,003h,80h, 000h,0F3h,080h,80h, 000h,0F5h,081h,80h
	db	000h,087h,082h,80h, 000h,032h,083h,80h, 000h,090h,085h,80h, 000h,03Ch,086h,80h
	db	000h,032h,087h,80h, 000h,0B0h,089h,80h, 000h,0F1h,08Ah,80h, 000h,0FBh,08Bh,80h
	db	000h,0C9h,08Ch,80h, 000h,0EDh,08Dh,80h, 000h,073h,08Eh,80h, 000h,0C0h,090h,80h
	db	000h,021h,091h,80h, 000h,00Ah,092h,80h, 000h,039h,094h,80h, 000h,0F9h,095h,80h
	db	000h,0E3h,096h,80h, 000h,07Ch,097h,80h, 000h,0FEh,098h,80h, 000h,0FCh,099h,80h
	db	000h,020h,09Ah,80h, 000h,015h,09Bh,80h, 000h,02Bh,09Ch,80h, 000h,02Bh,09Dh,80h
	db	000h,07Dh,09Eh,80h, 000h,023h,09Fh,80h, 000h,0E6h,0A0h,80h, 000h,003h,0A1h,80h
	db	000h,0FEh,0A2h,80h, 000h,001h,0A3h,80h, 000h,0CBh,0A4h,80h, 000h,07Eh,0A5h,80h
	db	000h,028h,0A6h,80h, 000h,002h,0A7h,80h, 000h,0CBh,0A8h,80h, 000h,0BEh,0A9h,80h
	db	000h,023h,0AAh,80h, 000h,0E3h,0ABh,80h, 000h,0EDh,0ACh,80h, 000h,07Bh,0ADh,80h
	db	000h,0C0h,0AFh,80h, 000h,0C9h,0B0h,80h, 000h,0CDh,0B1h,80h, 000h,0ABh,0B2h,80h
	db	000h,080h,0B3h,80h, 000h,0C3h,0B4h,80h, 000h,081h,0B6h,80h, 032h,0CDh,012h,81h
	db	000h,080h,013h,81h, 000h,080h,014h,81h
SupLodeRunner_PD:
	db	13,6,3
	db	032h,0CDh,0E5h,96h, 000h,080h,0E6h,96h, 000h,080h,0E7h,96h
SupLodeRunner_PE:
	db	14,6,51
	db	000h,08Dh,002h,80h, 000h,080h,003h,80h, 000h,0F3h,080h,80h, 000h,0F5h,081h,80h
	db	000h,087h,082h,80h, 000h,032h,083h,80h, 000h,090h,085h,80h, 000h,03Ch,086h,80h
	db	000h,032h,087h,80h, 000h,0B0h,089h,80h, 000h,0F1h,08Ah,80h, 000h,0FBh,08Bh,80h
	db	000h,0C9h,08Ch,80h, 000h,0EDh,08Dh,80h, 000h,073h,08Eh,80h, 000h,0C0h,090h,80h
	db	000h,021h,091h,80h, 000h,00Ah,092h,80h, 000h,039h,094h,80h, 000h,0F9h,095h,80h
	db	000h,0E3h,096h,80h, 000h,07Ch,097h,80h, 000h,0FEh,098h,80h, 000h,0FCh,099h,80h
	db	000h,020h,09Ah,80h, 000h,015h,09Bh,80h, 000h,02Bh,09Ch,80h, 000h,02Bh,09Dh,80h
	db	000h,07Dh,09Eh,80h, 000h,023h,09Fh,80h, 000h,0E6h,0A0h,80h, 000h,003h,0A1h,80h
	db	000h,0FEh,0A2h,80h, 000h,001h,0A3h,80h, 000h,0CBh,0A4h,80h, 000h,07Eh,0A5h,80h
	db	000h,028h,0A6h,80h, 000h,002h,0A7h,80h, 000h,0CBh,0A8h,80h, 000h,0BEh,0A9h,80h
	db	000h,023h,0AAh,80h, 000h,0E3h,0ABh,80h, 000h,0EDh,0ACh,80h, 000h,07Bh,0ADh,80h
	db	000h,0C0h,0AFh,80h, 000h,0C9h,0B0h,80h, 000h,0CDh,0B1h,80h, 000h,0ABh,0B2h,80h
	db	000h,080h,0B3h,80h, 000h,0C3h,0B4h,80h, 000h,081h,0B6h,80h
SupLodeRunner_PF:
	db	15,6,21
	db	032h,0CDh,078h,96h, 000h,080h,079h,96h, 000h,080h,07Ah,96h, 032h,0CDh,085h,96h
	db	000h,080h,086h,96h, 000h,080h,087h,96h, 032h,0CDh,098h,96h, 000h,080h,099h,96h
	db	000h,080h,09Ah,96h, 032h,0CDh,0A2h,96h, 000h,080h,0A3h,96h, 000h,080h,0A4h,96h
	db	032h,0CDh,0FFh,96h, 000h,080h,000h,97h, 000h,080h,001h,97h, 032h,0CDh,09Eh,97h
	db	000h,080h,09Fh,97h, 000h,080h,0A0h,97h, 032h,0CDh,0A7h,97h, 000h,080h,0A8h,97h
	db	000h,080h,0A9h,97h
; --------


; --------



rtpatch: db	008h,080h,069h,08Dh,083h,0ABh,082h,0B3h,0ACh,026h,002h,002h,000h,091h,0c3h,002h
; --------


; --------

; --------
ZombHunt:
	db	0,0,18
	db	0AFh,0CDh,010h,80h, 032h,000h,011h,80h, 000h,060h,012h,80h, 064h,0AFh,013h,80h
	db	03Eh,032h,014h,80h, 001h,000h,015h,80h, 032h,050h,016h,80h, 000h,03Ch,017h,80h
	db	06Ah,032h,018h,80h, 03Eh,000h,019h,80h, 002h,070h,01Ah,80h, 032h,03Ch,01Bh,80h
	db	000h,032h,01Ch,80h, 074h,000h,01Dh,80h, 03EH,090h,01Eh,80h, 003h,03Ch,01Fh,80h
	db	07Ah,0B0h,022h,80h, 000h,021h,027h,80h
ZombHunt_P1:
	db	1,0,26
	db	0CDh,0C3h,01Eh,80h, 07Ah,0B0h,040h,80h, 07Ah,0B0h,050h,80h, 07Ah,0B0h,008h,82h
	db	07Ah,0B0h,019h,82h, 07Ah,0B0h,03Ah,82h, 07Ah,0B0h,072h,82h, 07Ah,0B0h,079h,82h
	db	07Ah,0B0h,0B1h,82h, 07Ah,0B0h,0B7h,82h, 07Ah,0B0h,010h,83h, 07Ah,0B0h,017h,83h
	db	07Ah,0B0h,045h,83h, 07Ah,0B0h,067h,83h, 07Ah,0B0h,0CBh,83h, 07Ah,0B0h,0D1h,83h
	db	07Ah,0B0h,0F4h,83h, 07Ah,0B0h,03Ch,84h, 07Ah,0B0h,0AEh,84h, 07Ah,0B0h,0BBh,84h
	db	07Ah,0B0h,0EFh,84h, 07Ah,0B0h,011h,85h, 07Ah,0B0h,047h,85h, 07Ah,0B0h,06Dh,85h
	db	07Ah,0B0h,074h,85h, 07Ah,0B0h,0E4h,85h




; --------
;, 060h,070h,0h,h
;, 080h,090h,0h,h
;, 0A0h,0B0h,0h,h
; Patch data

; db page number,patch ID,number of patch
; db original value, new value,address FSB,address MSB, etc...
; (address of data = 8000h ~ 9FFFh)