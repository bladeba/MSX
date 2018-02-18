;Search SCC in any slot-subslot
;----------------------------------------------------------------------------------
;You can execute it from RAM or ROM
;Input:	Nothing
;Output: a=slot with SCC, a=0FFh... not found SCC 

Search_SCC:

	ld	bc,00400h ;b->4 loop for all slots
	ld	hl,0fcc1h ;in RAM ->EXPTBL 

next_slot:
	push	bc
	push	hl
	ld	a,(hl)
	bit	7,a	;expanded slot?
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
	ld	a,0ffh	;SCC not found!!->A=0FFh
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
	ld	a,0ffh	;SCC not found!!->A=0FFh
	ret

	


check_no_expand:

	push	af
	call	putslotSCC
	jr	nc,next_slot2
	pop	af
	scf
	ret
next_slot2:
	pop	af
	and	a
	ret


putslotSCC:
	ld	h,80h
	call	0024h ;call ENASLT (put slot in 08000h-BFFFh)
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
		
		scf
		ret


isRAM:		
		
		or	a
		ret	

;-------------------------------------------------------------	