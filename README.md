## mandel.asm

This is my first time trying out x86 assembly, and my first time plotting Mandelbrot (though I did a quick prototype in Node.js). I know the calculations could be done using SSE, but I decided to use the classic 8087 FPU instructions to learn what my ancestors worked with. I even decided to just work on the FPU stack as much as I could.

I've written a bit of MMIX assembly and the TIS-100 pseudo-assembly before, but nothing that could run on real-world hardware. Any code review comments and such are welcome.
