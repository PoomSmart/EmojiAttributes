#import "../PS.h"
#import "Assert.h"
#import "WebCoreSupport/CharactersProperties.h"
#import "WebCoreSupport/Font.h"
#import "WebCoreSupport/RenderText.h"
#import "WebCoreSupport/CoreGraphicsSPI.h"
#include <unicode/utf16.h>
#import <CoreText/CoreText.h>

using namespace WebCore;
using namespace WTF;

bool (*isCJKIdeograph)(UChar32);
%hookf(bool, isCJKIdeograph, UChar32 c) {
    if (c >= 0x4E00 && c <= 0x9FFF)
        return true;
    if (c >= 0x3400 && c <= 0x4DBF)
        return true;
    if (c >= 0x2E80 && c <= 0x2EFF)
        return true;
    if (c >= 0x2F00 && c <= 0x2FDF)
        return true;
    if (c >= 0x31C0 && c <= 0x31EF)
        return true;
    if (c >= 0xF900 && c <= 0xFAFF)
        return true;
    if (c >= 0x20000 && c <= 0x2A6DF)
        return true;
    if (c >= 0x2A700 && c <= 0x2B73F)
        return true;
    if (c >= 0x2B740 && c <= 0x2B81F)
        return true;
    if (c >= 0x2F800 && c <= 0x2FA1F)
        return true;
    return false;
}

bool (*isCJKIdeographOrSymbol)(UChar32);
%hookf(bool, isCJKIdeographOrSymbol, UChar32 c) {
    if ((c == 0x2C7) || (c == 0x2CA) || (c == 0x2CB) || (c == 0x2D9))
        return true;
    if ((c == 0x2020) || (c == 0x2021) || (c == 0x2030) || (c == 0x203B) || (c == 0x203C)
        || (c == 0x2042) || (c == 0x2047) || (c == 0x2048) || (c == 0x2049) || (c == 0x2051)
        || (c == 0x20DD) || (c == 0x20DE) || (c == 0x2100) || (c == 0x2103) || (c == 0x2105)
        || (c == 0x2109) || (c == 0x210A) || (c == 0x2113) || (c == 0x2116) || (c == 0x2121)
        || (c == 0x212B) || (c == 0x213B) || (c == 0x2150) || (c == 0x2151) || (c == 0x2152))
        return true;
    if (c >= 0x2156 && c <= 0x215A)
        return true;
    if (c >= 0x2160 && c <= 0x216B)
        return true;
    if (c >= 0x2170 && c <= 0x217B)
        return true;
    if ((c == 0x217F) || (c == 0x2189) || (c == 0x2307) || (c == 0x2312) || (c == 0x23BE) || (c == 0x23BF))
        return true;
    if (c >= 0x23C0 && c <= 0x23CC)
        return true;
    if ((c == 0x23CE) || (c == 0x2423))
        return true;
    if (c >= 0x2460 && c <= 0x2492)
        return true;
    if (c >= 0x249C && c <= 0x24FF)
        return true;
    if ((c == 0x25A0) || (c == 0x25A1) || (c == 0x25A2) || (c == 0x25AA) || (c == 0x25AB))
        return true;
    if ((c == 0x25B1) || (c == 0x25B2) || (c == 0x25B3) || (c == 0x25B6) || (c == 0x25B7) || (c == 0x25BC) || (c == 0x25BD))
        return true;
    if ((c == 0x25C0) || (c == 0x25C1) || (c == 0x25C6) || (c == 0x25C7) || (c == 0x25C9) || (c == 0x25CB) || (c == 0x25CC))
        return true;
    if (c >= 0x25CE && c <= 0x25D3)
        return true;
    if (c >= 0x25E2 && c <= 0x25E6)
        return true;
    if (c == 0x25EF)
        return true;
    if (c >= 0x2600 && c <= 0x2603)
        return true;
    if ((c == 0x2605) || (c == 0x2606) || (c == 0x260E) || (c == 0x2616) || (c == 0x2617) || (c == 0x2640) || (c == 0x2642))
        return true;
    if (c >= 0x2660 && c <= 0x266F)
        return true;
    if (c >= 0x2672 && c <= 0x267D)
        return true;
    if ((c == 0x26A0) || (c == 0x26BD) || (c == 0x26BE) || (c == 0x2713) || (c == 0x271A) || (c == 0x273F) || (c == 0x2740) || (c == 0x2756))
        return true;
    if (c >= 0x2776 && c <= 0x277F)
        return true;
    if (c == 0x2B1A)
        return true;
    if (c >= 0x2FF0 && c <= 0x2FFF)
        return true;
    if (c >= 0x3000 && c < 0x3030)
        return true;
    if (c > 0x3030 && c <= 0x303F)
        return true;
    if (c >= 0x3040 && c <= 0x309F)
        return true;
    if (c >= 0x30A0 && c <= 0x30FF)
        return true;
    if (c >= 0x3100 && c <= 0x312F)
        return true;
    if (c >= 0x3190 && c <= 0x319F)
        return true;
    if (c >= 0x31A0 && c <= 0x31BF)
        return true;
    if (c >= 0x3200 && c <= 0x32FF)
        return true;
    if (c >= 0x3300 && c <= 0x33FF)
        return true;
    if (c >= 0xF860 && c <= 0xF862)
        return true;
    if (c >= 0xFE30 && c <= 0xFE4F)
        return true;
    if ((c == 0xFE10) || (c == 0xFE11) || (c == 0xFE12) || (c == 0xFE19))
        return true;
    if ((c == 0xFF0D) || (c == 0xFF1B) || (c == 0xFF1C) || (c == 0xFF1E))
        return false;
    if (c >= 0xFF00 && c <= 0xFFEF)
        return true;
    if (c == 0x1F100)
        return true;
    if (c >= 0x1F110 && c <= 0x1F129)
        return true;
    if (c >= 0x1F130 && c <= 0x1F149)
        return true;
    if (c >= 0x1F150 && c <= 0x1F169)
        return true;
    if (c >= 0x1F170 && c <= 0x1F189)
        return true;
    if (c >= 0x1F200 && c <= 0x1F6C5)
        return true;
    return isCJKIdeograph(c);
}

