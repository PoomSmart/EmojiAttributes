#import "../PS.h"
#import "CoreFoundationHack.h"
#import <substrate.h>
#import <version.h>
#import <unicode/utypes.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <sys/mman.h>

%config(generator=MobileSubstrate)

CF_INLINE bool CFUniCharIsMemberOfBitmap(UTF16Char theChar, const uint8_t *bitmap) {
    return (bitmap && (bitmap[(theChar) >> kCFUniCharBitShiftForByte] & (((uint32_t)1) << (theChar & kCFUniCharBitShiftForMask))) ? true : false);
}

inline Boolean __CFStrIsEightBit(CFStringRef str) {
    return (str->base._cfinfo[CF_INFO_BITS] & __kCFIsUnicodeMask) != __kCFIsUnicode;
}

inline bool CFUniCharIsSurrogateHighCharacter(UniChar character) {
    return ((character >= 0xD800UL) && (character <= 0xDBFFUL) ? true : false);
}

inline bool CFUniCharIsSurrogateLowCharacter(UniChar character) {
    return ((character >= 0xDC00UL) && (character <= 0xDFFFUL) ? true : false);
}

inline UTF32Char CFUniCharGetLongCharacterForSurrogatePair(UniChar surrogateHigh, UniChar surrogateLow) {
    return ((surrogateHigh - 0xD800UL) << 10) + (surrogateLow - 0xDC00UL) + 0x0010000UL;
}

static inline UTF32Char __CFStringGetLongCharacterFromInlineBuffer(CFStringInlineBuffer *buffer, CFIndex length, CFIndex idx, CFRange *readRange) {
    if (idx < 0 || idx >= length) {
        if (readRange) *readRange = CFRangeMake(kCFNotFound, 0);
        return 0;
    }
    
    CFRange range = CFRangeMake(idx, 1);
    UTF32Char character = CFStringGetCharacterFromInlineBuffer(buffer, idx);
    if (CFUniCharIsSurrogateHighCharacter(character) && idx < length - 1) {
        UTF16Char surrogateLow = CFStringGetCharacterFromInlineBuffer(buffer, idx + 1);
        if (CFUniCharIsSurrogateLowCharacter(surrogateLow)) {
            range.length++;
            character = CFUniCharGetLongCharacterForSurrogatePair(character, surrogateLow);
        }
    } else if (CFUniCharIsSurrogateLowCharacter(character) && idx > 0) {
        UTF16Char surrogateHigh = CFStringGetCharacterFromInlineBuffer(buffer, idx - 1);
        if (CFUniCharIsSurrogateHighCharacter(surrogateHigh)) {
            range.location--;
            range.length++;
            character = CFUniCharGetLongCharacterForSurrogatePair(surrogateHigh, character);
        }
    }
    
    if (readRange) *readRange = range;
    return character;
}

#ifdef FAMILY_HACK

static inline bool __CFStringIsFamilySequenceBaseCharacterHigh(UTF16Char character) {
    return ((character == 0xD83D) || (character == 0xD83E)) ? true : false;
}

static inline bool __CFStringIsFamilySequenceBaseCharacterLow(UTF16Char character) {
    return (((character >= 0xDC66) && (character <= 0xDC69)) || (character == 0xDC8B) || (character == 0xDC41) || (character == 0xDDD1) || (character == 0xDDE8)) ? true : false;
}

static inline bool __CFStringIsFamilySequenceCluster(CFStringInlineBuffer *buffer, CFRange range) {
    UTF16Char character = CFStringGetCharacterFromInlineBuffer(buffer, range.location);
    if (character == 0x2764 || character == 0xFE0F || character == 0x2640 || character == 0x2642 || character == 0xD83E || character == 0xDD1D) // HEART or variant selector or gender selector
        return true;
    if (range.length > 1) {
        if (__CFStringIsFamilySequenceBaseCharacterHigh(character) && __CFStringIsFamilySequenceBaseCharacterLow(CFStringGetCharacterFromInlineBuffer(buffer, range.location + 1)))
            return true;
    }
    return false;
}

#endif

static inline bool __CFStringIsValidExtendCharacterForPictographicSequence(UTF32Char character) {
    return u_hasBinaryProperty(character, UCHAR_GRAPHEME_EXTEND) || u_hasBinaryProperty(character, UCHAR_EMOJI_MODIFIER);
}

