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

prepare a usb disk, format as fat

cd to `usb` dirctory, edit the `s905_autoscript.cmd` according to your network

then generate autoscript with(need install uboot-tools):

```
mkimage -C none -A arm -T script -d s905_autoscript.cmd s905_autoscript
```

copy the `aml_autoscript` and `s905_autoscript` in `usb` directory into usb storage

power on the box, wait some minutes it should boot into the system

some notes:

we actually use u-boot on emmc, that should be u-boot 2015

the nfs server Dockerfile is from [tangjiujun/docker-nfs-server](https://github.com/tangjiujun/docker-nfs-server)
