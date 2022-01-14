@echo off

..\nasm mcode.asm -o mcode.bin
if errorlevel 1 goto end

..\bin2mif 32 mcode.bin

i:
cd \2\altera\TestEP4CE6F17
c:\altera\13.0sp1\quartus\bin64\quartus_cdb TestEP4CE6F17 -c Main --update_mif
c:\altera\13.0sp1\quartus\bin64\quartus_asm --read_settings_files=on --write_settings_files=off TestEP4CE6F17 -c Main
c:\altera\13.0sp1\quartus\bin64\quartus_pgm -c usb-blaster -m JTAG -o p;output_files\Main.sof
c:

:end
pause