//
//  YALSearchUserModel.h
//  MemoryCity
//
//  Created by Codex on 2026/4/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALSearchUserModel : NSObject

@property (nonatomic, strong, nullable) NSNumber *userId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *coverImage;
@property (nonatomic, copy) NSString *bio;
@property (nonatomic, copy) NSString *mood;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
