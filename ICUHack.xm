#include <unicode/utf16.h>
#include <unicode/ubrk.h>
#import "WebCoreSupport/UAX.h"
#import "WebCoreSupport/StringImpl.h"

// Description: We only need this when LineBreakIteratorModeUAX14Normal comes into play

static const char *check1 = "$AI = [:LineBreak = Ambiguous:]";
static const char *check2 = "!!forward;";
static const char *check3 = "!!reverse;";

void (*WTF_StringBuilder_append)(void *, const UChar *, unsigned);
%hookf(void, WTF_StringBuilder_append, void *arg0, const UChar* str, unsigned length) {
    unsigned strLen = strlen((const char *)str);
    if (strLen >= strlen(check1) && strncmp((const char *)str, (const char *)check1, strlen(check1)) == 0)
        %orig(arg0, (const UChar *)uax14AssignmentsAfter, strlen(uax14AssignmentsAfter));
    else if (strLen >= strlen(check2) && strncmp((const char *)str, (const char *)check2, strlen(check2)) == 0)
        %orig(arg0, (const UChar *)uax14Forward, strlen(uax14Forward));
    else if (strLen >= strlen(check3) && strncmp((const char *)str, (const char *)check3, strlen(check3)) == 0)
        %orig(arg0, (const UChar *)uax14Reverse, strlen(uax14Reverse));
    else
        %orig;
}

TextBreakIterator *(*openLineBreakIterator)(const AtomicString&, LineBreakIteratorMode, bool);
%hookf(TextBreakIterator *, openLineBreakIterator, const AtomicString &locale, LineBreakIteratorMode mode, bool isCJK) {
    return %orig(locale, LineBreakIteratorModeUAX14Normal, isCJK);
}

String (*makeLocaleWithBreakKeyword)(void *, const AtomicString&, LineBreakIteratorMode);
%hookf(String, makeLocaleWithBreakKeyword, void *arg0, const AtomicString &locale, LineBreakIteratorMode mode) {
    return %orig(arg0, locale, LineBreakIteratorModeUAX14Normal);
}

TextBreakIterator *(*take)(void *, const AtomicString&, LineBreakIteratorMode, bool);
%hookf(TextBreakIterator *, take, void *arg0, const AtomicString &locale, LineBreakIteratorMode mode, bool isCJK) {
    return %orig(arg0, locale, LineBreakIteratorModeUAX14Normal, isCJK);
}

/*void (*resetStringAndReleaseIterator)(String, void *, LineBreakIteratorMode);
   %hookf(void, resetStringAndReleaseIterator, String string, void *locale, LineBreakIteratorMode mode) {
        %orig(string, locale, LineBreakIteratorModeUAX14Normal);
   }*/

%ctor {
    MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/WebCore.framework/WebCore"));
    MSImageRef ref2 = MSGetImageByName(realPath2(@"/System/Library/Frameworks/JavaScriptCore.framework/JavaScriptCore"));
    ComplexTextController_ComplexTextRun_ComplexTextRun = (ComplexTextController::ComplexTextRun::ComplexTextRun (*)(const Font&, const UChar *, unsigned, size_t, bool))MSFindSymbol(ref, "__ZN7WebCore21ComplexTextController14ComplexTextRunC2ERKNS_4FontEPKtjmb");
    WTF_StringBuilder_append = (void (*)(void *, const UChar *, unsigned))MSFindSymbol(ref2, "__ZN3WTF13StringBuilder6appendEPKhj");
    openLineBreakIterator = (TextBreakIterator *(*)(const AtomicString&, LineBreakIteratorMode, bool))MSFindSymbol(ref, "__ZN7WebCore21openLineBreakIteratorERKN3WTF12AtomicStringENS_21LineBreakIteratorModeEb");
    makeLocaleWithBreakKeyword = (String (*)(void *, const AtomicString&, LineBreakIteratorMode))MSFindSymbol(ref, "__ZN7WebCore21LineBreakIteratorPool26makeLocaleWithBreakKeywordERKN3WTF12AtomicStringENS_21LineBreakIteratorModeE");
    take = (TextBreakIterator *(*)(void *, const AtomicString&, LineBreakIteratorMode, bool))MSFindSymbol(ref, "__ZN7WebCore21LineBreakIteratorPool4takeERKN3WTF12AtomicStringENS_21LineBreakIteratorModeEb");
    //resetStringAndReleaseIterator = (void (*)(String, void *, LineBreakIteratorMode))MSFindSymbol(ref, "__ZN7WebCore21LazyLineBreakIterator29resetStringAndReleaseIteratorEN3WTF6StringERKNS1_12AtomicStringENS_21LineBreakIteratorModeE");
}
