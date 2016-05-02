section .data
DEFAULT REL

section .rodata
align 32
vectorFactores:        dd 0.2, 0.3, 0.5, 0.0, 0.2, 0.3, 0.5, 0.0 
; mxcsr settings, round to zero
; DEFAULT_VALUE | RZ_MASK = 0x1F80H | 0x7000
MXCSR_RZ: dd 0x7F80

section .text

global sepia_avx2

;void sepia_c    (
    ; rdi | unsigned char *src,
    ; rsi | unsigned char *dst,
    ; edx | int filas,
    ; ecx | int cols,
    ; r8d | int src_row_size,
    ; r9d | int dst_row_size,
;)

sepia_avx2:
    push rbp
    mov rbp, rsp

    ; Save the MXCSR register
    sub rsp, 8
    stmxcsr [rsp]

    ; Set SSE rounding to zero
    ldmxcsr [MXCSR_RZ]

    imul ecx, edx                                ; ecx == #filas * #columnas

    vmovdqa ymm15, [vectorFactores]

    .cicloTriple:
            ; Traigo el cacho de memoria a xmm0

;| A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 |...
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | ymm0
            vmovdqu ymm0, [rdi]

            vmovdqu ymm5, [rdi + 32]

            vmovdqu ymm10, [rdi + 64]

;|  0 | R7 | G7 | B7 |  0 | R6 | G6 | B6 |  0 | R5 | G5 | B5 |  0 | R4 | G4 | B4 |...
;|  0 | R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 | ymm1

            vpslld ymm1, ymm0, 8
            vpsrld ymm1, ymm1, 8

            vpslld ymm6, ymm5, 8
            vpsrld ymm6, ymm6, 8

            vpslld ymm11, ymm10, 8
            vpsrld ymm11, ymm11, 8

            ; Desempaqueto para que los datos pasen de byte a word
;|    0    |    R7   |    G7   |   B7    |     0   |    R6   |    G6   |   B6    |...
;|    0    |    R3   |    G3   |   B3    |     0   |    R2   |    G2   |   B2    | xmm3
        ; &
;|    0    |    R5   |    G5   |   B5    |     0   |    R4   |    G4   |   B4    |...
;|    0    |    R1   |    G1   |   B1    |     0   |    R0   |    G0   |   B0    | xmm1

            vpxor ymm7, ymm7                                             ;Registro momentaneo de ceros

            vpunpckhbw ymm3, ymm1, ymm7
            vpunpcklbw ymm1, ymm1, ymm7

            vpunpckhbw ymm8, ymm6, ymm7
            vpunpcklbw ymm6, ymm6, ymm7

            vpunpckhbw ymm13, ymm11, ymm7
            vpunpcklbw ymm11, ymm11, ymm7

            ; Hago las dos sumas horizontales
;|    R7   | B7 + G7 |    R6   | B6 + G6 |    R5   | B5 + G5 |    R4   | B4 + G4 |...
;|    R3   | B3 + G3 |    R2   | B2 + G2 |    R1   | B1 + G1 |    R0   | B0 + G0 | xmm1
            vphaddw ymm1, ymm3, ymm1

            vphaddw ymm6, ymm8, ymm6

            vphaddw ymm11, ymm13, ymm11

;|    0    |    0    |    0    |    0    |    S7   |    S6   |    S5   |    S4   |...
;|    0    |    0    |    0    |    0    |    S3   |    S2   |    S1   |    S0   | xmm1
            vphaddw ymm1, ymm1, ymm7

            vphaddw ymm6, ymm6, ymm7

            vphaddw ymm11, ymm11, ymm7

;|         S7        |         S6        |         S5        |         S4        |...
;|         S3        |         S2        |         S1        |         S0        | xmm1
            vpunpcklwd ymm1, ymm1, ymm7

            vpunpcklwd ymm6, ymm6, ymm7

            vpunpcklwd ymm11, ymm11, ymm7


            ; Convierto cada uno a float

            vcvtdq2ps ymm1, ymm1

            vcvtdq2ps ymm6, ymm6

            vcvtdq2ps ymm11, ymm11

            ; Muevo cada usa a un registro separado
;|         S7        |         S7        |         S7        |         S7        |...
;|         S3        |         S3        |         S3        |         S3        | xmm4
            ; &
;|         S6        |         S6        |         S6        |         S6        |...
;|         S2        |         S2        |         S2        |         S2        | xmm3
            ; &
