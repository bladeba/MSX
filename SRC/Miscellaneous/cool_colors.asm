;Put cool colors in MSX2 or higher
;Subroutine
Put_Cool_Colors:

	ld      a,(002Dh)	;MSX version number
				;0 = MSX 1
				;1 = MSX 2
				;2 = MSX 2+
				;3 = MSX turbo R
	or      a
	ret     z		;MSX1? -> ret


	ld      a,(0007h)	;read VDP port to write from BIOS
	inc     a		;port 99h
	ld      c,a
	xor     a		;Set p#pointer to zero.
	di
	out     (c),a
	ld      a,16+128
	ei
	out     (c),a
	inc     c		;port 9Ah for palette
	ld      hl,Cool_Colors_palette
	ld      b,0020h		;2 bytes per colour
	otir
	ret



Cool_Colors_palette:		;created by FRS

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
