#include <unicode/utf16.h>

@interface PSEmojiData : NSObject
+ (int)pictographicCount;
+ (UChar32 *)pictographic;
+ (int)presentationCount;
+ (UChar32 *)presentation;
@end