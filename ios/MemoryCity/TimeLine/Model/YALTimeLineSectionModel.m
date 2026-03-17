//
//  YALTimeLineSectionModel.m
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "YALTimeLineSectionModel.h"

@implementation YALTimeLineSectionModel

- (instancetype)initWithMonthText:(NSString *)monthText
                         expanded:(BOOL)expanded
                          entries:(NSArray<YALTimeLineEntryModel *> *)entries {
    self = [super init];
    if (self) {
        _monthText = [monthText copy];
        _expanded = expanded;
        _entries = entries;
    }
    return self;
}

@end
