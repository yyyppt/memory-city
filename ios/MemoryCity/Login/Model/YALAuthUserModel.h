//
//  YALAuthUserModel.h
//  MemoryCity
//
//  Created by mac on 2026/3/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 登录/注册接口返回的用户数据
@interface YALAuthUserModel : NSObject

@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, copy, nullable) NSString *bio;
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, copy, nullable) NSString *phone;
@property (nonatomic, copy, nullable) NSString *nickname;
@property (nonatomic, copy, nullable) NSString *avatar;
@property (nonatomic, copy, nullable) NSString *token;

@end

NS_ASSUME_NONNULL_END

