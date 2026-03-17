//
//  YALTimeLineEntryModel.h
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALTimeLineEntryModel : NSObject

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *subtitleText;
@property (nonatomic, copy) NSString *dateText;
@property (nonatomic, strong, nullable) UIImage *image;

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         date:(NSString *)date
                        image:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
