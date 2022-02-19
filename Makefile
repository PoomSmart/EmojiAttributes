PACKAGE_VERSION = 1.5.0~b8

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:8.0
	ARCHS = x86_64
else
	TARGET = iphone:clang:latest:5.0
endif

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = EmojiAttributes
$(LIBRARY_NAME)_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/EmojiPort
$(LIBRARY_NAME)_FILES = ICUHack.xm TextInputHack.xm CoreTextHack.xm WebCoreHack.xm CoreFoundationHack.xm EmojiSizeFix.xm
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
