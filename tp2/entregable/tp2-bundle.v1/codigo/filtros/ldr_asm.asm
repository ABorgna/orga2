
extern copyN
extern copyN_sse
extern copyN_avx2

global ldr_asm
global ldr_sse
global ldr_sse_float
global ldr_avx
global ldr_avx2

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
    ; edx | int filas,
    ; ecx | int cols,
    ; r8d | int src_row_size,
    ; r9d | int dst_row_size,
    ; bp+16 | int alpha
;)
ldr_asm:
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
    mov rax, rcx
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

    ; mm0 = | LDR_MAX_MAGIC| LDR_MAX_MAGIC|
    ; mm1 = |     255      |     255      |
    ; mm2 = |    alpha     |    alpha     |
    movq mm0, [LDR_MAX_MAGIC]
    movq mm1, [PIXEL_MAX]
    pinsrd xmm6, r10d, 0
    pinsrd xmm6, r10d, 1
    movdq2q mm2, xmm6

    ; Empezamos a procesar desde fila2 - 4px
    lea rsi, [r8 + r15 - 16]
    lea rdi, [r9 + r15 - 16]

    ; Magic loop, correr sobre ((filas-4)*cols+4)/4
    lea rcx, [rdx-4]    ; rcx = filas-4
    imul rcx, rax       ; rcx = (filas-4)*cols
    add rcx, 4          ; rcx = (filas-4)*cols+4
    shr rcx, 2          ; rcx = ((filas-4)*cols+4)/4

    .magicLoop:

        ; xmmL tiene la suma de los primeros 4 pixeles vecinos y la parte alta en 0
; |    0    |    0    |    0    |    0    |   sum3  |   sum2  |   sum1  |   sum0  | xmmL

        ; load the new pixels
        ; ->
; | A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 | xmmN
        movdqu xmm5, [rsi+r12+16]
        movdqu xmm6, [rsi+r13+16]
        movdqu xmm7, [rsi+16]
        movdqu xmm8, [rsi+r14+16]
        movdqu xmm9, [rsi+r15+16]

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

        ; Save the sums on the line registers
        ; ->
;|   sum7  |   sum6  |   sum5  |   sum4  |   sum3  |   sum2  |   sum1  |   sum0  | xmmL
        por xmm0, xmm10
        por xmm1, xmm11
        por xmm2, xmm12
        por xmm3, xmm13
        por xmm4, xmm14

        ; Calcular sumargb_i (por linea) para cada uno de los 4 pixeles que vamos a procesar
        ; En el proceso vamos eliminando las sumas de pixeles viejos y dejamos xmmL
        ; listos para la siguiente vuelta
        ; ->
;|    X    |    X    |    X    |    X    |sumargb3n|sumargb2n|sumargb1n|sumargb0n| xmmN
;|    0    |    0    |    0    |    0    |   sum7  |   sum6  |   sum5  |   sum4  | xmmL
        movdqa xmm5, xmm0 ; Mover valor inicial, j-2
        movdqa xmm6, xmm1
        movdqa xmm7, xmm2
        movdqa xmm8, xmm3
        movdqa xmm9, xmm4
        psrldq xmm0, 2 ; Desechar valor viejo j-2
        psrldq xmm1, 2
        psrldq xmm2, 2
        psrldq xmm3, 2
        psrldq xmm4, 2
        paddw xmm5, xmm0 ; Sumar j-1
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4
        psrldq xmm0, 2 ; Desechar valor viejo j-1
        psrldq xmm1, 2
        psrldq xmm2, 2
        psrldq xmm3, 2
        psrldq xmm4, 2
        paddw xmm5, xmm0 ; Sumar j
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4
        psrldq xmm0, 2 ; Desechar valor viejo j
        psrldq xmm1, 2
        psrldq xmm2, 2
        psrldq xmm3, 2
        psrldq xmm4, 2
        paddw xmm5, xmm0 ; Sumar j+1
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4
        psrldq xmm0, 2 ; Desechar valor viejo j+1
        psrldq xmm1, 2
        psrldq xmm2, 2
        psrldq xmm3, 2
        psrldq xmm4, 2
        paddw xmm5, xmm0 ; Sumar j+2
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4

        ; Reducir todas las sumargb_i a una unica sumargb
        ; ->
;|    X    |    X    |    X    |    X    |sumargb3 |sumargb2 |sumargb1 |sumargb0 | xmm5
        paddw xmm8, xmm9
        paddw xmm5, xmm6
        paddw xmm7, xmm8
        paddw xmm5, xmm7

        ; Cargar alpha en xmm6 por cuadriplicado en fp
        ; ->
;|       alpha       |       alpha       |       alpha       |       alpha       | xmm6
        movq2dq xmm6, mm2
        movddup xmm6, xmm6

        ; Expandir las sumas y multiplicarlas por alpha
        ; ->
;| sumargb3 * alpha  | sumargb2 * alpha  | sumargb1 * alpha  | sumargb0 * alpha  | xmm5
        punpcklwd xmm5, xmm15
        pmuldq xmm5, xmm6

        ; Cargamos el magic number en xmm14 en fp
        ; ->
;|       MAGIC       |       MAGIC       |       MAGIC       |       MAGIC       | xmm14
        movq2dq xmm14, mm0
        movddup xmm14, xmm14

        ; Movemos las sumas cada una replicada en un vector
        ; ->
;| sumargb3 * alpha  | sumargb3 * alpha  | sumargb3 * alpha  | sumargb3 * alpha  | xmm5
;| sumargb2 * alpha  | sumargb2 * alpha  | sumargb2 * alpha  | sumargb2 * alpha  | xmm6
;| sumargb1 * alpha  | sumargb1 * alpha  | sumargb1 * alpha  | sumargb1 * alpha  | xmm7
;| sumargb0 * alpha  | sumargb0 * alpha  | sumargb0 * alpha  | sumargb0 * alpha  | xmm8
        pshufd xmm8, xmm5, 0b00000000
        pshufd xmm7, xmm5, 0b01010101
        pshufd xmm6, xmm5, 0b10101010
        pshufd xmm5, xmm5, 0b11111111

        ; cargamos los valores de los pixeles a xmm9
        ; ->
