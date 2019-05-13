#define CHECK_TARGET
#define CHECK_EXCEPTIONS
#import <dlfcn.h>
#import "../PS.h"

%ctor {
    if (_isTarget(TargetTypeApps | TargetTypeGenericExtensions, @[@"com.apple.WebKit.WebContent"]))
        dlopen("/Library/MobileSubstrate/DynamicLibraries/EmojiAttributes/EmojiAttributes.dylib", RTLD_NOW | RTLD_GLOBAL);
}
