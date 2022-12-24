#import "../PS.h"
#import "ICUBlocks.h"
#import "emojiprops.h"
#include "unicode/ucptrie_impl.h"
#include "unicode/ucmndata.h"
#include "unicode/udatamem.h"
#include "unicode/cmemory.h"
#import <theos/IOSMacros.h>
#import <libundirect/libundirect.h>
#import <HBLog.h>

#include <sys/mman.h>
#include <sys/stat.h>

#define uprv_memset(buffer, mark, size) U_STANDARD_CPP_NAMESPACE memset(buffer, mark, size)
U_CAPI void U_EXPORT2 uprv_free(void *mem);
U_CAPI void * U_EXPORT2 uprv_malloc(size_t s) U_MALLOC_ATTR U_ALLOC_SIZE_ATTR(1);

void (*ucptrie_close)(UCPTrie *trie);
int32_t (*ucptrie_internalSmallIndex)(const UCPTrie *trie, UChar32 c);
UCPTrie *(*ucptrie_openFromBinary)(UCPTrieType type, UCPTrieValueWidth valueWidth, const void *data, int32_t length, int32_t *pActualLength, UErrorCode *pErrorCode);

#if !__arm64e__

static UCPTrie *legacy_ucptrie_openFromBinary(UCPTrieType type, UCPTrieValueWidth valueWidth, const void *data, int32_t length, int32_t *pActualLength, UErrorCode *pErrorCode) {
    if (U_FAILURE(*pErrorCode)) {
        return nullptr;
    }

    if (length <= 0 || (U_POINTER_MASK_LSB(data, 3) != 0) ||
            type < UCPTRIE_TYPE_ANY || UCPTRIE_TYPE_SMALL < type ||
            valueWidth < UCPTRIE_VALUE_BITS_ANY || UCPTRIE_VALUE_BITS_8 < valueWidth) {
        *pErrorCode = U_ILLEGAL_ARGUMENT_ERROR;
        return nullptr;
    }

    if (length < (int32_t)sizeof(UCPTrieHeader)) {
        *pErrorCode = U_INVALID_FORMAT_ERROR;
        return nullptr;
    }

    const UCPTrieHeader *header = (const UCPTrieHeader *)data;
    if (header->signature != UCPTRIE_SIG) {
        *pErrorCode = U_INVALID_FORMAT_ERROR;
        return nullptr;
    }

    int32_t options = header->options;
    int32_t typeInt = (options >> 6) & 3;
    int32_t valueWidthInt = options & UCPTRIE_OPTIONS_VALUE_BITS_MASK;
    if (typeInt > UCPTRIE_TYPE_SMALL || valueWidthInt > UCPTRIE_VALUE_BITS_8 ||
            (options & UCPTRIE_OPTIONS_RESERVED_MASK) != 0) {
        *pErrorCode = U_INVALID_FORMAT_ERROR;
        return nullptr;
    }
    UCPTrieType actualType = (UCPTrieType)typeInt;
    UCPTrieValueWidth actualValueWidth = (UCPTrieValueWidth)valueWidthInt;
    if (type < 0) {
        type = actualType;
    }
    if (valueWidth < 0) {
        valueWidth = actualValueWidth;
    }
    if (type != actualType || valueWidth != actualValueWidth) {
        *pErrorCode = U_INVALID_FORMAT_ERROR;
        return nullptr;
    }

    UCPTrie tempTrie;
    uprv_memset(&tempTrie, 0, sizeof(tempTrie));
    tempTrie.indexLength = header->indexLength;
    tempTrie.dataLength =
        ((options & UCPTRIE_OPTIONS_DATA_LENGTH_MASK) << 4) | header->dataLength;
    tempTrie.index3NullOffset = header->index3NullOffset;
    tempTrie.dataNullOffset =
        ((options & UCPTRIE_OPTIONS_DATA_NULL_OFFSET_MASK) << 8) | header->dataNullOffset;

    tempTrie.highStart = header->shiftedHighStart << UCPTRIE_SHIFT_2;
    tempTrie.shifted12HighStart = (tempTrie.highStart + 0xfff) >> 12;
    tempTrie.type = type;
    tempTrie.valueWidth = valueWidth;

    int32_t actualLength = (int32_t)sizeof(UCPTrieHeader) + tempTrie.indexLength * 2;
    if (valueWidth == UCPTRIE_VALUE_BITS_16) {
        actualLength += tempTrie.dataLength * 2;
    } else if (valueWidth == UCPTRIE_VALUE_BITS_32) {
        actualLength += tempTrie.dataLength * 4;
    } else {
        actualLength += tempTrie.dataLength;
    }
    if (length < actualLength) {
        *pErrorCode = U_INVALID_FORMAT_ERROR;
        return nullptr;
    }

    UCPTrie *trie = (UCPTrie *)uprv_malloc(sizeof(UCPTrie));
    if (trie == nullptr) {
        *pErrorCode = U_MEMORY_ALLOCATION_ERROR;
        return nullptr;
    }
    uprv_memcpy(trie, &tempTrie, sizeof(tempTrie));

    const uint16_t *p16 = (const uint16_t *)(header + 1);
    trie->index = p16;
    p16 += trie->indexLength;

    int32_t nullValueOffset = trie->dataNullOffset;
    if (nullValueOffset >= trie->dataLength) {
        nullValueOffset = trie->dataLength - UCPTRIE_HIGH_VALUE_NEG_DATA_OFFSET;
    }
    switch (valueWidth) {
    case UCPTRIE_VALUE_BITS_16:
        trie->data.ptr16 = p16;
        trie->nullValue = trie->data.ptr16[nullValueOffset];
        break;
    case UCPTRIE_VALUE_BITS_32:
        trie->data.ptr32 = (const uint32_t *)p16;
        trie->nullValue = trie->data.ptr32[nullValueOffset];
        break;
    case UCPTRIE_VALUE_BITS_8:
        trie->data.ptr8 = (const uint8_t *)p16;
        trie->nullValue = trie->data.ptr8[nullValueOffset];
        break;
    default:
        *pErrorCode = U_INVALID_FORMAT_ERROR;
        return nullptr;
    }

    if (pActualLength != nullptr) {
        *pActualLength = actualLength;
    }
    return trie;
}

