//
//  YALLoginController.m
//  MemoryCity
//
//  Created by mac on 2026/3/15.
//

#import "YALLoginController.h"
#import "YALRegisterController.h"

@interface YALLoginController ()

@end

@implementation YALLoginController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    _loginView = [[YALLoginView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.loginView];
    
    __weak typeof(self) weakSelf = self;
    _loginView.tapRegisterBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        YALRegisterController *reg = [[YALRegisterController alloc] init];
        UINavigationController *nav = strongSelf.navigationController;
        if (nav) {
            [nav pushViewController:reg animated:YES];
        }
    };
    _loginView.tapLoginBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }

        YALTabBarController *tabBarController = [[YALTabBarController alloc] init];
        UIWindow *window = strongSelf.view.window;
        if (!window) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (![scene isKindOfClass:[UIWindowScene class]]) { continue; }
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                if (windowScene.activationState != UISceneActivationStateForegroundActive &&
                    windowScene.activationState != UISceneActivationStateForegroundInactive) {
                    continue;
                }
                window = windowScene.windows.firstObject;
                if (window) { break; }
            }
        }
        if (!window) { return; }

        // 登录成功后切根控制器，避免后续页面出现从登录页返回的 Back 按钮。
        // 使用淡入过渡，避免界面切换生硬。
        [UIView transitionWithView:window
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            BOOL oldState = [UIView areAnimationsEnabled];
            [UIView setAnimationsEnabled:NO];
            window.rootViewController = tabBarController;
            [UIView setAnimationsEnabled:oldState];
        } completion:nil];
        [window makeKeyAndVisible];
    };
}

@end
