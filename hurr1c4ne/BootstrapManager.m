#import "BootstrapManager.h"
#import <UIKit/UIKit.h>

@implementation BootstrapManager

+ (instancetype)sharedManager {
    static BootstrapManager *manager;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        manager = [[BootstrapManager alloc] init];
    });

    return manager;
}

- (HCBootstrapStatus)status {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *bootstrapPath =
        [NSHomeDirectory() stringByAppendingPathComponent:
            @"Library/hurr1c4ne/bootstrap"];

    BOOL isDirectory = NO;

    BOOL exists = [fileManager fileExistsAtPath:bootstrapPath
                                    isDirectory:&isDirectory];

    if (exists && isDirectory) {
        return HCBootstrapStatusInstalled;
    }

    return HCBootstrapStatusNotInstalled;
}

- (NSString *)statusDescription {
    switch ([self status]) {
        case HCBootstrapStatusInstalled:
            return @"Bootstrap data directory exists";

        case HCBootstrapStatusNotInstalled:
            return @"Procursus bootstrap is not installed";

        case HCBootstrapStatusIncompatible:
            return @"Bootstrap is incompatible";

        case HCBootstrapStatusUnavailable:
        default:
            return @"Bootstrap is unavailable";
    }
}

@end