;| R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 |  0 | xmm9
        movdqu xmm9, [rsi]
        pslld xmm9, 8 ; Clear the alpha bytes

        ; Separar los valores de cada pixel, mandarlos a double word
        ; ->
;|    R3   |    G3   |   B3    |    0    |    R2   |    G2   |   B2    |    0    | xmm9
;|    R1   |    G1   |   B1    |    0    |    R0   |    G0   |   B0    |    0    | xmm11
        movdqa xmm11, xmm9
        punpckhbw xmm9, xmm15
        punpcklbw xmm11, xmm15
        ; ->
;|         R3        |         G3        |         B3        |         0         | xmm9
;|         R2        |         G2        |         B2        |         0         | xmm10
;|         R1        |         G1        |         B1        |         0         | xmm11
;|         R0        |         G0        |         B0        |         0         | xmm12
        movdqa xmm10, xmm9
        movdqa xmm12, xmm11
        punpckhwd xmm9, xmm15
        punpcklwd xmm10, xmm15
        punpckhwd xmm11, xmm15
        punpcklwd xmm12, xmm15

        ; Multiplicamos cada valor de cada pixel por sumargb*alpha
        ; ->
;| R3*sumargb3*alpha | G3*sumargb3*alpha | B3*sumargb3*alpha |         0         | xmm5
;| R2*sumargb2*alpha | G2*sumargb2*alpha | B2*sumargb2*alpha |         0         | xmm6
;| R1*sumargb1*alpha | G1*sumargb1*alpha | B1*sumargb1*alpha |         0         | xmm7
;| R0*sumargb0*alpha | G0*sumargb0*alpha | B0*sumargb0*alpha |         0         | xmm8
        pmulhw xmm5, xmm9
        pmulhw xmm6, xmm10
        pmulhw xmm7, xmm11
        pmulhw xmm8, xmm12

        ; Dividir por MAX y sumarle el valor original de cada pixel
        ; ->
;|       ldrR3       |       ldrG3       |       ldrB3       |         0         | xmm5
;|       ldrR2       |       ldrG2       |       ldrB2       |         0         | xmm6
;|       ldrR1       |       ldrG1       |       ldrB1       |         0         | xmm7
;|       ldrR0       |       ldrG0       |       ldrB0       |         0         | xmm8
        pmulhw xmm5, xmm14
        pmulhw xmm6, xmm14
        pmulhw xmm7, xmm14
        pmulhw xmm8, xmm14
        psrad xmm5, 21
        psrad xmm6, 21
        psrad xmm7, 21
        psrad xmm8, 21
        paddd xmm5, xmm9
        paddd xmm6, xmm10
        paddd xmm7, xmm11
        paddd xmm8, xmm12

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
;|  0 | R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 | xmm8
        packusdw xmm8, xmm7
        packusdw xmm6, xmm5
        packuswb xmm8, xmm6
        psrld xmm8, 8

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


ldr_sse_float:
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
    mov rax, rcx
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

    ; mm0 = | LDR_MAX_INV. | LDR_MAX_INV. |
    ; mm1 = |     255.     |     255.     |
    ; mm2 = |    alpha.    |    alpha.    |
    movq mm0, [LDR_MAX_INV]
    movq mm1, [PIXEL_MAX_F]
    pinsrd xmm6, r10d, 0
    pinsrd xmm6, r10d, 1
    cvtdq2ps xmm6, xmm6
    movdq2q mm2, xmm6

    ; Empezamos a procesar desde fila2 - 4px
    lea rsi, [r8 + r15 - 16]
    lea rdi, [r9 + r15 - 16]

    ; Magic loop, correr sobre ((filas-4)*cols+4)/4
    lea rcx, [rdx-4]    ; rcx = filas-4
    imul rcx, rax       ; rcx = (filas-4)*cols
    add rcx, 4          ; rcx = (filas-4)*cols+4
    shr rcx, 2          ; rcx = ((filas-4)*cols+4)/4

    .magicLoop:

        ; xmmL tiene la suma de los primeros 4 pixeles vecinos y la parte alta en 0
; |    0    |    0    |    0    |    0    |   sum3  |   sum2  |   sum1  |   sum0  | xmmL

        ; load the new pixels
        ; ->
; | A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 | xmmN
        movdqu xmm5, [rsi+r12+16]
        movdqu xmm6, [rsi+r13+16]
        movdqu xmm7, [rsi+16]
        movdqu xmm8, [rsi+r14+16]
        movdqu xmm9, [rsi+r15+16]

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

        ; Save the sums on the line registers
        ; ->
;|   sum7  |   sum6  |   sum5  |   sum4  |   sum3  |   sum2  |   sum1  |   sum0  | xmmL
        por xmm0, xmm10
        por xmm1, xmm11
        por xmm2, xmm12
        por xmm3, xmm13
        por xmm4, xmm14

        ; Calcular sumargb_i (por linea) para cada uno de los 4 pixeles que vamos a procesar
        ; En el proceso vamos eliminando las sumas de pixeles viejos y dejamos xmmL
        ; listos para la siguiente vuelta
        ; ->
