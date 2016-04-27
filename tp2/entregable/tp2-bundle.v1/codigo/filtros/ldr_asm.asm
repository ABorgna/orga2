
extern copyN
extern copyN_sse
extern copyN_avx2

global ldr_asm
global ldr_sse
global ldr_sse_integer

section .data

align 8
; 1/max = 1/(5*5*255*3*255) = 1/4876875 ~= 2.050493399974369e-7
LDR_MAX_INV: dd 2.050493399974369e-7, 2.050493399974369e-7
; Floating point max
PIXEL_MAX_F: dd 255.0, 255.0
; Integer max
PIXEL_MAX: dd 255, 255
; x / max = x * MAGIC >> 53
LDR_MAX_MAGIC: dd 0x6e15c447, 0x6e15c447

section .text
;void ldr_asm    (
    ; rdi | unsigned char *src,
    ; rsi | unsigned char *dst,
    ; edx | int cols,
    ; ecx | int filas,
    ; r8d | int src_row_size,
    ; r9d | int dst_row_size,
    ; bp+16 | int alpha
;)
ldr_asm:
    jmp ldr_sse

ldr_sse_integer:
    ; Requires SSE4.1
    push rbp
    mov rbp, rsp
    push rbx
    push r15 ; Stack aligned
    push r14
    push r13
    push r12

    ; line offsets
    ; r12: -2
    ; r13: -1
    ; r14: +1
    ; r15: +2
    mov r13, r8
    mov r14, r8
    neg r13
    lea r12, [r13*2]
    lea r15, [r8*2]

    ; rax = cols
    ; rdx = filas
    ; r8 = src
    ; r9 = dst
    ; r10 = alpha
    ; rsi = current pixel src
    ; rdi = current pixel dst
    mov rax, rdx
    mov rdx, rcx
    mov r8, rdi
    mov r9, rsi
    movsx r10, word [rbp+16]
    mov rsi, r8
    mov rdi, r9

    ; Recorrer la imagen linealmente de a grupos de 4,
    ; manteniendo la suma de los pixeles vecinos en xmm0-4
    pxor xmm0, xmm0
    pxor xmm1, xmm1
    pxor xmm2, xmm2
    pxor xmm3, xmm3
    pxor xmm4, xmm4

    ; xmm15 is always zero
    pxor xmm15, xmm15

    ; mm0 = |   LDR_MAX_MAGIC   |   LDR_MAX_MAGIC   |
    ; mm1 = |        255        |        255        |
    ; mm2 = |  alpha  |  alpha  |  alpha  |  alpha  |
    movq mm0, [LDR_MAX_MAGIC]
    movq mm1, [PIXEL_MAX]
    pxor xmm6, xmm6
    pinsrw xmm6, r10w, 0
    pinsrw xmm6, r10w, 1
    pinsrw xmm6, r10w, 2
    pinsrw xmm6, r10w, 3
    movdq2q mm2, xmm6

    ; Empezamos a procesar desde fila2 - 2px
    lea rsi, [r8 + r15 - 8]
    lea rdi, [r9 + r15 - 8]

    ; Magic loop, correr sobre ((filas-4)*cols+4)/4
    lea rcx, [rdx-4]    ; rcx = filas-4
    imul rcx, rax       ; rcx = (filas-4)*cols
    add rcx, 4          ; rcx = (filas-4)*cols+4
    shr rcx, 2          ; rcx = ((filas-4)*cols+4)/4

    .magicLoop:

        ; xmm0 tiene la suma de las primeras cuatro columnas que necesitamos y lo demas en 0
; |    0    |    0    |    0    |    0    |sum_col3 |sum_col2 |sum_col1 |sum_col0 | xmm0

        ; load the new pixels
        ; ->
; | A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 | xmmN
        movdqu xmm5, [rsi+r12+8]
        movdqu xmm6, [rsi+r13+8]
        movdqu xmm7, [rsi+8]
        movdqu xmm8, [rsi+r14+8]
        movdqu xmm9, [rsi+r15+8]

        ; shift to clear the alpha bits
        ; ->
