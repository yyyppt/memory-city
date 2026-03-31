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
    return [self initWithTitle:title
                        subtitle:subtitle
                            date:date
                         content:nil
                      imageURLs:nil];
}

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         date:(NSString *)date
                      content:(nullable NSString *)content
                   imageURLs:(nullable NSArray<NSString *> *)imageURLs {
    self = [super init];
    if (self) {
        _titleText = [title copy] ?: @"";
        _subtitleText = [subtitle copy] ?: @"";
        _dateText = [date copy] ?: @"";
        _contentText = [content copy] ?: @"";
        _imageURLStrings = [imageURLs copy] ?: @[];
        _image = nil;
    }
    return self;
}

@end
