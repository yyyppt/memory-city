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

        NSMutableArray<NSString *> *resultTags = [NSMutableArray array];
        NSArray *rawTags = [dict[@"tags"] isKindOfClass:[NSArray class]] ? dict[@"tags"] : @[];
        for (id item in rawTags) {
            NSString *tag = YALAIAnalyzeTrimmedString(item);
            if (tag.length > 0) {
                [resultTags addObject:tag];
            }
        }
        _tags = [resultTags copy];
        _suggestions = YALAIAnalyzeTrimmedString(dict[@"suggestions"]);
        _highlights = YALAIAnalyzeStringArray(dict[@"highlights"]);
        _guide = YALAIAnalyzeTrimmedString(dict[@"guide"]);
    }
    return self;
}

@end
