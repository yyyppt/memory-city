//
//  YALLoginView.m
//  MemoryCity
//
//  Created by mac on 2026/3/15.
//

#import "YALLoginView.h"

@implementation YALLoginView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor systemBackgroundColor];
        [self setupUI];
    }
    
    return self;
}

- (void)setupUI {
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0,120,80,80)];
    logo.center = CGPointMake(self.center.x,160);
    logo.image = [UIImage imageNamed:@"logo"];
    logo.layer.cornerRadius = 20;
    logo.clipsToBounds = YES;
    [self addSubview:logo];
    
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0,220,self.frame.size.width,40)];
    title.text = @"拾光";
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textAlignment = NSTextAlignmentCenter;
    [self addSubview:title];
    
    
    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(0,260,self.frame.size.width,30)];
    sub.text = @"记录每一个温润如玉的瞬间";
    sub.font = [UIFont systemFontOfSize:14];
    sub.textColor = [UIColor grayColor];
    sub.textAlignment = NSTextAlignmentCenter;
    [self addSubview:sub];
    
    _accountField = [[UITextField alloc] initWithFrame:CGRectMake(40,320,self.frame.size.width-80,50)];
    _accountField.placeholder = @"请输入您的联系方式";
    _accountField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    _accountField.layer.cornerRadius = 25;
    _accountField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0,0,15,0)];
    _accountField.leftViewMode = UITextFieldViewModeAlways;
    [self addSubview:_accountField];
    
    _passwordField = [[UITextField alloc] initWithFrame:CGRectMake(40,390,self.frame.size.width-80,50)];
    _passwordField.placeholder = @"请输入密码";
    _passwordField.secureTextEntry = YES;
    _passwordField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    _passwordField.layer.cornerRadius = 25;
    _passwordField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0,0,15,0)];
    _passwordField.leftViewMode = UITextFieldViewModeAlways;
    [self addSubview:_passwordField];
    
    _loginButton = [[UIButton alloc] initWithFrame:CGRectMake(40,470,self.frame.size.width-80,55)];
    _loginButton.backgroundColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
    [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
    _loginButton.layer.cornerRadius = 28;
    [self addSubview:_loginButton];
    
    _forgetButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 120,440,100,30)];
    [_forgetButton setTitle:@"忘记密码?" forState:UIControlStateNormal];
    [_forgetButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    _forgetButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self addSubview:_forgetButton];
    
    _registerButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width-70,80,60,30)];
    [_registerButton setTitle:@"注册" forState:UIControlStateNormal];
    [_registerButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self addSubview:_registerButton];
    
    
    UILabel *other = [[UILabel alloc] initWithFrame:CGRectMake(0,560,self.frame.size.width,30)];
    other.text = @"其他登录方式";
    other.textColor = [UIColor grayColor];
    other.font = [UIFont systemFontOfSize:14];
    other.textAlignment = NSTextAlignmentCenter;
    [self addSubview:other];
    
    _appleButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/2-80,610,60,60)];
    [_appleButton setImage:[UIImage imageNamed:@"apple.png"] forState:UIControlStateNormal];
    [self addSubview:_appleButton];
    
    _wechatButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/2+20,610,60,60)];
    [_wechatButton setImage:[UIImage imageNamed:@"wechat.png"] forState:UIControlStateNormal];
    [self addSubview:_wechatButton];
}

@end
