# EmojiAttributes

Various under-the-hood fixes for emoji display.

# Technical Information

## CoreText
This framework is an intermediate layer between text display and text representation in iOS. It mainly handles character sets of such supported fonts, including emoji.

### Character Set Addition
Emoji character set is cached in bitmap format and retrievable from `CreateCharacterSetForFont()`. The set changes from version to version of iOS. We override this with the latest character set. To get the character set needed, we dump one from `libGSFontCache.dylib` which is what [EmojiCategory](https://github.com/PoomSmart/EmojiCategory) does. Without this override, emojis can be all shadowed (black out).

### Emoji Presentation Addition (iOS 11+)
As of iOS 11, a weird function `IsDefaultEmojiPresentation()` seems to determine which emojis are really supported by the system before showing them. The said representation is an array of emoji strings that can be easily overridden.

## CoreFoundation
This framework handles display emojis in most native (UIKit) applications. `CFStringGetRangeOfCharacterClusterAtIndex()` consults the cached emoji character set to determine the index of the given character, taking into account that it can be one of the characters (cluster) of one single emoji. We as well override the character set. Without this workaround, unsupported emojis will be rendered as blank or "?" icon.

## WebCore
This framework does a lot of things to displaying content in websites, including displaying emojis in web pages. Until at some point in the past, Apple hardcoded all emoji unicodes in here for iteration through characters in a webpage to apply a compatible (emoji) font for them. For present days, read ICU section below. Without this hack, emojis will be displayed as blank rectangles.

## TextInput (iOS < 10)
`-[NSString(TIExtras) _containsEmoji]` involves opening the emoji bitmap file `TIUserDictionaryEmojiCharacterSet.bitmap` residing in `/System/Library/Frameworks/TextInput.framework`. It simply needs to be replaced by the most recent bitmap so that such applications that perform checking emoji substrings will perform correctly.

## ICU
Apple has transitioned to be relying more on ICU API when it has to deal with emojis. Instead of hardcoding emoji codepoints in `CoreFoundation` framework, it directly consults ICU which already has similar information. At a high level, ICU embeds "props" data related to emojis inside `libicucore.A.dylib`. EmojiAttributes flexes its best to redirect readings of those data to be from its own.

## Emoji Size Fix (iOS 6 - 9)
Remove WebCore/CoreText emoji size restriction. See [here](https://emojier.com/faq/15122z-ios-small-font-size-emoji-hell).
