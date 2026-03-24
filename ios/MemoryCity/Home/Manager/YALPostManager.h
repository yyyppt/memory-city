//
//  YALPostManager.h
//  MemoryCity
//
//  Created by mac on 2026/3/23.
//

#import <Foundation/Foundation.h>
#import "YALNetworkManager.h"
#import "YALPostModel.h"

@interface YALPostManager : NSObject

+ (instancetype)shareManager;
- (void)getPosts:(void(^)(NSArray<YALPostModel *> *posts, NSError *error))completion;

@end
