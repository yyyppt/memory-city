//
//  YALForgotPasswordController.m
//  MemoryCity
//
//  Created by AI on 2026/4/11.
//

#import "YALForgotPasswordController.h"
#import "YALResetPasswordController.h"
#import "YALAuthManager.h"
#import <Masonry/Masonry.h>

@interface YALForgotPasswordController () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITextField *phoneField;
@property (nonatomic, strong) UITextField *codeField;
@property (nonatomic, strong) UIButton *sendCodeButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSInteger remainingSeconds;

@end

@implementation YALForgotPasswordController

static const NSInteger kYALResetCodeCountdownSeconds = 60;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"找回密码";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self buildUI];
    [self installKeyboardDismissGesture];
}

- (void)dealloc {
    [self invalidateCountdownTimer];
}

- (void)buildUI {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"验证你的手机号";
    titleLabel.font = [UIFont systemFontOfSize:26.0 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor labelColor];
    [self.view addSubview:titleLabel];

    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.text = @"输入注册手机号，我们会发送短信验证码用于重置密码。";
    hintLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    hintLabel.textColor = [UIColor secondaryLabelColor];
    hintLabel.numberOfLines = 0;
    [self.view addSubview:hintLabel];

    UIView *cardView = [[UIView alloc] init];
    cardView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    cardView.layer.cornerRadius = 18.0;
    cardView.layer.masksToBounds = YES;
    [self.view addSubview:cardView];

    self.phoneField = [self makeTextFieldWithPlaceholder:@"请输入手机号"];
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;
    self.phoneField.textContentType = UITextContentTypeTelephoneNumber;
    [cardView addSubview:self.phoneField];

    self.codeField = [self makeTextFieldWithPlaceholder:@"请输入验证码"];
    self.codeField.keyboardType = UIKeyboardTypeNumberPad;
    self.codeField.textContentType = UITextContentTypeOneTimeCode;
    [cardView addSubview:self.codeField];

    self.sendCodeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendCodeButton setTitle:@"获取验证码" forState:UIControlStateNormal];
    [self.sendCodeButton setTitleColor:[UIColor colorWithRed:0.90 green:0.40 blue:0.12 alpha:1.0] forState:UIControlStateNormal];
    self.sendCodeButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    self.sendCodeButton.layer.cornerRadius = 8.0;
    self.sendCodeButton.layer.masksToBounds = YES;
    self.sendCodeButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.94 blue:0.84 alpha:1.0];
    [self.sendCodeButton addTarget:self action:@selector(sendCodeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [cardView addSubview:self.sendCodeButton];

    self.nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.nextButton setTitle:@"下一步" forState:UIControlStateNormal];
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    self.nextButton.backgroundColor = [UIColor colorWithRed:0.98 green:0.52 blue:0.18 alpha:1.0];
    self.nextButton.layer.cornerRadius = 25.0;
    self.nextButton.layer.masksToBounds = YES;
    [self.nextButton addTarget:self action:@selector(nextButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(28.0);
        make.left.equalTo(self.view).offset(24.0);
        make.right.equalTo(self.view).offset(-24.0);
    }];

    [hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(8.0);
        make.left.right.equalTo(titleLabel);
    }];

    [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(hintLabel.mas_bottom).offset(24.0);
        make.left.right.equalTo(titleLabel);
    }];

    [self.phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cardView).offset(18.0);
        make.left.equalTo(cardView).offset(16.0);
        make.right.equalTo(cardView).offset(-16.0);
        make.height.mas_equalTo(50.0);
    }];

    [self.codeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.phoneField.mas_bottom).offset(14.0);
        make.left.height.equalTo(self.phoneField);
        make.right.equalTo(self.sendCodeButton.mas_left).offset(-10.0);
        make.bottom.equalTo(cardView).offset(-18.0);
    }];

    [self.sendCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.codeField);
        make.right.equalTo(cardView).offset(-16.0);
        make.width.mas_equalTo(104.0);
        make.height.mas_equalTo(42.0);
    }];

    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cardView.mas_bottom).offset(28.0);
        make.left.right.equalTo(titleLabel);
        make.height.mas_equalTo(50.0);
    }];
}

