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
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *year;
@property (nonatomic, copy) NSString *mood;
@property (nonatomic, strong) NSArray<NSString *> *images;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) NSInteger commentCount;
@property (nonatomic, copy) NSString *createdAt;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
