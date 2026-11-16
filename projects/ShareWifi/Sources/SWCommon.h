#import <Foundation/Foundation.h>
#import <sys/stat.h>
#import "SWRadioAction.h"

#define SW_VERSION @"0.2.1 beta 1"

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
static inline NSArray<NSString *> *SWRadioKeys(void) {
    return @[@"data", @"wifi", @"bluetooth", @"hotspot"];
}
static inline NSString *SWRadioName(NSString *key) {
    return @{@"data":@"Dữ liệu di động", @"wifi":@"Wi-Fi", @"bluetooth":@"Bluetooth", @"hotspot":@"Điểm truy cập cá nhân"}[key] ?: key;
}
static inline NSString *SWRadioSymbol(NSString *key) {
    return @{@"data":@"antenna.radiowaves.left.and.right", @"wifi":@"wifi", @"bluetooth":@"wave.3.right", @"hotspot":@"personalhotspot"}[key] ?: @"switch.2";
}
static inline BOOL SWHapticEnabled(void) {
    id value = SWRead(@"settings.plist")[@"hapticTouchEnabled"];
    return [value isKindOfClass:NSNumber.class] ? [value boolValue] : YES;
}
static inline BOOL SWShowHapticRadio(NSString *key) {
    id values = SWRead(@"settings.plist")[@"hapticRadios"];
    id value = [values isKindOfClass:NSDictionary.class] ? values[key] : nil;
    return [value isKindOfClass:NSNumber.class] ? [value boolValue] : YES;
}
static inline NSString *SWRadioCommand(NSString *key, BOOL on) {
    return [NSString stringWithFormat:@"set.%@.%d", key, on ? 1 : 0];
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
