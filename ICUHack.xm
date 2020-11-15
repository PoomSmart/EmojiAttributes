#import "../PS.h"
#import "ICUBlocks.h"

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

#ifdef __LP64__

typedef unsigned long long addr_t;

static addr_t step64(const uint8_t *buf, addr_t start, size_t length, uint32_t what, uint32_t mask) {
	addr_t end = start + length;
	while (start < end) {
		uint32_t x = *(uint32_t *)(buf + start);
		if ((x & mask) == what) {
			return start;
		}
		start += 4;
	}
	return 0;
}

static addr_t find_branch64(const uint8_t *buf, addr_t start, size_t length) {
	return step64(buf, start, length, 0x14000000, 0xFC000000);
}

static addr_t follow_branch64(const uint8_t *buf, addr_t branch) {
	long long w;
	w = *(uint32_t *)(buf + branch) & 0x3FFFFFF;
	w <<= 64 - 26;
	w >>= 64 - 26 - 2;
	return branch + w;
}

#endif

%ctor {
    if (IS_IOS_OR_NEWER(iOS_13_2))
        return;
    MSImageRef ref = MSGetImageByName(realPath2(@"/usr/lib/libicucore.A.dylib"));
    const uint8_t *p = (const uint8_t *)MSFindSymbol(ref, "_u_isUAlphabetic");
#ifdef __LP64__
    addr_t branch = find_branch64(p, 0, 16);
	addr_t branch_offset = follow_branch64(p, branch);
    void *rp = (void *)((const uint8_t *)p + branch_offset);
#else
    void *rp = (void *)((const uint8_t *)p + 0x16);
#endif
    uint32_t (*u_getUnicodeProperties_p)(UChar32, int32_t) = (uint32_t (*)(UChar32, int32_t))make_sym_callable(rp);
    %init(getUnicodeProperties, u_getUnicodeProperties = (void *)u_getUnicodeProperties_p);
}