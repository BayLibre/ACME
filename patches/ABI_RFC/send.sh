#!/bin/sh

git send-email --to jic23@kernel.org --to knaack.h@gmx.de --to lars@metafoo.de \
--to pmeerw@pmeerw.net --cc daniel.baluta@intel.com \
--cc linux-api@vger.kernel.org --cc linux-kernel@vger.kernel.org --cc linux-iio@vger.kernel.org \
--no-chain-reply-to 000*