; | R7 | G7 | B7 |  0 | R6 | G6 | B6 |  0 | R5 | G5 | B5 |  0 | R4 | G4 | B4 |  0 | xmmN
        pslld xmm5, 8
        pslld xmm6, 8
        pslld xmm7, 8
        pslld xmm8, 8
        pslld xmm9, 8

        ; unpack bytes to words, xmmN -> xmm{N+5}:xmmN
        ; ->
; |    R7   |    G7   |    B7   |     0   |    R6   |    G6   |    B6   |     0   | xmm{N+5}
; |    R5   |    G5   |    B5   |     0   |    R4   |    G4   |    B4   |     0   | xmmN
        movdqa xmm10, xmm5
        movdqa xmm11, xmm6
        movdqa xmm12, xmm7
        movdqa xmm13, xmm8
        movdqa xmm14, xmm9
        punpcklbw xmm5, xmm15
        punpcklbw xmm6, xmm15
        punpcklbw xmm7, xmm15
        punpcklbw xmm8, xmm15
        punpcklbw xmm9, xmm15
        punpckhbw xmm10, xmm15
        punpckhbw xmm11, xmm15
        punpckhbw xmm12, xmm15
        punpckhbw xmm13, xmm15
        punpckhbw xmm14, xmm15

        ; Get the horizontal sum
        ; ->
; | R7 + G7 |    B7   | R6 + G6 |    B6   | R5 + G5 |    B5   | R4 + G4 |    B4   | xmmN
        phaddw xmm5, xmm10
        phaddw xmm6, xmm11
        phaddw xmm7, xmm12
        phaddw xmm8, xmm13
        phaddw xmm9, xmm14
        ; ->
;| R7+G7+B7| R6+G6+B6| R5+G5+B5| R4+G4+B4|    0    |    0    |    0    |    0     | xmm{N+5}
        ; ==
;|   sum7  |   sum6  |   sum5  |   sum4  |    0    |    0    |    0    |    0     | xmm{N+5}
        pxor xmm10, xmm10
        pxor xmm11, xmm11
        pxor xmm12, xmm12
        pxor xmm13, xmm13
        pxor xmm14, xmm14
        phaddw xmm10, xmm5
        phaddw xmm11, xmm6
        phaddw xmm12, xmm7
        phaddw xmm13, xmm8
        phaddw xmm14, xmm9

        ; Reducir todas las sumargb_i a una unica sumargb
        ; ->
;|sum_col7 |sum_col6 |sum_col5 |sum_col4 |    0    |    0    |    0    |    0     | xmm10
        paddw xmm13, xmm14
        paddw xmm10, xmm11
        paddw xmm12, xmm13
        paddw xmm10, xmm12

        ; Save the sums in xmm0
        ; ->
;|sum_col7 |sum_col6 |sum_col5 |sum_col4 |sum_col3 |sum_col2 |sum_col1 |sum_col0 | xmm0
        por xmm0, xmm10

        ; Calcular sumargb para cada uno de los 4 pixeles que vamos a procesar
        ; En el proceso vamos eliminando las sumas de pixeles viejos y dejamos xmm0
        ; listo para la siguiente vuelta
        ; ->
;|    X    |    X    |    X    |    X    |sumargb3 |sumargb2 |sumargb1 |sumargb0 | xmm5
;|    0    |    0    |    0    |    0    |sum_col7 |sum_col6 |sum_col5 |sum_col4 | xmm0
        movdqa xmm5, xmm0 ; Mover valor inicial, j-2
        psrldq xmm0, 2 ; Desechar valor viejo j-2
        paddw xmm5, xmm0 ; Sumar j-1
        psrldq xmm0, 2 ; Desechar valor viejo j-1
        paddw xmm5, xmm0 ; Sumar j
        psrldq xmm0, 2 ; Desechar valor viejo j
        paddw xmm5, xmm0 ; Sumar j+1
        psrldq xmm0, 2 ; Desechar valor viejo j+1
        paddw xmm5, xmm0 ; Sumar j+2

        ; Cargar alpha en xmm6 por cuadriplicado
        ; ->
