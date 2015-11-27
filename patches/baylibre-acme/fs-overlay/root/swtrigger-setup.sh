#/!bin/sh

mkdir /config/iio/triggers/hrtimer/test1

find /sys/bus/iio/devices/trigger0/

echo $1 > /sys/bus/iio/devices/trigger0/sampling_frequency

