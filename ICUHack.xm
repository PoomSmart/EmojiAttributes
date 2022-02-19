#define EXTENDED_EMOJI_DATA
#import "../PS.h"
#import "PSEmojiData.h"
#import "ICUBlocks.h"
#import "emojiprops.h"
#import <theos/IOSMacros.h>
#import <libundirect/libundirect.h>
#import <HBLog.h>

#include <sys/mman.h>
#include <sys/stat.h>

#define uprv_memset(buffer, mark, size) U_STANDARD_CPP_NAMESPACE memset(buffer, mark, size)

U_CAPI UCPTrie *(*ucptrie_openFromBinary)(UCPTrieType type, UCPTrieValueWidth valueWidth, const void *data, int32_t length, int32_t *pActualLength, UErrorCode *pErrorCode);

UDataMemory *memory = nullptr;
UCPTrie *cpTrie = nullptr;

void UDataMemory_init(UDataMemory *This) {
    uprv_memset(This, 0, sizeof(UDataMemory));
    This->length=-1;
}

UDataMemory *UDataMemory_createNewInstance(UErrorCode *pErr) {
    UDataMemory *This;

    if (U_FAILURE(*pErr)) {
        return NULL;
    }
    This = (UDataMemory *)malloc(sizeof(UDataMemory));
    if (This == NULL) {
        *pErr = U_MEMORY_ALLOCATION_ERROR; }
    else {
        UDataMemory_init(This);
        This->heapAllocated = TRUE;
    }
    return This;
}

void udata_open_custom(UErrorCode *status) {
    static const char *path = "/usr/share/icu/uemoji.icu";
    int fd;
    int length;
    struct stat mystat;
    void *data;

    memory = UDataMemory_createNewInstance(status);
    if (U_FAILURE(*status)) {
        HBLogDebug(@"[ICUHack] udata_open_custom instance failed with error %s", u_errorName(*status));
        return;
    }

    UDataMemory_init(memory);

    if (stat(path, &mystat) != 0 || mystat.st_size <= 0) {
        HBLogDebug(@"[ICUHack] udata_open_custom stat() failed with error %d", errno);
        return;
    }
    length = mystat.st_size;

    fd = open(path, O_RDONLY);
    if (fd == -1) {
        HBLogDebug(@"[ICUHack] udata_open_custom open() failed with error %d", errno);
        return;
    }

    data = mmap(0, length, PROT_READ, MAP_SHARED, fd, 0);
    close(fd);
    if (data == MAP_FAILED) {
        HBLogDebug(@"[ICUHack] udata_open_custom mmap() failed");
        return;
    }

    memory->map = (char *)data + length;
    memory->pHeader=(const DataHeader *)data;
    memory->mapAddr = data;
#if U_PLATFORM == U_PF_IPHONE
    posix_madvise(data, length, POSIX_MADV_RANDOM);
#endif
}

static void EmojiProps_load(UErrorCode &errorCode) {
    udata_open_custom(&errorCode);
    if (U_FAILURE(errorCode)) {
        return;
    }
    const uint8_t *inBytes = (const uint8_t *)udata_getMemory(memory);
    const int32_t *inIndexes = (const int32_t *)inBytes;
    int32_t indexesLength = inIndexes[IX_CPTRIE_OFFSET] / 4;
    if (indexesLength <= IX_RGI_EMOJI_ZWJ_SEQUENCE_TRIE_OFFSET) {
        errorCode = U_INVALID_FORMAT_ERROR;  // Not enough indexes.
        HBLogDebug(@"[ICUHack] EmojiProps_load invalid format error");
        return;
    }

    int32_t i = IX_CPTRIE_OFFSET;
    int32_t offset = inIndexes[i++];
    int32_t nextOffset = inIndexes[i];
    cpTrie = ucptrie_openFromBinary(UCPTRIE_TYPE_FAST, UCPTRIE_VALUE_BITS_8,
                                    inBytes + offset, nextOffset - offset, nullptr, &errorCode);
    if (U_FAILURE(errorCode)) {
        HBLogDebug(@"[ICUHack] ucptrie_openFromBinary failed");
        return;
    }

    // for (i = IX_BASIC_EMOJI_TRIE_OFFSET; i <= IX_RGI_EMOJI_ZWJ_SEQUENCE_TRIE_OFFSET; ++i) {
    //     offset = inIndexes[i];
    //     nextOffset = inIndexes[i + 1];
    //     // Set/leave nullptr if there is no UCharsTrie.
    //     const UChar *p = nextOffset > offset ? (const UChar *)(inBytes + offset) : nullptr;
    //     stringTries[getStringTrieIndex(i)] = p;
    // }
}

