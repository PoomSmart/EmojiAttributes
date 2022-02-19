// © 2021 and later: Unicode, Inc. and others.
// License & terms of use: https://www.unicode.org/copyright.html

// emojiprops.h
// created: 2021sep03 Markus W. Scherer

#ifndef __EMOJIPROPS_H__
#define __EMOJIPROPS_H__

#include <unicode/uchar.h>
#include <unicode/utypes.h>
#include "unicode/udatamem.h"
#include "unicode/ucptrie.h"
#include "unicode/ucmndata.h"

UProperty UCHAR_RGI_EMOJI = (UProperty)71; // uchar.h

enum {
    // Byte offsets from the start of the data, after the generic header,
    // in ascending order.
    // UCPTrie=CodePointTrie, follows the indexes
    IX_CPTRIE_OFFSET,
    IX_RESERVED1,
    IX_RESERVED2,
    IX_RESERVED3,

    // UCharsTrie=CharsTrie
    IX_BASIC_EMOJI_TRIE_OFFSET,
    IX_EMOJI_KEYCAP_SEQUENCE_TRIE_OFFSET,
    IX_RGI_EMOJI_MODIFIER_SEQUENCE_TRIE_OFFSET,
    IX_RGI_EMOJI_FLAG_SEQUENCE_TRIE_OFFSET,
    IX_RGI_EMOJI_TAG_SEQUENCE_TRIE_OFFSET,
    IX_RGI_EMOJI_ZWJ_SEQUENCE_TRIE_OFFSET,
    IX_RESERVED10,
    IX_RESERVED11,
    IX_RESERVED12,
    IX_TOTAL_SIZE,

    // Not initially byte offsets.
    IX_RESERVED14,
    IX_RESERVED15,
    IX_COUNT  // 16
};

// Properties in the code point trie.
enum {
    // https://www.unicode.org/reports/tr51/#Emoji_Properties
    BIT_EMOJI,
    BIT_EMOJI_PRESENTATION,
    BIT_EMOJI_MODIFIER,
    BIT_EMOJI_MODIFIER_BASE,
    BIT_EMOJI_COMPONENT,
    BIT_EXTENDED_PICTOGRAPHIC,
    // https://www.unicode.org/reports/tr51/#Emoji_Sets
    BIT_BASIC_EMOJI
};

// static int32_t getStringTrieIndex(int32_t i) {
//     return i - IX_BASIC_EMOJI_TRIE_OFFSET;
// }

// const UChar *stringTries[6] = { nullptr, nullptr, nullptr, nullptr, nullptr, nullptr };

#endif  // __EMOJIPROPS_H__