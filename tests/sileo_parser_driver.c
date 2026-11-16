/* Test adapter for the unchanged Sileo 2.5.1 C parser. No iOS code is run. */
#include <stdio.h>
#include <stdlib.h>
#include "ControlFileParserFast.h"
/* Only non-capturing global blocks are used; no BlocksRuntime calls needed. */
void *_NSConcreteGlobalBlock[32];
static void emit_string(const char *p) {
    putchar('"');
    for (;*p;p++) {
        unsigned char c=(unsigned char)*p;
        if (c=='"'||c=='\\') {putchar('\\');putchar(c);}
        else if(c<32) printf("\\u%04x",c);
        else putchar(c);
    }
    putchar('"');
}
int main(int argc,char **argv) {
    if(argc!=3)return 2;
    FILE *f=fopen(argv[1],"rb");if(!f)return 3;
    if(fseek(f,0,SEEK_END))return 4;
    long size=ftell(f);if(size<0 || size>16000000)return 5;
    rewind(f);unsigned char *data=calloc((size_t)size+16,1);if(!data)return 6;
    if(fread(data,1,(size_t)size,f)!=(size_t)size)return 7;
    fclose(f);
    parseControlFile(data,(size_t)size,argv[2][0]=='1',^(const char *key,const char *value) {
        putchar('[');emit_string(key);putchar(',');emit_string(value);puts("]");
    },^(int tags){(void)tags;});
    free(data);return 0;
}
