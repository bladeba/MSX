	
	



BDOS	equ	5	
	org	0100h
	
	ld	de,search_string
	ld	c,40h;	Find first entry
	ld	ix,FIB
	ld	b,010000b;con directorios
	call	BDOS
	
	
	
	
	ld	c,01Ah ;set buffer disk transfer
	ld	de,buffer_directory
	call	BDOS
	
	;leemos un sector cualquiera de esa unidad
	ld	hl,00
	ld	de,99h ;sector 99h por ejemplo
	ld	a,1;unidad A
	dec	a
	ld	b,1	;numero de sectores
	ld	c,073h	;leer sector
	call	BDOS	
	
	
	
	
	

	;buscamos siguiente entrada
	ld	c,41h	;Find next entry
	ld	ix,FIB
	call	BDOS
	;aqui ya desaparece la particion sin dar error...
	
	rst	0	;volvemos correctamete al DOS

search_string:	db	"a:",0
FIB:	ds	64

buffer_directory:	ds	01024