String (*RenderText_originalText)(void *);
int (*RenderText_previousOffsetForBackwardDeletion)(void *, int);
%hookf(int, RenderText_previousOffsetForBackwardDeletion, void *arg0, int current) {
    String m_text = RenderText_originalText(arg0);
    ASSERT(!m_text.isNull());
    StringImpl& text = *m_text.impl();
    bool sawRegionalIndicator = false;
    bool sawEmojiGroupCandidate = false;
    bool sawEmojiFitzpatrickModifier = false;
    while (current > 0) {
        UChar32 character;
        U16_PREV(text, 0, current, character);
        if (sawEmojiGroupCandidate) {
            sawEmojiGroupCandidate = false;
            if (character == zeroWidthJoiner)
                continue;
            U16_FWD_1_UNSAFE(text, current);
            break;
        }
        if (sawEmojiFitzpatrickModifier) {
            if (isEmojiFitzpatrickModifier(character)) {
                U16_FWD_1_UNSAFE(text, current);
                break;
            }
            if (!isVariationSelector(character))
                break;
        }
        if (sawRegionalIndicator) {
            if (isRegionalIndicator(character))
                break;
            U16_FWD_1_UNSAFE(text, current);
        }
        if (isInArmenianToLimbuRange(character))
            break;
        if (isRegionalIndicator(character)) {
            sawRegionalIndicator = true;
            continue;
        }
        if (isEmojiFitzpatrickModifier(character)) {
            sawEmojiFitzpatrickModifier = true;
            continue;
        }
        if (isEmojiGroupCandidate(character)) {
            sawEmojiGroupCandidate = true;
            continue;
        }
        if (!isMark(character) && character != 0xFF9E && character != 0xFF9F)
            break;
    }
    if (current <= 0)
        return current;
    UChar character = text[current];
    if ((character >= hangulChoseongStart && character <= hangulJongseongEnd) || (character >= hangulSyllableStart && character <= hangulSyllableEnd)) {
        HangulState state;
        if (character < hangulJungseongStart)
            state = HangulState::L;
        else if (character < hangulJongseongStart)
            state = HangulState::V;
        else if (character < hangulSyllableStart)
            state = HangulState::T;
        else
            state = isHangulLVT(character) ? HangulState::LVT : HangulState::LV;
        while (current > 0 && (character = text[current - 1]) >= hangulChoseongStart && character <= hangulSyllableEnd && (character <= hangulJongseongEnd || character >= hangulSyllableStart)) {
            switch (state) {
                case HangulState::V:
                    if (character <= hangulChoseongEnd)
                        state = HangulState::L;
                    else if (character >= hangulSyllableStart && character <= hangulSyllableEnd && !isHangulLVT(character))
                        state = HangulState::LV;
                    else if (character > hangulJungseongEnd)
                        state = HangulState::Break;
                    break;
                case HangulState::T:
                    if (character >= hangulJungseongStart && character <= hangulJungseongEnd)
                        state = HangulState::V;
                    else if (character >= hangulSyllableStart && character <= hangulSyllableEnd)
                        state = isHangulLVT(character) ? HangulState::LVT : HangulState::LV;
                    else if (character < hangulJungseongStart)
                        state = HangulState::Break;
                    break;
                default:
                    state = (character < hangulJungseongStart) ? HangulState::L : HangulState::Break;
                    break;
            }
            if (state == HangulState::Break)
                break;
            --current;
        }
    }
    return current;
}

