//
//  YALPostCell.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YALPostModel;

@interface YALPostCell : UICollectionViewCell

- (void)configureWithModel:(YALPostModel *)model
             useWaterfall:(BOOL)useWaterfall
      fixedImageHeight:(CGFloat)fixedImageHeight;

@end

NS_ASSUME_NONNULL_END

