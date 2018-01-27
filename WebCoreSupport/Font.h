#include <unicode/utf16.h>
#import "FontPlatformData.h"
#import "RefCounted.h"

using namespace WTF;

namespace WebCore {
class Font : public RefCounted<Font> {
public:
const FontPlatformData& platformData() const;
const Font& brokenIdeographFont() const;
unsigned m_isBrokenIdeographFallback : 1;
};
class FontCascade {
public:
static bool isCJKIdeograph(UChar32);
static bool isCJKIdeographOrSymbol(UChar32);
enum CodePath {
    Auto, Simple, Complex, SimpleWithGlyphOverflow
};
static CodePath characterRangeCodePath(const UChar *, unsigned len);
};
};
