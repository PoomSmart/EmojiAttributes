#import "../PS.h"
#import "ICUBlocks.h"
#import <libundirect.h>

%config(generator=MobileSubstrate)

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

%group getUnicodeProperties

%hookf(uint32_t, u_getUnicodeProperties, UChar32 c, int32_t column) {
    if (column >= propsVectorsColumns)
        return 0;
    uint16_t vecIndex = UTRIE2_GET16(&propsVectorsTrie, c);
    return propsVectors[vecIndex + column];
}

%end

%ctor {
#ifdef __LP64__
#if TARGET_OS_SIMULATOR
    // Memory of function: 554889E5 31C083FE 020F8F8A 00000081 FFFFD700 00770789 F8C1E805 EB4C81FF FFFF0000 771731C0 81FF00DC 0000B940 0100000F 4DC889F8 C1E805EB 2B81FFFF FF100076 07B8D413 0000EB32 89F8C1E8 0B488D0D CFE61B00 0FB78C41 40100000 89F8C1E8 0583E03F 01C889C0 488D0DB4 E61B000F B7044183 E71F488D 0487488D 0DA2E61B 000FB704 414863CE 4801C148 8D0571D3 1A008B04 885DC3
    // Unique bytes: 0583E03F 01C889C0 488D0DB4 (offset: 100)
    // Starting byte: 0x55
    void *rp = libundirect_find(@"libicucore", (unsigned char[]){0x05, 0x83, 0xE0, 0x3F, 0x01, 0xC8, 0x89, 0xC0, 0x48, 0x8D, 0x0D, 0xB4}, 12, 0x55);
#else
    // Memory of function: 3F080071 6D000054 00008052 C0035FD6 087C0B53 1F690071 68000054 087C0513 08000014 087C1053 68020035 08809B52 1F00086B 08288052 08B19F1A 0815800B 090D00B0 29110F91 28D96878 09100012 2809080B 090D00B0 29110F91 28D96878 0801010B 890C00B0 29A12791 20D968B8 C0035FD6 1F410071 69000054 08548252 F5FFFF17 087C0B13 090D00B0 29110F91 28C5288B 08816079 0A280553 08412A8B 28796878 EAFFFF17
    // Unique bytes: 3F080071 6D000054 00008052 C0035FD6 (offset: 0)
    // Starting byte: 0x3F
    void *rp = libundirect_find(@"libicucore", (unsigned char[]){0x3F, 0x08, 0x00, 0x71, 0x6D, 0x00, 0x00, 0x54, 0x00, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6}, 16, 0x3F);
#endif
#else
    MSImageRef ref = MSGetImageByName(realPath2(@"/usr/lib/libicucore.A.dylib"));
    const uint8_t *p = (const uint8_t *)MSFindSymbol(ref, "_u_isUAlphabetic");
    void *rp = (void *)((const uint8_t *)p + 0x16);
#endif
    uint32_t (*u_getUnicodeProperties_p)(UChar32, int32_t) = (uint32_t (*)(UChar32, int32_t))make_sym_callable(rp);
    HBLogDebug(@"Pointer found %d", u_getUnicodeProperties_p != NULL);
    if (u_getUnicodeProperties_p) {
        %init(getUnicodeProperties, u_getUnicodeProperties = (void *)u_getUnicodeProperties_p);
    }
}