static UBool EmojiProps_hasBinaryPropertyImpl(UChar32 c, UProperty which) {
    if (which < UCHAR_EMOJI || UCHAR_RGI_EMOJI < which) {
        return false;
    }
    // Note: UCHAR_REGIONAL_INDICATOR is a single, hardcoded range implemented elsewhere.
    static constexpr int8_t bitFlags[] = {
        BIT_EMOJI,                  // UCHAR_EMOJI=57
        BIT_EMOJI_PRESENTATION,     // UCHAR_EMOJI_PRESENTATION=58
        BIT_EMOJI_MODIFIER,         // UCHAR_EMOJI_MODIFIER=59
        BIT_EMOJI_MODIFIER_BASE,    // UCHAR_EMOJI_MODIFIER_BASE=60
        BIT_EMOJI_COMPONENT,        // UCHAR_EMOJI_COMPONENT=61
        -1,                         // UCHAR_REGIONAL_INDICATOR=62
        -1,                         // UCHAR_PREPENDED_CONCATENATION_MARK=63
        BIT_EXTENDED_PICTOGRAPHIC,  // UCHAR_EXTENDED_PICTOGRAPHIC=64
        BIT_BASIC_EMOJI,            // UCHAR_BASIC_EMOJI=65
        -1,                         // UCHAR_EMOJI_KEYCAP_SEQUENCE=66
        -1,                         // UCHAR_RGI_EMOJI_MODIFIER_SEQUENCE=67
        -1,                         // UCHAR_RGI_EMOJI_FLAG_SEQUENCE=68
        -1,                         // UCHAR_RGI_EMOJI_TAG_SEQUENCE=69
        -1,                         // UCHAR_RGI_EMOJI_ZWJ_SEQUENCE=70
        BIT_BASIC_EMOJI,            // UCHAR_RGI_EMOJI=71
    };
    int32_t bit = bitFlags[which - UCHAR_EMOJI];
    if (bit < 0) {
        return false;  // not a property that we support in this function
    }
    uint8_t bits = UCPTRIE_FAST_GET(cpTrie, UCPTRIE_8, c);
    return (bits >> bit) & 1;
}

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

%group hasBinaryProperty

%hookf(UBool, u_hasBinaryProperty, UChar32 c, UProperty which) {
    return EmojiProps_hasBinaryPropertyImpl(c, which) || %orig;
}

%end

