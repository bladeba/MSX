
;*** FLP.COM v1.65 for MSX

;*** ROM Loader for MegaflashROM mapped Konami SCC

; Assembled with zasm cross assembler
; http://sourceforge.net/projects/zasm/


RUTrutin equ	07B00h

iniline	equ	0FB00h

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
	db	"KONAMI RC number error!  Example: FLP GRADIUS2.ROM /K746",CR,LF,"$"
DonMes:
	db	CR,LF,CR,LF,"Load complete. Thank you.",CR,LF,"$"
AM29F0xx:
	db	"29F040 FlashROM found in Slot $"
NO_FLSH:
	db	"FlashRom with SCC Mapper not found!",CR,LF,"$"
WarnMess:
	db	"You have selected a slot that",CR,LF
	db	"contains a DISK-ROM!",CR,LF,"$"
ConfirmMess:
	db	"Do you want to erase it? (Y/N)",CR,LF,"$"
CancelMess:
	db	"Canceled.",CR,LF,"$"

Main:
	ld	de,MESVER
	ld	c,9
	call	BDOS		; Print MESVER message (FL info)

; *** Auto-detection routine

	ld	b,3		; B=Primary Slot
BCLM:
	ld	c,0		; C=Secondary Slot
BCLMI:
	push	bc
	call	AutoSeek
	pop	bc
	inc	c
	ld	a,c
	cp	4
	jr	nz,BCLMI	; Jump if Secondary Slot < 4
	dec	b
	jp	p,BCLM		; Jump if Primary Slot < 0
	
NO_FND:
	ld	de,NO_FLSH	; Pointer to NO_FLSH message
	jp	Done

AutoSeek:
	ld	a,b
	xor	3		; Reverse the bits to reverse the search order (0 to 3)
	ld	hl,MNROM
	ld	d,0
	ld	e,a
	add	hl,de
	bit	7,(hl)
	jr	z,primSlt	; Jump if slot is not expanded
	or	(hl)		; Set flag for secondary slot
	sla	c
	sla	c
	or	c		; Add secondary slot value to format FxxxSSPP
primSlt:
	ld	(ERMSlt),a
; ---
	ld	b,a		; Keep actual slot value

	bit	7,a
	jr	nz,SecSlt	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt:
	ld	c,a
	ld	a,(DRVINV)	; A = slot value of main Rom-disk
	bit	7,a
	jr	nz,SecSlt1	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt1:
	cp	c
	ret	z		; Return if Disk-Rom Slot
	ld	a,(DRVINV+2)	; A = slot value of second Rom-disk
	bit	7,a
	jr	nz,SecSlt2	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt2:
	cp	c
	ret	z		; Return if Disk-Rom Slot
	ld	a,(DRVINV+4)	; A = slot value of third Rom-disk
	bit	7,a
	jr	nz,SecSlt3	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt3:
	cp	c
	ret	z		; Return if Disk-Rom Slot
	ld	a,(DRVINV+6)	; A = slot value of fourth Rom-disk
	bit	7,a
	jr	nz,SecSlt4	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt4:
	cp	c
	ret	z		; Return if Disk-Rom Slot

	ld	a,b		; Restore actual slot value
; ---
	ld	h,40h
	call	ENASLT		; Select a Slot in Bank 1 (4000h ~ 7FFFh)

	di
	ld	a,0aah
	ld	(4555h),a	; Autoselect
	ld	a,055h
	ld	(42aah),a	; Mode
	ld	a,090h
	ld	(4555h),a	; ON
	
	ld	b,16
	ld	hl,4000h
RDID_BCL:
	ld	a,(hl)		; (HL) = Manufacturer ID
;	ld	(MAN_ID),a
;	cp	01h		; Manufacturer ID (01h=AMD)
;	jr	z,SKIPmxicID
;	cp	0C2h		; Manufacturer ID (0C2h=MXIC)
;	ret	nz

;	ld	a,04Dh
;	ld	(AM29F0xx),a	; 'M'
;	ld	a,058h
;	ld	(AM29F0xx+1),a	; 'X'
;SKIPmxicID:

	inc	hl
	ld	a,(hl)

	cp	0D5h		; Device ID for AM29F080B
	ex	AF,AF'
	ld	a,038h
	ld	(AM29F0xx+4),a
	ld	a,030h
	ld	(AM29F0xx+5),a
	ex	AF,AF'
	jr	z,ID_OK

	cp	0A4h		; Device ID for AM29F040B
	ex	AF,AF'
	ld	a,034h
	ld	(AM29F0xx+4),a
	ld	a,030h
	ld	(AM29F0xx+5),a
	ex	AF,AF'
	jr	z,ID_OK

	cp	077h		; Device for AM29F004B (Top Boot Block)
	ex	AF,AF'
	ld	a,030h
	ld	(AM29F0xx+4),a
	ld	a,034h
	ld	(AM29F0xx+5),a
	ex	AF,AF'
	jr	z,ID_OK
	cp	07Bh		; Device for AM29F004B (Bottom Boot Block)
	jr	z,ID_OK

	cp	0B0h		; Device for AM29F002 (Top Boot Block)
	ex	AF,AF'
	ld	a,030h
	ld	(AM29F0xx+4),a
	ld	a,032h
	ld	(AM29F0xx+5),a
	ex	AF,AF'
	jr	z,ID_OK
	cp	034h		; Device for AM29F002 (Bottom Boot Block)
	jr	z,ID_OK

	cp	020h		; Device ID for AM29F010
	ex	AF,AF'
	ld	a,031h
	ld	(AM29F0xx+4),a
	ld	a,030h
	ld	(AM29F0xx+5),a
	ex	AF,AF'
	jr	z,ID_OK
	ret
ID_OK:
;	ld	(DEV_ID),a

	ld	a,(hl)
	inc	hl
;	ld	(SEC_PROT),a
;	cp	01h		; Sector Protection. (01h=protected, 00h=unprotected)
;	ret	nz

	inc	hl
	inc	hl
	djnz	RDID_BCL
	
	ld	(hl),0f0h	; AM29F0xx ID reading mode OFF

	ei
	pop	hl		; Remove RET address in stack
	pop	hl		; Remove BC value in stack
	
FLH_FND:
	ld	a,(RAMAD1)
	ld	h,40h
	call	ENASLT		; Select Main-RAM in MSX"s Bank 1

	ld	de,AM29F0xx	; Pointer to AM29F0xx message
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

Parameters:
	ld	hl,DMA
	ld	b,(HL)
	inc	b
	dec	b
	jp	z,Done		; Jump if no parameter

; Check parameter /S

	ld	c,053h		; 'S' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	jr	z,No_S		; Jump if S not found
	call	GetNum		; Get the slot number from parameter
	ld	a,e
	ld	(ERMSlt),a	; ERMSlt = Slot number from option S
	
	ld	a,(ERMSlt)	; A = Slot number from option S
	call	CheckSLT	; check if Megaflash is insered in /Sxx Slot
No_S:
	ld	a,(ERMSlt)
	or	a
	ld	de,NO_FLSH	; Pointer to NO_FLSH message
	jp	z,Done		; Jump if Flash Rom not found


; Check parameter /R
	
	ld	hl,DMA
	ld	b,(HL)
	ld	c,052h		; 'R' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if Megaflashrom not detected
	ld	(ParameterR),a


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
	

; Check parameter /X

	ld	hl,DMA
	ld	b,(HL)
	ld	c,058h		; 'X' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(EXEC),a
	

; Check parameter /T

	ld	hl,DMA
	ld	b,(HL)
	ld	c,054h		; 'T' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(TURBO),a

; Check parameter /F

	ld	hl,DMA
	ld	b,(HL)
	ld	c,046h		; 'F' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(FSCC),a

; Check parameter /K7xx
	
	ld	hl,DMA
	ld	b,(HL)
	ld	c,04Bh		; 'K' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	
	or	a
	jr	z,nok7

	call	GetRC		; Get the slot number from parameter
	or	a
	ld	de,RCnumErr
	jp	z,Done		;Jump if RC number error

	ld	(RC),a	; ERMSlt = Slot number from option S	
	cp	040h
	jr	z,RCTWINBEE
	cp	035h
	jr	z,RCGAME
	cp	046h
	jr	z,RCQBERT
	cp	039h
	jr	z,RCKNIGH
	jr	nz,nok7

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
	jr	nok7

; Check parameter /D
nok7:
	ld	hl,DMA
	ld	b,(HL)
	ld	c,044h		; 'D' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(DISK),a
	




; Check parameter /E

	ld	hl,DMA
	ld	b,(HL)
	ld	c,045h		; 'E' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	or	a
	ld	(FLerase),a
	jp	nz,SKIP		; Jump if /E found




	
	


	
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
	
	cp	40h
	jr	nz,putjump
	dec	a
putjump:
	
	cp	30h
	jr	nz,putjump2
	
	inc	a
	inc	a
	
	
	
putjump2:
	
	
	ld	(jump+1),a
	ld	(jumpG+1),a
		;-







	ld	c,1ah
	ld	de,BUFTOP
	call	BDOS		; Set disk transfer address (buffer start at 8000H)
	
	ld	c,27h
	ld	de,FCB
	ld	hl,4000h	; Number of records to read
	call	BDOS		; Read a block from file
	
	;--------------------------------- Save execute adress

	push	af
	push	hl
	
	push	bc
	ld	hl,BUFTOP		;save in memory the first 16 bytes
	ld	de,iniline
	ld	bc,0010h
	ldir
		
	pop	bc
	
	
	ld	a,(BUFTOP+9)	;BASIC ROM????
	cp	80h		;exe ROM adress
	
	ld	hl,BUFTOP+2
	jr	nz,nobasic
	inc	l
	inc	l
	inc	l
	inc	l
	inc	l
	inc	l
	
	xor	a

	ld	(noDSK),a

