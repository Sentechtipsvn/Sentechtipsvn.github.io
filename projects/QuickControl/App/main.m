#import <UIKit/UIKit.h>
#import <CoreImage/CoreImage.h>
#import "QCCommon.h"

@interface QCQR : UIViewController
@property(nonatomic,strong) UITextView *input;
@property(nonatomic,strong) UIImageView *imageView;
@property(nonatomic,strong) UIImage *qr;
@end
@implementation QCQR
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"QR nhanh";self.view.backgroundColor=UIColor.systemGroupedBackgroundColor;
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
    UIScrollView *scroll=[UIScrollView new];scroll.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:scroll];
    UIStackView *stack=[UIStackView new];stack.axis=UILayoutConstraintAxisVertical;stack.spacing=16;stack.translatesAutoresizingMaskIntoConstraints=NO;[scroll addSubview:stack];
    UILabel *hint=[UILabel new];hint.text=@"Nhập nội dung hoặc đường dẫn để tạo QR ngay trên máy. VietQR theo ngân hàng: thêm phím tắt VietQR của Sếp vào khay.";
    hint.numberOfLines=0;hint.textColor=UIColor.secondaryLabelColor;hint.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];[stack addArrangedSubview:hint];
    self.input=[UITextView new];self.input.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];self.input.backgroundColor=UIColor.secondarySystemGroupedBackgroundColor;self.input.layer.cornerRadius=14;
    self.input.accessibilityLabel=@"Nội dung mã QR";self.input.textContainerInset=UIEdgeInsetsMake(12,12,12,12);[self.input.heightAnchor constraintEqualToConstant:132].active=YES;[stack addArrangedSubview:self.input];
    UIButton *make=[UIButton buttonWithType:UIButtonTypeSystem];UIButtonConfiguration *c=UIButtonConfiguration.filledButtonConfiguration;c.title=@"Tạo mã QR";c.baseBackgroundColor=QCGreen();make.configuration=c;
    [make.heightAnchor constraintGreaterThanOrEqualToConstant:48].active=YES;[make addTarget:self action:@selector(generate) forControlEvents:UIControlEventTouchUpInside];[stack addArrangedSubview:make];
    self.imageView=[UIImageView new];self.imageView.backgroundColor=UIColor.whiteColor;self.imageView.contentMode=UIViewContentModeScaleAspectFit;
    [self.imageView.heightAnchor constraintEqualToAnchor:self.imageView.widthAnchor].active=YES;[stack addArrangedSubview:self.imageView];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],[scroll.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],[scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:20],[stack.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:20],[stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-30]]];
}
- (void)notice:(NSString *)text {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"QR nhanh" message:text preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];
}
- (void)generate {
    [self.view endEditing:YES];NSData *data=[self.input.text dataUsingEncoding:NSUTF8StringEncoding];
    if(!data.length||data.length>1200){[self notice:@"Nhập nội dung tối đa 1.200 byte UTF-8. Tiếng Việt có thể dùng nhiều byte cho mỗi ký tự."];return;}
    CIFilter *filter=[CIFilter filterWithName:@"CIQRCodeGenerator"];[filter setValue:data forKey:@"inputMessage"];[filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    CIImage *output=filter.outputImage;if(!output){[self notice:@"Chưa tạo được QR từ nội dung này."];return;}
    CGImageRef cg=[[CIContext contextWithOptions:nil]createCGImage:output fromRect:output.extent];
    if(!cg){[self notice:@"Không dựng được ảnh QR."];return;}
    UIImage *base=[UIImage imageWithCGImage:cg];CGImageRelease(cg);
    CGFloat modules=output.extent.size.width,scale=MAX(1,floor(600/(modules+8))),size=(modules+8)*scale;
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat defaultFormat];format.scale=1;format.opaque=YES;
    self.qr=[[[UIGraphicsImageRenderer alloc]initWithSize:CGSizeMake(size,size) format:format]imageWithActions:^(UIGraphicsImageRendererContext *ctx){
        [UIColor.whiteColor setFill];[ctx fillRect:CGRectMake(0,0,size,size)];CGContextSetInterpolationQuality(ctx.CGContext,kCGInterpolationNone);
        [base drawInRect:CGRectMake(4*scale,4*scale,modules*scale,modules*scale)];
    }];self.imageView.image=self.qr;
}
- (void)share {
    if(!self.qr){[self notice:@"Tạo mã QR trước khi chia sẻ."];return;}
    UIActivityViewController *a=[[UIActivityViewController alloc]initWithActivityItems:@[self.qr] applicationActivities:nil];a.popoverPresentationController.barButtonItem=self.navigationItem.rightBarButtonItem;[self presentViewController:a animated:YES completion:nil];
}
@end

