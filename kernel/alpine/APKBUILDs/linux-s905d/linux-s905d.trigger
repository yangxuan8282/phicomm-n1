#!/bin/sh

mkimage -A arm64 -O linux -T ramdisk -C gzip -n uInitrd -d /boot/initramfs-s905d /boot/uInitrd

[ -f /boot/dtb.img ] && rm -f /boot/dtb.img

cp /usr/lib/linux*/meson-gxl-s905d-p230.dtb /boot/dtb.img

