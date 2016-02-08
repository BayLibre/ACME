################################################################################
#
# BayLibre ACME Utilities
#
################################################################################
ACME_UTILS_VERSION = master
ACME_UTILS_SITE = $(call github,baylibre,acme-utils,$(ACME_UTILS_VERSION))
ACME_UTILS_CONF_OPTS = \
	CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" \
	LDFLAGS="$(TARGET_LDFLAGS)"
ACME_UTILS_LICENSE = GPLv3+
ACME_UTILS_LICENSE_FILES = COPYING

define ACME_UTILS_BUILD_CMDS
	$(MAKE)	-C $(@D)/api $(ACME_UTILS_CONF_OPTS)
endef

define ACME_UTILS_CLEAN_CMDS
	$(MAKE) -C $(@D)/api clean
endef

define ACME_UTILS_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D)/api DESTDIR="$(TARGET_DIR)" install
endef

$(eval $(generic-package))
