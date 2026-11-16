// ShareWifi — native controller; no changes to carrier settings, VPN, APN or packet routing.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <sys/utsname.h>
#import "SWCommon.h"
#import "SWClients.h"
#import "SWMethodABI.h"
#import "SWProfilePlan.h"
#import "SWHapticMenu.h"

extern void MSHookMessageEx(Class, SEL, IMP, IMP *);
typedef unsigned char SWBoolean;
static SWBoolean (*SWCellGet)(void);
static void (*SWCellSet)(SWBoolean);

static BOOL SWBoolType(const char *type) {
    return SWABIIsBoolean(type);
}
static NSMethodSignature *SWSignature(id object, NSString *name, NSUInteger arguments) {
    SEL sel = NSSelectorFromString(name);
    if (!object || ![object respondsToSelector:sel]) return nil;
    NSMethodSignature *sig = [object methodSignatureForSelector:sel];
    return sig.numberOfArguments == arguments ? sig : nil;
}
static id SWObject(id object, NSString *name) {
    NSMethodSignature *sig = SWSignature(object, name, 2);
    if (!sig || strcmp(sig.methodReturnType, "@")) return nil;
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    inv.target = object; inv.selector = NSSelectorFromString(name); [inv invoke];
    __unsafe_unretained id result = nil; [inv getReturnValue:&result]; return result;
}
static id SWBool(id object, NSString *name) {
    NSMethodSignature *sig = SWSignature(object, name, 2);
    if (!sig || !SWABIIsBooleanGetter(sig.methodReturnType, sig.numberOfArguments, sig.methodReturnLength)) return @"unknown";
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    inv.target = object; inv.selector = NSSelectorFromString(name); [inv invoke];
    BOOL value = NO; [inv getReturnValue:&value]; return @(value != NO);
}
static BOOL SWCanSet(id object, NSString *name) {
    NSMethodSignature *sig = SWSignature(object, name, 3);
    return sig && SWBoolType([sig getArgumentTypeAtIndex:2]) &&
        (!strcmp(sig.methodReturnType, "v") || SWBoolType(sig.methodReturnType));
}
static BOOL SWSet(id object, NSString *name, BOOL value) {
    if (!SWCanSet(object, name)) return NO;
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:NSSelectorFromString(name)]];
    inv.target = object; inv.selector = NSSelectorFromString(name);
    [inv setArgument:&value atIndex:2]; [inv invoke]; return YES;
}
static BOOL SWVoid(id object, NSString *name) {
    NSMethodSignature *sig = SWSignature(object, name, 2);
    if (!sig || strcmp(sig.methodReturnType, "v")) return NO;
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    inv.target = object; inv.selector = NSSelectorFromString(name); [inv invoke]; return YES;
}

static BOOL SWCanPerformAction(id object, NSString *name) {
    NSMethodSignature *sig = SWSignature(object, name, 2);
    return sig && SWABIIsNoArgumentAction(sig.methodReturnType, sig.numberOfArguments, sig.methodReturnLength);
}

static BOOL SWPerformAction(id object, NSString *name) {
    if (!SWCanPerformAction(object, name)) return NO;
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:NSSelectorFromString(name)]];
    inv.target = object; inv.selector = NSSelectorFromString(name); [inv invoke];
    // _toggleState returns BOOL on the reference API. Do not treat a NO result
    // as failure: when switching off it can be the new state. Readback decides.
    return YES;
}

static NSString *SWHotspotGetter(id object) {
    // `discoverable` is a PROPERTY name; its declared getter is isDiscoverable.
    for (NSString *name in @[@"isDiscoverable", @"discoverable"]) {
        NSMethodSignature *sig = SWSignature(object, name, 2);
        if (sig && SWABIIsBooleanGetter(sig.methodReturnType, sig.numberOfArguments, sig.methodReturnLength)) return name;
    }
    return nil;
}