static inline bool __CFStringIsValidExtendedPictographicCharacterForPictographicSequence(UTF32Char character) {
    return u_hasBinaryProperty(character, UCHAR_EXTENDED_PICTOGRAPHIC);
}

static inline bool __CFStringIsValidPrecoreCharacterForPictographicSequence(UTF32Char character) {
    bool isValid = (UGraphemeClusterBreak)u_getIntPropertyValue(character, UCHAR_GRAPHEME_CLUSTER_BREAK) == U_GCB_PREPEND;
    return isValid;
}

static inline bool __CFStringIsValidPostcoreCharacterForPictographicSequence(UTF32Char character) {
    bool isValid = character == ZERO_WIDTH_JOINER || __CFStringIsValidExtendCharacterForPictographicSequence(character) || (UGraphemeClusterBreak)u_getIntPropertyValue(character, UCHAR_GRAPHEME_CLUSTER_BREAK) == U_GCB_SPACING_MARK;
    return isValid;
}

typedef struct {
    CFRange range;
    CFIndex firstExtendIndex;
    CFIndex zwjIndex;
    CFIndex pictographIndex;
} __CFStringPictographicSequenceComponent;

static inline bool __CFStringGetExtendedPictographicSequenceComponent(CFStringInlineBuffer *buffer, CFIndex length, CFIndex index, __CFStringPictographicSequenceComponent *outComponent) {
    if (index < 0 || index >= length) {
        return false;
    }
    
    __CFStringPictographicSequenceComponent match = {{kCFNotFound, 0}, -1, -1, -1};
    
    CFRange currentRange = CFRangeMake(index, 0);
    while (currentRange.location >= 0) {
        UTF32Char character = __CFStringGetLongCharacterFromInlineBuffer(buffer, length, currentRange.location, &currentRange);
        
        if (__CFStringIsValidExtendCharacterForPictographicSequence(character)) {
            match.firstExtendIndex = currentRange.location;
        } else if (character == ZERO_WIDTH_JOINER) {
            if (match.firstExtendIndex != -1 || match.zwjIndex != -1) {
                break;
            }
            
            match.zwjIndex = currentRange.location;
        } else if (__CFStringIsValidExtendedPictographicCharacterForPictographicSequence(character)) {
            if (match.pictographIndex != -1 || match.zwjIndex != -1 || match.firstExtendIndex != -1) {
                break;
            }
            
            match.pictographIndex = currentRange.location;
        } else {
            break;
        }
        
        match.range.location = currentRange.location;
        match.range.length  += currentRange.length;
        currentRange.location--;
    }
    
    if (match.pictographIndex == -1) {
        if (match.zwjIndex == -1 && match.firstExtendIndex == -1) {
            return false;
        }
    } else {
        if (match.firstExtendIndex != -1 && match.zwjIndex == -1) {
            match.range.location = match.pictographIndex;
            match.range.length  -= (match.pictographIndex - match.firstExtendIndex);
        }
        
        if (outComponent) *outComponent = match;
        return true;
    }
    
    currentRange.location = match.range.location + match.range.length;
    currentRange.length = 0;
    while (match.pictographIndex == -1 && currentRange.location < length) {
        UTF32Char character = __CFStringGetLongCharacterFromInlineBuffer(buffer, length, currentRange.location, &currentRange);
        
        if (__CFStringIsValidExtendCharacterForPictographicSequence(character)) {
            if (match.zwjIndex != -1) {
                break;
            }
        } else if (character == ZERO_WIDTH_JOINER) {
            if (match.zwjIndex != -1) {
                break;
            }
            
            match.zwjIndex = currentRange.location;
        } else if (__CFStringIsValidExtendedPictographicCharacterForPictographicSequence(character)) {
            match.pictographIndex = currentRange.location;
        } else {
            break;
        }
        
        match.range.length    += currentRange.length;
        currentRange.location += currentRange.length;
        currentRange.length    = 0;
    }
    
    if (match.pictographIndex == -1) {
        return false;
    } else {
        if (outComponent) *outComponent = match;
        return true;
    }
}

