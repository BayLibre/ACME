#
# Copyright (c) 2015 BayLibre SAS
#
# Top level Makefile for the BayLibre ACME
# Power Monitoring and Switching device
#
#
ifndef TOPLEVEL
 $(error you need to source acme-setup, or define the matching variables)
endif

export UBOOT_BUILD=$(TOPLEVEL)/build/u-boot
export KERNEL_BUILD=$(TOPLEVEL)/build/linux

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
	cp patches/baylibre-acme_defconfig.iio buildroot/configs/baylibre-acme_defconfig
else
	-cd patches/baylibre-acme/fs-overlay/etc/init.d && ln -s hwmon_S95acme-init S95acme-init
	cp patches/baylibre-acme_defconfig buildroot/configs/baylibre-acme_defconfig
endif
	# Final copy and permission settings
	cp -rf patches/package/* buildroot/package
	cp -rf patches/baylibre-acme buildroot/board
	fakeroot chmod +x buildroot/board/baylibre-acme/fs-overlay/etc/init.d/*
	-cd buildroot && patch -p1 < ../patches/buildroot_add_acme_package.patch
	@date > patches/.applied
	echo "rootfs: you may want to add some id_rsa.pub keys to rootfs/root/.ssh/authorized_keys" > .log
        # Kernel patches
	cd $(KERNEL_SRC) && git am --reject -3 $(TOPLEVEL)/patches/linux/*.patch

##
# Kernel stuff
##

kernel:	$(KERNEL_BUILD)/arch/arm/boot/zImage

$(KERNEL_BUILD)/arch/arm/boot/zImage: $(KERNEL_BUILD)/.config
	make -j 5 -C $(KERNEL_BUILD) zImage modules dtbs
	mkdir -p $(INSTALL_MOD_PATH)/lib
	@fakeroot chmod 777 $(INSTALL_MOD_PATH)/lib
	make -C $(KERNEL_BUILD) modules_install
ifndef USE_BUILD_SERVER
	fakeroot mkdir -p $(TFTP_DIR)/dtbs
	fakeroot cp $(KERNEL_BUILD)/arch/arm/boot/zImage $(TFTP_DIR)
	fakeroot cp $(KERNEL_BUILD)/arch/arm/boot/dts/am335x-boneblack.dtb $(TFTP_DIR)/dtbs
endif

menuconfig: $(KERNEL_BUILD)/.config
	ARCH=arm make -C $(KERNEL_BUILD) menuconfig

$(KERNEL_BUILD)/.config: patches/.applied
	@mkdir -p $(KERNEL_BUILD)
	make -C $(KERNEL_SRC) O=$(KERNEL_BUILD) acme_defconfig
ifdef ACME_IIO
	cd $(KERNEL_BUILD) && kconfig-tweak --disable SENSORS_INA2XX
	cd $(KERNEL_BUILD) && kconfig-tweak --module IIO
	cd $(KERNEL_BUILD) && kconfig-tweak --module INA2XX_ADC
	echo "kernel: configured for INA2XX_ADC (IIO)" >> .log
endif

##
# BUILDROOT and ROOTFS
##
$(TOPLEVEL)/buildroot/.config:	patches/.applied
	@echo "preparing buildroot"
	make -C $(TOPLEVEL)/buildroot baylibre-acme_defconfig
ifdef ACME_IIO
	cd $(TOPLEVEL)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LIBIIO
	cd $(TOPLEVEL)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LIBIIO_IIOD
	echo "buildroot: added IIO packages" > .log
else
	cd $(TOPLEVEL)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LM_SENSORS
	echo "buildroot: added sensors/hwmon packages" > .log
endif
	cd $(TOPLEVEL)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable TARGET_ROOTFS_TAR
	cd $(TOPLEVEL)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_TRACE_CMD
	cd $(TOPLEVEL)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_AVAHI
	cd $(TOPLEVEL)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_AVAHI_DAEMON
	cd $(TOPLEVEL)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LIBDAEMON
	cd $(TOPLEVEL)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_EXPAT


# create rootfs.tar.xz
#

rootfs: rootfs.tar.xz fix-nfs

rootfs.tar.xz: $(INSTALL_MOD_PATH)/.rootfs
	xz -kc $(TOPLEVEL)/buildroot/output/images/rootfs.tar > rootfs.tar.xz

$(INSTALL_MOD_PATH)/.rootfs: $(TOPLEVEL)/buildroot/output/images/rootfs.tar
	@mkdir -p $(INSTALL_MOD_PATH)
	fakeroot tar xv -C $(INSTALL_MOD_PATH) -f $(TOPLEVEL)/buildroot/output/images/rootfs.tar
	fakeroot chown ${USER}:${USER} rootfs
	@date > $(INSTALL_MOD_PATH)/.rootfs

$(TOPLEVEL)/buildroot/output/images/rootfs.tar: $(TOPLEVEL)/buildroot/.config
	make -C $(TOPLEVEL)/buildroot -j 5

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
	fakeroot rm -rf rootfs rootfs.tar.xz
	echo "" > .log

clean:
	-@rm -rf $(KERNEL_BUILD)
	-@rm -rf $(UBOOT_BUILD)
	-@fakeroot rm $(TOPLEVEL)/buildroot/output/images/rootfs.tar
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