static UIWindow *toastWindow;
static NSString *SWName(NSString *key) {
    return SWRadioName(key);
}
static NSUInteger toastGeneration;
static void SWToast(NSString *text) {
    NSUInteger generation = ++toastGeneration;
    if (!toastWindow) {
        toastWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        toastWindow.windowLevel = UIWindowLevelAlert + 2;
        toastWindow.backgroundColor = UIColor.clearColor;
        toastWindow.userInteractionEnabled = NO;
        toastWindow.rootViewController = [UIViewController new];
        toastWindow.rootViewController.view.backgroundColor = UIColor.clearColor;
    }
    for (UIView *v in toastWindow.rootViewController.view.subviews) [v removeFromSuperview];
    UILabel *label = [UILabel new]; label.numberOfLines = 0; label.textAlignment = NSTextAlignmentCenter;
    label.text = text; label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    label.textColor = UIColor.whiteColor; label.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.94];
    label.layer.cornerRadius = 18; label.clipsToBounds = YES;
    CGFloat width = MIN(360, UIScreen.mainScreen.bounds.size.width - 32);
    label.frame = CGRectMake((UIScreen.mainScreen.bounds.size.width - width) / 2, 45, width, 84);
    [toastWindow.rootViewController.view addSubview:label]; toastWindow.hidden = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (generation == toastGeneration) toastWindow.hidden = YES;
    });
}

@interface SWController : NSObject
@property(nonatomic,strong) id wifi;
@property(nonatomic,strong) id bluetooth;
@property(nonatomic,strong) id hotspot;
@property(nonatomic,strong) dispatch_source_t timer;
@property(nonatomic,strong) NSDictionary *snapshot;
@property(nonatomic,strong) NSDictionary *sessionSnapshot;
@property(nonatomic,strong) NSDictionary *undoSessionSnapshot;
@property(nonatomic,strong) NSDictionary *nextSessionSnapshot;
@property(nonatomic,copy) NSString *operation;
@property(nonatomic,copy) NSString *individualKey;
@property(nonatomic,strong) NSDictionary *target;
@property(nonatomic,strong) NSArray *steps;
@property(nonatomic,copy) NSString *message;
@property(nonatomic,copy) NSString *phase;
@property(nonatomic,copy) NSString *lastID;
@property(nonatomic,copy) NSString *internet;
@property(nonatomic,copy) NSString *apiError;
@property(nonatomic) BOOL busy;
@property(nonatomic) BOOL iconOperation;
@property(nonatomic) BOOL tapHook;
@property(nonatomic) BOOL hapticHook;
@property(nonatomic) BOOL restoring;
@property(nonatomic) NSUInteger step;
@property(nonatomic) NSUInteger generation;
@property(nonatomic) NSUInteger probeGeneration;
@property(nonatomic) NSTimeInterval monitorUntil;
@property(nonatomic) NSTimeInterval verifiedAt;
- (void)start;
- (void)refresh;
- (NSDictionary *)powers;
- (void)request:(NSString *)action fromIcon:(BOOL)icon;
- (void)publish;
- (void)nextStep;
- (void)finish:(BOOL)success message:(NSString *)message;
- (void)probe;
- (void)waitFor:(NSString *)key desired:(BOOL)wanted deadline:(NSTimeInterval)deadline generation:(NSUInteger)generation;
@end
static SWController *controller;

