#!/bin/sh

set -xe

die() {
	printf '\033[1;31mERROR:\033[0m %s\n' "$@" >&2  # bold red
	exit 1
}

which unzip > /dev/null || die 'please install unzip'
which docker > /dev/null || die 'please install docker'
which docker-compose > /dev/null || die 'please install docker-compose with: sudo pip3 install docker-compose'

cd "$(dirname "$0")"

DEST=$(pwd)

url="https://github.com/yangxuan8282/phicomm-n1/releases/download/debian/2018-10-18-debian-arm64-n1-stretch.zip"

server_ip=$(ip route get 1 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tail -1)

ip_range=$(ip a show | grep "$server_ip" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tail -1)

sed -i "s|dhcp-range=.*|dhcp-range="$ip_range",proxy|" dnsmasq.conf

mkdir -p os/boot os/root

wget $url

unzip *debian*.zip

loop_dev=$(sudo losetup --find --show -P "2018-10-18-debian-arm64-n1-stretch.img")

mkdir -p /tmp/debian_boot /tmp/debian_root

sudo mount "$loop_dev"p1 /tmp/debian_boot
sudo mount "$loop_dev"p2 /tmp/debian_root

cp -a /tmp/debian_boot/* os/boot/
sudo cp -a /tmp/debian_root/* os/root/

sudo umount /tmp/debian_boot /tmp/debian_root
sudo losetup -d "$loop_dev"
rm -f debian*n1-stretch*

sudo rm -f os/root/etc/fstab && sudo touch os/root/etc/fstab

sudo rm -f os/root/resize2fs_once

docker-compose up -d