nobasic:				
	ld	de,saveexe+1
	ld	a,(hl)
	ld	(de),a
	inc	hl
	inc	de
	ld	a,(hl)
	ld	(de),a

	ld	a,(08000h)		;R-Type exe point
	cp	08h
	jr	nz,nortexe
	ld	a,010h
	ld	(saveexe+1),a
	ld	a,040h
	ld	(saveexe+2),a

nortexe:
	push	af
	push	hl
	push	de
	push	bc
	
	call	bus_tipo
	

	cp	01
	jr nz,noNOMA
	ld	a,(jump+1)		;increase jump
	inc	a
	ld	(jump+1),a
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
	cp	06
	jr nz,noNOLODE
	ld	de,SLRUN
	jp	printtype

noNOLODE:
	
	cp	07
	jr nz,noRTYPE
	ld	de,RTYPE
	jp	printtype
	
noRTYPE:	
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
	cp	058h		; 'X' character
	jr	z,SyntaxOK
	cp	043h		; 'C' character
	jr	z,SyntaxOK
	cp	050h		; 'P' character
	jr	z,SyntaxOK
	cp	04Eh		; 'N' character
	jr	z,SyntaxOK
	cp	044h		; 'D' character
	jr	z,SyntaxOK
	cp	04Bh		; 'K' character
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
	ld	a,(ERMSlt)	; A = Slot number from option S
	bit	7,a
	jr	nz,SecSltP	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltP:
	ld	e,a
	ld	a,(DRVINV)
	bit	7,a
	jr	nz,SecSltP1	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltP1:
	cp	e
	call	z,Warning	; Return if actual slot is same as Disk-Rom 1 Slot

	ld	a,(DRVINV+2)
	bit	7,a
	jr	nz,SecSltP2	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltP2:
	cp	e
	call	z,Warning	; Return if actual slot is same as Disk-Rom 2 Slot

	ld	a,(DRVINV+4)
	bit	7,a
	jr	nz,SecSltP3	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltP3:
	cp	e
	call	z,Warning	; Return if actual slot is same as Disk-Rom 3 Slot

	ld	a,(DRVINV+6)
	bit	7,a
	jr	nz,SecSltP4	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltP4:
	cp	e
	call	z,Warning	; Return if actual slot is same as Disk-Rom 4 Slot
	ld	a,(OverWR)
	cp	'Y'
	jr	z,NoCancel
	ld	de,CancelMess
	jp	Done
	
Warning:
	push	de
	ld	de,WarnMess
	ld	c,9
	call	BDOS		; Print WarnMess message
	pop	de
	ld	a,'N'
	ld	(OverWR),a
	ret
	
NoCancel:
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

; Flash Erase
 
SKIP:
; ----
	ld	a,(ERMSlt)	; A = Slot number from option S
	bit	7,a
	jr	nz,SecSltPa	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltPa:
	ld	e,a
	ld	a,(DRVINV)
	bit	7,a
	jr	nz,SecSltP1a	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltP1a:
	cp	e
	call	z,Confirm	; Return if actual slot is same as Disk-Rom 1 Slot

	ld	a,(DRVINV+2)
	bit	7,a
	jr	nz,SecSltP2a	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltP2a:
	cp	e
	call	z,Confirm	; Return if actual slot is same as Disk-Rom 2 Slot

	ld	a,(DRVINV+4)
	bit	7,a
	jr	nz,SecSltP3a	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltP3a:
	cp	e
	call	z,Confirm	; Return if actual slot is same as Disk-Rom 3 Slot

	ld	a,(DRVINV+6)
	bit	7,a
	jr	nz,SecSltP4a	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSltP4a:
	cp	e
	call	z,Confirm	; Return if actual slot is same as Disk-Rom 4 Slot
	ld	a,(OverWR)
	cp	'Y'
	jr	z,OverWrite
	ld	de,CancelMess
	jp	Done

Confirm:
	push	de
	ld	de,WarnMess
	ld	c,9
	call	BDOS		; Print WarnMess message

	ld	de,ConfirmMess
	ld	c,9
	call	BDOS		; Print WarnMess message
	pop	de
WaitKey:
	ld	ix,CHGET
	ld	iy,(MNROM)
	call	CALSLT		; Execute the ROM
	and	0dfh
	cp	'Y'
	ld	(OverWR),a
	ret	z
	cp	'N'
	ld	(OverWR),a
	ret	z
	jr	WaitKey

OverWrite:
; ----	
	ld	de,FlsEra	; Pointer to message FLASH-ROM erase start
	ld	c,9
	call	BDOS		; Print FlsEra message

	ld	a,(ERMSlt)
	ld	h,40h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh

	di
	ld	a,0aah
	ld	(4555h),a	; Flashrom...
	ld	a,055h
	ld	(42aah),a	;
	ld	a,080h
	ld	(4555h),a	; ... erase ...
	ld	a,0aah
	ld	(4555h),a	;
	ld	a,055h
	ld	(42aah),a	;
	ld	a,010h
	ld	(4555h),a	; ... command

	ld	a,0ffh
	ld	de,4000h
	call	CHECK
	jp	c,Done		; Jump if Erase fail

	ei
	ld	de,FlsEok	; Pointer to Erase OK message
	ld	a,(FLerase)
	cp	045h
	jp	z,Done		; Jump if Erase option used

	ld	c,9
	call	BDOS		; Print FlsEok message

	ld	a,(RAMAD1)
	ld	h,40h
	call	ENASLT		; Select Main-RAM at bank 4000h~7FFFh

_8kL01:
	ld	c,27h
	ld	de,FCB
	ld	hl,2000h	; Number of records to read
	call	BDOS		; Read a block from file

	push	hl
	

	ld	a,(PreBnk)
	or	a
	call	z,changeini
	
	
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


	ld	a,(PreBnk)		;512 Kbytes!!!
	cp	40h
	ld	de,DonMes
	jp	z,Done
	
	
	

	ld	a,h
	or	l
	ld	de,DonMes
	jp	nz,CONTloading	; Jump if record is readed

	

	push	de

	call	Donepag

	pop	de


	ld	a,(PreBnk)
	cp	2
	jr	z,MakeMirror
	cp	3
	jr	z,MakeMirror
	cp	4
	jp	z,FLashPage	; FLash Page 1 again to page 3
	jp	Done		; Jump if any record is readed

MakeMirror:
	ld	a,(FileSize)
	cp	20h
	jp	z,FLashPage	; Jump if 8KB rom

Make16KMirror:
	ld	a,(ERMSlt)
	ld	h,40h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh

	ld	a,(PreBnk)
	ld	(5000h),a	; Select Flashrom page at Bank 4000h~7FFFh for SCC mapper

	ld	hl,4555h
	ld	de,42aah

	exx
	ld	bc,2000h	; Length
	ld	de,4000h	; Destination
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
	call	patchLNG


	ld	a,(tipo_detec)
	cp	1
	jr	nz,noMIRROR
	
	
	jr	noFSCC
	
noMIRROR:	
	cp	2
	jp	z,patchk4


	cp	3
	jp	z,patchk8

	cp	4
	jp	z,patchas8

	cp	5
	jp	z,patchas16

	cp	7
	jp	z,patchrtype

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

	ld	hl,AthleticBall
	call	MEGpatch	; Apply patch for page 0 of 16KB Rom

	ld	hl,CrazyBuggy
	call	MEGpatch	; Apply patch for page 0 of 16KB Rom

	ld	hl,Nausicaa
	call	MEGpatch	; Apply patch for page 0 of 16KB Rom

	ld	hl,Tatica
	call	MEGpatch	; Apply patch for page 0 of 16KB Rom

	ld	hl,BUFTOP
	ld	de,0A000h
	ld	bc,2000h
	ldir			; backup of page 0 for 16KB Rom

PatchHead:
	ld	hl,(BUFTOP+2)
	ld	a,h
	cp	80h
	jr	c,SKIP_PatchRomHeader	; Jump Start address is > 7FFFh

	ld	hl,BUFTOP+8h
	ld	(hl),0			; Remove pointer for Basic
	inc	hl
	ld	(hl),0			; Remove pointer for Basic
SKIP_PatchRomHeader:

	
	
	

	ld	hl,Anty_P1
	call	MEGpatch		; Apply patch 

	

	ld	hl,CarRace
	call	MEGpatch		; Apply patch 

	ld	hl,CrazyBuggy_P1
	call	MEGpatch		; Apply patch 

	

	

	ld	hl,Galaxian
	call	MEGpatch		; Apply patch

	ld	hl,Game80zemina
	call	MEGpatch		; Apply patch 

	ld	hl,Garakuta
	call	MEGpatch		; Apply patch 
	ld	a,(CURRpatchID)
	cp	8			; condition used when a page patch is small
	jr	nz,SKIPgarakuta		; jump game if Graduis page 0 is not patched
	ld	hl,Garakuta_P1
	call	MEGpatch		; Apply patch 
SKIPgarakuta:


	ld	hl,GoonR
	call	MEGpatch		; Apply patch 
	ld	a,(CURRpatchID)
	cp	7			; condition used when a page patch is small
	jr	nz,SKIPGoonR		; jump game if Graduis page 0 is not patched
	ld	hl,GoonR_P3
	call	MEGpatch		; Apply patch 
	ld	hl,GoonR_P4
	call	MEGpatch		; Apply patch 