;|         S5        |         S5        |         S5        |         S5        |...
;|         S1        |         S1        |         S1        |         S1        | xmm2
            ; &
;|         S4        |         S4        |         S4        |         S4        |...
;|         S0        |         S0        |         S0        |         S0        | xmm1
            vpshufd ymm4, ymm1, 0b11111111
            vpshufd ymm3, ymm1, 0b10101010
            vpshufd ymm2, ymm1, 0b01010101
            vpshufd ymm1, ymm1, 0b00000000

            vpshufd ymm9, ymm6, 0b11111111
            vpshufd ymm8, ymm6, 0b10101010
            vpshufd ymm7, ymm6, 0b01010101
            vpshufd ymm6, ymm6, 0b00000000

            vpshufd ymm14, ymm11, 0b11111111
            vpshufd ymm13, ymm11, 0b10101010
            vpshufd ymm12, ymm11, 0b01010101
            vpshufd ymm11, ymm11, 0b00000000

            ; Ejecuto una multiplicación empaquetada para conseguir las componentes adecuadas correspondientes a aplicar el filtro

;|         0         |      S7 * 0.5     |      S7 * 0.3     |      S7 * 0.2     |...
;|         0         |      S3 * 0.5     |      S3 * 0.3     |      S3 * 0.2     | xmm4
            ; &
;|         0         |      S6 * 0.5     |      S6 * 0.3     |      S6 * 0.2     |...
;|         0         |      S2 * 0.5     |      S2 * 0.3     |      S2 * 0.2     | xmm3
            ; &
;|         0         |      S5 * 0.5     |      S5 * 0.3     |      S5 * 0.2     |...
;|         0         |      S1 * 0.5     |      S1 * 0.3     |      S1 * 0.2     | xmm2
            ; &
;|         0         |      S4 * 0.5     |      S4 * 0.3     |      S4 * 0.2     |...
;|         0         |      S0 * 0.5     |      S0 * 0.3     |      S0 * 0.2     | xmm1
            vmulps ymm1, ymm1, ymm15
            vmulps ymm2, ymm2, ymm15
            vmulps ymm3, ymm3, ymm15
            vmulps ymm4, ymm4, ymm15

            vmulps ymm6, ymm6, ymm15
            vmulps ymm7, ymm7, ymm15
            vmulps ymm8, ymm8, ymm15
            vmulps ymm9, ymm9, ymm15

            vmulps ymm11, ymm11, ymm15
            vmulps ymm12, ymm12, ymm15
            vmulps ymm13, ymm13, ymm15
            vmulps ymm14, ymm14, ymm15

            ; Reconvierto a int
            vcvttps2dq ymm1, ymm1
            vcvttps2dq ymm2, ymm2
            vcvttps2dq ymm3, ymm3
            vcvttps2dq ymm4, ymm4

            vcvttps2dq ymm6, ymm6
            vcvttps2dq ymm7, ymm7
            vcvttps2dq ymm8, ymm8
            vcvttps2dq ymm9, ymm9

            vcvttps2dq ymm11, ymm11
            vcvttps2dq ymm12, ymm12
            vcvttps2dq ymm13, ymm13
            vcvttps2dq ymm14, ymm14

            ; Empaqueto los datos saturando con 255 en el caso de la componente roja
;|    0    |   Ir7   |   Ig7   |  Ib7    |    0    |   Ir6   |   Ig6   |  Ib6    |...
;|    0    |   Ir3   |   Ig3   |  Ib3    |    0    |   Ir2   |   Ig2   |  Ib2    | xmm3
        ; &
;|    0    |   Ir5   |   Ig5   |  Ib5    |    0    |   Ir4   |   Ig4   |  Ib4    |...
;|    0    |   Ir1   |   Ig1   |  Ib1    |    0    |   Ir0   |   Ig0   |  Ib0    | xmm1
            vpackusdw ymm1, ymm2
            vpackusdw ymm3, ymm4

            vpackusdw ymm6, ymm7
            vpackusdw ymm8, ymm9

            vpackusdw ymm11, ymm12
            vpackusdw ymm13, ymm14

;|  0 |Ir7 |Ig7 |Ib7 |  0 |Ir6 |Ig6 |Ib6 |  0 |Ir5 |Ig5 |Ib5 |  0 |Ir4 |Ig4 |Ib4 |...
;|  0 |Ir3 |Ig3 |Ib3 |  0 |Ir2 |Ig2 |Ib2 |  0 |Ir1 |Ig1 |Ib1 |  0 |Ir0 |Ig0 |Ib0 | ymm1
            vpackuswb ymm1, ymm3, ymm1

            vpackuswb ymm6, ymm8, ymm6

            vpackuswb ymm11, ymm13, ymm11

            ; Fusiono con ymm0
