
global ldr_asm

section .data

; 1/max = 1/(5*5*255*3*255) = 1/4876875 ~= 2.050493399974369e-7
align 16
LDR_MAX_INV: dd 2.050493399974369e-7, 2.050493399974369e-7, \
                2.050493399974369e-7, 2.050493399974369e-7

section .text
;void ldr_asm    (
    ; rdi | unsigned char *src,
    ; rsi | unsigned char *dst,
    ; edx | int filas,
    ; ecx | int cols,
    ; r8d | int src_row_size,
    ; r9d | int dst_row_size,
    ; bp+16 | char alpha
;)
ldr_asm:
    ; Requires SSSE3
    push rbp
    mov rbp, rsp
    push rbx
    push r15 ; Stack aligned

    ; rax = cols
    ; rdi = current pixel src
    ; rsi = current pixel dst
    ; r10 = src
    ; r11 = dst
    ; r15 = alpha
    mov rax, rcx
    mov r10, rdi
    mov r11, rsi
    movzx r15, byte [rbp+16]

    ; Do a direct copy of the first two lines
    ; Loop (4B * 2 * cols / 128b) = cols/2 times
    shr rcx, 1
    .copyUp:
        movdqu xmm0, [rdi]
        movdqu [rsi], xmm0

        add rdi, 16
        add rsi, 16
    loop .copyUp
    ; Copy the last two pixels if cols is odd
    test rax, 1
    jz .endCopyUp
        movq xmm0, [rdi]
        movq [rsi], xmm0

        add rdi, 8
        add rsi, 8
    .endCopyUp:

    ; Recorrer la imagen linealmente de a grupos de 4,
    ; manteniendo la suma de los pixeles vecinos en xmm0-4
    pxor xmm0, xmm0
    pxor xmm1, xmm1
    pxor xmm2, xmm2
    pxor xmm3, xmm3
    pxor xmm4, xmm4

    ; xmm15 is always zero
    pxor xmm15, xmm15

    ; Magic loop
    ; TODO: generar cosas para las primeras dos columnas
    ;mov rcx, ??
    .magicLoop:

        ; xmmL tiene la suma de los primeros 4 pixeles vecinos y la parte alta en 0
; |    0    |    0    |    0    |    0    |   sum3  |   sum2  |   sum1  |   sum0  | xmmL

        ; load the new pixels
        ; ->
; | A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 | xmmN
        ;movdqu xmm5, [] ; TODO
        ;movdqu xmm6, []
        ;movdqu xmm7, []
        ;movdqu xmm8, []
        ;movdqu xmm9, []

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
        psrld xmm0, 16 ; Desechar valor viejo j-2
        psrld xmm1, 16
        psrld xmm2, 16
        psrld xmm3, 16
        psrld xmm4, 16
        paddw xmm5, xmm0 ; Sumar j-1
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4
        psrld xmm0, 16 ; Desechar valor viejo j-1
        psrld xmm1, 16
        psrld xmm2, 16
        psrld xmm3, 16
        psrld xmm4, 16
        paddw xmm5, xmm0 ; Sumar j
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4
        psrld xmm0, 16 ; Desechar valor viejo j
        psrld xmm1, 16
        psrld xmm2, 16
        psrld xmm3, 16
        psrld xmm4, 16
        paddw xmm5, xmm0 ; Sumar j+1
        paddw xmm6, xmm1
        paddw xmm7, xmm2
        paddw xmm8, xmm3
        paddw xmm9, xmm4
        psrld xmm0, 16 ; Desechar valor viejo j+1
        psrld xmm1, 16
        psrld xmm2, 16
        psrld xmm3, 16
        psrld xmm4, 16
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
        pinsrw xmm6, r15w, 0
        pshuflw xmm6, xmm6, 0
        punpcklwd xmm6, xmm15
        cvtdq2ps xmm6, xmm6

        ; Expandir las sumas y, convertirlas a fp y multiplicarlas por alpha
        ; ->
;| sumargb3 * alpha. | sumargb2 * alpha. | sumargb1 * alpha. | sumargb0 * alpha. | xmm5
        punpcklwd xmm5, xmm15
        cvtdq2ps xmm5, xmm5
        mulps xmm5, xmm6

        ; Cargamos el 1/max en xmm14 en fp
        ; ->