static inline bool __CFStringGetExtendedPictographicSequence(CFStringInlineBuffer *buffer, CFIndex length, CFIndex index, CFRange *outRange) {
    if (index < 0 || index >= length) {
        return false;
    }
    
    CFRange currentRange;
    UTF32Char currentCharacter = __CFStringGetLongCharacterFromInlineBuffer(buffer, length, index, &currentRange);
    
    CFRange postcoreRange = CFRangeMake(currentRange.length, 0);
    while (__CFStringIsValidPostcoreCharacterForPictographicSequence(currentCharacter)) {
        postcoreRange.location = currentRange.location;
        postcoreRange.length  += currentRange.length;
        
        if (postcoreRange.location == 0) {
            return false;
        }
        
        currentCharacter = __CFStringGetLongCharacterFromInlineBuffer(buffer, length, postcoreRange.location - 1, &currentRange);
    }
    
    __CFStringPictographicSequenceComponent currentComponent = {{kCFNotFound, 0}, -1, -1, -1};
    CFRange coreRange = CFRangeMake(currentRange.location, 0);
    while (__CFStringGetExtendedPictographicSequenceComponent(buffer, length, currentRange.location, &currentComponent)) {
        coreRange.location = currentComponent.range.location;
        coreRange.length  += currentComponent.range.length;
        
        currentRange.location = currentComponent.range.location - 1;
        currentRange.length   = 0;
        
        if (currentComponent.zwjIndex == -1) {
            break;
        }
    }
    
    bool shouldLookForPrecoreCharacters = true;
    if (currentComponent.firstExtendIndex != -1 || currentComponent.zwjIndex != -1) {
        coreRange.location    = currentComponent.pictographIndex;
        coreRange.length     -= currentComponent.pictographIndex - currentComponent.range.location;
        currentRange.location = currentComponent.pictographIndex + 1;

        shouldLookForPrecoreCharacters = false;
    }
    
    if (postcoreRange.length > 0 && coreRange.length == 0) {
        return false;
    }
    
    CFRange precoreRange = CFRangeMake(currentRange.location, 0);
    if (shouldLookForPrecoreCharacters) {
        if (currentRange.location >= 0) {
            currentCharacter = __CFStringGetLongCharacterFromInlineBuffer(buffer, length, currentRange.location, &currentRange);
            while (__CFStringIsValidPrecoreCharacterForPictographicSequence(currentCharacter)) {
                precoreRange.location = currentRange.location;
                precoreRange.length  += currentRange.length;
                
                if (precoreRange.location == 0) {
                    break;
                }
                
                currentCharacter = __CFStringGetLongCharacterFromInlineBuffer(buffer, length, precoreRange.location - 1, &currentRange);
            }
        }
        
        currentRange = CFRangeMake(precoreRange.location + precoreRange.length, 0);
        while (currentRange.location < length) {
            currentCharacter = __CFStringGetLongCharacterFromInlineBuffer(buffer, length, currentRange.location, &currentRange);
            if (__CFStringIsValidPrecoreCharacterForPictographicSequence(currentCharacter)) {
                precoreRange.length   += currentRange.length;
                currentRange.location += currentRange.length;
            } else {
                break;
            }
        }
    }
    
    if (precoreRange.length == 0 && coreRange.length == 0) {
        return false;
    }
    
    if (coreRange.length == 0) {
        coreRange = CFRangeMake(precoreRange.location + precoreRange.length, 0);
        currentRange = coreRange;
    } else {
        currentRange = CFRangeMake(coreRange.location + coreRange.length, 0);
    }
    
    while (__CFStringGetExtendedPictographicSequenceComponent(buffer, length, currentRange.location, &currentComponent)) {
        if (coreRange.length > 0 && currentComponent.zwjIndex == -1) {
            break;
        }
        
        coreRange.length      += currentComponent.range.length;
        currentRange.location += currentComponent.range.length;
    }

    if (postcoreRange.length > 0) {
        CFIndex onePastCore     = coreRange.location     + coreRange.length;
        CFIndex onePastPostcore = postcoreRange.location + postcoreRange.length;
        if (onePastCore >= onePastPostcore) {
            postcoreRange = CFRangeMake(onePastCore, 0);
        }
        
        currentRange = CFRangeMake(postcoreRange.location + postcoreRange.length, 0);
    } else {
        postcoreRange = currentRange;
    }
    
    if (currentRange.location < length) {
        currentCharacter = __CFStringGetLongCharacterFromInlineBuffer(buffer, length, currentRange.location, &currentRange);
        while (__CFStringIsValidPostcoreCharacterForPictographicSequence(currentCharacter)) {
            postcoreRange.length  += currentRange.length;
            currentRange.location += currentRange.length;
            currentCharacter = __CFStringGetLongCharacterFromInlineBuffer(buffer, length, currentRange.location, &currentRange);
        }
    }
    
    bool const haveMatch = coreRange.length > 0;
    if (haveMatch && outRange) {
        *outRange = coreRange;
        if (precoreRange.length > 0) {
            outRange->location = precoreRange.location;
            outRange->length  += precoreRange.length;
        }
        
        if (postcoreRange.length > 0) {
            outRange->length += postcoreRange.length;
        }
    }
    
    return haveMatch;
}

