#include <string.h>

#define U_POINTER_MASK_LSB(ptr, mask) ((uintptr_t)(ptr) & (mask))

#define uprv_memcpy(dst, src, size) U_STANDARD_CPP_NAMESPACE memcpy(dst, src, size)