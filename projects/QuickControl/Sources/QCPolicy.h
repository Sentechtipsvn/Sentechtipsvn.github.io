#ifndef QC_POLICY_H
#define QC_POLICY_H
#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include <math.h>
static inline double QCPosition(double y) {return !isfinite(y)?0.5:fmin(0.85,fmax(0.15,y));}
static inline bool QCRecent(double now,double updated,double maxAge) {
    double age=now-updated;return isfinite(age)&&age>=0&&age<maxAge;
}
static inline bool QCShouldInteract(bool locked,bool expanded,bool handleVisible,bool overHandle) {
    return !locked&&(expanded||(handleVisible&&overHandle));
}
static inline bool QCBoolType(const char *s) {return s && (!strcmp(s,"B")||!strcmp(s,"c"));}
static inline bool QCActionType(const char *s,size_t size) {return s && ((!strcmp(s,"v")&&!size)||(QCBoolType(s)&&size==1));}
static inline bool QCBundleValid(const char *s) {
    if(!s || !*s || strlen(s)>180)return false;
    bool dot=false;
    for(size_t i=0;s[i];i++) {
        char c=s[i];if(c=='.'){if(i==0||s[i+1]==0||s[i+1]=='.')return false;dot=true;}
        else if(!((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='-'))return false;
    }
    return dot;
}
static inline bool QCURLValid(const char *s) {
    if(!s || strlen(s)>2048)return false;
    size_t colon=0;
    for(size_t i=0;s[i];i++)if((unsigned char)s[i]<32 || (unsigned char)s[i]==127)return false;
    while(s[colon]&&s[colon]!=':')colon++;
    if(!colon || colon>40 || s[colon]!=':')return false;
    for(size_t i=0;i<colon;i++) {
        char c=s[i];bool letter=(c>='a'&&c<='z')||(c>='A'&&c<='Z');
        if(!letter && (i==0 || !((c>='0'&&c<='9')||c=='+'||c=='-'||c=='.')))return false;
    }
    char scheme[41]={0};for(size_t i=0;i<colon;i++)scheme[i]=(s[i]>='A'&&s[i]<='Z')?s[i]+32:s[i];
    return strcmp(scheme,"javascript")&&strcmp(scheme,"data")&&strcmp(scheme,"file");
}
#endif