#define RI_SURROGATE_HI (0xD83C)
static inline bool __CFStringIsRegionalIndicatorSurrogateLow(UTF16Char character) {
    return (character >= 0xDDE6) && (character <= 0xDDFF) ? true : false;
}

static inline bool __CFStringIsRegionalIndicatorAtIndex(CFStringInlineBuffer *buffer, CFIndex index) {
    return ((CFStringGetCharacterFromInlineBuffer(buffer, index) == RI_SURROGATE_HI) && __CFStringIsRegionalIndicatorSurrogateLow(CFStringGetCharacterFromInlineBuffer(buffer, index + 1))) ? true : false;
}

static inline bool __CFStringIsFitzpatrickModifiers(UTF32Char character) { return ((character >= 0x1F3FB) && (character <= 0x1F3FF) ? true : false); }
static inline bool __CFStringIsTagSequence(UTF32Char character) { return ((character >= 0xE0020) && (character <= 0xE007F) ? true : false); }

CF_INLINE uint8_t CFUniCharGetCombiningPropertyForCharacter(UTF16Char character, const uint8_t *bitmap) {
    if (bitmap) {
        uint8_t value = bitmap[(character >> 8)];

        if (value) {
            bitmap = bitmap + 256 + ((value - 1) * 256);
            return bitmap[character % 256];
        }
    }
    return 0;
}

CF_INLINE bool _CFStringIsVirama(UTF32Char character, const uint8_t *combClassBMP) {
    return ((character == COMBINING_GRAPHEME_JOINER) || (CFUniCharGetCombiningPropertyForCharacter(character, (const uint8_t *)((character < 0x10000) ? combClassBMP : CFUniCharGetUnicodePropertyDataForPlane(kCFUniCharCombiningProperty, (character >> 16)))) == 9) ? true : false);
}

CF_INLINE bool _CFStringIsHangulLVT(UTF32Char character) {
    return (((character - HANGUL_SYLLABLE_START) % HANGUL_JONGSEONG_COUNT) ? true : false);
}

