#ifndef SW_RADIO_ACTION_H
#define SW_RADIO_ACTION_H
#include <string.h>
#include "SWProfilePlan.h"

static inline const char *SWRadioKey(unsigned radio) {
    static const char *keys[] = {"data", "wifi", "bluetooth", "hotspot"};
    return radio < SWRadioCount ? keys[radio] : NULL;
}

// Absolute targets make a stale Home Screen menu safe to select twice.
static inline bool SWDecodeRadioAction(const char *action, int *radio, int *value) {
    if (!action || !radio || !value || strncmp(action, "set.", 4)) return false;
    size_t length = strlen(action);
    for (unsigned i = 0; i < SWRadioCount; i++) {
        const char *key = SWRadioKey(i);
        size_t n = strlen(key);
        if (length == n + 6 && !memcmp(action + 4, key, n) && action[n + 4] == '.' &&
            (action[n + 5] == '0' || action[n + 5] == '1')) {
            *radio = (int)i; *value = action[n + 5] - '0'; return true;
        }
    }
    return false;
}

// Unknown peers are allowed; the one selected radio must have a known state.
static inline bool SWBuildRadioPlan(int radio, int value, const int *current, SWPlan *out) {
    if (!current || !out || radio < 0 || radio >= SWRadioCount || (value != 0 && value != 1)) return false;
    for (unsigned i = 0; i < SWRadioCount; i++)
        if (current[i] < -1 || current[i] > 1) return false;
    if (current[radio] < 0) return false;
    SWPlan plan = {0};
    for (unsigned i = 0; i < SWRadioCount; i++) plan.target[i] = current[i];
    plan.target[radio] = value; plan.order[0] = radio; plan.count = 1;
    *out = plan; return true;
}
#endif
