namespace WTF {

    template <typename T> class PassRefPtr;

    template <typename T> class RefPtr
    {
    public:
        RefPtr() : m_ptr(0) {}
        RefPtr(T *ptr) : m_ptr(ptr) { if (ptr) ptr->ref(); }
        RefPtr(const RefPtr& o) : m_ptr(o.m_ptr) { if (T *ptr = m_ptr) ptr->ref(); }
        // see comment in PassRefPtr.h for why this takes const reference
        template <typename U> RefPtr(const PassRefPtr<U>&);

        ~RefPtr() { if (T *ptr = m_ptr) ptr->deref(); }
        
        template <typename U> RefPtr(const RefPtr<U>& o) : m_ptr(o.get()) { if (T *ptr = m_ptr) ptr->ref(); }
        
        T *get() const { return m_ptr; }
        
        PassRefPtr<T> release() { PassRefPtr<T> tmp = adoptRef(m_ptr); m_ptr = 0; return tmp; }

        T& operator*() const { return *m_ptr; }
        T *operator->() const { return m_ptr; }
        
        bool operator!() const { return !m_ptr; }
    
        // This conversion operator allows implicit conversion to bool but not to other integer types.
        typedef T * (RefPtr::*UnspecifiedBoolType)() const;
        operator UnspecifiedBoolType() const { return m_ptr ? &RefPtr::get : 0; }
        
        RefPtr& operator=(const RefPtr&);
        RefPtr& operator=(T *);
        RefPtr& operator=(const PassRefPtr<T>&);
        template <typename U> RefPtr& operator=(const RefPtr<U>&);
        template <typename U> RefPtr& operator=(const PassRefPtr<U>&);

        void swap(RefPtr&);

    private:
        T *m_ptr;
    };
    
    template <typename T> template <typename U> inline RefPtr<T>::RefPtr(const PassRefPtr<U>& o)
        : m_ptr(o.release())
    {
    }

    template <typename T> inline RefPtr<T>& RefPtr<T>::operator=(const RefPtr<T>& o)
    {
        T* optr = o.get();
        if (optr)
            optr->ref();
        T* ptr = m_ptr;
        m_ptr = optr;
        if (ptr)
            ptr->deref();
        return *this;
    }
    
    template <typename T> template <typename U> inline RefPtr<T>& RefPtr<T>::operator=(const RefPtr<U>& o)
    {
        T* optr = o.get();
        if (optr)
            optr->ref();
        T* ptr = m_ptr;
        m_ptr = optr;
        if (ptr)
            ptr->deref();
        return *this;
    }
    
    template <typename T> inline RefPtr<T>& RefPtr<T>::operator=(T* optr)
    {
        if (optr)
            optr->ref();
        T* ptr = m_ptr;
        m_ptr = optr;
        if (ptr)
            ptr->deref();
        return *this;
    }

    template <typename T> inline RefPtr<T>& RefPtr<T>::operator=(const PassRefPtr<T>& o)
    {
        T* ptr = m_ptr;
        m_ptr = o.release();
        if (ptr)
            ptr->deref();
        return *this;
    }

    template <typename T> template <typename U> inline RefPtr<T>& RefPtr<T>::operator=(const PassRefPtr<U>& o)
    {
        T* ptr = m_ptr;
        m_ptr = o.release();
        if (ptr)
            ptr->deref();
        return *this;
    }

    template <class T> inline void RefPtr<T>::swap(RefPtr<T>& o)
    {
        std::swap(m_ptr, o.m_ptr);
    }

    template <class T> inline void swap(RefPtr<T>& a, RefPtr<T>& b)
    {
        a.swap(b);
    }

    template <typename T, typename U> inline bool operator==(const RefPtr<T>& a, const RefPtr<U>& b)
    { 
        return a.get() == b.get(); 
    }

    template <typename T, typename U> inline bool operator==(const RefPtr<T>& a, U* b)
    { 
        return a.get() == b; 
    }
    
    template <typename T, typename U> inline bool operator==(T* a, const RefPtr<U>& b) 
    {
        return a == b.get(); 
    }
    
    template <typename T, typename U> inline bool operator!=(const RefPtr<T>& a, const RefPtr<U>& b)
    { 
        return a.get() != b.get(); 
    }

    template <typename T, typename U> inline bool operator!=(const RefPtr<T>& a, U* b)
    {
        return a.get() != b; 
    }

    template <typename T, typename U> inline bool operator!=(T* a, const RefPtr<U>& b)
    { 
        return a != b.get(); 
    }
    
    template <typename T, typename U> inline RefPtr<T> static_pointer_cast(const RefPtr<U>& p)
    { 
        return RefPtr<T>(static_cast<T *>(p.get())); 
    }

    template <typename T, typename U> inline RefPtr<T> const_pointer_cast(const RefPtr<U>& p)
    { 
        return RefPtr<T>(const_cast<T *>(p.get())); 
    }

    template <typename T> inline T* getPtr(const RefPtr<T>& p)
    {
        return p.get();
    }

} // namespace WTF

using WTF::RefPtr;
using WTF::static_pointer_cast;
using WTF::const_pointer_cast;