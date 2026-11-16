#import "SWClients.h"
#import "SWArp.h"
#include <ifaddrs.h>
#include <net/if.h>
#include <sys/sysctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

static BOOL SWHotspotInterface(NSString *name) {
    if ([name hasPrefix:@"ap"] && name.length > 2) return YES;
    if ([name hasPrefix:@"bridge"] && name.length > 6) {
        NSString *digits = [name substringFromIndex:6];
        return [digits rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location == NSNotFound
            && digits.integerValue >= 100;
    }
    return NO;
}

static NSString *SWMac(NSString *raw) {
    NSString *body = [[raw componentsSeparatedByString:@","] lastObject];
    NSArray *pieces = [body componentsSeparatedByString:@":"];
    if (pieces.count != 6) return nil;
    NSMutableArray *out = [NSMutableArray array];
    for (NSString *piece in pieces) {
        unsigned int n = 0;
        NSScanner *scanner = [NSScanner scannerWithString:piece];
        if (piece.length < 1 || piece.length > 2 || ![scanner scanHexInt:&n] || !scanner.isAtEnd || n > 255) return nil;
        [out addObject:[NSString stringWithFormat:@"%02x", n]];
    }
    return [out componentsJoinedByString:@":"];
}

static NSDictionary *SWLeaseNames(BOOL *readable) {
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:@"/var/db/dhcpd_leases" encoding:NSUTF8StringEncoding error:&error];
    *readable = text != nil;
    if (!text || text.length > 4 * 1024 * 1024) return @{};
    NSMutableDictionary *names = [NSMutableDictionary dictionary];
    NSMutableDictionary *record = nil;
    for (NSString *line in [text componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSString *s = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if ([s isEqualToString:@"{"]) { record = [NSMutableDictionary dictionary]; continue; }
        if ([s isEqualToString:@"}"]) {
            NSString *mac = SWMac(record[@"hw_address"] ?: @"");
            NSString *name = record[@"name"];
            if (mac && name.length && name.length <= 128) names[mac] = name;
            record = nil; continue;
        }
        NSRange equal = [s rangeOfString:@"="];
        if (record && equal.location != NSNotFound) {
            NSString *key = [[s substringToIndex:equal.location] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            NSString *val = [[s substringFromIndex:equal.location + 1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            if (key.length < 80 && val.length < 256) record[key] = val;
        }
    }
    return names;
}

@interface SWArpContext : NSObject
@property(nonatomic,strong) NSDictionary *networks;
@property(nonatomic,strong) NSDictionary *names;
@property(nonatomic,strong) NSMutableArray *rows;
@end
@implementation SWArpContext
@end

static void SWFound(void *context, uint16_t index, const uint8_t ip[4], const uint8_t mac[6], int32_t expiry) {
    SWArpContext *c = (__bridge SWArpContext *)context;
    NSArray *networks = c.networks[@(index)];
    if (!networks || c.rows.count >= 64) return;
    uint32_t address; memcpy(&address, ip, 4);
    BOOL belongs = NO;
    for (NSDictionary *network in networks) {
        uint32_t own = [network[@"address"] unsignedIntValue], mask = [network[@"mask"] unsignedIntValue];
        if (address != own && mask && (address & mask) == (own & mask) &&
            (address & ~mask) != 0 && (address & ~mask) != ~mask) belongs = YES;
    }
    if (!belongs) return;
    NSString *hardware = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",mac[0],mac[1],mac[2],mac[3],mac[4],mac[5]];
    NSString *addressText = [NSString stringWithFormat:@"%u.%u.%u.%u",ip[0],ip[1],ip[2],ip[3]];
    [c.rows addObject:@{@"mac":hardware, @"ip":addressText,
                       @"name":c.names[hardware] ?: @"Thiết bị chưa có tên",
                       @"evidence":@"Vừa thấy trong ARP · chưa xác nhận còn kết nối",
                       @"arpExpiry":@(expiry)}];
}

NSDictionary *SWCollectClients(void) {
    struct ifaddrs *list = NULL;
    if (getifaddrs(&list) != 0) return @{@"rows":@[], @"error":@"Không đọc được giao diện mạng"};
    NSMutableDictionary *networks = [NSMutableDictionary dictionary];
    BOOL bridgeUp = NO;
    for (struct ifaddrs *p = list; p; p = p->ifa_next) {
        NSString *name = p->ifa_name ? @(p->ifa_name) : @"";
        if ((p->ifa_flags & IFF_UP) && [name hasPrefix:@"bridge"] && SWHotspotInterface(name)) bridgeUp = YES;
    }
    for (struct ifaddrs *p = list; p; p = p->ifa_next) {
        if (!p->ifa_addr || !p->ifa_netmask || p->ifa_addr->sa_family != AF_INET || !(p->ifa_flags & IFF_UP)) continue;
        NSString *name = p->ifa_name ? @(p->ifa_name) : @"";
        if (!SWHotspotInterface(name) && !(bridgeUp && [name isEqualToString:@"en2"])) continue;
        unsigned int index = if_nametoindex(p->ifa_name);
        if (!index) continue;
        NSMutableArray *items = networks[@(index)];
        if (!items) { items = [NSMutableArray array]; networks[@(index)] = items; }
        [items addObject:@{@"address":@(((struct sockaddr_in *)p->ifa_addr)->sin_addr.s_addr),
                           @"mask":@(((struct sockaddr_in *)p->ifa_netmask)->sin_addr.s_addr)}];
    }
    freeifaddrs(list);
    if (!networks.count) return @{@"rows":@[], @"note":@"Chưa có giao diện hotspot đang hoạt động"};
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, 2, 0x400};
    size_t size = 0;
    if (sysctl(mib, 6, NULL, &size, NULL, 0) != 0 || size > 4 * 1024 * 1024)
        return @{@"rows":@[], @"error":@"Không đọc được bảng ARP"};
    if (!size) return @{@"rows":@[]};
    uint8_t *bytes = NULL; BOOL fetched = NO;
    for (int retry = 0; retry < 3; retry++) {
        free(bytes); bytes = calloc(1, size + 4096);
        if (!bytes) break;
        size += 4096;
        if (sysctl(mib, 6, bytes, &size, NULL, 0) == 0) { fetched = YES; break; }
        if (errno != ENOMEM || size > 4 * 1024 * 1024) break;
    }
    if (!fetched) { free(bytes); return @{@"rows":@[], @"error":@"Bảng ARP chưa sẵn sàng"}; }
    BOOL readable = NO;
    SWArpContext *c = [SWArpContext new];
    c.networks = networks; c.names = SWLeaseNames(&readable); c.rows = [NSMutableArray array];
    int parsed = SWParseArp(bytes, size, SWFound, (__bridge void *)c);
    free(bytes);
    if (parsed < 0) return @{@"rows":@[], @"error":@"Định dạng ARP không khớp; cần chẩn đoán trên máy"};
    NSMutableSet *seen = [NSMutableSet set]; NSMutableArray *unique = [NSMutableArray array];
    for (NSDictionary *row in c.rows) if (![seen containsObject:row[@"mac"]]) {
        [unique addObject:row]; [seen addObject:row[@"mac"]];
    }
    return @{@"rows":unique, @"leaseNamesReadable":@(readable),
             @"note":@"ARP có thể giữ máy đã rời đi. Số kết nối hệ thống và danh sách này có thể khác nhau."};
}