;|    X    |    X    |    X    |    X    |sumargb3n|sumargb2n|sumargb1n|sumargb0n| xmmN
;|    0    |    0    |    0    |    0    |   sum7  |   sum6  |   sum5  |   sum4  | xmmL
        movdqa xmm5, xmm0 ; Mover valor inicial, j-2
        movdqa xmm6, xmm1
        movdqa xmm7, xmm2
        movdqa xmm8, xmm3
        movdqa xmm9, xmm4
        psrldq xmm0, 2 ; Desechar valor viejo j-2
        psrldq xmm1, 2
        psrldq xmm2, 2
        psrldq xmm3, 2
        psrldq xmm4, 2
        paddw xmm5, xmm0 ; Sumar j-1
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4
        psrldq xmm0, 2 ; Desechar valor viejo j-1
        psrldq xmm1, 2
        psrldq xmm2, 2
        psrldq xmm3, 2
        psrldq xmm4, 2
        paddw xmm5, xmm0 ; Sumar j
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4
        psrldq xmm0, 2 ; Desechar valor viejo j
        psrldq xmm1, 2
        psrldq xmm2, 2
        psrldq xmm3, 2
        psrldq xmm4, 2
        paddw xmm5, xmm0 ; Sumar j+1
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4
        psrldq xmm0, 2 ; Desechar valor viejo j+1
        psrldq xmm1, 2
        psrldq xmm2, 2
        psrldq xmm3, 2
        psrldq xmm4, 2
        paddw xmm5, xmm0 ; Sumar j+2
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4

        ; Reducir todas las sumargb_i a una unica sumargb
        ; ->
;|    X    |    X    |    X    |    X    |sumargb3 |sumargb2 |sumargb1 |sumargb0 | xmm5
        paddw xmm8, xmm9
        paddw xmm5, xmm6
        paddw xmm7, xmm8
        paddw xmm5, xmm7

        ; Cargar alpha en xmm6 por cuadriplicado en fp
        ; ->
;|       alpha.      |       alpha.      |       alpha.      |       alpha.      | xmm6
        movq2dq xmm6, mm2
        movddup xmm6, xmm6

        ; Expandir las sumas y, convertirlas a fp y multiplicarlas por alpha
        ; ->
;| sumargb3 * alpha. | sumargb2 * alpha. | sumargb1 * alpha. | sumargb0 * alpha. | xmm5
        punpcklwd xmm5, xmm15
        cvtdq2ps xmm5, xmm5
        mulps xmm5, xmm6

        ; Cargamos el 1/max en xmm14 en fp
        ; ->
;|      1/MAX.       |      1/MAX.       |      1/MAX.       |      1/MAX.       | xmm14
        movq2dq xmm14, mm0
        movddup xmm14, xmm14

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

        ; cargamos los valores de los pixeles a xmm9
        ; ->
;| R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 |  0 | xmm9
        movdqu xmm9, [rsi]
        pslld xmm9, 8 ; Clear the alpha bytes

        ; Separar los valores de cada pixel, mandarlos a double word, convertirlos a fp
        ; ->
;|    R3   |    G3   |   B3    |    0    |    R2   |    G2   |   B2    |    0    | xmm9
;|    R1   |    G1   |   B1    |    0    |    R0   |    G0   |   B0    |    0    | xmm11
        movdqa xmm11, xmm9
        punpckhbw xmm9, xmm15
        punpcklbw xmm11, xmm15
        ; ->
;|         R3        |         G3        |         B3        |         0         | xmm9
;|         R2        |         G2        |         B2        |         0         | xmm10
;|         R1        |         G1        |         B1        |         0         | xmm11
;|         R0        |         G0        |         B0        |         0         | xmm12
        movdqa xmm10, xmm9
        movdqa xmm12, xmm11
        punpckhwd xmm9, xmm15
        punpcklwd xmm10, xmm15
        punpckhwd xmm11, xmm15
        punpcklwd xmm12, xmm15
        ; ->
;|         R3.       |         G3.       |         B3.       |         0.        | xmm9
;|         R2.       |         G2.       |         B2.       |         0.        | xmm10
;|         R1.       |         G1.       |         B1.       |         0.        | xmm11
;|         R0.       |         G0.       |         B0.       |         0.        | xmm12
        cvtdq2ps xmm9, xmm9
        cvtdq2ps xmm10, xmm10
        cvtdq2ps xmm11, xmm11
        cvtdq2ps xmm12, xmm12

        ; Multiplicamos cada valor de cada pixel por sumargb*alpha
        ; ->
;| R3*sumargb3*alpha.| G3*sumargb3*alpha.| B3*sumargb3*alpha.|         0.        | xmm5
;| R2*sumargb2*alpha.| G2*sumargb2*alpha.| B2*sumargb2*alpha.|         0.        | xmm6
;| R1*sumargb1*alpha.| G1*sumargb1*alpha.| B1*sumargb1*alpha.|         0.        | xmm7
;| R0*sumargb0*alpha.| G0*sumargb0*alpha.| B0*sumargb0*alpha.|         0.        | xmm8
        mulps xmm5, xmm9
        mulps xmm6, xmm10
        mulps xmm7, xmm11
        mulps xmm8, xmm12

        ; Dividir por MAX y sumarle el valor original de cada pixel
        ; ->
;|       ldrR3.      |       ldrG3.      |       ldrB3.      |         0.        | xmm5
;|       ldrR2.      |       ldrG2.      |       ldrB2.      |         0.        | xmm6
;|       ldrR1.      |       ldrG1.      |       ldrB1.      |         0.        | xmm7
;|       ldrR0.      |       ldrG0.      |       ldrB0.      |         0.        | xmm8
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
;|  0 | R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 | xmm8
        packusdw xmm8, xmm7
        packusdw xmm6, xmm5
        packuswb xmm8, xmm6
        psrld xmm8, 8

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

