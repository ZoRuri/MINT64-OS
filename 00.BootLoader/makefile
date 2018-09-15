all: BootLoader.bin

BootLoader.bin: BootLoader.asm
	nasm -o BootLoader.bin BootLoader.asm
	
cleam:
	rm -f BootLoader.bin