SKIPGoonR:

	

	

	ld	hl,Labyrinth
	call	MEGpatch		; Apply patch 

	ld	hl,Manb2
	call	MEGpatch		; Apply patch 

	ld	hl,Manb2v2
	call	MEGpatch		; Apply patch 
	
SKIPmonmon_D:

	ld	hl,MSXDOS22
	call	MEGpatch		; Apply patch 
	ld	a,(CURRpatchID)
	cp	9			; condition used when a page patch is small
	jr	nz,SKIPmsxdos22		; jump if Monmon Kaibutsu published by Daewoo page 0 is not patched
	ld	hl,MSXDOS22_P1
	call	MEGpatch		; Apply patch 
	ld	hl,MSXDOS22_P2
	call	MEGpatch		; Apply patch 
	ld	hl,MSXDOS22_P3
	call	MEGpatch		; Apply patch 
SKIPmsxdos22:

	ld	hl,MSXDOS22NL
	call	MEGpatch		; Apply patch 
	ld	a,(CURRpatchID)
	cp	10			; condition used when a page patch is small
	jr	nz,SKIPmsxdos22NL	; jump if Monmon Kaibutsu published by Daewoo page 0 is not patched
	ld	hl,MSXDOS22NL_P1
	call	MEGpatch		; Apply patch 
	ld	hl,MSXDOS22NL_P2
	call	MEGpatch		; Apply patch 
SKIPmsxdos22NL:

	ld	hl,Nausicaa_P1
	call	MEGpatch		; Apply patch 

	ld	hl,Robocop
	call	MEGpatch			; Apply patch 
	ld	a,(CURRpatchID)
	cp	14			; condition used when a page patch is small
	jr	nz,SKIPRobocop		; jump if Robocop page 0 is not patched
	ld	hl,Robocop_P1
	call	MEGpatch		; Apply patch 
SKIPRobocop:

	ld	hl,SupLodeRunner
	call	MEGpatch		; Apply patch 
	ld	a,(CURRpatchID)
	cp	6			; condition used when a page patch is small
	jr	nz,SkipSupLodeR		; jump if Super Lode Runner page 0 is not patched
	ld	hl,SupLodeRunner_P1
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_P2
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_P3
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_P4
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_P5
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_P6
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_P8
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_PA
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_PC
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_PD
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_PE
	call	MEGpatch		; Apply patch 
	ld	hl,SupLodeRunner_PF
	call	MEGpatch		; Apply patch 
SkipSupLodeR:

	
;

	ld	hl,Tatica_P1
	call	MEGpatch		; Apply patch

	
	

	ld	hl,ZombHunt
	call	MEGpatch		; Apply patch 
	ld	hl,ZombHunt_P1
	call	MEGpatch		; Apply patch 

FLashPage:	
	ld	a,(ERMSlt)
	ld	h,40h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh

	ld	a,(PreBnk)
	ld	(5000h),a	; Select Flashrom page at Bank 4000h~7FFFh for SCC mapper

	
	cp	04h
	call	z,rc725
	
	
	cp	3fh
	jr	nz,no512k
	
	
	ld	hl,rutE			;If filesize is 512Kbytes, put
	ld	de,02000h+RUTrutin	;rutine in last page (03Fh)
	ld	bc,rutEend-rutE
	ldir




no512k:
	ld	hl,4555h
	ld	de,42aah

	exx
	ld	bc,2000h	; Length
	ld	de,4000h	; Destination
	ld	hl,BUFTOP	; Source
Loop:
 	di
	exx
	ld	(hl),0aah
	ld	a,055h
	ld	(de),a
	ld	(hl),0a0h
 	exx
	ld	a,(hl)
	ld	(de),a		; Write a byte to flashrom

	ex	AF,AF'
	ld	a,(PreBnk)
	ld	(5000h),a	; Select flashrom page 4000h~7FFFh for SCC mapper 
	ex	AF,AF'

	call	CHECK		; Check this byte
	jp	c,Done

	inc	hl
	inc	de
	dec	bc
	ld	a,b
	or	c
	jr	nz,Loop

	ei
	ld	a,(RAMAD1)
	ld	h,40h
	call	ENASLT		; Select Main-RAM at bank 4000h~7FFFh

	ld	a,(PreBnk)
	inc	a
	ld	(PreBnk),a	; Increments Rom mapper page

	
	;------------------------------------  RType??????
	ld	a,(tipo_detec)
	cp	07h
	jr	nz,nort
	ld	a,(PreBnk)
	
	cp	01h
	jr	z,FLashPage
	
	cp	02h
	jr	z,FLashRtype
	jr	nz,nort
FLashRtype:
	push	hl
	ld	hl,rtpatch
	ld	de,08000h
	ld	bc,0010h
	ldir
	pop	hl
	jp	FLashPage
	
nort:	
	cp	1
	jr	nz,noMIRR
	
	

	ld	a,(PreBnk)
	
	cp	01h		;restore ini line
	jr	nz,noMIRR
	ld	hl,iniline
	ld	de,08000h
	ld	bc,0010h
	ldir
	jp	FLashPage
	
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

CHECK:
	push	bc
	ld	c,a
CHK_L1:
	ld	a,(de)
	xor	c
	jp	p,CHK_R1	; Jump if readed bit 7 = written bit 7
	xor	c
	and	020h
	jr	z,CHK_L1	; Jump if readed bit 5 = 1
	ld	a,(de)
	xor	c
	jp	p,CHK_R1	; Jump if readed bit 7 = written bit 7
	ld	de,FlsErr
	scf
CHK_R1:
	pop	bc
	ret

; ~~~ Routine that check if Megaflash is insered in /Sxx Slot

CheckSLT:
	ld	(ERMSlt),a
	ld	h,40h
	call	ENASLT			; Select a Slot in Bank 1 (4000h ~ 7FFFh)

	di
	ld	a,0aah
	ld	(4555h),a	; Autoselect
	ld	a,055h
	ld	(42aah),a	; Mode
	ld	a,090h
	ld	(4555h),a	; ON
	
	ld	b,16
	ld	hl,4001h
	ld	a,(hl)
	inc	hl		; (HL) = Sector Protection
	inc	hl
	inc	hl		; (HL) = manufacturer ID
	inc	hl		; (HL) = Device ID
	ld	(DEV_ID),a
	cp	0D5h		; Device ID for AM29F080B
	jr	z,RDID_BCL2
	cp	0A4h		; Device ID for AM29F040B
	jr	z,RDID_BCL2
	cp	077h		; Device for AM29F004B (Top Boot Block)
	jr	z,RDID_BCL2
	cp	07Bh		; Device for AM29F004B (Bottom Boot Block)
	jr	z,RDID_BCL2
	cp	0B0h		; Device for AM29F002 (Top Boot Block)
	jr	z,RDID_BCL2
	cp	034h		; Device for AM29F002 (Bottom Boot Block)
	jr	z,RDID_BCL2
	cp	020h		; Device ID for AM29F010
	jr	z,RDID_BCL2
	jr	NO_FLH2

RDID_BCL2:
	ld	a,(DEV_ID)
	cp	(hl)		; Device ID for AM29F080B
	jr	z,ID_OK2
NO_FLH2:
	pop	hl		; Remove RET address in stack
	pop	hl		; Remove BC value in stack

	ld	de,NO_FLSH	; Pointer to NO_FLSH message
	jp	Done

ID_OK2:
	inc	hl		; (HL) = Sector Protection
	inc	hl
	inc	hl		; (HL) = manufacturer ID
	inc	hl		; (HL) = Device ID
	djnz	RDID_BCL2
	
	ld	(hl),0f0h		; AM29F0xx ID reading mode OFF
	ei
	
FLH_FND2:
	ld	a,(RAMAD1)
	ld	h,40h
	call	ENASLT			; Select Main-RAM in MSX"s Bank 1
	ret

; ~~~ End of routine that check if Megaflash is insered in /Sxx Slot


Done:
	ld	a,(ParameterR)
	cp	052h		; Seek 'R' character
	jr	z,ResetRoutine
	jp	NoReset

ResetRoutine:
	ld	a,(ERMSlt)	; Megaflashrom slot
	ld	hl,5000h	; Page selection address for scc mapper
	ld	e,0		; Page number
	call	0014h		; Select page 0 of Megaflashrom

	ld	a,(ERMSlt)	; Megaflashrom slot
	ld	hl,7000h	; Page selection address for scc mapper
	ld	e,1		; Page number
	call	0014h		; Select page 1 of Megaflashrom

	ld	a,(ERMSlt)	; Megaflashrom slot
	ld	hl,9000h	; Page selection address for scc mapper
	ld	e,2		; Page number
	call	0014h		; Select page 2 of Megaflashrom

	ld	a,(ERMSlt)	; Megaflashrom slot
	ld	hl,0B000h	; Page selection address for scc mapper
	ld	e,3		; Page number
	call	0014h		; Select page 3 of Megaflashrom

	ld	hl,ResetMSX
	ld	de,0C000h
	ld	bc,0020h
	ldir 			; Copy ResetMSX Routine to 0C000h
	jp	0C000h		; jump to ResetMSX routine
ResetMSX:
	ld	a,(0FCC1h)	; A = Main-rom slot
	ld	h,00h		; HL = address start of slot bank
	call	0024h		; Select Main-rom
	ld	a,(0FCC1h)	; Main-rom slot
	ld	h,40h		; HL = address start of slot bank
	call	0024h		; Select Main-rom
	call	006fh		; Screen 1
	rst	0		; msx reset
NoReset:
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
	
Donepag:
	
	
	
	
	
		
Flashend:

	ld	a,(ERMSlt)
	ld	h,40h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh

	ld	a,(PreBnk)
	ld	(5000h),a	; Select Flashrom page at Bank 4000h~7FFFh for SCC mapper

	ld	hl,4555h
	ld	de,42aah

	exx
	ld	hl,rutE
	ld	de,RUTrutin-02000h
	ld	bc,rutEend-rutE	; Source
