#
# Copyright (c) 2015 BayLibre SAS
#
# Top level Makefile for the BayLibre ACME
# Power Monitoring and Switching device
#
#
ifndef ACME_SDCARD
 $(error you need to CAREFULLY define ACME_SDCARD, lsblk is helpful to do so.)
endif
ifndef UBOOT_BUILD
 $(error UBOOT_BUILD undefined)
endif

TEMPDIR=/tmp/acme-tmp-rootfs

.PHONY: reset help

all: reset
	sudo dd if=${UBOOT_BUILD}/MLO of=${ACME_SDCARD} count=1 seek=1 bs=128k
	sudo dd if=${UBOOT_BUILD}/u-boot.img of=${ACME_SDCARD} count=2 seek=1 bs=384k
	# make partitions and format
	sudo fdisk ${ACME_SDCARD} < ./fdisk-cmds
	@mkdir -p ${TEMPDIR}
ifeq (mmcblk,$(findstring mmcblk,$(ACME_SDCARD)))
	sudo mkfs.ext4 ${ACME_SDCARD}p1 -L rootfs
	sudo mount ${ACME_SDCARD}p1 ${TEMPDIR}
else
	sudo mkfs.ext4 ${ACME_SDCARD}1 -L rootfs
	sudo mount ${ACME_SDCARD}1 ${TEMPDIR}
endif

	sudo mkdir -p ${TEMPDIR}/opt/backup/uboot/
	sudo mkdir -p ${TEMPDIR}/boot/dtbs
	# create backup bootloader
	sudo cp -v ${UBOOT_BUILD}/MLO ${TEMPDIR}/opt/backup/uboot/
	sudo cp -v ${UBOOT_BUILD}/u-boot.img ${TEMPDIR}/opt/backup/uboot/
	#rootfs, modules, kernel and dtb
	sudo cp -r ${INSTALL_MOD_PATH}/* ${TEMPDIR}/
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/zImage ${TEMPDIR}/boot
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/dts/am335x-boneblack.dtb ${TEMPDIR}/boot/dtbs
	# uEnv
	sudo cp -v  ./uenv/uEnv-sd.txt ${TEMPDIR}/boot/uEnv.txt
	sudo cp -v  ./uenv/uEnv-sd.txt ${TEMPDIR}/uEnv.txt
	sudo cp -v  ./uenv/uEnv-nfs.txt ${TEMPDIR}
	sync
	sync
	-sudo eject ${ACME_SDCARD}

reset:
	./check-acme-disk
	-@sudo umount ${ACME_SDCARD}1
	-@sudo umount ${ACME_SDCARD}p1

	sudo dd if=/dev/zero of=${ACME_SDCARD} bs=1M count=10

help:
	lsblk | grep disk -A 2
	@echo "export ACME_SDCARD according to dmesg, ex: /dev/sde"


