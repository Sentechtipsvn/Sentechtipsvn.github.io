ARCHS = arm64
TARGET = iphone:clang:15.6:15.0
THEOS_PACKAGE_SCHEME = rootless
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SenSwipePrefs
SenSwipePrefs_FILES = SENSRootListController.m
SenSwipePrefs_CFLAGS = -fobjc-arc -Wall -Wextra -Werror
SenSwipePrefs_FRAMEWORKS = UIKit Foundation
SenSwipePrefs_PRIVATE_FRAMEWORKS = Preferences
SenSwipePrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk
