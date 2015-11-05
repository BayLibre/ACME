#!/bin/sh
cd $ACME_HOME/buildroot/output/build
mv libsigrok-generic-iio libsigrok-generic-iio_OLD
mv sigrok-cli-master sigrok-cli-master_OLD

ln -s ../../../libsigrok libsigrok-generic-iio
ln -s ../../../sigrok-cli sigrok-cli-master

