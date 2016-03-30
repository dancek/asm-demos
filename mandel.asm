; Mandelbrot in x86 assembly for Mac OS X
; Usage: /usr/local/bin/nasm -f macho mandel.asm && ld -macosx_version_min 10.7.0 -o mandel mandel.o && ./mandel

%define SIZE 40
%define ITERATIONS 64
%define LINELEN SIZE+1

global start

section .bss
line:   resb    LINELEN

section .text
start:
    mov byte [line+SIZE], `\n`  ; add newline after each line (this isn't overwritten)
    finit
    call draw
    jmp exit

draw:
    ; local variable: line index
    push dword SIZE
_draw_loop:
    call fill_line
    call print_line
    dec dword [esp]
    jg _draw_loop
    add esp, 4
    ret


;;; build a single line in the `line` memory area
; params:
;   [esp+4] line number

fill_line:
    mov     ebx, SIZE-1
_fill_line_loop:
    ; compute st(0) and st(1) from row and column
    ; st(1): c_i or line
    push    dword [esp+4]
    sub     dword [esp], SIZE/2
    fild    dword [esp]
    push    SIZE/2
    fidiv   dword [esp]
    ; st(0): c_r or column
    push    dword ebx
    sub     dword [esp], SIZE/2
    fild    dword [esp]
    push    SIZE/2
    fidiv   dword [esp]
    add     esp, 16     ; reset after 4 dword pushes
    ; run mandelbrot iteration and add character
    call    is_mandelbrot
    fninit      ; clear FPU stack
    cmp     eax, 0
    je      _fill_line_false
_fill_line_true:
    mov     byte [line+ebx], '#'
    jmp     _fill_line_next
_fill_line_false:
    mov     byte [line+ebx], '.'
_fill_line_next:
    dec     ebx
    jge     _fill_line_loop
    ret

print_line:
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


;;; check if given coordinates belong in the mandelbrot set
;   (implemented using just the floating-point stack for practice; it would
;    be more readable and easier using fst+fld with memory)
; params:
;   st0 c_r
;   st1 c_i
; return:
;   eax: 1 if in set; 0 if not
; computation: z=z^2+c, pseudocode: (temp = z*z; z = temp+c;)

is_mandelbrot:
    mov edx, ITERATIONS
        ; stack: c_r, c_i
    fldz
    fldz
    jmp _is_mandelbrot_check    ; start with squaring z_r and z_i
_is_mandelbrot_loop:
        ; stack: z_r, z_i, c_r, c_i
    dec edx
    jz _is_mandelbrot_false
    ; temp_i = 2 * z_r^2
    fldz
        ; stack: temp_i, z_r^2, z_i^2, c_r, c_i
    fadd    st0, st1
    fadd    st0, st1
    ; temp_r = z_r^2 - z_i^2
    fldz
    fadd    st0, st2
    fsub    st0, st3
fpu:
        ; stack: temp_r, temp_i, z_r^2, z_i^2, c_r, c_i
    ; shuffle stack
    fxch    st2
    fstp    st0     ; pop and discard
    fxch    st2
    fstp    st0
        ; stack: temp_r, temp_i, c_r, c_i
    ; z_r = temp_r + c_r
    fadd    st0, st2    ; z_r += c_r
    ; z_i = temp_i + c_i
    fincstp
    fadd    st0, st2    ; z_i += c_i
    fdecstp
        ; stack: z_r, z_i, c_r, c_i
_is_mandelbrot_check:
    ; square z_r and z_i (because we only need the squares)
    fmul    st0, st0
    fincstp
    fmul    st0, st0
    fdecstp
    ; check z_r^2 + z_i^2 > 4
    push    dword -4
    fild    dword [esp]
    add     esp, 4
    fadd    st1
    fadd    st2
    ; test st0 > 0
    ftst
    fstsw   ax
    fwait
    fstp    st0
    sahf
    jb _is_mandelbrot_loop
_is_mandelbrot_true:
    mov     eax, 1
    ret
_is_mandelbrot_false:
    mov     eax, 0
    ret