Loop2:
 	di
	exx
	ld	(hl),0aah
	ld	a,055h
	ld	(de),a
	ld	(hl),0a0h
 	exx
	ld	a,(hl)
	ld	(de),a		; Write a byte to flashrom

	ex	AF,AF'
	ld	a,(PreBnk)
	ld	(5000h),a	; Select flashrom page 4000h~7FFFh for SCC mapper 
	ex	AF,AF'

	call	CHECK		; Check this byte
	jp	c,Done

	inc	hl
	inc	de
	dec	bc
	ld	a,b
	or	c
	jr	nz,Loop2

	ei
	ld	a,(RAMAD1)
	ld	h,40h
	call	ENASLT				
	


	ld	a,010h		;------------------------------
	ld	(PreBnk),a


	ret
	
	

;-----------------------------------
rutin:
	dw	4241h
	dw	4004h
	push	af

jump:	ld	a,00h   ;self!!
	nop	
	nop
	nop
	ld	(07000h),a
	jp	RUTrutin
rutinEND:


rutinG:
	dw	4006h
	dw	8033h
	push	af
	
	
jumpG:	ld	a,00h   ;self!!
	nop
	ld	(07000h),a
	jp	RUTrutin
	nop
	nop
rutinENDG:

	

;---------------------------------

RUT_MROM	equ RUTrutin-rutE
dR_MROM	equ	R_MROM-RUT_MROM

rutE:	
	
	
	ld	a,(0FEDCh)
	cp	04h
	jr	z,DDSKok
	
	
	ld	a,(DISK+RUT_MROM)
	or	a
	jr	nz,putDSK
	
	
	
	
	ld	a,03h
	call	SNSMAT
	bit 1,a	;"D" key	
	jr	nz,DDSKok
	
putDSK:	call	checkslotrom+RUT_MROM

	
	pop	af
	pop	de
	pop	bc
	pop	hl
	ld	hl,0CDA3h	;change jump!! for no ini second slot!!
	push	hl
	push	bc
	push	de
	
	ret
	
DDSKok:	
	push hl
	push de
	push bc
	
	exx
	
	push af
	push hl
	push de
	push bc
	
	exx
	
	


	ld	hl,RUTrutin+exeRAM-rutE	;copy rutine  to memory page 
	ld	de,R_MROM
	ld	bc,rutEend-exeRAM
	ldir
	ld	a,(002Bh)
	ld	(LENGcopy+R_MROM-exeRAM),a
	



	
	ld	a,(002Dh)
	or	a
	jr	z,MSX1
;------------------------------------------------------;PAL o NTSC
	
	ld	a,(PAL+RUT_MROM)
	or	a
	call	nz,putPAL+RUT_MROM

	ld	a,(NTSC+RUT_MROM)
	or	a
	call	nz,putNTSC+RUT_MROM
	
	
	;-------------PAL & NTSC
	
	
	ld	a,04h
	call	SNSMAT
	bit	5,a	;"P" key	
	call	z,putPAL+RUT_MROM

	ld	a,04h
	call	SNSMAT
	bit	3,a	;"N" key	
	call	z,putNTSC+RUT_MROM

;------------------------------------------------------;Cool Colors

	ld	a,03h
	call	SNSMAT
	bit	0,a	;"C" key	
	jr	z,noCCOL		;pressed ?? no put cool colors 
	
	ld	a,(CCOL+RUT_MROM)
	or	a
	jr	nz,noCCOL

	xor	a
	di
	out	(099h),a		;put Cool Colors
	ld	a,090h
	ei
	out	(099h),a
	ld	hl,palette+RUT_MROM
	ld	bc,0209ah
	otir




noCCOL:	
;------------------------------------------------------;TURBO
	ld	a,(002Dh)
	cp	1
	jr	z,MSX1
	
	ld	a,(TURBO+RUT_MROM)
	or	a
	call	nz,putTURBO+RUT_MROM


	ld	a,05h
	call	SNSMAT
	bit 1,a	;"T" key	
	call	z,putTURBO+RUT_MROM



;------------------------------------------------------;lenguaje


MSX1:	
	ld	a,(RC+RUT_MROM)
	or	a
	call	nz,putRC+RUT_MROM

	ld	a,(INT+RUT_MROM)
	or	a
	call	nz,putINT+RUT_MROM

	ld	a,(JAP+RUT_MROM)
	or	a
	call	nz,putJAP+RUT_MROM

	ld	a,03h
	call	SNSMAT
	bit 6,a	;"I" key	
	call	z,putINT+RUT_MROM
	
		
	ld	a,03h
	call	SNSMAT
	bit 7,a	;"J" key	
	call	z,putJAP+RUT_MROM


	ld	a,(EXEC+RUT_MROM)
	or	a
	jr	z,noEXIT

	ld	a,05h		
	call	SNSMAT
	bit 5,a	;"X" key	
	jr	z,contexe
	jr	yesEXIT

noEXIT:
	ld	a,05h		
	call	SNSMAT
	bit 5,a	;"X" key	
	jr	nz,contexe

yesEXIT:
	exx

	pop bc		
	pop de
	pop hl
	pop af

	exx

	pop bc		
	pop de
	pop hl
	pop af
	

	ret
	
;------------------------------------------------------------
contexe:
	ld	a,(04006h)
	cp	2
	jp	z,ponmirrorM+RUT_MROM
	cp	3
	jp	z,ponmirrorM+RUT_MROM
	
	cp	5
	jp	z,ponmir32k+RUT_MROM

	ld	a,(MAPPER+RUT_MROM)
	cp	5
	jp	z,ponmirror+RUT_MROM

	cp	7
	jp	z,ponrtype+RUT_MROM

	ld	a,(SPECIAL+RUT_MROM)
	cp	9
	jp	z,ponmirror+RUT_MROM

contbig:
	
	ld	a,(MAPPER+RUT_MROM)
	cp	3
	call	z,LOOK_4_SCC+RUT_MROM
	
		
	exx

	pop bc		
	pop de
	pop hl
	pop af

	exx

	pop bc		
	pop de
	pop hl
	pop af
	
;----------------------------------------  special ini

	push	af

	ld	a,(SPECIAL+RUT_MROM)

	cp	00
	jr	z,nospecial
	cp	01
	jr	z,golvelius
	
	cp	03
	jr	z,fanzone2
	cp	05
	jr	z,penw2
	
	cp	7
	jr	z,superlode

nospecial:
	
	

mirrorback:
	pop	af

	jp	R_MROM

superlode:
	xor	a
	ld	(noDSK-exeRAM+R_MROM),a
	jr	nospecial


golvelius:
	
	push hl
	push de
	push bc

	ld	hl,golvp+RUT_MROM
	ld	de,patchini-exeRAM+R_MROM
	ld	bc,000Ch
	ldir

	pop	bc
	pop	de
	pop	hl

	jr	nospecial




fanzone2:
	
	push hl
	push de
	push bc

	ld	hl,FZIIp+RUT_MROM
	ld	de,patchini-exeRAM+R_MROM
	ld	bc,0007h
	ldir

	pop	bc
	pop	de
	pop	hl

	jr	nospecial

penw2:

	ld	a,021h
	ld	hl,pengmap+R_MROM-exeRAM
	ld	(hl),a
	xor	a
	inc	hl
	ld	(hl),a
	ld	a,060h
	inc	hl
	ld	(hl),a
	jr	nospecial



ponmirror:
	
	ld	a,(SPECIAL+RUT_MROM)
	cp	5
	jp	z,contbig+RUT_MROM
	
	
	xor	a
	ld	(pag8+1+R_MROM-exeRAM),a
	inc	a
	ld	(pagA+1+R_MROM-exeRAM),a
	jr	actipag2

ponmirrorM:
	
	ld	a,1
	ld	(05000h),a
	
	ld	(pag8+1+R_MROM-exeRAM),a
	
	inc	a
	ld	(exeRAM+1+R_MROM-exeRAM),a
	
	ld	(pagA+1+R_MROM-exeRAM),a
	jr	actipag2

ponmir32k:

	ld	a,1
	ld	(05000h),a
	inc	a
	ld	(exeRAM+1+R_MROM-exeRAM),a
	inc	a
	ld	(pag8+1+R_MROM-exeRAM),a
	inc	a
	ld	(pagA+1+R_MROM-exeRAM),a
	jr	actipag2

ponrtype:
	ld	a,030h
	ld	(05000h),a
	ld	a,031h
	ld	(exeRAM+1+R_MROM-exeRAM),a
	jp	contbig+RUT_MROM








actipag2:
	in	a,(0a8h)	;put cartridge in page 2
	rra
	rra
	and	3
	ld	h,080h
	call	024h

	
	jp	contbig+RUT_MROM
;-------------------------------------------------------------

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

	ret

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

	ret



putTURBO:
				;Si es un Panasonic 2+, activamos Turbo
	LD	A,8
	OUT 	(040H),A	;out the manufacturer code 8 (Panasonic) to I/O port 40h
	IN	A,(040H)	;read the value you have just written
	CPL			;complement all bits of the value
	CP	8		;if it does not match the value you originally wrote,
	JR	NZ,Not_WX	;it is not a WX/WSX/FX.
	XOR	A		;write 0 to I/O port 41h
	OUT	(041H),A	;and the mode changes to high-speed clock
	ret

Not_WX: ld	a,(002Dh)
	cp	3
	ret	nz
	ld	a,081h
	call	0180h
	ret

