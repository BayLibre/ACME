#!/bin/bash
iio_info -n 192.168.1.69 ina226
iio_readdev  -n 192.168.1.69  ina226  >  result
gnuplot plot_ina2xx
firefox iio-test.png