static CFRange _CFStringInlineBufferGetComposedRange(CFStringInlineBuffer *buffer, CFIndex start, CFStringCharacterClusterType type, const uint8_t *bmpBitmap, CFIndex csetType){
    CFIndex end = start + 1;
    const uint8_t *bitmap = bmpBitmap;
    UTF32Char character;
    UTF16Char otherSurrogate;
    uint8_t step;

    character = CFStringGetCharacterFromInlineBuffer(buffer, start);

    if ((type != kCFStringBackwardDeletionCluster) || (character < 0x0530) || (character > 0x194F)) {
        if (CFUniCharIsSurrogateHighCharacter(character) && CFUniCharIsSurrogateLowCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(buffer, start + 1)))) {
            ++end;
            character = CFUniCharGetLongCharacterForSurrogatePair(character, otherSurrogate);
            bitmap = CFUniCharGetBitmapPtrForPlane(csetType, (character >> 16));
        }

        while (start > 0) {
            if ((type == kCFStringBackwardDeletionCluster) && (character >= 0x0530) && (character < 0x1950)) break;

            if (character < 0x10000) {
                if (CFUniCharIsSurrogateLowCharacter(character) && CFUniCharIsSurrogateHighCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(buffer, start - 1)))) {
                    character = CFUniCharGetLongCharacterForSurrogatePair(otherSurrogate, character);
                    bitmap = CFUniCharGetBitmapPtrForPlane(csetType, (character >> 16));
                    if (--start == 0) break;
                } else {
                    bitmap = bmpBitmap;
                }
            }

            Boolean isRelevantFitzpatrickModifier = (start > 0 && __CFStringIsFitzpatrickModifiers(character));
            Boolean isInBitmap = CFUniCharIsMemberOfBitmap(character, bitmap);
            Boolean isTagSequence = __CFStringIsTagSequence(character);
            Boolean behavesLikeCombiningMark = (character == 0xFF9E) || (character == 0xFF9F) || ((character & 0x1FFFF0) == 0xF870 /* variant tag */);
            if (!isRelevantFitzpatrickModifier && !isInBitmap && !isTagSequence && !behavesLikeCombiningMark) {
                break;
            }
    
            --start;
    
            character = CFStringGetCharacterFromInlineBuffer(buffer, start);
        }
    }

    if (((character >= HANGUL_CHOSEONG_START) && (character <= HANGUL_JONGSEONG_END)) || ((character >= HANGUL_SYLLABLE_START) && (character <= HANGUL_SYLLABLE_END))) {
        uint8_t state;
        uint8_t initialState;

        if (character < HANGUL_JUNGSEONG_START) {
            state = kCFStringHangulStateL;
        } else if (character < HANGUL_JONGSEONG_START) {
            state = kCFStringHangulStateV;
        } else if (character < HANGUL_SYLLABLE_START) {
            state = kCFStringHangulStateT;
        } else {
            state = (_CFStringIsHangulLVT(character) ? kCFStringHangulStateLVT : kCFStringHangulStateLV);
        }
        initialState = state;

        while (((character = CFStringGetCharacterFromInlineBuffer(buffer, start - 1)) >= HANGUL_CHOSEONG_START) && (character <= HANGUL_SYLLABLE_END) && ((character <= HANGUL_JONGSEONG_END) || (character >= HANGUL_SYLLABLE_START))) {
            switch (state) {
            case kCFStringHangulStateV:
                if (character <= HANGUL_CHOSEONG_END) {
                    state = kCFStringHangulStateL;
                } else if ((character >= HANGUL_SYLLABLE_START) && (character <= HANGUL_SYLLABLE_END) && !_CFStringIsHangulLVT(character)) {
                    state = kCFStringHangulStateLV;
                } else if (character > HANGUL_JUNGSEONG_END) {
                    state = kCFStringHangulStateBreak;
                }
                break;

            case kCFStringHangulStateT:
                if ((character >= HANGUL_JUNGSEONG_START) && (character <= HANGUL_JUNGSEONG_END)) {
                    state = kCFStringHangulStateV;
                } else if ((character >= HANGUL_SYLLABLE_START) && (character <= HANGUL_SYLLABLE_END)) {
                    state = (_CFStringIsHangulLVT(character) ? kCFStringHangulStateLVT : kCFStringHangulStateLV);
                } else if (character < HANGUL_JUNGSEONG_START) {
                    state = kCFStringHangulStateBreak;
                }
                break;

            default:
                state = ((character < HANGUL_JUNGSEONG_START) ? kCFStringHangulStateL : kCFStringHangulStateBreak);
                break;
            }

            if (state == kCFStringHangulStateBreak) break;
            --start;
        }

        state = initialState;
        while (((character = CFStringGetCharacterFromInlineBuffer(buffer, end)) > 0) && (((character >= HANGUL_CHOSEONG_START) && (character <= HANGUL_JONGSEONG_END)) || ((character >= HANGUL_SYLLABLE_START) && (character <= HANGUL_SYLLABLE_END)))) {
            switch (state) {
            case kCFStringHangulStateLV:
            case kCFStringHangulStateV:
                if ((character >= HANGUL_JUNGSEONG_START) && (character <= HANGUL_JONGSEONG_END)) {
                    state = ((character < HANGUL_JONGSEONG_START) ? kCFStringHangulStateV : kCFStringHangulStateT);
                } else {
                    state = kCFStringHangulStateBreak;
                }
                break;

            case kCFStringHangulStateLVT:
            case kCFStringHangulStateT:
                state = (((character >= HANGUL_JONGSEONG_START) && (character <= HANGUL_JONGSEONG_END)) ? kCFStringHangulStateT : kCFStringHangulStateBreak);
                break;

            default:
                if (character < HANGUL_JUNGSEONG_START) {
                    state = kCFStringHangulStateL;
                } else if (character < HANGUL_JONGSEONG_START) {
                    state = kCFStringHangulStateV;
                } else if (character >= HANGUL_SYLLABLE_START) {
                    state = (_CFStringIsHangulLVT(character) ? kCFStringHangulStateLVT : kCFStringHangulStateLV);
                } else {
                    state = kCFStringHangulStateBreak;
                }
                break;
            }

            if (state == kCFStringHangulStateBreak) break;
            ++end;
        }
    }

    while ((character = CFStringGetCharacterFromInlineBuffer(buffer, end)) > 0) {
        if ((type == kCFStringBackwardDeletionCluster) && (character >= 0x0530) && (character < 0x1950)) break;
    
        if (CFUniCharIsSurrogateHighCharacter(character) && CFUniCharIsSurrogateLowCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(buffer, end + 1)))) {
            character = CFUniCharGetLongCharacterForSurrogatePair(character, otherSurrogate);
            bitmap = CFUniCharGetBitmapPtrForPlane(csetType, (character >> 16));
            step = 2;
        } else {
            bitmap = bmpBitmap;
            step = 1;
        }

        Boolean isRelevantFitzpatrickModifier = __CFStringIsFitzpatrickModifiers(character);
        Boolean isInBitmap = CFUniCharIsMemberOfBitmap(character, bitmap);
        Boolean isTagSequence = __CFStringIsTagSequence(character);
        Boolean behavesLikeCombiningMark = (character == 0xFF9E) || (character == 0xFF9F) || ((character & 0x1FFFF0) == 0xF870 /* variant tag */);
        if (!isRelevantFitzpatrickModifier && !isInBitmap && !isTagSequence && !behavesLikeCombiningMark) {
            break;
        }

        end += step;
    }

    return CFRangeMake(start, end - start);
}

