; Mandelbrot in x86 assembly for Mac OS X
; Usage: /usr/local/bin/nasm -f macho mandel.asm && ld -macosx_version_min 10.7.0 -o mandel mandel.o && ./mandel

%define SIZE 80
%define LINELEN SIZE+1

global start

section .bss
line:   resb    LINELEN

section .text
start:
    mov byte [line+SIZE], `\n`  ; add newline after each line (this isn't overwritten)
    call draw
    jmp exit

draw:
    sub esp, 4      ; local variable: line index
    mov dword [esp], 80
_draw_loop:
    call fillline
    call printline
    dec dword [esp]
    jg _draw_loop
    add esp, 4
    ret

; params: line number
fillline:
    sub esp, 4      ; local variable: column index
    mov ebx, SIZE-1
_fillline_loop:

    mov byte [line+ebx], '#'
    dec ebx
    jge _fillline_loop
    add esp, 4
    ret

printline:
    push    dword LINELEN
    push    dword line
    push    dword 1
    mov     eax, 4      ; syscall: write
    sub     esp, 4      ; extra space on stack
    int     0x80
    add     esp, 16     ; reset stack
    ret

exit:
    push    dword 0     ; exit status: 0
    mov     eax, 1      ; syscall: exit
    sub     esp, 4
    int     0x80
