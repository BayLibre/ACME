#!/bin/sh
echo 0 > /sys/bus/iio/devices/iio\:device0/buffer/enable

echo 1024 > /sys/bus/iio/devices/iio\:device0/buffer/enable
echo 1 > /sys/bus/iio/devices/iio\:device0/in_mean_raw


echo 1 >  /sys/bus/iio/devices/iio:device0/scan_elements/in_power3_en
echo 1  > /sys/bus/iio/devices/iio:device0/scan_elements/in_timestamp_en
echo 2000  > /sys/bus/iio/devices/iio:device0/in_sampling_frequency

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

