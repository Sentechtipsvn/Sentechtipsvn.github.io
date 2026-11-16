#include <assert.h>
#include <stdio.h>
#include "SWRadioAction.h"

int main(void) {
    SWPlan plan;
    for (int bits=0; bits<16; bits++) {
        int current[4];
        for (int i=0; i<4; i++) current[i]=(bits>>i)&1;
        for (int i=0; i<4; i++) for (int value=0; value<2; value++) {
            char action[40]; int decoded=-1, desired=-1;
            snprintf(action,sizeof(action),"set.%s.%d",SWRadioKey(i),value);
            assert(SWDecodeRadioAction(action,&decoded,&desired) && decoded==i && desired==value);
            assert(SWBuildRadioPlan(decoded,desired,current,&plan));
            assert(plan.count==1 && plan.order[0]==i);
            for (int j=0; j<4; j++) assert(plan.target[j]==(i==j?value:current[j]));
        }
    }
    int unknown[]={-1,1,-1,-1};
    assert(SWBuildRadioPlan(SWWifi,0,unknown,&plan));
    assert(plan.target[SWData]==-1 && plan.target[SWHotspot]==-1 && plan.count==1);
    assert(!SWBuildRadioPlan(SWHotspot,1,unknown,&plan));
    assert(!SWBuildRadioPlan(4,1,unknown,&plan));
    assert(!SWBuildRadioPlan(-1,1,unknown,&plan));
    assert(!SWBuildRadioPlan(SWWifi,2,unknown,&plan));
    int invalid[]={-2,1,0,0};
    assert(!SWBuildRadioPlan(SWWifi,0,invalid,&plan));
    int radio=9,value=9;
    const char *bad[]={"", "set", "set.", "set.wifi", "set.wifi.", "set.wifi.2", "set.wifi.01", "set.Wifi.1", "set.wifi.1.extra", "set..1", "toggle.wifi", "set.unknown.0"};
    for (unsigned i=0;i<sizeof(bad)/sizeof(*bad);i++) {
        assert(!SWDecodeRadioAction(bad[i],&radio,&value));
        assert(radio==9 && value==9);
    }
    assert(!SWDecodeRadioAction(NULL,&radio,&value));
    assert(!SWDecodeRadioAction("set.wifi.1",NULL,&value));
    assert(!SWBuildRadioPlan(SWWifi,1,NULL,&plan));
    puts("Radio tests passed: 128 explicit-target plans; selected-only setters; unknown peers; malformed command rejection.");
}
