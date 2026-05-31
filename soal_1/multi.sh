#!/bin/bash

set -e

BUSYBOX_DIR="busybox-1.36.1"
OUTPUT_DIR="osboot"
ROOTFS_DIR="rootfs_multi"

echo "=========================================="
echo " Membuat Multi-User Filesystem"
echo "=========================================="

mkdir -p "${OUTPUT_DIR}"


echo "[1/4] Membuat struktur direktori..."
rm -rf "${ROOTFS_DIR}"
mkdir -p "${ROOTFS_DIR}"
mkdir -p "${ROOTFS_DIR}"/{bin,dev,proc,sys,etc,tmp,root}
mkdir -p "${ROOTFS_DIR}"/home/{henn,hann,viii,kids}
cp "${BUSYBOX_DIR}/busybox" "${ROOTFS_DIR}/bin/busybox"
WORK_DIR="$(pwd)"
cd "${ROOTFS_DIR}/bin"
for cmd in $(./busybox --list); do
    ln -sf busybox "$cmd"
done
cd "${WORK_DIR}"

echo "[2/4] Membuat konfigurasi user..."
cat > "${ROOTFS_DIR}/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/sh
henn:x:1000:1000:henn:/home/henn:/bin/sh
hann:x:1001:1001:hann:/home/hann:/bin/sh
viii:x:1002:1002:viii:/home/viii:/bin/sh
kids:x:1003:1003:kids:/home/kids:/bin/sh
EOF

ROOT_HASH=$(openssl passwd -1 "root123")
HENN_HASH=$(openssl passwd -1 "henn123")
HANN_HASH=$(openssl passwd -1 "hann123")
VIII_HASH=$(openssl passwd -1 "viii123")
KIDS_HASH=$(openssl passwd -1 "kids123")

cat > "${ROOTFS_DIR}/etc/shadow" << EOF
root:${ROOT_HASH}:0:0:99999:7:::
henn:${HENN_HASH}:0:0:99999:7:::
hann:${HANN_HASH}:0:0:99999:7:::
viii:${VIII_HASH}:0:0:99999:7:::
kids:${KIDS_HASH}:0:0:99999:7:::
EOF

cat > "${ROOTFS_DIR}/etc/group" << 'EOF'
root:x:0:root
henn:x:1000:henn
hann:x:1001:hann
viii:x:1002:viii
kids:x:1003:kids
EOF

cat > "${ROOTFS_DIR}/etc/profile" << 'EOF'
echo ""
echo " _____   ____  ____     ___ __    __    ___  _      _          ____   ____  ____  ______  __ __ "
echo "|     | /    ||    \   /  _]  |__|  |  /  _]| |    | |        |    \ /    ||    \|      ||  |  |"
echo "|   __||  o  ||  D  ) /  [_|  |  |  | /  [_ | |    | |        |  o  )  o  ||  D  )      ||  |  |"
echo "|  |_  |     ||    / |    _]  |  |  ||    _]| |___ | |___     |   _/|     ||    /|_|  |_||  ~  |"
echo "|   _] |  _  ||    \ |   [_|  \`  '  ||   [_ |     ||     |    |  |  |  _  ||    \  |  |  |___, |"
echo "|  |   |  |  ||  .  \|     |\      / |     ||     ||     |    |  |  |  |  ||  .  \ |  |  |     |"
echo "|__|   |__|__||__|\_||_____| \_/\_/  |_____||_____||_____|    |__|  |__|__||__|\_| |__|  |____/ "
echo ""
echo "  Welcome, $(whoami)."
echo ""
EOF

echo "[3/4] Mengatur permission..."
chown -R 1000:1000 "${ROOTFS_DIR}/home/henn"
chown -R 1001:1001 "${ROOTFS_DIR}/home/hann"
chown -R 1002:1002 "${ROOTFS_DIR}/home/viii"
chown -R 1003:1003 "${ROOTFS_DIR}/home/kids"
chmod 755 "${ROOTFS_DIR}/home/henn"
chmod 755 "${ROOTFS_DIR}/home/hann"
chmod 755 "${ROOTFS_DIR}/home/viii"
chmod 755 "${ROOTFS_DIR}/home/kids"

chmod 700 "${ROOTFS_DIR}/root"

mkdir -p "${ROOTFS_DIR}/mnt/fuse"
chmod 755 "${ROOTFS_DIR}/mnt"
chmod 777 "${ROOTFS_DIR}/tmp"
chmod 1777 "${ROOTFS_DIR}/tmp"

touch "${ROOTFS_DIR}/etc/mtab"
chmod 666 "${ROOTFS_DIR}/etc/mtab"
chmod 777 "${ROOTFS_DIR}/mnt"
chmod 777 "${ROOTFS_DIR}/mnt/fuse"

echo "Membuat package manager 'party'..."
cat > "${ROOTFS_DIR}/bin/party" << 'EOF'
#!/bin/sh
ALPINE_REPO="http://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64"

# Tentukan install directory berdasarkan user
if [ "$(id -u)" = "0" ]; then
    INSTALL_DIR="/"
else
    INSTALL_DIR="${HOME}/.local"
    mkdir -p "${HOME}/.local/bin"
fi

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
            tar -xzf /tmp/${PKG}.apk -C "${INSTALL_DIR}" 2>/dev/null
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
rm -f /tmp/hello_fuse.c
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

cp /bin/fusermount3 "${ROOTFS_DIR}/bin/fusermount3"
ln -sf fusermount3 "${ROOTFS_DIR}/bin/fusermount"
chmod +s "${ROOTFS_DIR}/bin/fusermount3"

mkdir -p "${ROOTFS_DIR}/lib/x86_64-linux-gnu"
mkdir -p "${ROOTFS_DIR}/lib64"
cp /lib/x86_64-linux-gnu/libc.so.6 "${ROOTFS_DIR}/lib/x86_64-linux-gnu/"
cp /lib64/ld-linux-x86-64.so.2 "${ROOTFS_DIR}/lib64/"

echo "[4/4] Membuat init script..."
cat > "${ROOTFS_DIR}/init" << 'INIT_EOF'
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || mdev -s
chmod 666 /dev/fuse 2>/dev/null || true

hostname multi-os

ifconfig eth0 up
udhcpc -i eth0 2>/dev/null || true
ifconfig eth0 10.0.2.15 netmask 255.255.255.0
ip route add default via 10.0.2.2 2>/dev/null || true
echo "nameserver 10.0.2.3" > /etc/resolv.conf

while true; do
    /bin/login
done
INIT_EOF

chmod +x "${ROOTFS_DIR}/init"

SCRIPT_DIR="$(pwd)"
cd "${ROOTFS_DIR}"
find . | cpio --quiet -H newc -o | gzip -9 > "${SCRIPT_DIR}/${OUTPUT_DIR}/multi.gz"
cd ..

rm -rf "${ROOTFS_DIR}"

echo ""
echo "=========================================="
echo " SELESAI! Multi filesystem berhasil dibuat."
echo " Output: ${OUTPUT_DIR}/multi.gz"
echo "=========================================="