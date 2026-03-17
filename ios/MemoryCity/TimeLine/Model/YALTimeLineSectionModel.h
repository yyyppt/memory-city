//
//  YALTimeLineSectionModel.h
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import <Foundation/Foundation.h>
#import "YALTimeLineEntryModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YALTimeLineSectionModel : NSObject

@property (nonatomic, copy) NSString *monthText;
@property (nonatomic, assign, getter=isExpanded) BOOL expanded;
@property (nonatomic, strong) NSArray<YALTimeLineEntryModel *> *entries;

- (instancetype)initWithMonthText:(NSString *)monthText
                         expanded:(BOOL)expanded
                          entries:(NSArray<YALTimeLineEntryModel *> *)entries;

@end

NS_ASSUME_NONNULL_END
