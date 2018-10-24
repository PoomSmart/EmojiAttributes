#import "../PS.h"
#import <dlfcn.h>

%hook NSBundle

- (NSString *)pathForResource:(NSString *)resourceName ofType:(NSString *)resourceType {
    if (stringEqual(resourceName, @"TIUserDictionaryEmojiCharacterSet") && stringEqual(resourceType, @"bitmap"))
        return %orig(@"emoji", @"bitmap");
    return %orig;
}

%end

%ctor {
    if (isiOS10Up)
        return;
    dlopen(realPath2(@"/System/Library/PrivateFrameworks/TextInput.framework/TextInput"), RTLD_LAZY);
    %init;
}
