EmojiAttributes
=============

Fixing emoji display bugs for all capable iOS versions.

Description
=============

Function (Character set): Emoji character set has to be modified in order to display emoji correctly. Having the up-to-date emoji font installed on your device is not enough, as iOS recognizes and displays emojis based on character set known by it. For an analogy, the character set consists of tickets of all emojis (emoji characters) allowed to be displayed. If a ticket isn't found for an emoji, that emoji won't display properly, instead as "?", "..." or blank space. EmojiAttributes makes sure there is a ticket for everyone.

Function (Combined characters): Some emojis are made of multiple characters. This has been a thing since iOS 8.3 when Apple introduced family, couple emojis and also skinned emojis. Apple used to treat emoji as one single character (or, one character followed by just a variant selector character: 0xFE0F). Therefore, if the code (in EmojiAttributes) that handles grouped emojis doesn't present, iOS would break them into separate emojis, and not combined as a single unit as it should. Also, being able to see them as one unit means you can delete the whole emoji at once.

Technical Information
=============

This tweak may be categorized into:
* [Active] Character set addition (CharacterSetHack)
* [Active] CF-based emoji display (CoreFoundationHack)
* [Active] Web-based emoji display (WebCoreHack)
* [Active] TextInput character set addition (TextInputHack)

The first part is already described above. For CoreFoundation hack, the algorithm mimics emoji support from open-source of latest CoreFoundation framework
found on the internet. For WebCore hack, the algorithm aims to fix emoji
display on websites (which is different from display of iOS system itself) by implementing the whole modern code from open-source WebKit (WebCore here) framework.
Character set addition also takes place in `TextInput.framework`, as presented in TextInputHack. Using the up-to-date bitmap is always good when a tweak developer checks whether a string contains emoji via `-[NSString(TIExtras) _containsEmoji]`.
