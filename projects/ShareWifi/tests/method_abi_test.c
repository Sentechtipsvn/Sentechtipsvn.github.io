#include "SWMethodABI.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
    // Regression: the native hotspot property has a one-byte BOOL getter,
    // while the no-argument toggle ALSO returns BOOL, not void.
    assert(SWABIIsBooleanGetter("B",2,1));
    assert(SWABIIsBooleanGetter("c",2,1));
    assert(SWABIIsNoArgumentAction("B",2,1));
    assert(SWABIIsNoArgumentAction("c",2,1));
    assert(SWABIIsNoArgumentAction("v",2,0));
    // Wrong-width and object-returning APIs must never be invoked as BOOLs.
    assert(!SWABIIsBooleanGetter("Q",2,8));
    assert(!SWABIIsBooleanGetter("B",2,8));
    assert(!SWABIIsBooleanGetter("B",3,1));
    assert(!SWABIIsNoArgumentAction("@",2,8));
    assert(!SWABIIsNoArgumentAction("B",3,1));
    assert(!SWABIIsNoArgumentAction("v",2,8));
    assert(!SWABIIsNoArgumentAction(NULL,2,0));
    puts("PASS: hotspot BOOL getter/action regression and ABI rejection cases");
}
