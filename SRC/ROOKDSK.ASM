



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

	org	0100h

START:
	jp	Main

MESVER:
	db	CR,LF,"Rookie drive DISKROM Loader v1.1 beta",CR,LF
	db	"based on FLLOAD by K.Tsujikawa"
MESend:
	db	CR,LF,CR,LF,"$"
HlpMes:
	db	"Usage: FL8 filename.ext /Sxx /R /A",CR,LF
	db	"       FL8 /Sxx /E",CR,LF,CR,LF
	db	"(xx: MegaFlashRom slot address)",CR,LF,"$"
	db	CR,"(^_^)/~",CR,LF,1ah

DosErr:
	db	"File reading error!",CR,LF,"$"
FlsEra:
	db	"Sector erasing...$"
FlsEok:
	db	"OK",CR,LF,CR,LF,"$"
FlsErr:
	db	"Flash writing error!",CR,LF,"$"
DonMes:
	db	"Load complete. Thank you.",CR,LF,"$"
AM29F0xx:
	db	"29F040 found in Slot $"
NO_FLSH:
	db	"MegaFlashRom not found!",CR,LF,"$"
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
	call	BDOS		; Print MESVER message (FL8 info)

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

	cp	0A4h		; Device ID for 29F040B
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

	cp	086h		; Device ID for 29F040 AMIC
	ex	AF,AF'
	ld	a,034h
	ld	(AM29F0xx+4),a
	ld	a,030h
	ld	(AM29F0xx+5),a
	ex	AF,AF'
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

;	cp	020h		; Device ID for AM29F010
;	ex	AF,AF'
;	ld	a,031h
;	ld	(AM29F0xx+4),a
;	ld	a,030h
;	ld	(AM29F0xx+5),a
;	ex	AF,AF'
;	jr	z,ID_OK

	cp	0ADh		; Device ID for AM29F016
	ex	AF,AF'
	ld	a,031h
	ld	(AM29F0xx+4),a
	ld	a,036h
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

	call System_PrintChar
;	ld	c,2
;	call	BDOS		; Print primary Slot number

	ld	e,02Dh

	call System_PrintChar	
;	ld	c,2
;	call	BDOS		; Print "-" character

	ld	a,(ERMSlt)
	and	0Ch
	srl	a
	srl	a
	add	a,30h
	ld	e,a
	call System_PrintChar
;	ld	c,2
;	call	BDOS		; Print secondary Slot number	

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
	jr	z,No_S
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
	jp	z,Done		; Jump if syntax error
	ld	(ParameterR),a

; Check parameter /A
	
	ld	hl,DMA
	ld	b,(HL)
	ld	c,041h		; 'A' character
	call	SeekParameter
	cp	255
	jp	z,Done		; Jump if syntax error
	ld	(ParameterA),a

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
	cp	041h		; 'A' character
	jr	z,SyntaxOK
	cp	045h		; 'E' character
	jr	z,SyntaxOK
	cp	052h		; 'R' character
	jr	z,SyntaxOK
	cp	053h		; 'S' character
	jr	z,SyntaxOK
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
	ld	a,(ParameterA)
	cp	041h
	jr	z,NoErase	; Jump if option /A used 
	
	ld a,12
loopsectorerase:
	ld (6000h),a  ; switch
	ex af,af' ;'
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
	ld	a,030h
	ld	(4000h),a	; ... command

NoErase:
	ld	a,0ffh
	ld	de,4000h
	call	CHECK
	jp	c,Done		; Jump if Erase fail
	
	ld e, '.'
;	ld c,2   ; output function
;	call BDOS
	call System_PrintChar
	
	ex af,af' ;'
	add a,4
	cp 32
	jp nz, loopsectorerase
	
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
	ld	hl,4000h	; Number of records to read
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
	cp	4
	jr	z,TestSize
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
	ld	(6000h),a	; Select Flashrom page at Bank 4000h~5FFFh for ASCII mapper
	;ld	(5000h),a	; Select Flashrom page at Bank 4000h~5FFFh for SCC mapper

	ld	hl,4555h
	ld	de,42aah

	exx
	ld	bc,4000h	; Length
	ld	de,4000h	; Destination
	ld	hl,0A000h	; Source
	jp	Loop

TestSize:
	;ld	a,(FileSize)
	;cp	80h
	;jr	z,Patch4P4	; Jump if 32KB rom
;	cp	40h
;	jr	z,Patch4P4	; Jump if 16KB rom
	jp	Done


CONTloading:
	ld	a,h
	cp	40h
	ld	de,DosErr
	jp	nz,Done		; Jump if readed records number is not 2000h



