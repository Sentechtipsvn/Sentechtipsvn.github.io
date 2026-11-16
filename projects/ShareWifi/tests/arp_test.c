#include "SWArp.h"
#include <assert.h>
#include <string.h>
#include <stdio.h>
static int calls;
static void got(void *ctx,uint16_t index,const uint8_t ip[4],const uint8_t mac[6],int32_t expiry) {
    (void)ctx;assert(index==8);assert(ip[0]==172&&ip[3]==2);assert(mac[0]==0x22&&mac[5]==0x66);assert(expiry==1234);calls++;
}
static void fixture(uint8_t p[128]) {
    memset(p,0,128);p[0]=128;p[2]=5;p[4]=8;p[9]=4;p[12]=3;
    p[48]=0xd2;p[49]=4;
    p[92]=16;p[93]=2;p[96]=172;p[97]=20;p[98]=10;p[99]=2;
    p[108]=20;p[109]=18;p[110]=8;p[113]=3;p[114]=6;
    memcpy(p+116,"ap1",3);
    uint8_t mac[]={0x22,0x33,0x44,0x55,0x55,0x66};memcpy(p+119,mac,6);
}
int main(void) {
    uint8_t p[256];fixture(p);calls=0;
    assert(SWParseArp(p,128,got,NULL)==1&&calls==1);
    fixture(p+128);assert(SWParseArp(p,256,got,NULL)==2);
    assert(SWParseArp(p,127,got,NULL)==-1);
    p[0]=0;assert(SWParseArp(p,128,got,NULL)==-1);
    fixture(p);p[113]=250;assert(SWParseArp(p,128,got,NULL)==0);
    fixture(p);p[119]|=1;assert(SWParseArp(p,128,got,NULL)==0);
    fixture(p);p[108]=1;assert(SWParseArp(p,128,got,NULL)==-1);
    fixture(p);p[12]|=4;assert(SWParseArp(p,128,got,NULL)==-1);
    fixture(p);p[2]=99;assert(SWParseArp(p,128,got,NULL)==0);
    assert(SWParseArp(NULL,0,got,NULL)==0);
    puts("PASS: ARP stream framing, named-interface padding, batch rows, truncation, invalid MAC, malformed sockaddr, unknown ABI");
}
