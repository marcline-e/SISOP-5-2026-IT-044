#!/bin/bash

set -e

OUTPUT_DIR="osboot"

for f in bzImage single.gz multi.gz farewell.iso; do
    if [ ! -f "${OUTPUT_DIR}/${f}" ]; then
        echo "ERROR: ${OUTPUT_DIR}/${f} tidak ditemukan!"
        exit 1
    fi
done

TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
BACKUP_NAME="farewell_backup_${TIMESTAMP}.zip"

echo "=========================================="
echo " Membuat Backup: ${BACKUP_NAME}"
echo "=========================================="

zip -j "${OUTPUT_DIR}/${BACKUP_NAME}" \
    "${OUTPUT_DIR}/bzImage" \
    "${OUTPUT_DIR}/single.gz" \
    "${OUTPUT_DIR}/multi.gz" \
    "${OUTPUT_DIR}/farewell.iso"

rm "${OUTPUT_DIR}/bzImage" \
   "${OUTPUT_DIR}/single.gz" \
   "${OUTPUT_DIR}/multi.gz" \
   "${OUTPUT_DIR}/farewell.iso"

echo ""
echo "=========================================="
echo " SELESAI! Backup tersimpan di:"
echo " ${OUTPUT_DIR}/${BACKUP_NAME}"
echo "=========================================="

