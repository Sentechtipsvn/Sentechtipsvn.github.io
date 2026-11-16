#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "SWCommon.h"
#import "SWHapticMenu.h"

extern void MSHookMessageEx(Class, SEL, IMP, IMP *);
static NSString *const SWMenuPrefix=@"vn.sentechtips.sharewifi.radio.";
static NSDictionary *(^SWMenuPowers)(void);
static void (^SWMenuPerform)(NSString *);
static id (*SWOriginalItems)(id,SEL);
static void (*SWOriginalActivate)(id,SEL,id,id,id);
static void (*SWOriginalProviderActivate)(id,SEL,id,id,id);

static BOOL SWMenuMethod(Method method, char result, unsigned objectArguments) {
    if (!method || method_getNumberOfArguments(method)!=objectArguments+2) return NO;
    char *type=method_copyReturnType(method);
    BOOL valid=type && type[0]==result && (result=='@' || type[1]=='\0');free(type);
    for(unsigned i=2; valid && i<objectArguments+2; i++) {
        type=method_copyArgumentType(method,i);valid=type && type[0]=='@' && type[1]!='?';free(type);
    }
    return valid;
}
static id SWMenuObject(id object, NSString *name) {
    SEL selector=NSSelectorFromString(name);
    if(!object || ![object respondsToSelector:selector] || !SWMenuMethod(class_getInstanceMethod([object class],selector),'@',0))return nil;
    NSInvocation *call=[NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:selector]];
    call.target=object;call.selector=selector;[call invoke];
    __unsafe_unretained id result=nil;[call getReturnValue:&result];return result;
}
static BOOL SWMenuSetObject(id object, NSString *name, id value) {
    SEL selector=NSSelectorFromString(name);
    if(!object || !SWMenuMethod(class_getInstanceMethod([object class],selector),'v',1))return NO;
    NSInvocation *call=[NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:selector]];
    call.target=object;call.selector=selector;[call setArgument:&value atIndex:2];[call invoke];return YES;
}
static NSString *SWMenuBundle(id view) {
    for(NSString *name in @[@"applicationBundleIdentifier",@"applicationBundleIdentifierForShortcuts"]) {
        id bundle=SWMenuObject(view,name);if([bundle isKindOfClass:NSString.class])return bundle;
    }
    id bundle=SWMenuObject(SWMenuObject(view,@"icon"),@"applicationBundleID");
    return [bundle isKindOfClass:NSString.class]?bundle:nil;
}

@interface NSObject (SWPrivateShortcutSymbol)
- (instancetype)initWithSystemImageName:(NSString *)name;
@end