ldr_avx:
    ; Requires AVX & FMA
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
    mov rax, rcx
    mov r8, rdi
    mov r9, rsi
    movsx r10, word [rbp+16]
    mov rsi, r8
    mov rdi, r9

    ; Recorrer la imagen linealmente de a grupos de 4,
    ; manteniendo la suma de los pixeles vecinos en xmm0-4
    ; xmm15 is always zero
    vzeroall

    ; mm0 = | LDR_MAX_INV. | LDR_MAX_INV. |
    ; mm1 = |     255.     |     255.     |
    ; mm2 = |    alpha.    |    alpha.    |
    movq mm0, [LDR_MAX_INV]
    movq mm1, [PIXEL_MAX_F]
    pinsrd xmm6, r10d, 0
    pinsrd xmm6, r10d, 1
    cvtdq2ps xmm6, xmm6
    movdq2q mm2, xmm6

    ; Empezamos a procesar desde fila2 - 4px
    lea rsi, [r8 + r15 - 16]
    lea rdi, [r9 + r15 - 16]

    ; Magic loop, correr sobre ((filas-4)*cols+4)/4
    lea rcx, [rdx-4]    ; rcx = filas-4
    imul rcx, rax       ; rcx = (filas-4)*cols
    add rcx, 4          ; rcx = (filas-4)*cols+4
    shr rcx, 2          ; rcx = ((filas-4)*cols+4)/4

    .magicLoop:

        ; xmmL tiene la suma de los primeros 4 pixeles vecinos y la parte alta en 0
; |    0    |    0    |    0    |    0    |   sum3  |   sum2  |   sum1  |   sum0  | xmmL

        ; load the new pixels
        ; ->
; | A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 | xmmN
        movdqu xmm5, [rsi+r12+16]
        movdqu xmm6, [rsi+r13+16]
        movdqu xmm7, [rsi+16]
        movdqu xmm8, [rsi+r14+16]
        movdqu xmm9, [rsi+r15+16]

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
        vpunpckhbw xmm10, xmm5, xmm15
        vpunpckhbw xmm11, xmm6, xmm15
        vpunpckhbw xmm12, xmm7, xmm15
        vpunpckhbw xmm13, xmm8, xmm15
        vpunpckhbw xmm14, xmm9, xmm15
        vpunpcklbw xmm5, xmm5, xmm15
        vpunpcklbw xmm6, xmm6, xmm15
        vpunpcklbw xmm7, xmm7, xmm15
        vpunpcklbw xmm8, xmm8, xmm15
        vpunpcklbw xmm9, xmm9, xmm15

        ; Get the horizontal sum
        ; ->
; | R7 + G7 |    B7   | R6 + G6 |    B6   | R5 + G5 |    B5   | R4 + G4 |    B4   | xmmN
        vphaddw xmm5, xmm5, xmm10
        vphaddw xmm6, xmm6, xmm11
        vphaddw xmm7, xmm7, xmm12
        vphaddw xmm8, xmm8, xmm13
        vphaddw xmm9, xmm9, xmm14
        ; ->
;| R7+G7+B7| R6+G6+B6| R5+G5+B5| R4+G4+B4|    0    |    0    |    0    |    0     | xmmN
;|   sum7  |   sum6  |   sum5  |   sum4  |    0    |    0    |    0    |    0     | xmmN
        vphaddw xmm5, xmm15, xmm5
        vphaddw xmm6, xmm15, xmm6
        vphaddw xmm7, xmm15, xmm7
        vphaddw xmm8, xmm15, xmm8
        vphaddw xmm9, xmm15, xmm9

        ; Get the final sums
        ; ->
;|   sum7  |   sum6  |   sum5  |   sum4  |   sum3  |   sum2  |   sum1  |   sum0  | xmmN
        por xmm5, xmm0
        por xmm6, xmm1
        por xmm7, xmm2
        por xmm8, xmm3
        por xmm9, xmm4

        ; Calcular sumargb_i (por linea) para cada uno de los 4 pixeles que vamos a procesar
        ; En el proceso vamos eliminando las sumas de pixeles viejos y dejamos xmmL
        ; listos para la siguiente vuelta
        ; ->
;|    X    |    X    |    X    |    X    |sumargb3n|sumargb2n|sumargb1n|sumargb0n| xmmN
;|    0    |    0    |    0    |    0    |   sum7  |   sum6  |   sum5  |   sum4  | xmmL
        vpsrldq xmm0, xmm5, 2 ; Desechar valor viejo j-2
        vpsrldq xmm1, xmm6, 2
        vpsrldq xmm2, xmm7, 2
        vpsrldq xmm3, xmm8, 2
        vpsrldq xmm4, xmm9, 2
        vpaddw xmm5, xmm5, xmm0 ; Sumar j-1
        vpaddw xmm6, xmm6, xmm1
        vpaddw xmm7, xmm7, xmm2
        vpaddw xmm8, xmm8, xmm3
        vpaddw xmm9, xmm9, xmm4
        vpsrldq xmm0, xmm0, 2 ; Desechar valor viejo j-1
        vpsrldq xmm1, xmm1, 2
        vpsrldq xmm2, xmm2, 2
        vpsrldq xmm3, xmm3, 2
        vpsrldq xmm4, xmm4, 2
        vpaddw xmm5, xmm5, xmm0 ; Sumar j
        vpaddw xmm6, xmm6, xmm1
        vpaddw xmm7, xmm7, xmm2
        vpaddw xmm8, xmm8, xmm3
        vpaddw xmm9, xmm9, xmm4
        vpsrldq xmm0, xmm0, 2 ; Desechar valor viejo j
        vpsrldq xmm1, xmm1, 2
        vpsrldq xmm2, xmm2, 2
        vpsrldq xmm3, xmm3, 2
        vpsrldq xmm4, xmm4, 2
        vpaddw xmm5, xmm5, xmm0 ; Sumar j+1
        vpaddw xmm6, xmm6, xmm1
        vpaddw xmm7, xmm7, xmm2
        vpaddw xmm8, xmm8, xmm3
        vpaddw xmm9, xmm9, xmm4
        vpsrldq xmm0, xmm0, 2 ; Desechar valor viejo j+1
        vpsrldq xmm1, xmm1, 2
        vpsrldq xmm2, xmm2, 2
        vpsrldq xmm3, xmm3, 2
        vpsrldq xmm4, xmm4, 2
        vpaddw xmm5, xmm5, xmm0 ; Sumar j+2
        vpaddw xmm6, xmm6, xmm1
        vpaddw xmm7, xmm7, xmm2
        vpaddw xmm8, xmm8, xmm3
        vpaddw xmm9, xmm9, xmm4

        ; Reducir todas las sumargb_i a una unica sumargb
        ; ->
