# V188 Gerber files

This folder contains Gerber PCB files of the board.

Technology:

* 4 layers.
* Minimum hole diameter is 0.3 mm.
* Via diameter is 0.6 mm.
* Track width min 0.127 mm.
* Track-to-pad min 0.127 mm.
* Track-to-track min 0.127 mm.

Most popular PCB factories should accept it without applying a price multiplier.

I have paid only $7 for 5 pcs on jlcpcb.com

![V188 PCB](../pictures/V188pcb.jpg)

ICs:

* EP4CE55F23C8N - FPGA
* W25Q64 - Configuration EEPROM
* W9825G6KHC1 - SDRAM
* IS61LV25616 - Video SRAM
* CH340C - Debug UART to USB
* AMS1117-3.3 - 3.3 V power converter
* AMS1117-2.5 - 2.5 V power converter
* AMS1117-1.2 - 1.2 V power converter
* 50 MHz active crystal generator

Please do not connect 5 V ICs/devices directly to FPGA!

Refer to Cyclone IV datasheet for voltage overshoot diagrams.

![Cyclone IV EP4CE55 chips](../pictures/EP4CE55.jpg)
