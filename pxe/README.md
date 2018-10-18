# n1-pxe-docker

setup network boot server for phicomm n1 use docker

the default docker image is for arm, if want to run on amd64, please edit docker-compose.yml use amd64 tag imgage

Server:

run as normal user( not need sudo ):

```
./setup-debian
```

or

```
./setup-centos
```

Client:

prepare a usb disk, create as fat

copy the `aml_autoscript` and `s905_autoscript` in `usb` directory into it

then install u-boot ( also in `usb` directory ) with `dd`:

( replace TARGET_DEV with your usb devices )

```
sudo dd if=usb/u-boot.bin of=TARGET_DEV bs=1 count=442 conv=fsync &&
sudo dd if=usb/u-boot.bin of=TARGET_DEV bs=512 skip=1 seek=1 conv=fsync
```

power on the box

the u-boot in this repos is mainline 2018.07, use khadas-vim_defconfig

the nfs server Dockerfile is from [tangjiujun/docker-nfs-server](https://github.com/tangjiujun/docker-nfs-server)
