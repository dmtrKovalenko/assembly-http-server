.section __TEXT,__const
mom_response:
    .ascii "HTTP/1.1 413 Entity Too Large\r\n"
    .ascii "Content-Type: text/plain\r\n"
    .ascii "Content-Length: 43\r\n"
    .ascii "\r\n"
    .ascii "Honey, mama is busy right now. Ask your dad."
mom_response_len = . - mom_response
dad_response:
    .ascii "HTTP/1.1 410 Gone\r\n"
    .ascii "Content-Type: text/plain\r\n"
    .ascii "Content-Length: 36\r\n"
    .ascii "\r\n"
    .ascii "I'll buy some milk and get back soon"
dad_response_len = . - dad_response
default_response:
    .ascii "HTTP/1.1 405 Method Not Allowed\r\n"
    .ascii "Content-Type: text/plain\r\n"
    .ascii "Content-Length: 29\r\n"
    .ascii "Allow: GET\r\n"
    .ascii "\r\n"
    .ascii "Method is not allowed for URL"
default_response_len = . - default_response
mom_url: .asciz "GET /urmom"
dad_url: .asciz "GET /urdad"
start_msg: .asciz "Server starting on port %d...\n"
listen_msg: .asciz "Server is listening...\n"
listen_msg_len = . - listen_msg
close_msg: .asciz "Connection closed\n"
close_msg_len = . - close_msg
error_msg: .asciz "Error occurred!\n"
error_msg_len = . - error_msg

.section __DATA,__data
.align 4
.globl _sockaddr
_sockaddr:
    .short AF_INET 
    .short 0
    .long 0
_reuseaddr:
    .word 1

.section __TEXT,__text
.globl _main
.align 2
.equ SOCK_STREAM, 1
.equ AF_INET, 2
.equ SOL_SOCKET, 0xffff
.equ SO_REUSEADDR, 0x4
.equ HTTP_PORT, 6969

print: // raw syscall print function 
    mov x2, x1 // x1 message length
    mov x1, x0 // x0 message address
    mov x0, #1 /// this is file descriptor 1 (stdout)
    mov x16, #4
    svc #0x80
    ret

_main:
    sub sp, sp, #16 // darwin passed printf values on stack o_O
    mov x8, HTTP_PORT
    str x8, [sp] 
    adrp x0, start_msg@PAGE
    add x0, x0, start_msg@PAGEOFF
    bl _printf // libc call. I am not getting paid to manually convert ints to strings
    add sp, sp, #16 // increase stack back to normal but we don't use anyway

    mov w0, HTTP_PORT
    bl _htons // libc call again. Convert the port number to the host-to-network byte order
    adrp x1, _sockaddr@PAGE
    add x1, x1, _sockaddr@PAGEOFF 
    strh w0, [x1, #2] // and store it in the _sockaddr struct

    mov x0, AF_INET
    mov x1, SOCK_STREAM
    mov x2, #0
    mov x16, #97 // socket syscall
    svc #0x80

    cmp x0, #0 // Check error
    b.lt print_error
    mov x19, x0

    mov x1, SOL_SOCKET   // here we manually rebinding address we want to the new socket
    mov x2, SO_REUSEADDR // without this it will work but you have to wait after each restart
    adrp x3, _reuseaddr@GOTPAGE
    ldr x3, [x3, _reuseaddr@GOTPAGEOFF]
    mov x4, #4
    mov x16, #105 // setsockopt syscall
    svc #0x80

    mov x0, x19
    adrp x1, _sockaddr@GOTPAGE
    ldr x1, [x1, _sockaddr@GOTPAGEOFF]
    mov x2, #16
    mov x16, #104 // bind the osocket syscall
    svc #0x80
    
    cmp x0, #0 // Check error
    b.lt print_error 

    mov x0, x19
    mov x1, #5
    mov x16, #106 // listen syscall
    svc #0x80

    cmp x0, #0 // Check for listen error
    b.lt print_error

    adrp x0, listen_msg@PAGE // Print listen success
    add x0, x0, listen_msg@PAGEOFF
    mov x1, listen_msg_len
    bl print

request_loop: // Accepts the connection and sends the response
    mov x0, x19
    mov x1, #0
    mov x2, #0
    mov x16, #30 // accept syscall
    svc #0x80

    cmp x0, #0 // Check accept error
    b.lt request_loop
    mov x20, x0 // Save client socket for future
    // Read request
    sub sp, sp, #1024 // Allocate buffer on stack
    mov x1, sp
    mov x2, #1024
    mov x16, #3 // read syscall
    svc #0x80
    // Print request
    mov x1, x0 
    mov x0, sp // Buffer address
    bl print

    mov x0, sp // Check for /urmom URL
    adrp x1, mom_url@PAGE
    add x1, x1, mom_url@PAGEOFF
    bl _strstr // yes again libc function but it's okay
    cmp x0, #0
    b.ne load_mom_response

    mov x0, sp // Check for /urdad URL
    adrp x1, dad_url@PAGE
    add x1, x1, dad_url@PAGEOFF
    bl _strstr
    cmp x0, #0
    b.ne load_dad_response
    b load_default_response

load_mom_response:
    adrp x21, mom_response@PAGE
    add x21, x21, mom_response@PAGEOFF
    mov x22, mom_response_len
    b send_response

load_dad_response:
    adrp x21, dad_response@PAGE
    add x21, x21, dad_response@PAGEOFF
    mov x22, dad_response_len
    b send_response

load_default_response:
    adrp x21, default_response@PAGE
    add x21, x21, default_response@PAGEOFF
    mov x22, default_response_len
    b send_response

send_response:
    mov x0, x20 // x20 holds the socket descriptor
    mov x1, x21
    mov x2, x22
    mov x16, #4
    svc #0x80

    mov x0, x20
    mov x16, #6 // close socket syscall
    svc #0x80

    adrp x0, close_msg@PAGE
    add x0, x0, close_msg@PAGEOFF
    mov x1, close_msg_len
    bl print

    add sp, sp, #1024
    b request_loop

print_error:
    adrp x0, error_msg@PAGE
    add x0, x0, error_msg@PAGEOFF
    mov x1, error_msg_len
    bl print
    b request_loop
