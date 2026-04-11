//
//  YALLoginView.h
//  MemoryCity
//
//  Created by mac on 2026/3/15.
//

#import <UIKit/UIKit.h>

typedef void(^TapLoginBlock)(void);
typedef void(^TapRegisterBlock)(void);
typedef void(^TapForgetPasswordBlock)(void);

@interface YALLoginView : UIView

@property(nonatomic,strong)UITextField *accountField;
@property(nonatomic,strong)UITextField *passwordField;

@property(nonatomic,strong)UIButton *loginButton;
@property(nonatomic,strong)UIButton *registerButton;
@property(nonatomic,strong)UIButton *forgetButton;

@property (nonatomic, copy) TapLoginBlock tapLoginBlock;
@property (nonatomic, copy, nullable) TapRegisterBlock tapRegisterBlock;
@property (nonatomic, copy, nullable) TapForgetPasswordBlock tapForgetPasswordBlock;

@end