static id SWMenuItems(id view, SEL selector) {
    id original=SWOriginalItems?SWOriginalItems(view,selector):nil;
    @try {
        if(!SWHapticEnabled() || ![SWMenuBundle(view) isEqual:SW_BUNDLE])return original;
        if(original && ![original isKindOfClass:NSArray.class])return original;
        NSDictionary *powers=SWMenuPowers?SWMenuPowers():@{};
        NSMutableArray *items=[NSMutableArray array];
        Class itemClass=NSClassFromString(@"SBSApplicationShortcutItem");
        for(NSString *key in SWRadioKeys()) {
            if(!SWShowHapticRadio(key))continue;
            id power=powers[key];BOOL known=[power isKindOfClass:NSNumber.class];
            NSString *action=known?SWRadioCommand(key,![power boolValue]):[@"refresh." stringByAppendingString:key];
            NSString *title=known?[NSString stringWithFormat:@"%@ %@",[power boolValue]?@"Tắt":@"Bật",SWRadioName(key)]:
                [NSString stringWithFormat:@"%@ · Làm mới trạng thái",SWRadioName(key)];
            id item=[itemClass new];
            if(!SWMenuSetObject(item,@"setType:",[SWMenuPrefix stringByAppendingString:action]) ||
               !SWMenuSetObject(item,@"setLocalizedTitle:",title) ||
               !SWMenuSetObject(item,@"setBundleIdentifierToLaunch:",SW_BUNDLE))return original;
            SWMenuSetObject(item,@"setLocalizedSubtitle:",SWPowerText(power));
            Class symbolClass=NSClassFromString(@"SBSApplicationShortcutSystemIcon");
            if(SWMenuMethod(class_getInstanceMethod(symbolClass,@selector(initWithSystemImageName:)),'@',1)) {
                id symbol=[[symbolClass alloc] initWithSystemImageName:SWRadioSymbol(key)];
                if(symbol)SWMenuSetObject(item,@"setIcon:",symbol);
            }
            [items addObject:item];
        }
        // Retain all four established shortcuts and the system's edit/remove actions.
        for(id item in original) {
            id type=SWMenuObject(item,@"type");
            if(![type isKindOfClass:NSString.class] || ![type hasPrefix:SWMenuPrefix])[items addObject:item];
        }
        return items;
    } @catch(NSException *exception) { (void)exception;return original; }
}
static BOOL SWHandleMenuShortcut(id item, id bundle, id view) {
    @try {
        BOOL target=[bundle isKindOfClass:NSString.class]?[bundle isEqual:SW_BUNDLE]:[SWMenuBundle(view) isEqual:SW_BUNDLE];
        NSString *type=SWMenuObject(item,@"type");
        if(!target || ![type isKindOfClass:NSString.class] || ![type hasPrefix:SWMenuPrefix])return NO;
        if(!SWHapticEnabled())return YES;
        NSString *action=[type substringFromIndex:SWMenuPrefix.length];
        int radio,value;
        if(SWDecodeRadioAction(action.UTF8String,&radio,&value)) {
            if(SWShowHapticRadio(SWRadioKeys()[radio]) && SWMenuPerform) {
                [[UISelectionFeedbackGenerator new] selectionChanged];SWMenuPerform(action);
            }
        } else if([action hasPrefix:@"refresh."] && SWMenuPerform)SWMenuPerform(@"refresh");
        return YES;
    } @catch(NSException *exception) { (void)exception;return NO; }
}
static void SWActivate(id cls,SEL selector,id item,id bundle,id view) {
    if(!SWHandleMenuShortcut(item,bundle,view) && SWOriginalActivate)SWOriginalActivate(cls,selector,item,bundle,view);
}
static void SWProviderActivate(id cls,SEL selector,id item,id bundle,id view) {
    if(!SWHandleMenuShortcut(item,bundle,view) && SWOriginalProviderActivate)SWOriginalProviderActivate(cls,selector,item,bundle,view);
}

BOOL SWInstallHapticMenu(NSDictionary *(^powers)(void), void (^perform)(NSString *)) {
    Class view=NSClassFromString(@"SBIconView"),item=NSClassFromString(@"SBSApplicationShortcutItem");
    SEL getter=NSSelectorFromString(@"applicationShortcutItems");
    SEL activate=NSSelectorFromString(@"activateShortcut:withBundleIdentifier:forIconView:");
    Class provider=NSClassFromString(@"SBHIconViewApplicationShortcutsContextMenuProvider");
    BOOL canView=SWMenuMethod(class_getClassMethod(view,activate),'v',3);
    BOOL canProvider=SWMenuMethod(class_getClassMethod(provider,activate),'v',3);
    if(!powers || !perform || !SWMenuMethod(class_getInstanceMethod(view,getter),'@',0) || (!canView && !canProvider))return NO;
    for(NSString *name in @[@"setType:",@"setLocalizedTitle:",@"setBundleIdentifierToLaunch:"])
        if(!SWMenuMethod(class_getInstanceMethod(item,NSSelectorFromString(name)),'v',1))return NO;
    SWMenuPowers=[powers copy];SWMenuPerform=[perform copy];
    if(canView)MSHookMessageEx(object_getClass(view),activate,(IMP)SWActivate,(IMP *)&SWOriginalActivate);
    if(canProvider)MSHookMessageEx(object_getClass(provider),activate,(IMP)SWProviderActivate,(IMP *)&SWOriginalProviderActivate);
    if(!SWOriginalActivate && !SWOriginalProviderActivate)return NO;
    MSHookMessageEx(view,getter,(IMP)SWMenuItems,(IMP *)&SWOriginalItems);
    return SWOriginalItems!=NULL;
}
