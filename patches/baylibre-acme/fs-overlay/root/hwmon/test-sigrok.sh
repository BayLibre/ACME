#!/bin/sh

if [ "$1" == "" ]
then
 echo "usage: $0 test-name frequency "
 exit 1
fi

trace-cmd start -p nop

sigrok-cli -d baylibre-acme --samples 500 --config samplerate=$2 -O csv  > /sample-$1-$2hz.csv
#sleep 1
#echo 0 > /sys/class/gpio/gpio489/value
#sleep 1
#echo 1 > /sys/class/gpio/gpio489/value

trace-cmd stop
trace-cmd extract
mv result /trace-$1-2$hz