extern "C" CFRange CFStringGetRangeOfCharacterClusterAtIndex(CFStringRef, CFIndex, CFStringCharacterClusterType);
%hookf(CFRange, CFStringGetRangeOfCharacterClusterAtIndex, CFStringRef string, CFIndex charIndex, CFStringCharacterClusterType type) {
    CFRange range;
    CFIndex currentIndex;
    CFIndex length = CFStringGetLength(string);
    CFIndex csetType = ((kCFStringGraphemeCluster == type) ? kCFUniCharGraphemeExtendCharacterSet : kCFUniCharNonBaseCharacterSet);
    CFStringInlineBuffer stringBuffer;
    const uint8_t *bmpBitmap;
    const uint8_t *letterBMP;
    static const uint8_t *combClassBMP = NULL;
    UTF32Char character;
    UTF16Char otherSurrogate;

    if (charIndex >= length) return CFRangeMake(kCFNotFound, 0);

    if (!CF_IS_OBJC(_kCFRuntimeIDCFString, string) && !CF_IS_SWIFT(_kCFRuntimeIDCFString, string) && __CFStrIsEightBit(string)) return CFRangeMake(charIndex, 1);

    bmpBitmap = CFUniCharGetBitmapPtrForPlane(csetType, 0);
    letterBMP = CFUniCharGetBitmapPtrForPlane(kCFUniCharLetterCharacterSet, 0);
    if (NULL == combClassBMP) combClassBMP = (const uint8_t *)CFUniCharGetUnicodePropertyDataForPlane(kCFUniCharCombiningProperty, 0);

    CFStringInitInlineBuffer(string, &stringBuffer, CFRangeMake(0, length));

    range = _CFStringInlineBufferGetComposedRange(&stringBuffer, charIndex, type, bmpBitmap, csetType);

    if (type < kCFStringCursorMovementCluster) {
        const uint8_t *letter = letterBMP;

        character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, range.location);

        if ((range.length > 1) && CFUniCharIsSurrogateHighCharacter(character) && CFUniCharIsSurrogateLowCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(&stringBuffer, range.location + 1)))) {
            character = CFUniCharGetLongCharacterForSurrogatePair(character, otherSurrogate);
            letter = CFUniCharGetBitmapPtrForPlane(kCFUniCharLetterCharacterSet, (character >> 16));
        }

        if ((character == ZERO_WIDTH_JOINER) || CFUniCharIsMemberOfBitmap(character, letter)) {
            CFRange otherRange;

            otherRange.location = currentIndex = range.location;

            while (currentIndex > 1) {
                character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, --currentIndex);
    
                if ((_CFStringIsVirama(character, combClassBMP) || ((character == ZERO_WIDTH_JOINER) && _CFStringIsVirama(CFStringGetCharacterFromInlineBuffer(&stringBuffer, --currentIndex), combClassBMP))) && (currentIndex > 0)) {
                    --currentIndex;                
                } else {
                    break;
                }

                currentIndex = _CFStringInlineBufferGetComposedRange(&stringBuffer, currentIndex, type, bmpBitmap, csetType).location;
    
                character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex);
    
                if (CFUniCharIsSurrogateLowCharacter(character) && CFUniCharIsSurrogateHighCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex - 1)))) {
                    character = CFUniCharGetLongCharacterForSurrogatePair(character, otherSurrogate);
                    letter = CFUniCharGetBitmapPtrForPlane(kCFUniCharLetterCharacterSet, (character >> 16));
                    --currentIndex;
                } else {
                    letter = letterBMP;
                }

                if (!CFUniCharIsMemberOfBitmap(character, letter)) break;
                range.location = currentIndex;
            }

            range.length += otherRange.location - range.location;

            if ((range.length > 1) && ((range.location + range.length) < length)) {
                otherRange = range;
                currentIndex = otherRange.location + otherRange.length;

                do {
                    character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex - 1);

                    if ((character != ZERO_WIDTH_JOINER) && !_CFStringIsVirama(character, combClassBMP)) break;

                    character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex);

                    if (character == ZERO_WIDTH_JOINER) character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, ++currentIndex);

                    if (CFUniCharIsSurrogateHighCharacter(character) && CFUniCharIsSurrogateLowCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex + 1)))) {
                        character = CFUniCharGetLongCharacterForSurrogatePair(character, otherSurrogate);
                        letter = CFUniCharGetBitmapPtrForPlane(kCFUniCharLetterCharacterSet, (character >> 16));
                    } else {
                        letter = letterBMP;
                    }
        
                    if (!CFUniCharIsMemberOfBitmap(character, letter)) break;
                    otherRange = _CFStringInlineBufferGetComposedRange(&stringBuffer, currentIndex, type, bmpBitmap, csetType);
                    currentIndex = otherRange.location + otherRange.length;
                } while ((otherRange.location + otherRange.length) < length);
                range.length = currentIndex - range.location;
            }
        }
    }

    CFIndex otherIndex;
    
    currentIndex = (range.location + range.length) - (MAX_TRANSCODING_LENGTH + 1);
    if (currentIndex < 0) currentIndex = 0;
    
    while (currentIndex <= range.location) {
        character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex);
        
        if ((character & 0x1FFFF0) == 0xF860) {
            otherIndex = currentIndex + __CFTranscodingHintLength[(character - 0xF860)] + 1;
            if (otherIndex >= (range.location + range.length)) {
                if (otherIndex <= length) {
                    range.location = currentIndex;
                    range.length = otherIndex - currentIndex;
                }
                break;
            }
        }
        ++currentIndex;
    }

    if ((range.length == 2) && __CFStringIsRegionalIndicatorAtIndex(&stringBuffer, range.location)) {
        currentIndex = range.location;
        
        while ((currentIndex > 1) && __CFStringIsRegionalIndicatorAtIndex(&stringBuffer, currentIndex - 2)) currentIndex -= 2;
        
        if ((range.location > currentIndex) && (0 != ((range.location - currentIndex) % 4))) {
            range.location -= 2;
            range.length += 2;
        }

        if ((range.length == 2) && ((range.location + range.length + 2) <= length) && __CFStringIsRegionalIndicatorAtIndex(&stringBuffer, range.location + range.length)) {
            range.length += 2;
        }
    }

    CFRange cluster;

    if (__CFStringGetExtendedPictographicSequence(&stringBuffer, length, range.location, &cluster)) {
        CFIndex const rangeEnd = range.location + range.length;
        CFIndex const clusterEnd = cluster.location + cluster.length;
        
        Boolean const clusterContainsRange = (range.location >= cluster.location && rangeEnd <= clusterEnd);

        if (clusterContainsRange) {
            range = cluster;
        }
    }
    
    CFRange finalCluster;
    
    if ((range.location > 0) && (range.length == 1) && (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, range.location))) {
        finalCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, range.location - 1, type, bmpBitmap, csetType);
        if (range.location == (finalCluster.location + finalCluster.length)) {
            range = finalCluster;
            ++range.length;
        }
    }
    if ((range.location + range.length) < length) {
        if (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, range.location + range.length)) {
            ++range.length;
        }
    }

    return range;
}

