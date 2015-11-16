#/!bin/sh

# check for sw_trigger to being loaded
modprobe industrialio-sw-trigger
modprobe iio-trig-hrtimer

lsmod | grep industrialio

# mount configfs
mount -t configfs none /config

#check for the iio/trigger folder
find /config

sleep 1

mkdir /config/iio/triggers/hrtimer/test1

find /sys/bus/iio/devices/trigger0/

echo 1500 > /sys/bus/iio/devices/trigger0/sampling_frequency

