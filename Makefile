PACKAGE_VERSION = 1.9.0~b3

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:8.0
	ARCHS = arm64 x86_64
else
	ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
		TARGET = iphone:clang:16.5:15.0
	else ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
		TARGET = iphone:clang:16.5:15.0
	else
		TARGET = iphone:clang:14.5:5.0
		export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/
	endif
endif

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = EmojiAttributes
$(LIBRARY_NAME)_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/EmojiPort
$(LIBRARY_NAME)_FILES = ICUHack.xm CoreTextHack.xm
ifeq ($(THEOS_PACKAGE_SCHEME),)
$(LIBRARY_NAME)_FILES += CoreFoundationHack.xm TextInputHack.xm WebCoreHack.xm EmojiSizeFix.xm
endif
$(LIBRARY_NAME)_CCFLAGS = -std=c++11 -stdlib=libc++
$(LIBRARY_NAME)_EXTRA_FRAMEWORKS = CydiaSubstrate
$(LIBRARY_NAME)_LIBRARIES = icucore undirect
$(LIBRARY_NAME)_USE_SUBSTRATE = 1
$(LIBRARY_NAME)_GENERATOR = MobileSubstrate

include $(THEOS_MAKE_PATH)/library.mk

ifeq ($(SIMULATOR),1)
setup:: clean all
	@rm -f /opt/simject/$(LIBRARY_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(LIBRARY_NAME).dylib /opt/simject/$(LIBRARY_NAME).dylib
	@cp -v $(PWD)/$(LIBRARY_NAME).plist /opt/simject/$(LIBRARY_NAME).plist
endif
