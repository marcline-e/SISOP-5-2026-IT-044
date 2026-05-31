# Soal 2 - Season

## Deskripsi
Mini OS 16-bit berbasis bare-metal yang berjalan di emulator Bochs. Dibuat menggunakan Assembly (NASM) dan C, dengan 2-stage bootloader.

## Struktur File
soal_2/
├── Makefile
├── README.md
├── bochsrc.txt      # Konfigurasi Bochs
├── bootloader.asm   # Stage 1 bootloader (512 bytes)
├── build.sh         # Script build
├── kernel.asm       # Stage 2 kernel assembly
└── kernel.c         # Kernel utama dalam C

## Cara Build
```bash
./build.sh
```
Output: `os.img`

## Cara Jalankan
1. Copy `os.img` ke Windows Desktop
2. Buka Bochs dengan `bochsrc.txt`
3. Klik Start/Continue

## Fitur
| Command | Deskripsi |
|---|---|
| `check` | Cek sistem berjalan |
| `add <a> <b>` | Penjumlahan |
| `sub <a> <b>` | Pengurangan |
| `fac <n>` | Faktorial (max 7, 16-bit limit) |
| `season <name>` | Ganti warna (winter/spring/summer/fall/radiant) |
| `triangle <n>` | Cetak segitiga |
| `clear` | Bersihkan layar |
| `help` | Tampilkan daftar command |

## Catatan
- OS berjalan di 16-bit real mode
- Dijalankan di Bochs x86 Emulator
- Package manager: 2-stage bootloader (stage1=512B, stage2=kernel)
