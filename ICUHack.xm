#import "PSEmojiData.h"
#import "ICUBlocks.h"

#define UPROPS_BLOCK_MASK 0x0001ff00
#define UPROPS_BLOCK_SHIFT 8

#define _UTRIE2_INDEX_FROM_SUPP(trieIndex, c) \
    (((int32_t)((trieIndex)[ \
        (trieIndex)[(UTRIE2_INDEX_1_OFFSET-UTRIE2_OMITTED_BMP_INDEX_1_LENGTH)+ \
                      ((c)>>UTRIE2_SHIFT_1)]+ \
        (((c)>>UTRIE2_SHIFT_2)&UTRIE2_INDEX_2_MASK)]) \
    <<UTRIE2_INDEX_SHIFT)+ \
    ((c)&UTRIE2_DATA_MASK))
#define _UTRIE2_GET_FROM_SUPP(trie, data, c) \
    (trie)->data[(c)>=(trie)->highStart ? (trie)->highValueIndex : \
                 _UTRIE2_INDEX_FROM_SUPP((trie)->index, c)]
#define UTRIE2_GET16_FROM_SUPP(trie, c) _UTRIE2_GET_FROM_SUPP((trie), index, c)
#define _UTRIE2_INDEX_RAW(offset, trieIndex, c) \
    (((int32_t)((trieIndex)[(offset)+((c)>>UTRIE2_SHIFT_2)]) \
    <<UTRIE2_INDEX_SHIFT)+ \
    ((c)&UTRIE2_DATA_MASK))
#define _UTRIE2_INDEX_FROM_CP(trie, asciiOffset, c) \
    ((uint32_t)(c)<0xd800 ? \
    _UTRIE2_INDEX_RAW(0, (trie)->index, c) : \
    (uint32_t)(c)<=0xffff ? \
    _UTRIE2_INDEX_RAW( \
    (c)<=0xdbff ? UTRIE2_LSCP_INDEX_2_OFFSET-(0xd800>>UTRIE2_SHIFT_2) : 0, \
    (trie)->index, c) : \
    (uint32_t)(c)>0x10ffff ? \
    (asciiOffset)+UTRIE2_BAD_UTF8_DATA_OFFSET : \
    (c)>=(trie)->highStart ? \
    (trie)->highValueIndex : \
    _UTRIE2_INDEX_FROM_SUPP((trie)->index, c))
#define _UTRIE2_GET(trie, data, asciiOffset, c) \
    (trie)->data[_UTRIE2_INDEX_FROM_CP(trie, asciiOffset, c)]
#define UTRIE2_GET16(trie, c) _UTRIE2_GET((trie), index, (trie)->indexLength, (c))

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
    UBool r = %orig(c, which);
    if (which == UCHAR_EMOJI_MODIFIER) {
        return r ?: binary_search(modifier, 0, modifierCount - 1, c) != -1;
    }
    if (which == UCHAR_EMOJI_PRESENTATION) {
        return r ?: binary_search(presentation, 0, presentationCount - 1, c) != -1;
    }
    if (which == UCHAR_EXTENDED_PICTOGRAPHIC) {
        return r ?: binary_search(pictographic, 0, pictographicCount - 1, c) != -1;
    }
    if (which == UCHAR_GRAPHEME_EXTEND) {
        return r ?: binary_search(graphme, 0, graphmeCount - 1, c) != -1;
    }
    return r;
}

static uint32_t u_getUnicodeProperties(UChar32 c, int32_t column) {
    if (column >= propsVectorsColumns)
        return 0;
    uint16_t vecIndex = UTRIE2_GET16(&propsVectorsTrie, c);
    return propsVectors[vecIndex + column];
}

%hookf(UBlockCode, ublock_getCode, UChar32 c) {
    return (UBlockCode)((u_getUnicodeProperties(c, 0) & UPROPS_BLOCK_MASK) >> UPROPS_BLOCK_SHIFT);
}

%ctor {
    %init;
}