;|    X    |    X    |    X    |    X    |  alpha  |  alpha  |  alpha  |  alpha  | xmm6
        movq2dq xmm6, mm2

        ; Expandir las sumas y multiplicarlas por alpha
        ; ->
;|    X    |    X    |    X    |    X    |L(sum3*a)|L(sum2*a)|L(sum1*a)|L(sum0*a)| xmm5
;|    X    |    X    |    X    |    X    |H(sum3*a)|H(sum2*a)|H(sum1*a)|H(sum0*a)| xmm7
        movdqa xmm7, xmm5
        pmullw xmm5, xmm6
        pmulhw xmm7, xmm6
        ; ->
;| sumargb3 * alpha  | sumargb2 * alpha  | sumargb1 * alpha  | sumargb0 * alpha  | xmm5
        punpcklwd xmm5, xmm7

        ; Movemos las sumas registros separados
        ; ->
;| sumargb3 * alpha  | sumargb3 * alpha  | sumargb3 * alpha  | sumargb3 * alpha  | xmm5
;| sumargb2 * alpha  | sumargb2 * alpha  | sumargb2 * alpha  | sumargb2 * alpha  | xmm6
;| sumargb1 * alpha  | sumargb1 * alpha  | sumargb1 * alpha  | sumargb1 * alpha  | xmm7
;| sumargb0 * alpha  | sumargb0 * alpha  | sumargb0 * alpha  | sumargb0 * alpha  | xmm8
        pshufd xmm8, xmm5, 0b00000000
        pshufd xmm7, xmm5, 0b01010101
        pshufd xmm6, xmm5, 0b10101010
        pshufd xmm5, xmm5, 0b11111111

        ; cargamos los valores de los pixeles
        ; y los unpackeamos a dw
        ; ->
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | xmm1
        movdqu xmm1, [rsi]
        ; ->
;|   A3    |    R3   |    G3   |   B3    |   A2    |    R2   |    G2   |   B2    | xmm1
;|   A1    |    R1   |    G1   |   B1    |   A0    |    R0   |    G0   |   B0    | xmm3
        movdqa xmm3, xmm1
        punpckhbw xmm1, xmm15
        punpcklbw xmm3, xmm15
        ; ->
;|        A3         |         R3        |         G3        |         B3        | xmm1
;|        A2         |         R2        |         G2        |         B2        | xmm2
;|        A1         |         R1        |         G1        |         B1        | xmm3
;|        A0         |         R0        |         G0        |         B0        | xmm4
        movdqa xmm2, xmm1
        movdqa xmm4, xmm3
        punpckhwd xmm1, xmm15
        punpcklwd xmm2, xmm15
        punpckhwd xmm3, xmm15
        punpcklwd xmm4, xmm15

        ; Cargar una mascara para borrar el canal alpha
        ; ->
;|         0         |    0xffffffff     |    0xffffffff     |    0xffffffff     | xmm13
        pxor xmm13, xmm13 ; remove dependencies
        pcmpeqq xmm13, xmm13
        psrldq xmm13, 4

        ; Multiplicamos cada valor de cada pixel por sumargb*alpha, borrando el canal alpha
        ; ->
;|         0         | R3*sumargb3*alpha | G3*sumargb3*alpha | B3*sumargb3*alpha | xmm5
;|         0         | R2*sumargb2*alpha | G2*sumargb2*alpha | B2*sumargb2*alpha | xmm6
;|         0         | R1*sumargb1*alpha | G1*sumargb1*alpha | B1*sumargb1*alpha | xmm7
;|         0         | R0*sumargb0*alpha | G0*sumargb0*alpha | B0*sumargb0*alpha | xmm8
        pmulld xmm5, xmm1
        pmulld xmm6, xmm2
        pmulld xmm7, xmm3
        pmulld xmm8, xmm4
        pand xmm5, xmm13
        pand xmm6, xmm13
        pand xmm7, xmm13
        pand xmm8, xmm13

        ; Cargar el magic number
        ; ->
