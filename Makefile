TARGET := iphone:clang:latest:14.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = YouTubeMusic

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MusicSpacePro

MusicSpacePro_FILES = Tweak.x
MusicSpacePro_CFLAGS = -fobjc-arc
MusicSpacePro_FRAMEWORKS = UIKit Foundation AVFoundation MediaPlayer

include $(THEOS_MAKE_PATH)/tweak.mk
