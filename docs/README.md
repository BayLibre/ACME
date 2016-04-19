# Baylibre ACME Build Crater #

## Instructions ##

### Getting the repo ###

If not already done, please install repo and pull the manifests as per

<https://github.com/BayLibre/manifests/blob/master/README.md#acme-build-crater>

### Getting started ###

* Review environment variables and path in setup script `acme-setup`.
  Check the top-level path and make sure the path in INSTALL_MOD_PATH
  is exported in /etc/exports if you wish to use NFS.

* source acme-setup

* make

## Build Targets ##

* u-boot	rebuild u-boot
* kernel	rebuild kernel and modules
* clean		clean kernel and u-boot
* distclean	distclean, including buildroot
* rootfs	untar buildroot image, build buildroot if necessary
* sdcard	create contents for a standalone device booting from sdcard.

## SD Card creation ##

Folder 'sdcard' holds the sdcard creation scripts.
In order for "make sdcard" to work, the user _must_
define the variable ACME_SDCARD based on the detected
device for the sdcard to format.

Please PAY SERIOUS ATTENTION TO NOT DESTROYING VALUABLE DEVICE CONTENT.

Especially when removing/re-inserting, always make sure
that the device exported in ACME_SDCARD is the card intended
to being used. Use dmesg or lsblk to check/findout.

> example:


```
		marc@marc-ThinkPad-L540:~$ lsblk
		NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
		sda      8:0    0 465,8G  0 disk 
		├─sda1   8:1    0   1,5G  0 part 
		...
		├─sda5   8:5    0 376,5G  0 part /
		└─sda6   8:6    0   7,7G  0 part [SWAP]
		...
		sdd      8:48   1   7,4G  0 disk 
		├─sdd1   8:49   1    52M  0 part /media/marc/boot
		└─sdd2   8:50   1   968M  0 part /media/marc/rootfs
		sr0     11:0    1  1024M  0 rom 

		marc@marc-ThinkPad-L540:~$ ACME_SDCARD=/dev/sdd make sdcard
```

### IIO Support ###

By default, HWMON support is enabled, you can build an IIO version of the product by defining
ACME_IIO from the acme-setup script.

The following optional command line tool will allow for simple recording of power metrics: <https://github.com/BayLibre/iio-capture>

## ACME PowerProbes EEPROM Tips ##

Manually checking the eeprom contents

* Check present I2C devices on bus 1:	i2cdetect -y -r 1 (look for the UU devices)
* For e.g. address 52 (eeprom of 3rd probe = 0x50 + 2) got ot /sys/class/i2c-dev/i2c-1/device/1-0052
* Data dump the contents of the eeprom: dd if=eeprom bs=64 count=1 | hexdump -C -v

The layout of the eeprom data is as such:

```
struct probe_eeprom {
	uint32_t type;  /* 1/2/3 for USB/JACK/HE10 */
	uint32_t rev;	/* 42 for 'B' */
	uint32_t shunt; /* RShunt value in uOhm 00013880h = 80000d*/
	uint8_t pwr_sw; /* 1 for has powerswitch*/
	uint8_t serial[EEPROM_SERIAL_SIZE];
	int8_t tag[EEPROM_TAG_SIZE];
};
```
