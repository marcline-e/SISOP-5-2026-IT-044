#!/bin/bash

OUTPUT_DIR="osboot"

if [ $# -eq 0 ]; then
    echo "Usage: ./qemu.sh --single | --multi | --all"
    exit 1
fi

case "$1" in
    --single)
        echo "Booting single-user filesystem..."
        qemu-system-x86_64 \
            -kernel "${OUTPUT_DIR}/bzImage" \
            -initrd "${OUTPUT_DIR}/single.gz" \
            -append "console=ttyS0" \
            -nographic \
            -m 512M \
            -net nic,model=e1000\
            -net user
        ;;

    --multi)
        echo "Booting multi-user filesystem..."
        qemu-system-x86_64 \
            -kernel "${OUTPUT_DIR}/bzImage" \
            -initrd "${OUTPUT_DIR}/multi.gz" \
            -append "console=ttyS0" \
            -nographic \
            -m 512M \
            -netdev user,id=net0 \
            -device e1000,netdev=net0
        ;;

    --all)
        echo "Booting dari ISO (menu GRUB)..."
        qemu-system-x86_64 \
            -cdrom "${OUTPUT_DIR}/farewell.iso" \
            -boot d \
            -nographic \
            -m 512M
        ;;

    *)
        echo "Argument tidak dikenal: $1"
        echo "Usage: ./qemu.sh --single | --multi | --all"
        exit 1
        ;;
esac