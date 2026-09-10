format ELF64

public read
public nanosleep

section '.text' executable

read:
	xor eax, eax
	syscall
	ret

nanosleep:
	sub rsp, 16

	mov [rsp], rdi
	mov [rsp + 8], rsi

	mov rdi, rsp
	xor rsi, rsi

	mov eax, 35
	syscall

	add rsp, 16
	ret
