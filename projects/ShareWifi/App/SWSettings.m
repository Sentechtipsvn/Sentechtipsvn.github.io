#import "SWSettings.h"
#import "SWCommon.h"

static BOOL SWSaveSetting(UIViewController *owner, NSString *key, id value) {
    NSMutableDictionary *settings=[SWRead(@"settings.plist") mutableCopy];
    settings[key]=value;
    if (SWWrite(settings,@"settings.plist")) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),SW_REFRESH,NULL,NULL,YES);
        [[UISelectionFeedbackGenerator new] selectionChanged];
        return YES;
    }
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Chưa lưu được tùy chỉnh" message:@"Thử lại sau khi cài ShareWifi và respring." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]];
    [owner presentViewController:alert animated:YES completion:nil];
    return NO;
}

static UITableViewCell *SWSettingsCell(void) {
    UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.textLabel.adjustsFontForContentSizeCategory=YES; cell.textLabel.numberOfLines=0;
    cell.detailTextLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    cell.detailTextLabel.adjustsFontForContentSizeCategory=YES;cell.detailTextLabel.numberOfLines=0;
    cell.detailTextLabel.textColor=UIColor.secondaryLabelColor;
    return cell;
}

@interface SWHapticSettings : UITableViewController
@end
@implementation SWHapticSettings
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"Haptic Touch";
    self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=60;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView;return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { (void)tableView;return section==0?1:4; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;return section==0?@"Màn hình chính":@"Kết nối trong menu";
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section==1)return @"Chọn những kết nối muốn điều khiển khi nhấn giữ biểu tượng ShareWifi. Đóng rồi mở lại menu để thấy thay đổi. Tắt Haptic Touch vẫn giữ các mục mở bảng điều khiển và thao tác của iOS.";
    BOOL hooked=[SWRead(@"status.plist")[@"hapticTouchHook"] boolValue];
    return hooked?@"Nhấn giữ biểu tượng ShareWifi để bật hoặc tắt từng kết nối ngay trên màn hình chính.":@"Menu chưa sẵn sàng. Sau khi cập nhật ShareWifi, hãy respring rồi thử lại. Các nút gạt trong ứng dụng vẫn dùng được.";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    (void)tableView;UITableViewCell *cell=SWSettingsCell();
    UISwitch *toggle=[UISwitch new]; toggle.onTintColor=self.view.tintColor;
    if (path.section==0) {
        cell.textLabel.text=@"Haptic Touch";cell.detailTextLabel.text=@"Menu điều khiển khi nhấn giữ biểu tượng";
        toggle.on=SWHapticEnabled();toggle.tag=0;
    } else {
        NSString *key=SWRadioKeys()[path.row];cell.textLabel.text=SWRadioName(key);
        cell.imageView.image=[UIImage systemImageNamed:SWRadioSymbol(key)];
        toggle.on=SWShowHapticRadio(key);toggle.enabled=SWHapticEnabled();toggle.tag=path.row+1;
    }
    toggle.accessibilityLabel=cell.textLabel.text;
    [toggle addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView=toggle;cell.selectionStyle=UITableViewCellSelectionStyleNone;return cell;
}
- (void)changed:(UISwitch *)sender {
    if (sender.tag==0) SWSaveSetting(self,@"hapticTouchEnabled",@(sender.on));
    else {
        id saved=SWRead(@"settings.plist")[@"hapticRadios"];
        NSMutableDictionary *radios=[saved isKindOfClass:NSDictionary.class]?[saved mutableCopy]:[NSMutableDictionary dictionary];
        radios[SWRadioKeys()[sender.tag-1]]=@(sender.on);SWSaveSetting(self,@"hapticRadios",radios);
    }
    [self.tableView reloadData];
}
@end

@implementation SWSettings
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"Tùy chỉnh";
    self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=60;
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated];[self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView;return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { (void)tableView;return section==1?3:1; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;return @[@"Biểu tượng ShareWifi",@"Chế độ khi tắt",@"Haptic Touch"][section];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if(section==0)return @"Bật: chạm biểu tượng để bật/tắt cả bộ. Tắt: chạm để mở ứng dụng. Nhấn giữ → Bảng điều khiển luôn mở được ứng dụng.";
    if(section==1)return @"Áp dụng cho nút chính, chạm biểu tượng và Control Center. Nút gạt từng kết nối chỉ đổi mục đã chọn. Khôi phục phiên cần có phiên đã lưu; phiên mất sau respring.";
    return @"Tùy chọn menu nhấn giữ riêng cho ShareWifi.";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    (void)tableView;UITableViewCell *cell=SWSettingsCell();
    if(path.section==0) {
        cell.textLabel.text=@"Chạm để bật/tắt cả bộ";
        UISwitch *toggle=[UISwitch new];toggle.onTintColor=self.view.tintColor;
        toggle.on=![SWRead(@"settings.plist")[@"disableIconToggle"] boolValue];toggle.accessibilityLabel=cell.textLabel.text;
        [toggle addTarget:self action:@selector(iconChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView=toggle;cell.selectionStyle=UITableViewCellSelectionStyleNone;
    } else if(path.section==1) {
        NSString *mode=@[@"off",@"hotspotOnly",@"restoreSession"][path.row];
        cell.textLabel.text=SWStopTitle(mode);cell.accessoryType=[SWStopMode() isEqual:mode]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
    } else {
        cell.textLabel.text=@"Haptic Touch";cell.detailTextLabel.text=SWHapticEnabled()?@"Bật":@"Tắt";
        cell.imageView.image=[UIImage systemImageNamed:@"hand.tap"];cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}
- (void)iconChanged:(UISwitch *)sender {
    SWSaveSetting(self,@"disableIconToggle",@(!sender.on));[self.tableView reloadData];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    if(path.section==1) {
        SWSaveSetting(self,@"stopMode",@[@"off",@"hotspotOnly",@"restoreSession"][path.row]);[self.tableView reloadData];
    } else if(path.section==2) [self.navigationController pushViewController:[SWHapticSettings new] animated:YES];
}
@end