;|       MAGIC       |       MAGIC       |       MAGIC       |       MAGIC       | xmm14
        movq2dq xmm14, mm0
        movddup xmm14, xmm14

        ; Cargar una mascara para borrar la parte baja de MAGIC * G
        ; ->
;|    0xffffffff     |    0xffffffff     |    0xffffffff     |         0         | xmm13
        pxor xmm13, xmm13 ; remove dependencies
        pcmpeqq xmm13, xmm13
        psrldq xmm13, 12
        pcmpeqd xmm13, xmm15

        ; Dividir por MAX, multiplicando por MAGIC y shifteando 53 (division exacta)
        ; Esto es hiper complicado y tira el performance a la basura,
        ; pero el SSE no tiene PMULHD :/
        ; ->
;|         0         |    delta ldrR3    |    delta ldrG3    |    delta ldrB3    | xmm5
;|         0         |    delta ldrR2    |    delta ldrG2    |    delta ldrB2    | xmm6
;|         0         |    delta ldrR1    |    delta ldrG1    |    delta ldrB1    | xmm7
;|         0         |    delta ldrR0    |    delta ldrG0    |    delta ldrB0    | xmm8
        movdqa xmm9, xmm5
        movdqa xmm10, xmm6
        movdqa xmm11, xmm7
        movdqa xmm12, xmm8
        psrlq xmm9, 32
        psrlq xmm10, 32
        psrlq xmm11, 32
        psrlq xmm12, 32
        pmuldq xmm5, xmm14
        pmuldq xmm6, xmm14
        pmuldq xmm7, xmm14
        pmuldq xmm8, xmm14
        pmuldq xmm9, xmm14
        pmuldq xmm10, xmm14
        pmuldq xmm11, xmm14
        pmuldq xmm12, xmm14
        psrlq xmm5, 53
        psrlq xmm6, 53
        psrlq xmm7, 53
        psrlq xmm8, 53
        psrlq xmm9, 21
        psrlq xmm10, 21
        psrlq xmm11, 21
        psrlq xmm12, 21
        pand xmm9, xmm13
        pand xmm10, xmm13
        pand xmm11, xmm13
        pand xmm12, xmm13
        por xmm5, xmm9
        por xmm6, xmm10
        por xmm7, xmm11
        por xmm8, xmm12

        ; Sumarle el valor original de cada pixel
        ; ->
;|        A3         |       ldrR3       |       ldrG3       |       ldrB3       | xmm5
;|        A2         |       ldrR2       |       ldrG2       |       ldrB2       | xmm6
;|        A1         |       ldrR1       |       ldrG1       |       ldrB1       | xmm7
;|        A0         |       ldrR0       |       ldrG0       |       ldrB0       | xmm8
        paddd xmm5, xmm1
        paddd xmm6, xmm2
        paddd xmm7, xmm3
        paddd xmm8, xmm4

        ; Cargamos 255 para aplicar max/min
        ; ->