@interface QCPinEditor : UITableViewController
@property(nonatomic,strong) NSDictionary *item;
@property(nonatomic,copy) void (^saved)(NSDictionary *);
@property(nonatomic,strong) UITextField *nameField;
@property(nonatomic,strong) UITextField *targetField;
@property(nonatomic,strong) UISegmentedControl *kind;
@end
@implementation QCPinEditor
- (instancetype)init {return [super initWithStyle:UITableViewStyleInsetGrouped];}
- (void)viewDidLoad {
    [super viewDidLoad];self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=64;self.title=self.item?@"Sửa tiện ích":@"Thêm tiện ích";
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.kind=[[UISegmentedControl alloc]initWithItems:@[@"Ứng dụng",@"URL",@"Phím tắt"]];self.kind.selectedSegmentIndex=1;
    NSArray *kinds=@[@"app",@"url",@"shortcut"];NSUInteger selected=[kinds indexOfObject:self.item[@"kind"]?:@"url"];
    if(selected!=NSNotFound)self.kind.selectedSegmentIndex=(NSInteger)selected;
    [self.kind addTarget:self action:@selector(kindChanged) forControlEvents:UIControlEventValueChanged];
    self.nameField=[UITextField new];self.nameField.placeholder=@"Tên hiển thị";self.nameField.text=self.item[@"title"];
    self.targetField=[UITextField new];self.targetField.text=self.item[@"value"];self.targetField.autocorrectionType=UITextAutocorrectionTypeNo;self.targetField.autocapitalizationType=UITextAutocapitalizationTypeNone;
    self.nameField.clearButtonMode=self.targetField.clearButtonMode=UITextFieldViewModeWhileEditing;
    if([self.item[@"kind"]isEqual:@"sharewifi"]){self.kind.enabled=NO;self.targetField.enabled=NO;}
    [self kindChanged];
}
- (void)kindChanged {
    self.targetField.placeholder=@[@"com.apple.mobilenotes",@"Ứng dụng:// hoặc https://…",@"Tên chính xác của phím tắt"][self.kind.selectedSegmentIndex];
    self.targetField.keyboardType=self.kind.selectedSegmentIndex==1?UIKeyboardTypeURL:UIKeyboardTypeDefault;
    [self.tableView reloadData];
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s {(void)t;(void)s;return 3;}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    (void)t;UITableViewCell *c=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];c.selectionStyle=UITableViewCellSelectionStyleNone;
    UIView *content=p.row==0?self.kind:(p.row==1?self.nameField:self.targetField);content.translatesAutoresizingMaskIntoConstraints=NO;[c.contentView addSubview:content];
    [NSLayoutConstraint activateConstraints:@[[content.leadingAnchor constraintEqualToAnchor:c.contentView.leadingAnchor constant:16],[content.trailingAnchor constraintEqualToAnchor:c.contentView.trailingAnchor constant:-16],[content.topAnchor constraintEqualToAnchor:c.contentView.topAnchor constant:12],[content.bottomAnchor constraintEqualToAnchor:c.contentView.bottomAnchor constant:-12],[content.heightAnchor constraintGreaterThanOrEqualToConstant:32]]];return c;
}
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s {
    (void)t;(void)s;
    if([self.item[@"kind"]isEqual:@"sharewifi"])return @"Tiện ích tích hợp ShareWifi: có thể đổi tên, kéo sắp xếp hoặc xóa khỏi khay. Chế độ bật/tắt chọn trong ShareWifi.";
    return @"Ứng dụng: nhập Bundle ID. URL: nhập địa chỉ ứng dụng hoặc trang web. Phím tắt: nhập đúng tên phím tắt đã cài, ví dụ VietQR. QuickControl gửi yêu cầu mở; ứng dụng hoặc phím tắt nhận sẽ xử lý tiếp.";
}
- (void)save {
    NSString *title=[self.nameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *value=[self.targetField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *kind=[self.item[@"kind"]isEqual:@"sharewifi"]?@"sharewifi":@[@"app",@"url",@"shortcut"][self.kind.selectedSegmentIndex];
    BOOL valid=[kind isEqual:@"sharewifi"]||([kind isEqual:@"app"]&&QCBundleValid(value.UTF8String))||([kind isEqual:@"url"]&&QCURLValid(value.UTF8String)&&[NSURL URLWithString:value])||([kind isEqual:@"shortcut"]&&value.length&&value.length<=200);
    if(!title.length||title.length>60||!valid){
        UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Kiểm tra nội dung" message:@"Tên từ 1–60 ký tự. Bundle ID cần đúng định dạng; URL cần có scheme; tên phím tắt tối đa 200 ký tự." preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];return;
    }
    NSString *symbol=[kind isEqual:@"shortcut"]?@"bolt.fill":([kind isEqual:@"url"]?@"link":@"app");
    if([self.item[@"kind"]isEqual:kind]&&QCString(self.item[@"symbol"]).length)symbol=self.item[@"symbol"];
    self.saved(@{@"id":self.item[@"id"]?:NSUUID.UUID.UUIDString,@"title":title,@"kind":kind,@"value":value?:@"",@"symbol":symbol});
}
@end

@interface QCSettings : UITableViewController
@property(nonatomic,strong) NSMutableDictionary *settings;
@property(nonatomic,strong) NSMutableArray *items;
- (void)reload;
- (void)openQR;
@end
@implementation QCSettings
- (instancetype)init {return [super initWithStyle:UITableViewStyleInsetGrouped];}
- (void)viewDidLoad {
    [super viewDidLoad];self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=60;self.title=@"QuickControl";self.navigationItem.rightBarButtonItem=self.editButtonItem;[self reload];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reload) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)reload {self.settings=[QCRead(@"settings.plist")mutableCopy];self.items=[QCItems(self.settings)mutableCopy];[self.tableView reloadData];}
- (BOOL)persist {
    self.settings[@"items"]=self.items;
    if(!QCWrite(self.settings,@"settings.plist")){[self notice:@"Không lưu được tùy chọn. Cần cài bản .deb trong môi trường jailbreak."];return NO;}
    QCNotify(QC_CHANGED);[self.tableView reloadData];return YES;
}
- (void)notice:(NSString *)text {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"QuickControl" message:text preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]];[self presentViewController:a animated:YES completion:nil];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t {(void)t;return 4;}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s {(void)t;return s==0?1:(s==1?3:(s==2?(NSInteger)self.items.count+1:3));}
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s {(void)t;return @[@"Khay tiện ích",@"Tay nắm cạnh màn hình",@"Tiện ích trong khay",@"Công cụ"][s];}
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s {
    (void)t;if(s==1)return @"Chạm tay nắm hoặc kéo vào trong để mở. Kéo lên/xuống để đổi vị trí. Chạm vùng ngoài để đóng. Khay ẩn khi khóa máy.";
    if(s==2)return @"Tối đa 12 nút. Chạm để sửa; bấm Sửa để xóa hoặc kéo đổi thứ tự. ShareWifi cần bản 0.2.x đang nạp.";
    if(s==3)return @"QuickControl 0.1.0 beta 1 · © Sentechtipsvn\niPhone 7 Plus · iOS 15.8.8 · Dopamine rootless. Bản beta cần thử trên máy thật.";
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    (void)t;UITableViewCell *c=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];c.textLabel.numberOfLines=0;c.detailTextLabel.numberOfLines=0;c.imageView.tintColor=QCGreen();
    if(p.section==0){c.textLabel.text=@"Mở khay QuickControl";c.imageView.image=[UIImage systemImageNamed:@"square.grid.2x2.fill"];}
    if(p.section==1) {
        c.textLabel.text=@[@"Bật QuickControl",@"Vị trí tay nắm",@"Đặt lại vị trí giữa cạnh"][p.row];
        if(p.row==0){UISwitch *s=[UISwitch new];s.on=QCEnabled(self.settings);s.onTintColor=QCGreen();[s addTarget:self action:@selector(enable:) forControlEvents:UIControlEventValueChanged];c.accessoryView=s;}
        if(p.row==1){c.detailTextLabel.text=QCRight(self.settings)?@"Cạnh phải":@"Cạnh trái";c.accessoryType=UITableViewCellAccessoryDisclosureIndicator;}
    }
    if(p.section==2) {
        if((NSUInteger)p.row==self.items.count){c.textLabel.text=@"Thêm tiện ích";c.imageView.image=[UIImage systemImageNamed:@"plus.circle.fill"];}
        else {NSDictionary *i=self.items[(NSUInteger)p.row];c.textLabel.text=i[@"title"];c.detailTextLabel.text=[i[@"kind"]isEqual:@"sharewifi"]?@"Bật/tắt theo chế độ đã chọn trong ShareWifi":i[@"value"];c.imageView.image=[UIImage systemImageNamed:i[@"symbol"]]?:[UIImage systemImageNamed:@"app"];}
    }
    if(p.section==3){c.textLabel.text=@[@"Tạo QR offline",@"Chẩn đoán",@"Khôi phục 6 tiện ích mặc định"][p.row];c.imageView.image=[UIImage systemImageNamed:@[@"qrcode",@"stethoscope",@"arrow.counterclockwise"][p.row]];}
    return c;
}
- (void)enable:(UISwitch *)sender {self.settings[@"enabled"]=@(sender.on);[self persist];}
- (void)openQR {[self.navigationController pushViewController:[QCQR new] animated:YES];}
- (void)editPin:(NSInteger)index {
    if(index<0&&self.items.count>=12){[self notice:@"Khay đã đủ 12 nút. Xóa bớt một nút để thêm."];return;}
    QCPinEditor *e=[QCPinEditor new];e.item=index<0?nil:self.items[(NSUInteger)index];
    __weak QCSettings *weakSelf=self;e.saved=^(NSDictionary *item){QCSettings *s=weakSelf;if(!s)return;
        if(index<0)[s.items addObject:item];else if((NSUInteger)index<s.items.count)s.items[(NSUInteger)index]=item;
        if([s persist])[s.navigationController popViewControllerAnimated:YES];
    };[self.navigationController pushViewController:e animated:YES];
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
    [t deselectRowAtIndexPath:p animated:YES];
    if(p.section==0) {
        if(!QCEnabled(self.settings)){[self notice:@"Bật QuickControl trước khi mở khay."];return;}
        NSDictionary *status=QCRead(@"status.plist");
        if(![status[@"version"]isEqual:QC_VERSION]){[self notice:@"Cài .deb, respring rồi chờ khoảng 5 giây để nạp khay vào SpringBoard."];return;}
        QCNotify(QC_TOGGLE);return;
    }
    if(p.section==1&&p.row==1){self.settings[@"right"]=@(!QCRight(self.settings));[self persist];}
    if(p.section==1&&p.row==2){self.settings[@"position"]=@0.5;[self persist];}
    if(p.section==2)[self editPin:(NSUInteger)p.row==self.items.count?-1:p.row];
    if(p.section==3&&p.row==0)[self openQR];
    if(p.section==3&&p.row==1) {
        NSDictionary *status=QCRead(@"status.plist");NSData *data=[NSJSONSerialization dataWithJSONObject:status options:NSJSONWritingPrettyPrinted error:NULL];
        [self notice:[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]?:@"Chưa nhận trạng thái SpringBoard."];
    }
    if(p.section==3&&p.row==2) {
        UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Khôi phục tiện ích?" message:@"Thay danh sách hiện tại bằng 6 nút mặc định. Không thay đổi ứng dụng hoặc phím tắt đã cài." preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:@"Khôi phục" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action){self.items=[QCDefaults()mutableCopy];[self persist];}]];[self presentViewController:a animated:YES completion:nil];
    }
}
- (BOOL)tableView:(UITableView *)t canEditRowAtIndexPath:(NSIndexPath *)p {(void)t;return p.section==2&&(NSUInteger)p.row<self.items.count;}
- (BOOL)tableView:(UITableView *)t canMoveRowAtIndexPath:(NSIndexPath *)p {return [self tableView:t canEditRowAtIndexPath:p];}
- (NSIndexPath *)tableView:(UITableView *)t targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)source toProposedIndexPath:(NSIndexPath *)destination {
    (void)t;(void)source;NSInteger row=destination.section<2?0:(destination.section>2?(NSInteger)self.items.count-1:destination.row);return [NSIndexPath indexPathForRow:MIN(MAX(row,0),(NSInteger)self.items.count-1) inSection:2];
}
- (void)tableView:(UITableView *)t moveRowAtIndexPath:(NSIndexPath *)from toIndexPath:(NSIndexPath *)to {
    (void)t;id item=self.items[(NSUInteger)from.row];[self.items removeObjectAtIndex:(NSUInteger)from.row];[self.items insertObject:item atIndex:(NSUInteger)to.row];[self persist];
}
- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)p {
    (void)t;if(style==UITableViewCellEditingStyleDelete&&(NSUInteger)p.row<self.items.count){[self.items removeObjectAtIndex:(NSUInteger)p.row];[self persist];}
}
@end

@interface QCDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) QCSettings *settings;
@end
@implementation QCDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)app;(void)options;self.window=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];self.settings=[QCSettings new];
    self.window.rootViewController=[[UINavigationController alloc]initWithRootViewController:self.settings];self.window.tintColor=QCGreen();[self.window makeKeyAndVisible];return YES;
}
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
    (void)app;(void)options;if(![url.scheme.lowercaseString isEqual:@"quickcontrol"])return NO;
    if([url.host isEqual:@"qr"]){[self.settings.navigationController popToRootViewControllerAnimated:NO];[self.settings openQR];return YES;}
    return YES;
}
@end
int main(int argc,char *argv[]) {@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(QCDelegate.class));}}
