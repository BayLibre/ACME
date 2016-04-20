# Baylibre ACME Build Environment #

## Instructions ##

### Getting the repo ###

If not already done, please install repo and pull the manifests as per the [ACME manifest](https://github.com/BayLibre/manifests#acme-build-environment-iio-version)

### Getting started ###

* Review environment variables and path in setup script `acme-setup`.
  Check the top-level path and make sure the path in INSTALL_MOD_PATH
  is exported in /etc/exports if you wish to use NFS.

* source acme-setup

* make
* potentially fix the ACME's hostname and add your RSA keys in rootfs/root/.ssh.authorized_keys
* make rootfs
* make sdcard

* finally use 'dd' to write the raw sdcard image in sdcard to your block device.

## Build Targets ##

* u-boot	rebuild u-boot
* kernel	rebuild kernel and modules
* clean		clean kernel and u-boot
* distclean	distclean, including buildroot
* rootfs	untar buildroot image, build buildroot if necessary
* sdcard	create contents for a standalone device booting from sdcard.

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
