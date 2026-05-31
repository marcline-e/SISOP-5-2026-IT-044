#!/bin/bash

set -e

KERNEL_VERSION="6.1.1"
KERNEL_DIR="linux-${KERNEL_VERSION}"
KERNEL_TAR="${KERNEL_DIR}.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TAR}"
OUTPUT_DIR="osboot"

echo "=========================================="
echo " Kompilasi Linux Kernel ${KERNEL_VERSION}"
echo "=========================================="

mkdir -p "${OUTPUT_DIR}"

if [ ! -f "${KERNEL_TAR}" ]; then
    echo "[1/4] Downloading Linux Kernel ${KERNEL_VERSION}..."
    wget -c "${KERNEL_URL}" -O "${KERNEL_TAR}"
else
    echo "[1/4] File ${KERNEL_TAR} sudah ada, skip download."
fi

if [ ! -d "${KERNEL_DIR}" ]; then
    echo "[2/4] Mengekstrak ${KERNEL_TAR}..."
    tar -xf "${KERNEL_TAR}"
else
    echo "[2/4] Folder ${KERNEL_DIR} sudah ada, skip ekstrak."
fi

echo "[3/4] Mengkonfigurasi kernel (defconfig)..."
cd "${KERNEL_DIR}"
make defconfig

echo "[4/4] Compile kernel... "
make -j$(nproc) KCFLAGS="-w"


echo ""
echo "Menyalin bzImage ke ../${OUTPUT_DIR}/bzImage ..."
cp arch/x86/boot/bzImage "../${OUTPUT_DIR}/bzImage"

cd ..

echo ""
echo "=========================================="
echo " SELESAI! Kernel berhasil di-compile."
echo " Output: ${OUTPUT_DIR}/bzImage"
echo "=========================================="