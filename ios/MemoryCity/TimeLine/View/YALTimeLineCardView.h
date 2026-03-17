//
//  YALTimeLineCardView.h
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import <UIKit/UIKit.h>
#import "YALTimeLineEntryModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YALTimeLineCardView : UIControl

@property (nonatomic, strong) YALTimeLineEntryModel *entry;
@property (nonatomic, copy, nullable) void (^tapAction)(YALTimeLineEntryModel *entry);

@end

NS_ASSUME_NONNULL_END
