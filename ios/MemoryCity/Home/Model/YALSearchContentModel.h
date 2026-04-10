//
//  YALSearchContentModel.h
//  MemoryCity
//
//  Created by Codex on 2026/4/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALSearchContentModel : NSObject

@property (nonatomic, strong, nullable) NSNumber *contentId;
@property (nonatomic, strong, nullable) NSNumber *userId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *year;
@property (nonatomic, copy) NSString *mood;
@property (nonatomic, strong) NSArray<NSString *> *images;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) NSInteger commentCount;
@property (nonatomic, copy) NSString *createdAt;
@property (nonatomic, copy) NSString *authorNickname;
@property (nonatomic, copy) NSString *authorUsername;
@property (nonatomic, copy) NSString *authorAvatar;
@property (nonatomic, copy) NSString *authorBio;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
