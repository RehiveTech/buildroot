################################################################################
#
# dpdk
#
################################################################################

DPDK_VERSION = 16.04
DPDK_SITE = http://dpdk.org/browse/dpdk/snapshot

DPDK_LICENSE = BSD-2c (core), GPLv2+ (Linux drivers)
DPDK_LICENSE_FILES = GNUmakefile LICENSE.GPL
DPDK_INSTALL_STAGING = YES

DPDK_DEPENDENCIES += linux

ifeq ($(BR2_PACKAGE_LIBPCAP),y)
DPDK_DEPENDENCIES += libpcap
endif

ifeq ($(BR2_SHARED_LIBS),y)
define DPDK_ENABLE_SHARED_LIBS
	$(call KCONFIG_ENABLE_OPT,CONFIG_RTE_BUILD_SHARED_LIB,\
			$(@D)/build/.config)
endef

DPDK_POST_CONFIGURE_HOOKS += DPDK_ENABLE_SHARED_LIBS
endif

DPDK_CONFIG = $(call qstrip,$(BR2_PACKAGE_DPDK_CONFIG))

define DPDK_CONFIGURE_CMDS
	$(MAKE) -C $(@D) T=$(DPDK_CONFIG) RTE_KERNELDIR=$(LINUX_DIR) \
			   CROSS=$(TARGET_CROSS) config
endef

define DPDK_BUILD_CMDS
	$(MAKE) -C $(@D) RTE_KERNELDIR=$(LINUX_DIR) CROSS=$(TARGET_CROSS)
endef

define DPDK_INSTALL_STAGING_CMDS
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) prefix=/usr \
		 CROSS=$(TARGET_CROSS) install-sdk
endef

ifeq ($(BR2_PACKAGE_DPDK_TEST),y)
define DPDK_INSTALL_TARGET_TEST
	mkdir -p $(TARGET_DIR)/usr/dpdk
	$(INSTALL) -m 0755 -D $(@D)/build/app/test $(TARGET_DIR)/usr/dpdk/test
	cp -dpfr $(@D)/app/test/*.py $(TARGET_DIR)/usr/dpdk
endef
endif

define DPDK_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) CROSS=$(TARGET_CROSS) \
		kerneldir=/lib/modules/$(LINUX_VERSION_PROBED)/extra/dpdk \
		prefix=/usr install-runtime install-kmod
	$(DPDK_INSTALL_TARGET_TEST)
endef

$(eval $(generic-package))
