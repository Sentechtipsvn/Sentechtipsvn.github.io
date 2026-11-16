#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>
#import <notify.h>
#import <sys/utsname.h>
#import "QCCommon.h"
#import "QCRuntime.h"

@class QCOverlay;
static QCOverlay *overlay;
@interface QCWindow : UIWindow
@property(nonatomic,weak) QCOverlay *panel;
@end
@interface QCOverlay : UIViewController
@property(nonatomic,strong) QCWindow *window;
@property(nonatomic,strong) UIControl *backdrop;
@property(nonatomic,strong) UIView *handle;
@property(nonatomic,strong) UIVisualEffectView *card;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) UIStackView *stack;
@property(nonatomic,strong) UILabel *message;
@property(nonatomic,strong) NSMutableArray<UIButton *> *tiles;
@property(nonatomic,strong) NSArray *items;
@property(nonatomic,strong) NSDictionary *settings;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic) BOOL expanded;
@property(nonatomic) BOOL animating;
@property(nonatomic) BOOL openedByPan;
@property(nonatomic) BOOL dragging;
@property(nonatomic) CGFloat dragStart;
@property(nonatomic) double position;
@property(nonatomic) NSTimeInterval lastTap;
- (void)start;
- (void)reloadSettings;
- (void)toggle;
- (void)close;
- (void)syncVisibility;
- (BOOL)accepts:(CGPoint)point;
@end
@implementation QCWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {(void)event;return [self.panel accepts:point];}
@end
@implementation QCOverlay
- (void)loadView {
    self.view=[[UIView alloc]initWithFrame:UIScreen.mainScreen.bounds];self.view.backgroundColor=UIColor.clearColor;
    self.backdrop=[UIControl new];self.backdrop.backgroundColor=[UIColor colorWithWhite:0 alpha:0.20];
    [self.backdrop addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backdrop];self.backdrop.hidden=YES;
    self.card=[[UIVisualEffectView alloc]initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
    self.card.layer.cornerRadius=28;self.card.clipsToBounds=YES;
    self.card.layer.borderWidth=0.5;self.card.layer.borderColor=[QCGreen() colorWithAlphaComponent:0.24].CGColor;
    [self.view addSubview:self.card];self.card.hidden=YES;
    self.scroll=[UIScrollView new];self.scroll.translatesAutoresizingMaskIntoConstraints=NO;
    [self.card.contentView addSubview:self.scroll];
    self.stack=[UIStackView new];self.stack.axis=UILayoutConstraintAxisVertical;self.stack.spacing=12;self.stack.translatesAutoresizingMaskIntoConstraints=NO;
    [self.scroll addSubview:self.stack];
    [NSLayoutConstraint activateConstraints:@[
        [self.scroll.leadingAnchor constraintEqualToAnchor:self.card.contentView.leadingAnchor],
        [self.scroll.trailingAnchor constraintEqualToAnchor:self.card.contentView.trailingAnchor],
        [self.scroll.topAnchor constraintEqualToAnchor:self.card.contentView.topAnchor],
        [self.scroll.bottomAnchor constraintEqualToAnchor:self.card.contentView.bottomAnchor],
        [self.stack.topAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.topAnchor constant:18],
        [self.stack.bottomAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.bottomAnchor constant:-18],
        [self.stack.leadingAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.leadingAnchor constant:16],
        [self.stack.trailingAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.trailingAnchor constant:-16]]];
    self.handle=[UIView new];self.handle.accessibilityLabel=@"Mở QuickControl";self.handle.accessibilityTraits=UIAccessibilityTraitButton;self.handle.isAccessibilityElement=YES;
    UIView *pill=[UIView new];pill.tag=70;pill.backgroundColor=[QCGreen()colorWithAlphaComponent:0.82];pill.layer.cornerRadius=3;
    [self.handle addSubview:pill];[self.view addSubview:self.handle];
    [self.handle addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggle)]];
    [self.handle addGestureRecognizer:[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)]];
}
- (BOOL)accessibilityPerformMagicTap {[self toggle];return YES;}
- (void)start {
    self.window=[[QCWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];self.window.panel=self;
    self.window.windowLevel=UIWindowLevelAlert+1;self.window.backgroundColor=UIColor.clearColor;
    self.window.rootViewController=self;self.window.hidden=YES;
    [self reloadSettings];
    self.timer=[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}
- (BOOL)accepts:(CGPoint)point {
    return QCShouldInteract(QCLocked(),self.expanded,!self.handle.hidden,CGRectContainsPoint(self.handle.frame,point));
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect b=self.view.bounds;UIEdgeInsets safe=self.view.safeAreaInsets;
    CGFloat top=MAX(safe.top,28)+12,bottom=MAX(safe.bottom,16)+12;
    CGFloat range=MAX(1,b.size.height-top-bottom-72);
    BOOL right=QCRight(self.settings);
    self.handle.frame=CGRectMake(right?b.size.width-22:0,top+range*self.position,22,72);
    [self.handle viewWithTag:70].frame=CGRectMake(right?12:4,8,6,56);
    self.backdrop.frame=b;
    CGFloat width=MIN(356,b.size.width-28),height=MIN(b.size.height-top-bottom,180+ceil(self.items.count/2.0)*90);
    height=MAX(190,height);
    CGFloat y=MIN(MAX(top,CGRectGetMidY(self.handle.frame)-height/2),b.size.height-bottom-height);
    self.card.frame=CGRectMake(right?b.size.width-width-14:14,y,width,height);
}
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self close];[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}
- (void)reloadSettings {
    [self loadViewIfNeeded];
    self.settings=QCRead(@"settings.plist");self.position=QCStoredPosition(self.settings);self.items=QCItems(self.settings);
    for(UIView *v in self.stack.arrangedSubviews){[self.stack removeArrangedSubview:v];[v removeFromSuperview];}
    self.tiles=[NSMutableArray array];
    UIStackView *header=[UIStackView new];header.axis=UILayoutConstraintAxisHorizontal;header.alignment=UIStackViewAlignmentCenter;
    UILabel *title=[UILabel new];title.text=@"QuickControl";title.font=[UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];[close setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    close.accessibilityLabel=@"Đóng khay";close.tintColor=UIColor.secondaryLabelColor;[close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [close.widthAnchor constraintEqualToConstant:44].active=YES;[close.heightAnchor constraintEqualToConstant:44].active=YES;
    [header addArrangedSubview:title];[header addArrangedSubview:close];[self.stack addArrangedSubview:header];
    for(NSUInteger row=0;row<self.items.count;row+=2) {
        UIStackView *line=[UIStackView new];line.axis=UILayoutConstraintAxisHorizontal;line.spacing=10;line.distribution=UIStackViewDistributionFillEqually;
        for(NSUInteger i=row;i<MIN(row+2,self.items.count);i++) {
            NSDictionary *item=self.items[i];UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];button.tag=(NSInteger)i;
            button.layer.cornerRadius=18;button.backgroundColor=[QCGreen()colorWithAlphaComponent:0.10];button.tintColor=QCGreen();
            UIButtonConfiguration *c=UIButtonConfiguration.plainButtonConfiguration;c.image=[UIImage systemImageNamed:item[@"symbol"]]?:[UIImage systemImageNamed:@"square.grid.2x2"];
            c.imagePlacement=NSDirectionalRectEdgeTop;c.imagePadding=8;c.title=item[@"title"];c.baseForegroundColor=QCGreen();
            c.contentInsets=NSDirectionalEdgeInsetsMake(12,6,12,6);button.configuration=c;
            button.titleLabel.numberOfLines=2;button.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
            [button.heightAnchor constraintGreaterThanOrEqualToConstant:82].active=YES;
            [button addTarget:self action:@selector(tile:) forControlEvents:UIControlEventTouchUpInside];
            [line addArrangedSubview:button];[self.tiles addObject:button];
        }
        if(line.arrangedSubviews.count==1)[line addArrangedSubview:[UIView new]];
        [self.stack addArrangedSubview:line];
    }
    self.message=[UILabel new];self.message.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];self.message.numberOfLines=0;self.message.textColor=UIColor.secondaryLabelColor;
    self.message.text=@"Chọn tiện ích · Kéo tay nắm lên/xuống để đổi vị trí";[self.stack addArrangedSubview:self.message];
    UIButton *configure=[UIButton buttonWithType:UIButtonTypeSystem];[configure setTitle:@"Tùy chỉnh QuickControl  ›" forState:UIControlStateNormal];configure.tintColor=QCGreen();
    [configure.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;[configure addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];[self.stack addArrangedSubview:configure];
    [self.view setNeedsLayout];[self syncVisibility];[self updateShareWifi];
}
- (void)publish {
    QCWrite(@{@"version":QC_VERSION,@"updated":@(NSDate.date.timeIntervalSince1970),@"visible":@(self.expanded),@"locked":@(QCLocked()),@"enabled":@(QCEnabled(self.settings))},@"status.plist");QCNotify(QC_STATUS);
}
- (void)syncVisibility {
    BOOL locked=QCLocked();
    if(locked||!QCEnabled(self.settings)) {
        self.expanded=NO;self.animating=NO;self.card.hidden=YES;self.card.transform=CGAffineTransformIdentity;
        self.backdrop.hidden=YES;self.window.hidden=YES;
    }else {self.window.hidden=NO;self.handle.hidden=self.expanded;}
}
- (void)tick {
    BOOL wasVisible=self.expanded;[self syncVisibility];
    if(wasVisible&&!self.expanded)[self publish];
    if(self.expanded){QCNotify(CFSTR("vn.sentechtips.sharewifi.refresh"));[self updateShareWifi];}
}
- (void)toggle {
    if(self.expanded){[self close];return;}
    [self syncVisibility];if(self.animating||QCLocked()||!QCEnabled(self.settings))return;
    self.expanded=YES;self.handle.hidden=YES;self.card.hidden=NO;self.backdrop.hidden=NO;self.animating=YES;
    [self.view setNeedsLayout];[self.view layoutIfNeeded];
    self.card.alpha=0;self.backdrop.alpha=0;self.card.transform=CGAffineTransformMakeTranslation(QCRight(self.settings)?32:-32,0);
    [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled()?0:0.22 animations:^{self.card.alpha=1;self.backdrop.alpha=1;self.card.transform=CGAffineTransformIdentity;} completion:^(__unused BOOL done){self.animating=NO;}];
    QCNotify(CFSTR("vn.sentechtips.sharewifi.refresh"));[self updateShareWifi];[self publish];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,self.card);
}
- (void)close {
    if(!self.expanded)return;self.expanded=NO;self.card.hidden=YES;self.backdrop.hidden=YES;self.handle.hidden=NO;self.animating=NO;
    [self syncVisibility];[self publish];
}
- (void)pan:(UIPanGestureRecognizer *)g {
    CGPoint t=[g translationInView:self.view];
    if(g.state==UIGestureRecognizerStateBegan){self.dragStart=self.position;self.openedByPan=NO;self.dragging=YES;}
    if(g.state==UIGestureRecognizerStateChanged&&!self.openedByPan) {
        BOOL inward=QCRight(self.settings)?t.x < -24:t.x>24;
        if(inward&&fabs(t.x)>fabs(t.y)*1.3){self.openedByPan=YES;[self toggle];}
        else if(fabs(t.y)>fabs(t.x)) {
            self.position=QCPosition(self.dragStart+t.y/MAX(1,self.view.bounds.size.height-132));[self.view setNeedsLayout];
        }
    }
    if(g.state==UIGestureRecognizerStateEnded||g.state==UIGestureRecognizerStateCancelled||g.state==UIGestureRecognizerStateFailed) {
        self.dragging=NO;
        if(!self.openedByPan) {
            NSMutableDictionary *s=[QCRead(@"settings.plist")mutableCopy];s[@"position"]=@(self.position);
            QCWrite(s,@"settings.plist");self.settings=s;
        }
    }
}
- (void)updateShareWifi {
    NSDictionary *s=QCSWStatus();BOOL fresh=QCSWFresh(s),on=[s[@"powers"]isKindOfClass:NSDictionary.class]&&[s[@"powers"][@"hotspot"]isEqual:@YES];
    for(UIButton *b in self.tiles)if([self.items[(NSUInteger)b.tag][@"kind"]isEqual:@"sharewifi"]) {
        UIButtonConfiguration *c=b.configuration;
        c.subtitle=fresh?([s[@"busy"]boolValue]?@"Đang xử lý…":(on?@"Đang bật":@"Đang tắt")):@"Mở ShareWifi";
        b.configuration=c;b.backgroundColor=[QCGreen()colorWithAlphaComponent:fresh&&on?0.23:0.10];
        b.enabled=!fresh||![s[@"busy"]boolValue];
    }
}
- (void)alert:(NSString *)text {
    if(QCLocked())return;
    if(!self.expanded)[self toggle];self.message.text=text;
}
- (void)launch:(NSString *)bundle {
    if(QCLocked())return;[self close];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        BOOL requested=QCLaunchBundle(bundle);
        if(!requested)dispatch_async(dispatch_get_main_queue(),^{[self alert:@"Chưa mở được ứng dụng. Kiểm tra ứng dụng đã cài và Bundle ID trong Tùy chỉnh."];});
    });
}
- (void)openSettings {[self launch:QC_BUNDLE];}
- (void)tile:(UIButton *)sender {
    if(QCLocked()||NSDate.date.timeIntervalSince1970-self.lastTap<0.5)return;
    self.lastTap=NSDate.date.timeIntervalSince1970;
    if(sender.tag<0||(NSUInteger)sender.tag>=self.items.count)return;
    NSDictionary *item=self.items[(NSUInteger)sender.tag];NSString *kind=item[@"kind"],*value=item[@"value"];
    if([kind isEqual:@"sharewifi"]) {
        NSDictionary *s=QCSWStatus();
        if(!QCSWFresh(s)){[self launch:@"vn.sentechtips.sharewifi"];return;}
        if([s[@"busy"]boolValue])return;
        QCNotify(CFSTR("vn.sentechtips.sharewifi.cc-toggle"));self.message.text=@"Đã gửi lệnh ShareWifi · Dùng chế độ tắt đã chọn trong ShareWifi";
        [self updateShareWifi];return;
    }
    if([kind isEqual:@"app"]){[self launch:value];return;}
    NSURL *url=[kind isEqual:@"shortcut"]?QCShortcutURL(value):[NSURL URLWithString:value];
    if(!url){[self alert:@"Địa chỉ chưa hợp lệ. Kiểm tra lại trong Tùy chỉnh."];return;}
    [self close];[UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL ok){
        if(!ok)dispatch_async(dispatch_get_main_queue(),^{[self alert:@"Không có ứng dụng nhận địa chỉ này. Kiểm tra URL hoặc cài ứng dụng/phím tắt tương ứng."];});
    }];
}
@end

