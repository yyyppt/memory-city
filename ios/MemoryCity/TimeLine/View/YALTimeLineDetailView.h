//
//  YALTimeLineDetailView.h
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALTimeLineDetailView : UIView

@property (nonatomic, strong, readonly) UIImageView *coverImageView;
@property (nonatomic, strong, readonly) UILabel *dateLabel;
@property (nonatomic, strong, readonly) UILabel *bodyLabel;

@property (nonatomic, strong, readonly) UIButton *likeButton;
@property (nonatomic, strong, readonly) UIButton *commentButton;
@property (nonatomic, strong, readonly) UILabel *likeCountLabel;

- (void)configureWithDateText:(NSString *)dateText
                        image:(nullable UIImage *)image
                         body:(NSString *)body
                    likeCount:(NSInteger)likeCount;

@end

NS_ASSUME_NONNULL_END
