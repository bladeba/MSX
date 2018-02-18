;Turn On Turbo CPU: MSX CIEL, Panasonic 2+,Panasonic Turbo R, special TurboCPU kits
;----------------------------------------------------------------------------------

;Input:	Nothing
;Output: Nothing 
	

putTURBO_CPU:
	
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
	
;------------------------------------------------------------------------------			
				;Check for Panasonic 2+
	LD	A,8
	OUT 	(040H),A	;out the manufacturer code 8 (Panasonic) to I/O port 40h
	IN	A,(040H)	;read the value you have just written
	CPL			;complement all bits of the value
	CP	8		;if it does not match the value you originally wrote,
	JR	NZ,Not_WX	;it is not a WX/WSX/FX.
	XOR	A		;write 0 to I/O port 41h
	OUT	(041H),A	;and the mode changes to high-speed clock
	jr	end_turbo

Not_WX:  ld	a,(0180h)	;Turbo R or Turbo CPU kits with JUMP in 0180h
	cp	0c3h
		;no_turbo
	jr	nz,end_turbo
	ld	a,082h		;DRAM Mode... for ROM Mode-> 81h
	call	0180h

end_turbo:

	ret