putINT:	ld	a,0FFh
	ld	(LENGcopy-exeRAM+R_MROM),a
	ret

putJAP:	ld	a,000h
	ld	(LENGcopy-exeRAM+R_MROM),a
	ret

putRC:
	ld	a,2
	out	(0FEh),a
	ld	hl,04443h
	ld	(8010h),hl
	ld	a,07h
	ld	(8012h),a
	ld	a,(RC+RUT_MROM)
	ld	(8013h),a
	
	ld	hl,rcrom+RUT_MROM
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

golvp:
	di
	ld	sp,0f3b0h
	call	138h
	
	jp	04012h

FZIIp:
	di
	ld	sp,0f380h
	jp	04012h


rcrom:		db	000h,000h,000h,000h,000h,000h

;--------------------------------------------------------------------

checkslotrom:
	
	push	af
	push	hl
	push	de
	push	bc

	ld	hl,searchslot+RUT_MROM	;copy rutine  to memory page 
	ld	de,0CD7Eh
	ld	bc,searchslotend-searchslot
	ldir
	
	
	
	
	
	call	0138h
	rrca
	rrca
	and	03
	ld	c,a
	ld	b,0
	ld	hl,0ffc1h
	add	hl,bc
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a,(hl)
	and	0ch
	or	c
	
	ld	h,a		;back routine
	ld	l,0F7h
	ld	(0FEDAh),hl
	ld	hl,04004h
	ld	(0fedch),hl
	
	cpl

	and	3

	
	

	ld	(0CE4Fh),a	;SKIP SLOT!!

	pop	bc
	pop	de
	pop	hl
	pop	af

	ret








;-----------------------------------------------------------------



searchslot:

jum4:	ld	a,(de)		;copy to CD7eh
	or	c
	ld	c,a

	push    de		
jum3:   inc     hl
        push    hl
        ld      hl,4000h
jum2:   call    0ce1ah
        push    hl
        ld      hl,4241h
        rst     20h
        pop     hl
        ld      b,00h
        jr      nz,jum1
        call    0ce1ah
        push    hl
        push    bc
        push    de
        pop     ix
        ld      a,c
        push    af
        pop     iy
        call    nz,07ff2h
        pop     bc			;ini  after jump!!
        pop     hl
        call    0ce1ah
        add     a,0ffh
        rr      b
        call    0ce1ah
        add     a,0ffh
        rr      b
        call    0ce1ah
        add     a,0ffh
        rr      b
        ld      de,0fff8h
        add     hl,de
jum1:   ex      (sp),hl
        ld      (hl),b
        inc     hl
        ex      (sp),hl
        ld      de,3ffeh
        add     hl,de
        ld      a,h
        cp      0c0h
        jr      c,jum2
        pop     hl
        inc     hl
        ld      a,c
        and     a
        ld      de,000ch
        jp      p,0cde0h
        add     a,04h
        ld      c,a
        cp      90h
        jr      c,jum3
        and     03h
        ld      c,a
        ld      a,19h
        
	
	pop     de
        
	
	call	0CE4Bh

        cp      04h
        jr      c,jum4
        ld      hl,0fcc9h
        ld      b,40h
jum7:   ld      a,(hl)
        add     a,a
        jr      c,jum6
        inc     hl
        djnz    jum7
        ret     

jum6:   call    0ce2ah
        call    0024h
        ld      hl,(0f6c2h)
        ld      de,0c000h
        rst     20h
        jr      nc,jum5
        ex      de,hl
        ld      (0f6c2h),hl
jum5:   ld      hl,(8008h)
        inc     hl
        ld      (0f676h),hl
        ld      a,h
        ld      (0fbb1h),a
	call    0629ah
        jp      04601h
        call    0ce1eh
        ld      e,d
        ld      a,c
        push    bc
        push    de
        call    000ch
        pop     de
        pop     bc
        ld      d,a
        or      e
        inc     hl
        ret     

        ld      a,40h
        sub     b
        ld      b,a
        ld      h,00h
        rra     
        rr      h
        rra     
        rr      h
        rra     
        rra     
        and     03h
        ld      c,a
        ld      a,b
        ld      b,00h
        push    hl
        ld      hl,0fcc1h
        add     hl,bc
        and     0ch
        or      c
        ld      c,a
        ld      a,(hl)
        pop     hl
        or      c
        ret     
	
	
	inc     de		;check if is slot 2!!!!
        inc     c		
        ld      a,c
skipslot:
	cp	02		;self!!! (0CE4Fh)
	ret	nz
	inc	c		;if YES -> select slot 3 and continue
	ld	a,c
	inc	de
	ret



searchslotend:

;--------------------------------------------------------------------
RUT_MSCC	equ RUTrutin-LOOK_4_SCC
LOOK_4_SCC:	;from KINROU5.DRV 
	;OUT: SCC_found=slot  00:no  01:slot1 02:slot2 03:slot3 


		in	a,(0a8h)
		;ld	(inimapa8+1-exeRAM+R_MROM),a
		ld	(oldmap-exeRAM+R_MROM),a
		
		push	af
			
		rra
		rra
		and	030h

		ld	(RAMpag3A+1-exeRAM+R_MROM),a
		ld	(RAMpag3B+1-exeRAM+R_MROM),a
	





		pop	af


		rra
		rra
		and	3
		ld	h,080h
		call	024h




		in	a,(0a8h)

		
		
		ld	(pagRAM+1-exeRAM+R_MROM),a
		ld	(pagRAMpen+1-exeRAM+R_MROM),a
		ld	(pagRAMvoi+1-exeRAM+R_MROM),a
		
		ld	(slSCC+1-exeRAM+R_MROM),a
		ld	(slSCCpen+1-exeRAM+R_MROM),a
		ld	(pagSCCvoi+1-exeRAM+R_MROM),a

		rra
		rra
		cpl
		and	3
		

					; the other slot
		
		LD	HL,0fcc1h
		ld	c,a
		ld	a,l
		add	a,c
		LD	L,A
		ld	a,(hl)
		or	c
		ld	e,a
		
		
		
		

checkSCC:	LD	H,80h
		
		push	de
		
		CALL	024h	
		
		pop	de

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
                JR      Z,isSCC
		
	;	jr	isRAM

isRAM:		
		ld	a,e
		BIT	7,a
		
		jr	z,noSCC				;slot no expanded
		



		
		ADD	A,%00000100	; increase subslot number
		LD	E,A		; C = new slot + subslot
		BIT	4,A		; check if slot expanded
		
		JR	Z,checkSCC	
					
		
				; still some subslots left


		
noSCC:		 
		ld	a,1		;search GR8NET
		out	(05Eh),a
		in	a,(05fh)
		cp	0ffh
		jr	z,putolda8
		
		ld	e,a
		ld	a,2		
		out	(05Eh),a	
		ld	a,3		;select SCC mapper type in GR8NET
		out	(05fh),a
		jr	isSCC

putolda8:		
		ld	a,(oldmap-exeRAM+R_MROM)
		out	(0a8h),a
		ret

isSCC:		ld	a,e
		ld	(selectSCC+1-exeRAM+R_MROM),a


		in	a,(0a8h)
		ld	(slSCC+1-exeRAM+R_MROM),a
		ld	(slSCCpen+1-exeRAM+R_MROM),a
		ld	(pagSCCvoi+1-exeRAM+R_MROM),a
		
		
		jr	putolda8
		




LOOK_4_end: db 0	
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

exeRAM:	ld	a,01h
	ld	(07000h),a
pag8:	ld	a,02h
	ld	(09000h),a
pagA:	ld	a,03h
	ld	(0B000h),a
	
	
inimapa8: 
	ei
	halt

patchini:
	ld	hl,0FEDAh
noDSK:	push	hl

saveexe:
	jp 00000h ;self----
	nop
	nop
	nop
	nop
	nop

put60:	push	af
	and	a
	rla
	ld	(05000h),a
	inc	a
	ld	(07000h),a
	pop	af
pengmap:
	nop
	nop
	nop
	
	
	
	ret

put70:  push	af
put70rt:
	and	a
	rla
	ld	(09000h),a
	inc	a
	ld	(0B000h),a
	pop	af
	ret

LENGcopy: db	0
SCCTEMP:  db	0
oldmap:	  db	0

romancia:
	
	push	af
	ld	a,2
	jr	put70+1



PUTSCC:	push	af
	cp	03fh
	
	jr	z,pagSCC

	in	a,(0a8h)
	and	030h
RAMpag3A:	cp	030h	;self!!
	jr	z,RAMpag2


pagRAM:	ld	a,00h	;self!!!!	
			;left RAM in page 1

	OUT	(0A8h),a
	pop	af
                           			;---------------------------------------
	ld	(09000h),a			;select game in page 2
	ret

pagSCC:	
	in	a,(0a8h)
	and	30h
RAMpag3B:	cp	030h	;self!!
	jr	z,RAMpag2

slSCC:	ld	a,00	;self!!!!!
	
	OUT	(0A8h),a
	
quit:	jr	selectSCC

	pop	af
	ld	(09000h),a
	ret

selectSCC:
	ld	a,00	;self!!
	push	hl
	push	de
	push	bc
	ld	h,080h
	call	024h
	
	
	ld	hl,quit+2-exeRAM+R_MROM	;quit jump here!!
	ld	de,quit-exeRAM+R_MROM
	ld	bc,0005h
	ldir

	pop	bc
	pop	de
	pop	hl
	
	pop	af
	ld	(09000h),a
	ret

RAMpag2:	
	pop af
	ret





penint:
	push	af
	
pagRAMpen:
	ld	a,00	; select ROM!!
	out	(0A8h),a
	ld	a,(hl)
	push	af