;|       255         |       255         |       255         |       255         | xmm13
        movq2dq xmm13, mm1
        movddup xmm13, xmm13

        ; Aplicar min(max(xmmN,0.),255.)
        maxps xmm5, xmm15
        maxps xmm6, xmm15
        maxps xmm7, xmm15
        maxps xmm8, xmm15
        minps xmm5, xmm13
        minps xmm6, xmm13
        minps xmm7, xmm13
        minps xmm8, xmm13

        ; Pack the results into a single line again
        ; ->
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | xmm8
        packusdw xmm8, xmm7
        packusdw xmm6, xmm5
        packuswb xmm8, xmm6

        .continue:

        ; Store in the destination
        movdqu [rdi], xmm8

        add rsi, 16
        add rdi, 16
        dec rcx
    jnz .magicLoop

    ; Do a direct copy of the first and last two lines
    lea rbx, [rax*2+2] ; rbx = cols * 2 + 2 = pixels to copy
    mov rsi, r8 ; rsi = src start
    mov rdi, r9 ; rdi = dst start
    call copyN_sse

    ; rax: cols
    ; rdx: filas
    ; r8: srcBase
    ; r9: dstBase
    ; startDir = (filas - 2) * row_size - 2 + base
    lea r11, [rdx-2]
    imul r11, rax
    sub r11, 2
    shl r11, 2 ; #pixels -> #bytes
    lea rsi, [r11+r8]
    lea rdi, [r11+r9]
    call copyN_sse

    ; copia directa de los bordes
    lea rsi, [r8 + r15 - 8]
    lea rdi, [r9 + r15 - 8]
    ; rcx = #filas-3
    lea rcx, [rdx-3]
    .copyBorders:
        movdqu xmm0, [rsi]
        movdqu [rdi], xmm0

        add rsi, r14
        add rdi, r14
    loop .copyBorders

    pop r12
    pop r13
    pop r14
    pop r15
    pop rbx
    pop rbp
    ret


ldr_sse:
    ; Requires SSE4.1
    push rbp
    mov rbp, rsp
    push rbx
    push r15 ; Stack aligned
    push r14
    push r13
    push r12

    ; line offsets
    ; r12: -2
    ; r13: -1
    ; r14: +1
    ; r15: +2
    mov r13, r8
    mov r14, r8
    neg r13
    lea r12, [r13*2]
    lea r15, [r8*2]

    ; rax = cols
    ; rdx = filas
    ; r8 = src
    ; r9 = dst
    ; r10 = alpha
    ; rdi = current pixel src
    ; rsi = current pixel dst
    mov rax, rdx
    mov rdx, rcx
    mov r8, rdi
    mov r9, rsi
    movsx r10, word [rbp+16]
    mov rsi, r8
    mov rdi, r9

    ; Recorrer la imagen linealmente de a grupos de 4,
    ; manteniendo la suma de los pixeles vecinos en xmm0-4
    pxor xmm0, xmm0
    pxor xmm1, xmm1
    pxor xmm2, xmm2
    pxor xmm3, xmm3
    pxor xmm4, xmm4

    ; xmm15 is always zero
    pxor xmm15, xmm15

    ; mm0 = |   LDR_MAX_MAGIC.  |   LDR_MAX_MAGIC   |
    ; mm1 = |        255.       |        255        |
    ; mm2 = |       alpha.      |       alpha.      |
    movq mm0, [LDR_MAX_INV]
    movq mm1, [PIXEL_MAX_F]
    pinsrd xmm6, r10d, 0
    pinsrd xmm6, r10d, 1
    cvtdq2ps xmm6, xmm6
    movdq2q mm2, xmm6

    ; Empezamos a procesar desde fila2 - 4px
    lea rsi, [r8 + r15 - 8]
    lea rdi, [r9 + r15 - 8]

    ; Magic loop, correr sobre ((filas-4)*cols+4)/4
    lea rcx, [rdx-4]    ; rcx = filas-4
    imul rcx, rax       ; rcx = (filas-4)*cols
    add rcx, 4          ; rcx = (filas-4)*cols+4
    shr rcx, 2          ; rcx = ((filas-4)*cols+4)/4

    .magicLoop:

        ; xmm0 tiene la suma de las primeras cuatro columnas que necesitamos y lo demas en 0
; |    0    |    0    |    0    |    0    |sum_col3 |sum_col2 |sum_col1 |sum_col0 | xmm0

        ; load the new pixels
        ; ->
; | A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 | xmmN
        movdqu xmm5, [rsi+r12+8]
        movdqu xmm6, [rsi+r13+8]
        movdqu xmm7, [rsi+8]
        movdqu xmm8, [rsi+r14+8]
        movdqu xmm9, [rsi+r15+8]

        ; shift to clear the alpha bits
        ; ->
