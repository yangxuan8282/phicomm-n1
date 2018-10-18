setenv kernel_addr "0x11000000"
setenv initrd_addr "0x13000000"
setenv dtb_mem_addr "0x1000000"

setenv serverip 192.168.2.101
setenv ipaddr 192.168.2.105

setenv bootargs "root=/dev/nfs nfsroot=${serverip}:/nfsshare/root rw ip=dhcp console=ttyAML0,115200n8 console=tty0 no_console_suspend consoleblank=0 rootwait"

setenv bootcmd_pxe "tftp ${kernel_addr} zImage; tftp ${initrd_addr} uInitrd; tftp ${dtb_mem_addr} dtb.img; booti ${kernel_addr} ${initrd_addr} ${dtb_mem_addr} "
run bootcmd_pxe
