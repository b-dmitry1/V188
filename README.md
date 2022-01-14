# V188
FPGA 80186 IBM PC compatible system for Altera Cyclone IV (EP4CE15F23/EP4CE55F23)

16-bit real mode software will work good.

To play Dune 2 and Wolfenstein 3D just enable 286 CPU detection in the mcode.asm file:

    ; %define SHOW_8086 <- comment this line and rebuild the project

### BIOS
Please use this compact BIOS:

https://github.com/b-dmitry1/BIOS

### Compiling

Please use Quartus 13.0sp1 to compile the project.

### Using disk images

Images from e86r project will work good:

https://github.com/b-dmitry1/e86r

### Known problems
* USB detection / hot plugging sometimes fails.
* USB port 1 supports only a keyboard and port 2 supports only a mouse.
* No full-speed USB device support.
* VGA virtual resolution (panning) calculation may be wrong for some games.
* No FPU emulation.

### Disclaimer
The project is provided "as is" without any warranty. Use at your own risk.

Please tell me if you find some bug or if you plan to port it to another platform.
