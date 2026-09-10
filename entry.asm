format ELF64

public _entry
extrn main

section '.text' executable

_entry:
	xor ebp, ebp

	mov rdi, [rsp]
	lea rsi, [rsp+8]
	
	and rsp, -16
	sub rsp, 8

	call main

	mov rdi, rax
	mov rax, 60
	syscall
