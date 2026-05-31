# Laporan Resmi - Soal Shift Modul 5
# Sistem Operasi 2026

## Identitas
| | |
|---|---|
| **Nama** | [NAMA] |
| **NRP** | [NRP] |
| **Kelas** | [KELAS] |

---

## Soal 1 - Farewell Party

### Deskripsi
Membuat otomasi script Bash untuk kompilasi Linux Kernel 6.1.1, pembuatan filesystem (single dan multi-user) menggunakan BusyBox, pembuatan ISO bootable, serta implementasi internet access, package manager, dan FUSE.

### Struktur File
```
soal_1/
├── .config          # Konfigurasi kernel Linux
├── backup.sh        # Script backup hasil build
├── iso.sh           # Script pembuatan ISO bootable
├── kernel.sh        # Script kompilasi Linux kernel
├── multi.sh         # Script pembuatan multi-user filesystem
├── osboot/          # Folder hasil build
├── qemu.sh          # Script menjalankan OS di QEMU
└── single.sh        # Script pembuatan single-user filesystem
```

### Penjelasan Script

#### 1. `kernel.sh`
Script untuk mendownload dan mengompilasi Linux Kernel versi 6.1.1.
- Download source code dari kernel.org
- Konfigurasi dengan `make defconfig`
- Kompilasi dengan `make -j$(nproc)`
- Output: `osboot/bzImage`

#### 2. `single.sh`
Script untuk membuat single-user filesystem menggunakan BusyBox.
- Download dan compile BusyBox (static linking)
- Membuat struktur direktori: `bin/, dev/, proc/, sys/, etc/, tmp/, root/`
- User: root only (tanpa password)
- Konfigurasi network (DHCP + static fallback)
- Package manager `party` berbasis Alpine APK
- Program FUSE sederhana (`hello_fuse`)
- Output: `osboot/single.gz`

#### 3. `multi.sh`
Script untuk membuat multi-user filesystem menggunakan BusyBox.
- User: root, henn, hann, viii, kids
- Password masing-masing user di-hash dengan openssl
- Permission sesuai spesifikasi soal
- Banner ASCII art "Farewell Party" saat login
- Konfigurasi network (DHCP + static fallback)
- Package manager `party` berbasis Alpine APK
- Program FUSE dengan `/dev/fuse` support
- Output: `osboot/multi.gz`

#### 4. `iso.sh`
Script untuk membuat bootable ISO menggunakan GRUB.
- Membuat struktur ISO dengan `grub.cfg`
- Menu boot: pilih single atau multi filesystem
- Output: `osboot/farewell.iso`

#### 5. `qemu.sh`
Script untuk menjalankan OS di QEMU.

| Command | Fungsi |
|---|---|
| `./qemu.sh --single` | Boot single-user filesystem |
| `./qemu.sh --multi` | Boot multi-user filesystem |
| `./qemu.sh --all` | Boot dari ISO (menu GRUB) |

#### 6. `backup.sh`
Script untuk backup semua hasil build.
- Zip: `bzImage`, `single.gz`, `multi.gz`, `farewell.iso`
- Format nama: `farewell_backup_[DDMMYYYY-HHMMSS].zip`
- File asli dihapus setelah diarsip

### Dokumentasi Output

#### kernel.sh - Kompilasi Kernel
![kernel.sh output](dokumentasi/kernel_compile.png)

#### single.sh - Single User Filesystem
![single boot](dokumentasi/single_boot.png)

#### multi.sh - Multi User Filesystem & Login
![multi login](dokumentasi/multi_login.png)

#### Internet Access (wget)
![wget google](dokumentasi/wget_google.png)

#### Package Manager (party)
![party install](dokumentasi/party_install.png)

#### FUSE
![fuse demo](dokumentasi/fuse_demo.png)

#### iso.sh - Bootable ISO & GRUB Menu
![grub menu](dokumentasi/grub_menu.png)

#### backup.sh - Backup
![backup result](dokumentasi/backup_result.png)

---

## Soal 2 - Season

