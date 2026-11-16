// Copyright (c) 2026 Sentechtipsvn. MIT License.
// Intentionally confined to SpringBoard. No device spoofing or UIKit layout hooks.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/utsname.h>
#import <string.h>
#import <stdlib.h>

extern void MSHookMessageEx(Class cls, SEL selector, IMP replacement, IMP *original);

static CFStringRef const SENSPreferenceDomain = CFSTR("vn.sentechtips.senswipe");
static BOOL SENSActive = NO;
static BOOL SENSControlCenterEnabled = YES;
static BOOL SENSShowHomeBar = NO;

typedef BOOL (*SENSBoolGetter)(id, SEL);
typedef unsigned long long (*SENSIntegerGetter)(id, SEL);
static SENSBoolGetter originalHomeGesture;
static SENSBoolGetter originalHomeGrabber;
static SENSIntegerGetter originalCCPresentation;
static SENSIntegerGetter originalCCEdge;

static BOOL SENSPreference(CFStringRef key, BOOL fallback) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(key, SENSPreferenceDomain);
    if (!value) return fallback;
    BOOL result = fallback;
    if (CFGetTypeID(value) == CFBooleanGetTypeID()) {
        result = CFBooleanGetValue((CFBooleanRef)value);
    }
    CFRelease(value);
    return result;
}

static BOOL SENSIsSupportedDevice(void) {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        return NO;
    }
    NSOperatingSystemVersion version = NSProcessInfo.processInfo.operatingSystemVersion;
    if (version.majorVersion != 15 || version.minorVersion != 8 || version.patchVersion != 8) {
        NSLog(@"[SenSwipe] Inactive: this beta targets iOS 15.8.8 only.");
        return NO;
    }
    struct utsname hardware;
    if (uname(&hardware) != 0) return NO;
    BOOL supported = strcmp(hardware.machine, "iPhone9,2") == 0 ||
                     strcmp(hardware.machine, "iPhone9,4") == 0;
    if (!supported) NSLog(@"[SenSwipe] Inactive: this beta targets iPhone 7 Plus only.");
    return supported;
}

// Method existence alone is insufficient: a changed ABI can corrupt registers.
// Accept Objective-C BOOL encodings and ABI-compatible 64-bit integers.
static BOOL SENSValidateGetter(const char *className, const char *selectorName,
                               BOOL booleanResult, Class *outClass, SEL *outSelector) {
    Class cls = objc_getClass(className);
    SEL selector = sel_registerName(selectorName);
    Method method = cls ? class_getInstanceMethod(cls, selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != 2) {
        NSLog(@"[SenSwipe] Inactive: missing getter %s.%s.", className, selectorName);
        return NO;
    }
    char *returnType = method_copyReturnType(method);
    char *selfType = method_copyArgumentType(method, 0);
    char *selectorType = method_copyArgumentType(method, 1);
    BOOL validReturn = returnType && (booleanResult ?
        (strcmp(returnType, "B") == 0 || strcmp(returnType, "c") == 0) :
        (strcmp(returnType, "Q") == 0 || strcmp(returnType, "q") == 0));
    BOOL valid = validReturn && selfType && strcmp(selfType, "@") == 0 &&
                 selectorType && strcmp(selectorType, ":") == 0;
    free(returnType);
    free(selfType);
    free(selectorType);
    if (!valid) {
        NSLog(@"[SenSwipe] Inactive: unexpected signature %s.%s.", className, selectorName);
        return NO;
    }
    *outClass = cls;
    *outSelector = selector;
    return YES;
}

static BOOL SENSHomeGesture(id object, SEL selector) {
    return SENSActive ? YES : (originalHomeGesture ? originalHomeGesture(object, selector) : NO);
}

static BOOL SENSHomeGrabber(id object, SEL selector) {
    return SENSActive ? SENSShowHomeBar : (originalHomeGrabber ? originalHomeGrabber(object, selector) : NO);
}

static unsigned long long SENSCCPresentation(id object, SEL selector) {
    return (SENSActive && SENSControlCenterEnabled) ? 1ULL :
        (originalCCPresentation ? originalCCPresentation(object, selector) : 0ULL);
}

static unsigned long long SENSCCEdge(id object, SEL selector) {
    return (SENSActive && SENSControlCenterEnabled) ? 1ULL :
        (originalCCEdge ? originalCCEdge(object, selector) : 4ULL);
}

__attribute__((constructor)) static void SENSInitialize(void) {
    @autoreleasepool {
        if (!SENSIsSupportedDevice()) return;
        CFPreferencesAppSynchronize(SENSPreferenceDomain);
        if (!SENSPreference(CFSTR("Enabled"), YES)) {
            NSLog(@"[SenSwipe] Disabled in preferences. No hooks installed.");
            return;
        }
        // Settings are a startup snapshot; changes deliberately require respring.
        SENSControlCenterEnabled = SENSPreference(CFSTR("ControlCenterEnabled"), YES);
        SENSShowHomeBar = SENSPreference(CFSTR("ShowHomeBar"), NO);

        Class gestureClass, grabberClass, ccDefaultsClass = Nil, ccControllerClass = Nil;
        SEL gestureSelector, grabberSelector, ccDefaultsSelector = NULL, ccEdgeSelector = NULL;
        // Preflight every requested hook before changing any behavior.
        if (!SENSValidateGetter("SBHomeGestureSettings", "isHomeGestureEnabled", YES,
                                &gestureClass, &gestureSelector) ||
            !SENSValidateGetter("SBFHomeGrabberSettings", "isEnabled", YES,
                                &grabberClass, &grabberSelector)) return;
        if (SENSControlCenterEnabled &&
            (!SENSValidateGetter("CCSControlCenterDefaults", "_defaultPresentationGesture", NO,
                                 &ccDefaultsClass, &ccDefaultsSelector) ||
             !SENSValidateGetter("SBControlCenterController", "presentingEdge", NO,
                                 &ccControllerClass, &ccEdgeSelector))) return;

        MSHookMessageEx(gestureClass, gestureSelector, (IMP)SENSHomeGesture,
                        (IMP *)&originalHomeGesture);
        MSHookMessageEx(grabberClass, grabberSelector, (IMP)SENSHomeGrabber,
                        (IMP *)&originalHomeGrabber);
        if (SENSControlCenterEnabled) {
            MSHookMessageEx(ccDefaultsClass, ccDefaultsSelector, (IMP)SENSCCPresentation,
                            (IMP *)&originalCCPresentation);
            MSHookMessageEx(ccControllerClass, ccEdgeSelector, (IMP)SENSCCEdge,
                            (IMP *)&originalCCEdge);
        }
        // ElleKit/Substrate must supply valid originals before activation.
        SENSActive = originalHomeGesture && originalHomeGrabber &&
            (!SENSControlCenterEnabled || (originalCCPresentation && originalCCEdge));
        NSLog(@"[SenSwipe] 0.1.0 beta 1: active=%d, top-right CC=%d, home bar=%d.",
               SENSActive, SENSControlCenterEnabled, SENSShowHomeBar);
    }
}
