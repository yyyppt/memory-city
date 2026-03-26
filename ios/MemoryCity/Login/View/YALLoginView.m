//
//  YALLoginView.m
//  MemoryCity
//
//  Created by mac on 2026/3/15.
//

#import "YALLoginView.h"
#import <Masonry/Masonry.h>

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
    UIImageView *logo = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        logo.image = [UIImage systemImageNamed:@"sparkles"];
        logo.tintColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    }
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.backgroundColor = [UIColor colorWithRed:1.0 green:0.96 blue:0.85 alpha:1.0];
    logo.layer.cornerRadius = 16;
    logo.layer.masksToBounds = YES;
    logo.layer.borderWidth = 3.0;
    logo.layer.borderColor = [UIColor whiteColor].CGColor;
    [self addSubview:logo];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"拾光";
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textAlignment = NSTextAlignmentCenter;
    [self addSubview:title];

    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"记录每一个温润如玉的瞬间";
    sub.font = [UIFont systemFontOfSize:14];
    sub.textColor = [UIColor secondaryLabelColor];
    sub.textAlignment = NSTextAlignmentCenter;
    [self addSubview:sub];

    _accountField = [[UITextField alloc] init];
    _accountField.placeholder = @"请输入您的联系方式";
    _accountField.backgroundColor = [UIColor colorWithRed:1.0 green:0.97 blue:0.92 alpha:1.0];
    _accountField.layer.borderWidth = 1.0;
    _accountField.layer.borderColor = [UIColor colorWithRed:1.0 green:0.85 blue:0.6 alpha:1.0].CGColor;
    _accountField.layer.cornerRadius = 25;
    _accountField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    _accountField.leftViewMode = UITextFieldViewModeAlways;
    [self addSubview:_accountField];

    _passwordField = [[UITextField alloc] init];
    _passwordField.placeholder = @"请输入密码";
    _passwordField.secureTextEntry = YES;
    _passwordField.backgroundColor = [UIColor colorWithRed:1.0 green:0.97 blue:0.92 alpha:1.0];
    _passwordField.layer.borderWidth = 1.0;
    _passwordField.layer.borderColor = [UIColor colorWithRed:1.0 green:0.85 blue:0.6 alpha:1.0].CGColor;
    _passwordField.layer.cornerRadius = 25;
    _passwordField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    _passwordField.leftViewMode = UITextFieldViewModeAlways;
    [self addSubview:_passwordField];

    _loginButton = [[UIButton alloc] init];
    _loginButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0];
    _loginButton.layer.shadowColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0].CGColor;
    _loginButton.layer.shadowOpacity = 0.15;
    _loginButton.layer.shadowOffset = CGSizeMake(0, 3);
    _loginButton.layer.shadowRadius = 6;
    [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
    _loginButton.layer.cornerRadius = 28;
    [_loginButton addTarget:self action:@selector(pressLogin) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_loginButton];

    _forgetButton = [[UIButton alloc] init];
    [_forgetButton setTitle:@"忘记密码?" forState:UIControlStateNormal];
    [_forgetButton setTitleColor:[UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
    _forgetButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self addSubview:_forgetButton];

    _registerButton = [[UIButton alloc] init];
    [_registerButton setTitle:@"注册" forState:UIControlStateNormal];
    [_registerButton setTitleColor:[UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
    [_registerButton addTarget:self action:@selector(pressRegister) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_registerButton];

    // Masonry 约束
    [logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_top).offset(140);
        make.centerX.equalTo(self);
        // make.left.equalTo(self.mas_left).offset(40);
        // make.right.equalTo(self.mas_right).offset(-40);
        make.width.height.mas_equalTo(80);
    }];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logo.mas_bottom).offset(24);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(40);
    }];

    [sub mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(4);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(30);
    }];

    [_accountField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sub.mas_bottom).offset(30);
        make.left.equalTo(self.mas_left).offset(40);
        make.right.equalTo(self.mas_right).offset(-40);
        make.height.mas_equalTo(50);
    }];

    [_passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_accountField.mas_bottom).offset(16);
        make.left.right.height.equalTo(_accountField);
    }];

    [_forgetButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passwordField.mas_bottom).offset(8);
        make.right.equalTo(self.mas_right).offset(-40);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(30);
    }];

    [_loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_forgetButton.mas_bottom).offset(8);
        make.left.right.equalTo(_accountField);
        make.height.mas_equalTo(55);
    }];

    [_registerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_top).offset(80);
        make.right.equalTo(self.mas_right).offset(-10);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(30);
    }];
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

@end
