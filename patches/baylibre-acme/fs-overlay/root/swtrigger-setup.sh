#/!bin/sh

# check for sw_trigger to being loaded
modprobe industrialio-sw-trigger
modprobe iio-trig-hrtimer

# mount configfs
mount -t configfs none /config

mkdir /config/iio/triggers/hrtimer/test1

find /sys/bus/iio/devices/trigger0/

echo $1 > /sys/bus/iio/devices/trigger0/sampling_frequency