### Deskripsi
Membuat mini Operating System 16-bit dari nol (bare-metal) menggunakan Assembly (NASM) dan C, dijalankan di emulator Bochs x86.

### Struktur File
```
soal_2/
├── Makefile
├── README.md
├── bochsrc.txt      # Konfigurasi Bochs
├── bootloader.asm   # Stage 1 bootloader (512 bytes)
├── build.sh         # Script build
├── kernel.asm       # Stage 2 kernel assembly
└── kernel.c         # Kernel utama dalam C
```

### Arsitektur OS

```
┌─────────────────────────────────┐
│  Stage 1: bootloader.asm        │ ← BIOS load ke 0x7C00
│  (512 bytes, sektor 1)          │
│  - Setup segment registers      │
│  - Load stage 2 dari disk       │
│  - Jump ke 0x0000:0x8000        │
└─────────────────┬───────────────┘
                  │
                  ▼
┌─────────────────────────────────┐
│  Stage 2: kernel.asm + kernel.c │ ← Load ke 0x8000
│  - Setup environment            │
│  - Panggil kernel_main()        │
│  - BIOS interrupt handlers      │
└─────────────────────────────────┘
```

### Penjelasan File

#### `bootloader.asm`
2-stage bootloader stage 1. Bertugas:
- Setup segment registers
- Load kernel (stage 2) dari floppy disk ke memori 0x8000
- Jump ke kernel

#### `kernel.asm`
Assembly interface antara bootloader dan kernel C. Berisi:
- Setup environment untuk kode C
- Fungsi `_getChar`, `_putChar`, `_setColor`, `_clearScreen` menggunakan BIOS interrupt

#### `kernel.c`
Kernel utama dalam C. Berisi implementasi semua fitur:

| Command | Fungsi |
|---|---|
| `check` | Cek sistem berjalan → `ok` |
| `add <a> <b>` | Penjumlahan dua angka |
| `sub <a> <b>` | Pengurangan dua angka |
| `fac <n>` | Faktorial (16-bit, overflow → pesan limit) |
| `season <name>` | Ganti warna teks (winter/spring/summer/fall/radiant) |
| `triangle <n>` | Cetak segitiga dari karakter 'x' |
| `clear` | Bersihkan layar |
| `help` | Tampilkan daftar command |

#### `build.sh`
Script build otomatis:
1. Compile `bootloader.asm` → `bootloader.bin`
2. Compile `kernel.asm` → ELF object
3. Compile `kernel.c` → ELF object
4. Link semua → `kernel_stage2.bin`
5. Buat `os.img` (floppy 1.44MB)

#### `bochsrc.txt`
Konfigurasi Bochs untuk menjalankan `os.img`.

### Cara Build dan Jalankan
```bash
# Build
./build.sh

# Copy ke Windows (untuk Bochs)
cp os.img /mnt/c/Users/[USERNAME]/Desktop/os.img

# Jalankan Bochs di Windows dengan bochsrc.txt
```

### Dokumentasi Output

#### Boot OS & Welcome Screen
![welcome screen](dokumentasi/welcome.png)

#### check
![check](dokumentasi/check.png)

#### add & sub
![add sub](dokumentasi/add_sub.png)

#### fac
![fac](dokumentasi/fac.png)

#### season
![season](dokumentasi/season.png)

#### triangle
![triangle](dokumentasi/triangle.png)

#### clear & help
![clear help](dokumentasi/clear_help.png)

---

## Kendala dan Solusi

| Kendala | Solusi |
|---|---|
| GCC terlalu strict saat compile kernel | Tambahkan flag `KCFLAGS="-w"` |
| BusyBox error `networking/tc.c` | Disable `CONFIG_TC` di .config |
| Symlink BusyBox absolut | Gunakan `ln -sf busybox` manual |
| QEMU ping gagal di WSL2 | Gunakan TCP (wget) sebagai pengganti ICMP |
| Bochs tidak bisa baca `os.img` dari path WSL | Copy `os.img` ke Windows Desktop |
| Kernel 16-bit tidak bisa load dari 2-stage | Gunakan `-Ttext 0x8000` dan load ke `0x0000:0x8000` |
