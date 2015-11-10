#!/bin/sh
echo 0 > /sys/bus/iio/devices/iio\:device0/buffer/enable

echo 1024 > /sys/bus/iio/devices/iio\:device0/buffer/length
echo 1 > /sys/bus/iio/devices/iio\:device0/in_mean_raw

echo 1 >  /sys/bus/iio/devices/iio:device0/scan_elements/in_power3_en
echo 1  > /sys/bus/iio/devices/iio:device0/scan_elements/in_timestamp_en
echo 1000  > /sys/bus/iio/devices/iio:device0/in_sampling_frequency

trace-cmd start -p nop

echo 1 > /sys/bus/iio/devices/iio\:device0/buffer/enable

dd if=/dev/iio\:device0 of=/result bs=16k count=5000

echo 0 > /sys/bus/iio/devices/iio\:device0/buffer/enable

trace-cmd stop
trace-cmd extract
cp trace.dat  /

