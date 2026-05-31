# Makefile untuk Soal 2 - Season OS

all: build

build:
	./build.sh

clean:
	rm -f bootloader.bin kernel_asm.o kernel_c.o kernel.elf kernel_stage2.bin kernel_raw.bin os.img bochs.log

run:
	cp os.img /mnt/c/Users/noteb/OneDrive/Desktop/os.img
	@echo "os.img copied to Windows Desktop. Run Bochs manually."

.PHONY: all build clean run
