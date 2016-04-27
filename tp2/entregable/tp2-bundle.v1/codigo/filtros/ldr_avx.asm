
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
    ; edx | int cols,
    ; ecx | int filas,
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
    mov rax, rdx
    mov rdx, rcx
    mov r8, rdi
    mov r9, rsi
    movsx r10, word [rbp+16]
    mov rsi, r8
    mov rdi, r9

    ; Recorrer la imagen linealmente de a grupos de 4,
    ; manteniendo la suma de los pixeles vecinos en xmm0-4
    ; xmm15 is always zero
    vzeroall

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
        vmovdqu xmm5, [rsi+r12+8]
        vmovdqu xmm6, [rsi+r13+8]
        vmovdqu xmm7, [rsi+8]
        vmovdqu xmm8, [rsi+r14+8]
        vmovdqu xmm9, [rsi+r15+8]

        ; shift to clear the alpha bits
        ; ->
; | R7 | G7 | B7 |  0 | R6 | G6 | B6 |  0 | R5 | G5 | B5 |  0 | R4 | G4 | B4 |  0 | xmmN
        vpslld xmm5, 8
        vpslld xmm6, 8
        vpslld xmm7, 8
        vpslld xmm8, 8
        vpslld xmm9, 8

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
;| R7+G7+B7| R6+G6+B6| R5+G5+B5| R4+G4+B4|    0    |    0    |    0    |    0     | xmm{N+5}
        ; ==
;|   sum7  |   sum6  |   sum5  |   sum4  |    0    |    0    |    0    |    0     | xmm{N+5}
        vpxor xmm10, xmm10, xmm10
        vpxor xmm11, xmm11, xmm11
        vpxor xmm12, xmm12, xmm12
        vpxor xmm13, xmm13, xmm13
        vpxor xmm14, xmm14, xmm14
        vphaddw xmm10, xmm10, xmm5
        vphaddw xmm11, xmm11, xmm6
        vphaddw xmm12, xmm12, xmm7
        vphaddw xmm13, xmm13, xmm8
        vphaddw xmm14, xmm14, xmm9

        ; Reducir todas las sumargb_i a una unica sumargb
        ; ->
;|sum_col7 |sum_col6 |sum_col5 |sum_col4 |    0    |    0    |    0    |    0     | xmm10
        vpaddw xmm13, xmm13, xmm14
        vpaddw xmm10, xmm10, xmm11
        vpaddw xmm12, xmm12, xmm13
        vpaddw xmm10, xmm10, xmm12

        ; Save the sums in xmm0
        ; ->
;|sum_col7 |sum_col6 |sum_col5 |sum_col4 |sum_col3 |sum_col2 |sum_col1 |sum_col0 | xmm0
        vpor xmm0, xmm0, xmm10

        ; Calcular sumargb para cada uno de los 4 pixeles que vamos a procesar
        ; En el proceso vamos eliminando las sumas de pixeles viejos y dejamos xmm0
        ; listo para la siguiente vuelta
        ; ->
;|    X    |    X    |    X    |    X    |sumargb3 |sumargb2 |sumargb1 |sumargb0 | xmm5
;|    0    |    0    |    0    |    0    |sum_col7 |sum_col6 |sum_col5 |sum_col4 | xmm0
        vmovdqa xmm5, xmm0 ; Mover valor inicial, j-2
        vpsrldq xmm0, xmm0, 2 ; Desechar valor viejo j-2
        vpaddw xmm5, xmm5, xmm0 ; Sumar j-1
        vpsrldq xmm0, xmm0, 2 ; Desechar valor viejo j-1
        vpaddw xmm5, xmm5, xmm0 ; Sumar j
        vpsrldq xmm0, xmm0, 2 ; Desechar valor viejo j
        vpaddw xmm5, xmm5, xmm0 ; Sumar j+1
        vpsrldq xmm0, xmm0, 2 ; Desechar valor viejo j+1
        vpaddw xmm5, xmm5, xmm0 ; Sumar j+2

        ; Cargar alpha en xmm6 por cuadriplicado en fp
        ; ->
;|       alpha.      |       alpha.      |       alpha.      |       alpha.      | xmm6
        vpxor xmm6, xmm6, xmm6
        movq2dq xmm6, mm2
        vmovddup xmm6, xmm6

        ; Expandir las sumas, convertirlas a fp y multiplicarlas por alpha
        ; ->
;| sumargb3 * alpha. | sumargb2 * alpha. | sumargb1 * alpha. | sumargb0 * alpha. | xmm5
        vpunpcklwd xmm5, xmm5, xmm15
        vcvtdq2ps xmm5, xmm5
        vmulps xmm5, xmm5, xmm6

        ; Movemos las sumas cada una replicada en un vector
        ; ->
;| sumargb3 * alpha. | sumargb3 * alpha. | sumargb3 * alpha. | sumargb3 * alpha. | xmm5
;| sumargb2 * alpha. | sumargb2 * alpha. | sumargb2 * alpha. | sumargb2 * alpha. | xmm6
;| sumargb1 * alpha. | sumargb1 * alpha. | sumargb1 * alpha. | sumargb1 * alpha. | xmm7
;| sumargb0 * alpha. | sumargb0 * alpha. | sumargb0 * alpha. | sumargb0 * alpha. | xmm8
        vpshufd xmm8, xmm5, 0b00000000
        vpshufd xmm7, xmm5, 0b01010101
        vpshufd xmm6, xmm5, 0b10101010
        vpshufd xmm5, xmm5, 0b11111111

        ; Cargar los valores de los pixeles, unpackearlos a dw y pasarlos a float
        ; ->
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | xmm9
        movdqu xmm9, [rsi]
        ; ->
