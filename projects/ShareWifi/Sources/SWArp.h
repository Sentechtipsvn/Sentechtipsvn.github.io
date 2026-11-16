#ifndef SW_ARP_H
#define SW_ARP_H
#include <stdint.h>
#include <stddef.h>
typedef void (*SWArpCallback)(void *context, uint16_t index, const uint8_t ip[4],
                              const uint8_t mac[6], int32_t expiry);
// XNU NET_RT_FLAGS/RTF_LLINFO framing. Reads bytes without unaligned casts.
// Return -1 for a malformed/truncated stream; otherwise the emitted row count.
int SWParseArp(const uint8_t *bytes, size_t size, SWArpCallback callback, void *context);
#endif
