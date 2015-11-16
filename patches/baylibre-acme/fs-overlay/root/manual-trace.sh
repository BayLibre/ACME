#!/bin/sh
set -x

echo 0 > /sys/bus/iio/devices/iio\:device0/buffer/enable

echo 1024 > /sys/bus/iio/devices/iio\:device0/buffer/length

echo 4 > /sys/bus/iio/devices/iio\:device0/in_averaging_steps
echo 1506 > /sys/bus/iio/devices/iio:device0/in_sampling_frequency

echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_voltage0_en
echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_voltage1_en
echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_power3_en
echo 1 > /sys/bus/iio/devices/iio:device0/scan_elements/in_timestamp_en

echo test1 >  /sys/bus/iio/devices/iio\:device0/trigger/current_trigger

trace-cmd start -p nop

echo 1 > /sys/bus/iio/devices/iio\:device0/buffer/enable

dd if=/dev/iio\:device0  count=1000 | od -x

echo 0 > /sys/bus/iio/devices/iio\:device0/buffer/enable

trace-cmd stop
trace-cmd show

#extract

cp trace.dat  /

