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
@property (nonatomic, strong) CAGradientLayer *imageVignetteLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIView *metaRowView;
@property (nonatomic, strong) UIImageView *heartImageView;
@property (nonatomic, strong) UILabel *likeCountLabel;
@property (nonatomic, strong) UIView *metaDividerView;
@property (nonatomic, strong) UIImageView *commentImageView;
@property (nonatomic, strong) UILabel *commentCountLabel;
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
    self.layer.cornerRadius = 22.0;
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor colorWithRed:0.38 green:0.24 blue:0.12 alpha:1.0].CGColor;
    self.layer.shadowOpacity = 0.10;
    self.layer.shadowRadius = 18.0;
    self.layer.shadowOffset = CGSizeMake(0, 9.0);

    self.contentView.backgroundColor = [UIColor colorWithRed:1.0 green:0.995 blue:0.985 alpha:1.0];
    self.contentView.layer.cornerRadius = 22.0;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;

    self.imageRatio = 1.0;
    self.useWaterfall = YES;
    self.fixedImageHeight = 0.0;

    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;  // 改为 ScaleAspectFill
    _imageView.clipsToBounds = YES;
    _imageView.layer.cornerRadius = 18.0;
    _imageView.layer.masksToBounds = YES;

    self.imageVignetteLayer = [CAGradientLayer layer];
    self.imageVignetteLayer.colors = @[
        (id)[UIColor colorWithWhite:0.0 alpha:0.00].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:0.12].CGColor
    ];
    self.imageVignetteLayer.startPoint = CGPointMake(0.5, 0.18);
    self.imageVignetteLayer.endPoint = CGPointMake(0.5, 1.0);
    [self.imageView.layer addSublayer:self.imageVignetteLayer];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _titleLabel.numberOfLines = 1;
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    _descLabel = [[UILabel alloc] init];
    _descLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    _descLabel.textColor = [UIColor secondaryLabelColor];
    _descLabel.numberOfLines = 1;
    _descLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    _metaRowView = [[UIView alloc] init];
    _metaRowView.backgroundColor = [UIColor clearColor];

    _heartImageView = [[UIImageView alloc] init];
    _heartImageView.contentMode = UIViewContentModeScaleAspectFit;

    _likeCountLabel = [[UILabel alloc] init];
    _likeCountLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightSemibold];
    _likeCountLabel.numberOfLines = 1;

    _metaDividerView = [[UIView alloc] init];
    _metaDividerView.layer.cornerRadius = 1.5;
    _metaDividerView.layer.masksToBounds = YES;

    _commentImageView = [[UIImageView alloc] init];
    _commentImageView.contentMode = UIViewContentModeScaleAspectFit;

    _commentCountLabel = [[UILabel alloc] init];
    _commentCountLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightSemibold];
    _commentCountLabel.numberOfLines = 1;

    if (@available(iOS 13.0, *)) {
        _heartImageView.image = [UIImage systemImageNamed:@"heart.fill"];
        _commentImageView.image = [UIImage systemImageNamed:@"bubble.left.fill"];
    }

    [self.contentView addSubview:_imageView];
    [self.contentView addSubview:_titleLabel];
    [self.contentView addSubview:_descLabel];
    [self.contentView addSubview:_metaRowView];
    [self.metaRowView addSubview:_heartImageView];
    [self.metaRowView addSubview:_likeCountLabel];
    [self.metaRowView addSubview:_metaDividerView];
    [self.metaRowView addSubview:_commentImageView];
    [self.metaRowView addSubview:_commentCountLabel];

    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(9.0);
        make.left.equalTo(self.contentView.mas_left).offset(9.0);
        make.right.equalTo(self.contentView.mas_right).offset(-9.0);
        self.imageHeightConstraint = make.height.mas_equalTo(120.0);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageView.mas_bottom).offset(9.0);
        make.left.equalTo(self.contentView.mas_left).offset(14.0);
        make.right.equalTo(self.contentView.mas_right).offset(-14.0);
        make.height.mas_equalTo(20.0);
    }];

    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(3.0);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.titleLabel);
        make.height.mas_equalTo(17.0);
    }];

    [self.metaRowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descLabel.mas_bottom).offset(5.0);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.titleLabel);
        make.height.mas_equalTo(22.0);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-8.0);
    }];

    [self.heartImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.metaRowView.mas_left);
        make.centerY.equalTo(self.metaRowView.mas_centerY);
        make.width.height.mas_equalTo(14.0);
    }];

    [self.likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.heartImageView.mas_right).offset(4.0);
        make.centerY.equalTo(self.metaRowView.mas_centerY);
    }];

    [self.metaDividerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.likeCountLabel.mas_right).offset(8.0);
        make.centerY.equalTo(self.metaRowView.mas_centerY);
        make.width.height.mas_equalTo(3.0);
    }];

    [self.commentImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.metaDividerView.mas_right).offset(8.0);
        make.centerY.equalTo(self.metaRowView.mas_centerY);
        make.width.height.mas_equalTo(14.0);
    }];

    [self.commentCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.commentImageView.mas_right).offset(4.0);
        make.centerY.equalTo(self.metaRowView.mas_centerY);
        make.right.lessThanOrEqualTo(self.metaRowView.mas_right);
    }];

    [self applyAppearanceForCurrentTrait];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection &&
            [self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self applyAppearanceForCurrentTrait];
            [self setNeedsLayout];
        }
    }
}

