//
//  YALAIAnalyzeResultModel.m
//  MemoryCity
//
//  Created by Codex on 2026/4/8.
//

#import "YALAIAnalyzeResultModel.h"

static NSString *YALAIAnalyzeTrimmedString(id value) {
    if (![value isKindOfClass:[NSString class]]) {
        return @"";
    }
    return [((NSString *)value) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@implementation YALAIAnalyzeResultModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _summary = YALAIAnalyzeTrimmedString(dict[@"summary"]);
        _mood = YALAIAnalyzeTrimmedString(dict[@"mood"]);

        NSMutableArray<NSString *> *resultTags = [NSMutableArray array];
        NSArray *rawTags = [dict[@"tags"] isKindOfClass:[NSArray class]] ? dict[@"tags"] : @[];
        for (id item in rawTags) {
            NSString *tag = YALAIAnalyzeTrimmedString(item);
            if (tag.length > 0) {
                [resultTags addObject:tag];
            }
        }
        _tags = [resultTags copy];
    }
    return self;
}

@end
