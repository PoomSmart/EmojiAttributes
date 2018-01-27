#import "../PS.h"
#import <CoreFoundation/CoreFoundation.h>
#import "CoreFoundationHack.h"
#import <substrate.h>

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

        // Extend backward
        while (start > 0) {
            if ((type == kCFStringBackwardDeletionCluster) && (character >= 0x0530) && (character < 0x1950))
                break;

            if (character < 0x10000) { // the first round could be already be non-BMP
                if (CFUniCharIsSurrogateLowCharacter(character) && CFUniCharIsSurrogateHighCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(buffer, start - 1)))) {
                    character = CFUniCharGetLongCharacterForSurrogatePair(otherSurrogate, character);
                    bitmap = CFUniCharGetBitmapPtrForPlane(csetType, (character >> 16));
                    if (--start == 0)
                        break; // starting with non-BMP combining mark
                } else {
                    bitmap = bmpBitmap;
                }
            }

            if (__CFStringIsFitzpatrickModifiers(character) && (start > 0)) {
                UTF32Char baseCharacter = CFStringGetCharacterFromInlineBuffer(buffer, start - 1);

                if (CFUniCharIsSurrogateLowCharacter(baseCharacter) && ((start - 1) > 0)) {
                    UTF16Char otherCharacter = CFStringGetCharacterFromInlineBuffer(buffer, start - 2);

                    if (CFUniCharIsSurrogateHighCharacter(otherCharacter))
                        baseCharacter = CFUniCharGetLongCharacterForSurrogatePair(otherCharacter, baseCharacter);
                }

                if (!__CFStringIsBaseForFitzpatrickModifiers(baseCharacter))
                    break;
            } else {
                if (!CFUniCharIsMemberOfBitmap(character, bitmap) && (character != 0xFF9E) && (character != 0xFF9F) && ((character & 0x1FFFF0) != 0xF870))
                    break;
            }

            --start;

            character = CFStringGetCharacterFromInlineBuffer(buffer, start);
        }
    }

    // Hangul
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

        // Extend backward
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

            if (state == kCFStringHangulStateBreak)
                break;
            --start;
        }

        // Extend forward
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

            if (state == kCFStringHangulStateBreak)
                break;
            ++end;
        }
    }

    bool prevIsFitzpatrickBase = __CFStringIsBaseForFitzpatrickModifiers(character);

    // Extend forward
    while ((character = CFStringGetCharacterFromInlineBuffer(buffer, end)) > 0) {
        if ((type == kCFStringBackwardDeletionCluster) && (character >= 0x0530) && (character < 0x1950))
            break;

        if (CFUniCharIsSurrogateHighCharacter(character) && CFUniCharIsSurrogateLowCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(buffer, end + 1)))) {
            character = CFUniCharGetLongCharacterForSurrogatePair(character, otherSurrogate);
            bitmap = CFUniCharGetBitmapPtrForPlane(csetType, (character >> 16));
            step = 2;
        } else {
            bitmap = bmpBitmap;
            step = 1;
        }

        if ((!prevIsFitzpatrickBase || !__CFStringIsFitzpatrickModifiers(character)) && !CFUniCharIsMemberOfBitmap(character, bitmap) && (character != 0xFF9E) && (character != 0xFF9F) && ((character & 0x1FFFF0) != 0xF870))
            break;

        prevIsFitzpatrickBase = __CFStringIsBaseForFitzpatrickModifiers(character);

        end += step;
    }

    return CFRangeMake(start, end - start);
}

