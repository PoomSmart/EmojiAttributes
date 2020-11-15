#if !__arm64e__

#import "../PS.h"
#import <dlfcn.h>

%hook NSBundle

- (NSString *)pathForResource:(NSString *)resourceName ofType:(NSString *)resourceType {
    if (stringEqual(resourceName, @"TIUserDictionaryEmojiCharacterSet"))
        return %orig(@"emoji", @"bitmap");
    return %orig;
}

%end

%ctor {
    if (IS_IOS_OR_NEWER(iOS_10_0))
        return;
    dlopen(realPath2(@"/System/Library/PrivateFrameworks/TextInput.framework/TextInput"), RTLD_LAZY);
    %init;
}

#endif