;| A7 |  0 |  0 |  0 | A6 |  0 |  0 |  0 | A5 |  0 |  0 |  0 | A4 |  0 |  0 |  0 |...
;| A3 |  0 |  0 |  0 | A2 |  0 |  0 |  0 | A1 |  0 |  0 |  0 | A0 |  0 |  0 |  0 | ymm0

            vpsrld ymm0, ymm0, 24
            vpslld ymm0, ymm0, 24

            vpsrld ymm5, ymm5, 24
            vpslld ymm5, ymm5, 24

            vpsrld ymm10, ymm10, 24
            vpslld ymm10, ymm10, 24

;| A7 |Ir7 |Ig7 |Ib7 | A6 |Ir6 |Ig6 |Ib6 | A5 |Ir5 |Ig5 |Ib5 | A4 |Ir4 |Ig4 |Ib4 |...
;| A3 |Ir3 |Ig3 |Ib3 | A2 |Ir2 |Ig2 |Ib2 | A1 |Ir1 |Ig1 |Ib1 | A0 |Ir0 |Ig0 |Ib0 | ymm1
            vpxor ymm0, ymm1

            vpxor ymm5, ymm6

            vpxor ymm10, ymm11

            ; Acomodo de vuelta en memoria

            vmovdqu [rsi], ymm0
            vmovdqu [rsi + 32], ymm5
            vmovdqu [rsi + 64], ymm10

            ; Avanzo en el loop y chequeo si tengo que terminar

            add rdi, 96
            add rsi, 96
            sub ecx, 24
            cmp ecx, 24
            jge .cicloTriple

;-------------------------------------------------------------------------------------------------------------------------
    

    .cicloSimple:
            ; Traigo el cacho de memoria a xmm0

;| A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 |...
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | ymm0
            vmovdqu ymm0, [rdi]

;|  0 | R7 | G7 | B7 |  0 | R6 | G6 | B6 |  0 | R5 | G5 | B5 |  0 | R4 | G4 | B4 |...
;|  0 | R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 | ymm1

            ;vpand ymm1, ymm0, [mskQuitarAlpha]

            vpslld ymm1, ymm0, 8
            vpsrld ymm1, ymm1, 8

            ; Desempaqueto para que los datos pasen de byte a word
;|    0    |    R7   |    G7   |   B7    |     0   |    R6   |    G6   |   B6    |...
;|    0    |    R3   |    G3   |   B3    |     0   |    R2   |    G2   |   B2    | xmm3
        ; &
;|    0    |    R5   |    G5   |   B5    |     0   |    R4   |    G4   |   B4    |...
;|    0    |    R1   |    G1   |   B1    |     0   |    R0   |    G0   |   B0    | xmm1

            vpxor ymm7, ymm7                                             ;Registro momentaneo de ceros

            vpunpckhbw ymm3, ymm1, ymm7
            vpunpcklbw ymm1, ymm1, ymm7

            ; Hago las dos sumas horizontales
;|    R7   | B7 + G7 |    R6   | B6 + G6 |    R5   | B5 + G5 |    R4   | B4 + G4 |...
;|    R3   | B3 + G3 |    R2   | B2 + G2 |    R1   | B1 + G1 |    R0   | B0 + G0 | xmm1
            vphaddw ymm1, ymm3, ymm1

;|    0    |    0    |    0    |    0    |    S7   |    S6   |    S5   |    S4   |...
;|    0    |    0    |    0    |    0    |    S3   |    S2   |    S1   |    S0   | xmm1
            vphaddw ymm1, ymm1, ymm7

;|         S7        |         S6        |         S5        |         S4        |...
;|         S3        |         S2        |         S1        |         S0        | xmm1
            vpunpcklwd ymm1, ymm1, ymm7

            ; Convierto cada uno a float

            vcvtdq2ps ymm1, ymm1

            ; Muevo cada usa a un registro separado
;|         S7        |         S7        |         S7        |         S7        |...
;|         S3        |         S3        |         S3        |         S3        | xmm4
            ; &
;|         S6        |         S6        |         S6        |         S6        |...
;|         S2        |         S2        |         S2        |         S2        | xmm3
            ; &
;|         S5        |         S5        |         S5        |         S5        |...
;|         S1        |         S1        |         S1        |         S1        | xmm2
            ; &
