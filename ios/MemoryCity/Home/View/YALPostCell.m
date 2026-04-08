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
    self.contentView.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;

    self.imageRatio = 1.0;
    self.useWaterfall = YES;
    self.fixedImageHeight = 0.0;

    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;  // 改为 ScaleAspectFill
    _imageView.clipsToBounds = YES;
    _imageView.layer.cornerRadius = 8.0;  // 添加圆角
    _imageView.layer.masksToBounds = YES;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    _titleLabel.numberOfLines = 1;
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    _descLabel = [[UILabel alloc] init];
    _descLabel.font = [UIFont systemFontOfSize:12.0];
    _descLabel.textColor = [UIColor secondaryLabelColor];
    _descLabel.numberOfLines = 2;
    _descLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    [self.contentView addSubview:_imageView];
    [self.contentView addSubview:_titleLabel];
    [self.contentView addSubview:_descLabel];

    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(8.0);  // 添加顶部间距
        make.left.equalTo(self.contentView.mas_left).offset(8.0);  // 添加左侧间距
        make.right.equalTo(self.contentView.mas_right).offset(-8.0);  // 添加右侧间距
        self.imageHeightConstraint = make.height.mas_equalTo(120.0);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageView.mas_bottom).offset(7.0);
        make.left.equalTo(self.contentView.mas_left).offset(12.0);
        make.right.equalTo(self.contentView.mas_right).offset(-12.0);
        make.height.mas_equalTo(20.0);
    }];

    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(5.0);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.titleLabel);
        make.height.mas_equalTo(30.0);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-10.0);
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
    self.contentView.backgroundColor = isDark ? [UIColor secondarySystemBackgroundColor] : [UIColor systemBackgroundColor];
    self.contentView.layer.borderColor = (isDark
                                          ? [UIColor colorWithWhite:1.0 alpha:0.18]
                                          : [UIColor colorWithWhite:0.0 alpha:0.06]).CGColor;
    self.layer.shadowOpacity = isDark ? 0.24 : 0.08;
    self.layer.shadowRadius = isDark ? 10.0 : 6.0;
    self.layer.shadowOffset = isDark ? CGSizeMake(0, 4) : CGSizeMake(0, 2);
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
    self.descLabel.hidden = NO;
    self.useWaterfall = YES;
    self.fixedImageHeight = 0.0;
    self.imageRatio = 1.0;
}

- (void)configureWithModel:(YALPostModel *)model useWaterfall:(BOOL)useWaterfall fixedImageHeight:(CGFloat)fixedImageHeight {
    NSString *titleText = [model.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *descText = [model.desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (titleText.length == 0) {
        titleText = @"未命名内容";
    }

    self.titleLabel.text = titleText;
    self.descLabel.text = descText;
    self.descLabel.hidden = (descText.length == 0);

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

@end
