#
# Copyright (c) 2015 BayLibre SAS
#
# Top level Makefile for the BayLibre ACME
# Power Monitoring and Switching device
#
#
ifndef KERNEL_BUILD
 $(error you need to source acme-setup, or define the matching variables)
endif

.PHONY: sdcard

all: kernel u-boot rootfs

patches/.applied: patches/baylibre-acme_defconfig patches/baylibre-acme
	@echo "applying patches"
	cp patches/baylibre-acme_defconfig buildroot/configs/baylibre-acme_defconfig
	cp -rf patches/baylibre-acme buildroot/board
ifdef ACME_IIO
	cd buildroot/board/fs-overlay/etc/init.d && ln -s iio_S95acme-init S95acme-init
else
	cd buildroot/board/fs-overlay/etc/init.d && ln -s hwmon_S95acme-init S95acme-init
endif
	cd buildroot/board/fs-overlay/etc/init.d && chmod +x S95acme-init
	@date > patches/.applied

##
# Kernel stuff
##

$(KERNEL_BUILD)/arch/arm/boot/zImage: kernel

kernel: $(KERNEL_BUILD)/.config
	make -j 5 -C $(KERNEL_BUILD) zImage modules dtbs
	mkdir -p $(INSTALL_MOD_PATH)/lib
	@sudo chmod 777 $(INSTALL_MOD_PATH)/lib
	make -C $(KERNEL_BUILD) modules_install
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/zImage $(TFTP_DIR)
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/dts/am335x-boneblack.dtb $(TFTP_DIR)/dtbs

menuconfig: $(KERNEL_BUILD)/.config
	ARCH=arm make -C kbuild menuconfig
ifdef ACME_IIO
	cd $(ACME_HOME)/kbuild && kconfig-tweak --module IIO
	cd $(ACME_HOME)/kbuild && kconfig-tweak --module INA2XX_ADC
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
else
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_LM_SENSORS
	cd $(ACME_HOME)/buildroot && CONFIG_="BR2_" kconfig-tweak --enable PACKAGE_TRACE_CMD
endif

rootfs: $(INSTALL_MOD_PATH)/.rootfs fix-nfs

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

sdcard: u-boot/MLO $(INSTALL_MOD_PATH)/.rootfs $(KERNEL_BUILD)/arch/arm/boot/zImage
	@make -C sdcard all

u-boot: u-boot/MLO u-boot/u-boot.bin

u-boot/MLO: u-boot/.config
	make -C u-boot ARCH=arm

u-boot/.config: patches/.applied
	make -C u-boot ARCH=arm am335x_evm_defconfig

##
# cleanup
##

distclean: clean
	-@rm -f .patches
	-@rm -rf $(KERNEL_BUILD)
	make -C $(KERNEL_SRC) mrproper
	make -C buildroot clean
	make -C u-boot distclean

clean:
	-@make -C $(KERNEL_BUILD) clean
	-@make -C u-boot clean
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
