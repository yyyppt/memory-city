//
//  YALResetPasswordController.m
//  MemoryCity
//
//  Created by AI on 2026/4/11.
//

#import "YALResetPasswordController.h"
#import "YALAuthManager.h"
#import <Masonry/Masonry.h>

@interface YALResetPasswordController () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *verificationCode;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *repeatPasswordField;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, assign) BOOL isSubmitting;

@end

@implementation YALResetPasswordController

static const NSUInteger kYALForgotPasswordMinLength = 6;
static const NSUInteger kYALForgotPasswordMaxLength = 15;

- (instancetype)initWithUsername:(NSString *)username
                           phone:(NSString *)phone
                verificationCode:(NSString *)code {
    self = [super init];
    if (self) {
        _username = [username copy] ?: @"";
        _phone = [phone copy] ?: @"";
        _verificationCode = [code copy] ?: @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"重置密码";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self buildUI];
    [self installKeyboardDismissGesture];
}

- (void)buildUI {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"设置新密码";
    titleLabel.font = [UIFont systemFontOfSize:26.0 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor labelColor];
    [self.view addSubview:titleLabel];

    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.text = @"新密码长度需为 6 到 15 位，请和确认密码保持一致。";
    hintLabel.font = [UIFont systemFontOfSize:14.0];
    hintLabel.textColor = [UIColor secondaryLabelColor];
    hintLabel.numberOfLines = 0;
    [self.view addSubview:hintLabel];

    UIView *cardView = [[UIView alloc] init];
    cardView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    cardView.layer.cornerRadius = 18.0;
    cardView.layer.masksToBounds = YES;
    [self.view addSubview:cardView];

    self.passwordField = [self makePasswordFieldWithPlaceholder:@"请输入新密码"];
    [cardView addSubview:self.passwordField];

    self.repeatPasswordField = [self makePasswordFieldWithPlaceholder:@"请再次输入新密码"];
    [cardView addSubview:self.repeatPasswordField];

    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveButton setTitle:@"确认重置" forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.saveButton.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    self.saveButton.backgroundColor = [UIColor colorWithRed:0.98 green:0.52 blue:0.18 alpha:1.0];
    self.saveButton.layer.cornerRadius = 25.0;
    self.saveButton.layer.masksToBounds = YES;
    [self.saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveButton];

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

    [self.passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cardView).offset(18.0);
        make.left.equalTo(cardView).offset(16.0);
        make.right.equalTo(cardView).offset(-16.0);
        make.height.mas_equalTo(50.0);
    }];

    [self.repeatPasswordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passwordField.mas_bottom).offset(14.0);
        make.left.right.height.equalTo(self.passwordField);
        make.bottom.equalTo(cardView).offset(-18.0);
    }];

    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cardView.mas_bottom).offset(28.0);
        make.left.right.equalTo(titleLabel);
        make.height.mas_equalTo(50.0);
    }];

    [self.passwordField addTarget:self action:@selector(passwordFieldsDidChange) forControlEvents:UIControlEventEditingChanged];
    [self.repeatPasswordField addTarget:self action:@selector(passwordFieldsDidChange) forControlEvents:UIControlEventEditingChanged];
    [self updateSaveButtonState];
}

- (UITextField *)makePasswordFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.secureTextEntry = YES;
    field.backgroundColor = [UIColor systemBackgroundColor];
    field.layer.cornerRadius = 12.0;
    field.layer.masksToBounds = YES;
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14.0, 1.0)];
    field.leftViewMode = UITextFieldViewModeAlways;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.textContentType = UITextContentTypeNewPassword;
    field.keyboardType = UIKeyboardTypeASCIICapable;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.delegate = self;
    if (@available(iOS 13.0, *)) {
        field.passwordRules = [UITextInputPasswordRules passwordRulesWithDescriptor:@"minlength: 6; maxlength: 15;"];
    }
    return field;
}

- (void)installKeyboardDismissGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)saveButtonTapped {
    NSString *password = [self trimmedText:self.passwordField.text];
    NSString *repeatPassword = [self trimmedText:self.repeatPasswordField.text];
    if (password.length == 0 || repeatPassword.length == 0) {
        [self showAlert:@"请输入新密码和确认密码" completion:nil];
        return;
    }
    if (password.length < kYALForgotPasswordMinLength || password.length > kYALForgotPasswordMaxLength ||
        repeatPassword.length < kYALForgotPasswordMinLength || repeatPassword.length > kYALForgotPasswordMaxLength) {
        [self showAlert:@"密码长度需为6到15位" completion:nil];
        return;
    }
    if (![password isEqualToString:repeatPassword]) {
        [self showAlert:@"两次密码不一致" completion:nil];
        return;
    }

    self.isSubmitting = YES;
    [self updateSaveButtonState];
    [[YALAuthManager sharedManager] resetPasswordForUsername:self.username
                                                       phone:self.phone
                                            verificationCode:self.verificationCode
                                                 newPassword:password
                                              repeatPassword:repeatPassword
                                                  completion:^(BOOL success, NSString * _Nullable message, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isSubmitting = NO;
            if (success) {
                [self showAlert:@"密码重置成功，请重新登录" completion:^{
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
            } else {
                [self updateSaveButtonState];
                NSString *displayMessage = message.length > 0 ? message : (error.localizedDescription ?: @"密码重置失败");
                if ([displayMessage containsString:@"验证码"]) {
                    displayMessage = @"验证码无效或已过期，请返回上一步重新获取验证码";
                }
                [self showAlert:displayMessage completion:nil];
            }
        });
    }];
}

- (NSString *)trimmedText:(NSString *)text {
    return [text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)passwordFieldsDidChange {
    [self updateSaveButtonState];
}

- (void)updateSaveButtonState {
    BOOL hasValidLength = [self trimmedText:self.passwordField.text].length >= kYALForgotPasswordMinLength &&
                          [self trimmedText:self.repeatPasswordField.text].length >= kYALForgotPasswordMinLength;
    BOOL canSubmit = hasValidLength && !self.isSubmitting;
    self.saveButton.enabled = canSubmit;
    self.saveButton.alpha = canSubmit ? 1.0 : 0.6;
    [self.saveButton setTitle:(self.isSubmitting ? @"提交中..." : @"确认重置") forState:UIControlStateNormal];
}

- (void)showAlert:(NSString *)message completion:(void (^ __nullable)(void))completion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message.length > 0 ? message : @"操作失败"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        if (completion) {
            completion();
        }
    }]];
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
    return updated.length <= kYALForgotPasswordMaxLength;
}

@end
