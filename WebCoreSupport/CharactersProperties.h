#import <unicode/uchar.h>
#import <unicode/utf16.h>

namespace WebCore {

static inline bool isEmojiGroupCandidate(UChar32 character){
    auto unicodeBlock = ublock_getCode(character);
    if (unicodeBlock == UBLOCK_MISCELLANEOUS_SYMBOLS
        || unicodeBlock == UBLOCK_DINGBATS
        || unicodeBlock == UBLOCK_MISCELLANEOUS_SYMBOLS_AND_PICTOGRAPHS
        || unicodeBlock == UBLOCK_EMOTICONS
        || unicodeBlock == UBLOCK_TRANSPORT_AND_MAP_SYMBOLS)
        return true;
    #if ICU_HEADERS_UNDERSTAND_SUPPLEMENTAL_SYMBOLS_AND_PICTOGRAPHS
    static bool useSupplementalSymbolsAndPictographs = icuLibraryUnderstandsSupplementalSymbolsAndPictographs();
    if (useSupplementalSymbolsAndPictographs)
        return unicodeBlock == UBLOCK_SUPPLEMENTAL_SYMBOLS_AND_PICTOGRAPHS;
    #endif
    return character >= 0x1F900 && character <= 0x1F9FF;
}

static inline bool isEmojiFitzpatrickModifier(UChar32 character){
    return character >= 0x1F3FB && character <= 0x1F3FF;
}

inline bool isVariationSelector(UChar32 character){
    return character >= 0xFE00 && character <= 0xFE0F;
}

}

const UChar zeroWidthJoiner = 0x200D;
const UChar hangulChoseongStart = 0x1100;
const UChar hangulChoseongEnd = 0x115F;
const UChar hangulJungseongStart = 0x1160;
const UChar hangulJungseongEnd = 0x11A2;
const UChar hangulJongseongStart = 0x11A8;
const UChar hangulJongseongEnd = 0x11F9;
const UChar hangulSyllableStart = 0xAC00;
const UChar hangulSyllableEnd = 0xD7AF;
const UChar hangulJongseongCount = 28;

enum class HangulState {
    L, V, T, LV, LVT, Break
};

static inline bool isHangulLVT(UChar character){
    return (character - hangulSyllableStart) % hangulJongseongCount;
}

static inline bool isMark(UChar32 character){
    return U_GET_GC_MASK(character) & U_GC_M_MASK;
}

static inline bool isRegionalIndicator(UChar32 character){
    return 0x1F1E6 <= character && character <= 0x1F1FF;
}

static inline bool isInArmenianToLimbuRange(UChar32 character){
    return character >= 0x0530 && character < 0x1950;
}
