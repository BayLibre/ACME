#!/bin/sh
set -x
iio_info

echo 0 > /sys/bus/iio/devices/iio\:device0/buffer/enable

echo 1024 > /sys/bus/iio/devices/iio\:device0/buffer/length
echo 4 > /sys/bus/iio/devices/iio\:device0/in_mean_raw

cat /sys/bus/iio/devices/iio:device0/scan_elements/in_*_en

echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_voltage0_en
echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_voltage1_en
echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_power3_en
echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_timestamp_en

trace-cmd start -p nop

echo 1 > /sys/bus/iio/devices/iio\:device0/buffer/enable

#dd if=/dev/iio\:device0  of=/result
iio_readdev ina226 > result & 


echo 0 > /sys/bus/iio/devices/iio\:device0/buffer/enable

trace-cmd stop
trace-cmd extract

cp trace.dat  /

