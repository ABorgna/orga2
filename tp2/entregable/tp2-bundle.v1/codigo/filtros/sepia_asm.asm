section .data
DEFAULT REL

section .rodata
align 16
vectorFactores:		dd 0.2, 0.3, 0.5, 0.0

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

	movdqa xmm15, [vectorFactores]

	.cicloTriple:
		; Traigo el cacho de memoria a xmm0 y xmm10

		movdqu xmm0, [rdi]						; xmm0:  [ a4 | r4 | g4 | b4 | a3 | r3 | g3 | b3 | a2 | r2 | g2 | b2 | a1 | r1 | g1 | b1 ]
		movdqu xmm5, [rdi + 16]
		movdqu xmm10, [rdi + 32]				; xmm11: [ a8 | r8 | g8 | b8 | a7 | r7 | g7 | b7 | a6 | r6 | g6 | b6 | a5 | r5 | g5 | b5 ]

		; Separo en dos para poder desempaquetar y les quito el alpha

		movdqa xmm1, xmm0 						; xmm1 == xmm0
		pslld xmm1, 8
        psrld xmm1, 8							; xmm1:  [  0 | r4 | g4 | b4 |  0 | r3 | g3 | b3 |  0 | r2 | g2 | b2 |  0 | r1 | g1 | b1 ]
		movdqa xmm3, xmm1 						; xmm3 == xmm1

		movdqa xmm6, xmm5	 					; xmm11 == xmm10
		pslld xmm6, 8
        psrld xmm6, 8							; xmm11: [  0 | r8 | g8 | b8 |  0 | r7 | g7 | b7 |  0 | r6 | g6 | b6 |  0 | r5 | g5 | b5 ]
		movdqa xmm8, xmm6		 				; xmm13 == xmm11

		movdqa xmm11, xmm10 					; xmm11 == xmm10
		pslld xmm11, 8
        psrld xmm11, 8							; xmm11: [  0 | r8 | g8 | b8 |  0 | r7 | g7 | b7 |  0 | r6 | g6 | b6 |  0 | r5 | g5 | b5 ]
		movdqa xmm13, xmm11		 				; xmm13 == xmm11

		; Desempaqueto para que los datos pasen de byte a word

		pxor xmm7, xmm7							; Registro auxiliar de ceros

		punpcklbw xmm1, xmm7					; xmm1:  [  0 |  0 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		punpckhbw xmm3, xmm7					; xmm3:  [  0 |  0 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]

		punpcklbw xmm6, xmm7					; xmm11: [  0 |  0 |  0 | r6 |  0 | g6 |  0 | b6 |  0 |  0 |  0 | r5 |  0 | g5 |  0 | b5 ]
		punpckhbw xmm8, xmm7					; xmm13: [  0 |  0 |  0 | r8 |  0 | g8 |  0 | b8 |  0 |  0 |  0 | r7 |  0 | g7 |  0 | b7 ]

		punpcklbw xmm11, xmm7					; xmm11: [  0 |  0 |  0 | r6 |  0 | g6 |  0 | b6 |  0 |  0 |  0 | r5 |  0 | g5 |  0 | b5 ]
		punpckhbw xmm13, xmm7					; xmm13: [  0 |  0 |  0 | r8 |  0 | g8 |  0 | b8 |  0 |  0 |  0 | r7 |  0 | g7 |  0 | b7 ]

		; Hago las dos sumas horizontales

		phaddw xmm1, xmm3						; xmm1:  [ r4 + g4 |    b4   | r3 + g3 |    b3   | r2 + g2 |    b2   | r1 + g1 |    b1   ]

		phaddw xmm6, xmm8						; xmm11: [ r8 + g8 |    b8   | r7 + g7 |    b7   | r6 + g6 |    b6   | r5 + g5 |    b5   ]

		phaddw xmm11, xmm13						; xmm11: [ r8 + g8 |    b8   | r7 + g7 |    b7   | r6 + g6 |    b6   | r5 + g5 |    b5   ]

		phaddw xmm1, xmm7						; xmm1:  [     0   |     0   |     0   |     0   |    s4   |    s3   |    s2   |    s1   ]
		
		phaddw xmm6, xmm7						; xmm11: [     0   |     0   |     0   |     0   |    s8   |    s7   |    s6   |    s5   ]

		phaddw xmm11, xmm7						; xmm11: [     0   |     0   |     0   |     0   |    s8   |    s7   |    s6   |    s5   ]


		; Convierto a float y reordeno los datos

		punpcklwd xmm1, xmm7					; xmm1:  [		  s4  		|		  s3		|		  s2		|		  s1		]

		punpcklwd xmm6, xmm7					; xmm11: [		  s5  		|		  s5		|		  s5		|		  s5		]

		punpcklwd xmm11, xmm7					; xmm11: [		  s5  		|		  s5		|		  s5		|		  s5		]


		cvtdq2ps xmm1, xmm1

		cvtdq2ps xmm6, xmm6

		cvtdq2ps xmm11, xmm11


		pshufd xmm4, xmm1, 0b11111111			; xmm1:  [		  s1  		|		  s1		|		  s1		|		  s1		]
		pshufd xmm3, xmm1, 0b10101010			; xmm1:  [		  s2  		|		  s2		|		  s2		|		  s2		]
		pshufd xmm2, xmm1, 0b01010101			; xmm1:  [		  s3  		|		  s3		|		  s3		|		  s3		]
		pshufd xmm1, xmm1, 0b00000000			; xmm1:  [		  s4  		|		  s4		|		  s4		|		  s4		]

		pshufd xmm9, xmm6, 0b11111111			; xmm1:  [		  s5  		|		  s5		|		  s5		|		  s5		]
		pshufd xmm8, xmm6, 0b10101010			; xmm1:  [		  s6  		|		  s6		|		  s6		|		  s6		]
		pshufd xmm7, xmm6, 0b01010101			; xmm1:  [		  s7  		|		  s7		|		  s7		|		  s7		]
		pshufd xmm6, xmm6, 0b00000000			; xmm1:  [		  s8  		|		  s8		|		  s8		|		  s8		]

		pshufd xmm14, xmm11, 0b11111111			; xmm1:  [		  s5  		|		  s5		|		  s5		|		  s5		]
		pshufd xmm13, xmm11, 0b10101010			; xmm1:  [		  s6  		|		  s6		|		  s6		|		  s6		]
		pshufd xmm12, xmm11, 0b01010101			; xmm1:  [		  s7  		|		  s7		|		  s7		|		  s7		]
		pshufd xmm11, xmm11, 0b00000000			; xmm1:  [		  s8  		|		  s8		|		  s8		|		  s8		]


		; Ejecuto una multiplicación empaquetada para conseguir las componentes adecuadas correspondientes a aplicar el filtro

		mulps xmm1, xmm15						; xmm1:  [		   0 		|		0.5*s1		|		0.3*s1		|		0.2*s1		]
		mulps xmm2, xmm15						; xmm2:  [		   0 		|		0.5*s2		|		0.3*s2		|		0.2*s2		]
		mulps xmm3, xmm15						; xmm3:  [		   0 		|		0.5*s3		|		0.3*s3		|		0.2*s3		]
		mulps xmm4, xmm15						; xmm4:  [		   0 		|		0.5*s4		|		0.3*s4		|		0.2*s4		]

		mulps xmm6, xmm15						; xmm11: [		   0 		|		0.5*s5		|		0.3*s5		|		0.2*s5		]
		mulps xmm7, xmm15						; xmm12: [		   0 		|		0.5*s6		|		0.3*s6		|		0.2*s6		]
		mulps xmm8, xmm15						; xmm13: [		   0 		|		0.5*s7		|		0.3*s7		|		0.2*s7		]
		mulps xmm9, xmm15						; xmm14: [		   0 		|		0.5*s8		|		0.3*s8		|		0.2*s8		]

		mulps xmm11, xmm15						; xmm11: [		   0 		|		0.5*s5		|		0.3*s5		|		0.2*s5		]
		mulps xmm12, xmm15						; xmm12: [		   0 		|		0.5*s6		|		0.3*s6		|		0.2*s6		]
		mulps xmm13, xmm15						; xmm13: [		   0 		|		0.5*s7		|		0.3*s7		|		0.2*s7		]
		mulps xmm14, xmm15						; xmm14: [		   0 		|		0.5*s8		|		0.3*s8		|		0.2*s8		]

		; Reconvierto a int

		cvttps2dq xmm1, xmm1
		cvttps2dq xmm2, xmm2
		cvttps2dq xmm3, xmm3
		cvttps2dq xmm4, xmm4

		cvttps2dq xmm6, xmm6
		cvttps2dq xmm7, xmm7
		cvttps2dq xmm8, xmm8
		cvttps2dq xmm9, xmm9

		cvttps2dq xmm11, xmm11
		cvttps2dq xmm12, xmm12
		cvttps2dq xmm13, xmm13
		cvttps2dq xmm14, xmm14

		; Empaqueto los datos saturando con 255 en el caso de la componente roja

		packusdw xmm1, xmm2 					; xmm1:  [     0   |   Ir2   |   Ig2   |   Ib2   |    0    |   Ir1   |   Ig1   |   Ib1   ]
		packusdw xmm3, xmm4 					; xmm1:  [     0   |   Ir4   |   Ig4   |   Ib4   |    0    |   Ir3   |   Ig3   |   Ib3   ]

		packusdw xmm6, xmm7						; xmm1:  [     0   |   Ir6   |   Ig6   |   Ib6   |    0    |   Ir5   |   Ig5   |   Ib5   ]
		packusdw xmm8, xmm9						; xmm1:  [     0   |   Ir8   |   Ig8   |   Ib8   |    0    |   Ir7   |   Ig7   |   Ib7   ]

		packusdw xmm11, xmm12					; xmm1:  [     0   |   Ir6   |   Ig6   |   Ib6   |    0    |   Ir5   |   Ig5   |   Ib5   ]
		packusdw xmm13, xmm14					; xmm1:  [     0   |   Ir8   |   Ig8   |   Ib8   |    0    |   Ir7   |   Ig7   |   Ib7   ]
		
		packuswb xmm1, xmm3						; xmm1:  [  0 |Ir4 |Ig4 |Ib4 |  0 |Ir3 |Ig3 |Ib3 |  0 |Ir2 |Ig2 |Ib2 |  0 |Ir1 |Ig1 |Ib1 ]

		packuswb xmm6, xmm8						; xmm11: [  0 |Ir8 |Ig8 |Ib8 |  0 |Ir7 |Ig7 |Ib7 |  0 |Ir6 |Ig6 |Ib6 |  0 |Ir5 |Ig5 |Ib5 ]

		packuswb xmm11, xmm13					; xmm11: [  0 |Ir8 |Ig8 |Ib8 |  0 |Ir7 |Ig7 |Ib7 |  0 |Ir6 |Ig6 |Ib6 |  0 |Ir5 |Ig5 |Ib5 ]

												;Donde Ikj es el filtro aplicado a la componente k del pixel j

		; Fusiono con xmm0

		psrld xmm0, 24
        pslld xmm0, 24							; xmm0:  [ a4 |  0 |  0 |  0 | a3 |  0 |  0 |  0 | a2 |  0 |  0 |  0 | a1 |  0 |  0 |  0 ]

        psrld xmm5, 24
        pslld xmm5, 24							; xmm10: [ a8 |  0 |  0 |  0 | a7 |  0 |  0 |  0 | a6 |  0 |  0 |  0 | a5 |  0 |  0 |  0 ]

        psrld xmm10, 24
        pslld xmm10, 24							; xmm10: [ a8 |  0 |  0 |  0 | a7 |  0 |  0 |  0 | a6 |  0 |  0 |  0 | a5 |  0 |  0 |  0 ]

		pxor xmm0, xmm1 						; xmm0:  [ a4 |Ir4 |Ig4 |Ib4 | a3 |Ir3 |Ig3 |Ib3 | a2 |Ir2 |Ig2 |Ib2 | a1 |Ir1 |Ig1 |Ib1 ]

		pxor xmm5, xmm6							; xmm11: [ a8 |Ir8 |Ig8 |Ib8 | a7 |Ir7 |Ig7 |Ib7 | a6 |Ir6 |Ig6 |Ib6 | a5 |Ir5 |Ig5 |Ib5 ]

		pxor xmm10, xmm11						; xmm11: [ a8 |Ir8 |Ig8 |Ib8 | a7 |Ir7 |Ig7 |Ib7 | a6 |Ir6 |Ig6 |Ib6 | a5 |Ir5 |Ig5 |Ib5 ]

		; Acomodo de vuelta en memoria

		movdqa [rsi], xmm0

		movdqa [rsi + 16], xmm5

		movdqa [rsi + 32], xmm10

		; Avanzo en el loop y chequeo si tengo que terminar

		add rdi, 48
		add rsi, 48
		sub ecx, 12
		cmp ecx, 12
		jge .cicloTriple


;-------------------------------------------------------------------------------------------------------------------------
    cmp ecx, 0
    je .fin

	.cicloSimple:
		; Traigo el cacho de memoria a xmm0 y xmm10

		movdqu xmm0, [rdi]						; xmm0:  [ a4 | r4 | g4 | b4 | a3 | r3 | g3 | b3 | a2 | r2 | g2 | b2 | a1 | r1 | g1 | b1 ]

		; Separo en dos para poder desempaquetar y les quito el alpha

		movdqa xmm1, xmm0 						; xmm1 == xmm0
		pslld xmm1, 8
        psrld xmm1, 8							; xmm1:  [  0 | r4 | g4 | b4 |  0 | r3 | g3 | b3 |  0 | r2 | g2 | b2 |  0 | r1 | g1 | b1 ]
		movdqa xmm3, xmm1 						; xmm3 == xmm1

		; Desempaqueto para que los datos pasen de byte a word

		pxor xmm7, xmm7

		punpcklbw xmm1, xmm7					; xmm1:  [  0 |  0 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		punpckhbw xmm3, xmm7					; xmm3:  [  0 |  0 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]

		; Hago las dos sumas horizontales

		phaddw xmm1, xmm3						; xmm1:  [ r4 + g4 |    b4   | r3 + g3 |    b3   | r2 + g2 |    b2   | r1 + g1 |    b1   ]

		phaddw xmm1, xmm7						; xmm1:  [     0   |     0   |     0   |     0   |    s4   |    s3   |    s2   |    s1   ]

		; Convierto a float y reordeno los datos

		punpcklwd xmm1, xmm7					; xmm1:  [		  s4  		|		  s3		|		  s2		|		  s1		]

		cvtdq2ps xmm1, xmm1

		pshufd xmm4, xmm1, 0b11111111			; xmm1:  [		  s1  		|		  s1		|		  s1		|		  s1		]
		pshufd xmm3, xmm1, 0b10101010			; xmm1:  [		  s2  		|		  s2		|		  s2		|		  s2		]
		pshufd xmm2, xmm1, 0b01010101			; xmm1:  [		  s3  		|		  s3		|		  s3		|		  s3		]
		pshufd xmm1, xmm1, 0b00000000			; xmm1:  [		  s4  		|		  s4		|		  s4		|		  s4		]

		; Ejecuto una multiplicación empaquetada para conseguir las componentes adecuadas correspondientes a aplicar el filtro

		mulps xmm1, xmm15						; xmm1:  [		   0 		|		0.5*s1		|		0.3*s1		|		0.2*s1		]
		mulps xmm2, xmm15						; xmm2:  [		   0 		|		0.5*s2		|		0.3*s2		|		0.2*s2		]
		mulps xmm3, xmm15						; xmm3:  [		   0 		|		0.5*s3		|		0.3*s3		|		0.2*s3		]
		mulps xmm4, xmm15						; xmm4:  [		   0 		|		0.5*s4		|		0.3*s4		|		0.2*s4		]

		; Reconvierto a int

		cvttps2dq xmm1, xmm1
		cvttps2dq xmm2, xmm2
		cvttps2dq xmm3, xmm3
		cvttps2dq xmm4, xmm4

		; Empaqueto los datos saturando con 255 en el caso de la componente roja

		packusdw xmm1, xmm2 					; xmm1:  [     0   |   Ir2   |   Ig2   |   Ib2   |    0    |   Ir1   |   Ig1   |   Ib1   ]
		packusdw xmm3, xmm4 					; xmm1:  [     0   |   Ir4   |   Ig4   |   Ib4   |    0    |   Ir3   |   Ig3   |   Ib3   ]
		
		packuswb xmm1, xmm3						; xmm1:  [  0 |Ir4 |Ig4 |Ib4 |  0 |Ir3 |Ig3 |Ib3 |  0 |Ir2 |Ig2 |Ib2 |  0 |Ir1 |Ig1 |Ib1 ]

												;Donde Ikj es el filtro aplicado a la componente k del pixel j

		; Fusiono con xmm0

		psrld xmm0, 24
        pslld xmm0, 24							; xmm0:  [ a4 |  0 |  0 |  0 | a3 |  0 |  0 |  0 | a2 |  0 |  0 |  0 | a1 |  0 |  0 |  0 ]

		pxor xmm0, xmm1 						; xmm0:  [ a4 |Ir4 |Ig4 |Ib4 | a3 |Ir3 |Ig3 |Ib3 | a2 |Ir2 |Ig2 |Ib2 | a1 |Ir1 |Ig1 |Ib1 ]

		; Acomodo de vuelta en memoria

		movdqa [rsi], xmm0

		; Avanzo en el loop y chequeo si tengo que terminar

		add rdi, 16
		add rsi, 16
		sub ecx, 4
		cmp ecx, 4
		jge .cicloSimple




	;Finishing

	.fin:

		pop rbp
		ret