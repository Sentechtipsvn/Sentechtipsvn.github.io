#include "QCPolicy.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    assert(QCPosition(NAN)==0.5);assert(QCPosition(INFINITY)==0.5);
    assert(QCPosition(-200)==0.15);assert(QCPosition(20)==0.85);assert(QCPosition(.4)==.4);
    for(int lock=0;lock<2;lock++)for(int open=0;open<2;open++)for(int visible=0;visible<2;visible++)for(int over=0;over<2;over++) {
        bool allowed=QCShouldInteract(lock,open,visible,over);
        if(lock)assert(!allowed);
        else if(open)assert(allowed);
        else assert(allowed==(visible&&over));
    }
    assert(QCRecent(100,99,90));assert(!QCRecent(100,10,90));assert(!QCRecent(100,101,90));
    assert(!QCRecent(NAN,99,90));assert(!QCRecent(100,INFINITY,90));
    assert(QCBundleValid("com.apple.mobilenotes"));assert(QCBundleValid("vn.sentechtips.sharewifi"));
    const char *badBundles[]={"",NULL,"bad", ".bad.app","bad.app.","bad..app","app;id","app/id.test","com.app\n"};
    for(unsigned i=0;i<sizeof(badBundles)/sizeof(*badBundles);i++)assert(!QCBundleValid(badBundles[i]));
    const char *goodURLs[]={"quickcontrol://qr","https://example.com/a?x=1&y=2","App-Prefs:root=WIFI","my-app.v2://action"};
    const char *badURLs[]={"",NULL,"example.com",":nothing","1a://x","JavaScript:alert(1)","data:text/plain,x","FILE:///tmp/x","a://x\nsecret"};
    for(unsigned i=0;i<sizeof(goodURLs)/sizeof(*goodURLs);i++)assert(QCURLValid(goodURLs[i]));
    for(unsigned i=0;i<sizeof(badURLs)/sizeof(*badURLs);i++)assert(!QCURLValid(badURLs[i]));
    char longURL[2051];memset(longURL,'x',2050);memcpy(longURL,"a:",2);longURL[2050]=0;assert(!QCURLValid(longURL));
    assert(QCBoolType("B")&&QCBoolType("c"));assert(!QCBoolType("@"));assert(!QCBoolType(NULL));
    assert(QCActionType("v",0));assert(QCActionType("B",1));assert(QCActionType("c",1));
    assert(!QCActionType("v",1));assert(!QCActionType("B",8));assert(!QCActionType("@",8));assert(!QCActionType(NULL,0));
    // Parser robustness over arbitrary byte strings (including high UTF-8 bytes).
    unsigned seed=17;
    for(unsigned n=0;n<10000;n++) {
        char s[97];unsigned length=n%96;
        for(unsigned i=0;i<length;i++){seed=seed*1664525u+1013904223u;s[i]=(char)(seed>>24);}
        s[length]=0;(void)QCBundleValid(s);(void)QCURLValid(s);
    }
    puts("PASS: touch/lock gating; stale state; position; URL/bundle validation; BOOL/void ABI; 10,000 malformed strings.");
}
