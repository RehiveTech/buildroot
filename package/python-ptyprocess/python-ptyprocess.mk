################################################################################
#
# python-ptyprocess
#
################################################################################

PYTHON_PTYPROCESS_VERSION = 0.5
PYTHON_PTYPROCESS_SITE = $(call github,pexpect,ptyprocess,$(PYTHON_PTYPROCESS_VERSION))
PYTHON_PTYPROCESS_LICENSE = ISC
PYTHON_PTYPROCESS_LICENSE_FILES = LICENSE
PYTHON_PTYPROCESS_SETUP_TYPE = distutils

$(eval $(python-package))
