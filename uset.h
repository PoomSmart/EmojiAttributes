#ifndef _MY_USET_H_
#define _MY_USET_H_

#include <unicode/utypes.h>

typedef struct USet USet;

extern "C" {
    USet *uset_openEmpty(void);
    void uset_close(USet *);
    void uset_freeze(USet *);
    void uset_add(USet *, UChar32);
    UBool uset_contains(USet *, UChar32);
}

#endif