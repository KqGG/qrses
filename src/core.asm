; TODO: Optionally implement error handling to endscr
; TODO: Go validate the entire code
; TODO: Possibly just paste in flags in initscr instead of combining them
; TODO: Improve error handling
format ELF64

public clear
public initscr
public getwidth
public getheight
public addch
public refresh
public endscr

section '.rodata'
initstr db 27, "[?1049h", 27, "[?25l", 27, "[37;40m", 27, "[2J", 27, "[H" ; 29 bytes
endstr db 27, "[?25h", 27, "[0m", 27, "[2J", 27, "[H", 27, "[?1049l"; 25 bytes

section '.data' writeable
width dw 0
height dw 0

section '.bss'
state: rb 36
scr: rq 1

section '.text' executable
clear:
	mov di, [width]             ; load width and height
	mov si, [height]            ;

	test si, si                 ; if height is 0, then the
	jz .exit                    ; library has not been initialized

	dec si                      ; height--;

	mov rax, [scr]              ; initialize "crawling pointer"
.heightloop:
	mov dx, di                  ; refresh width loop
.widthloop:
	mov byte [rax], 0x20        ; *p++ = ' '
	inc rax                     ;

	dec dx                      ; loop until dx == 0
	jnz .widthloop              ;

	mov byte [rax], 0x0A        ; *p++ = '\n'
	inc rax                     ;

	dec si                      ; loop until si == 0
	jnz .heightloop             ;
.widthloop2:
	mov byte [rax], 0x20        ; *p++ = ' '
	inc rax                     ;

	dec di                      ; loop until di == 0
	jnz .widthloop2             ;

	ret                         ; return void
.exit: ret

getwidth:
	movzx eax, word [width]     ; return &width - 1
	dec eax                     ;
	ret                         ;

getheight:
	movzx eax, word [height]    ; return &height - 1
	dec eax                     ;
	ret                         ;

initscr:
	push rbp                    ; build stack frame
	mov rbp, rsp                ;

	xor edi, edi                ; ioctl(0, TCGETS, &state)
	mov esi, 0x5401             ;
	lea rdx, [state]            ;
	mov eax, 16                 ;
	syscall                     ;

	test rax, rax               ; ioctl error
	js .err1                    ; return 1
	
	sub rsp, 40                 ; make space for termios

	lea rdi, [state]            ; copy state onto the stack
	mov rax, [rdi]              ;
	mov [rsp], rax              ;
	mov rax, [rdi + 8]          ;
	mov [rsp + 8], rax          ;
	mov rax, [rdi + 16]         ;
	mov [rsp + 16], rax         ;
	mov rax, [rdi + 24]         ;
	mov [rsp + 24], rax         ;
	mov eax, [rdi + 32]         ;
	mov [rsp + 32], eax         ;

	mov eax, [rsp]              ; iflag &= ~(ICRNL | IXON)
	and eax, 0xFFFFFAFF         ;
	mov [rsp], eax              ;

	mov eax, [rsp + 12]         ; lflag &= ~(ECHO | ICANON | ISIG)
	and eax, 0xFFFFFFF4         ;
	mov [rsp + 12], eax         ;

	mov byte [rsp + 23], 1      ; c_cc[VMIN] = 1

	mov byte [rsp + 22], 0      ; c_cc[VTIME] = 0

	sub rsp, 8                  ; make space for winsize

	mov edi, 1                  ; ioctl(1, TIOCGWINSZ, &winsize)
	mov esi, 0x5413             ;
	lea rdx, [rsp]              ;
	mov eax, 16                 ;
	syscall                     ;

	test rax, rax               ; ioctl error
	js .err1                    ; return 1

	movzx eax, word [rsp]       ; &height = winsize.rows
	mov [height], ax            ;
	test ax, ax                 ; if (height == 0) return 2
	jz .err2                    ;
		
	movzx ecx, word [rsp + 2]   ; &width = winsize.cols
	mov [width], cx             ;
	test cx, cx                 ; if (width == 0) return 2
	jz .err2                    ;
	
	inc rcx                     ; SIZE = (width + 1) * height + 2
	imul rax, rcx               ;
	add rax, 2                  ;
	
	xor edi, edi                ; mmap(0,
	mov rsi, rax                ;      SIZE,
	mov edx, 0x03               ;      PROT_READ | PROT_WRITE,
	mov r10, 0x22               ;      MAP_PRIVATE | MAP_ANONYMOUS,
	xor r8, r8                  ;      0,
	xor r9, r9                  ;      0)
	mov eax, 9                  ;
	syscall                     ;

	test rax, rax               ; mmap error
	js .err3                    ; return 3

	mov dword [rax], 0x00485B1B ; ESC, '[', 'H', 0
	
	add rax, 3                  ; advance the pointer by 3

	mov [scr], rax              ; scr = mmap return

	call clear

	xor edi, edi                ; ioctl(0, TCSETS, &termios)
	mov esi, 0x5402             ;
	lea rdx, [rsp + 8]          ;
	mov eax, 16                 ;
	syscall                     ;

	test rax, rax               ; ioctl error
	js .err1                    ; return 1

	mov edi, 1                  ; write(1, &initstr, 29)
	lea rsi, [initstr]          ;
	mov edx, 29                 ;
	mov eax, 1                  ;
	syscall                     ;

	test rax, rax               ; write error
	js .err1                    ; return 1

	mov rsp, rbp                ; collapse stack frame
	pop rbp                     ;

	xor eax, eax                ; return 0
	ret                         ;