; | R7 | G7 | B7 |  0 | R6 | G6 | B6 |  0 | R5 | G5 | B5 |  0 | R4 | G4 | B4 |  0 | xmmN
        pslld xmm5, 8
        pslld xmm6, 8
        pslld xmm7, 8
        pslld xmm8, 8
        pslld xmm9, 8

        ; unpack bytes to words, xmmN -> xmm{N+5}:xmmN
        ; ->
; |    R7   |    G7   |    B7   |     0   |    R6   |    G6   |    B6   |     0   | xmm{N+5}
; |    R5   |    G5   |    B5   |     0   |    R4   |    G4   |    B4   |     0   | xmmN
        movdqa xmm10, xmm5
        movdqa xmm11, xmm6
        movdqa xmm12, xmm7
        movdqa xmm13, xmm8
        movdqa xmm14, xmm9
        punpcklbw xmm5, xmm15
        punpcklbw xmm6, xmm15
        punpcklbw xmm7, xmm15
        punpcklbw xmm8, xmm15
        punpcklbw xmm9, xmm15
        punpckhbw xmm10, xmm15
        punpckhbw xmm11, xmm15
        punpckhbw xmm12, xmm15
        punpckhbw xmm13, xmm15
        punpckhbw xmm14, xmm15

        ; Get the horizontal sum
        ; ->
; | R7 + G7 |    B7   | R6 + G6 |    B6   | R5 + G5 |    B5   | R4 + G4 |    B4   | xmmN
        phaddw xmm5, xmm10
        phaddw xmm6, xmm11
        phaddw xmm7, xmm12
        phaddw xmm8, xmm13
        phaddw xmm9, xmm14
        ; ->
;| R7+G7+B7| R6+G6+B6| R5+G5+B5| R4+G4+B4|    0    |    0    |    0    |    0     | xmm{N+5}
        ; ==
;|   sum7  |   sum6  |   sum5  |   sum4  |    0    |    0    |    0    |    0     | xmm{N+5}
        pxor xmm10, xmm10
        pxor xmm11, xmm11
        pxor xmm12, xmm12
        pxor xmm13, xmm13
        pxor xmm14, xmm14
        phaddw xmm10, xmm5
        phaddw xmm11, xmm6
        phaddw xmm12, xmm7
        phaddw xmm13, xmm8
        phaddw xmm14, xmm9

        ; Reducir todas las sumargb_i a una unica sumargb
        ; ->
;|sum_col7 |sum_col6 |sum_col5 |sum_col4 |    0    |    0    |    0    |    0     | xmm10
        paddw xmm13, xmm14
        paddw xmm10, xmm11
        paddw xmm12, xmm13
        paddw xmm10, xmm12

        ; Save the sums in xmm0
        ; ->
;|sum_col7 |sum_col6 |sum_col5 |sum_col4 |sum_col3 |sum_col2 |sum_col1 |sum_col0 | xmm0
        por xmm0, xmm10

        ; Calcular sumargb para cada uno de los 4 pixeles que vamos a procesar
        ; En el proceso vamos eliminando las sumas de pixeles viejos y dejamos xmm0
        ; listo para la siguiente vuelta
        ; ->
;|    X    |    X    |    X    |    X    |sumargb3 |sumargb2 |sumargb1 |sumargb0 | xmm5
;|    0    |    0    |    0    |    0    |sum_col7 |sum_col6 |sum_col5 |sum_col4 | xmm0
        movdqa xmm5, xmm0 ; Mover valor inicial, j-2
        psrldq xmm0, 2 ; Desechar valor viejo j-2
        paddw xmm5, xmm0 ; Sumar j-1
        psrldq xmm0, 2 ; Desechar valor viejo j-1
        paddw xmm5, xmm0 ; Sumar j
        psrldq xmm0, 2 ; Desechar valor viejo j
        paddw xmm5, xmm0 ; Sumar j+1
        psrldq xmm0, 2 ; Desechar valor viejo j+1
        paddw xmm5, xmm0 ; Sumar j+2

        ; Cargar alpha en xmm6 por cuadriplicado en fp
        ; ->
