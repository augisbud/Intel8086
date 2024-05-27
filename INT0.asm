.model small

.stack 100h

.data
    purpose      db 'Augustas Budnikas PS 1 kursas 1 grupe.',0Dh, 0Ah,'Programa apdoroja dalybos is nulio pertraukimo procedura.$'
    int0_text1   db 0Dh,0Ah,'Dalyba is nulio! $'
    int0_text2   db '  DIV $'
    int0_segment dw 0
    int0_address dw 0
    int0_opcode  db 0
    int0_extra   db 0
    int0_offsetl db 0
    int0_offseth db 0
    registers    db 'AL$CL$DL$BL$AH$CH$DH$BH$AX$CX$DX$BX$SP$BP$SI$DI$'
    reg_text     db ' AX = $ CX = $ DX = $ BX = $ SP = $ BP = $ SI = $ DI = $'
    reg_values   dw 8 dup(0)
    byteText     db 'byte ptr[$'
    wordText     db 'word ptr[$'
    zero         dw 500 dup(0)
    
.code
    start:
        MOV	    ax, @data
        MOV	    ds, ax	

        LEA     DX, purpose
        CALL    print

        MOV	    ax, 0
        MOV	    es, ax

        PUSH	es:[0]
        PUSH	es:[2]
        
        MOV	    word ptr es:[0], offset int0_handler
        MOV	    es:[2], cs
        
        LEA     BX, zero
        DIV     word ptr [BX + 10h]

        POP	    es:[2]
        POP	    es:[0]

        MOV	    ah, 4Ch
        MOV	    al, 0
        INT	    21h

    int0_handler PROC
        PUSH    ax
        PUSH    bx
        PUSH    dx
        PUSH    bp
        PUSH    es
        PUSH    ds
        
        MOV     [reg_values], AX
        MOV     [reg_values + 2], CX
        MOV     [reg_values + 4], DX
        MOV     [reg_values + 6], BX
        MOV     [reg_values + 8], SP
        MOV     [reg_values + 10], BP
        MOV     [reg_values + 12], SI
        MOV     [reg_values + 14], DI

        MOV     ax, @data
        MOV     ds, ax

        MOV ah, 9
        MOV dx, offset int0_text1
        INT 21h

        MOV     bp, sp
        ADD     bp, 12
        MOV     ES, [bp+2]

        MOV     AX, ES
        
        MOV     DL, AH
        CALL    print_hex_byte
        MOV     DL, AL
        CALL    print_hex_byte

        MOV     AH, 2
        MOV     DL, 03Ah
        INT     21h

        MOV     bx, [bp]
        
        MOV     DL, BH
        CALL    print_hex_byte
        MOV     DL, BL
        CALL    print_hex_byte
        MOV     AH, 2
        MOV     DL, 020h
        INT     21h 

        MOV     dl, [es:bx]
        MOV     int0_opcode, dl     ; Išsaugom OPK
        CALL    print_hex_byte
        INC     bx

        MOV     dl, [es:bx]
        MOV     int0_extra, dl      ; Išsaugom OPK papildinį
        CALL    print_hex_byte
        INC     bx

        cmp int0_extra, 0F0h
        jae work

        cmp int0_extra, 037h
        jbe work

        MOV     dl, [es:bx]
        MOV     int0_offsetl, dl     ; Išsaugom poslinkį (low byte)
        MOV     DL, int0_offsetl
        CALL    print_hex_byte
        INC     bx

        CMP     int0_extra, 0B0h
        JB      work

        MOV     dl, [es:bx]
        MOV     int0_offseth, dl
        INC     bx                  ; Išsaugom poslinkį (high byte)
        MOV     DL, int0_offseth
        CALL    print_hex_byte
        
    work:
        CALL    parse_mnemonics

        MOV     [bp], bx

        POP     ds
        POP     es
        POP     bp
        POP     dx
        POP     bx
        POP     ax
        IRET
    int0_handler ENDP

    parse_mnemonics PROC
        PUSH    DX
        LEA     DX, int0_text2
        CALL    print
        POP     DX

        CMP     int0_extra, 0F0h
        JAE     call_parse_register

        CMP     int0_extra, 0B0h
        JAE     call_parse_address

        CMP     int0_extra, 070h
        JAE     call_parse_address

        CMP     int0_extra, 030h
        JAE     call_parse_address

    call_parse_register:
        CALL    parse_register
        JMP     end_parse

    call_parse_address:
        CALL    parse_address
        JMP     end_parse

    end_parse:
        RET
    parse_mnemonics ENDP

    parse_address PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        LEA     DX, byteText
        CMP     int0_opcode, 0F6h
        JE      printWordOrByte
        JNE     isWord
    isWord:
        LEA     DX, wordText

    printWordOrByte:
        CALL    print

        MOV     AL, int0_extra
        MOV     BL, 10h
        DIV     BL
        MOV     AL, AH

        CMP     AL, 0h
        JE      case0
        CMP     AL, 1h
        JE      case1
        CMP     AL, 2h
        JE      case2
        CMP     AL, 3h
        JE      case3
        CMP     AL, 4h
        JE      case4
        CMP     AL, 5h
        JE      case5
        CMP     AL, 6h
        JE      case6
        CMP     AL, 7h
        JE      case7
    case0:
        MOV     AL, 33
        MOV     AH, 42
        CALL    print_multiple_registers
        JMP     continue_parsing
    case1:
        MOV     AL, 33
        MOV     AH, 45
        CALL    print_multiple_registers
        JMP     continue_parsing
    case2:
        MOV     AL, 39
        MOV     AH, 42
        CALL    print_multiple_registers
        JMP     continue_parsing
    case3:
        MOV     AL, 39
        MOV     AH, 45
        CALL    print_multiple_registers
        JMP     continue_parsing
    case4:
        MOV     AL, 100
        MOV     AH, 42
        CALL    print_multiple_registers
        JMP     continue_parsing
    case5:
        MOV     AL, 100
        MOV     AH, 45
        CALL    print_multiple_registers
        JMP     continue_parsing
    case6:
        ; isspausdint tik poslinki
        MOV     AL, 39
        MOV     AH, 100
        CALL    print_multiple_registers
        JMP     continue_parsing
    case7:
        MOV     AL, 100
        MOV     AH, 33
        CALL    print_multiple_registers
        JMP     continue_parsing

    continue_parsing:
        MOV     BL, int0_opcode
        SUB     BL, 0F6h

        CMP     BL, 0
        JE      print_ax_value_isBytePtr
    print_dx_value_isWordPtr:
        MOV     AL, 2
        CALL    print_reg_value

        MOV     AH, 2
        MOV     DL, 02ch
        INT     21h
    print_ax_value_isBytePtr:
        MOV     AL, 0
        CALL    print_reg_value

        MOV     AH, 2
        MOV     DL, 02ch
        INT     21h

    ; BX = 3; BP = 5; SI = 6; DI = 7
    print_leftover_participants:
        MOV     AL, int0_extra
        MOV     BL, 10h
        DIV     BL
        MOV     AL, AH

        CMP     AL, 0h
        JE      leftover_case0
        CMP     AL, 1h
        JE      leftover_case1
        CMP     AL, 2h
        JE      leftover_case2
        CMP     AL, 3h
        JE      leftover_case3
        CMP     AL, 4h
        JE      leftover_case4
        CMP     AL, 5h
        JE      leftover_case5
        CMP     AL, 6h
        JE      leftover_case6
        CMP     AL, 7h
        JE      leftover_case7

    leftover_case0:
        MOV     AL, 3
        CALL    print_reg_value
        MOV     AL, 6
        CALL    print_reg_value
        JMP     end_this_stuff
    leftover_case1:
        MOV     AL, 3
        CALL    print_reg_value
        MOV     AL, 7
        CALL    print_reg_value
        JMP     end_this_stuff
    leftover_case2:
        MOV     AL, 5
        CALL    print_reg_value
        MOV     AL, 6
        CALL    print_reg_value
        JMP     end_this_stuff
    leftover_case3:
        MOV     AL, 5
        CALL    print_reg_value
        MOV     AL, 7
        CALL    print_reg_value
        JMP     end_this_stuff
    leftover_case4:
        MOV     AL, 6
        CALL    print_reg_value
        JMP     end_this_stuff
    leftover_case5:
        MOV     AL, 7
        CALL    print_reg_value
        JMP     end_this_stuff
    leftover_case6:
        CMP     int0_extra, 036h
        JE      end_this_stuff

        MOV     AL, 5
        CALL    print_reg_value
        JMP     end_this_stuff
    leftover_case7:
        MOV     AL, 3
        CALL    print_reg_value
        JMP     end_this_stuff

    end_this_stuff:
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
    parse_address ENDP

    parse_register PROC 
        PUSH    AX
        PUSH    BX
        PUSH    DX

        XOR     AX, AX
        MOV     AL, int0_extra
        SUB     AL, 0F0h

        MOV     BL, 3h
        MUL     BL

        CMP     int0_opcode, 0F6h
        JE      output_command

        ADD     AL, 018h

    output_command:
        LEA     DX, registers
        ADD     DX, AX
        CALL    print

        MOV     AH, 2
        MOV     DL, 03Bh
        INT     21h

    output_registers:
        MOV     BL, int0_opcode
        SUB     BL, 0F6h

        CMP     BL, 0
        JE      print_ax_value
    print_dx_value:
        MOV     AL, 2
        CALL    print_reg_value

        MOV     AH, 2
        MOV     DL, 02ch
        INT     21h
    print_ax_value:
        MOV     AL, 0
        CALL    print_reg_value

        MOV     AH, 2
        MOV     DL, 02ch
        INT     21h

        MOV     AL, int0_extra
        SUB     AL, 0F0h
        
        CMP     BL, 0
        JNE     print_leftover
        CMP     AL, 3
        JBE     print_leftover
    reduce:
        SUB     AL, 4
    print_leftover:
        CMP     AL, 0
        JE      end_register_parse
        CMP     AL, 2
        JE      end_register_parse
        CALL    print_reg_value

    end_register_parse:
        POP     DX
        POP     BX
        POP     AX
        RET
    parse_register ENDP

    print_reg_value PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSH DI

        MOV     CL, AL

        MOV     BL, 7
        MOV     AL, CL
        MUL     BL

        LEA     DX, reg_text
        ADD     DX, AX
        CALL    print

        MOV     BL, 2
        MOV     AL, CL
        MUL     BL

        LEA     SI, reg_values
        ADD     SI, AX
        MOV     BX, [SI]
        
        MOV     DL, BH
        CALL    print_hex_byte
        MOV     DL, BL
        CALL    print_hex_byte

        POP DI
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    print_reg_value ENDP

    print PROC 
        PUSH    AX
        XOR     AX, AX
        MOV     AH, 09h
        INT     21h
        POP     AX

        RET
    print ENDP

    print_hex_byte PROC
        PUSH AX
        PUSH CX

        MOV CH, DL

        AND DL, 0F0h
        SHR DL, 4
        CALL print_hex_digit

        MOV DL, CH
        AND DL, 0Fh
        CALL print_hex_digit

        MOV DL, AH

        POP CX
        POP AX
        RET
    print_hex_byte ENDP

    print_hex_digit PROC
        ADD DL, 30h
        CMP DL, 39h
        JA adjust_hex
        JMP print_digit

    adjust_hex:
        ADD DL, 7

    print_digit:
        MOV AH, 02h
        INT 21h
        RET
    print_hex_digit ENDP

    print_multiple_registers PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX

        INT 3

        MOV     CX, AX
        CMP     int0_extra, 036h
        JE      print_direct_address
        CMP     CL, 100
        JE      print_only_last

        LEA     DX, registers
        ADD     DL, CL
        CALL    print
        MOV     AH, 2
        MOV     DL, 02Bh
        INT     21h
    print_only_last:
        LEA     DX, registers
        ADD     DL, CH
        CALL    print

        CMP int0_extra, 070h
        JB     end_multi_print
        
    print_offset_third:
        CALL    print_offset
        JMP     end_multi_print

    print_direct_address:
        CALL    print_offset

    end_multi_print:
        MOV     AH, 2
        MOV     DL, 05dh
        INT     21h

        POP DX
        POP CX
        POP BX
        POP AX
        RET
    print_multiple_registers ENDP

    print_offset PROC
        MOV     AH, 2
        MOV     DL, 02Bh
        INT     21h

        CMP     int0_extra, 036h
        JE      print_high_offset_byte

        CMP     int0_extra, 0B0h
        JAE     print_high_offset_byte

        JMP     print_low_offset_byte

    print_high_offset_byte:
        MOV     DL, int0_offseth
        CALL    print_hex_byte
    print_low_offset_byte:
        MOV     DL, int0_offsetl
        CALL    print_hex_byte

        MOV     AH, 2
        MOV     DL, 068h
        INT     21h

        RET
    print_offset ENDP
END start
