#import <UIKit/UIKit.h>
#import <ControlCenterUIKit/CCUIToggleModule.h>
#import "SWCommon.h"

@interface SWControlCenterModule : CCUIToggleModule
@property(nonatomic) NSTimeInterval lastTap;
@end

static void SWModuleStatus(CFNotificationCenterRef center,void *observer,CFStringRef name,const void *object,CFDictionaryRef userInfo) {
    (void)center;(void)name;(void)object;(void)userInfo;
    // Retain until the queued UI refresh finishes; observer is removed on dealloc.
    SWControlCenterModule *module=(__bridge SWControlCenterModule *)observer;
    dispatch_async(dispatch_get_main_queue(),^{[module refreshState];});
}

@implementation SWControlCenterModule
- (instancetype)init {
    if((self=[super init])) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge void *)self,SWModuleStatus,SW_STATUS,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),SW_REFRESH,NULL,NULL,YES);
    }
    return self;
}
- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge void *)self);
}
- (UIImage *)iconGlyph { return [UIImage systemImageNamed:@"personalhotspot"]; }
- (UIImage *)selectedIconGlyph { return [self iconGlyph]; }
- (UIColor *)selectedColor { return [UIColor colorWithRed:0.13 green:0.65 blue:0.36 alpha:1]; }
- (BOOL)isSelected {
    NSDictionary *status=SWRead(@"status.plist");
    return NSDate.date.timeIntervalSince1970-[status[@"updated"] doubleValue]<90 && [status[@"powers"][@"hotspot"] isEqual:@YES];
}
- (void)setSelected:(BOOL)selected {
    (void)selected;
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(now-self.lastTap<0.8 || [SWRead(@"status.plist")[@"busy"]boolValue])return;
    self.lastTap=now;
    // Backend re-reads actual radios, applies the configured stop mode, and
    // publishes readback. The module never assumes a command has succeeded.
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),SW_CC_TOGGLE,NULL,NULL,YES);
    [super refreshState];
}
@end
