section .data
DEFAULT REL

section .rodata
align 16
vectorFactores:		dd 0.2, 0.3, 0.5, 0.0
; mxcsr settings, round to zero
; DEFAULT_VALUE | RZ_MASK = 0x1F80H | 0x7000
MXCSR_RZ: dd 0x7F80

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

	; Save the MXCSR register
	sub rsp, 8
	stmxcsr [rsp]

	; Set SSE rounding to zero
	ldmxcsr [MXCSR_RZ]

	imul ecx, edx								; ecx == #filas * #columnas

	movdqa xmm15, [vectorFactores]

	.cicloTriple:
		; Traigo el segmento de memoria a xmm0

		movdqu xmm0, [rdi]						; xmm0:  [ a4 | r4 | g4 | b4 | a3 | r3 | g3 | b3 | a2 | r2 | g2 | b2 | a1 | r1 | g1 | b1 ]
		movdqu xmm5, [rdi + 16]
		movdqu xmm10, [rdi + 32]

		; Separo en dos para poder desempaquetar y les quito el alpha

		movdqa xmm1, xmm0 						; xmm1 == xmm0
		pslld xmm1, 8
        psrld xmm1, 8							; xmm1:  [  0 | r4 | g4 | b4 |  0 | r3 | g3 | b3 |  0 | r2 | g2 | b2 |  0 | r1 | g1 | b1 ]
		movdqa xmm3, xmm1 						; xmm3 == xmm1

		movdqa xmm6, xmm5
		pslld xmm6, 8
        psrld xmm6, 8	
		movdqa xmm8, xmm6

		movdqa xmm11, xmm10
		pslld xmm11, 8
        psrld xmm11, 8		
		movdqa xmm13, xmm11	

		; Desempaqueto para que los datos pasen de byte a word

		pxor xmm7, xmm7							; Registro auxiliar de ceros

		punpcklbw xmm1, xmm7					; xmm1:  [  0 |  0 |  0 | r2 |  0 | g2 |  0 | b2 |  0 |  0 |  0 | r1 |  0 | g1 |  0 | b1 ]
		punpckhbw xmm3, xmm7					; xmm3:  [  0 |  0 |  0 | r4 |  0 | g4 |  0 | b4 |  0 |  0 |  0 | r3 |  0 | g3 |  0 | b3 ]

		punpcklbw xmm6, xmm7
		punpckhbw xmm8, xmm7

		punpcklbw xmm11, xmm7
		punpckhbw xmm13, xmm7

		; Hago las dos sumas horizontales

		phaddw xmm1, xmm3						; xmm1:  [ r4 + g4 |    b4   | r3 + g3 |    b3   | r2 + g2 |    b2   | r1 + g1 |    b1   ]

		phaddw xmm6, xmm8

		phaddw xmm11, xmm13

		phaddw xmm1, xmm7						; xmm1:  [     0   |     0   |     0   |     0   |    s4   |    s3   |    s2   |    s1   ]
		
		phaddw xmm6, xmm7

		phaddw xmm11, xmm7


		; Convierto a float y reordeno los datos

		punpcklwd xmm1, xmm7					; xmm1:  [		  s4  		|		  s3		|		  s2		|		  s1		]

		punpcklwd xmm6, xmm7

		punpcklwd xmm11, xmm7


		cvtdq2ps xmm1, xmm1

		cvtdq2ps xmm6, xmm6

		cvtdq2ps xmm11, xmm11


		pshufd xmm4, xmm1, 0b11111111			; xmm1:  [		  s1  		|		  s1		|		  s1		|		  s1		]
		pshufd xmm3, xmm1, 0b10101010			; xmm1:  [		  s2  		|		  s2		|		  s2		|		  s2		]
		pshufd xmm2, xmm1, 0b01010101			; xmm1:  [		  s3  		|		  s3		|		  s3		|		  s3		]
		pshufd xmm1, xmm1, 0b00000000			; xmm1:  [		  s4  		|		  s4		|		  s4		|		  s4		]

		pshufd xmm9, xmm6, 0b11111111
		pshufd xmm8, xmm6, 0b10101010
		pshufd xmm7, xmm6, 0b01010101
		pshufd xmm6, xmm6, 0b00000000

		pshufd xmm14, xmm11, 0b11111111
		pshufd xmm13, xmm11, 0b10101010
		pshufd xmm12, xmm11, 0b01010101
		pshufd xmm11, xmm11, 0b00000000


		; Ejecuto una multiplicación empaquetada para conseguir las componentes adecuadas correspondientes a aplicar el filtro

		mulps xmm1, xmm15						; xmm1:  [		   0 		|		0.5*s1		|		0.3*s1		|		0.2*s1		]
		mulps xmm2, xmm15						; xmm2:  [		   0 		|		0.5*s2		|		0.3*s2		|		0.2*s2		]
		mulps xmm3, xmm15						; xmm3:  [		   0 		|		0.5*s3		|		0.3*s3		|		0.2*s3		]
		mulps xmm4, xmm15						; xmm4:  [		   0 		|		0.5*s4		|		0.3*s4		|		0.2*s4		]

		mulps xmm6, xmm15
		mulps xmm7, xmm15
		mulps xmm8, xmm15
		mulps xmm9, xmm15

		mulps xmm11, xmm15
		mulps xmm12, xmm15
		mulps xmm13, xmm15
		mulps xmm14, xmm15

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

		packusdw xmm6, xmm7
		packusdw xmm8, xmm9

		packusdw xmm11, xmm12
		packusdw xmm13, xmm14
		
		packuswb xmm1, xmm3						; xmm1:  [  0 |Ir4 |Ig4 |Ib4 |  0 |Ir3 |Ig3 |Ib3 |  0 |Ir2 |Ig2 |Ib2 |  0 |Ir1 |Ig1 |Ib1 ]

		packuswb xmm6, xmm8	

		packuswb xmm11, xmm13

												;Donde Ikj es el filtro aplicado a la componente k del pixel j

		; Fusiono con xmm0

		psrld xmm0, 24
        pslld xmm0, 24							; xmm0:  [ a4 |  0 |  0 |  0 | a3 |  0 |  0 |  0 | a2 |  0 |  0 |  0 | a1 |  0 |  0 |  0 ]

        psrld xmm5, 24
        pslld xmm5, 24

        psrld xmm10, 24
        pslld xmm10, 24

		pxor xmm0, xmm1 						; xmm0:  [ a4 |Ir4 |Ig4 |Ib4 | a3 |Ir3 |Ig3 |Ib3 | a2 |Ir2 |Ig2 |Ib2 | a1 |Ir1 |Ig1 |Ib1 ]

		pxor xmm5, xmm6

		pxor xmm10, xmm11

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

	; Restore the MXCSR register
	ldmxcsr [rsp]
	add rsp, 8

		pop rbp
		ret
