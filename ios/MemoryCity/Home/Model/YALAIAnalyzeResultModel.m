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

static NSArray<NSString *> *YALAIAnalyzeStringArray(id value) {
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    if ([value isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)value) {
            NSString *text = YALAIAnalyzeTrimmedString(item);
            if (text.length > 0) {
                [items addObject:text];
            }
        }
    } else if ([value isKindOfClass:[NSString class]]) {
        NSString *text = YALAIAnalyzeTrimmedString(value);
        if (text.length > 0) {
            NSArray<NSString *> *components = [text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",，\n"]];
            for (NSString *component in components) {
                NSString *trimmed = YALAIAnalyzeTrimmedString(component);
                if (trimmed.length > 0) {
                    [items addObject:trimmed];
                }
            }
        }
    }
    return [items copy];
}

@implementation YALAIAnalyzeResultModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _summary = YALAIAnalyzeTrimmedString(dict[@"summary"]);
        _mood = YALAIAnalyzeTrimmedString(dict[@"mood"]);

        _tags = YALAIAnalyzeStringArray(dict[@"tags"]);
        _suggestions = YALAIAnalyzeTrimmedString(dict[@"suggestions"]);
        _highlights = YALAIAnalyzeStringArray(dict[@"highlights"]);
        _guide = YALAIAnalyzeTrimmedString(dict[@"guide"]);
        NSLog(@"[AI ResultModel] init summary=%@ tags=%@ highlights=%@ suggestions=%@ guide=%@ mood=%@ raw=%@",
              _summary ?: @"",
              [_tags componentsJoinedByString:@" | "] ?: @"",
              [_highlights componentsJoinedByString:@" | "] ?: @"",
              _suggestions ?: @"",
              _guide ?: @"",
              _mood ?: @"",
              dict ?: @{});
    }
    return self;
}

@end
