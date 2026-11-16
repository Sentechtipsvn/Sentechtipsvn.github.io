#ifndef SW_METHOD_ABI_H
#define SW_METHOD_ABI_H
#include <stddef.h>
#include <string.h>

// NSMethodSignature encodes Objective-C's implicit self and _cmd as two args.
// An action may return its resulting state (BOOL), including NO when turning
// off. A valid invocation is not evidence of success; callers must read back.
static inline int SWABIIsBoolean(const char *type) {
    return type && (!strcmp(type, "B") || !strcmp(type, "c"));
}
static inline int SWABIIsBooleanGetter(const char *type, size_t args, size_t bytes) {
    return args == 2 && bytes == 1 && SWABIIsBoolean(type);
}
static inline int SWABIIsNoArgumentAction(const char *type, size_t args, size_t bytes) {
    return args == 2 && type && ((!strcmp(type, "v") && bytes == 0) ||
                                 (SWABIIsBoolean(type) && bytes == 1));
}
#endif
