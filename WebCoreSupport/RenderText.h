#import "StringImpl.h"

using namespace WTF;

namespace WebCore {

class InlineTextBox;

class RenderText {
	private:
		String m_text;
	public:
		StringImpl* text() const { return m_text.impl(); }
	};
} // namespace WebCore