WebCore::FontCascade::CodePath (*characterRangeCodePath)(const UChar *, unsigned);
%hookf(FontCascade::CodePath, characterRangeCodePath, const UChar *characters, unsigned len) {
    WebCore::FontCascade::CodePath result = WebCore::FontCascade::Simple;
    bool previousCharacterIsEmojiGroupCandidate = false;
    for (unsigned i = 0; i < len; i++) {
        const UChar c = characters[i];
        if (c == zeroWidthJoiner && previousCharacterIsEmojiGroupCandidate)
            return WebCore::FontCascade::Complex;
        previousCharacterIsEmojiGroupCandidate = false;
        if (c < 0x2E5)
            continue;
        if (c <= 0x2E9)
            return WebCore::FontCascade::Complex;
        if (c < 0x300)
            continue;
        if (c <= 0x36F)
            return WebCore::FontCascade::Complex;
        if (c < 0x0591 || c == 0x05BE)
            continue;
        if (c <= 0x05CF)
            return WebCore::FontCascade::Complex;
        if (c < 0x0600)
            continue;
        if (c <= 0x109F)
            return WebCore::FontCascade::Complex;
        if (c < 0x1100)
            continue;
        if (c <= 0x11FF)
            return WebCore::FontCascade::Complex;
        if (c < 0x135D)
            continue;
        if (c <= 0x135F)
            return WebCore::FontCascade::Complex;
        if (c < 0x1700)
            continue;
        if (c <= 0x18AF)
            return WebCore::FontCascade::Complex;
        if (c < 0x1900)
            continue;
        if (c <= 0x194F)
            return WebCore::FontCascade::Complex;
        if (c < 0x1980)
            continue;
        if (c <= 0x19DF)
            return WebCore::FontCascade::Complex;
        if (c < 0x1A00)
            continue;
        if (c <= 0x1CFF)
            return WebCore::FontCascade::Complex;
        if (c < 0x1DC0)
            continue;
        if (c <= 0x1DFF)
            return WebCore::FontCascade::Complex;
        if (c <= 0x2000) {
            result = WebCore::FontCascade::SimpleWithGlyphOverflow;
            continue;
        }
        if (c < 0x20D0)
            continue;
        if (c <= 0x20FF)
            return WebCore::FontCascade::Complex;
        if (c < 0x26F9)
            continue;
        if (c < 0x26FA)
            return WebCore::FontCascade::Complex;
        if (c < 0x2CEF)
            continue;
        if (c <= 0x2CF1)
            return WebCore::FontCascade::Complex;
        if (c < 0x302A)
            continue;
        if (c <= 0x302F)
            return WebCore::FontCascade::Complex;
        if (c < 0xA67C)
            continue;
        if (c <= 0xA67D)
            return WebCore::FontCascade::Complex;
        if (c < 0xA6F0)
            continue;
        if (c <= 0xA6F1)
            return WebCore::FontCascade::Complex;
        if (c < 0xA800)
            continue;
        if (c <= 0xABFF)
            return WebCore::FontCascade::Complex;
        if (c < 0xD7B0)
            continue;
        if (c <= 0xD7FF)
            return WebCore::FontCascade::Complex;
        if (c <= 0xDBFF) {
            if (i == len - 1)
                continue;
            UChar next = characters[++i];
            if (!U16_IS_TRAIL(next))
                continue;
            UChar32 supplementaryCharacter = U16_GET_SUPPLEMENTARY(c, next);
            if (supplementaryCharacter < 0x1F1E6)
                continue;
            if (supplementaryCharacter <= 0x1F1FF)
                return WebCore::FontCascade::Complex;
            if (isEmojiFitzpatrickModifier(supplementaryCharacter))
                return WebCore::FontCascade::Complex;
            if (isEmojiGroupCandidate(supplementaryCharacter)) {
                previousCharacterIsEmojiGroupCandidate = true;
                continue;
            }
            if (supplementaryCharacter < 0xE0100)
                continue;
            if (supplementaryCharacter <= 0xE01EF)
                return WebCore::FontCascade::Complex;
            continue;
        }
        if (c < 0xFE00)
            continue;
        if (c <= 0xFE0F)
            return WebCore::FontCascade::Complex;
        if (c < 0xFE20)
            continue;
        if (c <= 0xFE2F)
            return WebCore::FontCascade::Complex;
    }
    return result;
}

