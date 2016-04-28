section .data
DEFAULT REL

section .rodata
align 16
mskDejarSoloAlpha:	db 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF
mskQuitarAlpha:		db 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0x00
mskReordenar:	    db 0x00, 0x01, 0x04, 0x05, 0x08, 0x09, 0x0C, 0x0D, 0x02, 0x03, 0x06, 0x07, 0x0A, 0x0B, 0x0E, 0x0F
vectorFactores:		dd 0.2, 0.3, 0.5, 0.0
vectorSaturacion: 	dd 0xFFFFFFFF, 0xFFFFFFFF, 0x000000FF, 0xFFFFFFFF

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

	imul ecx, edx								; ecx == #filas * #columnas
	sar ecx, 3									; divide por 8

	;Almaceno máscaras en registros

	pxor xmm5, xmm5								;Vector de ceros
	movdqa xmm6, [mskQuitarAlpha]
	movdqa xmm7, [mskReordenar]
	movdqa xmm8, [vectorFactores]
	movdqa xmm9, [mskDejarSoloAlpha]

	.ciclo:
		; Traigo el cacho de memoria a xmm0 y xmm10

		movdqu xmm0, [rdi]						; xmm0:  [ a4 | r4 | g4 | b4 | a3 | r3 | g3 | b3 | a2 | r2 | g2 | b2 | a1 | r1 | g1 | b1 ]
		movdqu xmm10, [rdi + 16]				; xmm11: [ a8 | r8 | g8 | b8 | a7 | r7 | g7 | b7 | a6 | r6 | g6 | b6 | a5 | r5 | g5 | b5 ]

		; Separo en dos para poder desempaquetar y les quito el alpha

		movdqa xmm1, xmm0 						; xmm1 == xmm0
		pand xmm1, xmm6							; xmm1:  [  0 | r4 | g4 | b4 |  0 | r3 | g3 | b3 |  0 | r2 | g2 | b2 |  0 | r1 | g1 | b1 ]
		movdqa xmm3, xmm1 						; xmm3 == xmm1

		movdqa xmm11, xmm10 					; xmm11 == xmm10
		pand xmm11, xmm6						; xmm11: [  0 | r8 | g8 | b8 |  0 | r7 | g7 | b7 |  0 | r6 | g6 | b6 |  0 | r5 | g5 | b5 ]
		movdqa xmm13, xmm11		 				; xmm13 == xmm11

		; Desempaqueto para que los datos pasen de byte a word

		punpcklbw xmm1, xmm5					; xmm1:  [  0 |  0 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		punpckhbw xmm3, xmm5					; xmm3:  [  0 |  0 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]

		punpcklbw xmm11, xmm5					; xmm11: [  0 |  0 |  0 | r6 |  0 | g6 |  0 | b6 |  0 |  0 |  0 | r5 |  0 | g5 |  0 | b5 ]
		punpckhbw xmm13, xmm5					; xmm13: [  0 |  0 |  0 | r8 |  0 | g8 |  0 | b8 |  0 |  0 |  0 | r7 |  0 | g7 |  0 | b7 ]

		; Hago las dos sumas horizontales

		phaddw xmm1, xmm1						; xmm1:  [ r2 + g2 |    b2   | r1 + g1 |    b1   | r2 + g2 |    b2   | r1 + g1 |    b1   ]
		phaddw xmm3, xmm3						; xmm3:  [ g4 + r4 |    b4   | g3 + b3 |    b3   | r4 + g4 |    b4   | r3 + g3 |    b3   ]

		phaddw xmm11, xmm11						; xmm11: [ r6 + g6 |    b6   | r5 + g5 |    b5   | r6 + g6 |    b6   | r5 + g5 |    b5   ]
		phaddw xmm13, xmm13						; xmm13: [ g8 + r8 |    b8   | g7 + b7 |    b7   | r8 + g8 |    b8   | r7 + g7 |    b7   ]

		phaddw xmm1, xmm1						; xmm1:  [    s2   |    s1   |    s2   |    s1   |    s2   |    s1   |    s2   |    s1   ]
		phaddw xmm3, xmm3						; xmm3:  [    s4   |    s3   |    s4   |    s3   |    s4   |    s3   |    s4   |    s3   ]
		
		phaddw xmm11, xmm11						; xmm11: [    s6   |    s5   |    s6   |    s5   |    s6   |    s5   |    s6   |    s5   ]
		phaddw xmm13, xmm13						; xmm13: [    s8   |    s7   |    s8   |    s7   |    s8   |    s7   |    s8   |    s7   ]

		; Reordeno los datos de forma tal que las mismas sumas queden una al lado de la otra

		pshufb xmm1, xmm7						; xmm1:  [    s2   |    s2   |    s2   |    s2   |    s1   |    s1   |    s1   |    s1   ]
		pshufb xmm3, xmm7						; xmm3:  [    s4   |    s4   |    s4   |    s4   |    s3   |    s3   |    s3   |    s3   ]

		pshufb xmm11, xmm7						; xmm11: [    s6   |    s6   |    s6   |    s6   |    s5   |    s5   |    s5   |    s5   ]
		pshufb xmm13, xmm7						; xmm13: [    s8   |    s8   |    s8   |    s8   |    s7   |    s7   |    s7   |    s7   ]

		; Vuelvo a separar en dos. Cada registro contiene cuatro veces su respectiva suma en forma de doubleword

		movdqa xmm2, xmm1						; xmm2 == xmm1
		movdqa xmm4, xmm3						; xmm4 == xmm3

		movdqa xmm12, xmm11						; xmm12 == xmm11
		movdqa xmm14, xmm13						; xmm14 == xmm13

		punpcklwd xmm1, xmm5					; xmm1:  [		  s1  		|		  s1		|		  s1		|		  s1		]
		punpckhwd xmm2, xmm5					; xmm2:  [		  s2  		|		  s2		|		  s2		|		  s2		]
		punpcklwd xmm3, xmm5					; xmm3:  [		  s3  		|		  s3		|		  s3		|		  s3		]
		punpckhwd xmm4, xmm5					; xmm4:  [		  s4  		|		  s4		|		  s4		|		  s4		]

		punpcklwd xmm11, xmm5					; xmm11: [		  s5  		|		  s5		|		  s5		|		  s5		]
		punpckhwd xmm12, xmm5					; xmm12: [		  s6  		|		  s6		|		  s6		|		  s6		]
		punpcklwd xmm13, xmm5					; xmm13: [		  s7  		|		  s7		|		  s7		|		  s7		]
		punpckhwd xmm14, xmm5					; xmm14: [		  s8  		|		  s8		|		  s8		|		  s8		]


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

		mulps xmm1, xmm8						; xmm1:  [		   0 		|		0.5*s1		|		0.3*s1		|		0.2*s1		]
		mulps xmm2, xmm8						; xmm2:  [		   0 		|		0.5*s2		|		0.3*s2		|		0.2*s2		]
		mulps xmm3, xmm8						; xmm3:  [		   0 		|		0.5*s3		|		0.3*s3		|		0.2*s3		]
		mulps xmm4, xmm8						; xmm4:  [		   0 		|		0.5*s4		|		0.3*s4		|		0.2*s4		]

		mulps xmm11, xmm8						; xmm11: [		   0 		|		0.5*s5		|		0.3*s5		|		0.2*s5		]
		mulps xmm12, xmm8						; xmm12: [		   0 		|		0.5*s6		|		0.3*s6		|		0.2*s6		]
		mulps xmm13, xmm8						; xmm13: [		   0 		|		0.5*s7		|		0.3*s7		|		0.2*s7		]
		mulps xmm14, xmm8						; xmm14: [		   0 		|		0.5*s8		|		0.3*s8		|		0.2*s8		]

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

		packusdw xmm1, xmm2 					; xmm1:  [     0   |   Ir2   |   Ig2   |   Ib2   |    0    |   Ir1   |   Ig1   |   Ib1   ]
		packusdw xmm3, xmm4 					; xmm1:  [     0   |   Ir4   |   Ig4   |   Ib4   |    0    |   Ir3   |   Ig3   |   Ib3   ]

		packusdw xmm11, xmm12					; xmm1:  [     0   |   Ir6   |   Ig6   |   Ib6   |    0    |   Ir5   |   Ig5   |   Ib5   ]
		packusdw xmm13, xmm14					; xmm1:  [     0   |   Ir8   |   Ig8   |   Ib8   |    0    |   Ir7   |   Ig7   |   Ib7   ]
		
		packuswb xmm1, xmm3						; xmm1:  [  0 |Ir4 |Ig4 |Ib4 |  0 |Ir3 |Ig3 |Ib3 |  0 |Ir2 |Ig2 |Ib2 |  0 |Ir1 |Ig1 |Ib1 ]

		packuswb xmm11, xmm13					; xmm11: [  0 |Ir8 |Ig8 |Ib8 |  0 |Ir7 |Ig7 |Ib7 |  0 |Ir6 |Ig6 |Ib6 |  0 |Ir5 |Ig5 |Ib5 ]

												;Donde Ikj es el filtro aplicado a la componente k del pixel j

		; Fusiono con xmm0

		pand xmm0, xmm9							; xmm0:  [ a4 |  0 |  0 |  0 | a3 |  0 |  0 |  0 | a2 |  0 |  0 |  0 | a1 |  0 |  0 |  0 ]

		pand xmm10, xmm9						; xmm10: [ a8 |  0 |  0 |  0 | a7 |  0 |  0 |  0 | a6 |  0 |  0 |  0 | a5 |  0 |  0 |  0 ]

		pxor xmm0, xmm1 						; xmm0:  [ a4 |Ir4 |Ig4 |Ib4 | a3 |Ir3 |Ig3 |Ib3 | a2 |Ir2 |Ig2 |Ib2 | a1 |Ir1 |Ig1 |Ib1 ]

		pxor xmm10, xmm11						; xmm11: [ a8 |Ir8 |Ig8 |Ib8 | a7 |Ir7 |Ig7 |Ib7 | a6 |Ir6 |Ig6 |Ib6 | a5 |Ir5 |Ig5 |Ib5 ]

		; Acomodo de vuelta en memoria

		movdqa [rsi], xmm0

		movdqa [rsi + 16], xmm10

		; Avanzo en el loop y chequeo si tengo que terminar

		add rdi, 32
		add rsi, 32
		dec ecx
		jnz .ciclo

	;Finishing

	pop rbp

	ret