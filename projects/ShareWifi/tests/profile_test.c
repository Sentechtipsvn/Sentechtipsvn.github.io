#include <assert.h>
#include <stdio.h>
#include "SWProfilePlan.h"
int main(void) {
    SWPlan p;
    for(int bits=0;bits<16;bits++) {
        int now[4];for(unsigned i=0;i<4;i++)now[i]=(bits>>i)&1;
        assert(SWBuildPlan(SWStopHotspot,now,0,&p));
        assert(p.count==1 && p.order[0]==SWHotspot && p.target[3]==0);
        for(unsigned i=0;i<3;i++)assert(p.target[i]==now[i]);
        for(int before=0;before<16;before++) {
            int baseline[4];for(unsigned i=0;i<4;i++)baseline[i]=(before>>i)&1;
            assert(SWBuildPlan(SWRestore,now,baseline,&p));
            for(unsigned i=0;i<4;i++)assert(p.target[i]==baseline[i]);
            assert(p.order[baseline[3]?3:0]==SWHotspot);
        }
        assert(SWBuildPlan(SWStartAll,now,0,&p));
        assert(p.order[3]==SWHotspot);
        for(unsigned i=0;i<4;i++)assert(p.target[i]==1);
        assert(SWBuildPlan(SWStopAll,now,0,&p));
        assert(p.order[0]==SWHotspot);
        for(unsigned i=0;i<4;i++)assert(p.target[i]==0);
        assert(!SWBuildPlan(SWRestore,now,0,&p));
        assert(SWCaptureSession(SWStartAll,now,false)==!now[3]);
        assert(!SWCaptureSession(SWStartAll,now,true));
        assert(!SWCaptureSession(SWStopAll,now,false));
    }
    int invalid[]={1,-1,0,0},valid[]={1,0,1,0};
    assert(!SWBuildPlan(SWStartAll,invalid,0,&p));
    assert(!SWBuildPlan(SWRestore,valid,invalid,&p));
    assert(!SWBuildPlan((SWProfile)99,valid,0,&p));
    assert(!SWBuildPlan(SWStopAll,0,0,&p));
    puts("Profile tests passed: 16 radio combinations; 256 restores; missing/invalid state rejection.");
}