;|    X    |    X    |    X    |    X    |sumargb3 |sumargb2 |sumargb1 |sumargb0 | xmm5
        paddw xmm8, xmm9
        paddw xmm5, xmm6
        paddw xmm7, xmm8
        paddw xmm5, xmm7

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

        ; Cargamos el 1/max en xmm14 en fp
        ; ->
;|      1/MAX.       |      1/MAX.       |      1/MAX.       |      1/MAX.       | xmm14
        movq2dq xmm14, mm0
        movddup xmm14, xmm14

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

        ; cargamos los valores de los pixeles a xmm9
        ; ->
;| R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 |  0 | xmm9
        movdqu xmm9, [rsi]
        pslld xmm9, 8 ; Clear the alpha bytes

        ; Separar los valores de cada pixel, mandarlos a double word, convertirlos a fp
        ; ->
;|    R3   |    G3   |   B3    |    0    |    R2   |    G2   |   B2    |    0    | xmm9
;|    R1   |    G1   |   B1    |    0    |    R0   |    G0   |   B0    |    0    | xmm11
        vpunpcklbw xmm11, xmm9, xmm15
        vpunpckhbw xmm9, xmm9, xmm15
        ; ->
;|         R3        |         G3        |         B3        |         0         | xmm9
;|         R2        |         G2        |         B2        |         0         | xmm10
;|         R1        |         G1        |         B1        |         0         | xmm11
;|         R0        |         G0        |         B0        |         0         | xmm12
        vpunpcklwd xmm10, xmm9, xmm15
        vpunpckhwd xmm9, xmm9, xmm15
        vpunpcklwd xmm12, xmm11, xmm15
        vpunpckhwd xmm11, xmm11, xmm15
        ; ->
;|         R3.       |         G3.       |         B3.       |         0.        | xmm9
;|         R2.       |         G2.       |         B2.       |         0.        | xmm10
;|         R1.       |         G1.       |         B1.       |         0.        | xmm11
;|         R0.       |         G0.       |         B0.       |         0.        | xmm12
        cvtdq2ps xmm9, xmm9
        cvtdq2ps xmm10, xmm10
        cvtdq2ps xmm11, xmm11
        cvtdq2ps xmm12, xmm12

        ; Multiplicamos cada valor de cada pixel por sumargb*alpha
        ; ->
;| R3*sumargb3*alpha.| G3*sumargb3*alpha.| B3*sumargb3*alpha.|         0.        | xmm5
;| R2*sumargb2*alpha.| G2*sumargb2*alpha.| B2*sumargb2*alpha.|         0.        | xmm6
;| R1*sumargb1*alpha.| G1*sumargb1*alpha.| B1*sumargb1*alpha.|         0.        | xmm7
;| R0*sumargb0*alpha.| G0*sumargb0*alpha.| B0*sumargb0*alpha.|         0.        | xmm8
        mulps xmm5, xmm9
        mulps xmm6, xmm10
        mulps xmm7, xmm11
        mulps xmm8, xmm12

        ; Dividir por MAX y sumarle el valor original de cada pixel
        ; ->
;|       ldrR3.      |       ldrG3.      |       ldrB3.      |         0.        | xmm5
;|       ldrR2.      |       ldrG2.      |       ldrB2.      |         0.        | xmm6
;|       ldrR1.      |       ldrG1.      |       ldrB1.      |         0.        | xmm7
;|       ldrR0.      |       ldrG0.      |       ldrB0.      |         0.        | xmm8
        vfmadd132ps xmm5, xmm9, xmm14
        vfmadd132ps xmm6, xmm10, xmm14
        vfmadd132ps xmm7, xmm11, xmm14
        vfmadd132ps xmm8, xmm12, xmm14

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
;|  0 | R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 | xmm8
        packusdw xmm8, xmm7
        packusdw xmm6, xmm5
        packuswb xmm8, xmm6
        psrld xmm8, 8

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


;void ldr_avx    (
    ; rdi | unsigned char *src,
    ; rsi | unsigned char *dst,
    ; edx | int filas,
    ; ecx | int cols,
    ; r8d | int src_row_size,
    ; r9d | int dst_row_size,
    ; bp+16 | int alpha
;)
ldr_avx2:
    ; Requires AVX2
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
    mov rax, rcx
    mov r8, rdi
    mov r9, rsi
    movsx r10, word [rbp+16]
    mov rsi, r8
    mov rdi, r9

    ; Recorrer la imagen linealmente de a grupos de 4,
    ; manteniendo la suma de los pixeles vecinos en ymm0-4
    ; ymm15 is always zero
    vzeroall

    ; mm0 = | LDR_MAX_INV. | LDR_MAX_INV. |
    ; mm1 = |     255.     |     255.     |
    ; mm2 = |    alpha.    |    alpha.    |
    ; [sp] = alpha
    movq mm0, [LDR_MAX_INV]
    movq mm1, [PIXEL_MAX_F]
    pinsrd xmm6, r10d, 0
    pinsrd xmm6, r10d, 1
    cvtdq2ps xmm6, xmm6
    movdq2q mm2, xmm6
    push r10

    ; Empezamos a procesar desde fila2 - 4px
    lea rsi, [r8 + r15 - 16]
    lea rdi, [r9 + r15 - 16]

    ; Magic loop, correr sobre ((filas-4)*cols+8)/8
    lea rcx, [rdx-4]    ; rcx = filas-4
    imul rcx, rax       ; rcx = (filas-4)*cols
    add rcx, 8          ; rcx = (filas-4)*cols+8
    shr rcx, 3          ; rcx = ((filas-4)*cols+8)/8

    .magicLoop:

        ; ymmL tiene la suma de los primeros 8 pixeles vecinos y tod0 lo demas en 0
