#import <Foundation/Foundation.h>
#import "QCPolicy.h"
static inline NSMethodSignature *QCSignature(id object,NSString *name,NSUInteger n) {
    SEL sel=NSSelectorFromString(name);
    if(!object||![object respondsToSelector:sel])return nil;
    NSMethodSignature *s=[object methodSignatureForSelector:sel];return s.numberOfArguments==n?s:nil;
}
static inline id QCObject(id object,NSString *name) {
    NSMethodSignature *s=QCSignature(object,name,2);if(!s||strcmp(s.methodReturnType,"@"))return nil;
    NSInvocation *i=[NSInvocation invocationWithMethodSignature:s];i.target=object;i.selector=NSSelectorFromString(name);[i invoke];
    __unsafe_unretained id result=nil;[i getReturnValue:&result];return result;
}
static inline BOOL QCLocked(void) {
    @try {
        id manager=QCObject(NSClassFromString(@"SBLockScreenManager"),@"sharedInstance");
        NSMethodSignature *s=QCSignature(manager,@"isUILocked",2);
        if(!s||!QCBoolType(s.methodReturnType)||s.methodReturnLength!=1)return YES;
        NSInvocation *i=[NSInvocation invocationWithMethodSignature:s];i.target=manager;i.selector=NSSelectorFromString(@"isUILocked");
        [i invoke];BOOL locked=YES;[i getReturnValue:&locked];return locked;
    } @catch(NSException *e){(void)e;return YES;}
}
// Some private headers disagree on void vs BOOL. Validate the runtime ABI;
// a void result means only that the launch request was submitted.
static inline BOOL QCLaunchBundle(NSString *bundle) {
    @try {
        id workspace=QCObject(NSClassFromString(@"LSApplicationWorkspace"),@"defaultWorkspace");
        NSMethodSignature *s=QCSignature(workspace,@"openApplicationWithBundleID:",3);
        if(!s||strcmp([s getArgumentTypeAtIndex:2],"@")||!QCActionType(s.methodReturnType,s.methodReturnLength))return NO;
        NSInvocation *i=[NSInvocation invocationWithMethodSignature:s];i.target=workspace;i.selector=NSSelectorFromString(@"openApplicationWithBundleID:");
        __unsafe_unretained NSString *argument=bundle;[i setArgument:&argument atIndex:2];[i invoke];
        if(!strcmp(s.methodReturnType,"v"))return YES;
        BOOL result=NO;[i getReturnValue:&result];return result;
    } @catch(NSException *e){(void)e;return NO;}
}
