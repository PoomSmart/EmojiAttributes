#import <unicode/uchar.h>
#import <unicode/utf16.h>

namespace WebCore {

static inline bool isEmojiGroupCandidate(UChar32 character) {
    switch (static_cast<int>(ublock_getCode(character))) {
        case UBLOCK_MISCELLANEOUS_SYMBOLS:
        case UBLOCK_DINGBATS:
        case UBLOCK_MISCELLANEOUS_SYMBOLS_AND_PICTOGRAPHS:
        case UBLOCK_EMOTICONS:
        case UBLOCK_TRANSPORT_AND_MAP_SYMBOLS:
        case UBLOCK_SUPPLEMENTAL_SYMBOLS_AND_PICTOGRAPHS:
        case UBLOCK_SYMBOLS_AND_PICTOGRAPHS_EXTENDED_A:
            return true;
        default:
            return false;
    }
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

inline bool isEmojiRegionalIndicator(UChar32 character) {
    return character >= 0x1F1E6 && character <= 0x1F1FF;
}
	
// inline bool isEmojiWithPresentationByDefault(UChar32 character) {
//     return u_hasBinaryProperty(character, UCHAR_EMOJI_PRESENTATION);
// }

// inline bool isEmojiModifierBase(UChar32 character) {
//     return u_hasBinaryProperty(character, UCHAR_EMOJI_MODIFIER_BASE);
// }

static inline bool isInArmenianToLimbuRange(UChar32 character){
    return character >= 0x0530 && character < 0x1950;
}
