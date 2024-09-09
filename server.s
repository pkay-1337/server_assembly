.intel_syntax noprefix
.globl _start

.section .text

_start:
        //socket
        mov rax, 41
        mov rdi, 2
        mov rsi, 1
        mov rdx, 0
        syscall
        mov r12, rax

        //bind
        mov rdi, r12
        mov rax, 49
        mov rsi, offset x
        mov rdx, 16
        syscall

        //listen
        mov rax, 50
        mov rdi, r12
        mov rsi, 0
        syscall

        jmp accept

parent_accept:
        mov rax, 3
        mov rdi, 4
        syscall

accept:
        //accept
        mov rax, 43
        mov rdi, r12
        mov rsi, 0
        mov rdx, 0
        syscall
        mov r13, rax

        mov rax, 57
        syscall

        cmp rax, 0
        jne parent_accept

        mov rax, 3
        mov rdi, 3
        syscall

        //read_request
        mov rax, 0
        mov rdi, r13
        mov rsi, offset request
        mov rdx, 1000
        syscall
	mov r15, rax

        //GET_or_POST
        mov rax, offset request
        mov rbx, offset path
        cmp byte ptr [rax], 0x47
        je get
        cmp byte ptr [rax], 0x50
        je post

get:
        //get_path_GET
        mov rax, offset request
        mov rbx, offset path
        add rax, 4
loop:
        cmp byte ptr [rax], 32
        je end_loop
        mov r10b, byte ptr [rax]
        mov byte ptr [rbx], r10b
        add rax, 1
        add rbx, 1
        jmp loop

end_loop:

        mov rax, 2
        mov rdi, offset path
        mov rsi, 0
        mov rdx, 0600
        syscall

        //read_file
        //file_fd
        mov r15, rax
        mov rax, 0
        mov rdi, r15
        mov rsi, offset file_data
        mov rdx, 1024
        syscall
        mov r14, rax

        mov rax, 3
        mov rdi, r15
        syscall

        mov rax, 1
        mov rdi, r13
        mov rsi, offset response
        mov rdx, 19
        syscall

        mov rax, 1
        mov rdi, r13
        mov rsi, offset file_data
        mov rdx, r14
        syscall

        jmp end
post:
        mov rax, offset request
        mov rbx, offset path
        add rax, 5
loop_post:
        cmp byte ptr [rax], 32
        je end_loop_post
        mov r10b, byte ptr [rax]
        mov byte ptr [rbx], r10b
        add rax, 1
        add rbx, 1
        jmp loop_post
end_loop_post:

	//open file
        mov rax, 2
        mov rdi, offset path
        mov rsi, 65
        mov rdx, 0777
        syscall

	//get post data
	mov rax, offset request
	mov rbx, offset post_data
	add rax, r15
	mov r14, 0
get_first_data:
	mov cl, byte ptr [rax]
	cmp cl, 10
	je got_first_data
	sub rax, 1
	add r14, 1
	jmp get_first_data
got_first_data:
	add rax, 1
get_data:
	mov cl, byte ptr [rax]
	cmp cl, 0
	je got_data
	mov byte ptr [rbx], cl
	add rax, 1
	add rbx, 1
	jmp get_data
got_data:
	

        mov rdi, 3
        mov rax, 1
        mov rsi, offset post_data
	sub r14, 1
        mov rdx, r14
        syscall

        mov rax, 3
        mov rdi, 3
        syscall

        mov rax, 1
        mov rdi, 4
        mov rsi, offset response
        mov rdx, 19
        syscall
	
        jmp end

end:
        mov rax, offset path
cleaning:
        cmp byte ptr [rax], 0
        je end_cleaning
        mov byte ptr [rax], 0
        add rax, 1
        jmp cleaning
end_cleaning:
        //jmp accept

        mov rax, 60
        mov rdi, 0
        syscall


.section .data
sock_addr:
        .byte 0x02, 0x00, 0x00, 0x50, 0x7f, 0x00, 0x00, 0x01
x:
        .word 2
        .byte 0
        .byte 80
request:
        .space 1000
post_data:
	.space 1000
path:
        .space 200
response:
        .ascii "HTTP/1.0 200 OK\r\n\r\n"
file_data:
        .space 1024

