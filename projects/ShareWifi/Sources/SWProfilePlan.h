// Portable policy shared by the iOS controller and host regression tests.
#ifndef SW_PROFILE_PLAN_H
#define SW_PROFILE_PLAN_H
#include <stdbool.h>
enum { SWData, SWWifi, SWBluetooth, SWHotspot, SWRadioCount };
typedef enum { SWStartAll, SWStopAll, SWStopHotspot, SWRestore } SWProfile;
typedef struct { int target[SWRadioCount]; int order[SWRadioCount]; unsigned count; } SWPlan;
static inline bool SWValidPowers(const int *p) {
    if (!p) return false;
    for (unsigned i=0;i<SWRadioCount;i++) if(p[i]!=0 && p[i]!=1) return false;
    return true;
}
static inline bool SWBuildPlan(SWProfile profile,const int *current,const int *baseline,SWPlan *out) {
    if (!out || !SWValidPowers(current)) return false;
    if (profile<SWStartAll || profile>SWRestore || (profile==SWRestore && !SWValidPowers(baseline))) return false;
    SWPlan p={0};
    for(unsigned i=0;i<SWRadioCount;i++) p.target[i]=profile==SWRestore?baseline[i]:(profile==SWStartAll?1:0);
    if(profile==SWStopHotspot) {
        for(unsigned i=0;i<SWHotspot;i++) p.target[i]=current[i];
        p.order[0]=SWHotspot;p.count=1;
    } else {
        p.count=SWRadioCount;
        if(p.target[SWHotspot]) {for(unsigned i=0;i<SWRadioCount;i++)p.order[i]=(int)i;}
        else {p.order[0]=SWHotspot;for(unsigned i=0;i<SWHotspot;i++)p.order[i+1]=(int)i;}
    }
    *out=p;return true;
}
static inline bool SWCaptureSession(SWProfile profile,const int *current,bool hasSession) {
    return profile==SWStartAll && SWValidPowers(current) && !current[SWHotspot] && !hasSession;
}
#endif
