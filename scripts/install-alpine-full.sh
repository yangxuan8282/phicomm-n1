#!/bin/sh

die() {
	printf '\033[1;31mERROR:\033[0m %s\n' "$@" >&2  # bold red
	exit 1
}

which mkimage >/dev/null || die 'please install uboot-tools'
which parted >/dev/null || die 'please install parted'
which unzip >/dev/null || die 'please install unzip'

ALPINE_VERSION="2018-11-09"
echo "Download Alpine OS ${ALPINE_VERSION} "
wget "https://github.com/yangxuan8282/phicomm-n1/releases/download/alpine/"$ALPINE_VERSION"-alpine-n1-aarch64.zip"

unzip "$ALPINE_VERSION"-alpine-n1-aarch64.zip
LOOP_DEV=$(losetup --find --show -P "$ALPINE_VERSION"-alpine-n1-aarch64.img)
mkdir -p /tmp/alpine
mount "$LOOP_DEV"p2 /tmp/alpine
mount "$LOOP_DEV"p1 /tmp/alpine/boot

echo "Start script create MBR and filesystem"

DEV_EMMC=/dev/mmcblk1

echo "Start backup u-boot default"

dd if="${DEV_EMMC}" of=/boot/u-boot-default.img bs=1M count=4

echo "Start create MBR and partittion"

parted -s "${DEV_EMMC}" mklabel msdos
parted -s "${DEV_EMMC}" mkpart primary fat32 700M 828M
parted -s "${DEV_EMMC}" mkpart primary ext4 829M 100%

echo "Start restore u-boot"

dd if=/boot/u-boot-default.img of="${DEV_EMMC}" conv=fsync bs=1 count=442
dd if=/boot/u-boot-default.img of="${DEV_EMMC}" conv=fsync bs=512 skip=1 seek=1

sync

echo "Done"

echo "Start copy system for eMMC."

mkdir -p /ddbr
chmod 777 /ddbr

PART_BOOT="/dev/mmcblk1p1"
PART_ROOT="/dev/mmcblk1p2"
DIR_INSTALL="/ddbr/install"

if [ -d $DIR_INSTALL ] ; then
    rm -rf $DIR_INSTALL
fi
mkdir -p $DIR_INSTALL

if grep -q $PART_BOOT /proc/mounts ; then
    echo "Unmounting BOOT partiton."
    umount -f $PART_BOOT
fi
echo -n "Formatting BOOT partition..."
mkfs.vfat -n "BOOT_EMMC" $PART_BOOT
echo "done."

mount -o rw $PART_BOOT $DIR_INSTALL

echo -n "Copying BOOT..."
cp -r /tmp/alpine/boot/* $DIR_INSTALL && sync
echo "done."

echo -n "Create new init config..."

cat > "$DIR_INSTALL/uEnv.ini" <<'EOF'
dtb_name=/dtbs/meson-gxl-s905d-phicomm-n1.dtb
bootargs=root=/dev/mmcblk1p2 rootflags=data=writeback rw console=ttyAML0,115200n8 console=tty0 no_console_suspend consoleblank=0 fsck.fix=yes fsck.repair=yes net.ifnames=0
EOF

cat > "$DIR_INSTALL/emmc_autoscript.cmd" <<'EOF'
setenv env_addr "0x10400000"
setenv kernel_addr "0x11000000"
setenv initrd_addr "0x13000000"
setenv dtb_mem_addr "0x1000000"
setenv boot_start booti ${kernel_addr} ${initrd_addr} ${dtb_mem_addr}
if fatload mmc 1 ${kernel_addr} vmlinuz-amlogic; then if fatload mmc 1 ${initrd_addr} uInitrd; then if fatload mmc 1 ${env_addr} uEnv.ini; then env import -t ${env_addr} ${filesize}; fi; if fatload mmc 1 ${dtb_mem_addr} ${dtb_name}; then run boot_start;fi;fi;fi;
EOF

mkimage -C none -A arm -T script -d "$DIR_INSTALL/emmc_autoscript.cmd" "$DIR_INSTALL/emmc_autoscript"

echo "done."

rm $DIR_INSTALL/s9*

umount $DIR_INSTALL

if grep -q $PART_ROOT /proc/mounts ; then
    echo "Unmounting ROOT partiton."
    umount -f $PART_ROOT
fi

echo "Formatting ROOT partition..."
mke2fs -F -q -t ext4 -L ROOT_EMMC -m 0 $PART_ROOT
e2fsck -n $PART_ROOT
echo "done."

echo "Copying ROOTFS."

mount -o rw $PART_ROOT $DIR_INSTALL

cd /tmp/alpine
echo "Copy BIN"
tar -cf - bin | (cd $DIR_INSTALL; tar -xpf -)
#echo "Copy BOOT"
#mkdir -p $DIR_INSTALL/boot
#tar -cf - boot | (cd $DIR_INSTALL; tar -xpf -)
echo "Create DEV"
mkdir -p $DIR_INSTALL/dev
#tar -cf - dev | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy ETC"
tar -cf - etc | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy HOME"
tar -cf - home | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy LIB"
tar -cf - lib | (cd $DIR_INSTALL; tar -xpf -)
echo "Create MEDIA"
mkdir -p $DIR_INSTALL/media
#tar -cf - media | (cd $DIR_INSTALL; tar -xpf -)
echo "Create MNT"
mkdir -p $DIR_INSTALL/mnt
#tar -cf - mnt | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy OPT"
tar -cf - opt | (cd $DIR_INSTALL; tar -xpf -)
echo "Create PROC"
mkdir -p $DIR_INSTALL/proc
echo "Copy ROOT"
tar -cf - root | (cd $DIR_INSTALL; tar -xpf -)
echo "Create RUN"
mkdir -p $DIR_INSTALL/run
echo "Copy SBIN"
tar -cf - sbin | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy SRV"
tar -cf - srv | (cd $DIR_INSTALL; tar -xpf -)
echo "Create SYS"
mkdir -p $DIR_INSTALL/sys
echo "Create TMP"
mkdir -p $DIR_INSTALL/tmp
echo "Copy USR"
tar -cf - usr | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy VAR"
tar -cf - var | (cd $DIR_INSTALL; tar -xpf -)

cat > $DIR_INSTALL/usr/bin/resize2fs-once <<'EOF'
#!/bin/sh
set -xe
rc-update del resize2fs-once default
EOF

chmod +x /usr/bin/resize2fs-once

echo "Create new fstab"

cat > "$DIR_INSTALL/etc/fstab" <<'EOF'
/dev/mmcblk1p1  /boot           vfat    defaults          0       2
EOF

cd /
sync

umount $DIR_INSTALL
umount -l /tmp/alpine/boot
umount -l /tmp/alpine
losetup -d "$LOOP_DEV"

echo "*******************************************"
echo "Complete copy OS to eMMC "
echo "*******************************************"

