# gdb -x mandel.gdb ./mandel

set disassembly-flavor intel

define nf
nexti
disassemble
info float
end

define cf
continue
info float
end

break is_mandelbrot if $st1 == 0
run
info float

define fpus
disable 1
break is_mandelbrot_check if $edx == 64
end