#define __kCFCharacterSetDir "/System/Library/CoreServices"

const char *(*__CFgetenv)(const char *n);

CF_INLINE const char *CFPathRelativeToAppleFrameworksRoot(const char *path, Boolean *allocated) {
    if (path) {
        const char *platformRoot = __CFgetenv("APPLE_FRAMEWORKS_ROOT");
        if (platformRoot) {
            char *newPath = NULL;
            asprintf(&newPath, "%s%s", platformRoot, path);
            if (allocated && newPath) {
                *allocated = true;
            }
            return newPath;
        }
    }
    if (allocated) {
        *allocated = false;
    }
    return path;
}

CF_INLINE void __CFUniCharCharacterSetPath(char *cpath) {
    strlcpy(cpath, __kCFCharacterSetDir, MAXPATHLEN);
}

static bool __CFUniCharLoadBytesFromFile(const char *fileName, const void **bytes, int64_t *fileSize) {
    struct stat statBuf;
    int fd = -1;

    if ((fd = open(fileName, O_RDONLY, 0)) < 0) {
	    return false;
    }
    if (fstat(fd, &statBuf) < 0 || (*bytes = mmap(0, statBuf.st_size, PROT_READ, MAP_PRIVATE, fd, 0)) == (void *)-1) {
        close(fd);
        return false;
    }
    close(fd);

    if (NULL != fileSize) *fileSize = statBuf.st_size;

    return true;
}