;|       alpha.      |       alpha.      |       alpha.      |       alpha.      | xmm6
        movq2dq xmm6, mm2
        movddup xmm6, xmm6

        ; Expandir las sumas, convertirlas a fp y multiplicarlas por alpha
        ; ->
;| sumargb3 * alpha. | sumargb2 * alpha. | sumargb1 * alpha. | sumargb0 * alpha. | xmm5
        punpcklwd xmm5, xmm15
        cvtdq2ps xmm5, xmm5
        mulps xmm5, xmm6

        ; Movemos las sumas cada una replicada en un vector
        ; ->
;| sumargb3 * alpha. | sumargb3 * alpha. | sumargb3 * alpha. | sumargb3 * alpha. | xmm5
;| sumargb2 * alpha. | sumargb2 * alpha. | sumargb2 * alpha. | sumargb2 * alpha. | xmm6
;| sumargb1 * alpha. | sumargb1 * alpha. | sumargb1 * alpha. | sumargb1 * alpha. | xmm7
;| sumargb0 * alpha. | sumargb0 * alpha. | sumargb0 * alpha. | sumargb0 * alpha. | xmm8
        pshufd xmm8, xmm5, 0b00000000
        pshufd xmm7, xmm5, 0b01010101
        pshufd xmm6, xmm5, 0b10101010
        pshufd xmm5, xmm5, 0b11111111

        ; Cargar los valores de los pixeles, unpackearlos a dw y pasarlos a float
        ; ->
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | xmm9
        movdqu xmm9, [rsi]
        ; ->
;|    A3   |    R3   |    G3   |   B3    |    A2   |    R2   |    G2   |   B2    | xmm9
;|    A1   |    R1   |    G1   |   B1    |    A0   |    R0   |    G0   |   B0    | xmm11
        movdqa xmm11, xmm9
        punpckhbw xmm9, xmm15
        punpcklbw xmm11, xmm15
        ; ->
;|        A3         |         R3        |         G3        |         B3        | xmm9
;|        A2         |         R2        |         G2        |         B2        | xmm10
;|        A1         |         R1        |         G1        |         B1        | xmm11
;|        A0         |         R0        |         G0        |         B0        | xmm12
        movdqa xmm10, xmm9
        movdqa xmm12, xmm11
        punpckhwd xmm9, xmm15
        punpcklwd xmm10, xmm15
        punpckhwd xmm11, xmm15
        punpcklwd xmm12, xmm15
        ; ->
;|        A3.        |         R3.       |         G3.       |         B3.       | xmm9
;|        A2.        |         R2.       |         G2.       |         B2.       | xmm10
;|        A1.        |         R1.       |         G1.       |         B1.       | xmm11
;|        A0.        |         R0.       |         G0.       |         B0.       | xmm12
        cvtdq2ps xmm9, xmm9
        cvtdq2ps xmm10, xmm10
        cvtdq2ps xmm11, xmm11
        cvtdq2ps xmm12, xmm12

        ; Cargar una mascara para borrar el canal alpha
        ; ->
;|         0         |    0xffffffff     |    0xffffffff     |    0xffffffff     | xmm13
        pxor xmm13, xmm13 ; remove dependencies
        pcmpeqq xmm13, xmm13
        psrldq xmm13, 4

        ; Multiplicamos cada valor de cada pixel por sumargb*alpha
        ; y borramos el canal alpha
        ; ->
;|         0.        | R3*sumargb3*alpha.| G3*sumargb3*alpha.| B3*sumargb3*alpha.| xmm5
;|         0.        | R2*sumargb2*alpha.| G2*sumargb2*alpha.| B2*sumargb2*alpha.| xmm6
;|         0.        | R1*sumargb1*alpha.| G1*sumargb1*alpha.| B1*sumargb1*alpha.| xmm7
;|         0.        | R0*sumargb0*alpha.| G0*sumargb0*alpha.| B0*sumargb0*alpha.| xmm8
        mulps xmm5, xmm9
        mulps xmm6, xmm10
        mulps xmm7, xmm11
        mulps xmm8, xmm12
        pand xmm5, xmm13
        pand xmm6, xmm13
        pand xmm7, xmm13
        pand xmm8, xmm13


        ; Cargamos el 1/max en xmm14 en fp
        ; ->
