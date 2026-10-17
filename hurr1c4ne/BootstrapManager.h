#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HCBootstrapStatus) {
    HCBootstrapStatusUnavailable = 0,
    HCBootstrapStatusNotInstalled,
    HCBootstrapStatusInstalled,
    HCBootstrapStatusIncompatible
};

@interface BootstrapManager : NSObject

+ (instancetype)sharedManager;

- (HCBootstrapStatus)status;
- (NSString *)statusDescription;

@end

NS_ASSUME_NONNULL_END
