#!/bin/sh

if [ -x "$(apk list | grep uboot-tools | grep installed )" ]
then
	echo 'uboot-tools not installed, install now'
	apk add uboot-tools
fi

mkimage -A arm64 -O linux -T ramdisk -C gzip -n uInitrd -d /boot/initramfs-s905d /boot/uInitrd

[ -f /boot/dtb.img ] && rm -f /boot/dtb.img

cp /usr/lib/linux*/meson-gxl-s905d-p230.dtb /boot/dtb.img

