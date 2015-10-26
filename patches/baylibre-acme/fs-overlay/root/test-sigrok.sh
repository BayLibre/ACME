#!/bin/sh

if [ "$1" == "" ]
then
 echo "usage: $0 file-name (will be a csv file)"
 exit 1
fi

sigrok-cli -l 2 -d baylibre-acme --samples 2000 --config samplerate=500 -O csv  > ../$1.csv &
sleep 1
echo 0 > /sys/class/gpio/gpio489/value
sleep 1
echo 1 > /sys/class/gpio/gpio489/value


