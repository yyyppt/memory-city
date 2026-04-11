//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/21.
//
#import "YALRegisterController.h"
#import "YALRegisterView.h"
#import "YALAuthManager.h"
#import "SceneDelegate.h"

@interface YALRegisterController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) YALRegisterView *registerView;

@end

@implementation YALRegisterController

static const NSUInteger kYALRegisterPasswordMinLength = 6;
static const NSUInteger kYALRegisterPasswordMaxLength = 15;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"注册";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UIColor *accent = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
    self.navigationController.navigationBar.tintColor = accent;

    self.registerView = [[YALRegisterView alloc] initWithFrame:self.view.bounds];
    self.registerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    __weak typeof(self) ws = self;
    self.registerView.submitBlock = ^(NSString *phone, NSString *username, NSString *password, NSString *nickname) {
        __strong typeof(ws) ss = ws;
        if (!ss) return;
        NSString *trimPhone = [phone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *trimUsername = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *trimPw = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *trimName = [nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![ss isValidPhone:trimPhone]) {
            [ss showAlert:@"请输入有效手机号"];
            return;
        }
        if (![ss isValidUsername:trimUsername]) {
            [ss showAlert:@"请输入3到20位账号，不能包含空格"];
            return;
        }
        if (trimPw.length < kYALRegisterPasswordMinLength || trimPw.length > kYALRegisterPasswordMaxLength) {
            [ss showAlert:@"密码长度需为6到15位"];
            return;
        }
        if (trimName.length == 0) {
            [ss showAlert:@"请输入昵称"];
            return;
        }

        [[YALAuthManager sharedManager] registerWithUsername:trimUsername
                                                       phone:trimPhone
                                                    password:trimPw
                                                    nickname:trimName
                                                  completion:^(YALAuthUserModel *user, NSError *error) {
            if (user) {
                UIAlertController *a = [UIAlertController alertControllerWithTitle:nil
                                                                          message:@"注册成功，请重新登录"
                                                                   preferredStyle:UIAlertControllerStyleAlert];
                __weak typeof(ss) weakSelf = ss;
                [a addAction:[UIAlertAction actionWithTitle:@"好"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(__unused UIAlertAction * _Nonnull action) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf.navigationController popViewControllerAnimated:YES];
                }]];
                [ss presentViewController:a animated:YES completion:nil];
            } else {
                [ss showAlert:[NSString stringWithFormat:@"注册失败：%@", error.localizedDescription]];
            }
        }];
    };
    [self.view addSubview:self.registerView];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (BOOL)isValidPhone:(NSString *)phone {
    if (phone.length != 11) {
        return NO;
    }
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [phone rangeOfCharacterFromSet:nonDigits].location == NSNotFound;
}

- (BOOL)isValidUsername:(NSString *)username {
    if (username.length < 3 || username.length > 20) {
        return NO;
    }
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [username rangeOfCharacterFromSet:whitespace].location == NSNotFound;
}

- (void)showAlert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)enterMainInterface {
    [SceneDelegate switchToMainInterfaceAnimated:YES];
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

@end