;|      1/MAX.       |      1/MAX.       |      1/MAX.       |      1/MAX.       | xmm14
        movdqa xmm14, [LDR_MAX_INV]

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
        ;movdqu xmm9, [] ;TODO
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
        vfmadd123ps xmm5, xmm9, xmm14
        vfmadd123ps xmm6, xmm10, xmm14
        vfmadd123ps xmm7, xmm11, xmm14
        vfmadd123ps xmm8, xmm12, xmm14

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
;| R3 | G3 | B3 |  0 | R2 | G2 | B2 |  0 | R1 | G1 | B1 |  0 | R0 | G0 | B0 |  0 | xmm8
        packusdw xmm8, xmm7
        packusdw xmm6, xmm5
        packuswb xmm8, xmm6

        ; Store in the destination
        ;movdqu [], xmm9 ;TODO

        dec rcx
    jnz .magicLoop

    ; Do a direct copy of the last two lines
    ; Loop (4B * 2 * cols / 128b) = cols/2 times
    mov rcx, rax
    shr rcx, 1
    .copyDown:
        movdqu xmm0, [rdi]
        movdqu [rsi], xmm0

        add rdi, 16
        add rsi, 16
    loop .copyDown
    ; Copy the last two pixels if cols is odd
    test rax, 1
    jz .endCopyDown
        movq xmm0, [rdi]
        movq [rsi], xmm0

        add rdi, 8
        add rsi, 8
    .endCopyDown:

    pop r15
    pop rbx
    pop rbp
    ret

ldr_asm_ooo: ; Optimize for out of order operations
    push rbp
    mov rbp, rsp ; Stack aligned

    ; r10 = src, r11 = dst
    mov r10, rdi
    mov r11, rsi

    ; Do a direct copy of the first two lines
    ; Loop (4B * 2 * filas / 128b / 8) = filas/16 times
    shr rcx, 1
    .copyUp:
        ; https://stackoverflow.com/questions/1715224/very-fast-memcpy-for-image-processing
        prefetchnta [rdi+128] ; Prefetch at least 32B
        prefetchnta [rdi+160] ; TODO: Test with/without prefetchs
        prefetchnta [rdi+192]
        prefetchnta [rdi+224]

        movdqu xmm0, [rdi]
        movdqu xmm1, [rdi+16]
        movdqu xmm2, [rdi+32]
        movdqu xmm3, [rdi+48]
        movdqu xmm4, [rdi+64]
        movdqu xmm5, [rdi+80]
        movdqu xmm6, [rdi+96]
        movdqu xmm7, [rdi+112]

        movntdq [rdi], xmm0
        movntdq [rdi+16], xmm1
        movntdq [rdi+32], xmm2
        movntdq [rdi+48], xmm3
        movntdq [rdi+64], xmm4
        movntdq [rdi+80], xmm5
        movntdq [rdi+96], xmm6
        movntdq [rdi+112], xmm7

        add rdi, 128
        add rsi, 128
    loop .copyUp


    ; Loop over each line, except the first and last two
    ; rbx = lineNum
    lea rbx, [edx-4]
    .lineLoop:
        ; Do a direct copy of the first two columns
        movq xmm0, [rdi]
        movq [rsi], xmm0
        add rdi, 8
        add rsi, 8

        ; Loop over each group of 4 pixel in the column, ignoring the first and last two
        lea rcx, [rax-4]
        shr rcx, 2
        .colLoop:
            ; TODO: PSHUFB or PUNPCKHBW & mask ? (test)


            movdqu xmm4, [rdi]
            movdqu xmm6, [rdi]


            add rdi, 4
            add rsi, 4
        loop .colLoop

        ; Do a direct copy of the last two columns
        movq xmm0, [rdi]
        movq [rsi], xmm0
        add rdi, 8
        add rsi, 8

        inc ebx
        cmp ebx, edx
    jne .lineLoop



    ; Do a direct copy of the last two lines
    ; Loop (4B * 2 * filas / 128b) = filas/2 times
    shr rcx, 1
    .copyDown:
        movq xmm0, [rdi]
        movq [rsi], xmm0

        add rdi, 16
        add rsi, 16
    loop .copyDown

    pop rbp
    ret

