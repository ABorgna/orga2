extern copyN

global cropflip_asm_COPYN


section .text
;void cropflip_asm		(
	;        rdi     | unsigned char *src,
	;        rsi     | unsigned char *dst,
	;        edx    | int cols,
	;        ecx    | int filas,
	;        r8d    | int src_row_size,
	;        r9d    | int dst_row_size,
	;        rbp+16 | int tamx,
	;        rbp+24 | int tamy,
	;        rbp+32 | int offsetx,
	;        rbp+40 | int offsety
;)


;			CON COPYN
;	src1 = src + offsetx*4 +src_row_size*(filas-1)
;	for(i = tamy ; i > 0 ; i--)
;		copyN	(rsi = copia de src1, rdi = dst, rbx = dst_row_size)
;		src1 = src1 - src_row_size


cropflip_asm_COPYN:
	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	
	mov r14, rdi							; swap source & destiny
	mov rdi, rsi
	mov rsi, r14			

	movsxd r12, dword [rbp+24]
	movsxd r13, r8d 		
	movsxd rbx, dword [rbp+16]		
			
	movsxd r14, ecx						; src1 = filas
	dec r14									; srci = filas-1
	imul r14, r13							; src1 = (filas-1)*src_row_size
	movsxd r10, dword [rbp+32]
	lea r14, [r14+ 4*r10]				; src1 = 4*offsetx + (filas-1)*src_row_size
	add r14, rsi							; src1 = src + 4*offsetx + (filas-1)*src_row_size 


	;		rsi		| src 
	;		rdi		| dst
	;		rbx		| tamx
	;		r12		| tamy (iterador Y)
	;		r13		| src_row_size 
	;		r14		| src1
	;		Loop in y: tamy times
	

.loopSkywalkerY:
	cmp r12, 0
	je .fin
	mov rsi, r14
	call copyN	
	sub r14, r13			; Apuntamos al inicio de la fila anterior + offsetx 
	dec r12
	jmp .loopSkywalkerY
			
.fin:	
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret
