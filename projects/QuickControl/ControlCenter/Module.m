#import <ControlCenterUIKit/CCUIToggleModule.h>
#import "QCCommon.h"
@interface QCModule : CCUIToggleModule
@property(nonatomic) NSTimeInterval lastTap;
@end
static void QCModuleUpdate(CFNotificationCenterRef center,void *observer,CFStringRef name,const void *object,CFDictionaryRef info) {
    (void)center;(void)name;(void)object;(void)info;
    QCModule *module=(__bridge QCModule *)observer;dispatch_async(dispatch_get_main_queue(),^{[module refreshState];});
}
@implementation QCModule
- (instancetype)init {
    if((self=[super init]))CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge void *)self,QCModuleUpdate,QC_STATUS,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    return self;
}
- (void)dealloc {CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge void *)self);}
- (UIImage *)iconGlyph {return [UIImage systemImageNamed:@"square.grid.2x2.fill"];}
- (UIImage *)selectedIconGlyph {return [self iconGlyph];}
- (UIColor *)selectedColor {return QCGreen();}
- (BOOL)isSelected {return [QCRead(@"status.plist")[@"visible"]boolValue];}
- (void)setSelected:(BOOL)selected {
    (void)selected;double now=NSDate.date.timeIntervalSince1970;if(now-self.lastTap<0.6)return;self.lastTap=now;QCNotify(QC_TOGGLE);[super refreshState];
}
@end
