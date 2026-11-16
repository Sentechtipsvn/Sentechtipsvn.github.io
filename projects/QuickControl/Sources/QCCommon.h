#import <UIKit/UIKit.h>
#import <sys/stat.h>
#import "QCPolicy.h"
#define QC_BUNDLE @"vn.sentechtips.quickcontrol"
#define QC_VERSION @"0.1.0 beta 1"
#define QC_DIRECTORY @"/var/mobile/Library/QuickControl"
#define QC_TOGGLE CFSTR("vn.sentechtips.quickcontrol.toggle")
#define QC_CHANGED CFSTR("vn.sentechtips.quickcontrol.changed")
#define QC_STATUS CFSTR("vn.sentechtips.quickcontrol.status")
static inline NSDictionary *QCRead(NSString *name) {
    NSDictionary *d=[NSDictionary dictionaryWithContentsOfFile:[QC_DIRECTORY stringByAppendingPathComponent:name]];
    return [d isKindOfClass:NSDictionary.class]?d:@{};
}
static inline BOOL QCWrite(NSDictionary *d,NSString *name) {
    [NSFileManager.defaultManager createDirectoryAtPath:QC_DIRECTORY withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:NULL];
    chmod(QC_DIRECTORY.fileSystemRepresentation,0700);
    NSString *path=[QC_DIRECTORY stringByAppendingPathComponent:name];
    BOOL ok=[d writeToFile:path atomically:YES];if(ok)chmod(path.fileSystemRepresentation,0600);return ok;
}
static inline void QCNotify(CFStringRef name) {CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),name,NULL,NULL,YES);}
static inline UIColor *QCGreen(void) {return [UIColor colorWithRed:0.10 green:0.61 blue:0.40 alpha:1];}
static inline NSString *QCString(id value) {return [value isKindOfClass:NSString.class]?value:@"";}
static inline NSArray *QCDefaults(void) {
    return @[
        @{@"id":@"sharewifi",@"title":@"ShareWifi",@"kind":@"sharewifi",@"value":@"",@"symbol":@"personalhotspot"},
        @{@"id":@"calculator",@"title":@"Máy tính",@"kind":@"app",@"value":@"com.apple.calculator",@"symbol":@"plus.forwardslash.minus"},
        @{@"id":@"notes",@"title":@"Ghi chú",@"kind":@"app",@"value":@"com.apple.mobilenotes",@"symbol":@"note.text"},
        @{@"id":@"qr",@"title":@"QR nhanh",@"kind":@"url",@"value":@"quickcontrol://qr",@"symbol":@"qrcode"},
        @{@"id":@"camera",@"title":@"Máy ảnh",@"kind":@"app",@"value":@"com.apple.camera",@"symbol":@"camera"},
        @{@"id":@"settings",@"title":@"Cài đặt",@"kind":@"app",@"value":@"com.apple.Preferences",@"symbol":@"gearshape"}];
}
static inline NSArray *QCItems(NSDictionary *settings) {
    id raw=settings[@"items"];if(![raw isKindOfClass:NSArray.class])return QCDefaults();
    NSMutableArray *out=[NSMutableArray array];
    for(id entry in raw) {
        if(![entry isKindOfClass:NSDictionary.class])continue;
        NSString *title=QCString(entry[@"title"]),*kind=QCString(entry[@"kind"]),*value=QCString(entry[@"value"]);
        if(!title.length||title.length>60)continue;
        BOOL valid=[kind isEqual:@"sharewifi"]||([kind isEqual:@"app"]&&QCBundleValid(value.UTF8String))||
            ([kind isEqual:@"url"]&&QCURLValid(value.UTF8String))||([kind isEqual:@"shortcut"]&&value.length&&value.length<=200);
        if(!valid)continue;
        NSString *symbol=QCString(entry[@"symbol"]);if(!symbol.length||symbol.length>80)symbol=@"square.grid.2x2";
        [out addObject:@{@"id":QCString(entry[@"id"]),@"title":title,@"kind":kind,@"value":value,@"symbol":symbol}];
        if(out.count==12)break;
    }
    return out;
}
static inline BOOL QCEnabled(NSDictionary *s) {return ![s[@"enabled"]isKindOfClass:NSNumber.class]||[s[@"enabled"]boolValue];}
static inline BOOL QCRight(NSDictionary *s) {return ![s[@"right"]isKindOfClass:NSNumber.class]||[s[@"right"]boolValue];}
static inline double QCStoredPosition(NSDictionary *s) {return QCPosition([s[@"position"]isKindOfClass:NSNumber.class]?[s[@"position"]doubleValue]:0.5);}
static inline NSDictionary *QCSWStatus(void) {
    NSDictionary *s=[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/ShareWifi/status.plist"];
    return [s isKindOfClass:NSDictionary.class]?s:@{};
}
static inline BOOL QCSWFresh(NSDictionary *s) {
    if(![s[@"updated"]isKindOfClass:NSNumber.class]||![s[@"version"]isKindOfClass:NSString.class])return NO;
    return QCRecent(NSDate.date.timeIntervalSince1970,[s[@"updated"]doubleValue],90)&&[s[@"version"]hasPrefix:@"0.2."]&&[s[@"powers"]isKindOfClass:NSDictionary.class]&&[s[@"powers"][@"hotspot"]isKindOfClass:NSNumber.class];
}
static inline NSURL *QCShortcutURL(NSString *name) {
    NSURLComponents *c=[NSURLComponents new];c.scheme=@"shortcuts";c.host=@"run-shortcut";
    c.queryItems=@[[NSURLQueryItem queryItemWithName:@"name" value:name]];return c.URL;
}
