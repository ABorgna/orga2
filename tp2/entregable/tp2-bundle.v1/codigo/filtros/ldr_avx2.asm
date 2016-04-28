
extern copyN
extern copyN_sse
extern copyN_avx2

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
; Reverse the first words of the upper part of a ymm register
; and clear the rest
align 16
MASK_REV_UPPER_FIRSTS_W: dq 0x0706050403020100, 0x0F0E0D0C0B0A0908, \
                            0x0100030205040706, 0xFFFFFFFFFFFFFFFF

section .text

;void ldr_avx    (
    ; rdi | unsigned char *src,
    ; rsi | unsigned char *dst,
    ; edx | int cols,
    ; ecx | int filas,
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
    mov rax, rdx
    mov rdx, rcx
    mov r8, rdi
    mov r9, rsi
    movsx r10, word [rbp+16]
    mov rsi, r8
    mov rdi, r9

    ; Recorrer la imagen linealmente de a grupos de 4,
    ; manteniendo la suma de los pixeles vecinos en ymm0-4
    ; ymm15 is always zero
    vzeroall

    ; mm0 = |   LDR_MAX_MAGIC.  |   LDR_MAX_MAGIC   |
    ; mm1 = |        255.       |        255        |
    ; mm2 = |       alpha.      |       alpha.      |
    movq mm0, [LDR_MAX_INV]
    movq mm1, [PIXEL_MAX_F]
    pinsrd xmm6, r10d, 0
    pinsrd xmm6, r10d, 1
    vcvtdq2ps xmm6, xmm6
    movdq2q mm2, xmm6

    ; Empezamos a procesar desde fila2 - 8px
    lea rsi, [r8 + r15 - 32]
    lea rdi, [r9 + r15 - 32]

    ; Magic loop, correr sobre ((filas-4)*cols+8)/8
    lea rcx, [rdx-4]    ; rcx = filas-4
    imul rcx, rax       ; rcx = (filas-4)*cols
    add rcx, 8          ; rcx = (filas-4)*cols+8
    shr rcx, 3          ; rcx = ((filas-4)*cols+8)/8

    .magicLoop:

        ; ymm0 tiene la suma de los primeros 8 pixeles vecinos y tod0 lo demas en 0
;|    0    |    0    |    0    |    0    |    0    |    0    |    0    |    0    |...
;|sum_col7 |sum_col6 |sum_col5 |sum_col4 |sum_col3 |sum_col2 |sum_col1 |sum_col0 | ymm0

        ; load the new pixels
        ; ->
;| AF | RF | GF | BF | AE | RE | GE | BE | AD | RD | GD | BD | AC | RC | GC | BC |...
;| AB | RB | GB | BB | AA | RA | GA | BA | A9 | R9 | G9 | B9 | A8 | R8 | G8 | B8 | ymmN
        vmovdqu ymm5, [rsi+r12+24]
        vmovdqu ymm6, [rsi+r13+24]
        vmovdqu ymm7, [rsi+24]
        vmovdqu ymm8, [rsi+r14+24]
        vmovdqu ymm9, [rsi+r15+24]

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
;| RF+GF+BF| RE+GE+BE| RD+GD+BD| RC+GC+BC|    0    |    0    |    0    |    0    |...
;| RB+GB+BB| RA+GA+BA| R9+G9+B9| R8+G8+B8|    0    |    0    |    0    |    0    | ymmN
        vphaddw ymm5, ymm15, ymm5
        vphaddw ymm6, ymm15, ymm6
        vphaddw ymm7, ymm15, ymm7
        vphaddw ymm8, ymm15, ymm8
        vphaddw ymm9, ymm15, ymm9
        ; ->
;| RF+GF+BF| RE+GE+BE| RD+GD+BD| RC+GC+BC| RB+GB+BB| RA+GA+BA| R9+G9+B9| R8+G8+B8|...
;|    0    |    0    |    0    |    0    |    0    |    0    |    0    |    0    | ymmN
        vpermq ymm5, ymm5, 0b11010000
        vpermq ymm6, ymm6, 0b11010000
        vpermq ymm7, ymm7, 0b11010000
        vpermq ymm8, ymm8, 0b11010000
        vpermq ymm9, ymm9, 0b11010000

        ; Reducir todas las sumargb_i a una unica sumargb
        ; ->
;|sum_colF |sum_colE |sum_colD |sum_colC |sum_colB |sum_colA |sum_col9 |sum_col8 |...
;|    0    |    0    |    0    |    0    |    0    |    0    |    0    |    0    | xmm5
        vpaddw ymm8, ymm8, ymm9
        vpaddw ymm6, ymm6, ymm7
        vpaddw ymm6, ymm6, ymm8
        vpaddw ymm5, ymm6, ymm5

        ; Save the sums in ymm0
        ; ->
;|sum_colF |sum_colE |sum_colD |sum_colC |sum_colB |sum_colA |sum_col9 |sum_col8 |...
;|sum_col7 |sum_col6 |sum_col5 |sum_col4 |sum_col3 |sum_col2 |sum_col1 |sum_col0 | ymm0
        vpor ymm0, ymm0, ymm5

        ; Hacer una copia de las sumas con la primer mitad de la parte alta invertida
        ; y la otra limpia
        ; Guardar la mascara en ymm2
        ; ->
;|    0    |    0    |    0    |    0    |sum_col8 |sum_col9 |sum_colB |sum_colA |...
;|sum_col7 |sum_col6 |sum_col5 |sum_col4 |sum_col3 |sum_col2 |sum_col1 |sum_col0 | ymm1
        vmovdqa ymm2, [MASK_REV_UPPER_FIRSTS_W]
        vpshufb ymm1, ymm0, ymm2

        ; Calcular sumargbl para cada uno de los 8 pixeles que vamos a procesar
        ; Dejamos xmm0 listo para la siguiente vuelta
        ; ->
;|    0    |    0    |    0    |    0    |  sum4_1 |  sum5_1 |  sum6_1 |  sum7_1 |...
;|  sum7_0 |  sum6_0 |  sum5_0 |  sum4_0 |  sum3   |  sum2   |  sum1   |  sum0   | ymm5
        vmovdqa ymm5, ymm1 ; Mover valor inicial, j-2
        vpsrldq ymm1, ymm1, 2 ; Desechar valor viejo j-2
        vpaddw ymm5, ymm5, ymm1 ; Sumar j-1
        vpsrldq ymm1, ymm1, 2 ; Desechar valor viejo j-1
        vpaddw ymm5, ymm5, ymm1 ; Sumar j
        vpsrldq ymm1, ymm1, 2 ; Desechar valor viejo j
        vpaddw ymm5, ymm5, ymm1 ; Sumar j+1
        vpsrldq ymm1, ymm1, 2 ; Desechar valor viejo j+1
        vpaddw ymm5, ymm5, ymm1 ; Sumar j+2
        ; Invertir la parte alta de la suma parcial y sacar el resultado final
        ; ->
;|    X    |    X    |    X    |    X    |sumargb7n|sumargb6n|sumargb5n|sumargb4n|...
;|    X    |    X    |    X    |    X    |sumargb3n|sumargb2n|sumargb1n|sumargb0n| ymm5
        vpshufb ymm1, ymm5, ymm2
        vpermq ymm5, ymm5, 0b11011111
        vpaddw ymm5, ymm5, ymm1

        ; Dejamos xmm0 listo para la siguiente vuelta
        ; ->
;|    0    |    0    |    0    |    0    |    0    |    0    |    0    |    0    |...
;|sum_colF |sum_colE |sum_colD |sum_colC |sum_colB |sum_colA |sum_col9 |sum_col8 | ymm0
        vpermq ymm0, ymm0, 0b01001110
        vmovdqa xmm0, xmm0 ; Clear upper half

        ; Cargar alpha en ymm6 ocho veces en fp
        ; ->
;|       alpha.      |       alpha.      |       alpha.      |       alpha.      |...
;|       alpha.      |       alpha.      |       alpha.      |       alpha.      | ymm6
        vpxor ymm6, ymm6, ymm6
        movq2dq xmm6, mm2
        vbroadcastss ymm6, xmm6

        ; Expandir las sumas, convertirlas a fp y multiplicarlas por alpha
        ; ->
;| sumargb7 * alpha. | sumargb6 * alpha. | sumargb5 * alpha. | sumargb4 * alpha. |...
;| sumargb3 * alpha. | sumargb2 * alpha. | sumargb1 * alpha. | sumargb0 * alpha. | ymm5
        vpunpcklwd ymm5, ymm5, ymm15
        vcvtdq2ps ymm5, ymm5
        vmulps ymm5, ymm5, ymm6

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
;| A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 |...
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | ymm9
        vmovdqu ymm9, [rsi]

        ; Separar los valores de cada pixel, mandarlos a double word, convertirlos a fp
        ; ->
;|    A7   |    R7   |    G7   |   B7    |    A6   |    R6   |    G6   |   B6    |...
;|    A3   |    R3   |    G3   |   B3    |    A2   |    R2   |    G2   |   B2    | xmm9
        ; &
;|    A5   |    R5   |    G5   |   B5    |    A4   |    R4   |    G4   |   B4    |...
;|    A1   |    R1   |    G1   |   B1    |    A0   |    R0   |    G0   |   B0    | xmm11
        vpunpcklbw ymm11, ymm9, ymm15
        vpunpckhbw ymm9, ymm9, ymm15
        ; ->
;|        A7.        |         R7.       |         G7.       |         B7.       |...
;|        A3.        |         R3.       |         G3.       |         B3.       | xmm9
                            ; &
;|        A6.        |         R6.       |         G6.       |         B6.       |...
;|        A2.        |         R2.       |         G2.       |         B2.       | xmm10
                            ; &
;|        A5.        |         R5.       |         G5.       |         B5.       |...
;|        A1.        |         R1.       |         G1.       |         B1.       | xmm11
                            ; &
;|        A4.        |         R4.       |         G4.       |         B4.       |
;|        A0.        |         R0.       |         G0.       |         B0.       | xmm12
        vpunpcklwd ymm10, ymm9, ymm15
        vpunpckhwd ymm9, ymm9, ymm15
        vpunpcklwd ymm12, ymm11, ymm15
        vpunpckhwd ymm11, ymm11, ymm15
        vcvtdq2ps ymm9, ymm9
        vcvtdq2ps ymm10, ymm10
        vcvtdq2ps ymm11, ymm11
        vcvtdq2ps ymm12, ymm12

        ; Cargar una mascara para borrar el canal alpha
        ; ->
;|         0         |    0xffffffff     |    0xffffffff     |    0xffffffff     |...
;|         0         |    0xffffffff     |    0xffffffff     |    0xffffffff     | ymm13
        vpxor ymm13, ymm13, ymm13 ; clean dependencies
        vpcmpeqq ymm13, ymm13, ymm13
        vpsrldq ymm13, ymm13, 4

        ; Multiplicamos cada valor de cada pixel por sumargb*alpha
        ; ->
;|         0.        | R7*sumargb7*alpha.| G7*sumargb7*alpha.| B7*sumargb7*alpha.|...
;|         0.        | R3*sumargb3*alpha.| G3*sumargb3*alpha.| B3*sumargb3*alpha.| xmm5
        ;&
;|         0.        | R6*sumargb6*alpha.| G6*sumargb6*alpha.| B6*sumargb6*alpha.|...
;|         0.        | R2*sumargb2*alpha.| G2*sumargb2*alpha.| B2*sumargb2*alpha.| xmm6
        ;&
;|         0.        | R5*sumargb5*alpha.| G5*sumargb5*alpha.| B5*sumargb5*alpha.|...
;|         0.        | R1*sumargb1*alpha.| G1*sumargb1*alpha.| B1*sumargb1*alpha.| xmm7
        ;&
;|         0.        | R4*sumargb4*alpha.| G4*sumargb4*alpha.| B4*sumargb4*alpha.|...
;|         0.        | R0*sumargb0*alpha.| G0*sumargb0*alpha.| B0*sumargb0*alpha.| xmm8
        vmulps ymm5, ymm5, ymm9
        vmulps ymm6, ymm6, ymm10
        vmulps ymm7, ymm7, ymm11
        vmulps ymm8, ymm8, ymm12
        vpand ymm5, ymm5, ymm13
        vpand ymm6, ymm6, ymm13
        vpand ymm7, ymm7, ymm13
        vpand ymm8, ymm8, ymm13

        ; Cargamos el 1/max en ymm14 en fp
        ; ->
;|      1/MAX.       |      1/MAX.       |      1/MAX.       |      1/MAX.       |...
;|      1/MAX.       |      1/MAX.       |      1/MAX.       |      1/MAX.       | ymm14
        vpxor ymm14, ymm14, ymm14
        movq2dq xmm14, mm0
        vbroadcastss ymm14, xmm14

        ; Dividir por MAX y sumarle el valor original de cada pixel
        ; ->
;|        A7.        |       ldrR7.      |       ldrG7.      |       ldrB7.      |...
;|        A3.        |       ldrR3.      |       ldrG3.      |       ldrB3.      | ymm5
        ; &
;|        A6.        |       ldrR6.      |       ldrG6.      |       ldrB6.      |...
;|        A2.        |       ldrR2.      |       ldrG2.      |       ldrB2.      | ymm6
        ; &
;|        A5.        |       ldrR5.      |       ldrG5.      |       ldrB5.      |...
;|        A1.        |       ldrR1.      |       ldrG1.      |       ldrB1.      | ymm7
        ; &
;|        A4.        |       ldrR4.      |       ldrG4.      |       ldrB4.      |...
;|        A0.        |       ldrR0.      |       ldrG0.      |       ldrB0.      | ymm8
        vfmadd132ps ymm5, ymm9, ymm14
        vfmadd132ps ymm6, ymm10, ymm14
        vfmadd132ps ymm7, ymm11, ymm14
        vfmadd132ps ymm8, ymm12, ymm14

        ; Cargamos 255 para aplicar max/min
        ; ->
;|       255.        |       255.        |       255.        |       255.        |...
;|       255.        |       255.        |       255.        |       255.        | ymm13
        vpxor ymm13, ymm13, ymm13
        movq2dq xmm13, mm1
        vbroadcastss ymm13, xmm13

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
;|        A7         |       ldrR7       |       ldrG7       |       ldrB7       |...
;|        A3         |       ldrR3       |       ldrG3       |       ldrB3       | ymm5
        ; &
;|        A6         |       ldrR6       |       ldrG6       |       ldrB6       |...
;|        A2         |       ldrR2       |       ldrG2       |       ldrB2       | ymm6
        ; &
;|        A5         |       ldrR5       |       ldrG5       |       ldrB5       |...
;|        A1         |       ldrR1       |       ldrG1       |       ldrB1       | ymm7
        ; &
;|        A4         |       ldrR4       |       ldrG4       |       ldrB4       |...
;|        A0         |       ldrR0       |       ldrG0       |       ldrB0       | ymm8
        vcvtps2dq ymm5, ymm5
        vcvtps2dq ymm6, ymm6
        vcvtps2dq ymm7, ymm7
        vcvtps2dq ymm8, ymm8

        ; Pack the results into a single line again
        ; ->
;|    A7   |    R7   |    G7   |   B7    |    A6   |    R6   |    G6   |   B6    |...
;|    A3   |    R3   |    G3   |   B3    |    A2   |    R2   |    G2   |   B2    | xmm9
        ; &
;|    A5   |    R5   |    G5   |   B5    |    A4   |    R4   |    G4   |   B4    |...
;|    A1   |    R1   |    G1   |   B1    |    A0   |    R0   |    G0   |   B0    | xmm11
        vpackusdw ymm8, ymm8, ymm7
        vpackusdw ymm6, ymm6, ymm5
        ; ->
;| A7 | R7 | G7 | B7 | A6 | R6 | G6 | B6 | A5 | R5 | G5 | B5 | A4 | R4 | G4 | B4 |...
;| A3 | R3 | G3 | B3 | A2 | R2 | G2 | B2 | A1 | R1 | G1 | B1 | A0 | R0 | G0 | B0 | ymm9
        vpackuswb ymm8, ymm8, ymm6

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

