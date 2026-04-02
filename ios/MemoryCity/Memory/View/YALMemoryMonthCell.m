#import "YALMemoryMonthCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

static NSString *YALMemoryImageURLString(NSString *raw) {
    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) {
        return nil;
    }
    if ([raw hasPrefix:@"http://"] || [raw hasPrefix:@"https://"]) {
        return raw;
    }
    return [NSString stringWithFormat:@"http://%@", raw];
}

@interface YALMemoryMonthCell ()

@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIView *heroPanel;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UILabel *bigMonthLabel;
@property (nonatomic, strong) UIImageView *primaryImageView;
@property (nonatomic, strong) UIImageView *secondaryImageView;
@property (nonatomic, strong) UIImageView *tertiaryImageView;
@property (nonatomic, strong) UILabel *stackCountLabel;
@property (nonatomic, strong) UILabel *featuredCaptionLabel;
@property (nonatomic, strong) UILabel *featuredLabel;
@property (nonatomic, strong) UIButton *arrowButton;

@end

@implementation YALMemoryMonthCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        _card = [[UIView alloc] init];
        _card.layer.cornerRadius = 28.0;
        _card.layer.masksToBounds = NO;
        _card.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _card.layer.borderColor = [UIColor colorWithRed:0.50 green:0.36 blue:0.22 alpha:0.08].CGColor;
        _card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
        _card.layer.shadowOpacity = 1.0;
        _card.layer.shadowOffset = CGSizeMake(0, 12);
        _card.layer.shadowRadius = 22.0;
        _card.backgroundColor = [UIColor colorWithRed:0.998 green:0.992 blue:0.985 alpha:1.0];
        [self.contentView addSubview:_card];

        _heroPanel = [[UIView alloc] init];
        _heroPanel.backgroundColor = [UIColor colorWithRed:0.99 green:0.95 blue:0.90 alpha:1.0];
        _heroPanel.layer.cornerRadius = 22.0;
        _heroPanel.layer.masksToBounds = YES;
        [_card addSubview:_heroPanel];

        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.colors = @[
            (id)[UIColor colorWithRed:1.0 green:0.97 blue:0.93 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.98 green:0.91 blue:0.80 alpha:1.0].CGColor
        ];
        gradient.startPoint = CGPointMake(0, 0);
        gradient.endPoint = CGPointMake(1, 1);
        [_heroPanel.layer insertSublayer:gradient atIndex:0];

        _monthLabel = [[UILabel alloc] init];
        _monthLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
        _monthLabel.textColor = [UIColor colorWithRed:0.36 green:0.23 blue:0.10 alpha:1.0];
        [_card addSubview:_monthLabel];

        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        _countLabel.textColor = [UIColor secondaryLabelColor];
        [_card addSubview:_countLabel];

        _bigMonthLabel = [[UILabel alloc] init];
        _bigMonthLabel.font = [UIFont systemFontOfSize:108 weight:UIFontWeightBlack];
        _bigMonthLabel.textColor = [UIColor colorWithRed:0.69 green:0.48 blue:0.24 alpha:0.10];
        _bigMonthLabel.textAlignment = NSTextAlignmentRight;
        [_card addSubview:_bigMonthLabel];

        _secondaryImageView = [self buildPreviewImageViewWithCornerRadius:16.0];
        [_heroPanel addSubview:_secondaryImageView];

        _tertiaryImageView = [self buildPreviewImageViewWithCornerRadius:16.0];
        [_heroPanel addSubview:_tertiaryImageView];

        _primaryImageView = [self buildPreviewImageViewWithCornerRadius:18.0];
        [_heroPanel addSubview:_primaryImageView];

        _stackCountLabel = [[UILabel alloc] init];
        _stackCountLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.50];
        _stackCountLabel.textColor = [UIColor whiteColor];
        _stackCountLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        _stackCountLabel.textAlignment = NSTextAlignmentCenter;
        _stackCountLabel.layer.cornerRadius = 12.0;
        _stackCountLabel.layer.masksToBounds = YES;
        _stackCountLabel.hidden = YES;
        [_heroPanel addSubview:_stackCountLabel];

        _featuredCaptionLabel = [[UILabel alloc] init];
        _featuredCaptionLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
        _featuredCaptionLabel.textColor = [UIColor colorWithRed:1.0 green:0.76 blue:0.48 alpha:1.0];
        _featuredCaptionLabel.text = @"FEATURED STORY";
        [_card addSubview:_featuredCaptionLabel];

        _featuredLabel = [[UILabel alloc] init];
        _featuredLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        _featuredLabel.textColor = [UIColor colorWithRed:0.31 green:0.24 blue:0.16 alpha:1.0];
        _featuredLabel.numberOfLines = 2;
        [_card addSubview:_featuredLabel];

        _arrowButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _arrowButton.userInteractionEnabled = NO;
        _arrowButton.backgroundColor = [UIColor colorWithRed:1 green:0.72 blue:0.40 alpha:1];
        _arrowButton.layer.cornerRadius = 20.0;
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg =
                [UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightBold];
            UIImage *img = [UIImage systemImageNamed:@"arrow.up.right" withConfiguration:cfg];
            [_arrowButton setImage:img forState:UIControlStateNormal];
        _arrowButton.tintColor = [UIColor colorWithRed:0.42 green:0.30 blue:0.08 alpha:1.0];
        }
        [_card addSubview:_arrowButton];

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];

        [_monthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(22);
            make.left.equalTo(_card).offset(22);
            make.right.lessThanOrEqualTo(_card).offset(-110);
        }];
        [_countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_monthLabel.mas_bottom).offset(3);
            make.left.equalTo(_monthLabel);
        }];
        [_bigMonthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card).offset(8);
            make.right.equalTo(_card).offset(-18);
            make.width.mas_equalTo(148);
            make.height.mas_equalTo(112);
        }];
        [_heroPanel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_countLabel.mas_bottom).offset(16);
            make.left.equalTo(_card).offset(20);
            make.right.equalTo(_card).offset(-20);
            make.height.mas_equalTo(148);
        }];
        [_secondaryImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_heroPanel).offset(16);
            make.left.equalTo(_heroPanel).offset(14);
            make.width.mas_equalTo(104);
            make.height.mas_equalTo(112);
        }];
        [_tertiaryImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_secondaryImageView.mas_right).offset(10);
            make.bottom.equalTo(_secondaryImageView).offset(-10);
            make.width.mas_equalTo(86);
            make.height.mas_equalTo(92);
        }];
        [_primaryImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_heroPanel).offset(10);
            make.right.equalTo(_heroPanel).offset(-14);
            make.width.mas_equalTo(164);
            make.height.mas_equalTo(128);
        }];
        [_stackCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_primaryImageView).offset(-8);
            make.bottom.equalTo(_primaryImageView).offset(-8);
            make.height.mas_equalTo(24);
            make.width.mas_greaterThanOrEqualTo(36);
        }];
        [_featuredCaptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_heroPanel.mas_bottom).offset(16);
            make.left.equalTo(_card).offset(22);
            make.right.lessThanOrEqualTo(_arrowButton.mas_left).offset(-10);
        }];
        [_arrowButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_card).offset(-22);
            make.bottom.equalTo(_card).offset(-20);
            make.width.height.mas_equalTo(40);
        }];
        [_featuredLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_featuredCaptionLabel);
            make.right.equalTo(_arrowButton.mas_left).offset(-10);
            make.top.equalTo(_featuredCaptionLabel.mas_bottom).offset(6);
            make.centerY.equalTo(_arrowButton);
        }];
    }
    return self;
}