%ctor {
    MSImageRef ref = MSGetImageByName(realPath2(@"/usr/lib/libicucore.A.dylib"));
#ifdef __LP64__
#if TARGET_OS_SIMULATOR
    // Memory of function (iOS 13.5): 31C083FE 020F8F8D 00000055 4889E581 FFFFD700 00770789 F8C1E805 EB4A81FF FFFF0000 771731C0 81FF00DC 0000B940 0100000F 4DC889F8 C1E805EB 29B8D813 000081FF FFFF1000 773289F8 C1E80B48 8D0D30CC 1B000FB7 8C414010 000089F8 C1E80583 E03F01C8 89C0488D 0D15CC1B 000FB704 4183E71F 488D0487 488D0D03 CC1B000F B7044148 63CE4801 C1488D05 D2B11A00 8B04885D C3
    // Memory of function (iOS 12.4): 554889E5 31C083FE 020F8F8A 00000081 FFFFD700 00770789 F8C1E805 EB4C81FF FFFF0000 771731C0 81FF00DC 0000B940 0100000F 4DC889F8 C1E805EB 2B81FFFF FF100076 07B8D413 0000EB32 89F8C1E8 0B488D0D CFE61B00 0FB78C41 40100000 89F8C1E8 0583E03F 01C889C0 488D0DB4 E61B000F B7044183 E71F488D 0487488D 0DA2E61B 000FB704 414863CE 4801C148 8D0571D3 1A008B04 885DC3
    // Unique bytes (iOS 13.5): E03F01C8 89C0488D 0D15CC1B (offset: 100)
    // Unique bytes (iOS 12.4): 0583E03F 01C889C0 488D0DB4 (offset: 100)
    // Starting byte (iOS 13.5): 0x31
    // Starting byte (iOS 12.4): 0x55
    void *rp = libundirect_find(@"libicucore.A.dylib", (unsigned char[]){0xE0, 0x3F, 0x01, 0xC8, 0x89, 0xC0, 0x48, 0x8D, 0x0D, 0x15, 0xCC, 0x1B}, 12, 0x31);
    if (rp == NULL)
        rp = libundirect_find(@"libicucore.A.dylib", (unsigned char[]){0x05, 0x83, 0xE0, 0x3F, 0x01, 0xC8, 0x89, 0xC0, 0x48, 0x8D, 0x0D, 0xB4}, 12, 0x55);
#else
    // From dyld_shared_cache_arm64 (iOS 11.3.1)
    // Memory of function: 3F080071 6D000054 00008052 C0035FD6 087C0B53 1F690071 68000054 087C0553 13000014 097C1053 E9000035 08809B52 1F00086B 08288052 08B19F1A 0815400B 0B000014 3F410071 69000054 08728252 0C000014 08812011 490D0090 29B11691 28596878 09280553 2801080B 490D0090 29B11691 28596878 09100012 2809088B 490D0090 29B11691 28796878 0801010B A90C00F0 29812B91 20D968B8 C0035FD6
    // From pure binary
    // Memory of function: 3F080071 6D000054 00008052 C0035FD6 087C0B53 1F690071 68000054 087C0513 08000014 087C1053 68020035 08809B52 1F00086B 08288052 08B19F1A 0815800B 090D00B0 29110F91 28D96878 09100012 2809080B 090D00B0 29110F91 28D96878 0801010B 890C00B0 29A12791 20D968B8 C0035FD6 1F410071 69000054 08548252 F5FFFF17 087C0B13 090D00B0 29110F91 28C5288B 08816079 0A280553 08412A8B 28796878 EAFFFF17
    // Unique bytes: 3F080071 6D000054 00008052 C0035FD6 (offset: 0)
    // Starting byte: 0x3F
    void *rp = libundirect_find(@"libicucore.A.dylib", (unsigned char[]){0x3F, 0x08, 0x00, 0x71, 0x6D, 0x00, 0x00, 0x54, 0x00, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6}, 16, 0x3F);
#endif
#else
    const uint8_t *p = (const uint8_t *)MSFindSymbol(ref, "_u_isUAlphabetic");
    void *rp = (void *)((const uint8_t *)p + 0x16);
#endif
    HBLogDebug(@"[ICUHack] u_getUnicodeProperties found %d", rp != NULL);
    if (rp) {
        %init(getUnicodeProperties, u_getUnicodeProperties = (void *)rp);
    }
    ucptrie_openFromBinary = (UCPTrie *(*)(UCPTrieType, UCPTrieValueWidth, const void *, int32_t, int32_t *, UErrorCode *))MSFindSymbol(ref, "_ucptrie_openFromBinary");
    HBLogDebug(@"[ICUHack] ucptrie_openFromBinary found %d", ucptrie_openFromBinary != NULL);
    UErrorCode errorCode = U_ZERO_ERROR;
    EmojiProps_load(errorCode);
    if (U_FAILURE(errorCode)) {
        HBLogDebug(@"[ICUHack] Failed to load uemoji.icu because %s", u_errorName(errorCode));
        return;
    }
    %init(hasBinaryProperty);
}

%dtor {
    if (memory)
        udata_close(memory);
    if (cpTrie)
        ucptrie_close(cpTrie);
}