/* Linux-only compatibility types; no CoreFoundation implementation is used. */
#ifndef SILEO_TEST_CF_TYPES
#define SILEO_TEST_CF_TYPES
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <ctype.h>
typedef unsigned char Boolean;
typedef unsigned long CFHashCode;
#define nil NULL
#undef __nonnull
#define __nonnull _Nonnull
static inline char *strnstr(const char *haystack, const char *needle, size_t length) {
    size_t n = strlen(needle);
    if (!n) return (char *)haystack;
    for (size_t i=0; i<length && haystack[i]; i++) {
        if (n<=length-i && !strncmp(haystack+i,needle,n)) return (char *)(haystack+i);
    }
    return NULL;
}
#endif
