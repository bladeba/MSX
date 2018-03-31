;xxh
Read_Joymega:
;Stick and buttons A,B,C and START
;shared by FX  (Thanks!!)
	
	di
	
	ld      a, 15   ; Read joystick port
        out     (#A0), a        
        in      a, (#A2)
        and     10101111b

        push    af	;and save it
        out     (#A1), a
        ld      a, 14
        out     (#A0), a
        in      a, (#A2)
;        and     00111111b
        or      11000000b               ;FIX for some MSX and OpenMSX

        ld      e, 0FFh
        cp      0F0h
        jr      z, .continue               ;Mouse??->Jump

        ld      e, a                    ;Nothing pressed-> FFh
                                        ;Save in E directions or B or C
.continue:
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
	
	ei
	
        ld      a, d            ; Check button A
        and     00001100b       ; -1
        ret     nz              ;Back.. not for button A or START

        ld      a, d
        and     00010000b
        jr      nz, check_START
        ld      a, e
        and     10111111b    ;Save in E if button A is pressed
        ld      e, a

check_START:
        ld      a, d
        and     00100000b
        ret     nz
        ld      a, e
        and     01111111b    ;Save in E if button START is pressed
        ld      e, a
        ret

; ---------------------------------------------------------------------------
;----------------------------------------------------------------------------
Read_Joymega_XYZ:;read X,Y Z and MODE buttons
        ld	de,08F23h
	ld	hl,0EF10h

	di
	
	ld      a, 15   ; Read joystick port
        out     (#A0), a        
        in      a, (#A2)
        and     d
	or	e

       
        out     (#A1), a
        ld      a, 14
        out     (#A0), a
        in      a, (#A2)
;        and     00111111b
        cpl              ;FIX for some MSX and OpenMSX

	and	03Fh

	ld	b,a
	and	10h
	ld	e,a
	ld	a,b
	and	2Fh
	ld	d,a

 
        ld      a, 15
        out     (#A0), a
     	in      a, (#A2)
	and	h
	ld	b,6

loop_6_buttons:

	;send loop to multiplexer to read the other buttons
	xor	l
        out     (#A1), a
	djnz	loop_6_buttons

        ld      a, 14
        out     (#A0), a
        in      a, (#A2)	
    	
	ei
	
	;now in A we have the pressed button
	;077h:Mode
	;07Bh:X
	;07Dh:Y
	;07Eh:Z
	;07Fh:Nothing

	ret


; ---------------------------------------------------------------------------