slSCCpen:
	ld	a,00	;select SCC
	out	(0A8h),a
	
	pop	af
	ld	(de),a
	
	
	
	inc	hl
	inc	de
	djnz	pagRAMpen
	pop	af
	ret

pentvoice:
	
	ld	hl,0C2C0h
	jr	contvoice
secvoice:
	ld	hl,0C2C2h
contvoice:
pagRAMvoi:
	ld	a,00	; select ROM!!
	out	(0A8h),a
	
	ld	(savehl1+1-exeRAM+R_MROM),hl
	ld	(savehl2+1-exeRAM+R_MROM),hl	
savehl1: ld	hl,(0C2C0h)  ;self!!
	ld	de,0FAE2h
	ld	bc,0013h
	ldir
savehl2: ld	(0C2C0h),hl  ;self!!
	ld	hl,0FAE2h
	
pagSCCvoi:
	ld	a,00	; select ROM!!
	out	(0A8h),a
	ret

gallf:	ld	a,0
	ld	hl,08031h
	push	hl
	jp	put70-exeRAM+R_MROM




rtyp:
	push	af
	inc	a
	
	jp	put70rt-exeRAM+R_MROM






slaydockpag:

	push	af
	ld	a,l
	ld	(09000h),a
	ld	a,h
	ld	(0B000h),a
	pop	af
	ret
slaydockpag2:

	push	af
	ld	a,l
	ld	(07000h),a
	ld	a,h
	ld	(09000h),a
	pop	af
	ret

goemonpatch:
	ei
	jr	goemonpatch+1

rutEend:
;---------------------------------  Search ROM type
t_tipoK8:db	13,10,"KONAMI 8K Type Mapper",13,10,13,10,"$"
t_16kPG: db	13,10,"ASCII 16K Type Mapper",13,10,13,10,"$"
t_tipoC: db	13,10,"ASCII 8K Type Mapper",13,10,13,10,"$"
;------------------------------------------------

bus_tipo:
	
	
	
	and a
	ld	hl,(08127h)		;Super Lode Runner
	ld	bc,0C5A8h
	sbc	hl,bc
	jr	nz,noSLODERU
	
	ld	a,08Dh
	ld	(saveexe+1),a
	ld	a,040h
	ld	(saveexe+2),a
	ld	a,7
	ld	(SPECIAL),a
	
	ld	a,6
	jp	fin_detec
	
noSLODERU:	
	
	and a
	ld	hl,(08000h)
	ld	bc,08008h	;R-Type
	sbc	hl,bc
	jr	nz,nortypem
	ld	a,7
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
	ld	hl,(08036h)		;Golvellius
	ld	bc,00021h
	sbc	hl,bc
	jr	nz,noGOLVE
	ld	a,1
	ld	(SPECIAL),a

noGOLVE:
	and a
	ld	hl,(08036h)		;Peng Wars 2
	ld	bc,0C03Fh
	sbc	hl,bc
	jr	nz,noPENWARS2
	ld	a,5
	ld	(SPECIAL),a
	ld	a,5
	jp	fin_detec

noPENWARS2:


	
	and a
	ld	hl,(08036h)		;Fantasy Zone II
	ld	bc,03A43h
	sbc	hl,bc
	jr	nz,noFZII
	ld	a,3
	ld	(SPECIAL),a

noFZII:


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
	
	inc	hl
	inc	hl
	ld e,42+14
	 push	bc
	ld	b,0
	ld	c,e
	ex	de,hl
	 ld	hl,R_MROM
	 add	hl,bc
	ex	de,hl
	pop	bc
	 ld	(hl),d
	 dec	hl
	 ld	(hl),e
	 dec	hl

	
sigBUSLNG:	inc	hl
no_2LNG:	dec	bc
	ld	a,b
	or	c
	jp	nz,b_lookLNG

	ret
;--------------------------------------------------------

patchk4:
	
	
	ld	hl,08000h
	ld	bc,02000h

b_lookk4:
	ld	a,(hl)

	call	goemon1
	call	goemon2

	
sigBUSk4:	cp	032h	;<<1
	jp	nz,no_1k4
	
	inc	hl
	ld	a,(hl)
	cp	00h	;<<2
	jr	z,si_0k4
	
	jp	nz,no_2k4

si_0k4:
	inc	hl

	ld	a,(hl)
;				;4000,6000,8000,A000  (A)
	cp	040h	;<<3a
	jp	z,is5k4
	cp	060h	;<<3b
	jp	z,is7k4
	cp	080h	;<<3c
	jp	z,is9k4
	cp	0A0h	;<<3d
	jp	z,isBk4
	

Back_TCk4: dec	hl
	jp	no_2k4

		
is5k4:	ld	e,50h	
	jp	isk4
	
is7k4:	
	ld	e,70h	
	jp	isk4

is9k4:	
	ld	e,90h
	jp	isk4


isBk4:	ld	e,0B0h	;<<new 3d
	jp	isk4


isk4:	
	 ld	(hl),e
	 dec	hl

	jr	no_2k4

no_1k4:	inc	hl
no_2k4:	dec	bc
	ld	a,b
	or	c
	jp	nz,b_lookk4
	
	jp	FLashPage


goemon1:
	
	push	af
	push	hl

	cp	0cdh		;patch Goemon English Version!!
	jr	nz,nogoemon
	
	inc	hl
	ld	a,(hl)
	cp	004h
	jr	nz,nogoemon
	
	inc	hl
	ld	a,(hl)
	cp	040h
	jr	nz,nogoemon
	
	ld	a,0F4h
	ld	(hl),a
	dec	hl
	ld	a,0FFh
	ld	(hl),a
	dec	hl
	ld	a,032h
	ld	(hl),a
	
	
nogoemon:
	pop	hl
	pop	af
	ret
goemon2:
	
	push	af
	push	hl

	cp	0c3h		;patch Goemon English Version!!
	jr	nz,nogoemon
	
	inc	hl
	ld	a,(hl)
	cp	00ah
	jr	nz,nogoemon
	
	inc	hl
	ld	a,(hl)
	cp	040h
	jr	nz,nogoemon
	
	
	ld	a,0FAh
	ld	(hl),a		;quit Call 4004h put JP FA8Fh
	dec	hl
	ld	a,08Fh
	ld	(hl),a
	
	ld	a,9
	ld	(SPECIAL),a
	jr	nogoemon

;-----------------------------------------------------------------------------------


patchas8:
	
	
	ld	hl,08000h
	ld	bc,02000h
	


b_lookas8:	ld	a,(hl)

	
	call ninjakun
	call fleetcom
	call slaydock





	
sigBUSas8:	cp	032h	;<<1
	jp	nz,no_1as8
	
	inc	hl
	ld	a,(hl)
	cp	00h	;<<2
	jr	z,si_0as8
	cp	0F8h	;<<2
	jr	z,si_0as8
	cp	41h	;<<2
	jr	z,si_0as8
	
	jp	nz,no_2as8

si_0as8:
	inc	hl

	ld	a,(hl)
;				;4000,6000,8000,A000  (A)
	cp	060h	;<<3a
	jp	z,is5as8
	cp	067h	;<<3a
	jp	z,is5as8

	cp	068h	;<<3b
	jp	z,is7as8
	cp	06Fh	;<<3b
	jp	z,is7as8

	cp	070h	;<<3c
	jp	z,is9as8
	cp	077h	;<<3c
	jp	z,is9as8

	cp	078h	;<<3d
	jp	z,isBas8
	cp	07Fh	;<<3d
	jp	z,isBas8

Back_TCas8: dec	hl
	jp	no_2as8

		
is5as8:	ld	e,50h	
	jp	isas8
	
is7as8:	
	ld	e,70h	
	jp	isas8

is9as8:	
	ld	a,l
	cp	0Ch
	jr	nz,contis9
	ld	a,h
	cp	080h
	jr	z,no_2as8
contis9:
	
	ld	e,90h
	jp	isas8


isBas8:	ld	e,0B0h	;<<new 3d
	jp	isas8


isas8:	
	 ld	(hl),e
	 dec	hl
	xor	a
	ld	(hl),a
	inc	hl

	jr	no_2as8

no_1as8:	inc	hl
no_2as8:	dec	bc
	ld	a,b
	or	c
	jp	nz,b_lookas8
	
	jp	FLashPage

ninjakun:
	
	push	af
	push	hl

	cp	0EDh		;patch NINJA KUN
	jr	nz,noninjakun
	
	inc	hl
	ld	a,(hl)
	cp	43h
	jr	nz,noninjakun
	
	inc	hl
	ld	a,(hl)
	cp	74h
	jr	nz,noninjakun
	
	inc	hl
	ld	a,(hl)
	cp	0B7h
	
	jr	nz,noninjakun
	xor	a
	ld	(hl),a
	dec	hl
	ld	(hl),a
	dec	hl
	ld	(hl),a
	dec	hl
	ld	(hl),a
noninjakun:
	pop	hl
	pop	af
	ret


fleetcom:
	
	push	af
	push	hl

	cp	0f3h		;patch fleet commander 2!!
	jr	nz,nofleetcom
	
	inc	hl
	ld	a,(hl)
	cp	072h
	jr	nz,nofleetcom
	
	inc	hl
	ld	a,(hl)
	cp	0fbh
	jr	nz,nofleetcom
	
	ld	a,0FAh
	ld	(hl),a
	
	dec	hl

	ld	a,079h
	ld	(hl),a
	
	dec	hl

	ld	a,0CDh
	ld	(hl),a

	
nofleetcom:
	pop	hl
	pop	af
	ret

