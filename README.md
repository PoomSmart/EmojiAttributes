# EmojiAttributes

Various under-the-hood fixes for emoji display.

# Technical Information

This tweak may be categorized into:
* **CoreText**-based emoji display (CoreTextHack)
* **CoreFoundation**-based emoji display (CoreFoundationHack)
* **WebCore**-based emoji display (WebCoreHack)
* **TextInput** character set addition (TextInputHack)
* **EmojiSize** (EmojiSizeFix)

## CoreText
### Character Set Addition
Character set for the emoji font is hard-coded according to how this framework works; `CreateCharacterSetForFont()`, instead of parsing all that are needed from the font itself. The character set is in bitmap format and it is vital to redefine with our up-to-date bitmap.

### Emoji Presentation Addition
As of iOS 11, a weird C++ function `IsDefaultEmojiPresentation()` seems to determine which emojis are really supported in the system before showing them. While it is unknown where exactly does this function matters, hooking this function may be good for the future.

## CoreFoundation
This framework handles display emojis in most native applications. `CFStringGetRangeOfCharacterClusterAtIndex()` plays the important role for emojis as it has to consult the emoji characterset - that should be up-to-date. If getting the range of emojis in a given string is invalid because the characterset is old, it can result in some emojis not grouping properly, or getting fallback to the "?" icon.

## WebCore
Tons of logic in displaying emojis in websites or web views are in here. They hard-coded all emoji unicodes in order to tell which character that WebCore is parsing is an emoji, so that the emoji font can be applied to.

## TextInput (iOS < 10)
`-[NSString(TIExtras) _containsEmoji]` involves opening the emoji bitmap file `TIUserDictionaryEmojiCharacterSet.bitmap` residing in `/System/Library/Frameworks/TextInput.framework`. It simply needs to be replaced by the most recent bitmap.

## Emoji Size Fix (iOS 6 - 9)
Remove WebCore/CoreText emoji size restriction. See [here](https://emojier.com/faq/15122z-ios-small-font-size-emoji-hell).