- (UITextField *)makeTextFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.backgroundColor = [UIColor systemBackgroundColor];
    field.layer.cornerRadius = 12.0;
    field.layer.masksToBounds = YES;
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14.0, 1.0)];
    field.leftViewMode = UITextFieldViewModeAlways;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.delegate = self;
    return field;
}

- (void)installKeyboardDismissGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)sendCodeButtonTapped {
    NSString *phone = [self trimmedText:self.phoneField.text];
    if (![self isValidPhone:phone]) {
        [self showAlert:@"请输入有效手机号"];
        return;
    }

    self.sendCodeButton.enabled = NO;
    [[YALAuthManager sharedManager] requestPasswordResetCodeForPhone:phone completion:^(BOOL success, NSString * _Nullable message, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self startCountdown];
                [self showAlert:message.length > 0 ? message : @"验证码已发送"];
            } else {
                self.sendCodeButton.enabled = YES;
                [self showAlert:message.length > 0 ? message : (error.localizedDescription ?: @"验证码发送失败")];
            }
        });
    }];
}

- (void)nextButtonTapped {
    NSString *phone = [self trimmedText:self.phoneField.text];
    NSString *code = [self trimmedText:self.codeField.text];
    if (![self isValidPhone:phone]) {
        [self showAlert:@"请输入有效手机号"];
        return;
    }
    if (code.length == 0) {
        [self showAlert:@"请输入验证码"];
        return;
    }
    if (code.length < 4 || code.length > 8) {
        [self showAlert:@"请输入正确的验证码"];
        return;
    }

    self.nextButton.enabled = NO;
    [[YALAuthManager sharedManager] verifyPasswordResetCodeForPhone:phone code:code completion:^(BOOL success, NSString * _Nullable message, NSString * _Nullable resetToken, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.nextButton.enabled = YES;
            if (success) {
                YALResetPasswordController *resetVC = [[YALResetPasswordController alloc] initWithPhone:phone verificationCode:code resetToken:resetToken];
                [self.navigationController pushViewController:resetVC animated:YES];
            } else {
                [self showAlert:message.length > 0 ? message : (error.localizedDescription ?: @"验证码错误或已过期")];
            }
        });
    }];
}

- (void)startCountdown {
    [self invalidateCountdownTimer];
    self.remainingSeconds = kYALResetCodeCountdownSeconds;
    [self updateCountdownButtonTitle];
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(countdownTimerFired)
                                                         userInfo:nil
                                                          repeats:YES];
}

- (void)countdownTimerFired {
    self.remainingSeconds -= 1;
    if (self.remainingSeconds <= 0) {
        [self invalidateCountdownTimer];
        self.sendCodeButton.enabled = YES;
        [self.sendCodeButton setTitle:@"重新获取" forState:UIControlStateNormal];
        return;
    }
    [self updateCountdownButtonTitle];
}

- (void)updateCountdownButtonTitle {
    NSString *title = [NSString stringWithFormat:@"%lds后重试", (long)self.remainingSeconds];
    [self.sendCodeButton setTitle:title forState:UIControlStateNormal];
}

- (void)invalidateCountdownTimer {
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
}

- (NSString *)trimmedText:(NSString *)text {
    return [text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isValidPhone:(NSString *)phone {
    if (phone.length != 11) {
        return NO;
    }
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [phone rangeOfCharacterFromSet:nonDigits].location == NSNotFound;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message.length > 0 ? message : @"操作失败"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *view = touch.view;
    while (view && view != self.view) {
        if ([view isKindOfClass:[UIControl class]]) {
            return NO;
        }
        view = view.superview;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    NSString *current = textField.text ?: @"";
    NSString *updated = [current stringByReplacingCharactersInRange:range withString:string ?: @""];
    if (textField == self.phoneField) {
        return updated.length <= 11;
    }
    if (textField == self.codeField) {
        return updated.length <= 8;
    }
    return YES;
}

@end
