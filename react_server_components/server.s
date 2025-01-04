.section __TEXT,__const
rsc_header:
    .ascii "HTTP/1.1 200 OK\r\n"
    .ascii "Content-Type: text/x-component\r\n"
    .ascii "Server: MY ASSEMBLY\r\n"
    .ascii "Access-Control-Allow-Origin: *\r\n"
    .ascii "\r\n"
rsc_header_len = . - rsc_header

response_start:
    .ascii "0:[\"$\",\"pre\",null,{\"children\":[[\"$\",\"span\",null,{\"children\":\""
response_start_len = . - response_start

response_end:
    .ascii "\"}]]}]\n\n"
response_end_len = . - response_end

file_error_tree:
    .ascii "1:I{\"id\":\"./src/PepeAlert.js\",\"chunks\":[\"main\"],\"name\":\"default\"}\r\n"
    .ascii "0:[\"$\",\"$L1\",null,{\"errorCode\":%d}]\r\n"
file_error_tree_len = . - file_error_tree

span_close: .asciz "\"}],[\"$\",\"s\",null,{\"children\":\""
span_close_len = . - span_close
strong_close: .asciz "\"}],[\"$\",\"span\",null,{\"children\":\""
strong_close_len = . - strong_close

file_path: .asciz "/tmp/rsc-content.txt"

button_url: .asciz "GET /rsc"
start_msg: .asciz "RSC Server starting on port %d...\n"
listen_msg: .asciz "Server is listening...\n"
listen_msg_len = . - listen_msg
close_msg: .asciz "Connection closed\n"
close_msg_len = . - close_msg
error_msg: .asciz "Error occurred!\n"
error_msg_len = . - error_msg

debug_msg1: .asciz "Debug: Before file open\n"
debug_msg2: .asciz "Debug: After file open, fd: %d\n"
debug_msg3: .asciz "Debug: Before file read\n"
debug_msg4: .asciz "Debug: After file read, bytes: %d\n"
debug_fmt: .asciz "Debug fmt"

.section __DATA,__data
.align 4
.globl _sockaddr
file_buffer: .space 4096
tmp_buffer: .space 8192
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

escape_string:
    // x0 = input buffer, x1 = output buffer, x2 = input length
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov x3, #0 // is_strong_applied
    
