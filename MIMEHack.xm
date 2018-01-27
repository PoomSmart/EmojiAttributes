#import "../PS.h"
#include <unicode/uset.h>

// Description: Unimplemented
// Description: Research state

%hookf(USet *, uset_openPattern, const UChar *pattern, int32_t patternLength, UErrorCode *ec) {
    NSLog(@"%s", pattern);
    return %orig;
}

%ctor {
    MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/MIME.framework/MIME"));
    %init;
}
