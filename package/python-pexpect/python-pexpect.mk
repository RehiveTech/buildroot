################################################################################
#
# python-pexpect
#
################################################################################

PYTHON_PEXPECT_VERSION = 4.0.1
PYTHON_PEXPECT_SITE = $(call github,pexpect,pexpect,$(PYTHON_PEXPECT_VERSION))
PYTHON_PEXPECT_LICENSE = ISC
PYTHON_PEXPECT_LICENSE_FILES = LICENSE
PYTHON_PEXPECT_SETUP_TYPE = distutils
PYTHON_PEXPECT_DEPENDENCIES = python-ptyprocess

$(eval $(python-package))
