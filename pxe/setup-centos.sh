#!/bin/sh

set -xe

die() {
	printf '\033[1;31mERROR:\033[0m %s\n' "$@" >&2  # bold red
	exit 1
}

which unzip > /dev/null || die 'please install unzip'
which docker > /dev/null || die 'please install docker'
which docker-compose > /dev/null || die 'please install docker-compose with: sudo pip3 install docker-compose'
which losetup > /dev/null || die 'please install losetup'

cd "$(dirname "$0")"

DEST=$(pwd)

url="https://github.com/yangxuan8282/phicomm-n1/releases/download/centos/CentOS-7-aarch64-n1-7.5.1804_4.18.7_20180922.zip"

server_ip=$(ip route get 1 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tail -1)

ip_range=$(ip a show | grep "$server_ip" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tail -1)

sed -i "s|dhcp-range=.*|dhcp-range="$ip_range",proxy|" dnsmasq.conf

mkdir -p os/boot os/root

wget $url

unzip CentOS-7*.zip

wget https://github.com/yangxuan8282/phicomm-n1/releases/download/dtb/meson-gxl-s905d-phicomm-n1.dtb

loop_dev=$(sudo losetup --find --show -P "CentOS-7-aarch64-n1-7.5.1804_4.18.7_20180922.img")

mkdir -p /tmp/cent_boot /tmp/cent_root

sudo mount "$loop_dev"p1 /tmp/cent_boot
sudo mount "$loop_dev"p2 /tmp/cent_root

cp -a /tmp/cent_boot/* os/boot/
sudo cp -a /tmp/cent_root/* os/root/

mv *.dtb os/boot/dtb.img

sudo umount /tmp/cent_boot /tmp/cent_root
sudo losetup -d "$loop_dev"
rm -f CentOS-7-aarch64-n1-7.5.1804_4.18.7_20180922*

sudo rm -f os/root/etc/fstab && sudo touch os/root/etc/fstab

sudo rm -f os/root/resize2fs_once

docker-compose up -d
