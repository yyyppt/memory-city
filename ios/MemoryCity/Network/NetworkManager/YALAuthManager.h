//
//  YALAuthManager.h
//  MemoryCity
//
//  Created by mac on 2026/3/26.
//

#import <Foundation/Foundation.h>
#import "YALAuthUserModel.h"


@interface YALAuthManager : NSObject

+ (instancetype)sharedManager;
- (void)loginWithUsername:(NSString *)userName password:(NSString *)password completion:(void(^)(YALAuthUserModel *user, NSError *error))completion;
- (void)registerWithUsername:(NSString *)username password:(NSString *)password nickname:(NSString *)nickname completion:(void (^)(YALAuthUserModel *user, NSError *error))completion;

@end
