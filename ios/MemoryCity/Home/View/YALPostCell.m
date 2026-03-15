//
//  YALPostCell.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALPostCell.h"
#import "YALPostModel.h"

@interface YALPostCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, assign) CGFloat imageRatio;
@property (nonatomic, assign) BOOL useWaterfall;
@property (nonatomic, assign) CGFloat fixedImageHeight;

@end

@implementation YALPostCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  self.backgroundColor = [UIColor clearColor];
  self.layer.cornerRadius = 12.0;
  self.layer.masksToBounds = NO;
  self.layer.shadowColor = [UIColor blackColor].CGColor;
  self.layer.shadowOpacity = 0.08;
  self.layer.shadowRadius = 6.0;
  self.layer.shadowOffset = CGSizeMake(0, 2);

  self.contentView.backgroundColor = [UIColor systemBackgroundColor];
  self.contentView.layer.cornerRadius = 12.0;
  self.contentView.layer.masksToBounds = YES;

  self.imageRatio = 1.0;
  self.useWaterfall = YES;
  self.fixedImageHeight = 0.0;

  _imageView = [[UIImageView alloc] init];
  _imageView.contentMode = UIViewContentModeScaleAspectFill;
  _imageView.clipsToBounds = YES;

  _titleLabel = [[UILabel alloc] init];
  _titleLabel.font = [UIFont boldSystemFontOfSize:14.0];

  _descLabel = [[UILabel alloc] init];
  _descLabel.font = [UIFont systemFontOfSize:12.0];
  _descLabel.textColor = [UIColor secondaryLabelColor];
  _descLabel.numberOfLines = 2;

  [self.contentView addSubview:_imageView];
  [self.contentView addSubview:_titleLabel];
  [self.contentView addSubview:_descLabel];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:12.0].CGPath;

  CGFloat width = CGRectGetWidth(self.bounds);
  CGFloat imageHeight = self.useWaterfall ? (width * self.imageRatio) : self.fixedImageHeight;
  imageHeight = MAX(120.0, imageHeight);
  imageHeight = MIN(imageHeight, CGRectGetHeight(self.bounds) - 60.0);

  self.imageView.frame = CGRectMake(0, 0, width, imageHeight);
  self.titleLabel.frame = CGRectMake(8, CGRectGetMaxY(self.imageView.frame) + 6, width - 16, 20);
  self.descLabel.frame = CGRectMake(8, CGRectGetMaxY(self.titleLabel.frame) + 4, width - 16, 34);
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.imageView.image = nil;
  self.titleLabel.text = nil;
  self.descLabel.text = nil;
  self.useWaterfall = YES;
  self.fixedImageHeight = 0.0;
}

- (void)configureWithModel:(YALPostModel *)model
              useWaterfall:(BOOL)useWaterfall
          fixedImageHeight:(CGFloat)fixedImageHeight {
  self.imageView.image = model.image;
  self.titleLabel.text = model.title;
  self.descLabel.text = model.desc;
  self.useWaterfall = useWaterfall;
  self.fixedImageHeight = fixedImageHeight;

  CGFloat ratio = 1.0;
  if (model.imageWidth > 0 && model.imageHeight > 0) {
    ratio = model.imageHeight / model.imageWidth;
  } else if (model.image.size.width > 0 && model.image.size.height > 0) {
    ratio = model.image.size.height / model.image.size.width;
  }
  self.imageRatio = MAX(ratio, 0.2);
  [self setNeedsLayout];
}

@end

