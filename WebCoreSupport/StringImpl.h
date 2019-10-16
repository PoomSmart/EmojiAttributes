#include <unicode/uchar.h>
#include <unicode/utf16.h>
#include <objc/objc.h>
#import "RefPtr.h"
#import "RefCounted.h"

typedef unsigned char LChar;

namespace WTF {
	class StringImplBase {
	public:
    	bool isStringImpl() { return (m_refCountAndFlags & s_refCountInvalidForStringImpl) != s_refCountInvalidForStringImpl; }
    	unsigned length() const { return m_length; }
    	void ref() { m_refCountAndFlags += s_refCountIncrement; }
    protected:
		enum BufferOwnership {
			BufferInternal,
			BufferOwned,
			BufferSubstring,
			BufferShared,
		};

		StringImplBase() { }
		
		static const unsigned s_refCountMask = 0xFFFFFF80;
		static const unsigned s_refCountIncrement = 0x80;
		static const unsigned s_refCountFlagStatic = 0x40;
		static const unsigned s_refCountFlagHasTerminatingNullCharacter = 0x20;
		static const unsigned s_refCountFlagIsAtomic = 0x10;
		static const unsigned s_refCountFlagShouldReportedCost = 0x8;
		static const unsigned s_refCountFlagIsIdentifier = 0x4;
		static const unsigned s_refCountMaskBufferOwnership = 0x3;
		static const unsigned s_refCountInvalidForStringImpl = s_refCountFlagStatic | s_refCountFlagShouldReportedCost;

		unsigned m_refCountAndFlags;
		unsigned m_length;
	};
};

namespace WTF {
	class StringImpl : public StringImplBase {
	public:
		CFStringRef createCFString();
		UChar operator[](unsigned i) { return m_data[i]; }
		//operator NSString*();
		const UChar* characters() const { return m_data; }
		bool is8Bit() const { return m_hashAndFlags & s_hashFlag8BitBuffer; }
		const LChar* characters8() const { return m_data8; }
		const UChar* characters16() const { return m_data16; }
		void deref() { m_refCountAndFlags -= s_refCountIncrement; if (!(m_refCountAndFlags & (s_refCountMask | s_refCountFlagStatic))) delete this; }
		unsigned length() const { return m_length; }
	private:
		static const unsigned s_hashFlag8BitBuffer = 1u << 3;
		const UChar* m_data;
		unsigned m_refCount;
		unsigned m_length;
		union {
			const LChar* m_data8;
			const UChar* m_data16;
		};
		mutable unsigned m_hashAndFlags;
	};
	
	bool equal(const StringImpl*, const StringImpl*);
	bool equal(const StringImpl*, const char*);
	inline bool equal(const char* a, StringImpl* b) { return equal(b, a); }

	bool equalIgnoringCase(StringImpl*, StringImpl*);
	bool equalIgnoringCase(StringImpl*, const char*);
	inline bool equalIgnoringCase(const char* a, StringImpl* b) { return equalIgnoringCase(b, a); }
	bool equalIgnoringCase(const UChar* a, const char* b, unsigned length);
	inline bool equalIgnoringCase(const char* a, const UChar* b, unsigned length) { return equalIgnoringCase(b, a, length); }
	
	int codePointCompare(const StringImpl*, const StringImpl*);
};

template<typename Type>
bool isPointerTypeAlignmentOkay(Type* ptr)
{
    return !(reinterpret_cast<intptr_t>(ptr) % __alignof__(Type));
}

template<typename TypePtr>
TypePtr reinterpret_cast_ptr(void* ptr)
{
    return reinterpret_cast<TypePtr>(ptr);
}

template<typename TypePtr>
TypePtr reinterpret_cast_ptr(const void* ptr)
{
    return reinterpret_cast<TypePtr>(ptr);
}

namespace WTF {
	class CStringBuffer : public RefCounted<CStringBuffer> {
		public:
			const char* data() { return mutableData(); }
			size_t length() const { return m_length; }
		private:
			friend class CString;
			CStringBuffer(size_t length) : m_length(length) { }
		char* mutableData() { return reinterpret_cast_ptr<char*>(this + 1); }
	const size_t m_length;
	};
	class CString {
		public:
			CString(CStringBuffer* buffer) : m_buffer(buffer) { }
			const char *data() { return m_buffer ? m_buffer->data() : 0; }
		private:
			RefPtr<CStringBuffer> m_buffer;
	};
};