;|      1/MAX.       |      1/MAX.       |      1/MAX.       |      1/MAX.       | xmm14
        movq2dq xmm14, mm0
        movddup xmm14, xmm14

        ; Dividir por MAX y sumarle el valor original de cada pixel
        ; ->
;|        A3.        |       ldrR3.      |       ldrG3.      |       ldrB3.      | xmm5
;|        A2.        |       ldrR2.      |       ldrG2.      |       ldrB2.      | xmm6
;|        A1.        |       ldrR1.      |       ldrG1.      |       ldrB1.      | xmm7
;|        A0.        |       ldrR0.      |       ldrG0.      |       ldrB0.      | xmm8
        mulps xmm5, xmm14
        mulps xmm6, xmm14
        mulps xmm7, xmm14
        mulps xmm8, xmm14
        addps xmm5, xmm9
        addps xmm6, xmm10
        addps xmm7, xmm11
        addps xmm8, xmm12

        ; Cargamos 255 para aplicar max/min
        ; ->
;|       255.        |       255.        |       255.        |       255.        | xmm13
        movq2dq xmm13, mm1
        movddup xmm13, xmm13

        ; Aplicar min(max(xmmN,0.),255.)
        maxps xmm5, xmm15
        maxps xmm6, xmm15
        maxps xmm7, xmm15
        maxps xmm8, xmm15
        minps xmm5, xmm13
        minps xmm6, xmm13
        minps xmm7, xmm13
        minps xmm8, xmm13

        ; Convert the numbers back to integers
        ; ->
;|       ldrR3       |       ldrG3       |       ldrB3       |         0         | xmm5
;|       ldrR2       |       ldrG2       |       ldrB2       |         0         | xmm6
;|       ldrR1       |       ldrG1       |       ldrB1       |         0         | xmm7
;|       ldrR0       |       ldrG0       |       ldrB0       |         0         | xmm8
        cvtps2dq xmm5, xmm5
        cvtps2dq xmm6, xmm6
        cvtps2dq xmm7, xmm7
        cvtps2dq xmm8, xmm8

        ; Pack the results into a single line again
        ; ->
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | xmm8
        packusdw xmm8, xmm7
        packusdw xmm6, xmm5
        packuswb xmm8, xmm6

        .continue:

        ; Store in the destination
        movdqu [rdi], xmm8

        add rsi, 16
        add rdi, 16
        dec rcx
    jnz .magicLoop

    ; Do a direct copy of the first and last two lines
    lea rbx, [rax*2+2] ; rbx = cols * 2 + 2 = pixels to copy
    mov rsi, r8 ; rsi = src start
    mov rdi, r9 ; rdi = dst start
    call copyN_sse

    ; rax: cols
    ; rdx: filas
    ; r8: srcBase
    ; r9: dstBase
    ; startDir = (filas - 2) * row_size - 2 + base
    lea r11, [rdx-2]
    imul r11, rax
    sub r11, 2
    shl r11, 2 ; #pixels -> #bytes
    lea rsi, [r11+r8]
    lea rdi, [r11+r9]
    call copyN_sse

    ; copia directa de los bordes
    lea rsi, [r8 + r15 - 8]
    lea rdi, [r9 + r15 - 8]
    ; rcx = #filas-3 = ((filas-4)*cols+4)/4
    lea rcx, [rdx-3]
    .copyBorders:
        movdqu xmm0, [rsi]
        movdqu [rdi], xmm0

        add rsi, r14
        add rdi, r14
    loop .copyBorders

    pop r12
    pop r13
    pop r14
    pop r15
    pop rbx
    pop rbp
    ret