slaydock:
	push	af
	push	hl

	cp	022h		
	jr	nz,noslaydock
	
	inc	hl
	ld	a,(hl)
	cp	0ffh
	jr	nz,noslaydock
	
	inc	hl
	ld	a,(hl)
	cp	077h
	jr	z,slaydock1
	cp	06Fh
	jr	z,slaydock2
	jr	noslaydock
slaydock1:
	ld	a,0FAh
	ld	(hl),a
	dec	hl
	ld	a,079h
	ld	(hl),a
	dec	hl
	ld	a,0CDh
	ld	(hl),a
	jr	noslaydock

slaydock2:
	ld	a,0FAh
	ld	(hl),a
	dec	hl
	ld	a,084h
	ld	(hl),a
	dec	hl
	ld	a,0CDh
	ld	(hl),a
	

	
noslaydock:
	pop	hl
	pop	af
	ret
;-----------------------------------------------------------------------------------


patchas16:
	
	
	
	
	and a
	ld	hl,(0802fh)
	ld	bc,08031h	;Gall Force!!!!!!!!!!!!!
	sbc	hl,bc
	jr	nz,nogallfo
	ld	hl,802fh
	ld	a,06Bh
	ld	(hl),a
	inc	hl
	ld	a,0fah
	ld	(hl),a
	
	
nogallfo:

	and a
	ld	hl,(08057h)
	ld	bc,0CD52h	;Super Pierrot!!!!!!!!!!!!!
	sbc	hl,bc
	jr	nz,nosuppierrot
	ld	a,02Bh
	ld	(saveexe+1),a
	ld	a,080h
	ld	(saveexe+2),a


nosuppierrot:	

	ld	hl,08000h
	ld	bc,02000h

b_lookas16:	ld	a,(hl)

	call	romancia2
	
sigBUSas16:	
	cp	021h
	jr	z,yes21
	
	cp	032h	;<<1
	jp	nz,no_1as16
	
	inc	hl
	ld	a,(hl)
	cp	00h	;<<2
	jr	z,si_0as16
	cp	0ffh
	jr	z,si_0as16

	jp	nz,no_2as16


yes21:	inc	hl
	ld	a,(hl)
	cp	00h	;<<2
	jp	nz,no_2as16
	inc	hl
	ld	a,(hl)
	cp	60h
	jr	z,is5as16
	cp	70h
	jr	z,isromanc		;Romancia!!
	jp	no_2as16

si_0as16:
	inc	hl

	ld	a,(hl)
;				;4000,6000,8000,A000  (A)
	cp	060h	;<<3a
	jp	z,is5as16
	cp	070h	;<<3b
	jp	z,is7as16
	cp	080h	;<<3b
	jp	z,is7as16
	cp	077h	;<<3b
	jp	z,is7as16
	
	
	

Back_TCas16: dec	hl
	jp	no_2as16

		
is5as16:	ld	e,18+11
	jp	isas16

isromanc:	
	inc	hl
	ld	a,(hl)
	cp	036h
	dec	hl
	jp	nz,no_2as16
	
	
	dec	hl
	dec	hl
	ld	a,0CDh   ; Romancia!!!	
	ld	(hl),a
	inc	hl
	ld	a,0E3h
	ld	(hl),a
	inc	hl
	ld	a,0f9h
	ld	(hl),a
	inc	hl
	xor	a
	ld	(hl),a
	inc	hl
	ld	(hl),a
	jr	no_2as16

is7as16:	
	ld	a,l
	cp	0Ch
	jr	nz,contis16
	ld	a,h
	cp	080h
	jr	z,no_2as16
contis16:
	
	
	
	ld	e,30+14
	jp	isas16



isas16:	
	 push	bc
	ld	b,0
	ld	c,e
	ex	de,hl
	 ld	hl,R_MROM
	 add	hl,bc
	ex	de,hl
	pop	bc
	 ld	(hl),d
	 dec	hl
	 ld	(hl),e
	 dec	hl
	 ld	(hl),0CDh	;call
	 inc	hl

	jr	no_2as16

no_1as16:	inc	hl
no_2as16:	dec	bc
	ld	a,b
	or	c
	jp	nz,b_lookas16
	
	jp	FLashPage

romancia2:
	
	push	af
	push	hl

	cp	0C3h		;patch Romancia 2!!
	jr	nz,noromancia2
	
	inc	hl
	ld	a,(hl)
	cp	04h
	jr	nz,noromancia2
	
	inc	hl
	ld	a,(hl)
	cp	040h
	jr	nz,noromancia2
	
	
	

	ld	a,0f9h
	ld	(hl),a
	
	dec	hl

	ld	a,0d4h
	ld	(hl),a

	
noromancia2:
	pop	hl
	pop	af
	ret







;----------------------------------------------------
patchrtype:
	
	
	
	
	
	ld	hl,08000h
	ld	bc,02000h

b_lookrtype:	ld	a,(hl)


	
sigBUSrtype:	
	
	
	cp	032h	;<<1
	jp	nz,no_1rtype
	
	inc	hl
	ld	a,(hl)
	cp	00h	;<<2
	jr	z,si_0rtype
	

	jp	nz,no_2rtype



si_0rtype:
	inc	hl

	ld	a,(hl)
;				;4000,6000,8000,A000  (A)
	cp	060h	;<<3a
	jp	z,is5rtype
	cp	070h	;<<3b
	jp	z,is7rtype
	cp	078h	;<<3b
	jp	z,is7rtype
		
	

Back_TCrtype: dec	hl
	jp	no_2rtype

		
is5rtype:	
	ld	e,18+11
	jp	isrtype


is7rtype:	
	
		
	ld	a,l
	cp	0Ch
	jr	nz,contisrtype
	ld	a,h
	cp	080h
	jr	z,no_2rtype

contisrtype:
		
	
	ld	e,204
	jp	isrtype



isrtype:	
	 push	bc
	ld	b,0
	ld	c,e
	ex	de,hl
	 ld	hl,R_MROM
	 add	hl,bc
	ex	de,hl
	pop	bc
	 ld	(hl),d
	 dec	hl
	 ld	(hl),e
	 dec	hl
	 ld	(hl),0CDh	;call
	 inc	hl

	jr	no_2rtype

no_1rtype:	inc	hl
no_2rtype:	dec	bc
	ld	a,b
	or	c
	jp	nz,b_lookrtype
	
	jp	FLashPage



	



;-------------------------------------------------------------------------

patchk8:
	
	ld	a,(08013h)
	ld	(oksalam+1),a



	ld	hl,08000h
	ld	bc,02000h
	

b_lookk8:
	
	ld	a,(hl)

	
	call	salamander
	
	call	pennant2
	call	penna2quit
sigBUSk8:	cp	032h	;<<1
	jp	nz,no_1k8
	
	inc	hl
	ld	a,(hl)
	or	a	;<<2
	jr	z,si_0k8
	
	jp	nz,no_2k8

si_0k8:
	inc	hl

	ld	a,(hl)
;				;4000,6000,8000,A000  (A)
	
	cp	090h	;<<3c
	jp	z,is9k8
	

Back_TCk8: dec	hl
	jp	no_2k8

		


is9k8:	
	
	ld	e,45+19

	call penvoices
	
	
	
	jp	isk8


isk8:	
	 push	bc
	ld	b,0
	ld	c,e
	ex	de,hl
	 ld	hl,R_MROM
	 add	hl,bc
	ex	de,hl
	pop	bc
	 ld	(hl),d
	 dec	hl
	 ld	(hl),e
	 dec	hl
	 ld	(hl),0CDh	;call
	 inc	hl

	jr	no_2k8

	jr	no_2k8

no_1k8:	inc	hl
no_2k8:	dec	bc
	ld	a,b
	or	c
	jp	nz,b_lookk8
	
	jp	FLashPage

pennant2:
	
	push	af
	push	hl

	cp	07Eh		;patch PENNANT RACE 2!!
	jr	nz,nopennant2
	
	inc	hl
	ld	a,(hl)
	cp	12h
	jr	nz,nopennant2
	
	inc	hl
	ld	a,(hl)
	cp	23h
	jr	nz,nopennant2
	
	inc	hl
	ld	a,(hl)
	cp	013h
	jr	nz,nopennant2

	inc	hl
	ld	a,(hl)
	cp	010h
	jr	nz,nopennant2

	inc	hl
	ld	a,(hl)
	cp	0FAh
	jr	nz,nopennant2

	xor	a
	ld	(hl),a
	dec	hl
	ld	(hl),a
	dec	hl
	ld	(hl),a
	dec	hl
	
	ld	a,0FAh
	ld	(hl),a
	dec	hl
	ld	a,030h
	ld	(hl),a
	dec	hl
	ld	a,0CDh
	ld	(hl),a
	

nopennant2:
	pop	hl
	pop	af
	ret


penvoices:
	push	hl
	
	
	inc	hl
	ld	a,(hl)
	cp	02Ah
	jr	nz,nopenvoices
	inc	hl
	inc	hl
	ld	a,(hl)
	cp	0C2h
	jr	nz,nopenvoices
	dec	hl
	ld	a,(hl)
	cp	0C0h
	jr	z,voice1
	cp	0C2h
	jr	z,voice2
	jr	nz,nopenvoices
voice1:
	ld	e,90+41h
	jr	quitjumpvoice

voice2:
	ld	e,95+41h
	jr	quitjumpvoice
	
nopenvoices:
	pop	hl
	ret
quitjumpvoice:
	xor	a
	dec	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
	jr	nopenvoices

penna2quit:
	push	af
	push	hl

	cp	0CDh		;patch PENNANT RACE 2!!
	jr	nz,nopennant2
	
	inc	hl
	ld	a,(hl)
	cp	059h
	jr	nz,nopennant2
	
	inc	hl
	ld	a,(hl)
	cp	063h
	jr	nz,nopennant2
	
	xor	a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
	jr	nopennant2




	
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

