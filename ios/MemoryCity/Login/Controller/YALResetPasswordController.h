//
//  YALResetPasswordController.h
//  MemoryCity
//
//  Created by AI on 2026/4/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALResetPasswordController : UIViewController

- (instancetype)initWithUsername:(NSString *)username
                           phone:(NSString *)phone
                verificationCode:(NSString *)code;

@end

NS_ASSUME_NONNULL_END
