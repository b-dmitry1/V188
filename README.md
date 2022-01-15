# V188

FPGA 80186 IBM PC compatible system for Altera Cyclone IV (EP4CE15F23/EP4CE55F23).

* Compact CPU implementation (CPU can fit in 1500-2300 LEs and 4-6 M9K ROM blocks!).
* Easy-to-understand extensible FPGA-accelerated microcode.
* Inexpensive 4-layer PCB.
* A minimal set of inexpensive external components is required. All the electronic components can be easily found on AliExpress or eBay.
* Can be used with lower capacity FPGA devices if you don't need music in games.
* Up to 50 MHz input clock speed.

The CPU is a simple **stack virtual machine** with a specialized reduced instruction set.

Execution algorithm:

1. The VM fetches an opcode from system memory pointed by CS:IP.
2. There is a table of instruction code locations at the beginning of a microcode file. Using a loaded opcode value the VM starts processing microcode by table-jumping.
3. VM emulates real CPU behavior by sequentially executing microcode instructions.
4. When END microcode instruction is executed VM resets temporary state registers and instruction prefixes, checks pending interrupt requests, and repeats the algorithm from step 1.

Microcode example for table translation (XLAT) instruction:

```assembly
; xlat
LOADREG BX      ; Push BX register into VM stack
LOADREG8 AL     ; Push AL register into VM stack
ADD             ; Add two values on the top of VM stack and push back the result
SETOFS          ; Save value on the top of VM stack as a memory address (offset)
READ8           ; Read 8-bit value from system RAM pointed by the data segment register
                ; and an address saved in a previous instruction
                ; Data segment register is DS unless overridden by instruction prefix
STOREREG8 AL    ; Save the result into AL register
END             ; Go to a next instruction
```

![V188 diagram](pictures/V188diagram.png)

To play Dune 2 and Wolfenstein 3D just enable 286 CPU detection in the mcode.asm file:

    %define SHOW_8086

Comment this line, compile and update the project firmware. This line should be uncommented if you want to run Windows or Minix in 16-bit real mode.

![V188](pictures/V188.jpg)

## Printed circuit board (PCB)

PCB Gerber files can be found in a [Gerber directory](Gerber/).

## BIOS

Please use this compact BIOS:

<https://github.com/b-dmitry1/BIOS>

## VGA

* CGA/EGA/VGA video card emulation.
* Linear / Planar addressing support.
* Simple EGA/VGA graphics processor (pipeline) compatible with most old games and Microsoft Windows.
* Planar 320x240x256 colors (mode X) support.
* 2 x 64-bit GPU data buses designed to unload RAM controller.
* The framebuffer can be located in the main system memory or in a dedicated video RAM.

## SoundBlaster

* 8-bit digital sound effects with DMA support.
* Unprecise but very simple extensible AdLib emulation.
* High-quality PWM output requires only 1-2 resistors and 1 ceramic capacitor.

AdLib consumes a lot of FPGA resources. Precise YM3812 emulation may require 30K LEs or even more.

## SDRAM controller

* Very simple and compact finite state machine design.
* Multiple channels. Additional channels can be easily added.
* Different bus widths.
* Automatic SDRAM refresh.
* Designed for cheap 16/32 megabyte SDRAM ICs.

## Memory card interface

Up to 32GB memory card with SPI support can be used.

Only 504 MB will be available due to 16-bit BIOS's limitations.

## USB

This version contains a new USB module with a dedicated parallel processing core designed to operate independently from a main CPU.
Firmware for this fast module is not completed.
Please use an old implementation from deprecated/USB folder or a Serial Port as a keyboard.

There are 4 USB ports on the board.
In this version only 2 low-speed ports are available.
The first one should be used for a keyboard and the second one for mouse.

USB needs a special BIOS driver to work properly.

## Compiling

Please use Quartus 13.0sp1 to compile the project.

To compile from a command line use "compile.bat" script.

## Disk images

Images from [e86r project](https://github.com/b-dmitry1/e86r) will work good.

Just write an 504 MB image on an SD card as described in the STM32 section of e86r.

![Lines game screenshot](pictures/ColorLines.jpg)

![Solitare game screenshot](pictures/Solit.jpg)

## Known problems

* USB detection / hot plugging sometimes fails.
* USB port 1 supports only a keyboard and port 2 supports only a mouse. (BIOS problem)
* Only low-speed USB device support.
* VGA virtual resolution (panning) calculation may be wrong for some games.
* No FPU emulation.

## Disclaimer

The project is provided "as is" without any warranty. Use at your own risk.

Please contact me if you find any bug or if you plan to port it to another platform.