FLashPage:	
	ld	a,(ERMSlt)
	ld	h,40h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh

	ld	a,(PreBnk)
	ld	(6000h),a	; Select Flashrom page at Bank 4000h~5FFFh for ASCII mapper
	;ld	(5000h),a	; Select Flashrom page at Bank 4000h~5FFFh for SCC mapper

	ld	hl,4555h
	ld	de,42aah

	exx
	ld	bc,4000h	; Length
	ld	de,4000h	; Destination
	ld	hl,BUFTOP	; Source
Loop:
 	di
	ld a,(hl)
	inc a
	jp z, NEXT
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
	ld	(6000h),a	; Select flashrom page 4000h~7FFFh for SCC mapper 
	ex	AF,AF'

	call	CHECK		; Check this byte
	jp	c,Done

NEXT:
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
	dec	a

	;cp 0x20
	;jp z, Done
	
	and	0fh
	cp	10
	jr	c,_8kR01
	add	a,7		; add	a,'A'-'0'-10
_8kR01:
	add	a,030h		; add	a,'0'
	ld	e,a
;	ld	c,2
;	call	BDOS		; Print current mapper page number
	call System_PrintChar
 
	ld	a,(PreBnk)
	and	0fh
	jp	nz,_8kL01
	ld	e,CR
	;ld	c,2
	;call	BDOS		; Print CR character
	call System_PrintChar
	ld	e,LF
	;ld	c,2
	;call	BDOS		; Print LF character
	call System_PrintChar
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
	call	ENASLT		; Select a Slot in Bank 1 (4000h ~ 7FFFh)

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
	cp	086h		; Device ID for AM29F040B
	jr	z,RDID_BCL2
	
	cp	0B0h		; Device for AM29F002 (Top Boot Block)
	jr	z,RDID_BCL2
	cp	034h		; Device for AM29F002 (Bottom Boot Block)
	jr	z,RDID_BCL2
	cp	020h		; Device ID for AM29F010
	jr	z,RDID_BCL2
	cp	0ADh		; Device ID for AM29F016
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
	ld	hl,6000h	; Page selection address for ASC8 mapper
	ld	e,0		; Page number
	call	0014h		; Select page 0 of Megaflashrom

	ld	a,(ERMSlt)	; Megaflashrom slot
	ld	hl,6800h	; Page selection address for ASC8 mapper
	ld	e,0		; Page number
	call	0014h		; Select page 1 of Megaflashrom

	ld	a,(ERMSlt)	; Megaflashrom slot
	ld	hl,7000h	; Page selection address for ASC8 mapper
	ld	e,0		; Page number
	call	0014h		; Select page 2 of Megaflashrom

	ld	a,(ERMSlt)	; Megaflashrom slot
	ld	hl,7800h	; Page selection address for ASC8 mapper
	ld	e,0		; Page number
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
	jp	0000h		; msx reset
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

; Patch for 16/32KB ROM Header & added page 4

NewHeader:
	ld	a,4
	ld	(06000h),a; length = 5
CopyINIpages:
	push	hl
	push	bc
	ld	hl,04022h; Start of INIpages routine in ROM
	ld	de,0C000h
	ld	bc,014H
	ldir
	pop	bc
	pop	hl
	jp	0C000h	; CopyINIpages length = 12h
INIpages:
	xor	a
	ld	(06000h),a
	inc	a
	ld	(06800h),a
	inc	a
	ld	(07000h),a
	inc	a
	ld	(07800h),a
HeaderJump:
	jp	4010h	; INIpages length = 13h


; Initialisation routine of pages for 32KB ROM (length = 11h)


; Initialisation routine of pages for 16KB ROM (length = 14h)

INIpages16:
	ld	a,1
	ld	(06800h),a
	ld	(07800h),a
	push	hl
	ld	hl,(0C012h)
	ld	a,(hl)
	inc	hl
	or	(hl)
	pop	hl
	ret	z
adrs16:
	jp	4010h

	
CHPUT    equ    000A2H
EXPTBL    equ    0FCC1H

System_PrintChar:    
    ex af,af' ; '
    push af
    ex af,af' ; '

    ld a,e
    ld iy,(EXPTBL-1)
    ld ix,CHPUT
    call CALSLT

    ex af,af'  ; '
    pop af
    ex af,af'; '
    ret
;Then replace all occurences of:
;    ld c,2
;    call BDOS	
	
	
	
	
ERMSlt:
	db	0
RAMtyp:
	db	0
PreBnk:
	db	12
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
HeaderADRS:
	dw	0
ParameterR:
	db	0
ParameterA:
	db	0
OverWR:
	db	"Y"

