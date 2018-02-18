;Search MegaflashROM SD routine
;------------------------------

;Input:	Nothing

;Output: 
;	A=0 not found
;	A=1 found

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
	ld	a,1	;found A->1
	ret

not_found_MFRSD:
	xor	a	;not found A->0
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