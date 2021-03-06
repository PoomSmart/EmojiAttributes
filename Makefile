PACKAGE_VERSION = 1.4.5

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:8.0
	ARCHS = x86_64
else
	TARGET = iphone:clang:latest:5.0
endif

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = EmojiAttributes
EmojiAttributes_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/EmojiPort
EmojiAttributes_FILES = ICUHack.xm TextInputHack.xm CoreTextHack.xm WebCoreHack.xm CoreFoundationHack.xm EmojiSizeFix.xm
EmojiAttributes_CCFLAGS = -std=c++11 -stdlib=libc++
EmojiAttributes_EXTRA_FRAMEWORKS = CydiaSubstrate
EmojiAttributes_LIBRARIES = icucore undirect
EmojiAttributes_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/library.mk

ifeq ($(SIMULATOR),1)
setup:: clean all
	@rm -f /opt/simject/$(LIBRARY_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(LIBRARY_NAME).dylib /opt/simject/$(LIBRARY_NAME).dylib
	@cp -v $(PWD)/$(LIBRARY_NAME).plist /opt/simject/$(LIBRARY_NAME).plist
endif