changeini:
	
	ld	a,(SPECIAL)
	cp	1
	jr	nz,noinigol
	
	push	hl
	ld	hl,rutinG
	ld	de,08002h
	ld	bc,rutinENDG-rutinG
	
	ldir
	pop	hl
	ret



noinigol:
	push	hl
	ld	hl,rutin
	ld	de,08000h
	ld	bc,rutinEND-rutin
	
	ldir
	pop	hl

	ret
	
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

NOMA:	db	"ROM File:  Mirrored Mapper Type",CR,LF,"$"
K4:	db	"ROM File:  Konami Mapper Type",CR,LF,"$"
K8:	db	"ROM File:  Konami SCC Mapper Type",CR,LF,"$"
AS8:	db	"ROM File:  ASCII 8k Mapper Type",CR,LF,"$"
AS16:	db	"ROM File:  ASCII 16k Mapper Type",CR,LF,"$"
SLRUN:	db	"ROM File:  Super Lode Runner Mapper Type",CR,LF,"$"
RTYPE:	db	"ROM File:  R-Type Mapper Type",CR,LF,"$"



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
ParameterR:
	db	0
OverWR:
	db	"Y"

;--------------------------------------------------

MESVER:
	db	CR,LF,"FLP.COM v1.65 by Victor Martinez",CR,LF
	db	"Read mapper type and patch ROMs to SCC Mapper.",CR,LF
	db	"You can use the SCC from other slot",CR,LF
	db	"Based on FLLOAD by K.Tsujikawa, dedicated to Rafa Bollero."
MESend:
	db	CR,LF,CR,LF,"$"
HlpMes:
	
	
	db	"  /E  Erase FashROM             /Sxx FlashROM slot         ",CR,LF
	db	"  /I  Force International       /J  Force Japanese         ",CR,LF
	db	"  /P  Force PAL (50Hz)          /N  Force NTSC (60Hz)      ",CR,LF 
	db	"  /C  NO change color palette to 'Cool Colors'             ",CR,LF
	db	"  /T  Force Turbo Mode (only for Turbo R and  Panasonic 2+)",CR,LF
	db	"  /X  Game won't execute unless you press 'X' key at boot  ",CR,LF
	db	"  /R  Reset Computer            /D Enable Floppy Disk      ",CR,LF
	db	"  /K7xx Simulate KONAMI RC7xx inserted in the other slot   ",CR,LF
	db	CR,LF
	db	"Keys with game patched at init computer:",CR,LF
	db	"  P Put PAL (50Hz)                   N  Put NTSC (60Hz)",CR,LF
	db	"  I Force International              J  Force Japanese ",CR,LF
	db	"  T Force Turbo (Panasonic 2+,TR)    X  No EXE / Yes EXE   ",CR,LF
	db	"  C Disable 'Cool Colors'            D  Enable Floppy Disk",CR,LF,CR,LF
	
	db	"   Usage: FLP filename[.ext] [/options]","$"
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
Garakuta:
	db	0,8,59
	db	010h,012h,002h,80h, 000h,032h,00Ah,80h, 000h,090h,00Ch,80h, 000h,03Ch,00Dh,80h
	db	000h,032h,00Eh,80h, 0F3h,0B0h,010h,80h, 021h,0C9h,011h,80h, 0DAh,03Eh,012h,80h
	db	0FEh,001h,013h,80h, 03Eh,032h,014h,80h, 0F7h,000h,015h,80h, 077h,070h,016h,80h
	db	023h,021h,017h,80h, 0CDh,0DAh,018h,80h, 03Fh,0FEh,019h,80h, 040h,036h,01Ah,80h
	db	077h,0F7h,01Bh,80h, 011h,071h,01Dh,80h, 025h,023h,01Eh,80h, 040h,036h,01Fh,80h
	db	073h,025h,020h,80h, 072h,036h,022h,80h, 0FBh,040h,023h,80h, 002h,004h,085h,80h
	db	032h,0CDh,086h,80h, 000h,00Ah,087h,80h, 070h,040h,088h,80h, 001h,002h,08Fh,80h
	db	032h,0CDh,090h,80h, 000h,00Ah,091h,80h, 070h,040h,092h,80h, 001h,002h,084h,81h
	db	032h,0CDh,085h,81h, 000h,00Ah,086h,81h, 070h,040h,087h,81h, 002h,004h,008h,82h
	db	032h,0CDh,009h,82h, 000h,00Ah,00Ah,82h, 070h,040h,00Bh,82h, 001h,002h,075h,82h
	db	032h,0CDh,076h,82h, 000h,00Ah,077h,82h, 070h,040h,078h,82h, 002h,004h,093h,82h
	db	032h,0CDh,094h,82h, 000h,00Ah,095h,82h, 070h,040h,096h,82h, 002h,004h,0B0h,82h
	db	032h,0CDh,0B1h,82h, 000h,00Ah,0B2h,82h, 070h,040h,0B3h,82h, 002h,004h,0CDh,82h
	db	032h,0CDh,0CEh,82h, 000h,00Ah,0CFh,82h, 070h,040h,0D0h,82h, 002h,004h,0EAh,82h
	db	032h,0CDh,0EBh,82h, 000h,00Ah,0ECh,82h, 070h,040h,0EDh,82h
Garakuta_P1:
	db	1,8,4
	db	003h,006h,047h,87h, 032h,0CDh,048h,87h, 000h,00Ah,049h,87h, 070h,040h,04Ah,87h
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
MSXDOS22:
	db	0,9,15
	db	032h,007h,092h,80h, 000h,032h,093h,80h, 060h,000h,094h,80h, 0C9h,050h,095h,80h
	db	000h,03Ch,096h,80h, 000h,032h,097h,80h, 000h,070h,099h,80h, 000h,0C9h,09Ah,80h
	db	04Dh,04Dh,01Eh,81h, 053h,053h,01Fh,81h, 058h,058h,020h,81h, 02Dh,02Dh,021h,81h
	db	044h,044h,022h,81h, 04Fh,04Fh,023h,81h, 053h,053h,024h,81h
MSXDOS22_P1:
	db	1,9,8
	db	032h,007h,092h,80h, 000h,032h,093h,80h, 060h,000h,094h,80h, 0C9h,050h,095h,80h
	db	000h,03Ch,096h,80h, 000h,032h,097h,80h, 000h,070h,099h,80h, 000h,0C9h,09Ah,80h
MSXDOS22_P2:
	db	2,9,8
	db	032h,007h,092h,80h, 000h,032h,093h,80h, 060h,000h,094h,80h, 0C9h,050h,095h,80h
	db	000h,03Ch,096h,80h, 000h,032h,097h,80h, 000h,070h,099h,80h, 000h,0C9h,09Ah,80h
MSXDOS22_P3:
	db	3,9,8
	db	032h,007h,092h,80h, 000h,032h,093h,80h, 060h,000h,094h,80h, 0C9h,050h,095h,80h
	db	000h,03Ch,096h,80h, 000h,032h,097h,80h, 000h,070h,099h,80h, 000h,0C9h,09Ah,80h
; --------
MSXDOS22NL:
	db	0,10,15
	db	032h,007h,092h,80h, 0FEh,032h,093h,80h, 07Fh,000h,094h,80h, 0C9h,050h,095h,80h
	db	000h,03Ch,096h,80h, 000h,032h,097h,80h, 000h,070h,099h,80h, 000h,0C9h,09Ah,80h
	db	04Dh,04Dh,01Eh,81h, 053h,053h,01Fh,81h, 058h,058h,020h,81h, 02Dh,02Dh,021h,81h
	db	044h,044h,022h,81h, 04Fh,04Fh,023h,81h, 053h,053h,024h,81h
MSXDOS22NL_P1:
	db	1,10,8
	db	032h,007h,092h,80h, 0FEh,032h,093h,80h, 07Fh,000h,094h,80h, 0C9h,050h,095h,80h
	db	000h,03Ch,096h,80h, 000h,032h,097h,80h, 000h,070h,099h,80h, 000h,0C9h,09Ah,80h
MSXDOS22NL_P2:
	db	2,10,8
	db	032h,007h,092h,80h, 0FEh,032h,093h,80h, 07Fh,000h,094h,80h, 0C9h,050h,095h,80h
	db	000h,03Ch,096h,80h, 000h,032h,097h,80h, 000h,070h,099h,80h, 000h,0C9h,09Ah,80h
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
Tatica:
	db	0,11,6
	db	0E5h,0E5h,09Ah,97h, 070h,000h,09Bh,97h, 0BEh,0BEh,09Ch,97h, 0C8h,0C8h,09Dh,97h
	db	0CDh,0CDh,09Eh,97h, 006h,006h,09Fh,97h
Tatica_P1:
	db	1,11,4
	db	077h,000h,0E2h,91h, 077h,000h,0CDh,9Ah, 0EDh,000h,0BEh,9Eh, 0B0h,000h,0BFh,9Eh
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

twinbeepatch:	db	0Ach,081h,091h,006h,040h,0aah
gmasterpatch:	db	000h,030h,031h,013h,035h,0aah
qbertpatch:	db	0bah,0b2h,086h,007h,046h,0aah
knightpatch:	db	0b7h,08bh,09eh,00ah,039h,0aah





; --------
;, 060h,070h,0h,h
;, 080h,090h,0h,h
;, 0A0h,0B0h,0h,h
; Patch data

; db page number,patch ID,number of patch
; db original value, new value,address FSB,address MSB, etc...
; (address of data = 8000h ~ 9FFFh)