%group preiOS10_2

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

    /* Fast case.  If we're eight-bit, it's either the default encoding is cheap or the content is all ASCII.  Watch out when (or if) adding more 8bit Mac-scripts in CFStringEncodingConverters
    */
    if (!CF_IS_OBJC(__kCFStringTypeID, string) && !CF_IS_SWIFT(__kCFStringTypeID, string) && __CFStrIsEightBit(string)) return CFRangeMake(charIndex, 1);

    bmpBitmap = CFUniCharGetBitmapPtrForPlane(csetType, 0);
    letterBMP = CFUniCharGetBitmapPtrForPlane(kCFUniCharLetterCharacterSet, 0);
    if (NULL == combClassBMP) combClassBMP = (const uint8_t *)CFUniCharGetUnicodePropertyDataForPlane(kCFUniCharCombiningProperty, 0);

    CFStringInitInlineBuffer(string, &stringBuffer, CFRangeMake(0, length));

    // Get composed character sequence first
    range = _CFStringInlineBufferGetComposedRange(&stringBuffer, charIndex, type, bmpBitmap, csetType);

    // Do grapheme joiners
    if (type < kCFStringCursorMovementCluster) {
        const uint8_t *letter = letterBMP;

        // Check to see if we have a letter at the beginning of initial cluster
        character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, range.location);

        if ((range.length > 1) && CFUniCharIsSurrogateHighCharacter(character) && CFUniCharIsSurrogateLowCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(&stringBuffer, range.location + 1)))) {
            character = CFUniCharGetLongCharacterForSurrogatePair(character, otherSurrogate);
            letter = CFUniCharGetBitmapPtrForPlane(kCFUniCharLetterCharacterSet, (character >> 16));
        }

        if ((character == ZERO_WIDTH_JOINER) || CFUniCharIsMemberOfBitmap(character, letter)) {
            CFRange otherRange;

            // Check if preceded by grapheme joiners (U034F and viramas)
            otherRange.location = currentIndex = range.location;

            while (currentIndex > 1) {
                character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, --currentIndex);
    
                // ??? We're assuming viramas only in BMP
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

            // Check if followed by grapheme joiners
            if ((range.length > 1) && ((range.location + range.length) < length)) {
                otherRange = range;
                currentIndex = otherRange.location + otherRange.length;

                do {
                    character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex - 1);

                    // ??? We're assuming viramas only in BMP
                    if ((character != ZERO_WIDTH_JOINER) && !_CFStringIsVirama(character, combClassBMP)) break;

                    character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex);

                    if (character == ZERO_WIDTH_JOINER) character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, ++currentIndex);

                    if (CFUniCharIsSurrogateHighCharacter(character) && CFUniCharIsSurrogateLowCharacter((otherSurrogate = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex + 1)))) {
                        character = CFUniCharGetLongCharacterForSurrogatePair(character, otherSurrogate);
                        letter = CFUniCharGetBitmapPtrForPlane(kCFUniCharLetterCharacterSet, (character >> 16));
                    } else {
                        letter = letterBMP;
                    }
        
                    // We only conjoin letters
                    if (!CFUniCharIsMemberOfBitmap(character, letter)) break;
                    otherRange = _CFStringInlineBufferGetComposedRange(&stringBuffer, currentIndex, type, bmpBitmap, csetType);
                    currentIndex = otherRange.location + otherRange.length;
                } while ((otherRange.location + otherRange.length) < length);
                range.length = currentIndex - range.location;
            }
        }
    }

    // Check if we're part of prefix transcoding hints
    CFIndex otherIndex;
    
    currentIndex = (range.location + range.length) - (MAX_TRANSCODING_LENGTH + 1);
    if (currentIndex < 0) currentIndex = 0;
    
    while (currentIndex <= range.location) {
        character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex);
        
        if ((character & 0x1FFFF0) == 0xF860) { // transcoding hint
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

    // Regional flag
    if ((range.length == 2) && __CFStringIsRegionalIndicatorAtIndex(&stringBuffer, range.location)) { // RI

        // Extend backward
        currentIndex = range.location;
        
        while ((currentIndex > 1) && __CFStringIsRegionalIndicatorAtIndex(&stringBuffer, currentIndex - 2)) currentIndex -= 2;
        
        if ((range.location > currentIndex) && (0 != ((range.location - currentIndex) % 4))) { // currentIndex is the 2nd RI
            range.location -= 2;
            range.length += 2;
        }

        if ((range.length == 2) && ((range.location + range.length + 2) <= length) && __CFStringIsRegionalIndicatorAtIndex(&stringBuffer, range.location + range.length)) {
            range.length += 2;
        }
    }

    // Rainbow flag sequence & Gender modifier sequence
    CFRange aCluster;

    if (__CFStringIsWavingWhiteFlagCluster(&stringBuffer, range)) {
        CFIndex end = range.location + range.length - 1;
        if ((end + 1) < length) {
            UTF32Char endCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, end);
            if (endCharacter != ZERO_WIDTH_JOINER) {
                end++;
                endCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, end);
            }
            if (endCharacter == ZERO_WIDTH_JOINER)  {
                aCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, end + 1, type, bmpBitmap, csetType);
                if (__CFStringIsRainbowCluster(&stringBuffer, aCluster)) {
                    currentIndex = aCluster.location + aCluster.length;
                    if ((aCluster.length > 1) && (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex - 1))) --currentIndex;
                }
                if (currentIndex > (range.location + range.length)) range.length = currentIndex - range.location;
            }
        }
    } else if (__CFStringIsRainbowCluster(&stringBuffer, range)) {
        if (range.location > 1) {
            CFIndex prev = range.location - 1;
            UTF32Char prevCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, prev);
            if (prevCharacter == ZERO_WIDTH_JOINER) {
                aCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, prev - 1, type, bmpBitmap, csetType);
                if (__CFStringIsWavingWhiteFlagCluster(&stringBuffer, aCluster)) {
                    currentIndex = aCluster.location;
                }
                if (currentIndex < range.location) {
                    range.length += range.location - currentIndex;
                    range.location = currentIndex;
                }
            }
        }
    } else if (__CFStringIsGenderModifierBaseCluster(&stringBuffer, range)) {
        CFIndex end = range.location + range.length - 1;
        if ((end + 1) < length) {
            UTF32Char endCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, end);
            if (endCharacter != ZERO_WIDTH_JOINER) {
                end++;
                endCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, end);
            }
            if (endCharacter == ZERO_WIDTH_JOINER)  {
                aCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, end + 1, type, bmpBitmap, csetType);
                if (__CFStringIsGenderModifierCluster(&stringBuffer, aCluster)) {
                    currentIndex = aCluster.location + aCluster.length;
                    if ((aCluster.length > 1) && (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex - 1))) --currentIndex;
                }
                if (currentIndex > (range.location + range.length)) range.length = currentIndex - range.location;
            }
        }
    } else if (__CFStringIsGenderModifierCluster(&stringBuffer, range)) {
        if (range.location > 1) {
            CFIndex prev = range.location - 1;
            UTF32Char prevCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, prev);
            if (prevCharacter == ZERO_WIDTH_JOINER) {
                aCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, prev - 1, type, bmpBitmap, csetType);
                if (__CFStringIsGenderModifierBaseCluster(&stringBuffer, aCluster)) {
                    currentIndex = aCluster.location;
                }
                if (currentIndex < range.location) {
                    range.length += range.location - currentIndex;
                    range.location = currentIndex;
                }
            }
        }
    } else if (__CFStringIsProfessionBaseCluster(&stringBuffer, range)) {
        CFIndex end = range.location + range.length - 1;
        if ((end + 1) < length) {
            UTF32Char endCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, end);
            if (endCharacter != ZERO_WIDTH_JOINER) {
                end++;
                endCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, end);
            }
            if (endCharacter == ZERO_WIDTH_JOINER)  {
                aCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, end + 1, type, bmpBitmap, csetType);
                if (__CFStringIsProfessionModifierCluster(&stringBuffer, aCluster)) {
                    currentIndex = aCluster.location + aCluster.length;
                    if ((aCluster.length > 1) && (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex - 1))) --currentIndex;
                }
                if (currentIndex > (range.location + range.length)) range.length = currentIndex - range.location;
            }
        }
    } else if (__CFStringIsProfessionModifierCluster(&stringBuffer, range)) {
        if (range.location > 1) {
            CFIndex prev = range.location - 1;
            UTF32Char prevCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, prev);
            if (prevCharacter == ZERO_WIDTH_JOINER) {
                aCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, prev - 1, type, bmpBitmap, csetType);
                if (__CFStringIsProfessionBaseCluster(&stringBuffer, aCluster)) {
                    currentIndex = aCluster.location;
                }
                if (currentIndex < range.location) {
                    range.length += range.location - currentIndex;
                    range.location = currentIndex;
                }
            }
        }
    } else {
        // range is zwj
        CFIndex end = range.location + range.length - 1;
        UTF32Char endCharacter = CFStringGetCharacterFromInlineBuffer(&stringBuffer, end);
        if (((end + 1) < length) && ((endCharacter == ZERO_WIDTH_JOINER) || (endCharacter == WHITE_SPACE_CHARACTER))) {
            // Get cluster before and after zwj.  Range length of zwj cluster is always 1.
            CFRange rangeBeforeZWJ = _CFStringInlineBufferGetComposedRange(&stringBuffer, end - 1, type, bmpBitmap, csetType);
            aCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, end + 1, type, bmpBitmap, csetType);

            if (((__CFStringIsWavingWhiteFlagCluster(&stringBuffer, rangeBeforeZWJ)) && (__CFStringIsRainbowCluster(&stringBuffer, aCluster)))
                || ((__CFStringIsGenderModifierBaseCluster(&stringBuffer, rangeBeforeZWJ)) && (__CFStringIsGenderModifierCluster(&stringBuffer, aCluster)))
                || ((__CFStringIsProfessionBaseCluster(&stringBuffer, rangeBeforeZWJ)) && (__CFStringIsProfessionModifierCluster(&stringBuffer, aCluster)))) {
                range.location = rangeBeforeZWJ.location;
                range.length += rangeBeforeZWJ.length + aCluster.length;
            }
        }
    }

    // Family face sequence
    if (range.location > 1) { // there are more than 2 chars
        character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, range.location);

        if (__CFStringIsFamilySequenceCluster(&stringBuffer, range) || (character == ZERO_WIDTH_JOINER)) { // extend backward
            currentIndex = (character == ZERO_WIDTH_JOINER) ? range.location + 1 : range.location;

            while ((currentIndex > 1) && (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex - 1))) {
                aCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, currentIndex - 2, type, bmpBitmap, csetType);

                if (aCluster.location < range.location) {
                    if (__CFStringIsFamilySequenceCluster(&stringBuffer, aCluster)) {
                        currentIndex = aCluster.location;
                    } else {
                        break;
                    }
                }
            }

            if (currentIndex < range.location) {
                range.length += range.location - currentIndex;
                range.location = currentIndex;
            }
        }
    }

    // Extend forward
    if (range.location + range.length < length) {
        currentIndex = range.location + range.length - 1;
        character = CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex);

        if ((ZERO_WIDTH_JOINER == character) || __CFStringIsFamilySequenceCluster(&stringBuffer, _CFStringInlineBufferGetComposedRange(&stringBuffer, currentIndex, type, bmpBitmap, csetType))) {

            if (ZERO_WIDTH_JOINER != character) ++currentIndex; // move to the end of cluster

            while (((currentIndex + 1) < length) && (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex))) {
                aCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, currentIndex + 1, type, bmpBitmap, csetType);
                if ((__CFStringIsFamilySequenceCluster(&stringBuffer, aCluster))) {
                    currentIndex = aCluster.location + aCluster.length;
                    if ((aCluster.length > 1) && (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, currentIndex - 1))) --currentIndex;
                } else {
                    break;
                }
            }
            if (currentIndex > (range.location + range.length)) range.length = currentIndex - range.location;
        }
    }

    // Gather the final grapheme extends
    CFRange finalCluster;
    
    // Backwards
    if ((range.location > 0) && (range.length == 1) && (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, range.location))) {
        finalCluster = _CFStringInlineBufferGetComposedRange(&stringBuffer, range.location - 1, type, bmpBitmap, csetType);
        if (range.location == (finalCluster.location + finalCluster.length)) {
            range = finalCluster;
            ++range.length;
        }
    }
    // Forwards
    if ((range.location + range.length) < length) {
        if (ZERO_WIDTH_JOINER == CFStringGetCharacterFromInlineBuffer(&stringBuffer, range.location + range.length)) {
            ++range.length;
        }
    }

    return range;
}

