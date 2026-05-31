#!/bin/bash

set -e

BUSYBOX_VERSION="1.36.1"
BUSYBOX_TAR="busybox-${BUSYBOX_VERSION}.tar.bz2"
BUSYBOX_URL="https://busybox.net/downloads/${BUSYBOX_TAR}"
BUSYBOX_DIR="busybox-${BUSYBOX_VERSION}"
OUTPUT_DIR="osboot"
ROOTFS_DIR="rootfs_single"

echo "=========================================="
echo " Membuat Single-User Filesystem"
echo "=========================================="

mkdir -p "${OUTPUT_DIR}"

if [ ! -f "${BUSYBOX_TAR}" ]; then
    echo "[1/6] Downloading BusyBox ${BUSYBOX_VERSION}..."
    wget -c "${BUSYBOX_URL}" -O "${BUSYBOX_TAR}"
else
    echo "[1/6] BusyBox sudah ada, skip download."
fi

if [ ! -d "${BUSYBOX_DIR}" ]; then
    echo "[2/6] Mengekstrak BusyBox..."
    tar -xf "${BUSYBOX_TAR}"
else
    echo "[2/6] Folder BusyBox sudah ada, skip ekstrak."
fi

echo "[3/6] Mengcompile BusyBox..."
cd "${BUSYBOX_DIR}"
make defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config
make -j$(nproc) CFLAGS="-w"
cd ..

echo "[4/6] Membuat struktur direktori..."
rm -rf "${ROOTFS_DIR}"
mkdir -p "${ROOTFS_DIR}"

mkdir -p "${ROOTFS_DIR}"/{bin,dev,proc,sys,etc,tmp,root}
cp "${BUSYBOX_DIR}/busybox" "${ROOTFS_DIR}/bin/busybox"
WORK_DIR="$(pwd)"
cd "${ROOTFS_DIR}/bin"
for cmd in $(./busybox --list); do
    ln -sf busybox "$cmd"
done
cd "${WORK_DIR}"

echo "[5/6] Membuat konfigurasi sistem..."

cat > "${ROOTFS_DIR}/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/sh
EOF

cat > "${ROOTFS_DIR}/etc/shadow" << 'EOF'
root::0:0:99999:7:::
EOF

cat > "${ROOTFS_DIR}/etc/group" << 'EOF'
root:x:0:root
EOF

cat > "${ROOTFS_DIR}/init" << 'EOF'
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || mdev -s

hostname single-os

ifconfig eth0 up
udhcpc -i eth0 2>/dev/null || true
ifconfig eth0 10.0.2.15 netmask 255.255.255.0
ip route add default via 10.0.2.2 2>/dev/null || true
echo "nameserver 10.0.2.3" > /etc/resolv.conf

exec /bin/sh
EOF

chmod +x "${ROOTFS_DIR}/init"
chmod 1777 "${ROOTFS_DIR}/tmp"

echo "Menyalin package manager sebagai 'party'..."
cat > "${ROOTFS_DIR}/bin/party" << 'EOF'
#!/bin/sh
# party - simple package manager berbasis Alpine APK

ALPINE_REPO="http://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64"

case "$1" in
    --version)
        echo "party version 1.0.0"
        ;;
    install)
        if [ -z "$2" ]; then
            echo "Usage: party install <package>"
            exit 1
        fi
        PKG="$2"
        echo "party: fetching package index..."
        wget -q -O /tmp/APKINDEX.tar.gz "${ALPINE_REPO}/APKINDEX.tar.gz"
        tar -xzf /tmp/APKINDEX.tar.gz -C /tmp 2>/dev/null
        VERSION=$(grep -A1 "^P:${PKG}$" /tmp/APKINDEX | grep "^V:" | cut -d: -f2)
        if [ -z "$VERSION" ]; then
            echo "party: package '${PKG}' not found"
            exit 1
        fi
        echo "party: installing ${PKG}-${VERSION}..."
        echo "${ALPINE_REPO}/${PKG}-${VERSION}.apk" > /tmp/pkgurl.txt
        wget -q -O /tmp/${PKG}.apk $(cat /tmp/pkgurl.txt)
        if [ $? -eq 0 ]; then
            tar -xzf /tmp/${PKG}.apk -C / 2>/dev/null
            echo "party: ${PKG} installed successfully"
        else
            echo "party: failed to install ${PKG}"
            exit 1
        fi
        ;;
    *)
        echo "Usage: party --version | party install <package>"
        ;;
esac
EOF
chmod +x "${ROOTFS_DIR}/bin/party"

echo "Membuat program FUSE..."
mkdir -p "${ROOTFS_DIR}/fuse_example"

cat > /tmp/hello_fuse.c << 'EOF'
#define FUSE_USE_VERSION 30
#include <fuse.h>
#include <string.h>
#include <errno.h>

static const char *hello_str = "Hello from FUSE!\n";
static const char *hello_path = "/hello.txt";

static int hello_getattr(const char *path, struct stat *stbuf) {
    memset(stbuf, 0, sizeof(struct stat));
    if (strcmp(path, "/") == 0) {
        stbuf->st_mode = S_IFDIR | 0755;
        stbuf->st_nlink = 2;
    } else if (strcmp(path, hello_path) == 0) {
        stbuf->st_mode = S_IFREG | 0444;
        stbuf->st_nlink = 1;
        stbuf->st_size = strlen(hello_str);
    } else {
        return -ENOENT;
    }
    return 0;
}

static int hello_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
                         off_t offset, struct fuse_file_info *fi) {
    filler(buf, ".", NULL, 0);
    filler(buf, "..", NULL, 0);
    filler(buf, "hello.txt", NULL, 0);
    return 0;
}

static int hello_open(const char *path, struct fuse_file_info *fi) {
    if (strcmp(path, hello_path) != 0)
        return -ENOENT;
    return 0;
}

static int hello_read(const char *path, char *buf, size_t size,
                      off_t offset, struct fuse_file_info *fi) {
    size_t len = strlen(hello_str);
    if (offset >= len) return 0;
    if (offset + size > len) size = len - offset;
    memcpy(buf, hello_str + offset, size);
    return size;
}

static struct fuse_operations hello_oper = {
    .getattr = hello_getattr,
    .readdir = hello_readdir,
    .open    = hello_open,
    .read    = hello_read,
};

int main(int argc, char *argv[]) {
    return fuse_main(argc, argv, &hello_oper, NULL);
}
EOF

gcc -o "${ROOTFS_DIR}/fuse_example/hello_fuse" /tmp/hello_fuse.c \
    $(pkg-config --cflags --libs fuse) -static 2>/dev/null || \
gcc -o "${ROOTFS_DIR}/fuse_example/hello_fuse" /tmp/hello_fuse.c \
    -I/usr/include/fuse -lfuse -lpthread -static

echo "FUSE program berhasil dibuat!"

echo "[6/6] Membuat single.gz..."
SCRIPT_DIR="$(pwd)"
cd "${ROOTFS_DIR}"
find . | cpio --quiet -H newc -o | gzip -9 > "${SCRIPT_DIR}/${OUTPUT_DIR}/single.gz"
cd ..
rm -rf "${ROOTFS_DIR}"

echo ""
echo "=========================================="
echo " SELESAI! Single filesystem berhasil dibuat."
echo " Output: ${OUTPUT_DIR}/single.gz"
echo "=========================================="