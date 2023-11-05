.model small

skBufDydis	EQU 10
raBufDydis	EQU 2

.stack 100h

.data
	duom		db "duom.txt",0
	rez			db "rez.txt",0
	skBuf		db skBufDydis dup (0)
	raBuf		db raBufDydis dup (0)
	dFail		dw ?			
	rFail		dw ?
	nuskaityta	dw 0
	numStrs 	db 'nulis$', 'vienas$', 'du$', 'trys$', 'keturi$', 'penki$', 'sesi$', 'septyni$', 'astuoni$', 'devyni$'
	numOffset 	db 0, 6, 13, 16, 21, 28, 34, 39, 47, 55

.code
  klaidaAtidarantSkaitymui:
	JMP	pabaiga
  klaidaAtidarantRasymui:
	JMP	uzdarytiSkaitymui
	
  pradzia:
	MOV	ax, @data	
	MOV	ds, ax

	MOV	ah, 3Dh
	MOV	al, 00
	MOV	dx, offset duom
	INT	21h
	JC	klaidaAtidarantSkaitymui
	MOV	dFail, ax

	MOV	ah, 3Ch
	MOV	cx, 0
	MOV	dx, offset rez
	INT	21h
	JC	klaidaAtidarantRasymui
	MOV	rFail, ax

  skaityk:
	MOV	bx, dFail
	CALL	SkaitykBuf
	CMP	ax, 0
	JE	uzdarytiRasymui
	MOV cx, ax
	MOV dx, 0
	
	MOV	si, offset skBuf
	MOV di, offset raBuf
  dirbk:
	cmp cx, 0
	JE baigesiKaSkaitem
	
	DEC CX ; pazymim, kad viena nuskaitem
 
    MOV	bl, [si]
    CMP	bl, '0'
    JB	tesk
    CMP	bl, '9'
    JA	tesk
	
    SUB	bl, '0'
	add bl, offset numOffset
	
	mov ax, [bx]
	mov ah, 0
	mov bx, ax
	
	add bx, offset numStrs
	
  rasykZodi:
	cmp dx, raBufDydis
	JAE rasykBufs ; jeigu jau pilnas buferis, tada viska surasom ir idealiu atveju griztam cia
	
	mov ax, [bx]
	
	cmp al, '$'
	JE baigesiZodis
	
	mov ax, [bx]
	mov [di], al
	
	INC BX ; pakeliam adresa
	INC DX ; pakeliam, kad irasem
	INC DI ; pastumiam per viena vieta outputo buferi
	
	jmp rasykZodi
	
  rasykBufs:
	PUSH BX
	PUSH CX
	
	mov BX, rFail
	mov CX, DX
	CALL RasykBuf
	POP CX
	POP BX
	
	mov DX, 0
	MOV di, offset raBuf
	jmp rasykZodi
	
  baigesiZodis:
	inc si
	jmp dirbk

  tesk:

  baigesiKaSkaitem:
	CMP	nuskaityta, skBufDydis
	JE	skaityk

  uzdarytiRasymui:
	MOV	ah, 3Eh
	MOV	bx, rFail
	INT	21h
	JC	klaidaUzdarantRasymui
	
  uzdarytiSkaitymui:
	MOV	ah, 3Eh
	MOV	bx, dFail
	INT	21h
	JC	klaidaUzdarantSkaitymui

  pabaiga:
	mov ah, 4Ch
	int 21h

  klaidaUzdarantRasymui:
	JMP	uzdarytiSkaitymui
  klaidaUzdarantSkaitymui:
	JMP	pabaiga

PROC SkaitykBuf
	PUSH	cx
	PUSH	dx
	
	MOV	ah, 3Fh
	MOV	cx, skBufDydis
	MOV	dx, offset skBuf
	INT	21h
	JC	klaidaSkaitant

  SkaitykBufPabaiga:
	POP	dx
	POP	cx
	RET

  klaidaSkaitant:
	MOV ax, 0
	JMP	SkaitykBufPabaiga
SkaitykBuf ENDP

PROC RasykBuf
	PUSH 	AX
	PUSH	DX
	
	MOV	ah, 40h
	MOV	dx, offset raBuf
	INT	21h
	JC	klaidaRasant

  RasykBufPabaiga:
	POP 	AX
	POP		DX
	RET

  klaidaRasant:
	MOV	ax, 0			;Pažymime registre ax, kad nebuvo įrašytas nė vienas simbolis
	JMP	RasykBufPabaiga
RasykBuf ENDP

END pradzia