namespace WTF {

	typedef enum {
		LenientConversion,
		StrictConversion,
		StrictConversionReplacingUnpairedSurrogatesWithFFFD,
	} ConversionMode;
	
	class String {
	public:
		String() { }
		String(StringImpl* impl) : m_impl(impl) { }
		String(RefPtr<StringImpl> impl) : m_impl(impl) { }
		void swap(String& o) { m_impl.swap(o.m_impl); }
		bool isEmpty() const { return !m_impl || !m_impl->length(); }
		bool isNull() const { return !m_impl; }
		bool is8Bit() const { return m_impl->is8Bit(); }
		StringImpl* impl() const { return m_impl.get(); }
		unsigned length() const {
        	if (!m_impl)
            	return 0;
        	return m_impl->length();
    	}
		const LChar* characters8() const {
			if (!m_impl)
				return 0;
			return m_impl->characters8();
		}
		const UChar* characters16() const {
			if (!m_impl)
				return 0;
			return m_impl->characters16();
		}
    	const UChar* characters() const {
        	if (!m_impl)
            	return 0;
        	return m_impl->characters();
    	}
		UChar operator[](unsigned index) const {
        	if (!m_impl || index >= m_impl->length())
            	return 0;
        	return m_impl->characters()[index];
    	}
    	static String number(short);
		static String number(unsigned short);
		static String number(int);
		static String number(unsigned);
		static String number(long);
		static String number(unsigned long);
		static String number(long long);
		static String number(unsigned long long);
		static String number(double);
		
		void append(const String&);
		void append(char);
		void append(UChar);
		void append(const UChar*, unsigned length);
		void insert(const String&, unsigned pos);
		void insert(const UChar*, unsigned length, unsigned pos);
		
		CString utf8(ConversionMode = LenientConversion) const;
	private:
    	RefPtr<StringImpl> m_impl;
	};
};

namespace WTF {
	class AtomicString {
		public:
			bool isEmpty() const { return m_string.isEmpty(); };
			const String& string() const { return m_string; };
		private:
			String m_string;
	};
};

namespace WTF {
	class StringBuilder {
		public:
			void append(const UChar*, unsigned);
			void append(const LChar*, unsigned);
			void append(const char* characters, unsigned length) { append(reinterpret_cast<const LChar*>(characters), length); }
			void append(const char* characters) {
				if (characters)
					append(characters, strlen(characters));
			}
			String toString() {
				shrinkToFit();
				if (m_string.isNull())
					reifyString();
				return m_string;
			}
		private:
			void shrinkToFit();
			void reifyString() const;
			mutable String m_string;
			unsigned m_length;
	};
};

namespace WebCore {
	class TextBreakIterator;
};

namespace WTF {
	class StringView {
		public:
			StringView();
			StringView(const String&);
			StringView(const StringImpl&);
			StringView(const StringImpl*);
			class UpconvertedCharacters;
			const UChar* characters16() const;
			bool is8Bit() const;
			UpconvertedCharacters upconvertedCharacters() const;
		private:
			const void *m_characters { nullptr };
			unsigned m_length { 0 };
	};
	static const unsigned is16BitStringFlag = 1u << 31;
	inline bool StringView::is8Bit() const {
		return !(m_length & is16BitStringFlag);
	}
	class StringView::UpconvertedCharacters {
		public:
			explicit UpconvertedCharacters(const StringView&);
			operator const UChar*() const { return m_characters; };
			const UChar* get() const { return m_characters; };
		private:
			//Vector<UChar, 32> m_upconvertedCharacters;
			const UChar* m_characters;
	};
	inline const UChar* StringView::characters16() const {
		return static_cast<const UChar*>(m_characters);
	}
	inline StringView::UpconvertedCharacters StringView::upconvertedCharacters() const {
		return UpconvertedCharacters(*this);
	}
	inline StringView::UpconvertedCharacters::UpconvertedCharacters(const StringView& string) {
		if (!string.is8Bit()) {
			m_characters = string.characters16();
			return;
		}
	}
	inline StringView::StringView(const String& string) {
		if (!string.impl()) {
			m_characters = nullptr;
			m_length = 0;
			return;
		}
		if (string.is8Bit()) {
			return;
		}
	}
};