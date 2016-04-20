#
# Copyright (c) 2015 BayLibre SAS
#
# Top level Makefile for the BayLibre ACME
# Power Monitoring and Switching device
#
#
UBOOT_BUILD?=../build/u-boot
KERNEL_BUILD?=../build/linux
IMAGEFILE?=acme.img

TEMPDIR=$(shell mktemp)

.PHONY: reset help

all: reset
	dd if=/dev/zero of=${IMAGEFILE} bs=1M count=2048
	dd if=../build/u-boot/MLO of=${IMAGEFILE} count=1 seek=1 bs=128k conv=nocreat,notrunc
	dd if=../build/u-boot/u-boot.img of=${IMAGEFILE} count=2 seek=1 bs=384k conv=nocreat,notrunc
	parted -s ${IMAGEFILE} mklabel msdos
	parted -s ${IMAGEFILE} unit cyl mkpart primary ext2 -- 16 100%
	# make filesystem
	sudo losetup -v /dev/loop1 ${IMAGEFILE} -o 1048576
	sudo mkfs.ext2 /dev/loop1
	mkdir -p ${TEMPDIR}
	sudo mount  -o loop /dev/loop1 ${TEMPDIR}
	sudo mkdir -p ${TEMPDIR}/opt/backup/uboot/
	sudo mkdir -p ${TEMPDIR}/boot/dtbs
	#rootfs, modules, kernel and dtb
	sudo cp -r ${INSTALL_MOD_PATH}/* ${TEMPDIR}/
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/zImage ${TEMPDIR}/boot
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/dts/am335x-boneblack.dtb ${TEMPDIR}/boot/dtbs
	# uEnv
	sudo cp -v  ./uenv/uEnv-sd.txt ${TEMPDIR}/boot/uEnv.txt
	sudo cp -v  ./uenv/uEnv-sd.txt ${TEMPDIR}/uEnv.txt
	sync
	sudo umount ${TEMPDIR}
	echo "you may now dd the image to your sdcard with e.g:"
	echo "sudo dd if=acme.img of=/dev/sdc bs=1M count=2048"

help:

reset:
	rm -f *.img
	-@sudo umount ${TEMPDIR}
	-@sudo losetup -D -v
