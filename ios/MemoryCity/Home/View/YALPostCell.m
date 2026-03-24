//
//  YALPostCell.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALPostCell.h"
#import "YALPostModel.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface YALPostCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, assign) CGFloat imageRatio;
@property (nonatomic, assign) BOOL useWaterfall;
@property (nonatomic, assign) CGFloat fixedImageHeight;
@property (nonatomic, strong) MASConstraint *imageHeightConstraint;

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
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
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

    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        self.imageHeightConstraint = make.height.mas_equalTo(120.0);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageView.mas_bottom).offset(6.0);
        make.left.equalTo(self.contentView.mas_left).offset(8.0);
        make.right.equalTo(self.contentView.mas_right).offset(-8.0);
        make.height.mas_equalTo(20.0);
    }];

    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4.0);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.titleLabel);
        make.height.mas_equalTo(34.0);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:12.0].CGPath;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.imageView.image = nil;
    [self.imageView sd_cancelCurrentImageLoad];
    self.titleLabel.text = nil;
    self.descLabel.text = nil;
    self.useWaterfall = YES;
    self.fixedImageHeight = 0.0;
    self.imageRatio = 1.0;
}

- (void)configureWithModel:(YALPostModel *)model useWaterfall:(BOOL)useWaterfall fixedImageHeight:(CGFloat)fixedImageHeight {
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

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat imageHeight = self.useWaterfall ? (width * self.imageRatio) : self.fixedImageHeight;
    imageHeight = MAX(120.0, imageHeight);
    CGFloat maxAvailableHeight = CGRectGetHeight(self.bounds) - 60.0;
    if (maxAvailableHeight > 120.0) {
        imageHeight = MIN(imageHeight, maxAvailableHeight);
    }
    self.imageHeightConstraint.offset = imageHeight;

    if (model.imageURLString.length > 0) {
        NSURL *url = [NSURL URLWithString:model.imageURLString];
        [self.imageView sd_setImageWithURL:url
                          placeholderImage:model.image
                                   options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages
                                 completed:nil];
    } else {
        self.imageView.image = model.image;
    }
    [self.contentView layoutIfNeeded];
}

@end
