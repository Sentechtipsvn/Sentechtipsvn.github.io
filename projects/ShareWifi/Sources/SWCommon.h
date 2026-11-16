#import <Foundation/Foundation.h>
#import <sys/stat.h>

#define SW_BUNDLE @"vn.sentechtips.sharewifi"
#define SW_DIRECTORY @"/var/mobile/Library/ShareWifi"
#define SW_REQUEST CFSTR("vn.sentechtips.sharewifi.request")
#define SW_STATUS CFSTR("vn.sentechtips.sharewifi.status")
#define SW_CC_TOGGLE CFSTR("vn.sentechtips.sharewifi.cc-toggle")
#define SW_REFRESH CFSTR("vn.sentechtips.sharewifi.refresh")

static inline NSString *SWPath(NSString *name) {
    return [SW_DIRECTORY stringByAppendingPathComponent:name];
}
static inline BOOL SWWrite(NSDictionary *value, NSString *name) {
    NSFileManager *fm = NSFileManager.defaultManager;
    [fm createDirectoryAtPath:SW_DIRECTORY withIntermediateDirectories:YES
                  attributes:@{NSFilePosixPermissions:@0700} error:NULL];
    chmod(SW_DIRECTORY.fileSystemRepresentation, 0700);
    BOOL ok = [value writeToFile:SWPath(name) atomically:YES];
    if (ok) chmod(SWPath(name).fileSystemRepresentation, 0600);
    return ok;
}
static inline NSDictionary *SWRead(NSString *name) {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:SWPath(name)];
    return [d isKindOfClass:NSDictionary.class] ? d : @{};
}
static inline NSString *SWPowerText(id value) {
    return [value isKindOfClass:NSNumber.class] ? ([value boolValue] ? @"Bật" : @"Tắt") : @"Chưa đọc được";
}

// Unknown configuration values keep the established full-off default.
static inline NSString *SWStopMode(void) {
    id mode=SWRead(@"settings.plist")[@"stopMode"];
    return [@[@"hotspotOnly",@"restoreSession"] containsObject:mode ?: @""] ? mode : @"off";
}
static inline NSString *SWStopTitle(NSString *mode) {
    if([mode isEqual:@"hotspotOnly"])return @"Chỉ tắt hotspot";
    if([mode isEqual:@"restoreSession"])return @"Khôi phục trước khi chia sẻ";
    return @"Tắt cả bộ kết nối";
}
