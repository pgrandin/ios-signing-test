#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Create window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    // Create view controller
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view.backgroundColor = [UIColor whiteColor];

    // Create label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, self.window.bounds.size.width - 40, 100)];
    label.text = @"Hello World from iOS!";
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];
    label.textColor = [UIColor systemBlueColor];
    label.numberOfLines = 0;
    [viewController.view addSubview:label];

    // Create subtitle label
    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 220, self.window.bounds.size.width - 40, 60)];
    subtitle.text = @"Built with GitHub Actions";
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.font = [UIFont systemFontOfSize:18];
    subtitle.textColor = [UIColor grayColor];
    subtitle.numberOfLines = 0;
    [viewController.view addSubview:subtitle];

    // Set root view controller
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];

    return YES;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