@implementation SWController
- (void)start {
    self.phase = @"ready"; self.message = @"Sẵn sàng"; self.internet = @"Chưa kiểm tra";
    @try {
        dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_NOW);
        dlopen("/System/Library/PrivateFrameworks/BluetoothManager.framework/BluetoothManager", RTLD_NOW);
        dlopen("/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle/ConnectivityModule", RTLD_NOW);
        SWCellGet = dlsym(RTLD_DEFAULT, "CTCellularDataPlanGetIsEnabled");
        SWCellSet = dlsym(RTLD_DEFAULT, "CTCellularDataPlanSetIsEnabled");
        self.wifi = SWObject(NSClassFromString(@"SBWiFiManager"), @"sharedInstance");
        self.bluetooth = SWObject(NSClassFromString(@"BluetoothManager"), @"sharedInstance");
        Class hs = NSClassFromString(@"CCUIConnectivityHotspotViewController");
        if (hs && [hs isSubclassOfClass:UIViewController.class]) self.hotspot = [[hs alloc] init];
    } @catch (NSException *exception) {
        self.apiError = [NSString stringWithFormat:@"Khởi tạo API chưa thành công (%@)", exception.name];
    }
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    __weak SWController *weakSelf = self;
    dispatch_source_set_event_handler(self.timer, ^{ [weakSelf refresh]; });
    dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), 60 * NSEC_PER_SEC, NSEC_PER_SEC);
    dispatch_resume(self.timer); [self refresh];
}
- (NSDictionary *)powers {
    @try {
        SWVoid(self.hotspot, @"_updateState");
        NSString *getter = SWHotspotGetter(self.hotspot);
        return @{@"data":SWCellGet ? @(SWCellGet() != 0) : @"unknown",
                 @"wifi":SWBool(self.wifi, @"wiFiEnabled"),
                 @"bluetooth":SWBool(self.bluetooth, @"powered"),
                 @"hotspot":getter ? SWBool(self.hotspot, getter) : @"unknown"};
    } @catch (NSException *exception) {
        self.apiError = [NSString stringWithFormat:@"Không đọc được trạng thái (%@)",exception.name];
        return @{@"data":@"unknown",@"wifi":@"unknown",@"bluetooth":@"unknown",@"hotspot":@"unknown"};
    }
}
- (id)nativeCount {
    id telephony = SWObject(NSClassFromString(@"SBTelephonyManager"), @"sharedTelephonyManager");
    if (!telephony) return @"unknown";
    Ivar ivar = class_getInstanceVariable([telephony class], "_numberOfNetworkTetheredDevices");
    if (!ivar || strcmp(ivar_getTypeEncoding(ivar), "i")) return @"unknown";
    ptrdiff_t offset = ivar_getOffset(ivar);
    if (offset < 0 || (size_t)offset + sizeof(int) > class_getInstanceSize([telephony class])) return @"unknown";
    int count = -1;
    memcpy(&count, (const char *)(__bridge const void *)telephony + offset, sizeof(count));
    return count >= 0 && count <= 128 ? @(count) : @"unknown";
}
- (void)refresh {
    if (self.busy) return;
    NSDictionary *powers = [self powers];
    BOOL active = [powers[@"hotspot"] isEqual:@YES];
    NSTimeInterval interval = NSDate.date.timeIntervalSince1970 < self.monitorUntil ? 3 : (active ? 30 : 60);
    dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, NSEC_PER_SEC / 2);
    [self publish];
}
- (void)publish {
    NSDictionary *p = [self powers];
    NSString *getter = SWHotspotGetter(self.hotspot);
    NSMethodSignature *toggleSignature = SWSignature(self.hotspot, @"_toggleState", 2);
    NSDictionary *hotspotAPI = @{@"controllerPresent":@(self.hotspot != nil),
        @"controllerClass":self.hotspot ? NSStringFromClass([self.hotspot class]) : @"missing",
        @"getter":getter ?: @"missing",
        @"isDiscoverablePresent":@([self.hotspot respondsToSelector:NSSelectorFromString(@"isDiscoverable")]),
        @"legacyDiscoverablePresent":@([self.hotspot respondsToSelector:NSSelectorFromString(@"discoverable")]),
        @"toggleReturnType":toggleSignature ? @(toggleSignature.methodReturnType) : @"missing",
        @"toggleCompatible":@(SWCanPerformAction(self.hotspot, @"_toggleState"))};
    NSMutableDictionary *status = [@{@"version":SW_VERSION, @"updated":@(NSDate.date.timeIntervalSince1970),
        @"powers":p, @"busy":@(self.busy), @"phase":self.phase ?: @"ready",
        @"message":self.message ?: @"", @"lastRequest":self.lastID ?: @"",
        @"canRestoreSession":@(self.sessionSnapshot != nil), @"stopMode":SWStopMode(),
        @"canUndo":@(self.snapshot != nil), @"iconTapHook":@(self.tapHook),
        @"hapticTouchHook":@(self.hapticHook), @"hapticTouchEnabled":@(SWHapticEnabled()),
        @"internet":self.internet ?: @"Chưa kiểm tra", @"internetCheckedAt":@(self.verifiedAt),
        @"apiError":self.apiError ?: @"", @"systemCount":[self nativeCount], @"hotspotAPI":hotspotAPI} mutableCopy];
    if (NSDate.date.timeIntervalSince1970 < self.monitorUntil && [p[@"hotspot"] isEqual:@YES]) {
        status[@"clients"] = SWCollectClients();
    } else status[@"clients"] = @{@"rows":@[]};
    if (SWWrite(status, @"status.plist")) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),SW_STATUS,NULL,NULL,YES);
}
- (NSString *)preflight:(NSDictionary *)p {
    if (self.apiError.length) return self.apiError;
    for (NSString *key in @[@"data",@"wifi",@"bluetooth",@"hotspot"])
        if (![p[key] isKindOfClass:NSNumber.class]) return [NSString stringWithFormat:@"Chưa đọc được %@. Mở bảng điều khiển để chẩn đoán.",SWName(key)];
    if (!SWCellSet || !SWCanSet(self.wifi,@"setWiFiEnabled:") || !SWCanSet(self.bluetooth,@"setPowered:"))
        return @"API điều khiển radio không khớp. Chưa thay đổi kết nối.";
    if (!SWCanPerformAction(self.hotspot,@"_toggleState")) return @"API hotspot chưa tương thích. Chưa thay đổi kết nối.";
    return nil;
}
- (NSString *)preflightRadio:(NSString *)key desired:(BOOL)on powers:(NSDictionary *)p {
    if (![p[key] isKindOfClass:NSNumber.class]) return [NSString stringWithFormat:@"Chưa đọc được %@. Hãy làm mới và thử lại.",SWName(key)];
    BOOL capable=[key isEqual:@"data"]?SWCellSet!=NULL:
        ([key isEqual:@"wifi"]?SWCanSet(self.wifi,@"setWiFiEnabled:"):
        ([key isEqual:@"bluetooth"]?SWCanSet(self.bluetooth,@"setPowered:"):SWCanPerformAction(self.hotspot,@"_toggleState")));
    if (!capable) return [NSString stringWithFormat:@"API điều khiển %@ chưa tương thích. Chưa thay đổi kết nối.",SWName(key)];
    if ([key isEqual:@"hotspot"] && on && ![p[key] isEqual:@YES]) {
        if (![p[@"data"] isEqual:@YES]) return @"Bật Dữ liệu di động trước khi bật riêng Điểm truy cập cá nhân.";
        if (![p[@"wifi"] isEqual:@YES]) return @"Bật Wi-Fi trước để chia sẻ mạng. Nút Bật chia sẻ mạng có thể bật cả bộ.";
    }
    return nil;
}
- (void)request:(NSString *)action fromIcon:(BOOL)icon {
    if ([action isEqualToString:@"refresh"]) { self.monitorUntil = NSDate.date.timeIntervalSince1970 + 12; [self refresh]; return; }
    if ([action isEqualToString:@"probe"]) { [self probe]; return; }
    if (self.busy) { if (icon) SWToast(@"ShareWifi đang xử lý…"); return; }
    int radio=-1,desired=-1;
    BOOL individual=SWDecodeRadioAction(action.UTF8String,&radio,&desired);
    if (!individual && ![@[@"toggle",@"on",@"off",@"stop",@"hotspotOnly",@"restoreSession",@"undo"] containsObject:action]) return;
    self.apiError=@"";
    NSDictionary *p = [self powers];
    NSString *individualKey=individual?SWRadioKeys()[radio]:nil;
    NSString *failure = individual?[self preflightRadio:individualKey desired:desired powers:p]:[self preflight:p];
    if (failure) { self.phase=@"error";self.message=failure;[self publish];if(icon)SWToast(failure);return; }
    if (individual && [p[individualKey] isEqual:@(desired)]) {
        self.phase=@"ready";self.message=[NSString stringWithFormat:@"%@ đang %@.",SWName(individualKey),desired?@"bật":@"tắt"];
        [self publish];if(icon)SWToast(self.message);return;
    }
    if ([action isEqual:@"toggle"]) action=[p[@"hotspot"] boolValue]?@"stop":@"on";
    if ([action isEqual:@"stop"]) action=SWStopMode();
    self.restoring=[action isEqual:@"undo"];
    NSDictionary *baseline=self.restoring?self.snapshot:self.sessionSnapshot;
    SWProfile profile=[action isEqual:@"on"]?SWStartAll:([action isEqual:@"hotspotOnly"]?SWStopHotspot:
        ((self.restoring||[action isEqual:@"restoreSession"])?SWRestore:SWStopAll));
    NSArray *keys=@[@"data",@"wifi",@"bluetooth",@"hotspot"];
    int current[SWRadioCount],before[SWRadioCount];
    for(unsigned i=0;i<SWRadioCount;i++) {
        current[i]=[p[keys[i]] isKindOfClass:NSNumber.class]?[p[keys[i]] intValue]:-1;
        before[i]=[baseline[keys[i]] isKindOfClass:NSNumber.class]?[baseline[keys[i]] intValue]:-1;
    }
    SWPlan plan;
    BOOL planned=individual?SWBuildRadioPlan(radio,desired,current,&plan):SWBuildPlan(profile,current,baseline?before:NULL,&plan);
    if (!planned) {
        self.phase=@"error";
        self.message=self.restoring?@"Chưa có thao tác để hoàn tác.":@"Chưa lưu trạng thái trước phiên này. Hãy chọn Chỉ tắt hotspot hoặc Tắt cả bộ; lần sau bật bằng ShareWifi để lưu phiên.";
        [self publish];if(icon)SWToast(self.message);return;
    }
    NSMutableDictionary *target=[NSMutableDictionary dictionary];
    NSMutableArray *steps=[NSMutableArray array];
    for(unsigned i=0;i<SWRadioCount;i++)target[keys[i]]=@(plan.target[i]);
    for(unsigned i=0;i<plan.count;i++)[steps addObject:keys[plan.order[i]]];
    self.target=target;self.steps=steps;self.operation=action;self.individualKey=individualKey;
    NSDictionary *previousSession=self.sessionSnapshot;
    BOOL startSession=individual?(radio==SWHotspot && desired):profile==SWStartAll;
    if(startSession&&SWCaptureSession(SWStartAll,current,self.sessionSnapshot!=nil))self.sessionSnapshot=p;
    self.nextSessionSnapshot=individual?self.sessionSnapshot:(self.restoring?self.undoSessionSnapshot:(profile==SWStartAll?self.sessionSnapshot:nil));
    self.undoSessionSnapshot=previousSession;
    self.snapshot=SWValidPowers(current)?p:nil;
    self.busy=YES;self.step=0;self.generation++;self.probeGeneration++;
    self.internet=@"Chưa kiểm tra sau thay đổi";self.verifiedAt=0;
    self.phase=individual?@"changing":([self.target[@"hotspot"] boolValue]?@"starting":@"stopping");
    self.message=individual?[NSString stringWithFormat:@"Đang %@ %@…",desired?@"bật":@"tắt",SWName(individualKey)]:
        ([self.target[@"hotspot"] boolValue]?@"Đang bật chia sẻ mạng…":@"Đang tắt các kết nối…");
    self.iconOperation=icon; if(icon)SWToast(self.message);
    [self publish]; [self nextStep];
}
- (BOOL)setPower:(NSString *)key desired:(BOOL)value {
    @try {
        if ([key isEqualToString:@"data"]) { SWCellSet(value); return YES; }
        if ([key isEqualToString:@"wifi"]) return SWSet(self.wifi,@"setWiFiEnabled:",value);
        if ([key isEqualToString:@"bluetooth"]) return SWSet(self.bluetooth,@"setPowered:",value);
        if ([key isEqualToString:@"hotspot"]) {
            id current = [self powers][@"hotspot"];
            if (![current isKindOfClass:NSNumber.class]) return NO;
            return [current boolValue] == value || SWPerformAction(self.hotspot,@"_toggleState");
        }
    } @catch (NSException *exception) { self.apiError = [NSString stringWithFormat:@"Lỗi API (%@)",exception.name]; }
    return NO;
}
- (void)nextStep {
    if (self.step >= self.steps.count) {
        NSDictionary *actual = [self powers];
        for (NSString *key in self.steps) if (![actual[key] isEqual:self.target[key]]) {
            [self finish:NO message:@"Kết nối đã thay đổi trong lúc xử lý. Kiểm tra lại trạng thái từng mục."];return;
        }
        BOOL on=[actual[@"hotspot"] boolValue];
        NSString *message=self.individualKey.length?[NSString stringWithFormat:@"Đã %@ %@.",[self.target[self.individualKey] boolValue]?@"bật":@"tắt",SWName(self.individualKey)]:
            (self.restoring?@"Đã khôi phục trạng thái trước thao tác":
            ([self.operation isEqual:@"restoreSession"]?@"Đã khôi phục trạng thái trước phiên chia sẻ":
            ([self.operation isEqual:@"hotspotOnly"]?@"Đã tắt hotspot · Giữ nguyên dữ liệu di động, Wi-Fi và Bluetooth":
            (on?@"Đã bật cả bộ · Hotspot cho phép kết nối":@"Đã tắt hotspot, dữ liệu di động, Wi-Fi và Bluetooth"))));
        [self finish:YES message:message];
        if (on) [self probe]; return;
    }
    NSString *key=self.steps[self.step];BOOL wanted=[self.target[key] boolValue];
    if ([[self powers][key] isEqual:@(wanted)]) { self.step++;[self nextStep];return; }
    if (![self setPower:key desired:wanted]) { [self finish:NO message:[NSString stringWithFormat:@"Không điều khiển được %@. Có thể đã thay đổi một phần; dùng Hoàn tác nếu cần.",SWName(key)]];return; }
    [self waitFor:key desired:wanted deadline:NSDate.date.timeIntervalSince1970+([key isEqualToString:@"hotspot"]?12:7) generation:self.generation];
}
- (void)waitFor:(NSString *)key desired:(BOOL)wanted deadline:(NSTimeInterval)deadline generation:(NSUInteger)generation {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/3),dispatch_get_main_queue(),^{
        if (!self.busy || generation!=self.generation) return;
        if ([[self powers][key] isEqual:@(wanted)]) {self.step++;[self publish];[self nextStep];return;}
        if (NSDate.date.timeIntervalSince1970 >= deadline) {
            [self finish:NO message:[NSString stringWithFormat:@"%@ chưa chuyển trạng thái sau khi chờ. Có thể đã đổi một phần; kiểm tra hoặc Hoàn tác.",SWName(key)]];return;
        }
        [self waitFor:key desired:wanted deadline:deadline generation:generation];
    });
}
- (void)finish:(BOOL)success message:(NSString *)message {
    if(success)self.sessionSnapshot=self.nextSessionSnapshot;
    self.nextSessionSnapshot=nil;
    self.busy=NO;self.phase=success?@"ready":@"error";self.message=message;
    if(self.iconOperation)SWToast(message);self.iconOperation=NO;[self refresh];
}
- (void)probe {
    if (self.busy) return;
    NSUInteger generation=++self.probeGeneration;
    self.internet=@"Đang kiểm tra…";[self publish];
    NSURLSessionConfiguration *configuration=NSURLSessionConfiguration.ephemeralSessionConfiguration;
    configuration.timeoutIntervalForRequest=8;configuration.timeoutIntervalForResource=10;
    configuration.URLCache=nil;configuration.HTTPCookieStorage=nil;
    NSURLSession *session=[NSURLSession sessionWithConfiguration:configuration];
    NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://captive.apple.com/hotspot-detect.html"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:8];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response,NSError *error){
        BOOL good=!error && [response isKindOfClass:NSHTTPURLResponse.class] && [(NSHTTPURLResponse *)response statusCode]==200 && data.length<65536;
        NSString *body=good?[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]:nil;
        good=good && [body containsString:@"Success"];
        dispatch_async(dispatch_get_main_queue(),^{
            if(generation!=self.probeGeneration)return;
            self.internet=good?@"Truy cập được Internet từ iPhone 7 Plus":@"Chưa xác nhận Internet · kiểm tra sóng/gói cước/VPN";
            self.verifiedAt=NSDate.date.timeIntervalSince1970;[self publish];
        });[session finishTasksAndInvalidate];
    }] resume];
}
@end

