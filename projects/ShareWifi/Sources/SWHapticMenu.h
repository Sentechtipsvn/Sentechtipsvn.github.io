#import <Foundation/Foundation.h>

// Returns NO without replacing the existing menu if the runtime ABI differs.
BOOL SWInstallHapticMenu(NSDictionary *(^powers)(void), void (^perform)(NSString *action));
