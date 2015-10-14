################################################################################
#
# dpdk
#
################################################################################

DPDK_VERSION = 2.2.0-rc3
DPDK_SITE = http://dpdk.org/browse/dpdk/snapshot
DPDK_SOURCE = dpdk-$(DPDK_VERSION).tar.gz

DPDK_LICENSE = BSD
DPDK_LICENSE_FILES = LICENSE.LGPL LICENSE.GPL
DPDK_INSTALL_STAGING = YES

DPDK_DEPENDENCIES += linux

ifeq ($(BR2_PACKAGE_LIBPCAP),y)
DPDK_DEPENDENCIES += libpcap
endif

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

# We create symlink named $(DPDK_CONFIG) to the build directory
# to avoid calling install which behaves strange in DPDK build system.
define DPDK_CONFIGURE_CMDS
	$(MAKE) -C $(@D) T=$(DPDK_CONFIG) RTE_KERNELDIR=$(LINUX_DIR) CROSS=$(TARGET_CROSS) config
	@ln -sv build $(@D)/$(DPDK_CONFIG)
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

ifeq ($(BR2_PACKAGE_PYTHON),y)
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
	$(INSTALL) -m 0755 -D -d $(TARGET_DIR)/usr/dpdk
	$(INSTALL) -m 0755 -D $(@D)/build/app/test $(TARGET_DIR)/usr/dpdk
	$(INSTALL) -m 0755 -D $(@D)/app/test/*.py $(TARGET_DIR)/usr/dpdk
endef

ifeq ($(BR2_PACKAGE_PYTHON),y)
DPDK_DEPENDENCIES += python-pexpect
endif
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