static void SWRequestCallback(CFNotificationCenterRef center,void *observer,CFStringRef name,const void *object,CFDictionaryRef userInfo) {
    (void)center;(void)observer;(void)name;(void)object;(void)userInfo;
    dispatch_async(dispatch_get_main_queue(),^{
        NSDictionary *r=SWRead(@"request.plist");
        NSString *action=r[@"action"],*identifier=r[@"id"];
        if(![r[@"created"] isKindOfClass:NSNumber.class])return;
        NSTimeInterval age=NSDate.date.timeIntervalSince1970-[r[@"created"] doubleValue];
        if(![action isKindOfClass:NSString.class]||![identifier isKindOfClass:NSString.class]||identifier.length>80||age<0||age>30)return;
        if([controller.lastID isEqualToString:identifier])return;
        if(![action isEqualToString:@"refresh"] && ![action isEqualToString:@"probe"] && !controller.busy)controller.lastID=identifier;
        [controller request:action fromIcon:NO];
    });
}

static void SWRefreshCallback(CFNotificationCenterRef center,void *observer,CFStringRef name,const void *object,CFDictionaryRef userInfo) {
    (void)center;(void)observer;(void)name;(void)object;(void)userInfo;
    dispatch_async(dispatch_get_main_queue(),^{[controller request:@"refresh" fromIcon:NO];});
}