static int32_t legacy_ucptrie_internalSmallIndex(const UCPTrie *trie, UChar32 c) {
    int32_t i1 = c >> UCPTRIE_SHIFT_1;
    if (trie->type == UCPTRIE_TYPE_FAST) {
        i1 += UCPTRIE_BMP_INDEX_LENGTH - UCPTRIE_OMITTED_BMP_INDEX_1_LENGTH;
    } else {
        i1 += UCPTRIE_SMALL_INDEX_LENGTH;
    }
    int32_t i3Block = trie->index[
        (int32_t)trie->index[i1] + ((c >> UCPTRIE_SHIFT_2) & UCPTRIE_INDEX_2_MASK)];
    int32_t i3 = (c >> UCPTRIE_SHIFT_3) & UCPTRIE_INDEX_3_MASK;
    int32_t dataBlock;
    if ((i3Block & 0x8000) == 0) {
        dataBlock = trie->index[i3Block + i3];
    } else {
        i3Block = (i3Block & 0x7fff) + (i3 & ~7) + (i3 >> 3);
        i3 &= 7;
        dataBlock = ((int32_t)trie->index[i3Block++] << (2 + (2 * i3))) & 0x30000;
        dataBlock |= trie->index[i3Block + i3];
    }
    return dataBlock + (c & UCPTRIE_SMALL_DATA_MASK);
}

static void legacy_ucptrie_close(UCPTrie *trie) {
   uprv_free(trie); 
}

#endif

UDataMemory *memory = nullptr;
UCPTrie *cpTrie = nullptr;

static void UDataMemory_init(UDataMemory *This) {
    uprv_memset(This, 0, sizeof(UDataMemory));
    This->length=-1;
}

static UDataMemory *UDataMemory_createNewInstance(UErrorCode *pErr) {
    UDataMemory *This;

    if (U_FAILURE(*pErr)) {
        return NULL;
    }
    This = (UDataMemory *)uprv_malloc(sizeof(UDataMemory));
    if (This == NULL) {
        *pErr = U_MEMORY_ALLOCATION_ERROR; }
    else {
        UDataMemory_init(This);
        This->heapAllocated = TRUE;
    }
    return This;
}

static void udata_open_custom(UErrorCode *status) {
    static const char *defaultPath = "/Library/Application Support/EmojiAttributes/uemoji.icu";
    static const char *rootlessPath = "/var/LIY/Application Support/EmojiAttributes/uemoji.icu";
    int fd;
    int length;
    struct stat mystat;
    void *data;

    memory = UDataMemory_createNewInstance(status);
    if (U_FAILURE(*status)) {
        HBLogError(@"[ICUHack] udata_open_custom instance failed with error %s", u_errorName(*status));
        return;
    }

    UDataMemory_init(memory);

    const char *path = defaultPath;
    if (stat(path, &mystat) != 0 || mystat.st_size <= 0) {
        path = rootlessPath;
        if (stat(path, &mystat) != 0 || mystat.st_size <= 0) {
            *status = U_FILE_ACCESS_ERROR; // custom
            HBLogError(@"[ICUHack] udata_open_custom stat() failed with error %d", errno);
            return;
        }
    }
    length = mystat.st_size;

    fd = open(path, O_RDONLY);
    if (fd == -1) {
        *status = U_FILE_ACCESS_ERROR; // custom
        HBLogError(@"[ICUHack] udata_open_custom open() failed with error %d", errno);
        return;
    }

    data = mmap(0, length, PROT_READ, MAP_SHARED, fd, 0);
    close(fd);
    if (data == MAP_FAILED) {
        *status = U_FILE_ACCESS_ERROR; // custom
        HBLogError(@"[ICUHack] udata_open_custom mmap() failed");
        return;
    }

    memory->map = (char *)data + length;
    memory->pHeader = (const DataHeader *)data;
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
        errorCode = U_INVALID_FORMAT_ERROR; // Not enough indexes.
        HBLogError(@"[ICUHack] EmojiProps_load invalid format error");
        return;
    }

    int32_t i = IX_CPTRIE_OFFSET;
    int32_t offset = inIndexes[i++];
    int32_t nextOffset = inIndexes[i];
    cpTrie = ucptrie_openFromBinary(UCPTRIE_TYPE_FAST, UCPTRIE_VALUE_BITS_8,
                                    inBytes + offset, nextOffset - offset, nullptr, &errorCode);
    if (U_FAILURE(errorCode)) {
        HBLogError(@"[ICUHack] ucptrie_openFromBinary failed");
        return;
    }
}

