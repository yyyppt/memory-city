#import "YALRegisterView.h"

@implementation YALRegisterView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemBackgroundColor];

        UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 120, 80, 80)];
        logo.center = CGPointMake(self.center.x, 160);
        logo.image = [UIImage imageNamed:@"logo"];
        logo.layer.cornerRadius = 20;
        logo.clipsToBounds = YES;
        [self addSubview:logo];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 220, self.frame.size.width, 40)];
        title.text = @"注册账号";
        title.font = [UIFont boldSystemFontOfSize:30];
        title.textAlignment = NSTextAlignmentCenter;
        [self addSubview:title];

        UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(0, 260, self.frame.size.width, 30)];
        sub.text = @"填写信息，开始记录你的回忆";
        sub.font = [UIFont systemFontOfSize:14];
        sub.textColor = [UIColor grayColor];
        sub.textAlignment = NSTextAlignmentCenter;
        [self addSubview:sub];

        _phoneField = [[UITextField alloc] initWithFrame:CGRectMake(40, 320, self.frame.size.width - 80, 50)];
        _phoneField.placeholder = @"请输入手机号";
        _phoneField.keyboardType = UIKeyboardTypePhonePad;
        _phoneField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        _phoneField.layer.cornerRadius = 25;
        _phoneField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
        _phoneField.leftViewMode = UITextFieldViewModeAlways;
        [self addSubview:_phoneField];

        _passwordField = [[UITextField alloc] initWithFrame:CGRectMake(40, 390, self.frame.size.width - 80, 50)];
        _passwordField.placeholder = @"请输入密码";
        _passwordField.secureTextEntry = YES;
        _passwordField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        _passwordField.layer.cornerRadius = 25;
        _passwordField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
        _passwordField.leftViewMode = UITextFieldViewModeAlways;
        [self addSubview:_passwordField];

        _nicknameField = [[UITextField alloc] initWithFrame:CGRectMake(40, 460, self.frame.size.width - 80, 50)];
        _nicknameField.placeholder = @"请输入昵称";
        _nicknameField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        _nicknameField.layer.cornerRadius = 25;
        _nicknameField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
        _nicknameField.leftViewMode = UITextFieldViewModeAlways;
        [self addSubview:_nicknameField];

        _registerButton = [[UIButton alloc] initWithFrame:CGRectMake(40, 540, self.frame.size.width - 80, 55)];
        _registerButton.backgroundColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
        [_registerButton setTitle:@"注册" forState:UIControlStateNormal];
        _registerButton.layer.cornerRadius = 28;
        [_registerButton addTarget:self action:@selector(registerTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_registerButton];
    }
    return self;
}

- (void)registerTapped {
    if (!self.submitBlock) return;
    self.submitBlock(self.phoneField.text ?: @"", self.passwordField.text ?: @"", self.nicknameField.text ?: @"");
}

@end