;|    0    |    0    |    0    |    0    |    0    |    0    |    0    |    0    |...
;|   sum7  |   sum6  |   sum5  |   sum4  |   sum3  |   sum2  |   sum1  |   sum0  | ymmL

        ; load the new pixels
        ; ->
;| AF | RF | GF | BF | AE | RE | GE | BE | AD | RD | GD | BD | AC | RC | GC | BC |...
;| AB | RB | GB | BB | AA | RA | GA | BA | A9 | R9 | G9 | B9 | A8 | R8 | G8 | B8 | ymmN
        vmovdqu ymm5, [rsi+r12+16]
        vmovdqu ymm6, [rsi+r13+16]
        vmovdqu ymm7, [rsi+16]
        vmovdqu ymm8, [rsi+r14+16]
        vmovdqu ymm9, [rsi+r15+16]

        ; shift to clear the alpha bits
        ; ->
;| RF | GF | BF |  0 | RE | GE | BE |  0 | RD | GD | BD |  0 | RC | GC | BC |  0 |...
;| RB | GB | BB |  0 | RA | GA | BA |  0 | R9 | G9 | B9 |  0 | R8 | G8 | B8 |  0 | ymmN
        vpslld ymm5, 8
        vpslld ymm6, 8
        vpslld ymm7, 8
        vpslld ymm8, 8
        vpslld ymm9, 8

        ; unpack bytes to words, ymmN -> ymm{N+5} & ymmN
        ; ->
;|    RF   |    GF   |    BF   |    0    |    RE   |    GE   |    BE   |    0    |...
;|    RB   |    GB   |    BB   |    0    |    RA   |    GA   |    BA   |    0    | ymm{N+5}
        ; &
;|    RD   |    GD   |    BD   |    0    |    RC   |    GC   |    BC   |    0    |...
;|    R9   |    G9   |    B9   |    0    |    R8   |    G8   |    B8   |    0    | ymmN
        vpunpckhbw ymm10, ymm5, ymm15
        vpunpckhbw ymm11, ymm6, ymm15
        vpunpckhbw ymm12, ymm7, ymm15
        vpunpckhbw ymm13, ymm8, ymm15
        vpunpckhbw ymm14, ymm9, ymm15
        vpunpcklbw ymm5, ymm5, ymm15
        vpunpcklbw ymm6, ymm6, ymm15
        vpunpcklbw ymm7, ymm7, ymm15
        vpunpcklbw ymm8, ymm8, ymm15
        vpunpcklbw ymm9, ymm9, ymm15

        ; Get the horizontal sum
        ; ->
;| RF + GF |    BF   | RE + GE |    BE   | RD + GD |    BD   | RC + GC |    BC   |...
;| RB + GB |    BB   | RA + GA |    BA   | R9 + G9 |    B9   | R8 + G8 |    B8   | ymmN
        vphaddw ymm5, ymm5, ymm10
        vphaddw ymm6, ymm6, ymm11
        vphaddw ymm7, ymm7, ymm12
        vphaddw ymm8, ymm8, ymm13
        vphaddw ymm9, ymm9, ymm14
        ; ->
;| RF+GF+BF| RE+GE+BE| RD+GD+BD| RC+GC+BC| RB+GB+BB| RA+GA+BA| R9+G9+B9| R8+G8+B8|...
;|    0    |    0    |    0    |    0    |    0    |    0    |    0    |    0    | ymmN
        vphaddw ymm5, ymm15, ymm5
        vphaddw ymm6, ymm15, ymm6
        vphaddw ymm7, ymm15, ymm7
        vphaddw ymm8, ymm15, ymm8
        vphaddw ymm9, ymm15, ymm9
        vpermq ymm5, ymm5, 0b11010000
        vpermq ymm6, ymm6, 0b11010000
        vpermq ymm7, ymm7, 0b11010000
        vpermq ymm8, ymm8, 0b11010000

        ; Save the sums on the line registers
        ; ->
;|   sumF  |   sumE  |   sumD  |   sumC  |   sumB  |   sumA  |   sum9  |   sum8  |...
;|   sum7  |   sum6  |   sum5  |   sum4  |   sum3  |   sum2  |   sum1  |   sum0  | ymmN
        vpor ymm5, ymm0, ymm5
        vpor ymm6, ymm1, ymm6
        vpor ymm7, ymm2, ymm7
        vpor ymm8, ymm3, ymm8
        vpor ymm9, ymm4, ymm9

        ; Calcular sumargb_i (por linea) para cada uno de los 4 pixeles que vamos a procesar
        ; En el proceso vamos eliminando las sumas de pixeles viejos y dejamos xmmL
        ; listos para la siguiente vuelta
        ; ->
;oeoae|    X    |    X    |    X    |    X    |    X    |    X    |    X    |    X    |...
;|sumargb7n|sumargb6n|sumargb5n|sumargb4n|sumargb3n|sumargb2n|sumargb1n|sumargb0n| ymmN
        ; &
