#import "AppDelegate.h"
#import "RadixViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:
                   [UIScreen mainScreen].bounds];

    RadixViewController *rootViewController =
        [[RadixViewController alloc] init];

    UINavigationController *navigationController =
        [[UINavigationController alloc]
         initWithRootViewController:rootViewController];

    self.window.rootViewController = navigationController;

    [self.window makeKeyAndVisible];

    return YES;
}

@end