;|    A3   |    R3   |    G3   |   B3    |    A2   |    R2   |    G2   |   B2    | xmm9
;|    A1   |    R1   |    G1   |   B1    |    A0   |    R0   |    G0   |   B0    | xmm11
        vpunpcklbw xmm11, xmm9, xmm15
        vpunpckhbw xmm9, xmm9, xmm15
        ; ->
;|        A3         |         R3        |         G3        |         B3        | xmm9
;|        A2         |         R2        |         G2        |         B2        | xmm10
;|        A1         |         R1        |         G1        |         B1        | xmm11
;|        A0         |         R0        |         G0        |         B0        | xmm12
        vpunpcklwd xmm10, xmm9, xmm15
        vpunpckhwd xmm9, xmm9, xmm15
        vpunpcklwd xmm12, xmm11, xmm15
        vpunpckhwd xmm11, xmm11, xmm15
        ; ->
;|        A3.        |         R3.       |         G3.       |         B3.       | xmm9
;|        A2.        |         R2.       |         G2.       |         B2.       | xmm10
;|        A1.        |         R1.       |         G1.       |         B1.       | xmm11
;|        A0.        |         R0.       |         G0.       |         B0.       | xmm12
        vcvtdq2ps xmm9, xmm9
        vcvtdq2ps xmm10, xmm10
        vcvtdq2ps xmm11, xmm11
        vcvtdq2ps xmm12, xmm12

        ; Cargar una mascara para borrar el canal alpha
        ; ->
;|         0         |    0xffffffff     |    0xffffffff     |    0xffffffff     | xmm13
        vpxor xmm13, xmm13, xmm13 ; clean dependencies
        vpcmpeqq xmm13, xmm13, xmm13
        vpsrldq xmm13, xmm13, 4

        ; Multiplicamos cada valor de cada pixel por sumargb*alpha
        ; y borramos el canal alpha
        ; ->
;|         0.        | R3*sumargb3*alpha.| G3*sumargb3*alpha.| B3*sumargb3*alpha.| xmm5
;|         0.        | R2*sumargb2*alpha.| G2*sumargb2*alpha.| B2*sumargb2*alpha.| xmm6
;|         0.        | R1*sumargb1*alpha.| G1*sumargb1*alpha.| B1*sumargb1*alpha.| xmm7
;|         0.        | R0*sumargb0*alpha.| G0*sumargb0*alpha.| B0*sumargb0*alpha.| xmm8
        vmulps xmm5, xmm5, xmm9
        vmulps xmm6, xmm6, xmm10
        vmulps xmm7, xmm7, xmm11
        vmulps xmm8, xmm8, xmm12
        vpand xmm5, xmm5, xmm13
        vpand xmm6, xmm6, xmm13
        vpand xmm7, xmm7, xmm13
        vpand xmm8, xmm8, xmm13


        ; Cargamos el 1/max en xmm14 en fp
        ; ->
;|      1/MAX.       |      1/MAX.       |      1/MAX.       |      1/MAX.       | xmm14
        vpxor xmm14, xmm14, xmm14
        movq2dq xmm14, mm0
        vmovddup xmm14, xmm14

        ; Dividir por MAX y sumarle el valor original de cada pixel
        ; ->
;|        A3.        |       ldrR3.      |       ldrG3.      |       ldrB3.      | xmm5
;|        A2.        |       ldrR2.      |       ldrG2.      |       ldrB2.      | xmm6
;|        A1.        |       ldrR1.      |       ldrG1.      |       ldrB1.      | xmm7
;|        A0.        |       ldrR0.      |       ldrG0.      |       ldrB0.      | xmm8
        vfmadd132ps xmm5, xmm9, xmm14
        vfmadd132ps xmm6, xmm10, xmm14
        vfmadd132ps xmm7, xmm11, xmm14
        vfmadd132ps xmm8, xmm12, xmm14

        ; Cargamos 255 para aplicar max/min
        ; ->
;|       255.        |       255.        |       255.        |       255.        | xmm13
        vpxor xmm13, xmm13, xmm13
        movq2dq xmm13, mm1
        vmovddup xmm13, xmm13

        ; Aplicar min(max(xmmN,0.),255.)
        vmaxps xmm5, xmm5, xmm15
        vmaxps xmm6, xmm6, xmm15
        vmaxps xmm7, xmm7, xmm15
        vmaxps xmm8, xmm8, xmm15
        vminps xmm5, xmm5, xmm13
        vminps xmm6, xmm6, xmm13
        vminps xmm7, xmm7, xmm13
        vminps xmm8, xmm8, xmm13

        ; Convert the numbers back to integers
        ; ->
;|       ldrR3       |       ldrG3       |       ldrB3       |         0         | xmm5
;|       ldrR2       |       ldrG2       |       ldrB2       |         0         | xmm6
;|       ldrR1       |       ldrG1       |       ldrB1       |         0         | xmm7
;|       ldrR0       |       ldrG0       |       ldrB0       |         0         | xmm8
        vcvtps2dq xmm5, xmm5
        vcvtps2dq xmm6, xmm6
        vcvtps2dq xmm7, xmm7
        vcvtps2dq xmm8, xmm8

        ; Pack the results into a single line again
        ; ->
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | xmm8
        vpackusdw xmm8, xmm8, xmm7
        vpackusdw xmm6, xmm6, xmm5
        vpackuswb xmm8, xmm8, xmm6

        .continue:

        ; Store in the destination
        vmovdqu [rdi], xmm8

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


