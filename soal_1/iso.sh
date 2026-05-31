#!/bin/bash

set -e

OUTPUT_DIR="osboot"
ISO_DIR="iso_root"

echo "=========================================="
echo " Membuat Bootable ISO"
echo "=========================================="

if [ ! -f "${OUTPUT_DIR}/bzImage" ]; then
    echo "ERROR: bzImage tidak ditemukan! Jalankan kernel.sh dulu."
    exit 1
fi
if [ ! -f "${OUTPUT_DIR}/single.gz" ]; then
    echo "ERROR: single.gz tidak ditemukan! Jalankan single.sh dulu."
    exit 1
fi
if [ ! -f "${OUTPUT_DIR}/multi.gz" ]; then
    echo "ERROR: multi.gz tidak ditemukan! Jalankan multi.sh dulu."
    exit 1
fi

echo "[1/3] Membuat struktur ISO..."

rm -rf "${ISO_DIR}"
mkdir -p "${ISO_DIR}/boot/grub"

cp "${OUTPUT_DIR}/bzImage"   "${ISO_DIR}/boot/bzImage"
cp "${OUTPUT_DIR}/single.gz" "${ISO_DIR}/boot/single.gz"
cp "${OUTPUT_DIR}/multi.gz"  "${ISO_DIR}/boot/multi.gz"

echo "[2/3] Membuat konfigurasi GRUB..."
cat > "${ISO_DIR}/boot/grub/grub.cfg" << 'EOF'
set timeout=10
set default=0

menuentry "Farewell Party OS - Single User" {
    echo "Loading kernel..."
    linux /boot/bzImage quiet
    echo "Loading single-user filesystem..."
    initrd /boot/single.gz
    boot
}

menuentry "Farewell Party OS - Multi User" {
    echo "Loading kernel..."
    linux /boot/bzImage quiet
    echo "Loading multi-user filesystem..."
    initrd /boot/multi.gz
    boot
}
EOF

echo "[3/3] Membuat farewell.iso..."
grub-mkrescue -o "${OUTPUT_DIR}/farewell.iso" "${ISO_DIR}" 2>/dev/null
rm -rf "${ISO_DIR}"

echo ""
echo "=========================================="
echo " SELESAI! ISO berhasil dibuat."
echo " Output: ${OUTPUT_DIR}/farewell.iso"
echo "=========================================="