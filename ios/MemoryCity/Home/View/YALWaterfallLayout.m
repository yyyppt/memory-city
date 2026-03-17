//
//  YALWaterfallLayout.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALWaterfallLayout.h"

@interface YALWaterfallLayout ()

@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *attributesArray;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *columnHeights;
@property (nonatomic, assign) CGFloat contentHeight;

@end

@implementation YALWaterfallLayout

- (instancetype)init {
  self = [super init];
  if (self) {
    _columnCount = 2;
    _columnSpacing = 8.0;
    _rowSpacing = 8.0;
    _sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);
  }
  return self;
}

- (void)prepareLayout {
  [super prepareLayout];

  if (!self.collectionView) { return; }

  NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
  if (itemCount == 0) { return; }

  self.attributesArray = [NSMutableArray arrayWithCapacity:itemCount];
  self.columnHeights = [NSMutableArray arrayWithCapacity:self.columnCount];

  for (NSInteger i = 0; i < self.columnCount; i++) {
    [self.columnHeights addObject:@(self.sectionInset.top)];
  }

  CGFloat collectionWidth = CGRectGetWidth(self.collectionView.bounds);
  CGFloat totalSpacing = self.sectionInset.left + self.sectionInset.right +
                         (self.columnCount - 1) * self.columnSpacing;
  CGFloat itemWidth = (collectionWidth - totalSpacing) / self.columnCount;

  for (NSInteger i = 0; i < itemCount; i++) {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];

    CGFloat itemHeight = 100.0;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:heightForItemAtIndexPath:itemWidth:)]) {
      itemHeight = [self.delegate collectionView:self.collectionView
                                          layout:self
                       heightForItemAtIndexPath:indexPath
                                      itemWidth:itemWidth];
    }

    NSInteger targetColumn = 0;
    CGFloat minHeight = self.columnHeights.firstObject.floatValue;
    for (NSInteger col = 1; col < self.columnHeights.count; col++) {
      CGFloat colHeight = self.columnHeights[col].floatValue;
      if (colHeight < minHeight) {
        minHeight = colHeight;
        targetColumn = col;
      }
    }

    CGFloat x = self.sectionInset.left + targetColumn * (itemWidth + self.columnSpacing);
    CGFloat y = minHeight;
    CGRect frame = CGRectMake(x, y, itemWidth, itemHeight);

    UICollectionViewLayoutAttributes *attrs =
      [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attrs.frame = frame;
    [self.attributesArray addObject:attrs];

    self.columnHeights[targetColumn] = @(CGRectGetMaxY(frame) + self.rowSpacing);
  }

  CGFloat maxHeight = self.sectionInset.top;
  for (NSNumber *height in self.columnHeights) {
    if (height.floatValue > maxHeight) {
      maxHeight = height.floatValue;
    }
  }
  self.contentHeight = maxHeight + self.sectionInset.bottom - self.rowSpacing;
}

- (CGSize)collectionViewContentSize {
  if (!self.collectionView) {
    return CGSizeZero;
  }
  return CGSizeMake(CGRectGetWidth(self.collectionView.bounds), self.contentHeight);
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
  NSMutableArray *result = [NSMutableArray array];
  for (UICollectionViewLayoutAttributes *attrs in self.attributesArray) {
    if (CGRectIntersectsRect(rect, attrs.frame)) {
      [result addObject:attrs];
    }
  }
  return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.item < self.attributesArray.count) {
    return self.attributesArray[indexPath.item];
  }
  return nil;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
  CGRect oldBounds = self.collectionView.bounds;
  return fabs(CGRectGetWidth(oldBounds) - CGRectGetWidth(newBounds)) > 0.5;
}

@end

