#!/bin/sh
set -x
iio_info

echo 0 > /sys/bus/iio/devices/iio\:device0/buffer/enable

echo 1024 > /sys/bus/iio/devices/iio\:device0/buffer/enable
echo 4 > /sys/bus/iio/devices/iio\:device0/in_mean_raw


cat /sys/bus/iio/devices/iio:device0/scan_elements/in_*_en

trace-cmd start -p nop
iio_readdev ina226 > result &
sleep 2
tree /etc
sleep 2
ls -al
sleep 2
zcat /proc/config.gz | grep PM > /dev/null
sleep 4

trace-cmd stop
trace-cmd extract
cp trace.dat  /