;|         S4        |         S4        |         S4        |         S4        |...
;|         S0        |         S0        |         S0        |         S0        | xmm1
            vpshufd ymm4, ymm1, 0b11111111
            vpshufd ymm3, ymm1, 0b10101010
            vpshufd ymm2, ymm1, 0b01010101
            vpshufd ymm1, ymm1, 0b00000000

            ; Ejecuto una multiplicación empaquetada para conseguir las componentes adecuadas correspondientes a aplicar el filtro

;|         0         |      S7 * 0.5     |      S7 * 0.3     |      S7 * 0.2     |...
;|         0         |      S3 * 0.5     |      S3 * 0.3     |      S3 * 0.2     | xmm4
            ; &
;|         0         |      S6 * 0.5     |      S6 * 0.3     |      S6 * 0.2     |...
;|         0         |      S2 * 0.5     |      S2 * 0.3     |      S2 * 0.2     | xmm3
            ; &
;|         0         |      S5 * 0.5     |      S5 * 0.3     |      S5 * 0.2     |...
;|         0         |      S1 * 0.5     |      S1 * 0.3     |      S1 * 0.2     | xmm2
            ; &
;|         0         |      S4 * 0.5     |      S4 * 0.3     |      S4 * 0.2     |...
;|         0         |      S0 * 0.5     |      S0 * 0.3     |      S0 * 0.2     | xmm1
            vmulps ymm1, ymm1, ymm15
            vmulps ymm2, ymm2, ymm15
            vmulps ymm3, ymm3, ymm15
            vmulps ymm4, ymm4, ymm15

            ; Reconvierto a int
            vcvttps2dq ymm1, ymm1
            vcvttps2dq ymm2, ymm2
            vcvttps2dq ymm3, ymm3
            vcvttps2dq ymm4, ymm4

            ; Empaqueto los datos saturando con 255 en el caso de la componente roja
;|    0    |   Ir7   |   Ig7   |  Ib7    |    0    |   Ir6   |   Ig6   |  Ib6    |...
;|    0    |   Ir3   |   Ig3   |  Ib3    |    0    |   Ir2   |   Ig2   |  Ib2    | xmm3
        ; &
;|    0    |   Ir5   |   Ig5   |  Ib5    |    0    |   Ir4   |   Ig4   |  Ib4    |...
;|    0    |   Ir1   |   Ig1   |  Ib1    |    0    |   Ir0   |   Ig0   |  Ib0    | xmm1
            vpackusdw ymm1, ymm2
            vpackusdw ymm3, ymm4

;|  0 |Ir7 |Ig7 |Ib7 |  0 |Ir6 |Ig6 |Ib6 |  0 |Ir5 |Ig5 |Ib5 |  0 |Ir4 |Ig4 |Ib4 |...
;|  0 |Ir3 |Ig3 |Ib3 |  0 |Ir2 |Ig2 |Ib2 |  0 |Ir1 |Ig1 |Ib1 |  0 |Ir0 |Ig0 |Ib0 | ymm1
            vpackuswb ymm1, ymm3, ymm1

            ; Fusiono con ymm0
;| A7 |  0 |  0 |  0 | A6 |  0 |  0 |  0 | A5 |  0 |  0 |  0 | A4 |  0 |  0 |  0 |...
;| A3 |  0 |  0 |  0 | A2 |  0 |  0 |  0 | A1 |  0 |  0 |  0 | A0 |  0 |  0 |  0 | ymm0

            vpsrld ymm0, ymm0, 24
            vpslld ymm0, ymm0, 24

;| A7 |Ir7 |Ig7 |Ib7 | A6 |Ir6 |Ig6 |Ib6 | A5 |Ir5 |Ig5 |Ib5 | A4 |Ir4 |Ig4 |Ib4 |...
;| A3 |Ir3 |Ig3 |Ib3 | A2 |Ir2 |Ig2 |Ib2 | A1 |Ir1 |Ig1 |Ib1 | A0 |Ir0 |Ig0 |Ib0 | ymm1
            vpxor ymm0, ymm1

            ; Acomodo de vuelta en memoria

            vmovdqu [rsi], ymm0

            ; Avanzo en el loop y chequeo si tengo que terminar

            add rdi, 32
            add rsi, 32
            sub ecx, 8
            cmp ecx, 8
            jge .cicloSimple


    ;Finishing

    .fin:

        ; Restore the MXCSR register
        ldmxcsr [rsp]
        add rsp, 8

        pop rbp
        ret
