#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^YALRegisterSubmitBlock)(NSString *phone, NSString *username, NSString *password, NSString *nickname);

@interface YALRegisterView : UIView

@property (nonatomic, strong, readonly) UITextField *phoneField;
@property (nonatomic, strong, readonly) UITextField *accountField;
@property (nonatomic, strong, readonly) UITextField *passwordField;
@property (nonatomic, strong, readonly) UITextField *nicknameField;
@property (nonatomic, strong, readonly) UIButton *registerButton;

@property (nonatomic, copy, nullable) YALRegisterSubmitBlock submitBlock;

@end

NS_ASSUME_NONNULL_END
