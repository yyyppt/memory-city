//
//  YALLoginController.m
//  MemoryCity
//
//  Created by mac on 2026/3/15.
//

#import "YALLoginController.h"
#import "YALRegisterController.h"
#import "YALForgotPasswordController.h"
#import "YALAuthManager.h"

@interface YALLoginController () <UIGestureRecognizerDelegate>

@end

@implementation YALLoginController

static const NSUInteger kYALPasswordMinLength = 6;
static const NSUInteger kYALPasswordMaxLength = 15;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    _loginView = [[YALLoginView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.loginView];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
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
    _loginView.tapForgetPasswordBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        YALForgotPasswordController *forgotVC = [[YALForgotPasswordController alloc] init];
        UINavigationController *nav = strongSelf.navigationController;
        if (nav) {
            [nav pushViewController:forgotVC animated:YES];
        }
    };
    _loginView.tapLoginBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }

        NSString *username = strongSelf.loginView.accountField.text ?: @"";
        NSString *password = strongSelf.loginView.passwordField.text ?: @"";
        if (username.length == 0 || password.length == 0) {
            [strongSelf showAlert:@"请输入账号和密码"];
            return;
        }
        if (password.length < kYALPasswordMinLength || password.length > kYALPasswordMaxLength) {
            [strongSelf showAlert:@"密码长度需为6到15位"];
            return;
        }

        [[YALAuthManager sharedManager] loginWithUsername:username
                                                password:password
                                              completion:^(YALAuthUserModel *user, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (user) {
                    [[YALAuthManager sharedManager] setCurrentUser:user];
                    [strongSelf enterMainInterface];
                } else {
                    NSString *msg = error.localizedDescription.length > 0 ? error.localizedDescription : @"登录失败，请稍后重试";
                    [strongSelf showAlert:msg];
                }
            });
        }];
    };
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *v = touch.view;
    while (v && v != self.view) {
        if ([v isKindOfClass:[UITextField class]] ||
            [v isKindOfClass:[UITextView class]] ||
            [v isKindOfClass:[UIControl class]]) {
            return NO;
        }
        v = v.superview;
    }
    return YES;
}

- (void)enterMainInterface {
    YALTabBarController *tabBarController = [[YALTabBarController alloc] init];
    UIWindow *window = self.view.window;
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
}

- (void)showAlert:(NSString *)msg {
    if (msg.length == 0) { msg = @"操作失败"; }
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil
                                                                message:msg
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"好"
                                         style:UIAlertActionStyleDefault
                                       handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
