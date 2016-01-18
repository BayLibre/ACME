#
# Copyright (c) 2015 BayLibre SAS
#
# Top level Makefile for the BayLibre ACME
# Power Monitoring and Switching device
#
#
ifndef ACME_HOME
 $(error you need to source acme-setup, or define the matching variables)
endif

export UBOOT_BUILD=$(ACME_HOME)/build/u-boot
export KERNEL_BUILD=$(ACME_HOME)/build/linux

.PHONY: sdcard

all: kernel u-boot rootfs
	-@cat .log

patches/.applied: patches/baylibre-acme_defconfig patches/baylibre-acme
	@echo "applying patches"
	@rm -f patches/baylibre-acme/fs-overlay/etc/init.d/S95acme-init
	@mkdir -p patches/baylibre-acme/fs-overlay/root/.ssh/
	@touch patches/baylibre-acme/fs-overlay/root/.ssh/authorized_keys
ifdef ACME_IIO
	-cd patches/baylibre-acme/fs-overlay/etc/init.d && ln -s iio_S95acme-init S95acme-init
else
	-cd patches/baylibre-acme/fs-overlay/etc/init.d && ln -s hwmon_S95acme-init S95acme-init
endif
	# Final copy and permission settings
	cp patches/baylibre-acme_defconfig buildroot/configs/baylibre-acme_defconfig

	cp -rf patches/baylibre-acme buildroot/board
	sudo chmod +x buildroot/board/baylibre-acme/fs-overlay/etc/init.d/*
	@date > patches/.applied
	echo "rootfs: you may want to add some id_rsa.pub keys to rootfs/root/.ssh/authorized_keys" > .log
##
# Kernel stuff
##

kernel:	$(KERNEL_BUILD)/arch/arm/boot/zImage

$(KERNEL_BUILD)/arch/arm/boot/zImage: $(KERNEL_BUILD)/.config
	make -j 5 -C $(KERNEL_BUILD) zImage modules dtbs
	mkdir -p $(INSTALL_MOD_PATH)/lib
	@sudo chmod 777 $(INSTALL_MOD_PATH)/lib
	make -C $(KERNEL_BUILD) modules_install
	sudo mkdir -p $(TFTP_DIR)/dtbs
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/zImage $(TFTP_DIR)
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/dts/am335x-boneblack.dtb $(TFTP_DIR)/dtbs

menuconfig: $(KERNEL_BUILD)/.config
	ARCH=arm make -C $(KERNEL_BUILD) menuconfig
ifdef ACME_IIO
	cd $(ACME_HOME)/kbuild && kconfig-tweak --module IIO
	cd $(ACME_HOME)/kbuild && kconfig-tweak --module INA2XX_ADC
	echo "kernel: configured for INA2XX_ADC (IIO)" >> .log
endif

$(KERNEL_BUILD)/.config: patches/.applied
	@mkdir -p $(KERNEL_BUILD)
	make -C $(KERNEL_SRC) O=$(KERNEL_BUILD) acme_defconfig

##
# BUILDROOT and ROOTFS
##
$(ACME_HOME)/buildroot/.config:	patches/.applied
	@echo "preparing buildroot"
	make -C $(ACME_HOME)/buildroot baylibre-acme_defconfig
ifdef ACME_IIO
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LIBIIO
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LIBIIO_IIOD
	echo "buildroot: added IIO packages" > .log
else
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LM_SENSORS
	echo "buildroot: added sensors/hwmon packages" > .log
endif
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable TARGET_ROOTFS_TAR
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_TRACE_CMD
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_AVAHI
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_AVAHI_DAEMON
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LIBDAEMON
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_EXPAT


# create rootfs.tar.xz
#

rootfs: rootfs.tar.xz fix-nfs

rootfs.tar.xz: $(INSTALL_MOD_PATH)/.rootfs
	xz -kc $(ACME_HOME)/buildroot/output/images/rootfs.tar > rootfs.tar.xz

$(INSTALL_MOD_PATH)/.rootfs: $(ACME_HOME)/buildroot/output/images/rootfs.tar
	@mkdir -p $(INSTALL_MOD_PATH)
	sudo tar xv -C $(INSTALL_MOD_PATH) -f $(ACME_HOME)/buildroot/output/images/rootfs.tar
	sudo chown ${USER}:${USER} rootfs
	@date > $(INSTALL_MOD_PATH)/.rootfs

$(ACME_HOME)/buildroot/output/images/rootfs.tar: $(ACME_HOME)/buildroot/.config
	make -C $(ACME_HOME)/buildroot -j 5

fix-nfs: $(INSTALL_MOD_PATH)/.rootfs
	cat sdcard/uenv/uEnv-nfs.tmpl | sed 's#INSTALL_MOD_PATH#'"${INSTALL_MOD_PATH}"'#' >  sdcard/uenv/uEnv-nfs.txt
	sed 's#SERVERIP#'"${SERVERIP}"'#' -i  sdcard/uenv/uEnv-nfs.txt
	sed 's#BOARDIP#'"${BOARDIP}"'#' -i  sdcard/uenv/uEnv-nfs.txt

##
# SDCARD and BOOTLOADER contents
##

sdcard: $(UBOOT_BUILD)/MLO $(INSTALL_MOD_PATH)/.rootfs $(KERNEL_BUILD)/arch/arm/boot/zImage
	@make -C sdcard all
	-@cat .log

##
# U_BOOT
##

u-boot: $(UBOOT_BUILD)/MLO $(UBOOT_BUILD)/u-boot.bin

$(UBOOT_BUILD)/MLO: $(UBOOT_BUILD)/.config
	@mkdir -p $(UBOOT_BUILD)
	make -C $(UBOOT_BUILD) ARCH=arm -j4

$(UBOOT_BUILD)/.config: patches/.applied
	make -C $(UBOOT_SRC) O=$(UBOOT_BUILD) ARCH=arm am335x_evm_defconfig

##
# cleanup
##

distclean: clean
	-@rm -f patches/.applied
	-@rm -rf $(KERNEL_BUILD)
	make -C $(KERNEL_SRC) mrproper
	make -C buildroot clean
	make -C u-boot mrproper
	sudo rm -rf rootfs rootfs.tar.xz
	echo "" > .log

clean:
	-@make -C $(KERNEL_BUILD) clean
	-@rm -rf $(UBOOT_BUILD)
	-@sudo rm $(ACME_HOME)/buildroot/output/images/rootfs.tar
	-@rm $(INSTALL_MOD_PATH)/.rootfs


help:
	@echo "Source acme-setup first, after revising the various variables and pathes"
	@echo "If you wish to experiment with IIO, you may export ACME_IIO=1 so that"
	@echo "the makefile automates the right setup for buildroot and kernel"
	@echo
	@echo " == Make Targets == "
	@echo
	@echo "all			build everything, except the sdcard contents"
	@echo
	@echo "kernel, menuconfig	configure and build the kernel, or menuconfig"
	@echo "u-boot			build u-boot"
	@echo "rootfs			create a bootable rootfs"
	@echo
	@echo "clean			clean the kernel and uboot"
	@echo "distclean		flush all the build, including buildroot"
	@echo
	@echo " == Building the SDCard == "
	@echo
	@echo "sdcard			create the sdcard contents, please use with care."
	@echo
	make -C sdcard help
