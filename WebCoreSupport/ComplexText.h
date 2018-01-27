#import "Font.h"
#import "RefCounted.h"
#import "StringImpl.h"

/*typedef unsigned short CGGlyph;

typedef const struct __CTRun * CTRunRef;
typedef const struct __CTLine * CTLineRef;*/

namespace WebCore {

class FontCascade;
class Font;
class TextRun;

enum GlyphIterationStyle { IncludePartialGlyphs, ByWholeGlyphs };

class ComplexTextController {
	public:
		ComplexTextController(const FontCascade&, const TextRun&, bool mayUseNaturalWritingDirection = false, void *fallbackFonts = 0, bool forTextEmphasis = false);
	//private: // HAX
		class ComplexTextRun : public WTF::RefCounted<ComplexTextRun> {
		public:
			unsigned glyphCount() const { return m_glyphCount; }
			const Font& font() const { return m_font; }
			const UChar* characters() const { return m_characters; }
			unsigned stringLocation() const { return m_stringLocation; }
			size_t stringLength() const { return m_stringLength; }
			CFIndex indexBegin() const { return m_indexBegin; }
			CFIndex indexEnd() const { return m_indexEnd; }
			const CGGlyph* glyphs() const { return m_glyphs; }
			CGSize initialAdvance() const { return m_initialAdvance; }
			const CGSize* advances() const { return m_advances; }
			bool isLTR() const { return m_isLTR; }
			bool isMonotonic() const { return m_isMonotonic; }
			void setIsNonMonotonic();

		private:
			ComplexTextRun(const Font&, const UChar* characters, unsigned stringLocation, size_t stringLength, bool ltr);

			unsigned m_glyphCount;
			const Font& m_font;
			const UChar* m_characters;
			unsigned m_stringLocation;
			size_t m_stringLength;
			const CFIndex* m_coreTextIndices;
			CFIndex m_indexBegin;
			CFIndex m_indexEnd;
			const CGGlyph* m_glyphs;
			CGSize m_initialAdvance;
			const CGSize* m_advances;
			bool m_isLTR;
			bool m_isMonotonic;
		};

		unsigned indexOfCurrentRun(unsigned& leftmostGlyph);
		unsigned incrementCurrentRun(unsigned& leftmostGlyph);

		const FontCascade& m_font;
		const TextRun& m_run;
		bool m_isLTROnly;
		bool m_mayUseNaturalWritingDirection;
		bool m_forTextEmphasis;

		unsigned m_currentCharacter;
		int m_end;

		CGFloat m_totalWidth;

		float m_runWidthSoFar;
		unsigned m_numGlyphsSoFar;
		size_t m_currentRun;
		unsigned m_glyphInCurrentRun;
		unsigned m_characterInCurrentGlyph;
		float m_finalRoundingWidth;
		float m_expansion;
		float m_expansionPerOpportunity;
		float m_leadingExpansion;

		float m_minGlyphBoundingBoxX;
		float m_maxGlyphBoundingBoxX;
		float m_minGlyphBoundingBoxY;
		float m_maxGlyphBoundingBoxY;

		unsigned m_lastRoundingGlyph;
	};

}
