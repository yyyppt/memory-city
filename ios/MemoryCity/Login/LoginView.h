//
//  LoginView.h
//  MemoryCity
//
//  Created by mac on 2026/3/10.
//

#import <UIKit/UIKit.h>

@interface LoginView : UIView

@property(nonatomic,strong)UITextField *accountField;
@property(nonatomic,strong)UITextField *passwordField;

@property(nonatomic,strong)UIButton *loginButton;
@property(nonatomic,strong)UIButton *registerButton;
@property(nonatomic,strong)UIButton *forgetButton;

@property(nonatomic,strong)UIButton *appleButton;
@property(nonatomic,strong)UIButton *wechatButton;

@end