static void SWCCCallback(CFNotificationCenterRef center,void *observer,CFStringRef name,const void *object,CFDictionaryRef userInfo) {
    (void)center;(void)observer;(void)name;(void)object;(void)userInfo;
    dispatch_async(dispatch_get_main_queue(),^{[controller request:@"toggle" fromIcon:YES];});
}

static void (*originalTap)(id,SEL);
static void SWHandleTap(id view,SEL selector) {
    @try {
        id icon=SWObject(view,@"icon");
        NSString *bundle=SWObject(icon,@"applicationBundleID");
        id jitter=SWBool(view,@"isJittering");
        if(![jitter isKindOfClass:NSNumber.class]) {
            id icons=SWObject(NSClassFromString(@"SBIconController"),@"sharedInstance");
            jitter=SWBool(icons,@"isEditing");
        }
        if([bundle isKindOfClass:NSString.class]&&[bundle isEqualToString:SW_BUNDLE]&&[jitter isEqual:@NO]) {
            NSDictionary *settings=SWRead(@"settings.plist");
            if(![settings[@"disableIconToggle"] boolValue]) { [controller request:@"toggle" fromIcon:YES];return; }
        }
    } @catch(NSException *exception) { (void)exception; }
    if(originalTap)originalTap(view,selector);
}

