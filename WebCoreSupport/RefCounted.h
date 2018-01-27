namespace WTF {
	class RefCountedBase {
		public:
			void ref() const { ++m_refCount; }
			bool derefBase() const {
				unsigned tempRefCount = m_refCount - 1;
				if (!tempRefCount)
					return true;
				m_refCount = tempRefCount;
				return false;
			}
		protected:
			RefCountedBase() : m_refCount(1) { }
		private:
			mutable unsigned m_refCount;
	};
	template<typename T> class RefCounted : public RefCountedBase {
		public:
			void deref() const {
				if (derefBase())
					delete static_cast<const T *>(this);
			}
		protected:
			RefCounted() { }
	};
};