#if !__arm64e__

#import "../PS.h"
#import "WebCoreSupport/CharactersProperties.h"
#import "WebCoreSupport/RenderText.h"
#import "WebCoreSupport/CoreGraphicsSPI.h"
#import <CoreText/CoreText.h>
#import <HBLog.h>
#import <substrate.h>
#include <unicode/utf16.h>

%config(generator=MobileSubstrate)

enum CodePath {
    Auto, Simple, Complex, SimpleWithGlyphOverflow
};

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
            if (isEmojiRegionalIndicator(character))
                break;
            U16_FWD_1_UNSAFE(text, current);
        }
        if (isInArmenianToLimbuRange(character))
            break;
        if (isEmojiRegionalIndicator(character)) {
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

CodePath (*characterRangeCodePath)(const UChar *, unsigned);
%hookf(CodePath, characterRangeCodePath, const UChar *characters, unsigned len) {
    CodePath result = Simple;
	bool previousCharacterIsEmojiGroupCandidate = false;
	for (unsigned i = 0; i < len; ++i) {
        const UChar c = characters[i];
        if (c == zeroWidthJoiner && previousCharacterIsEmojiGroupCandidate)
            return Complex;
        
        previousCharacterIsEmojiGroupCandidate = false;
        if (c < 0x2E5) // U+02E5 through U+02E9 (Modifier Letters : Tone letters) 
            continue;
        if (c <= 0x2E9) 
            return Complex;
        
        if (c < 0x300) // U+0300 through U+036F Combining diacritical marks
            continue;
        if (c <= 0x36F)
            return Complex;
        
        if (c < 0x0591 || c == 0x05BE) // U+0591 through U+05CF excluding U+05BE Hebrew combining marks, Hebrew punctuation Paseq, Sof Pasuq and Nun Hafukha
            continue;
        if (c <= 0x05CF)
            return Complex;
        
        // U+0600 through U+109F Arabic, Syriac, Thaana, NKo, Samaritan, Mandaic,
        // Devanagari, Bengali, Gurmukhi, Gujarati, Oriya, Tamil, Telugu, Kannada,
        // Malayalam, Sinhala, Thai, Lao, Tibetan, Myanmar
        if (c < 0x0600) 
            continue;
        if (c <= 0x109F)
            return Complex;
        
        // U+1100 through U+11FF Hangul Jamo (only Ancient Korean should be left here if you precompose;
        // Modern Korean will be precomposed as a result of step A)
        if (c < 0x1100)
            continue;
        if (c <= 0x11FF)
            return Complex;
        
        if (c < 0x135D) // U+135D through U+135F Ethiopic combining marks
            continue;
        if (c <= 0x135F)
            return Complex;
        
        if (c < 0x1700) // U+1780 through U+18AF Tagalog, Hanunoo, Buhid, Taghanwa,Khmer, Mongolian
            continue;
        if (c <= 0x18AF)
            return Complex;
        
        if (c < 0x1900) // U+1900 through U+194F Limbu (Unicode 4.0)
            continue;
        if (c <= 0x194F)
            return Complex;
        
        if (c < 0x1980) // U+1980 through U+19DF New Tai Lue
            continue;
        if (c <= 0x19DF)
            return Complex;
        
        if (c < 0x1A00) // U+1A00 through U+1CFF Buginese, Tai Tham, Balinese, Batak, Lepcha, Vedic
            continue;
        if (c <= 0x1CFF)
            return Complex;
        
        if (c < 0x1DC0) // U+1DC0 through U+1DFF Comining diacritical mark supplement
            continue;
        if (c <= 0x1DFF)
            return Complex;
        
        // U+1E00 through U+2000 characters with diacritics and stacked diacritics
        if (c <= 0x2000) {
        result = SimpleWithGlyphOverflow;
            continue;
        }
        
        if (c < 0x20D0) // U+20D0 through U+20FF Combining marks for symbols
            continue;
        if (c <= 0x20FF)
            return Complex;
        
        if (c < 0x26F9)
            continue;
        if (c < 0x26FA)
            return Complex;
        
        if (c < 0x2CEF) // U+2CEF through U+2CF1 Combining marks for Coptic
            continue;
        if (c <= 0x2CF1)
            return Complex;
        
        if (c < 0x302A) // U+302A through U+302F Ideographic and Hangul Tone marks
            continue;
        if (c <= 0x302F)
            return Complex;
        
        if (c < 0xA67C) // U+A67C through U+A67D Combining marks for old Cyrillic
            continue;
        if (c <= 0xA67D)
            return Complex;
        
        if (c < 0xA6F0) // U+A6F0 through U+A6F1 Combining mark for Bamum
            continue;
        if (c <= 0xA6F1)
            return Complex;
        
        // U+A800 through U+ABFF Nagri, Phags-pa, Saurashtra, Devanagari Extended,
        // Hangul Jamo Ext. A, Javanese, Myanmar Extended A, Tai Viet, Meetei Mayek,
        if (c < 0xA800) 
            continue;
        if (c <= 0xABFF)
            return Complex;
        
        if (c < 0xD7B0) // U+D7B0 through U+D7FF Hangul Jamo Ext. B
            continue;
        if (c <= 0xD7FF)
            return Complex;
        
        if (c <= 0xDBFF) {
        // High surrogate
        
        if (i == len - 1)
            continue;
        
        UChar next = characters[++i];
        if (!U16_IS_TRAIL(next))
            continue;
        
        UChar32 supplementaryCharacter = U16_GET_SUPPLEMENTARY(c, next);
        
        if (supplementaryCharacter < 0x10A00)
            continue;
        if (supplementaryCharacter < 0x10A60) // Kharoshthi
            return Complex;
        if (supplementaryCharacter < 0x11000)
            continue;
        if (supplementaryCharacter < 0x11080) // Brahmi
            return Complex;
        if (supplementaryCharacter < 0x110D0) // Kaithi
            return Complex;
        if (supplementaryCharacter < 0x11100)
            continue;
        if (supplementaryCharacter < 0x11150) // Chakma
            return Complex;
        if (supplementaryCharacter < 0x11180) // Mahajani
            return Complex;
        if (supplementaryCharacter < 0x111E0) // Sharada
            return Complex;
        if (supplementaryCharacter < 0x11200)
            continue;
        if (supplementaryCharacter < 0x11250) // Khojki
            return Complex;
        if (supplementaryCharacter < 0x112B0)
            continue;
        if (supplementaryCharacter < 0x11300) // Khudawadi
            return Complex;
        if (supplementaryCharacter < 0x11380) // Grantha
            return Complex;
        if (supplementaryCharacter < 0x11400)
            continue;
        if (supplementaryCharacter < 0x11480) // Newa
            return Complex;
        if (supplementaryCharacter < 0x114E0) // Tirhuta
            return Complex;
        if (supplementaryCharacter < 0x11580)
            continue;
        if (supplementaryCharacter < 0x11600) // Siddham
            return Complex;
        if (supplementaryCharacter < 0x11660) // Modi
            return Complex;
        if (supplementaryCharacter < 0x11680)
            continue;
        if (supplementaryCharacter < 0x116D0) // Takri
            return Complex;
        if (supplementaryCharacter < 0x11C00)
            continue;
        if (supplementaryCharacter < 0x11C70) // Bhaiksuki
            return Complex;
        if (supplementaryCharacter < 0x11CC0) // Marchen
            return Complex;
        if (supplementaryCharacter < 0x1E900)
            continue;
        if (supplementaryCharacter < 0x1E960) // Adlam
            return Complex;
        if (supplementaryCharacter < 0x1F1E6) // U+1F1E6 through U+1F1FF Regional Indicator Symbols
            continue;
        if (supplementaryCharacter <= 0x1F1FF)
            return Complex;
        
        if (isEmojiFitzpatrickModifier(supplementaryCharacter))
            return Complex;
        if (isEmojiGroupCandidate(supplementaryCharacter)) {
            previousCharacterIsEmojiGroupCandidate = true;
            continue;
        }
        
        if (supplementaryCharacter < 0xE0000)
            continue;
        if (supplementaryCharacter < 0xE0080) // Tags
            return Complex;
        if (supplementaryCharacter < 0xE0100) // U+E0100 through U+E01EF Unicode variation selectors.
            continue;
        if (supplementaryCharacter <= 0xE01EF)
            return Complex;
        
        // FIXME: Check for Brahmi (U+11000 block), Kaithi (U+11080 block) and other Complex scripts
        // in plane 1 or higher.
        
            continue;
        }
        
        if (c < 0xFE00) // U+FE00 through U+FE0F Unicode variation selectors
            continue;
        if (c <= 0xFE0F)
            return Complex;
        
        if (c < 0xFE20) // U+FE20 through U+FE2F Combining half marks
            continue;
        if (c <= 0xFE2F)
            return Complex;
	}
	return result;
}

bool (*advanceByCombiningCharacterSequence)(const UChar *&, const UChar *, UChar32&, unsigned&);
%hookf(bool, advanceByCombiningCharacterSequence, const UChar*&iterator, const UChar* end, UChar32& baseCharacter, unsigned& markCount) {
    markCount = 0;
    unsigned i = 0;
    unsigned remainingCharacters = end - iterator;
    U16_NEXT(iterator, i, remainingCharacters, baseCharacter);
    iterator = iterator + i;
    if (U_IS_SURROGATE(baseCharacter))
        return false;
    bool sawEmojiGroupCandidate = isEmojiGroupCandidate(baseCharacter);
    bool sawJoiner = false;
    bool sawRegionalIndicator = isEmojiRegionalIndicator(baseCharacter);
    while (iterator < end) {
        UChar32 nextCharacter;
        unsigned markLength = 0;
        bool shouldContinue = false;
        U16_NEXT(iterator, markLength, static_cast<unsigned>(end - iterator), nextCharacter);
        if (isVariationSelector(nextCharacter) || isEmojiFitzpatrickModifier(nextCharacter))
            shouldContinue = true;
        if (sawRegionalIndicator && isEmojiRegionalIndicator(nextCharacter)) {
            shouldContinue = true;
            sawRegionalIndicator = false;
        }
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
    if (IS_IOS_OR_NEWER(iOS_10_0))
        return;
    MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/WebCore.framework/WebCore"));
    isCJKIdeograph = (bool (*)(UChar32))MSFindSymbol(ref, "__ZN7WebCore11FontCascade14isCJKIdeographEi");
    if (isCJKIdeograph == NULL)
        isCJKIdeograph = (bool (*)(UChar32))MSFindSymbol(ref, "__ZN7WebCore4Font14isCJKIdeographEi");
    HBLogDebug(@"[WebCoreHack] Found isCJKIdeograph: %d", isCJKIdeograph != NULL);
    isCJKIdeographOrSymbol = (bool (*)(UChar32))MSFindSymbol(ref, "__ZN7WebCore11FontCascade22isCJKIdeographOrSymbolEi");
    if (isCJKIdeographOrSymbol == NULL)
        isCJKIdeographOrSymbol = (bool (*)(UChar32))MSFindSymbol(ref, "__ZN7WebCore4Font22isCJKIdeographOrSymbolEi");
    HBLogDebug(@"[WebCoreHack] Found isCJKIdeographOrSymbol: %d", isCJKIdeographOrSymbol != NULL);
    RenderText_originalText = (String (*)(void *))MSFindSymbol(ref, "__ZNK7WebCore10RenderText12originalTextEv");
    HBLogDebug(@"[WebCoreHack] Found RenderText_originalText: %d", RenderText_originalText != NULL);
    RenderText_previousOffsetForBackwardDeletion = (int (*)(void *, int))MSFindSymbol(ref, "__ZNK7WebCore10RenderText33previousOffsetForBackwardDeletionEi");
    HBLogDebug(@"[WebCoreHack] Found RenderText_previousOffsetForBackwardDeletion: %d", RenderText_previousOffsetForBackwardDeletion != NULL);
    characterRangeCodePath = (CodePath (*)(const UChar *, unsigned))MSFindSymbol(ref, "__ZN7WebCore11FontCascade22characterRangeCodePathEPKtj"); // missing in iOS 5
    if (characterRangeCodePath == NULL)
        characterRangeCodePath = (CodePath (*)(const UChar *, unsigned))MSFindSymbol(ref, "__ZN7WebCore4Font22characterRangeCodePathEPKtj");
    HBLogDebug(@"[WebCoreHack] Found characterRangeCodePath: %d", characterRangeCodePath != NULL);
#if __LP64__ || !TARGET_OS_SIMULATOR
    advanceByCombiningCharacterSequence = (bool (*)(const UChar *&, const UChar *, UChar32&, unsigned&))MSFindSymbol(ref, "__ZN7WebCoreL35advanceByCombiningCharacterSequenceERPKtS1_RiRj"); // missing in iOS 5-6
    HBLogDebug(@"[WebCoreHack] Found advanceByCombiningCharacterSequence: %d", advanceByCombiningCharacterSequence != NULL);
#endif
    %init;
}

#endif