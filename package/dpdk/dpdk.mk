################################################################################
#
# dpdk
#
################################################################################

DPDK_VERSION = $(call qstrip,$(BR2_PACKAGE_DPDK_VERSION))
ifeq ($(BR2_PACKAGE_DPDK_CUSTOM_TARBALL),y)
DPDK_TARBALL = $(call qstrip,$(BR2_PACKAGE_DPDK_CUSTOM_TARBALL_LOCATION))
DPDK_SIZE = $(patsubst %/,%,$(dir $(DPDK_TARBALL)))
DPDK_SOURCE = $(notdir $(DPDK_TARBALL))
BR_NO_CHECK_HASH_FOR += $(DPDK_SOURCE)
else ifeq ($(BR2_PACKAGE_DPDK_CUSTOM_LOCAL),y)
DPDK_SITE = $(call qstrip,$(BR2_PACKAGE_DPDK_CUSTOM_LOCAL_PATH))
DPDK_SITE_METHOD = local
else ifeq ($(BR2_PACKAGE_DPDK_CUSTOM_GIT),y)
DPDK_SITE = $(call qstrip,$(BR2_PACKAGE_DPDK_CUSTOM_REPO_URL))
DPDK_SITE_METHOD = git
else
DPDK_SITE = http://dpdk.org/browse/dpdk/snapshot
DPDK_SOURCE = dpdk-$(DPDK_VERSION).tar.gz
ifeq ($(BR2_PACKAGE_DPDK_VERSION_CUSTOM),y)
BR_NO_CHECK_HASH_FOR += $(DPDK_SOURCE)
endif
endif

DPDK_LICENSE = BSD
DPDK_LICENSE_FILES = LICENSE.LGPL LICENSE.GPL
DPDK_INSTALL_STAGING = YES

DPDK_DEPENDENCIES += linux
#DPDK_DEPENDENCIES += $(if $(BR2_PACKAGE_DPDK_PMD_PCAP),libpcap,)

ifeq ($(BR2_SHARED_LIBS),y)
define DPDK_ENABLE_SHARED_LIBS
	@echo CONFIG_RTE_BUILD_COMBINE_LIBS=y >> $(@D)/build/.config
	@echo CONFIG_RTE_BUILD_SHARED_LIB=y >> $(@D)/build/.config
endef

DPDK_POST_CONFIGURE_HOOKS += DPDK_ENABLE_SHARED_LIBS
endif

# We're building a kernel module without using the kernel-module infra,
# so we need to tell we want module support in the kernel
ifeq ($(BR2_PACKAGE_DPDK),y)
LINUX_NEEDS_MODULES = y
endif


DPDK_CONFIG = $(call qstrip,$(BR2_PACKAGE_DPDK_CONFIG))

define DPDK_CONFIGURE_CMDS
	$(MAKE) -C $(@D) T=$(DPDK_CONFIG) RTE_KERNELDIR=$(LINUX_DIR) CROSS=$(TARGET_CROSS) config
	@ln -sv build $(@D)/$(DPDK_CONFIG) # avoid calling install
endef

define DPDK_BUILD_CMDS
	$(MAKE1) -C $(@D) T=$(DPDK_CONFIG) RTE_KERNELDIR=$(LINUX_DIR) CROSS=$(TARGET_CROSS) install
endef

ifeq ($(BR2_SHARED_LIBS),n)
# Install static libs only (DPDK compiles either *.so or *.a)
define DPDK_INSTALL_STAGING_LIBS
	$(INSTALL) -m 0755 -D -d $(STAGING_DIR)/usr/lib
	$(INSTALL) -m 0644 -D $(@D)/build/lib/*.a $(STAGING_DIR)/usr/lib
endef

DPDK_INSTALL_TARGET_LIBS =
else
# Install shared libs only (DPDK compiles either *.so or *.a)
define DPDK_INSTALL_STAGING_LIBS
	$(INSTALL) -m 0755 -D -d $(STAGING_DIR)/usr/lib
	$(INSTALL) -m 0644 -D $(@D)/build/lib/*.so* $(STAGING_DIR)/usr/lib
endef

define DPDK_INSTALL_TARGET_LIBS
	$(INSTALL) -m 0755 -D -d $(STAGING_DIR)/usr/lib
	$(INSTALL) -m 0644 -D $(@D)/build/lib/*.so* $(TARGET_DIR)/usr/lib
endef
endif

ifeq ($(BR2_PACKAGE_DPDK_TOOLS_PYSCRIPTS),y)
define DPDK_INSTALL_TARGET_PYSCRIPTS
	$(INSTALL) -m 0755 -D -d $(STAGING_DIR)/usr/bin
	$(INSTALL) -m 0755 -D $(@D)/tools/dpdk_nic_bind.py $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 0755 -D $(@D)/tools/cpu_layout.py $(TARGET_DIR)/usr/bin
endef

DPDK_DEPENDENCIES += python
endif

ifeq ($(BR2_PACKAGE_DPDK_TOOLS_TESTPMD),y)
define DPDK_INSTALL_TARGET_TESTPMD
	$(INSTALL) -m 0755 -D -d $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 0755 -D $(@D)/build/app/testpmd $(TARGET_DIR)/usr/bin
endef
endif

ifeq ($(BR2_PACKAGE_DPDK_TOOLS_TEST),y)
define DPDK_INSTALL_TARGET_TEST
	$(INSTALL) -m 0755 -D -d $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 0755 -D $(@D)/build/app/test $(TARGET_DIR)/usr/bin
endef
endif

define DPDK_INSTALL_STAGING_CMDS
	$(INSTALL) -m 0755 -D -d $(STAGING_DIR)/usr/include
	$(INSTALL) -m 0644 -D $(@D)/build/include/*.h $(STAGING_DIR)/usr/include
	$(DPDK_INSTALL_STAGING_LIBS)
endef

define DPDK_INSTALL_TARGET_CMDS
	$(DPDK_INSTALL_TARGET_LIBS)
	$(DPDK_INSTALL_TARGET_PYSCRIPTS)
	$(DPDK_INSTALL_TARGET_TESTPMD)
	$(DPDK_INSTALL_TARGET_TEST)
endef

$(eval $(generic-package))
