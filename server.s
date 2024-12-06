.section __TEXT,__text
.globl _main
.align 2
.extern _printf

// Constants
.equ SOCK_STREAM, 1
.equ AF_INET, 2
.equ SOL_SOCKET, 0xffff
.equ SO_REUSEADDR, 0x4
.equ HTTP_PORT, 6969

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
// URL patterns to match
urdad_url: .asciz "/urdad"
urdad_url_len = . - urdad_url
start_msg: .asciz "Server starting on port %d...\n"
start_msg_len = . - start_msg
socket_msg: .asciz "Socket created successfully\n"
socket_msg_len = . - socket_msg
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
// raw syscall print function (but check for the print of start message it uses libc printf)
// it's literally just showing out that you can write EVERYTHING yourself
print:
    mov x2, x1 // x1 message length
    mov x1, x0 // x0 message address
    mov x0, #1 /// this is file descriptor 1 (stdout)
    mov x16, #4
    svc #0x80
    ret

_main:
    // Save frame pointer
    stp x29, x30, [sp, #-16]!
    mov x29, sp
	
    // use the libc printf to print the message
    // I am not getting paid to manually convert ints to strings
    sub sp, sp, #16 // darwin passed printf values on stack o_O
    mov x8, HTTP_PORT
    str x8, [sp] 
    adrp x0, start_msg@PAGE
    add x0, x0, start_msg@PAGEOFF
    bl _printf
    add sp, sp, #16 // increase stack back to normal but we don't use anyway

    // Convert the port number to the host-to-network byte order
    // and store it in the _sockaddr struct
    mov w0, HTTP_PORT
    bl _htons
    adrp x1, _sockaddr@PAGE
    add x1, x1, _sockaddr@PAGEOFF
    strh w0, [x1, #2]

    // In the code after socket creation and before bind
    // Create socket
    mov x0, AF_INET
    mov x1, SOCK_STREAM
    mov x2, #0
    mov x16, #97 // socket syscall
    svc #0x80

    // Check for error
    cmp x0, #0
    b.lt print_error
    mov x19, x0

    // This is additional system wait for releasing the address before binding
    mov x0, x19
    mov x1, SOL_SOCKET
    mov x2, SO_REUSEADDR
    adrp x3, _reuseaddr@GOTPAGE
    ldr x3, [x3, _reuseaddr@GOTPAGEOFF]
    mov x4, #4
    mov x16, #105 // setsockopt syscall
    svc #0x80

    // bind the osocket
    mov x0, x19
    adrp x1, _sockaddr@GOTPAGE
    ldr x1, [x1, _sockaddr@GOTPAGEOFF]
    mov x2, #16
    mov x16, #104
    svc #0x80
    
    // Add this error check for bind
    cmp x0, #0
    b.lt print_error 

    // Listen
    mov x0, x19
    mov x1, #5
    mov x16, #106
    svc #0x80
    // Check for listen error
    cmp x0, #0
    b.lt print_error

    // Print listen success
    adrp x0, listen_msg@PAGE
    add x0, x0, listen_msg@PAGEOFF
    mov x1, listen_msg_len
    bl print

    // Set default response (mom)
    adrp x21, mom_response@PAGE
    add x21, x21, mom_response@PAGEOFF
    mov x22, mom_response_len

request_loop:
    // Accept connection
    mov x0, x19
    mov x1, #0
    mov x2, #0
    mov x16, #30 // accept syscall
    svc #0x80

    cmp x0, #0     // Check for accept error
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

    // Find "/urdad" in the request using strstr
    mov x0, sp 
    adrp x1, urdad_url@PAGE
    add x1, x1, urdad_url@PAGEOFF
    bl _strstr // yes again libc functione
    
    // If found, update response pointer to dad
    cbz x0, send_response    // If not found, skip to send response
    adrp x21, dad_response@PAGE
    add x21, x21, dad_response@PAGEOFF
    mov x22, dad_response_len

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

    b request_loop

print_error:
    adrp x0, error_msg@PAGE
    add x0, x0, error_msg@PAGEOFF
    mov x1, error_msg_len
    bl print
    b request_loop