bool (*advanceByCombiningCharacterSequence)(const UChar *&, const UChar *, UChar32&, unsigned&);
%hookf(bool, advanceByCombiningCharacterSequence, const UChar*&iterator, const UChar* end, UChar32& baseCharacter, unsigned& markCount) {
    ASSERT(iterator < end);
    markCount = 0;
    unsigned i = 0;
    unsigned remainingCharacters = end - iterator;
    U16_NEXT(iterator, i, remainingCharacters, baseCharacter);
    iterator = iterator + i;
    if (U_IS_SURROGATE(baseCharacter))
        return false;
    bool sawEmojiGroupCandidate = isEmojiGroupCandidate(baseCharacter);
    bool sawJoiner = false;
    while (iterator < end) {
        UChar32 nextCharacter;
        unsigned markLength = 0;
        bool shouldContinue = false;
        U16_NEXT(iterator, markLength, end - iterator, nextCharacter);
        if (isVariationSelector(nextCharacter) || isEmojiFitzpatrickModifier(nextCharacter))
            shouldContinue = true;
        if (sawJoiner && isEmojiGroupCandidate(nextCharacter))
            shouldContinue = true;
        sawJoiner = false;
        if (sawEmojiGroupCandidate && nextCharacter == zeroWidthJoiner) {
            sawJoiner = true;
            shouldContinue = true;
        }
        if (!shouldContinue && !(U_GET_GC_MASK(nextCharacter) & U_GC_M_MASK))
            break;
        markCount += markLength;
        iterator += markLength;
    }
    return true;
}

%ctor {
    if (isiOS10_2Up)
        return;
    MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/WebCore.framework/WebCore"));
    isCJKIdeograph = (bool (*)(UChar32))MSFindSymbol(ref, "__ZN7WebCore11FontCascade14isCJKIdeographEi");
    if (isCJKIdeograph == NULL)
        isCJKIdeograph = (bool (*)(UChar32))MSFindSymbol(ref, "__ZN7WebCore4Font14isCJKIdeographEi");
    HBLogDebug(@"Found isCJKIdeograph: %d", isCJKIdeograph != NULL);
    isCJKIdeographOrSymbol = (bool (*)(UChar32))MSFindSymbol(ref, "__ZN7WebCore11FontCascade22isCJKIdeographOrSymbolEi");
    if (isCJKIdeographOrSymbol == NULL)
        isCJKIdeographOrSymbol = (bool (*)(UChar32))MSFindSymbol(ref, "__ZN7WebCore4Font22isCJKIdeographOrSymbolEi");
    HBLogDebug(@"Found isCJKIdeographOrSymbol: %d", isCJKIdeographOrSymbol != NULL);
    RenderText_originalText = (String (*)(void *))MSFindSymbol(ref, "__ZNK7WebCore10RenderText12originalTextEv");
    HBLogDebug(@"Found RenderText_originalText: %d", RenderText_originalText != NULL);
    RenderText_previousOffsetForBackwardDeletion = (int (*)(void *, int))MSFindSymbol(ref, "__ZNK7WebCore10RenderText33previousOffsetForBackwardDeletionEi");
    HBLogDebug(@"Found RenderText_previousOffsetForBackwardDeletion: %d", RenderText_previousOffsetForBackwardDeletion != NULL);
    characterRangeCodePath = (WebCore::FontCascade::CodePath (*)(const UChar *, unsigned))MSFindSymbol(ref, "__ZN7WebCore11FontCascade22characterRangeCodePathEPKtj"); // missing in iOS 5
    if (characterRangeCodePath == NULL)
        characterRangeCodePath = (WebCore::FontCascade::CodePath (*)(const UChar *, unsigned))MSFindSymbol(ref, "__ZN7WebCore4Font22characterRangeCodePathEPKtj");
    HBLogDebug(@"Found characterRangeCodePath: %d", characterRangeCodePath != NULL);
#if __LP64__ || !TARGET_OS_SIMULATOR
    advanceByCombiningCharacterSequence = (bool (*)(const UChar *&, const UChar *, UChar32&, unsigned&))MSFindSymbol(ref, "__ZN7WebCoreL35advanceByCombiningCharacterSequenceERPKtS1_RiRj"); // missing in iOS 5
    HBLogDebug(@"Found advanceByCombiningCharacterSequence: %d", advanceByCombiningCharacterSequence != NULL);
#endif
    %init;
}
