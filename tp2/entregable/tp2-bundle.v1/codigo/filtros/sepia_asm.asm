	section .data
DEFAULT REL
section .rodata
align 16
vectorDeCeros: 	db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
mskQuitarAlpha:	db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF
separacionHigh: db 0x08, 0x80, 0x09, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x0D, 0x80, 0x0E, 0x80, 0x80, 0x80 
separacionLow:  db 0x00, 0x80, 0x01, 0x80, 0x02, 0x80, 0x80, 0x80, 0x04, 0x80, 0x05, 0x80, 0x06, 0x80, 0x80, 0x80
reordenar:	    db 0x00, 0x01, 0x04, 0x05, 0x08, 0x09, 0x0C, 0x0D, 0x02, 0x03, 0x06, 0x07, 0x0A, 0x0B, 0x0E, 0x0F
factores:		dd 0.2, 0.3, 0.5, 0.0
vectorSaturacion: dd 0xFFFFFFFF, 0xFFFFFFFF, 0x000000FF, 0xFFFFFFFF
p1:				db 0x00, 0x04, 0x08, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
p2:				db 0x80, 0x80, 0x80, 0x80, 0x00, 0x04, 0x08, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
p3:				db 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x04, 0x08, 0x80, 0x80, 0x80, 0x80, 0x80
p4:				db 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x04, 0x08, 0x80
dejarSoloAlpha 	db 0x80, 0x80, 0x80, 0x0F, 0x80, 0x80, 0x80, 0x0B, 0x80, 0x80, 0x80, 0x07, 0x80, 0x80, 0x80, 0x03
section .text
global sepia_asm
;void sepia_c    (
    ; rdi | unsigned char *src,
    ; rsi | unsigned char *dst,
    ; edx | int filas,
    ; ecx | int cols,
    ; r8d | int src_row_size,
    ; r9d | int dst_row_size,
;)
sepia_asm:
	push rbp
	mov rbp, rsp
	push rbx
	push r15
	push r14
	push r13
	push r12


	mov r12, rdi		; r12 == puntero a los cuatro píxeles actuales de src
	mov r13, rsi 		; r13 == puntero a los cuatro píxeles actuales de dst
	mov r14d, edx		; r14d == #filas
	mov r15d, ecx		; r15d == #cols

	xor rcx, rcx
	mov ecx, r14d
	imul ecx, r15d		; ecx == #filas * #columnas
	sar ecx, 2			; divide por 4

	pxor xmm15, xmm15					; Zero register
	movdqu xmm14, [vectorDeCeros]
	movdqu xmm13, [mskQuitarAlpha]
	movdqu xmm12, [reordenar]
	movdqu xmm11, [factores]
	movdqu xmm10, [vectorSaturacion]
	movdqu xmm9, [p1]
	movdqu xmm8, [p2]
	movdqu xmm7, [p3]
	movdqu xmm6, [p4]
	movdqu xmm5, [dejarSoloAlpha]

	.ciclo:
		;Backupear
		movdqu xmm0, [r12]
		movdqa xmm1, xmm0
		movdqa xmm3, xmm0
		

		;Separar en dos y shufflear
		punpcklbw xmm1, [vectorDeCeros]					; xmm1: [  0 | a2 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		punpckhbw xmm3, [vectorDeCeros]					; xmm3: [  0 | a4 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]
		pand xmm1, [mskQuitarAlpha]						; xmm1: [  0 |  0 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		pand xmm3, [mskQuitarAlpha]						; xmm3: [  0 |  0 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]
		
		;Hacer las dos sumas horizontales
		phaddw xmm1, xmm1								; xmm1: [ r2 + g2 |    b2   | r1 + g1 |    b1   | r2 + g2 |    b2   | r1 + g1 |    b1   ]
		phaddw xmm3, xmm3								; xmm3: [ g4 + r4 |    b4   | g3 + b3 |    b3   | r4 + g4 |    b4   | r3 + g3 |    b3   ]

		phaddw xmm1, xmm1								; xmm1: [    s2   |    s1   |    s2   |    s1   |    s2   |    s1   |    s2   |    s1   ]
		phaddw xmm3, xmm3								; xmm3: [    s4   |    s3   |    s4   |    s3   |    s4   |    s3   |    s4   |    s3   ]
		

		;Separar cada uno en dos de nuevo (para convertir)

		pshufb xmm1, [reordenar]								; xmm1: [    s2   |    s2   |    s2   |    s2   |    s1   |    s1   |    s1   |    s1   ]
		pshufb xmm3, [reordenar]								; xmm3: [    s4   |    s4   |    s4   |    s4   |    s3   |    s3   |    s3   |    s3   ]

		movdqa xmm2, xmm1								; xmm2 == xmm1
		movdqa xmm4, xmm3								; xmm4 == xmm3

		punpcklwd xmm1, [vectorDeCeros]							; xmm1: [s1]
		punpckhwd xmm2, [vectorDeCeros]							; xmm2: [s2]
		punpcklwd xmm3, [vectorDeCeros]							; xmm3: [s3]
		punpckhwd xmm4, [vectorDeCeros]							; xmm1: [s4]


		;Convertir a float

		cvtdq2ps xmm1, xmm1
		cvtdq2ps xmm2, xmm2
		cvtdq2ps xmm3, xmm3
		cvtdq2ps xmm4, xmm4

		;Multiplicar por el vector

		mulps xmm1, [factores]
		mulps xmm2, [factores]
		mulps xmm3, [factores]
		mulps xmm4, [factores]

		;Reconvertir a int

		cvttps2dq xmm1, xmm1
		cvttps2dq xmm2, xmm2
		cvttps2dq xmm3, xmm3
		cvttps2dq xmm4, xmm4

		;Saturar con 255

		pminud xmm1, [vectorSaturacion]
		pminud xmm2, [vectorSaturacion]
		pminud xmm3, [vectorSaturacion]
		pminud xmm4, [vectorSaturacion]

		;Reordenar

		pshufb xmm1, [p1]
		pshufb xmm2, [p2]
		pshufb xmm3, [p3]
		pshufb xmm4, [p4]

		;Fusionar con xmm0

		pshufb xmm0, [dejarSoloAlpha]		;Dejar solo los alpha en xmm0

		pxor xmm0, xmm1
		pxor xmm0, xmm2
		pxor xmm0, xmm3
		pxor xmm0, xmm4

		;Acomodar en memoria

		movdqa [r13], xmm0

		;loop

		add r12, 16
		add r13, 16
		dec ecx
		jnz .ciclo

	;Finishing

	pop r12
	pop r13
	pop r14
	pop r15
	pop rbx
	pop rbp

	ret