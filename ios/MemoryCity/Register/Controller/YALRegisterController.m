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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"注册";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UIColor *accent = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
    self.navigationController.navigationBar.tintColor = accent;

    self.registerView = [[YALRegisterView alloc] initWithFrame:self.view.bounds];
    self.registerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    __weak typeof(self) ws = self;
    self.registerView.submitBlock = ^(NSString *phone, NSString *password, NSString *nickname) {
        __strong typeof(ws) ss = ws;
        if (!ss) return;
        NSString *trimPhone = [phone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *trimPw = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *trimName = [nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimPhone.length < 11) {
            [ss showAlert:@"请输入有效手机号"];
            return;
        }
        if (trimPw.length < 6) {
            [ss showAlert:@"密码至少 6 位"];
            return;
        }
        if (trimName.length == 0) {
            [ss showAlert:@"请输入昵称"];
            return;
        }

        [[YALAuthManager sharedManager] registerWithUsername:trimPhone
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
