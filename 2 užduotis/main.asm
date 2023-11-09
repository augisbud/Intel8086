; Augustas Budnikas Vilniaus Universitetas Programų Sistemos 1 kursas 1 grupė
; Kompiuterių Architektūra 2 užduotis 7 variantas
; Atsiskaitymo data: 2023-11-08

.MODEL SMALL

inputBufSize	EQU 10
outputBufSize	EQU 10

.STACK 100h

.DATA
	numStrings 	DB 'nulis$', 'vienas$', 'du$', 'trys$', 'keturi$', 'penki$', 'sesi$', 'septyni$', 'astuoni$', 'devyni$'
	numOffsets 	DB 0, 6, 13, 16, 21, 28, 34, 39, 47, 55
	readBytes	DW 0
	inputFile  	DB 255 			 DUP(0)
    outputFile 	DB 255 			 DUP(0)
	inputBuf	DB inputBufSize  DUP(0)
	outputBuf	DB outputBufSize DUP(0)
	readFile	DW ?			
	writeFile	DW ?
	helpMessage DB 'Programa visus faile rastus skaitmenis pakeicia zodziais. Programos paleidimas: prog.exe duomenu_failas rezultatu_failas$'
	opReadErMs	DB 10,'Klaida atidarant duomenu faila.$'
	opWriteErMs	DB 10,'Klaida atidarant rezultatu faila.$'
	clReadErMs	DB 'Klaida uzdarant duomenu faila.$'
	clWriteErMs	DB 'Klaida uzdarant rezultatu faila.$'
	wrFormatMs	DB 10,'Klaidingas parametru ivedimas.$'
	
.CODE
  help:
	MOV		DX, offset helpMessage
	CALL	PrintMessage
	JMP		finish
  errorOpeningReadFile:
	MOV		DX, offset helpMessage
	CALL	PrintMessage
	MOV		DX, offset opReadErMs
	CALL	PrintMessage
	JMP		finish
  errorOpeningWriteFile:
  	MOV		DX, offset helpMessage
	CALL	PrintMessage
	MOV		DX, offset opWriteErMs
	CALL	PrintMessage
	JMP		closeReadFile
  wrongFormat:
	MOV		DX, offset helpMessage
	CALL 	PrintMessage
	MOV		DX, offset wrFormatMs
	CALL 	PrintMessage
	JMP		finish
  start:
	MOV		AX, @DATA	
	MOV		DS, AX
			
	MOV		CL, [ES:0080h]
	CMP		CL, 4
	JBE 	help
	
	MOV 	BX, 82h
	MOV 	SI, offset inputFile
	MOV 	DI, offset outputFile
	
  parseInputFileName:
	MOV 	AL, ES:[BX] ;al
	INC 	BX
	
	CMP 	AL, 20h
	JE 		parseOutputFileName
	CMP		AL, 13
	JE		wrongFormat
	
	MOV 	byte ptr[SI], AL
	INC 	SI
	JMP 	parseInputFileName
	
  parseOutputFileName:
	MOV 	AL, ES:[BX]
	INC 	BX
	
	CMP		AL, 20h
	JE		parseOutputFileName
	
	CMP 	AL, 13
	JE 		startProcessing
	
	MOV 	byte ptr[DI], AL
	INC 	DI
	JMP 	parseOutputFileName
	
  startProcessing:
	MOV 	byte ptr [SI], 0
	MOV 	byte ptr [DI], 0

	MOV		ah, 3Dh
	MOV		al, 00
	MOV		DX, offset inputFile
	INT		21h
	JC		errorOpeningReadFile
	MOV		readFile, AX

	MOV		ah, 3Ch
	MOV		CX, 0
	MOV		DX, offset outputFile
	INT		21h
	JC		errorOpeningWriteFile
	MOV		writeFile, AX

	MOV 	DI, offset outputBuf
	MOV 	DX, 0
  readToBuffer:
	MOV		BX, readFile
	CALL	ReadBuffer
	CMP		AX, 0
	JE		endOfRead
	MOV 	readBytes, AX
	MOV 	CX, AX
	
	MOV		SI, offset inputBuf
  processCharacter:
	CMP 	CX, 0
	JE 		endOfCurrentReadBuffer
	
	DEC 	CX ; pazymim, kad viena nuskaitem
 
    MOV		bl, [SI]
    CMP		bl, '0'
    JB		writeCharacter
    CMP		bl, '9'
    JA		writeCharacter
	
    SUB		bl, '0'
	ADD 	bl, offset numOffsets
	
	MOV 	AX, [BX]
	MOV 	ah, 0
	MOV 	BX, AX
	
	ADD 	BX, offset numStrings
	
  writeWord:
	CALL 	WriteBuffer
	
	MOV 	AX, [BX]
	
	CMP 	al, '$'
	JE 		endOfWord
	
	MOV 	AX, [BX]
	MOV 	[DI], al
	
	INC 	BX 
	INC 	DX 
	INC 	DI 
	
	JMP 	writeWord
	
  endOfWord:
	INC 	SI
	JMP 	processCharacter

  writeCharacter:
	CALL 	WriteBuffer
	MOV 	[DI], bl
	INC 	DX
	INC 	DI
	INC 	SI
	JMP 	processCharacter

  endOfCurrentReadBuffer:
	CMP		readBytes, inputBufSize
	JE		readToBuffer
	
  endOfRead:
	MOV 	SI, 128
	CALL 	WriteBuffer
	
  closeReadFile:
	MOV		ah, 3Eh
	MOV		BX, writeFile
	INT		21h
	JC		errorOnClosingWriteFile
	
  closeOpenFile:
	MOV		ah, 3Eh
	MOV		BX, readFile
	INT		21h
	JC		errorOnClosingReadFile

  finish:
	MOV 	ah, 4Ch
	INT 	21h

  errorOnClosingWriteFile:
	MOV		DX, offset clWriteErMs
	CALL	PrintMessage
	JMP		closeReadFile
  errorOnClosingReadFile:
	MOV		DX, offset clReadErMs
	CALL	PrintMessage
	JMP		finish

PROC ReadBuffer
	PUSH	CX
	PUSH	DX
	
	MOV		ah, 3Fh
	MOV		CX, inputBufSize
	MOV		DX, offset inputBuf
	INT		21h
	JC		readError

  endOfReadBuffer:
	POP		DX
	POP		CX
	RET

  readError:
	MOV 	AX, 0
	JMP		endOfReadBuffer
ReadBuffer ENDP

PROC WriteBuffer
    CMP 	SI, 128
	JE 		Rasyk
	
	CMP 	DX, outputBufSize
	JB 		bufferNotFilled
	
  Rasyk:
	PUSH 	BX
	PUSH 	CX
	MOV 	BX, writeFile
	MOV 	CX, DX
	
	PUSH 	AX
	PUSH	DX
	
	MOV		ah, 40h
	MOV		DX, offset outputBuf
	INT		21h
	JC		writeError

  endOfWriteBufferPabaiga:
	POP 	AX
	POP		DX
	
	POP		CX
	POP		BX
	MOV		DX, 0
	MOV 	DI, offset outputBuf
	RET

  writeError:
	MOV		AX, 0
	JMP		endOfWriteBufferPabaiga
	
  bufferNotFilled:
	RET
WriteBuffer ENDP

Proc PrintMessage
	MOV		ah, 9
	INT		21h
	RET
PrintMessage ENDP

END start
