//
//  YALLoginView.m
//  MemoryCity
//
//  Created by mac on 2026/3/15.
//

#import "YALLoginView.h"
#import <Masonry/Masonry.h>

@interface YALLoginView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *formContainer;
@property (nonatomic, strong) UIButton *headerRegisterButton;

@end

@implementation YALLoginView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemBackgroundColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    self.headerRegisterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.headerRegisterButton setTitle:@"注册" forState:UIControlStateNormal];
    [self.headerRegisterButton setTitleColor:[UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
    self.headerRegisterButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    self.headerRegisterButton.contentEdgeInsets = UIEdgeInsetsMake(10.0, 12.0, 10.0, 12.0);
    [self.headerRegisterButton addTarget:self action:@selector(pressRegister) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.headerRegisterButton];

    self.formContainer = [[UIView alloc] init];
    [self.contentView addSubview:self.formContainer];

    UIImageView *logo = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        logo.image = [UIImage systemImageNamed:@"sparkles"];
        logo.tintColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    }
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.backgroundColor = [UIColor colorWithRed:1.0 green:0.96 blue:0.85 alpha:1.0];
    logo.layer.cornerRadius = 16.0;
    logo.layer.masksToBounds = YES;
    logo.layer.borderWidth = 3.0;
    logo.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.formContainer addSubview:logo];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"拾光";
    title.font = [UIFont boldSystemFontOfSize:30.0];
    title.textAlignment = NSTextAlignmentCenter;
    [self.formContainer addSubview:title];

    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"记录每一个温润如玉的瞬间";
    sub.font = [UIFont systemFontOfSize:14.0];
    sub.textColor = [UIColor secondaryLabelColor];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.numberOfLines = 0;
    [self.formContainer addSubview:sub];

    _accountField = [[UITextField alloc] init];
    _accountField.placeholder = @"请输入账号";
    _accountField.textContentType = UITextContentTypeUsername;
    _accountField.keyboardType = UIKeyboardTypeASCIICapable;
    _accountField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self styleTextField:_accountField];
    [self.formContainer addSubview:_accountField];

    _passwordField = [[UITextField alloc] init];
    _passwordField.placeholder = @"请输入密码";
    _passwordField.secureTextEntry = YES;
    _passwordField.textContentType = UITextContentTypePassword;
    _passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    if (@available(iOS 13.0, *)) {
        _passwordField.passwordRules = [UITextInputPasswordRules passwordRulesWithDescriptor:@"minlength: 6; maxlength: 15;"];
    }
    [self styleTextField:_passwordField];
    [self.formContainer addSubview:_passwordField];

    _forgetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_forgetButton setTitle:@"忘记密码?" forState:UIControlStateNormal];
    [_forgetButton setTitleColor:[UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
    _forgetButton.titleLabel.font = [UIFont systemFontOfSize:13.0];
    _forgetButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_forgetButton addTarget:self action:@selector(pressForgetPassword) forControlEvents:UIControlEventTouchUpInside];
    [self.formContainer addSubview:_forgetButton];

    _loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _loginButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0];
    _loginButton.layer.shadowColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0].CGColor;
    _loginButton.layer.shadowOpacity = 0.15;
    _loginButton.layer.shadowOffset = CGSizeMake(0, 3);
    _loginButton.layer.shadowRadius = 6;
    _loginButton.layer.cornerRadius = 28.0;
    [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
    [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _loginButton.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    [_loginButton addTarget:self action:@selector(pressLogin) forControlEvents:UIControlEventTouchUpInside];
    [self.formContainer addSubview:_loginButton];

    _registerButton = self.headerRegisterButton;

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView.contentLayoutGuide);
        make.width.equalTo(self.scrollView.frameLayoutGuide);
        make.height.greaterThanOrEqualTo(self.scrollView.frameLayoutGuide);
    }];

    [self.headerRegisterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_safeAreaLayoutGuideTop).offset(8.0);
        make.right.equalTo(self.contentView).offset(-12.0);
        make.height.mas_equalTo(44.0);
    }];

    [self.formContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerRegisterButton.mas_bottom).offset(24.0);
        make.left.equalTo(self.contentView).offset(24.0);
        make.right.equalTo(self.contentView).offset(-24.0);
        make.centerX.equalTo(self.contentView);
        make.width.lessThanOrEqualTo(@420.0);
        make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom).offset(-24.0);
    }];

    [logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.formContainer);
        make.centerX.equalTo(self.formContainer);
        make.width.height.mas_equalTo(80.0);
    }];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logo.mas_bottom).offset(24.0);
        make.left.right.equalTo(self.formContainer);
    }];

    [sub mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(4.0);
        make.left.right.equalTo(self.formContainer);
    }];

    [_accountField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sub.mas_bottom).offset(28.0);
        make.left.right.equalTo(self.formContainer);
        make.height.mas_equalTo(50.0);
    }];

    [_passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_accountField.mas_bottom).offset(16.0);
        make.left.right.height.equalTo(_accountField);
    }];

    [_forgetButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passwordField.mas_bottom).offset(8.0);
        make.right.equalTo(self.formContainer);
        make.height.mas_equalTo(30.0);
        make.width.mas_greaterThanOrEqualTo(100.0);
    }];

    [_loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_forgetButton.mas_bottom).offset(12.0);
        make.left.right.equalTo(self.formContainer);
        make.height.mas_equalTo(55.0);
        make.bottom.equalTo(self.formContainer);
    }];
}

- (void)styleTextField:(UITextField *)field {
    field.backgroundColor = [UIColor colorWithRed:1.0 green:0.97 blue:0.92 alpha:1.0];
    field.textColor = [UIColor colorWithWhite:0.16 alpha:1.0];
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:field.placeholder ?: @""
                                                                  attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.45 alpha:1.0]}];
    field.layer.borderWidth = 1.0;
    field.layer.borderColor = [UIColor colorWithRed:1.0 green:0.85 blue:0.6 alpha:1.0].CGColor;
    field.layer.cornerRadius = 25.0;
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    field.leftViewMode = UITextFieldViewModeAlways;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
}

- (void)pressLogin {
    if (_tapLoginBlock) {
        _tapLoginBlock();
    }
}

- (void)pressRegister {
    if (_tapRegisterBlock) {
        _tapRegisterBlock();
    }
}

- (void)pressForgetPassword {
    if (_tapForgetPasswordBlock) {
        _tapForgetPasswordBlock();
    }
}

@end
