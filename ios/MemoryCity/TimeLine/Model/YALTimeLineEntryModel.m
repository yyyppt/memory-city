//
//  YALTimeLineEntryModel.m
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "YALTimeLineEntryModel.h"

@implementation YALTimeLineEntryModel

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         date:(NSString *)date
                        image:(nullable UIImage *)image {
    self = [super init];
    if (self) {
        _titleText = [title copy];
        _subtitleText = [subtitle copy];
        _dateText = [date copy];
        _image = image;
    }
    return self;
}

@end
