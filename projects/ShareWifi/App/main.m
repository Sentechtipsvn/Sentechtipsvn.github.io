#import <UIKit/UIKit.h>
#import "SWCommon.h"
#import "SWSettings.h"

@interface SWPanel : UITableViewController
@property(nonatomic,strong) NSDictionary *status;
@property(nonatomic,strong) NSArray *devices;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) UILabel *summary;
@property(nonatomic,strong) UILabel *explanation;
@property(nonatomic,strong) UIButton *toggle;
@property(nonatomic,strong) UIActivityIndicatorView *spinner;
@property(nonatomic,copy) NSString *pending;
@property(nonatomic) NSTimeInterval pendingUntil;
- (void)send:(NSString *)action;
- (void)resume;
- (void)pause;
- (void)reload;
- (void)manualRefresh;
@end

static UIColor *SWGreen(void) { return [UIColor colorWithRed:0.08 green:0.57 blue:0.35 alpha:1]; }

@implementation SWPanel
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"ShareWifi";self.view.tintColor=SWGreen();
    self.navigationController.navigationBar.prefersLargeTitles=YES;
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(manualRefresh)];
    UIView *header=[[UIView alloc]initWithFrame:CGRectMake(0,0,self.tableView.bounds.size.width,200)];
    self.summary=[UILabel new];self.summary.translatesAutoresizingMaskIntoConstraints=NO;
    self.summary.font=[UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];self.summary.adjustsFontForContentSizeCategory=YES;
    self.summary.numberOfLines=2;
    self.explanation=[UILabel new];self.explanation.translatesAutoresizingMaskIntoConstraints=NO;
    self.explanation.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];self.explanation.textColor=UIColor.secondaryLabelColor;
    self.explanation.numberOfLines=0;
    self.toggle=[UIButton buttonWithType:UIButtonTypeSystem];self.toggle.translatesAutoresizingMaskIntoConstraints=NO;
    self.toggle.backgroundColor=SWGreen();[self.toggle setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.toggle.titleLabel.font=[UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];self.toggle.layer.cornerRadius=17;
    [self.toggle addTarget:self action:@selector(togglePressed) forControlEvents:UIControlEventTouchUpInside];
    self.spinner=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.translatesAutoresizingMaskIntoConstraints=NO;self.spinner.color=UIColor.whiteColor;self.spinner.hidesWhenStopped=YES;
    [header addSubview:self.summary];[header addSubview:self.explanation];[header addSubview:self.toggle];[self.toggle addSubview:self.spinner];
    [NSLayoutConstraint activateConstraints:@[
        [self.summary.topAnchor constraintEqualToAnchor:header.topAnchor constant:8],
        [self.summary.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:24],
        [self.summary.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-24],
        [self.toggle.topAnchor constraintEqualToAnchor:self.summary.bottomAnchor constant:15],
        [self.toggle.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [self.toggle.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],
        [self.toggle.heightAnchor constraintEqualToConstant:58],
        [self.explanation.topAnchor constraintEqualToAnchor:self.toggle.bottomAnchor constant:12],
        [self.explanation.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:24],
        [self.explanation.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-24],
        [self.spinner.centerYAnchor constraintEqualToAnchor:self.toggle.centerYAnchor],
        [self.spinner.trailingAnchor constraintEqualToAnchor:self.toggle.trailingAnchor constant:-15]]];
    self.tableView.tableHeaderView=header;
    self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=64;
    [self resume];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIView *header=self.tableView.tableHeaderView;
    CGFloat width=MAX(100,self.tableView.bounds.size.width-48);
    CGFloat height=MAX(200,8+[self.summary sizeThatFits:CGSizeMake(width,CGFLOAT_MAX)].height+15+58+12+[self.explanation sizeThatFits:CGSizeMake(width,CGFLOAT_MAX)].height+16);
    if(fabs(header.frame.size.height-height)>0.5) {
        header.frame=CGRectMake(0,0,self.tableView.bounds.size.width,height);
        self.tableView.tableHeaderView=header;
    }
}
- (void)manualRefresh { [self send:@"refresh"];[self reload]; }
- (void)resume {
    if(!self.isViewLoaded)return;
    [self.timer invalidate];[self reload];[self send:@"refresh"];
    self.timer=[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}
- (void)pause { [self.timer invalidate];self.timer=nil; }
- (void)tick { [self send:@"refresh"];[self reload]; }
- (void)send:(NSString *)action {
    if([action isEqualToString:@"refresh"]) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),SW_REFRESH,NULL,NULL,YES);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/2),dispatch_get_main_queue(),^{[self reload];});
        return;
    }
    BOOL mutation=![@[@"refresh",@"probe"] containsObject:action];
    if(mutation&&self.pending.length&&NSDate.date.timeIntervalSince1970<self.pendingUntil)return;
    NSString *identifier=NSUUID.UUID.UUIDString;
    if(!SWWrite(@{@"id":identifier,@"action":action,@"created":@(NSDate.date.timeIntervalSince1970)},@"request.plist")) {
        self.explanation.text=@"Không ghi được lệnh. Cần cài bản .deb trong môi trường jailbreak.";return;
    }
    if(mutation){self.pending=identifier;self.pendingUntil=NSDate.date.timeIntervalSince1970+5;self.toggle.enabled=NO;[self.spinner startAnimating];}
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),SW_REQUEST,NULL,NULL,YES);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/2),dispatch_get_main_queue(),^{[self reload];});
}
- (void)reload {
    self.status=SWRead(@"status.plist");
    NSDictionary *clientInfo=[self.status[@"clients"] isKindOfClass:NSDictionary.class]?self.status[@"clients"]:@{};
    self.devices=[clientInfo[@"rows"] isKindOfClass:NSArray.class]?clientInfo[@"rows"]:@[];
    BOOL fresh=self.status.count && NSDate.date.timeIntervalSince1970-[self.status[@"updated"] doubleValue]<15;
    BOOL busy=[self.status[@"busy"] boolValue];
    if([self.status[@"lastRequest"] isEqual:self.pending])self.pending=nil;
    BOOL waiting=self.pending.length&&NSDate.date.timeIntervalSince1970<self.pendingUntil;
    BOOL on=[self.status[@"powers"][@"hotspot"] isEqual:@YES];
    if(!fresh){self.summary.text=@"Chưa nhận trạng thái mới";self.explanation.text=@"Cài .deb, respring và bật nạp tweak trong Dopamine. Chưa có lệnh nào được xác nhận.";}
    else {
        self.summary.text=busy?@"Đang xử lý…":(on?@"Đang cho phép chia sẻ mạng":@"Điểm truy cập cá nhân đang tắt");
        self.explanation.text=self.status[@"message"]?:@"";
        if([self.status[@"apiError"] length])self.explanation.text=self.status[@"apiError"];
    }
    [self.toggle setTitle:busy||waiting?@"Đang xử lý…":(on?SWStopTitle(SWStopMode()):@"Bật chia sẻ mạng") forState:UIControlStateNormal];
    self.toggle.backgroundColor=on?UIColor.systemRedColor:SWGreen();
    self.toggle.enabled=fresh&&!busy&&!waiting;self.toggle.alpha=self.toggle.enabled?1:0.6;
    if(busy||waiting)[self.spinner startAnimating];else [self.spinner stopAnimating];
    [self.tableView reloadData];
    [self.view setNeedsLayout];
}
- (void)togglePressed { [self send:@"toggle"]; }
- (void)radioChanged:(UISwitch *)sender {
    if(sender.tag<0||sender.tag>=SWRadioCount)return;
    NSString *key=SWRadioKeys()[sender.tag];
    [[UISelectionFeedbackGenerator new] selectionChanged];
    [self send:SWRadioCommand(key,sender.on)];
    // Keep the thumb tied to readback, including failures or iOS side effects.
    [self reload];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView;return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;return section==0?4:(section==1?MAX((NSInteger)self.devices.count,1):7);
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    if(section==0)return @"Kết nối";
    if(section==2)return @"Điều khiển";
    id count=self.status[@"systemCount"];
    return [count isKindOfClass:NSNumber.class]?[NSString stringWithFormat:@"Kết nối hệ thống: %@",count]:@"Thiết bị · chưa đọc được số kết nối";
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if(section==0)return [NSString stringWithFormat:@"Internet: %@",self.status[@"internet"]?:@"Chưa kiểm tra"];
    if(section==1)return @"Danh sách dưới đây là máy vừa thấy qua ARP, không phải bằng chứng chắc chắn còn online. Số kết nối hệ thống có thể khác. Chạm để đặt tên riêng.";
    return [NSString stringWithFormat:@"ShareWifi %@ · © Sentechtipsvn\nRời ứng dụng không tắt hotspot. Tắt dữ liệu di động vẫn giữ nghe gọi/SMS. iOS có thể tự ngắt hotspot khi không có máy dùng.",SW_VERSION];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.numberOfLines=0;cell.detailTextLabel.numberOfLines=0;
    cell.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];cell.textLabel.adjustsFontForContentSizeCategory=YES;
    cell.detailTextLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    cell.detailTextLabel.textColor=UIColor.secondaryLabelColor;
    if(indexPath.section==0) {
        NSArray *keys=@[@"data",@"wifi",@"bluetooth",@"hotspot"];
        NSArray *titles=@[@"Dữ liệu di động",@"Wi-Fi",@"Bluetooth",@"Điểm truy cập cá nhân"];
        NSArray *symbols=@[@"antenna.radiowaves.left.and.right",@"wifi",@"wave.3.right",@"personalhotspot"];
        id power=self.status[@"powers"][keys[indexPath.row]];
        cell.textLabel.text=titles[indexPath.row];cell.detailTextLabel.text=SWPowerText(power);
        cell.imageView.image=[UIImage systemImageNamed:symbols[indexPath.row]];
        cell.imageView.tintColor=[power isEqual:@YES]?SWGreen():UIColor.secondaryLabelColor;
        UISwitch *toggle=[UISwitch new];toggle.tag=indexPath.row;toggle.onTintColor=SWGreen();
        toggle.on=[power isEqual:@YES];toggle.accessibilityLabel=titles[indexPath.row];
        BOOL fresh=self.status.count&&NSDate.date.timeIntervalSince1970-[self.status[@"updated"] doubleValue]<15;
        BOOL waiting=self.pending.length&&NSDate.date.timeIntervalSince1970<self.pendingUntil;
        toggle.enabled=fresh&&![self.status[@"busy"] boolValue]&&!waiting&&[power isKindOfClass:NSNumber.class];
        [toggle addTarget:self action:@selector(radioChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView=toggle;
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    } else if(indexPath.section==1) {
        if(!self.devices.count) {
            cell.textLabel.text=@"Chưa có thiết bị để hiển thị";
            cell.detailTextLabel.text=self.status[@"clients"][@"error"]?:self.status[@"clients"][@"note"]?:@"Bật hotspot, kết nối iPhone 11 rồi bấm làm mới.";
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
        }else {
            NSDictionary *device=self.devices[indexPath.row];
            NSDictionary *aliases=SWRead(@"settings.plist")[@"aliases"];
            cell.textLabel.text=aliases[device[@"mac"]]?:device[@"name"];
            cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ · %@\n%@",device[@"ip"],device[@"mac"],device[@"evidence"]];
            cell.imageView.image=[UIImage systemImageNamed:@"iphone.radiowaves.left.and.right"];
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        }
    }else {
        NSArray *titles=@[@"Tắt cả bộ kết nối",@"Hoàn tác lần thay đổi gần nhất",@"Kiểm tra Internet",@"Mở cài đặt hotspot",@"Tùy chỉnh",@"Chẩn đoán",@"Dừng chia sẻ theo chế độ…"];
        NSArray *symbols=@[@"power",@"arrow.uturn.backward",@"network",@"gearshape",@"slider.horizontal.3",@"stethoscope",@"personalhotspot"];
        cell.textLabel.text=titles[indexPath.row];cell.imageView.image=[UIImage systemImageNamed:symbols[indexPath.row]];
        cell.imageView.tintColor=indexPath.row==0?UIColor.systemRedColor:SWGreen();
        cell.textLabel.textColor=indexPath.row==0?UIColor.systemRedColor:UIColor.labelColor;
        if(indexPath.row==1&&![self.status[@"canUndo"]boolValue])cell.textLabel.textColor=UIColor.tertiaryLabelColor;
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section==1&&self.devices.count){[self rename:self.devices[indexPath.row]];return;}
    if(indexPath.section!=2)return;
    switch(indexPath.row){
        case 0:[self send:@"off"];break;
        case 1:if([self.status[@"canUndo"]boolValue])[self send:@"undo"];break;
        case 2:[self send:@"probe"];break;
        case 3:[UIApplication.sharedApplication openURL:[NSURL URLWithString:@"App-Prefs:root=INTERNET_TETHERING"] options:@{} completionHandler:nil];break;
        case 4:[self settings];break;
        case 5:[self diagnostics];break;
        case 6:[self chooseStopMode:NO];break;
    }
}
- (void)rename:(NSDictionary *)device {
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Đặt tên thiết bị" message:@"Tên gắn với địa chỉ MAC hiện tại; MAC riêng tư đổi thì có thể cần đặt lại." preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field){field.placeholder=@"Ví dụ: iPhone 11 của Sếp";}];
    [alert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Lưu" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){
        NSString *name=[alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSMutableDictionary *settings=[SWRead(@"settings.plist")mutableCopy];
        NSMutableDictionary *aliases=[settings[@"aliases"]mutableCopy]?:[NSMutableDictionary dictionary];
        if(name.length)aliases[device[@"mac"]]=[name substringToIndex:MIN(name.length,80)];else [aliases removeObjectForKey:device[@"mac"]];
        settings[@"aliases"]=aliases;SWWrite(settings,@"settings.plist");[self reload];
    }]];[self presentViewController:alert animated:YES completion:nil];
}
- (void)chooseStopMode:(BOOL)save {
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:save?@"Chế độ khi tắt":@"Dừng chia sẻ" message:save?@"Áp dụng cho nút chính, biểu tượng và Control Center. Mặc định: Tắt cả bộ. Khôi phục phiên chỉ có sau khi bật bằng ShareWifi; dữ liệu phiên mất khi respring.":@"Chọn thao tác cho lần này. Hoàn tác vẫn khôi phục lần thay đổi gần nhất." preferredStyle:UIAlertControllerStyleAlert];
    for(NSString *mode in @[@"off",@"hotspotOnly",@"restoreSession"]) {
        NSString *title=SWStopTitle(mode);
        if(save&&[mode isEqual:SWStopMode()])title=[@"✓ " stringByAppendingString:title];
        UIAlertAction *choice=[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){
            if(save) {
                NSMutableDictionary *settings=[SWRead(@"settings.plist")mutableCopy];settings[@"stopMode"]=mode;
                SWWrite(settings,@"settings.plist");[self manualRefresh];
            }else [self send:mode];
        }];
        if(!save&&[mode isEqual:@"restoreSession"])choice.enabled=[self.status[@"canRestoreSession"]boolValue];
        [alert addAction:choice];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)settings {
    [self.navigationController pushViewController:[SWSettings new] animated:YES];
}
- (void)diagnostics {
    NSDictionary *redacted=@{@"version":self.status[@"version"]?:@"unknown",@"powers":self.status[@"powers"]?:@{},
        @"stopMode":SWStopMode(),@"canRestoreSession":self.status[@"canRestoreSession"]?:@NO,
        @"phase":self.status[@"phase"]?:@"unknown",@"apiError":self.status[@"apiError"]?:@"",
        @"message":self.status[@"message"]?:@"",@"iconTapHook":self.status[@"iconTapHook"]?:@NO,
        @"hapticTouchEnabled":@(SWHapticEnabled()),@"hapticTouchHook":self.status[@"hapticTouchHook"]?:@NO,
        @"systemCount":self.status[@"systemCount"]?:@"unknown",@"hotspotAPI":self.status[@"hotspotAPI"]?:@{}};
    NSData *data=[NSJSONSerialization dataWithJSONObject:redacted options:NSJSONWritingPrettyPrinted error:NULL];
    NSString *text=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]?:@"Chưa có trạng thái";
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Chẩn đoán ShareWifi" message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Sao chép" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){UIPasteboard.generalPasteboard.string=text;}]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

@interface SWAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) SWPanel *panel;
@end
@implementation SWAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)application;
    self.window=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];self.panel=[SWPanel new];
    self.window.rootViewController=[[UINavigationController alloc]initWithRootViewController:self.panel];
    self.window.tintColor=SWGreen();[self.window makeKeyAndVisible];
    UIApplicationShortcutItem *item=options[UIApplicationLaunchOptionsShortcutItemKey];
    if(item){dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/2),dispatch_get_main_queue(),^{[self shortcut:item];});return NO;}
    return YES;
}
- (void)shortcut:(UIApplicationShortcutItem *)item {
    if([item.type isEqualToString:@"on"]||[item.type isEqualToString:@"off"])[self.panel send:item.type];
    else if([item.type isEqualToString:@"devices"]) {
        [self.panel manualRefresh];
        [self.panel.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)item completionHandler:(void (^)(BOOL))completionHandler {
    (void)application;[self shortcut:item];completionHandler(YES);
}
- (void)applicationDidBecomeActive:(UIApplication *)application { (void)application;[self.panel resume]; }
- (void)applicationWillResignActive:(UIApplication *)application { (void)application;[self.panel pause]; }
@end
int main(int argc,char *argv[]) {
    @autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(SWAppDelegate.class));}
}
