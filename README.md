# EmojiAttributes

Various under-the-hood fixes for emoji display.

# Technical Information

## CoreText
This framework is an intermediate layer between text display and text representation in iOS. It mainly handles character sets of such supported fonts, including emoji.

### Character Set Addition
Emoji character set for display is hard-coded in bitmap format and retrievable from `CreateCharacterSetForFont()`. The set changes from version to version of iOS. We need to override this with the latest character set. To get the character set needed, we can dump one from `libGSFontCache.dylib` which is what [EmojiCategory](https://github.com/PoomSmart/EmojiCategory) does. Wtihout this override, emojis can be all shadowed (black out).

### Emoji Presentation Addition
As of iOS 11, a weird function `IsDefaultEmojiPresentation()` seems to determine which emojis are really supported by the system before showing them. While it is unknown where exactly does this function matters, hooking this function may be good for the future. The representation is just an array of strings and we can accumulate every single emoji and override it with that.

## CoreFoundation
This framework handles display emojis in most native (UIKit) applications. `CFStringGetRangeOfCharacterClusterAtIndex()` consults the hardcoded emoji character set to determine the index of the given character, taking into account that it can be one of the characters (cluster) of one single emoji. We as well need to override the character set. Without this workaround, unsupported emojis will be rendered as blank or "?" icon.

## WebCore
This framework does a lot of things to displaying content in websites, including displaying emojis in such web pages. Apple hardcoded all emoji unicodes in here for iteration through characters in a webpage to apply a compatible (emoji) font for them. Without this hack, emojis will be displayed as blank rectangles.

## TextInput (iOS < 10)
`-[NSString(TIExtras) _containsEmoji]` involves opening the emoji bitmap file `TIUserDictionaryEmojiCharacterSet.bitmap` residing in `/System/Library/Frameworks/TextInput.framework`. It simply needs to be replaced by the most recent bitmap so that such applications that perform checking emoji substrings will perform correctly.

## Emoji Size Fix (iOS 6 - 9)
Remove WebCore/CoreText emoji size restriction. See [here](https://emojier.com/faq/15122z-ios-small-font-size-emoji-hell).

## CoreEmoji (iOS >= 10)
This dedicated framework by Apple deals with emojis display logic at the low level (C++). One of the key point of it is a way to inject emoji metadata into the system correctly. On iOS 12.1 onwards, the "padding" is 16 whereas the earlier versions get 12 (More details once I figured out how the metadata file is constructed) - making the latest emoji metadata useless for those earlier versions and it needs some runtime modification as done in the code here.