loop:
    ldrb w4, [x0]
    cbz w4, done
    
    // double asterisk sequence
    cmp w4, #0x2A 
    b.ne not_asterisk
    ldrb w5, [x0, #1]
    cmp w5, #0x2A
    b.ne not_asterisk
    
    cmp x3, #0
    b.eq open_strong
    b close_strong
    
not_asterisk:
    cmp w4, #0x22 // quote
    b.eq escape_quote
    cmp w4, #0x5C // backslach
    b.eq escape_backslash
    cmp w4, #0x0A // \n
    b.eq escape_n
    cmp w4, #0x0D // \r 
    b.eq escape_n  // handle \r the same way as \n
    
    strb w4, [x1] // store normal chara
    add x0, x0, #1
    add x1, x1, #1
    b loop

open_strong:
    // Close span and open strong
    adrp x4, span_close@PAGE
    add x4, x4, span_close@PAGEOFF
    bl copy_string
    mov x3, #1 
    add x0, x0, #2 // Skip both asterisks
    mov x5, span_close_len
    sub x5, x5,  #3
    add x2, x2, x5
    b loop

close_strong:
    // Close strong and open new span
    adrp x4, strong_close@PAGE
    add x4, x4, strong_close@PAGEOFF
    bl copy_string
    mov x3, #0 
    add x0, x0, #2 // Skip both asterisks
    
    mov x5, strong_close_len
    sub x5, x5, #3
    add x2, x2, x5
    b loop
    
escape_quote:
    mov w4, #0x5C
    strb w4, [x1] // Store '\'
    mov w4, #0x22
    strb w4, [x1, #1] // Store "
    add x0, x0, #1
    add x1, x1, #2
    add x2, x2, #1
    b loop
    
escape_backslash:
    mov w4, #0x5C
    strb w4, [x1] // '\'
    strb w4, [x1, #1] // Store second '\'
    add x0, x0, #1
    add x1, x1, #2
    add x2, x2, #1
    b loop
    
escape_n:
    mov w4, #0x5c // "\" 
    strb w4, [x1] 
    mov w4, #0x6e // 'n'
    strb w4, [x1, #1]
    add x0, x0, #1
    add x1, x1, #2
    add x2, x2, #1
    b loop

// helper function to copy null-terminated string from x4 to x1
copy_string:
    stp x0, x2, [sp, #-16]!
copy_loop:
    ldrb w5, [x4], #1
    cbz w5, copy_done
    strb w5, [x1], #1
    b copy_loop
copy_done:
    ldp x0, x2, [sp], #16
    ret
    
done:
    mov w3, #0
    strb w3, [x1] // store null terminator
    ldp x29, x30, [sp], #16
    ret

print:
    mov x2, x1
    mov x1, x0
    mov x0, #1
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

    ; Check if it's a button request
    mov x0, sp
    adrp x1, button_url@PAGE
    add x1, x1, button_url@PAGEOFF
    bl _strstr
    cmp x0, #0
    b.eq handle_options

serve_rsc:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    mov x19, x20     ; Save socket fd

    ; Send header
    mov x0, x19
    adrp x1, rsc_header@PAGE
    add x1, x1, rsc_header@PAGEOFF
    mov x2, rsc_header_len
    mov x16, #4
    svc #0x80

    ; Debug print 1
    adrp x0, debug_msg1@PAGE
    add x0, x0, debug_msg1@PAGEOFF
    bl _printf

    ; Open file
    adrp x0, file_path@PAGE
    add x0, x0, file_path@PAGEOFF
    mov x1, #0 // O_RDONLY
    mov x2, #0644
    mov x16, #5
    svc #0x80
    
    mov x20, x0 // read file descriptr

    sub sp, sp, #16
    str x0, [sp]
    adrp x0, debug_msg2@PAGE
    add x0, x0, debug_msg2@PAGEOFF
    bl _printf
    add sp, sp, #16
    mov x0, x20

    cmp x20, #3
    b.lt file_error

    mov x0, x19
    adrp x1, response_start@PAGE
    add x1, x1, response_start@PAGEOFF
    mov x2, response_start_len
    mov x16, #4
    svc #0x80

    adrp x0, debug_msg3@PAGE
    add x0, x0, debug_msg3@PAGEOFF
    bl _printf

    mov x0, x20
    adrp x1, file_buffer@PAGE
    add x1, x1, file_buffer@PAGEOFF
    mov x2, #4095 // Leave space for null terminator
    mov x16, #3
    svc #0x80
    
    mov x21, x0 // actual length
    adrp x1, file_buffer@PAGE
    add x1, x1, file_buffer@PAGEOFF
    add x1, x1, x21
    strb wzr, [x1] // Store null terminator

    sub sp, sp, #16
    str x0, [sp]
    adrp x0, debug_msg4@PAGE
    add x0, x0, debug_msg4@PAGEOFF
    bl _printf
    add sp, sp, #16

    mov x0, x20
    mov x16, #6 // close file
    svc #0x80

    cmp x21, #0
    b.le file_done

    adrp x0, file_buffer@PAGE
    add x0, x0, file_buffer@PAGEOFF
    adrp x1, tmp_buffer@PAGE
    add x1, x1, tmp_buffer@PAGEOFF
    mov x2, x21
    bl escape_string // escape content for json encoding

    mov x0, x19 // write the new escaped file
    adrp x1, tmp_buffer@PAGE
    add x1, x1, tmp_buffer@PAGEOFF
    mov x16, #4 // write into the socket
    svc #0x80

file_done:
    mov x0, x19
    adrp x1, response_end@PAGE
    add x1, x1, response_end@PAGEOFF
    mov x2, response_end_len
    mov x16, #4
    svc #0x80

    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    b close_connection

file_error:
    sub sp, sp, #16
    mov x0, x20
    str x0, [sp]
    adrp x0, tmp_buffer@PAGE
    add x0, x0, tmp_buffer@PAGEOFF
    adrp x1, file_error_tree@PAGE
    add x1, x1, file_error_tree@PAGEOFF
    bl _sprintf
    add sp, sp, #16
    mov x0, x2 // length

    mov x0, x19// socket
    adrp x1, tmp_buffer@PAGE
    add x1, x1, tmp_buffer@PAGEOFF
    mov x2, file_error_tree_len
    mov x16, #4
    svc #0x80

    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    b close_connection

handle_options:
    mov x0, x20
    adrp x1, rsc_header@PAGE
    add x1, x1, rsc_header@PAGEOFF
    mov x2, rsc_header_len
    mov x16, #4
    svc #0x80
    b close_connection

close_connection:
    mov x0, x20
    mov x16, #6
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

