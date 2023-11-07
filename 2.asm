.model small

skBufDydis	EQU 10
raBufDydis	EQU 10

.stack 100h

.data
	helpMessage db 'Programa visus faile rastus skaitmenis pakeicia zodziais. Programos paleidimas: prog.exe duomenu_failas rezultatu_failas$'
	numStrs 	db 'nulis$', 'vienas$', 'du$', 'trys$', 'keturi$', 'penki$', 'sesi$', 'septyni$', 'astuoni$', 'devyni$'
	numOffset 	db 0, 6, 13, 16, 21, 28, 34, 39, 47, 55
	inputFile  	db 255 dup(0)
    outputFile 	db 255 dup(0)
	skBuf		db skBufDydis dup (0)
	raBuf		db raBufDydis dup (0)
	dFail		dw ?			
	rFail		dw ?
	nuskaityta	dw 0
	
.code
  help:
	MOV	ah, 9
	MOV	dx, offset helpMessage
	INT	21h
	
	jmp pabaiga
  klaidaAtidarantSkaitymui:
	JMP	pabaiga
  klaidaAtidarantRasymui:
	JMP	uzdarytiSkaitymui
	
  pradzia:
	MOV	ax, @data	
	MOV	ds, ax
	
	MOV	ch, 0			
	MOV	cl, [es:0080h]
	CMP	cx, 0
	JE help
	
	MOV	bx, 0081h
	
  search_for_help:
	CMP	[es:bx], '?/'	
	JE	help
	INC	bx
	LOOP search_for_help
	
	MOV	cl, [es:0080h]
	CMP	cx, 4
	JBE help
	
	mov bx, 82h
	mov si, offset inputFile
	mov di, offset outputFile
	
  parse_input_file:
	mov ax, es:[bx]
	inc bx
	
	cmp al, 20h
	je parse_output_file
	
	mov byte ptr[si], al
	inc si
	jmp parse_input_file
	
  parse_output_file:
	mov ax, es:[bx]
	inc bx
	cmp al, 13
	je dirbam
	
	mov byte ptr[di], al
	inc di
	jmp parse_output_file
	
  dirbam:
	MOV byte ptr [si], 0
	MOV byte ptr [di], 0

	MOV	ah, 3Dh
	MOV	al, 00
	MOV	dx, offset inputFile
	INT	21h
	JC	klaidaAtidarantSkaitymui
	MOV	dFail, ax

	MOV	ah, 3Ch
	MOV	cx, 0
	MOV	dx, offset outputFile
	INT	21h
	JC	klaidaAtidarantRasymui
	MOV	rFail, ax

	MOV di, offset raBuf
	MOV dx, 0
  skaityk:
	MOV	bx, dFail
	CALL	SkaitykBuf
	CMP	ax, 0
	JE	uzdarytiRasymui
	mov nuskaityta, ax
	MOV cx, ax
	
	MOV	si, offset skBuf
  dirbk:
	cmp cx, 0
	JE baigesiKaSkaitem
	
	DEC CX ; pazymim, kad viena nuskaitem
 
    MOV	bl, [si]
    int 3
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
	CALL RasykBuf
	
	mov ax, [bx]
	
	cmp al, '$'
	JE baigesiZodis
	
	mov ax, [bx]
	mov [di], al
	
	INC BX ; pakeliam adresa
	INC DX ; pakeliam, kad irasem
	INC DI ; pastumiam per viena vieta outputo buferi
	
	jmp rasykZodi
	
  baigesiZodis:
	inc si
	jmp dirbk

  tesk:
	CALL RasykBuf
	mov [di], bl
	INC dx
	INC di
	INC si
	jmp dirbk

  baigesiKaSkaitem:
	CMP	nuskaityta, skBufDydis
	JE	skaityk
	

  uzdarytiRasymui:
	mov si, 128
	CALL RasykBuf
	
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
    cmp si, 128
	JE Rasyk
	
	cmp dx, raBufDydis
	JB nepilnasBuf
	
  Rasyk:
	PUSH BX
	PUSH CX
	MOV BX, rFail
	MOV CX, DX
	
	PUSH 	AX
	PUSH	DX
	
	MOV	ah, 40h
	MOV	dx, offset raBuf
	INT	21h
	JC	klaidaRasant

  RasykBufPabaiga:
	POP 	AX
	POP		DX
	
	POP		CX
	POP		BX
	MOV		DX, 0
	MOV 	DI, offset raBuf
	RET

  klaidaRasant:
	MOV	ax, 0			;Pažymime registre ax, kad nebuvo irašytas ne vienas simbolis
	JMP	RasykBufPabaiga
	
  nepilnasBuf:
	RET
RasykBuf ENDP

Proc PrintHelp
	PUSH	AX
	PUSH 	DX
	
	MOV		ah, 9
	MOV		DX, offset helpMessage
	INT		21h
	RET
PrintHelp ENDP
END pradzia