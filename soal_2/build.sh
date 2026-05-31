#!/bin/bash

set -e

echo "=========================================="
echo " Building OS..."
echo "=========================================="

for tool in nasm gcc ld; do
    if ! which $tool > /dev/null 2>&1; then
        echo "ERROR: $tool tidak ditemukan!"
        exit 1
    fi
done

echo "[1/4] Compiling bootloader..."
nasm -f bin bootloader.asm -o bootloader.bin

echo "[2/4] Compiling kernel.asm..."
nasm -f elf kernel.asm -o kernel_asm.o

echo "[3/4] Compiling kernel.c..."
gcc -m16 -ffreestanding -fno-pie -nostdlib -nostdinc \
    -fno-stack-protector -mregparm=3 \
    -c kernel.c -o kernel_c.o

echo "[4/4] Linking..."
ld -m elf_i386 -Ttext 0x8000 --oformat binary \
    -o kernel_stage2.bin kernel_asm.o kernel_c.o

echo "Membuat disk image..."
dd if=/dev/zero of=os.img bs=512 count=2880 2>/dev/null
dd if=bootloader.bin of=os.img bs=512 count=1 conv=notrunc 2>/dev/null
dd if=kernel_stage2.bin of=os.img bs=512 seek=1 conv=notrunc 2>/dev/null

echo "Copying os.img to Windows Desktop..."
cp os.img /mnt/c/Users/noteb/OneDrive/Desktop/os.img 2>/dev/null || true

echo ""
echo "=========================================="
echo " SELESAI! Output: os.img"
echo "=========================================="