;|    0    |    0    |    0    |    0    |    0    |    0    |    0    |    0    |...
;|   sumF  |   sumE  |   sumD  |   sumC  |   sumB  |   sumA  |   sum9  |   sum8  | ymmL


    ; TODO TODO TODO TODO roto !!!!!!!!!!!!!!!!!!!!!!!!!!!


        vpsrldq ymm0, ymm5, 2 ; Desechar valor viejo j-2
        vpsrldq ymm1, ymm6, 2
        vpsrldq ymm2, ymm7, 2
        vpsrldq ymm3, ymm8, 2
        vpsrldq ymm4, ymm9, 2
        vpaddw ymm5, ymm5, ymm0 ; Sumar j-1
        vpaddw ymm6, ymm6, ymm1
        vpaddw ymm7, ymm7, ymm2
        vpaddw ymm8, ymm8, ymm3
        vpaddw ymm9, ymm9, ymm4
        vpsrldq ymm0, ymm0, 2 ; Desechar valor viejo j-1
        vpsrldq ymm1, ymm1, 2
        vpsrldq ymm2, ymm2, 2
        vpsrldq ymm3, ymm3, 2
        vpsrldq ymm4, ymm4, 2
        vpaddw ymm5, ymm5, ymm0 ; Sumar j
        vpaddw ymm6, ymm6, ymm1
        vpaddw ymm7, ymm7, ymm2
        vpaddw ymm8, ymm8, ymm3
        vpaddw ymm9, ymm9, ymm4
        vpsrldq ymm0, ymm0, 2 ; Desechar valor viejo j
        vpsrldq ymm1, ymm1, 2
        vpsrldq ymm2, ymm2, 2
        vpsrldq ymm3, ymm3, 2
        vpsrldq ymm4, ymm4, 2
        vpaddw ymm5, ymm5, ymm0 ; Sumar j+1
        vpaddw ymm6, ymm6, ymm1
        vpaddw ymm7, ymm7, ymm2
        vpaddw ymm8, ymm8, ymm3
        vpaddw ymm9, ymm9, ymm4
        vpsrldq ymm0, ymm0, 2 ; Desechar valor viejo j+1
        vpsrldq ymm1, ymm1, 2
        vpsrldq ymm2, ymm2, 2
        vpsrldq ymm3, ymm3, 2
        vpsrldq ymm4, ymm4, 2
        vpaddw ymm5, ymm5, ymm0 ; Sumar j+2
        vpaddw ymm6, ymm6, ymm1
        vpaddw ymm7, ymm7, ymm2
        vpaddw ymm8, ymm8, ymm3
        vpaddw ymm9, ymm9, ymm4
        vpsrldq ymm0, ymm0, 8 ; Desechar los valores restantes
        vpsrldq ymm1, ymm1, 8
        vpsrldq ymm2, ymm2, 8
        vpsrldq ymm3, ymm3, 8
        vpsrldq ymm4, ymm4, 8

        ; Reducir todas las sumargb_i a una unica sumargb
        ; ->
;|    0    |    0    |    0    |    0    |    0    |    0    |    0    |    0    |...
;|sumargb7 |sumargb6 |sumargb5 |sumargb4 |sumargb3 |sumargb2 |sumargb1 |sumargb0 | ymmN
        vpaddw xmm8, xmm9
        vpaddw xmm5, xmm6
        vpaddw xmm7, xmm8
        vpaddw xmm5, xmm7

        ; Cargar alpha en ymm6 ocho veces en fp
        ; ->
;|       alpha.      |       alpha.      |       alpha.      |       alpha.      |...
;|       alpha.      |       alpha.      |       alpha.      |       alpha.      | ymm6
        vbroadcastss ymm6, [rsp]

        ; Expandir las sumas, convertirlas a fp y multiplicarlas por alpha
        ; ->
;| sumargb7 * alpha. | sumargb6 * alpha. | sumargb5 * alpha. | sumargb4 * alpha. |...
;| sumargb3 * alpha. | sumargb2 * alpha. | sumargb1 * alpha. | sumargb0 * alpha. | ymm5
        vpunpcklwd ymm5, ymm5, ymm15
        ;vcvtdq2ps ymm5, ymm5 ; TODO TODO TODO why so slow ?
        vmulps ymm5, ymm5, ymm6

        ; Cargamos el 1/max en ymm14 en fp
        ; ->
;|      1/MAX.       |      1/MAX.       |      1/MAX.       |      1/MAX.       |...
;|      1/MAX.       |      1/MAX.       |      1/MAX.       |      1/MAX.       | ymm14
        vbroadcastsd ymm14, [LDR_MAX_INV]

        ; Movemos las sumas cada una replicada en un vector
        ; ->
;| sumargb7 * alpha. | sumargb7 * alpha. | sumargb7 * alpha. | sumargb7 * alpha. |...
;| sumargb3 * alpha. | sumargb3 * alpha. | sumargb3 * alpha. | sumargb3 * alpha. | ymm5
        ; &
;| sumargb6 * alpha. | sumargb6 * alpha. | sumargb6 * alpha. | sumargb6 * alpha. |...
;| sumargb2 * alpha. | sumargb2 * alpha. | sumargb2 * alpha. | sumargb2 * alpha. | ymm6
        ; &
;| sumargb5 * alpha. | sumargb5 * alpha. | sumargb5 * alpha. | sumargb5 * alpha. |...
;| sumargb1 * alpha. | sumargb1 * alpha. | sumargb1 * alpha. | sumargb1 * alpha. | ymm7
        ; &
;| sumargb5 * alpha. | sumargb5 * alpha. | sumargb5 * alpha. | sumargb5 * alpha. |...
;| sumargb0 * alpha. | sumargb0 * alpha. | sumargb0 * alpha. | sumargb0 * alpha. | ymm8
        vpshufd ymm8, ymm5, 0b00000000
        vpshufd ymm7, ymm5, 0b01010101
        vpshufd ymm6, ymm5, 0b10101010
        vpshufd ymm5, ymm5, 0b11111111

        ; cargamos los valores de los pixeles a xmm9
        ; ->
;| R7 | G7 | B7 |  0 | R6 | G6 | B6 |  0 | R5 | G5 | B5 |  0 | R4 | G4 | B4 |  0 |...
;| R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 |  0 | ymm9
        vmovdqu ymm9, [rsi]
        vpslld ymm9, 8 ; Clear the alpha bytes

        ; Separar los valores de cada pixel, mandarlos a double word, convertirlos a fp
        ; ->
;|    R7   |    G7   |   B7    |    0    |    R6   |    G6   |   B6    |    0    |...
;|    R5   |    G5   |   B5    |    0    |    R4   |    G4   |   B4    |    0    | ymm9
        ; &
;|    R3   |    G3   |   B3    |    0    |    R2   |    G2   |   B2    |    0    |...
;|    R1   |    G1   |   B1    |    0    |    R0   |    G0   |   B0    |    0    | ymm11
        vpunpcklbw ymm11, ymm9, ymm15
        vpunpckhbw ymm9, ymm9, ymm15
        ; ->