.err1:
	mov rsp, rbp                ; collapse stack frame
	pop rbp                     ;

	mov eax, 1                  ; return 1
	ret                         ;
.err2:
	mov rsp, rbp                ; collapse stack frame
	pop rbp                     ;

	mov eax, 2                  ; return 2
	ret                         ;
.err3:
	mov rsp, rbp                ; collapse stack frame
	pop rbp                     ;

	mov eax, 3                  ; return 3
	ret                         ;

addch:
	movzx eax, word [height]    ; if (y >= height) return 1
	cmp edi, eax                ;
	jae .outofbounds            ;
	
	movzx eax, word [width]     ; if (x >= width) return 1
	cmp esi, eax                ;
	jae .outofbounds            ;
	
	cmp dl, 0x20                ; if (ch < 0x20) return 2
	jb .invlch                  ;
	
	cmp dl, 0x7F                ; if (ch == 0x7F) return 2
	je .invlch                  ;
	
	movzx edi, di               ; zero extend the arguments
	movzx esi, si               ; to avoid random gibberish
	
	inc rax                     ; y * (width + 1) + x
	imul rax, rdi               ;
	add rax, rsi                ;
	
	mov rcx, [scr]              ; write to the cell
	mov [rcx + rax], dl         ;
	
	xor eax, eax                ; return 0
	ret                         ;
.outofbounds:
    mov eax, 1                      ; return 1
    ret                             ;
.invlch:
    mov eax, 2                      ; return 2
    ret                             ;

refresh:
	movzx eax, word [height]    ; load width and height
	movzx edx, word [width]     ;

	test eax, eax               ; if height is 0, then the
	jz .exit                    ; library has not been initialized

	mov edi, 1                  ; write(1, scr - 3, height * (width + 1) + 2)
                                    ;
	mov rsi, [scr]              ;
	sub rsi, 3                  ;
                                    ;
	inc edx                     ;
	imul rdx, rax               ;
	add rdx, 2                  ;
                                    ;
	mov eax, 1                  ;
	syscall                     ;

	ret                         ; pass return from write
.exit:
	mov eax, 1                  ; return 1
	ret                         ;

endscr:
	movzx eax, word [height]    ; load width and height
	movzx esi, word [width]     ;

	test eax, eax               ; if height is 0, then the
	jz .exit                    ; library has not been initialized

	mov rdi, [scr]              ; munmap(scr - 3, height * (width + 1) + 2)
	sub rdi, 3                  ;
                                    ;
	inc esi                     ;
	imul rsi, rax               ;
	add rsi, 2                  ;
                                    ;
	mov eax, 11                 ;
	syscall                     ;

	mov edi, 1                  ; write(1, &endstr, 25)
	lea rsi, [endstr]           ;
	mov edx, 25                 ;
	mov eax, 1                  ;
	syscall                     ;

	xor edi, edi                ; ioctl(0, TCSETS, &state)
	mov esi, 0x5402             ;
	lea rdx, [state]            ;
	mov eax, 16                 ;
	syscall                     ;

	mov word [width], 0         ; "uninitialize" library
	mov word [height], 0        ;
	mov qword [scr], 0          ;

	ret                         ; return void
.exit:
	mov eax, 1                  ; return 1
	ret                         ;
