
extern copyN
extern copyN_sse
extern copyN_avx2

global ldr_avx

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