__attribute__((constructor)) static void SWInitialize(void) {
    @autoreleasepool {
        if(![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"])return;
        NSOperatingSystemVersion v=NSProcessInfo.processInfo.operatingSystemVersion;
        struct utsname machine;if(uname(&machine)!=0)return;
        if(v.majorVersion!=15||v.minorVersion!=8||v.patchVersion!=8||
           (strcmp(machine.machine,"iPhone9,2")&&strcmp(machine.machine,"iPhone9,4")))return;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,4*NSEC_PER_SEC),dispatch_get_main_queue(),^{
            controller=[SWController new];[controller start];
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,SWRequestCallback,SW_REQUEST,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,SWRefreshCallback,SW_REFRESH,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,SWCCCallback,SW_CC_TOGGLE,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
            Class iconView=NSClassFromString(@"SBIconView");SEL tap=NSSelectorFromString(@"_handleTap");
            Method method=iconView?class_getInstanceMethod(iconView,tap):NULL;
            char *ret=method?method_copyReturnType(method):NULL;
            if(method&&method_getNumberOfArguments(method)==2&&ret&&!strcmp(ret,"v")) {
                MSHookMessageEx(iconView,tap,(IMP)SWHandleTap,(IMP *)&originalTap);controller.tapHook=originalTap!=NULL;
            }
            free(ret);
            controller.hapticHook=SWInstallHapticMenu(^{return [controller powers];},^(NSString *action){[controller request:action fromIcon:YES];});
            [controller publish];
        });
    }
}
