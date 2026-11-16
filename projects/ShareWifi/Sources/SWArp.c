#include "SWArp.h"
#include <string.h>
static uint16_t u16(const uint8_t *p) { return (uint16_t)(p[0] | ((uint16_t)p[1] << 8)); }
static uint32_t u32(const uint8_t *p) {
    return p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}
int SWParseArp(const uint8_t *bytes, size_t size, SWArpCallback callback, void *context) {
    if ((!bytes && size) || !callback) return -1;
    int rows = 0;
    for (size_t start = 0; start < size;) {
        if (size - start < 4) return -1;
        size_t length = u16(bytes + start);
        if (length < 92 || length > size - start) return -1;
        const uint8_t *p = bytes + start;
        if (p[2] != 5) { start += length; continue; }
        uint32_t flags = u32(p + 8), mask = u32(p + 12);
        const uint8_t *dst = NULL, *gateway = NULL;
        size_t cursor = 92;
        for (int slot = 0; slot < 8; ++slot) {
            if (!(mask & (1U << slot))) continue;
            if (cursor + 2 > length) return -1;
            size_t n = p[cursor];
            size_t aligned = n ? (n + 3U) & ~3U : 4U;
            if (n < 2 || aligned > length - cursor) return -1;
            if (slot == 0) dst = p + cursor;
            if (slot == 1) gateway = p + cursor;
            cursor += aligned;
        }
        if ((flags & 0x400) && !(flags & 0x8) && u32(p + 24) == 0 &&
            dst && dst[0] >= 16 && dst[1] == 2 && gateway &&
            gateway[0] >= 8 && gateway[1] == 18 && gateway[6] == 6 &&
            (size_t)8 + gateway[5] + 6 <= gateway[0]) {
            const uint8_t *mac = gateway + 8 + gateway[5];
            static const uint8_t zero[6] = {0};
            if (!(mac[0] & 1) && memcmp(mac, zero, 6) != 0) {
                callback(context, u16(p + 4), dst + 4, mac, (int32_t)u32(p + 48));
                rows++;
            }
        }
        start += length;
    }
    return rows;
}
