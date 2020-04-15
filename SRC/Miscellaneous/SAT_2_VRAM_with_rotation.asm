;Sprite transfer from RAM to VRAM with rotation for MSX1
;This routine is used in all KONAMI MSX1 game
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

;This is the call to BIOS function:SETWRT
SETWRT:	equ	0053h
VDP_DW:	equ	0007h	;port to write in VRAM from BIOS
;--------------------------------------------

;Set this values for your game:

;Adress of Sprite Attribute Table in VRAM
SAT_in_VRAM:		equ	03B00h

;Adress of Sprite Attribute Table in RAM to transfer
SAT_in_RAM:            equ	0EC80h

;This byte is used to check permutation number
permut_value:		equ	0E061h    
	       
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
SAT_2_VRAM:
                ld      hl, SAT_in_VRAM		; SAT in VRAM adress
                call    set_VRAM_2_write
                di
                exx
;This permutes sprites
                ld      hl, permut_value	;permutation number
                ld      a, (hl)
                add     a, 1Ch
                and     7Ch 
                ld      (hl), a
                ld      e, a
                ld      d, 20h 

SAT_2_VRAM_loop:                      
                ld      a, e
                ld      hl, SAT_in_RAM		;Adress of Sprite Attribute Table in RAM
                add     a, l
                ld      l, a
                ld      b, 4

SAT_2_VRAM_loop2:                      
                outi
                jp      nz, SAT_2_VRAM_loop2
                ld      a, e
                add     a, 0Ch
                and     7Ch 
                ld      e, a
                dec     d
                jr      nz, SAT_2_VRAM_loop
                ei
                ret
;------------------------------------------------------------------
;IN: HL = VRAM adress to transfer
set_VRAM_2_write:                       
              
		ex      af, af'
                call    SETWRT
                exx
                ld      a, (VDP_DW)
                ld      c, a
                exx
                ex      af, af'
                ret