;|         R7.       |         G7.       |         B7.       |         0.        |...
;|         R3.       |         G3.       |         B3.       |         0.        | xmm9
        ; &
;|         R6.       |         G6.       |         B6.       |         0.        |...
;|         R2.       |         G2.       |         B2.       |         0.        | xmm10
        ; &
;|         R5.       |         G5.       |         B5.       |         0.        |...
;|         R1.       |         G1.       |         B1.       |         0.        | xmm11
        ; &
;|         R4.       |         G4.       |         B4.       |         0.        |
;|         R0.       |         G0.       |         B0.       |         0.        | xmm12
        vpunpcklwd ymm10, ymm9, ymm15
        vpunpckhwd ymm9, ymm9, ymm15
        vpunpcklwd ymm12, ymm11, ymm15
        vpunpckhwd ymm11, ymm11, ymm15
        vcvtdq2ps ymm9, ymm9
        vcvtdq2ps ymm10, ymm10
        vcvtdq2ps ymm11, ymm11
        vcvtdq2ps ymm12, ymm12

        ; Multiplicamos cada valor de cada pixel por sumargb*alpha
        ; ->
        ;&
;| R7*sumargb7*alpha.| G7*sumargb7*alpha.| B7*sumargb7*alpha.|         7.        |...
;| R3*sumargb3*alpha.| G3*sumargb3*alpha.| B3*sumargb3*alpha.|         0.        | xmm5
        ;&
;| R6*sumargb6*alpha.| G6*sumargb6*alpha.| B6*sumargb6*alpha.|         6.        |...
;| R2*sumargb2*alpha.| G2*sumargb2*alpha.| B2*sumargb2*alpha.|         0.        | xmm6
        ;&
;| R5*sumargb5*alpha.| G5*sumargb5*alpha.| B5*sumargb5*alpha.|         5.        |...
;| R1*sumargb1*alpha.| G1*sumargb1*alpha.| B1*sumargb1*alpha.|         0.        | xmm7
        ;&
;| R4*sumargb4*alpha.| G4*sumargb4*alpha.| B4*sumargb4*alpha.|         4.        |...
;| R0*sumargb0*alpha.| G0*sumargb0*alpha.| B0*sumargb0*alpha.|         0.        | xmm8
        vmulps ymm5, ymm5, ymm9
        vmulps ymm6, ymm6, ymm10
        vmulps ymm7, ymm7, ymm11
        vmulps ymm8, ymm8, ymm12

        ; Dividir por MAX y sumarle el valor original de cada pixel
        ; ->
;|       ldrR3.      |       ldrG3.      |       ldrB3.      |         0.        | xmm5
;|       ldrR2.      |       ldrG2.      |       ldrB2.      |         0.        | xmm6
;|       ldrR1.      |       ldrG1.      |       ldrB1.      |         0.        | xmm7
;|       ldrR0.      |       ldrG0.      |       ldrB0.      |         0.        | xmm8
        vfmadd132ps xmm5, xmm9, xmm14
        vfmadd132ps xmm6, xmm10, xmm14
        vfmadd132ps xmm7, xmm11, xmm14
        vfmadd132ps xmm8, xmm12, xmm14

        ; Cargamos 255 para aplicar max/min
        ; ->
;|       255.        |       255.        |       255.        |       255.        |...
;|       255.        |       255.        |       255.        |       255.        | xmm13
        vbroadcastsd ymm13, [PIXEL_MAX_F]

        ; Aplicar min(max(xmmN,0.),255.)
        vmaxps ymm5, ymm5, ymm15
        vmaxps ymm6, ymm6, ymm15
        vmaxps ymm7, ymm7, ymm15
        vmaxps ymm8, ymm8, ymm15
        vminps ymm5, ymm5, ymm13
        vminps ymm6, ymm6, ymm13
        vminps ymm7, ymm7, ymm13
        vminps ymm8, ymm8, ymm13

        ; Convert the numbers back to integers
        ; ->
;|       ldrR3       |       ldrG3       |       ldrB3       |         0         | xmm5
;|       ldrR2       |       ldrG2       |       ldrB2       |         0         | xmm6
;|       ldrR1       |       ldrG1       |       ldrB1       |         0         | xmm7
;|       ldrR0       |       ldrG0       |       ldrB0       |         0         | xmm8
        ;cvtps2dq xmm5, xmm5 ; TODO TODO why so slow?
        ;cvtps2dq xmm6, xmm6
        ;cvtps2dq xmm7, xmm7
        ;cvtps2dq xmm8, xmm8

        ; Pack the results into a single line again
        ; ->
;|  0 | R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 | xmm8
        vpackusdw ymm8, ymm8, ymm7
        vpackusdw ymm6, ymm6, ymm5
        vpackuswb ymm8, ymm8, ymm6
        vpsrld ymm8, ymm8, 8

        ; Store in the destination
        vmovdqu [rdi], ymm8

        .continue:

        add rsi, 32
        add rdi, 32
        dec rcx
    jnz .magicLoop

    ; Do a direct copy of the first and last two lines
    lea rbx, [rax*2+2] ; rbx = cols * 2 + 2 = pixels to copy
    mov rsi, r8 ; rsi = src start
    mov rdi, r9 ; rdi = dst start
    ;call copyN_avx2

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
    ;call copyN_avx2

    ; copia directa de los bordes
    lea rsi, [r8 + r15 - 8]
    lea rdi, [r9 + r15 - 8]
    ; rcx = #filas-3 = ((filas-4)*cols+4)/4
    lea rcx, [rdx-3]
    .copyBorders:
        ;movdqu xmm0, [rsi]
        ;movdqu [rdi], xmm0

        add rsi, r14
        add rdi, r14
    loop .copyBorders

    add rsp, 8
    pop r12
    pop r13
    pop r14
    pop r15
    pop rbx
    pop rbp
    ret

