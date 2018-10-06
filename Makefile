PACKAGE_VERSION = 1.3.14d

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:10.0
	ARCHS = x86_64 i386
else
	TARGET = iphone:clang:11.0:5.0
endif

include $(THEOS)/makefiles/common.mk

ifeq ($(SIMULATOR),1)
	TWEAK_NAME = EmojiAttributes
else
	LIBRARY_NAME = EmojiAttributes
	EmojiAttributes_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/EmojiAttributes
endif
EmojiAttributes_FILES = TextInputHack.xm CharacterSet.xm WebCoreHack.xm CoreFoundationHack.xm
EmojiAttributes_CFLAGS = -std=c++11
EmojiAttributes_EXTRA_FRAMEWORKS = CydiaSubstrate
EmojiAttributes_LIBRARIES = icucore
EmojiAttributes_USE_SUBSTRATE = 1

ifneq ($(SIMULATOR),1)
	TWEAK_NAME = EmojiAttributesRun
	EmojiAttributesRun_FILES = Tweak.xm
	include $(THEOS_MAKE_PATH)/library.mk
endif

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(SIMULATOR),1)
all::
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(PWD)/EmojiAttributesRun.plist /opt/simject/$(TWEAK_NAME).plist
endif
