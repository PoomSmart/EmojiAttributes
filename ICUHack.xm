#import "../PS.h"
#import "PSEmojiData.h"

#include <unicode/utf8.h>
#include <unicode/utypes.h>

%config(generator=MobileSubstrate)

int binary_search(UChar32 arr[], int l, int r, UChar32 c) {
    if (r >= l) {
        int mid = l + (r - l) / 2;
        if (arr[mid] == c)
            return mid;
        if (arr[mid] > c)
            return binary_search(arr, l, mid - 1, c);
        return binary_search(arr, mid + 1, r, c);
    }
    return -1;
}

%hookf(UBool, u_hasBinaryProperty, UChar32 c, UProperty which) {
    if (c > 0x231a && c < 0x1ffff && which == UCHAR_EMOJI_PRESENTATION) {
        return binary_search([PSEmojiData presentation], 0, [PSEmojiData presentationCount] - 1, c) != -1;
    }
    if (c > 0xa9 && c < 0x1ffff && which == UCHAR_EXTENDED_PICTOGRAPHIC) {
        return binary_search([PSEmojiData pictographic], 0, [PSEmojiData pictographicCount] - 1, c) != -1;
    }
    return %orig(c, which);
}

%ctor {
    if (isiOS13_2Up)
        return;
    %init;
}