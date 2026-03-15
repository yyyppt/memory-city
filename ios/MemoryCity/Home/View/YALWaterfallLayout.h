//
//  YALWaterfallLayout.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YALWaterfallLayout;

@protocol YALWaterfallLayoutDelegate <NSObject>

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(YALWaterfallLayout *)layout
 heightForItemAtIndexPath:(NSIndexPath *)indexPath
                itemWidth:(CGFloat)width;

@end

@interface YALWaterfallLayout : UICollectionViewLayout

@property (nonatomic, weak) id<YALWaterfallLayoutDelegate> delegate;
@property (nonatomic, assign) NSInteger columnCount;
@property (nonatomic, assign) CGFloat columnSpacing;
@property (nonatomic, assign) CGFloat rowSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInset;

@end

NS_ASSUME_NONNULL_END