- (void)applyAppearanceForCurrentTrait {
    BOOL isDark = NO;
    if (@available(iOS 12.0, *)) {
        isDark = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    }
    self.contentView.backgroundColor = isDark ? [UIColor secondarySystemBackgroundColor] : [UIColor colorWithRed:1.0 green:0.995 blue:0.985 alpha:1.0];
    self.contentView.layer.borderColor = (isDark
                                          ? [UIColor colorWithWhite:1.0 alpha:0.18]
                                          : [UIColor colorWithRed:0.55 green:0.36 blue:0.17 alpha:0.10]).CGColor;
    self.layer.shadowOpacity = isDark ? 0.28 : 0.10;
    self.layer.shadowRadius = isDark ? 14.0 : 18.0;
    self.layer.shadowOffset = isDark ? CGSizeMake(0, 6.0) : CGSizeMake(0, 9.0);

    UIColor *accentColor = [UIColor colorWithRed:0.94 green:0.28 blue:0.20 alpha:1.0];
    UIColor *mutedColor = isDark ? [UIColor secondaryLabelColor] : [UIColor colorWithRed:0.58 green:0.45 blue:0.33 alpha:1.0];
    self.heartImageView.tintColor = accentColor;
    self.commentImageView.tintColor = mutedColor;
    self.likeCountLabel.textColor = mutedColor;
    self.commentCountLabel.textColor = mutedColor;
    self.metaDividerView.backgroundColor = [mutedColor colorWithAlphaComponent:0.35];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:22.0].CGPath;
    self.imageVignetteLayer.frame = self.imageView.bounds;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.imageView.image = nil;
    [self.imageView sd_cancelCurrentImageLoad];
    self.titleLabel.text = nil;
    self.descLabel.text = nil;
    self.descLabel.hidden = NO;
    self.likeCountLabel.text = nil;
    self.commentCountLabel.text = nil;
    self.useWaterfall = YES;
    self.fixedImageHeight = 0.0;
    self.imageRatio = 1.0;
}

- (void)configureWithModel:(YALPostModel *)model useWaterfall:(BOOL)useWaterfall fixedImageHeight:(CGFloat)fixedImageHeight {
    NSString *titleText = [model.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *descText = [model.desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (descText.length == 0) {
        NSMutableArray<NSString *> *parts = [NSMutableArray array];
        NSString *cityText = [model.city stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *moodText = [model.mood stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *yearText = [model.year stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (cityText.length > 0) { [parts addObject:cityText]; }
        if (moodText.length > 0) { [parts addObject:moodText]; }
        if (yearText.length > 0) { [parts addObject:yearText]; }
        descText = [parts componentsJoinedByString:@" · "];
    }
    if (titleText.length == 0) {
        titleText = @"未命名内容";
    }

    self.titleLabel.text = titleText;
    self.descLabel.text = descText;
    self.descLabel.hidden = (descText.length == 0);
    self.likeCountLabel.text = [self compactCountText:MAX(model.likeCount, 0)];
    self.commentCountLabel.text = [self compactCountText:MAX(model.commentCount, 0)];
    if (@available(iOS 13.0, *)) {
        NSString *heartIconName = model.isLiked ? @"heart.fill" : @"heart";
        self.heartImageView.image = [UIImage systemImageNamed:heartIconName];
    }

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
    CGFloat imageHeight = 0.0;
    
    if (self.useWaterfall) {
        // 瀑布流模式优先使用外部传入的固定高度，避免重复计算导致抖动。
        if (self.fixedImageHeight > 0) {
            imageHeight = self.fixedImageHeight;
        } else {
            imageHeight = width * self.imageRatio;
        }
        // 限制图片高度在120-400之间
        imageHeight = MAX(120.0, MIN(imageHeight, 400.0));
    } else {
        // 单列模式使用统一高度，保证所有卡片整齐对齐。
        imageHeight = (self.fixedImageHeight > 0) ? self.fixedImageHeight : 222.0;
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

- (NSString *)compactCountText:(NSInteger)count {
    if (count >= 10000) {
        CGFloat value = count / 10000.0;
        return [NSString stringWithFormat:@"%.1f万", value];
    }
    return [NSString stringWithFormat:@"%ld", (long)count];
}

@end
