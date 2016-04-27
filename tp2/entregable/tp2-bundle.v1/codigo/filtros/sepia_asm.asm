	section .data
DEFAULT REL
section .rodata
separacionHigh: db 0x08, 0x80, 0x09, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x0D, 0x80, 0x0E, 0x80, 0x80, 0x80 
separacionLow:  db 0x00, 0x80, 0x01, 0x80, 0x02, 0x80, 0x80, 0x80, 0x04, 0x80, 0x05, 0x80, 0x06, 0x80, 0x80, 0x80
reordenar:	    db 0x00, 0x01, 0x04, 0x05, 0x08, 0x09, 0x0C, 0x0D, 0x02, 0x03, 0x06, 0x07, 0x0A, 0x0B, 0x0E, 0x0F
factores:		dd 0.2, 0.3, 0.5, 0.0
vectorSaturacion: dd 0xFFFFFFFF, 0xFFFFFFFF, 0x000000FF, 0xFFFFFFFF
p4:				db 0x00, 0x04, 0x08, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
p2:				db 0x80, 0x80, 0x80, 0x80, 0x00, 0x04, 0x08, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
p3:				db 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x04, 0x08, 0x80, 0x80, 0x80, 0x80, 0x80
p1:				db 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x04, 0x08, 0x80
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
	movdqu xmm14, [separacionHigh]
	movdqu xmm13, [separacionLow]
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
		movdqa xmm2, xmm0
		

		;Separar en dos y shufflear
		pshufb xmm1, xmm14					; xmm1: [ r3 |  0 | g3 |  0 | b3 |  0 |  0 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 ]
		pshufb xmm2, xmm13					; xmm2: [ r1 |  0 | g1 |  0 | b1 |  0 |  0 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 ]
		
		
		;Hacer las dos sumas horizontales
		phaddw xmm1, xmm1					; xmm1: [ g3 + r3 |    b3   | g4 + b4 |    b4   | g3 + r3 |    b3   | g4 + b4 |    b4   ]
		phaddw xmm2, xmm2					; xmm1: [ g1 + r1 |    b1   | g2 + b2 |    b2   | g1 + r1 |    b1   | g2 + b2 |    b2   ]

		phaddw xmm1, xmm1					; xmm1: [    s3   |    s4   |    s3   |    s4   |    s3   |    s4   |    s3   |    s4   ]
		phaddw xmm2, xmm2					; xmm2: [    s1   |    s2   |    s1   |    s2   |    s1   |    s2   |    s1   |    s2   ]
		

		;Separar cada uno en dos de nuevo (para convertir)

		pshufb xmm1, xmm12
		pshufb xmm2, xmm12

		movdqa xmm3, xmm1
		movdqa xmm4, xmm2

		punpckhwd xmm1, xmm15
		punpckhwd xmm2, xmm15
		punpcklwd xmm3, xmm15
		punpcklwd xmm4, xmm15


		;Convertir a float

		cvtdq2ps xmm1, xmm1
		cvtdq2ps xmm2, xmm2
		cvtdq2ps xmm3, xmm3
		cvtdq2ps xmm4, xmm4

		;Multiplicar por el vector

		mulps xmm1, xmm11
		mulps xmm2, xmm11
		mulps xmm3, xmm11
		mulps xmm4, xmm11

		;Reconvertir a int

		cvttps2dq xmm1, xmm1
		cvttps2dq xmm2, xmm2
		cvttps2dq xmm3, xmm3
		cvttps2dq xmm4, xmm4

		;Saturar con 255

		pminud xmm1, xmm10
		pminud xmm2, xmm10
		pminud xmm3, xmm10
		pminud xmm4, xmm10

		;Reordenar

		pshufb xmm1, xmm9
		pshufb xmm2, xmm8
		pshufb xmm3, xmm7
		pshufb xmm4, xmm6

		;Fusionar con xmm0

		pshufb xmm0, xmm5		;Dejar solo los alpha en xmm0

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