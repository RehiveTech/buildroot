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

ifeq ($(BR2_PACKAGE_DPDK_EXAMPLES),y)
# Build of DPDK examples is not very straight-forward. It requires to have
# the SDK and runtime installed on same place to reference it by RTE_SDK.
# We place it locally in the build directory.
define DPDK_BUILD_EXAMPLES
	$(MAKE) -C $(@D) DESTDIR=$(@D)/examples-sdk \
		CROSS=$(TARGET_CROSS) install-sdk install-runtime
	$(MAKE) -C $(@D) RTE_KERNELDIR=$(LINUX_DIR) CROSS=$(TARGET_CROSS) \
		RTE_SDK=$(@D)/examples-sdk/usr/local/share/dpdk \
		T=$(DPDK_CONFIG) examples
endef

DPDK_EXAMPLES_PATH = $(@D)/examples-sdk/usr/local/share/dpdk/examples

# Installation of examples is tricky in DPDK so we do it explicitly here.
# As the binaries and libraries do not have a single or regular location
# where to find them after build, we search for them by find.
define DPDK_INSTALL_EXAMPLES
	for f in `find $(DPDK_EXAMPLES_PATH) -executable -type f       \
			-path '*/lib/*.so*'`; do                       \
		$(INSTALL) -m 0755 -D $$f                              \
			$(TARGET_DIR)/usr/lib/`basename $$f` || exit 1;\
	done
	for f in `find $(DPDK_EXAMPLES_PATH) -executable -type f       \
			-path '*/app/*'`; do                           \
		$(INSTALL) -m 0755 -D $$f                              \
			$(TARGET_DIR)/usr/bin/`basename $$f` || exit 1;\
	done
endef

# Build of the power example is broken (at least for 16.04).
define DPDK_DISABLE_POWER
	$(call KCONFIG_DISABLE_OPT,CONFIG_RTE_LIBRTE_POWER,\
			$(@D)/build/.config)
endef

DPDK_POST_CONFIGURE_HOOKS += DPDK_DISABLE_POWER
endif

define DPDK_CONFIGURE_CMDS
	$(MAKE) -C $(@D) T=$(DPDK_CONFIG) RTE_KERNELDIR=$(LINUX_DIR) \
			   CROSS=$(TARGET_CROSS) config
endef

define DPDK_BUILD_CMDS
	$(MAKE) -C $(@D) RTE_KERNELDIR=$(LINUX_DIR) CROSS=$(TARGET_CROSS)
	$(DPDK_BUILD_EXAMPLES)
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
	$(DPDK_INSTALL_EXAMPLES)
endef

$(eval $(generic-package))
