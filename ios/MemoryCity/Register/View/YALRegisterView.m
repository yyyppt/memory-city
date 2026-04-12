#import "YALRegisterView.h"
#import <Masonry/Masonry.h>

@implementation YALRegisterView

- (void)styleTextField:(UITextField *)tf {
    tf.backgroundColor = [UIColor colorWithRed:1.0 green:0.97 blue:0.92 alpha:1.0];
    tf.textColor = [UIColor colorWithWhite:0.16 alpha:1.0];
    if (tf.placeholder.length > 0) {
        tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:tf.placeholder
                                                                    attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.45 alpha:1.0]}];
    }
    tf.layer.borderWidth = 1.0;
    tf.layer.borderColor = [UIColor colorWithRed:1.0 green:0.85 blue:0.6 alpha:1.0].CGColor;
    tf.layer.cornerRadius = 25;
}

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
    logo.image = [UIImage imageNamed:@"logo"];
    logo.layer.cornerRadius = 20;
    logo.clipsToBounds = YES;
    [self addSubview:logo];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"注册账号";
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textAlignment = NSTextAlignmentCenter;
    [self addSubview:title];

    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"填写账号和手机号，开始记录你的回忆";
    sub.font = [UIFont systemFontOfSize:14];
    sub.textColor = [UIColor secondaryLabelColor];
    sub.textAlignment = NSTextAlignmentCenter;
    [self addSubview:sub];

    _phoneField = [[UITextField alloc] init];
    _phoneField.placeholder = @"请输入手机号";
    _phoneField.keyboardType = UIKeyboardTypePhonePad;
    _phoneField.textContentType = UITextContentTypeTelephoneNumber;
    [self styleTextField:_phoneField];
    _phoneField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    _phoneField.leftViewMode = UITextFieldViewModeAlways;
    [self addSubview:_phoneField];

    _accountField = [[UITextField alloc] init];
    _accountField.placeholder = @"请输入账号";
    _accountField.textContentType = UITextContentTypeUsername;
    _accountField.keyboardType = UIKeyboardTypeASCIICapable;
    _accountField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self styleTextField:_accountField];
    _accountField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    _accountField.leftViewMode = UITextFieldViewModeAlways;
    [self addSubview:_accountField];

    _passwordField = [[UITextField alloc] init];
    _passwordField.placeholder = @"请输入密码";
    _passwordField.secureTextEntry = YES;
    _passwordField.textContentType = UITextContentTypeNewPassword;
    _passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self styleTextField:_passwordField];
    _passwordField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    _passwordField.leftViewMode = UITextFieldViewModeAlways;
    [self addSubview:_passwordField];

    _nicknameField = [[UITextField alloc] init];
    _nicknameField.placeholder = @"请输入昵称";
    [self styleTextField:_nicknameField];
    _nicknameField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    _nicknameField.leftViewMode = UITextFieldViewModeAlways;
    [self addSubview:_nicknameField];

    _registerButton = [[UIButton alloc] init];
    _registerButton.backgroundColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
    [_registerButton setTitle:@"注册" forState:UIControlStateNormal];
    _registerButton.layer.cornerRadius = 28;
    [_registerButton addTarget:self action:@selector(registerTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_registerButton];

    [logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_top).offset(88);
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(80);
    }];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logo.mas_bottom).offset(20);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(40);
    }];

    [sub mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(4);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(30);
    }];

    [_phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sub.mas_bottom).offset(30);
        make.left.equalTo(self.mas_left).offset(40);
        make.right.equalTo(self.mas_right).offset(-40);
        make.height.mas_equalTo(50);
    }];

    [_accountField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_phoneField.mas_bottom).offset(16);
        make.left.right.height.equalTo(_phoneField);
    }];

    [_passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_accountField.mas_bottom).offset(16);
        make.left.right.height.equalTo(_phoneField);
    }];

    [_nicknameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passwordField.mas_bottom).offset(16);
        make.left.right.height.equalTo(_phoneField);
    }];

    [_registerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nicknameField.mas_bottom).offset(24);
        make.left.right.equalTo(_phoneField);
        make.height.mas_equalTo(55);
    }];
}

- (void)registerTapped {
    if (!self.submitBlock) return;
    self.submitBlock(self.phoneField.text ?: @"",
                     self.accountField.text ?: @"",
                     self.passwordField.text ?: @"",
                     self.nicknameField.text ?: @"");
}

@end
