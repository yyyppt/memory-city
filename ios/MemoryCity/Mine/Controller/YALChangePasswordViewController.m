//
//  YALChangePasswordViewController.m
//  MemoryCity
//
//  Created by AI on 2026/3/31.
//

#import "YALChangePasswordViewController.h"
#import <Masonry/Masonry.h>
#import "YALAuthManager.h"

@interface YALChangePasswordViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *oldPasswordField;
@property (nonatomic, strong) UITextField *updatedPasswordField;
@property (nonatomic, strong) UITextField *repeatPasswordField;
@property (nonatomic, strong) UIButton *saveButton;

@end

@implementation YALChangePasswordViewController

static const NSUInteger kYALPasswordMinLength = 6;
static const NSUInteger kYALPasswordMaxLength = 15;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"修改密码";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self buildUI];
}

- (void)buildUI {
    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    contentView.layer.cornerRadius = 16.0;
    contentView.layer.masksToBounds = YES;
    [self.view addSubview:contentView];
    
    self.oldPasswordField = [self makePasswordFieldWithPlaceholder:@"当前密码"];
    self.updatedPasswordField = [self makePasswordFieldWithPlaceholder:@"新密码"];
    self.repeatPasswordField = [self makePasswordFieldWithPlaceholder:@"确认新密码"];
    
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.oldPasswordField, self.updatedPasswordField, self.repeatPasswordField]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;
    stack.distribution = UIStackViewDistributionFillEqually;
    [contentView addSubview:stack];
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveButton setTitle:@"保存密码" forState:UIControlStateNormal];
    self.saveButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.saveButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.93 blue:0.7 alpha:1.0];
    [self.saveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.saveButton.layer.cornerRadius = 8.0;
    self.saveButton.layer.masksToBounds = YES;
    [self.saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveButton];
    
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(24.0);
        make.left.equalTo(self.view).offset(16.0);
        make.right.equalTo(self.view).offset(-16.0);
    }];
    
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView).offset(16.0);
        make.left.equalTo(contentView).offset(16.0);
        make.right.equalTo(contentView).offset(-16.0);
        make.bottom.equalTo(contentView).offset(-16.0);
    }];
    
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView.mas_bottom).offset(32.0);
        make.left.equalTo(self.view).offset(16.0);
        make.right.equalTo(self.view).offset(-16.0);
        make.height.mas_equalTo(50.0);
    }];
}

- (UITextField *)makePasswordFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.secureTextEntry = YES;
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.backgroundColor = [UIColor systemBackgroundColor];
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.delegate = self;
    return field;
}

- (void)saveButtonTapped {
    NSString *oldP = [self.oldPasswordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *newP = [self.updatedPasswordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *repeatP = [self.repeatPasswordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (oldP.length == 0 || newP.length == 0 || repeatP.length == 0) {
        [self showAlertWithTitle:@"提示" message:@"密码不能为空"];
        return;
    }
    if (oldP.length < kYALPasswordMinLength || oldP.length > kYALPasswordMaxLength ||
        newP.length < kYALPasswordMinLength || newP.length > kYALPasswordMaxLength ||
        repeatP.length < kYALPasswordMinLength || repeatP.length > kYALPasswordMaxLength) {
        [self showAlertWithTitle:@"提示" message:@"密码长度需为6到15位"];
        return;
    }
    if (![newP isEqualToString:repeatP]) {
        [self showAlertWithTitle:@"提示" message:@"两次新密码不一致"];
        return;
    }
    
    self.view.userInteractionEnabled = NO;
    [[YALAuthManager sharedManager] updatePasswordWithOldPassword:oldP
                                                      newPassword:newP
                                                    repeatPassword:repeatP
                                                        completion:^(BOOL success, NSString * _Nullable message, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.view.userInteractionEnabled = YES;
            NSString *msg = message;
            if (msg.length == 0) {
                msg = success ? @"更新成功" : (error.localizedDescription ?: @"更新失败");
            }
            [self showAlertWithTitle:success ? @"修改成功" : @"修改失败"
                             message:msg
                          completion:^{
                if (success) {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
        });
    }];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showAlertWithTitle:title message:message completion:nil];
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                completion:(void (^ __nullable)(void))completion {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        if (completion) {
            completion();
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    NSString *current = textField.text ?: @"";
    NSString *updated = [current stringByReplacingCharactersInRange:range withString:string ?: @""];
    return updated.length <= kYALPasswordMaxLength;
}

@end

