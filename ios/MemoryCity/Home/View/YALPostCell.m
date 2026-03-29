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
    _imageView.contentMode = UIViewContentModeScaleAspectFill;  // 改为 ScaleAspectFill
    _imageView.clipsToBounds = YES;
    _imageView.layer.cornerRadius = 8.0;  // 添加圆角
    _imageView.layer.masksToBounds = YES;

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
        make.top.equalTo(self.contentView.mas_top).offset(8.0);  // 添加顶部间距
        make.left.equalTo(self.contentView.mas_left).offset(8.0);  // 添加左侧间距
        make.right.equalTo(self.contentView.mas_right).offset(-8.0);  // 添加右侧间距
        self.imageHeightConstraint = make.height.mas_equalTo(120.0);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageView.mas_bottom).offset(8.0);  // 增加间距
        make.left.equalTo(self.contentView.mas_left).offset(12.0);
        make.right.equalTo(self.contentView.mas_right).offset(-12.0);
        make.height.mas_equalTo(20.0);
    }];

    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4.0);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.titleLabel);
        make.height.mas_equalTo(34.0);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-12.0);  // 添加底部约束
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
    CGFloat imageHeight = 0.0;
    
    if (self.useWaterfall) {
        // 瀑布流模式：根据图片比例计算高度，但限制在合理范围内
        imageHeight = width * self.imageRatio;
        // 限制图片高度在120-400之间
        imageHeight = MAX(120.0, MIN(imageHeight, 400.0));
    } else {
        // 单列模式：使用动态计算的高度，基于屏幕宽度
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat itemWidth = screenWidth - 24.0;  // 左右边距各12
        CGFloat baseHeight = itemWidth * 0.75;  // 使用4:3的比例
        
        // 如果图片比例更接近正方形，使用更高的高度
        if (self.imageRatio > 0.8 && self.imageRatio < 1.2) {
            baseHeight = itemWidth;  // 正方形图片使用1:1比例
        }
        
        imageHeight = MAX(200.0, MIN(baseHeight, 400.0));  // 限制在200-400之间
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