#ifndef UCHAR_RGI_EMOJI
#define UCHAR_RGI_EMOJI 71
#endif

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

%group inlineEmojiData

%hookf(UDataMemory *, udata_openChoice, const char *path, const char *type, const char *name, UDataMemoryIsAcceptable *isAcceptable, void *context, UErrorCode *pErrorCode) {
    if (!strcmp(type, "icu") && !strcmp(name, "uemoji")) {
        udata_open_custom(pErrorCode);
        return memory;
    }
    return %orig;
}

%end

%ctor {
    MSImageRef ref = MSGetImageByName(realPath2(@"/usr/lib/libicucore.A.dylib"));
#ifdef __LP64__
#if TARGET_OS_SIMULATOR
    // Unique bytes (iOS 13.5): E03F01C8 89C0488D 0D15CC1B (offset: 100)
    // Unique bytes (iOS 12.4): 0583E03F 01C889C0 488D0DB4 (offset: 100)
    // Unique bytes (iOS 8.2) : 554889E5 31C083FE 027F5C81 (offset: 0)
    // Starting byte (iOS 13.5): 0x31
    // Starting byte (iOS 12.4): 0x55
    // Starting byte (iOS 8.2) : 0x55
    void *rp = libundirect_find(@"libicucore.A.dylib", (unsigned char[]){0xE0, 0x3F, 0x01, 0xC8, 0x89, 0xC0, 0x48, 0x8D, 0x0D, 0x15, 0xCC, 0x1B}, 12, 0x31);
    if (rp == NULL)
        rp = libundirect_find(@"libicucore.A.dylib", (unsigned char[]){0x05, 0x83, 0xE0, 0x3F, 0x01, 0xC8, 0x89, 0xC0, 0x48, 0x8D, 0x0D, 0xB4}, 12, 0x55);
    if (rp == NULL)
        rp = libundirect_find(@"libicucore.A.dylib", (unsigned char[]){0x55, 0x48, 0x89, 0xE5, 0x31, 0xC0, 0x83, 0xFE, 0x02, 0x7F, 0x5C, 0x81}, 12, 0x55)
#else
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
    ucptrie_openFromBinary = (UCPTrie *(*)(UCPTrieType, UCPTrieValueWidth, const void *, int32_t, int32_t *, UErrorCode *))_PSFindSymbolCallable(ref, "_ucptrie_openFromBinary");
    ucptrie_internalSmallIndex = (int32_t (*)(const UCPTrie *, UChar32))_PSFindSymbolCallable(ref, "_ucptrie_internalSmallIndex");
    ucptrie_close = (void (*)(UCPTrie *))_PSFindSymbolCallable(ref, "_ucptrie_close");
#if !__arm64e__
    if (ucptrie_openFromBinary == NULL)
        ucptrie_openFromBinary = legacy_ucptrie_openFromBinary;
    if (ucptrie_internalSmallIndex == NULL)
        ucptrie_internalSmallIndex = legacy_ucptrie_internalSmallIndex;
    if (ucptrie_close == NULL)
        ucptrie_close = legacy_ucptrie_close;
    HBLogDebug(@"[ICUHack] ucptrie_openFromBinary found: %d", ucptrie_openFromBinary != NULL);
    HBLogDebug(@"[ICUHack] ucptrie_internalSmallIndex found: %d", ucptrie_internalSmallIndex != NULL);
    HBLogDebug(@"[ICUHack] ucptrie_close found: %d", ucptrie_close != NULL);
#endif
    UErrorCode errorCode = U_ZERO_ERROR;
    EmojiProps_load(errorCode);
    if (U_FAILURE(errorCode)) {
        HBLogDebug(@"[ICUHack] Failed to load uemoji.icu because %s", u_errorName(errorCode));
        return;
    }
    if (IS_IOS_OR_NEWER(iOS_15_4)) {
        %init(inlineEmojiData);
    } else {
        %init(hasBinaryProperty);
    }
}

%dtor {
    if (memory)
        udata_close(memory);
    if (cpTrie)
        ucptrie_close(cpTrie);
}