- (UIImageView *)buildPreviewImageViewWithCornerRadius:(CGFloat)cornerRadius {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = cornerRadius;
    imageView.backgroundColor = [UIColor colorWithRed:1.0 green:0.98 blue:0.95 alpha:1.0];
    return imageView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.primaryImageView.image = nil;
    self.secondaryImageView.image = nil;
    self.tertiaryImageView.image = nil;
    self.stackCountLabel.hidden = YES;
    self.stackCountLabel.text = @"";
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.card.bounds cornerRadius:28.0].CGPath;
    self.heroPanel.layer.sublayers.firstObject.frame = self.heroPanel.bounds;
}

- (void)configureWithModel:(YALMemoryMonthModel *)model {
    self.monthLabel.text = model.monthName;
    self.countLabel.text = [NSString stringWithFormat:@"%ld memories collected", (long)MAX(0, model.memoryCount)];
    self.bigMonthLabel.text = model.monthNumberText;
    self.featuredLabel.text = model.featuredTitle.length > 0 ? model.featuredTitle : @"FEATURED MOMENT";

    NSMutableArray<NSString *> *urls = [NSMutableArray array];
    if ([model.coverImageURLStrings isKindOfClass:[NSArray class]]) {
        for (id obj in model.coverImageURLStrings) {
            NSString *full = YALMemoryImageURLString(obj);
            if (full.length > 0) {
                [urls addObject:full];
            }
        }
    }
    if (urls.count == 0) {
        NSString *fallback = YALMemoryImageURLString(model.coverImageURLString);
        if (fallback.length > 0) {
            [urls addObject:fallback];
        }
    }

    [self configureImageView:self.primaryImageView withURLString:(urls.count > 0 ? urls[0] : nil)];
    [self configureImageView:self.secondaryImageView withURLString:(urls.count > 1 ? urls[1] : nil)];
    [self configureImageView:self.tertiaryImageView withURLString:(urls.count > 2 ? urls[2] : nil)];

    self.secondaryImageView.hidden = (urls.count <= 1);
    self.tertiaryImageView.hidden = (urls.count <= 2);
    self.stackCountLabel.hidden = (urls.count <= 3);
    self.stackCountLabel.text = urls.count > 3 ? [NSString stringWithFormat:@"+%lu", (unsigned long)(urls.count - 3)] : @"";
}

- (void)configureImageView:(UIImageView *)imageView withURLString:(nullable NSString *)urlString {
    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"photo"];
    }

    if (urlString.length > 0) {
        imageView.hidden = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.backgroundColor = [UIColor clearColor];
        [imageView sd_setImageWithURL:[NSURL URLWithString:urlString]
                     placeholderImage:placeholder
                              options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
    } else {
        imageView.hidden = NO;
        imageView.image = placeholder;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.backgroundColor = [UIColor colorWithRed:1.0 green:0.98 blue:0.95 alpha:1.0];
        if (@available(iOS 13.0, *)) {
            imageView.tintColor = [UIColor colorWithRed:0.78 green:0.62 blue:0.42 alpha:1.0];
        }
    }
}

@end