static void QCEvent(CFNotificationCenterRef center,void *observer,CFStringRef name,const void *object,CFDictionaryRef info) {
    (void)center;(void)observer;(void)object;(void)info;
    BOOL changed=CFEqual(name,QC_CHANGED);
    dispatch_async(dispatch_get_main_queue(),^{if(changed){[overlay reloadSettings];[overlay publish];}else [overlay toggle];});
}
static int lockToken;
__attribute__((constructor)) static void QCInitialize(void) {
    @autoreleasepool {
        if(![NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])return;
        struct utsname u;if(uname(&u))return;NSOperatingSystemVersion v=NSProcessInfo.processInfo.operatingSystemVersion;
        if((strcmp(u.machine,"iPhone9,2")&&strcmp(u.machine,"iPhone9,4"))||v.majorVersion!=15||v.minorVersion!=8||v.patchVersion!=8)return;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC),dispatch_get_main_queue(),^{
            dlopen("/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices",RTLD_NOW);
            overlay=[QCOverlay new];[overlay start];
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,QCEvent,QC_CHANGED,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,QCEvent,QC_TOGGLE,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
            notify_register_dispatch("com.apple.springboard.lockstate",&lockToken,dispatch_get_main_queue(),^(__unused int token){
                [overlay close];[overlay syncVisibility];[overlay publish];
            });
            [overlay publish];
        });
    }
}
