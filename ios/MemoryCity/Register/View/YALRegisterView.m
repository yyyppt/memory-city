#import "YALRegisterView.h"
#import <Masonry/Masonry.h>

@interface YALRegisterView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *formContainer;

@end

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
    tf.layer.cornerRadius = 25.0;
    tf.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    tf.leftViewMode = UITextFieldViewModeAlways;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
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
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    self.formContainer = [[UIView alloc] init];
    [self.contentView addSubview:self.formContainer];

    UIImageView *logo = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        logo.image = [UIImage systemImageNamed:@"person.crop.circle.badge.plus"];
        logo.tintColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    } else {
        logo.image = [UIImage imageNamed:@"logo"];
    }
    logo.backgroundColor = [UIColor colorWithRed:1.0 green:0.96 blue:0.85 alpha:1.0];
    logo.layer.cornerRadius = 20.0;
    logo.clipsToBounds = YES;
    logo.contentMode = UIViewContentModeScaleAspectFit;
    [self.formContainer addSubview:logo];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"注册账号";
    title.font = [UIFont boldSystemFontOfSize:30.0];
    title.textAlignment = NSTextAlignmentCenter;
    [self.formContainer addSubview:title];

    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"填写账号和手机号，开始记录你的回忆";
    sub.font = [UIFont systemFontOfSize:14.0];
    sub.textColor = [UIColor secondaryLabelColor];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.numberOfLines = 0;
    [self.formContainer addSubview:sub];

    _phoneField = [[UITextField alloc] init];
    _phoneField.placeholder = @"请输入手机号";
    _phoneField.keyboardType = UIKeyboardTypePhonePad;
    _phoneField.textContentType = UITextContentTypeTelephoneNumber;
    [self styleTextField:_phoneField];
    [self.formContainer addSubview:_phoneField];

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
    _passwordField.textContentType = UITextContentTypeNewPassword;
    _passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self styleTextField:_passwordField];
    [self.formContainer addSubview:_passwordField];

    _nicknameField = [[UITextField alloc] init];
    _nicknameField.placeholder = @"请输入昵称";
    [self styleTextField:_nicknameField];
    [self.formContainer addSubview:_nicknameField];

    _registerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _registerButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    _registerButton.layer.cornerRadius = 28.0;
    [_registerButton setTitle:@"注册" forState:UIControlStateNormal];
    [_registerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _registerButton.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    [_registerButton addTarget:self action:@selector(registerTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.formContainer addSubview:_registerButton];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView.contentLayoutGuide);
        make.width.equalTo(self.scrollView.frameLayoutGuide);
        make.height.greaterThanOrEqualTo(self.scrollView.frameLayoutGuide);
    }];

    [self.formContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_safeAreaLayoutGuideTop).offset(24.0);
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
        make.top.equalTo(logo.mas_bottom).offset(20.0);
        make.left.right.equalTo(self.formContainer);
    }];

    [sub mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(4.0);
        make.left.right.equalTo(self.formContainer);
    }];

    [_phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sub.mas_bottom).offset(28.0);
        make.left.right.equalTo(self.formContainer);
        make.height.mas_equalTo(50.0);
    }];

    [_accountField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_phoneField.mas_bottom).offset(16.0);
        make.left.right.height.equalTo(_phoneField);
    }];

    [_passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_accountField.mas_bottom).offset(16.0);
        make.left.right.height.equalTo(_phoneField);
    }];

    [_nicknameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passwordField.mas_bottom).offset(16.0);
        make.left.right.height.equalTo(_phoneField);
    }];

    [_registerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nicknameField.mas_bottom).offset(24.0);
        make.left.right.equalTo(self.formContainer);
        make.height.mas_equalTo(55.0);
        make.bottom.equalTo(self.formContainer);
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
