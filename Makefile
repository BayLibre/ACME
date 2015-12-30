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

all: rootfs kernel sdcard


patches/.applied: patches/baylibre-acme_defconfig patches/baylibre-acme
	@echo "applying patches"
	cp patches/baylibre-acme_defconfig buildroot/configs/baylibre-acme_defconfig
	cp -rf patches/baylibre-acme buildroot/board
	@date >> patches/.applied

$(ACME_HOME)/buildroot/.config:	patches/.applied
	@echo "preparing buildroot"
	make -C $(ACME_HOME)/buildroot baylibre-acme_defconfig
#	CONFIG_="BR2_" cd $ACME_HOME/buildroot && kconfig-tweak --enable PACKAGE_TRACE_CMD"
#	CONFIG_="BR2_" cd $ACME_HOME/buildroot && kconfig-tweak --enable PACKAGE_LM_SENSORS"

kernel: $(KERNEL_BUILD)/.config
	make -j 5 -C $(KERNEL_BUILD) zImage modules dtbs
	make -C $(KERNEL_BUILD) modules_install
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/zImage $(TFTP_DIR)
	sudo cp $(KERNEL_BUILD)/arch/arm/boot/dts/am335x-boneblack.dtb $(TFTP_DIR)/dtbs

menuconfig: $(KERNEL_BUILD)/.config
	ARCH=arm make -C kbuild menuconfig

$(KERNEL_BUILD)/.config: patches/.applied
	mkdir -p $(KERNEL_BUILD)
	make -C $(KERNEL_SRC) O=$(KERNEL_BUILD) acme_defconfig

rootfs: $(ACME_HOME)/buildroot/.config
	make -C $(ACME_HOME)/buildroot -j 5

##
# SDCARD and BOOTLOADER contents
##

sdcard: u-boot/MLO
	@echo "todo sdcard"

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