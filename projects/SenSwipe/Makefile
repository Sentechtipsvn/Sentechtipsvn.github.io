ARCHS = arm64
TARGET = iphone:clang:15.6:15.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SenSwipe
SenSwipe_FILES = Sources/Tweak.m
SenSwipe_CFLAGS = -fobjc-arc -Wall -Wextra -Werror
SenSwipe_FRAMEWORKS = Foundation
SenSwipe_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
