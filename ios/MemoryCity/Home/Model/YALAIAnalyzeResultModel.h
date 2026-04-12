//
//  YALAIAnalyzeResultModel.h
//  MemoryCity
//
//  Created by Codex on 2026/4/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALAIAnalyzeResultModel : NSObject

@property (nonatomic, copy) NSString *summary;
@property (nonatomic, strong) NSArray<NSString *> *tags;
@property (nonatomic, copy) NSString *mood;
@property (nonatomic, copy) NSString *suggestions;
@property (nonatomic, strong) NSArray<NSString *> *highlights;
@property (nonatomic, copy) NSString *guide;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