%group UniCharHack

bool (*__CFUniCharLoadFile)(const char *, const void **, int64_t *);
%hookf(bool, __CFUniCharLoadFile, const char *bitmapName, const void **bytes, int64_t *fileSize) {
    bool bitmap = strcmp(bitmapName, "__csbitmaps") == 0;
    bool data = strcmp(bitmapName, "__data") == 0;
    bool properties = strcmp(bitmapName, "__properties") == 0;
    if (bitmap || data || properties) {
        if (bitmap) bitmapName = "/CFCharacterSetBitmaps.bitmap";
        if (data) bitmapName = "/CFUnicodeData-L.mapping";
        if (properties) bitmapName = "/CFUniCharPropertyDatabase.data";
        char cpath[MAXPATHLEN];
        __CFUniCharCharacterSetPath(cpath);
        strlcat(cpath, bitmapName, MAXPATHLEN);
        Boolean needToFree = false;
        const char *possiblyFrameworkRootedCPath = CFPathRelativeToAppleFrameworksRoot(cpath, &needToFree);
        bool result = __CFUniCharLoadBytesFromFile(possiblyFrameworkRootedCPath, bytes, fileSize);
        if (needToFree) free((void *)possiblyFrameworkRootedCPath);
        return result;
    }
    return %orig(bitmapName, bytes, fileSize);
}

%end

%ctor {
    if (IS_IOS_OR_NEWER(iOS_13_2))
        return;
    MSImageRef cf = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"));
    __CFUniCharLoadFile = (bool (*)(const char *, const void **, int64_t *))_PSFindSymbolCallable(cf, "___CFUniCharLoadFile");
    __CFgetenv = (const char *(*)(const char *))_PSFindSymbolCallable(cf, "___CFgetenv");
    if (__CFUniCharLoadFile) {
        %init(UniCharHack);
    }
    %init;
}
