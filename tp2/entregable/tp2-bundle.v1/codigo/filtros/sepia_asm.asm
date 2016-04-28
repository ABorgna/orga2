section .data
DEFAULT REL

section .rodata
align 16
mskQuitarAlpha:		db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF
mskReordenar:	    db 0x00, 0x01, 0x04, 0x05, 0x08, 0x09, 0x0C, 0x0D, 0x02, 0x03, 0x06, 0x07, 0x0A, 0x0B, 0x0E, 0x0F
vectorFactores:		dd 0.2, 0.3, 0.5, 0.0
vectorSaturacion: 	dd 0xFFFFFFFF, 0xFFFFFFFF, 0x000000FF, 0xFFFFFFFF
mskDejarSoloAlpha:	db 0x80, 0x80, 0x80, 0x0F, 0x80, 0x80, 0x80, 0x0B, 0x80, 0x80, 0x80, 0x07, 0x80, 0x80, 0x80, 0x03

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


	mov r12, rdi					; r12 == puntero a los cuatro píxeles actuales de src
	mov r13, rsi 					; r13 == puntero a los cuatro píxeles actuales de dst
	mov r14d, edx					; r14d == #filas
	mov r15d, ecx					; r15d == #cols

	xor rcx, rcx
	mov ecx, r14d
	imul ecx, r15d					; ecx == #filas * #columnas
	sar ecx, 3						; divide por 8

	;Almaceno máscaras en registros

	pxor xmm5, xmm5					;Vector de ceros
	movdqa xmm6, [mskQuitarAlpha]
	movdqa xmm7, [mskReordenar]
	movdqa xmm8, [vectorFactores]
	movdqa xmm9, [mskDejarSoloAlpha]

	.ciclo:
		; Traigo el cacho de memoria a xmm0
		movdqu xmm0, [r12]
		movdqu xmm10, [r12 + 16]

		; Separo xmm0 en dos. xmmm va a tener los primeros dos píxeles y xmm3 los últimos dos.
		movdqa xmm1, xmm0
		movdqa xmm3, xmm0

		movdqa xmm11, xmm10
		movdqa xmm13, xmm10		

		; Desempaqueto para que los datos pasen de byte a word

		punpcklbw xmm1, xmm5					; xmm1: [  0 | a2 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		punpckhbw xmm3, xmm5					; xmm3: [  0 | a4 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]

		punpcklbw xmm11, xmm5					; xmm1: [  0 | a2 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		punpckhbw xmm13, xmm5					; xmm3: [  0 | a4 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]

		; Utilizo una máscara para deshacerme del alpha y poder ejecutar sumas horizontales
		pand xmm1, xmm6						; xmm1: [  0 |  0 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		pand xmm3, xmm6						; xmm3: [  0 |  0 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]

		pand xmm11, xmm6						; xmm1: [  0 |  0 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		pand xmm13, xmm6						; xmm3: [  0 |  0 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]
		
		; Hago las dos sumas horizontales
		phaddw xmm1, xmm1								; xmm1: [ r2 + g2 |    b2   | r1 + g1 |    b1   | r2 + g2 |    b2   | r1 + g1 |    b1   ]
		phaddw xmm3, xmm3								; xmm3: [ g4 + r4 |    b4   | g3 + b3 |    b3   | r4 + g4 |    b4   | r3 + g3 |    b3   ]

		phaddw xmm11, xmm11								; xmm1: [ r2 + g2 |    b2   | r1 + g1 |    b1   | r2 + g2 |    b2   | r1 + g1 |    b1   ]
		phaddw xmm13, xmm13								; xmm3: [ g4 + r4 |    b4   | g3 + b3 |    b3   | r4 + g4 |    b4   | r3 + g3 |    b3   ]

		phaddw xmm1, xmm1								; xmm1: [    s2   |    s1   |    s2   |    s1   |    s2   |    s1   |    s2   |    s1   ]
		phaddw xmm3, xmm3								; xmm3: [    s4   |    s3   |    s4   |    s3   |    s4   |    s3   |    s4   |    s3   ]
		
		phaddw xmm11, xmm11								; xmm1: [    s2   |    s1   |    s2   |    s1   |    s2   |    s1   |    s2   |    s1   ]
		phaddw xmm13, xmm13								; xmm3: [    s4   |    s3   |    s4   |    s3   |    s4   |    s3   |    s4   |    s3   ]

		; Reordeno los datos de forma tal que las mismas sumas queden una al lado de la otra

		pshufb xmm1, xmm7						; xmm1: [    s2   |    s2   |    s2   |    s2   |    s1   |    s1   |    s1   |    s1   ]
		pshufb xmm3, xmm7						; xmm3: [    s4   |    s4   |    s4   |    s4   |    s3   |    s3   |    s3   |    s3   ]

		pshufb xmm11, xmm7						; xmm1: [    s2   |    s2   |    s2   |    s2   |    s1   |    s1   |    s1   |    s1   ]
		pshufb xmm13, xmm7						; xmm3: [    s4   |    s4   |    s4   |    s4   |    s3   |    s3   |    s3   |    s3   ]

		; Vuelvo a separar en dos. Cada registro contiene cuatro veces su respectiva suma en forma de doubleword

		movdqa xmm2, xmm1								; xmm2 == xmm1
		movdqa xmm4, xmm3								; xmm4 == xmm3

		movdqa xmm12, xmm11								; xmm2 == xmm1
		movdqa xmm14, xmm13								; xmm4 == xmm3

		punpcklwd xmm1, xmm5					; xmm1: [		  s1  		|		  s1		|		  s1		|		  s1		]
		punpckhwd xmm2, xmm5					; xmm2: [		  s2  		|		  s2		|		  s2		|		  s2		]
		punpcklwd xmm3, xmm5					; xmm3: [		  s3  		|		  s3		|		  s3		|		  s3		]
		punpckhwd xmm4, xmm5					; xmm1: [		  s4  		|		  s4		|		  s4		|		  s4		]

		punpcklwd xmm11, xmm5					; xmm1: [		  s1  		|		  s1		|		  s1		|		  s1		]
		punpckhwd xmm12, xmm5					; xmm2: [		  s2  		|		  s2		|		  s2		|		  s2		]
		punpcklwd xmm13, xmm5					; xmm3: [		  s3  		|		  s3		|		  s3		|		  s3		]
		punpckhwd xmm14, xmm5					; xmm1: [		  s4  		|		  s4		|		  s4		|		  s4		]


		; Convierto cada uno a float

		cvtdq2ps xmm1, xmm1
		cvtdq2ps xmm2, xmm2
		cvtdq2ps xmm3, xmm3
		cvtdq2ps xmm4, xmm4

		cvtdq2ps xmm11, xmm11
		cvtdq2ps xmm12, xmm12
		cvtdq2ps xmm13, xmm13
		cvtdq2ps xmm14, xmm14

		; Ejecuto una multiplicación empaquetada para conseguir las componentes adecuadas correspondientes a aplicar el filtro

		mulps xmm1, xmm8
		mulps xmm2, xmm8
		mulps xmm3, xmm8
		mulps xmm4, xmm8

		mulps xmm11, xmm8
		mulps xmm12, xmm8
		mulps xmm13, xmm8
		mulps xmm14, xmm8

		; Reconvierto a int

		cvttps2dq xmm1, xmm1
		cvttps2dq xmm2, xmm2
		cvttps2dq xmm3, xmm3
		cvttps2dq xmm4, xmm4

		cvttps2dq xmm11, xmm11
		cvttps2dq xmm12, xmm12
		cvttps2dq xmm13, xmm13
		cvttps2dq xmm14, xmm14

		; Empaqueto los datos saturando con 255 en el caso de la componente roja

		packusdw xmm1, xmm2
		packusdw xmm3, xmm4

		packusdw xmm11, xmm12
		packusdw xmm13, xmm14
		
		packuswb xmm1, xmm3

		packuswb xmm11, xmm13

		; Fusiono con xmm0

		pand xmm0, xmm9		;Dejar solo los alpha en xmm0

		pand xmm10, xmm9		;Dejar solo los alpha en xmm0

		pxor xmm0, xmm1

		pxor xmm10, xmm11

		; Acomodo de vuelta en memoria

		movdqa [r13], xmm0

		movdqa [r13 + 16], xmm10

		;loop

		add r12, 32
		add r13, 32
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