%end

bool (*CFStringIsGenderModifierBaseCluster)(CFStringInlineBuffer *, CFRange);
bool (*CFStringIsBaseForFitzpatrickModifiers)(UTF32Char);

%group iOS10_2

%hookf(bool, CFStringIsGenderModifierBaseCluster, CFStringInlineBuffer *buffer, CFRange range) {
    return __CFStringIsGenderModifierBaseCluster(buffer, range);
}

%hookf(bool, CFStringIsBaseForFitzpatrickModifiers, UTF32Char character) {
    return __CFStringIsBaseForFitzpatrickModifiers(character);
}

%end

%ctor {
    if (isiOS10_2Up) {
        MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"));
        CFStringIsGenderModifierBaseCluster = (bool (*)(CFStringInlineBuffer *, CFRange))MSFindSymbol(ref, "___CFStringIsGenderModifierBaseCluster");
        HBLogDebug(@"Found CFStringIsGenderModifierBaseCluster: %d", CFStringIsGenderModifierBaseCluster != NULL);
        CFStringIsBaseForFitzpatrickModifiers = (bool (*)(UTF32Char))MSFindSymbol(ref, "___CFStringIsBaseForFitzpatrickModifiers");
        HBLogDebug(@"Found CFStringIsBaseForFitzpatrickModifiers: %d", CFStringIsBaseForFitzpatrickModifiers != NULL);
        %init(iOS10_2);
    } else {
        %init(preiOS10_2);
    }
}
