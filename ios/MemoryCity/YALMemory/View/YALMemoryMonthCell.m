#import "YALMemoryMonthCell.h"

@interface YALMemoryMonthCell ()

@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UILabel *bigMonthLabel;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *featuredLabel;
@property (nonatomic, strong) UIButton *arrowButton;

@end

@implementation YALMemoryMonthCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        _card = [[UIView alloc] initWithFrame:CGRectZero];
        _card.layer.cornerRadius = 22;
        _card.layer.masksToBounds = NO;
        _card.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.06].CGColor;
        _card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.35].CGColor;
        _card.layer.shadowOpacity = 1.0;
        _card.layer.shadowOffset = CGSizeMake(0, 18);
        _card.layer.shadowRadius = 26;
        if (@available(iOS 13.0, *)) {
            _card.backgroundColor = [UIColor secondarySystemBackgroundColor];
        } else {
            _card.backgroundColor = [UIColor whiteColor];
        }
        [self.contentView addSubview:_card];

        _monthLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _monthLabel.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
        _monthLabel.textColor = [UIColor colorWithRed:1 green:0.74 blue:0.46 alpha:1];
        [_card addSubview:_monthLabel];

        _countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _countLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        _countLabel.textColor = [UIColor secondaryLabelColor];
        [_card addSubview:_countLabel];

        _bigMonthLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _bigMonthLabel.font = [UIFont systemFontOfSize:96 weight:UIFontWeightHeavy];
        _bigMonthLabel.textColor = [UIColor colorWithWhite:1 alpha:0.04];
        _bigMonthLabel.textAlignment = NSTextAlignmentRight;
        [_card addSubview:_bigMonthLabel];

        _coverImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
        _coverImageView.layer.cornerRadius = 18;
        [_card addSubview:_coverImageView];

        _featuredLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _featuredLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        _featuredLabel.textColor = [UIColor secondaryLabelColor];
        _featuredLabel.numberOfLines = 2;
        [_card addSubview:_featuredLabel];

        _arrowButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _arrowButton.userInteractionEnabled = NO;
        _arrowButton.backgroundColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
        _arrowButton.layer.cornerRadius = 18;
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg =
                [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold];
            UIImage *img = [UIImage systemImageNamed:@"chevron.right" withConfiguration:cfg];
            [_arrowButton setImage:img forState:UIControlStateNormal];
            _arrowButton.tintColor = [UIColor blackColor];
        }
        [_card addSubview:_arrowButton];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.coverImageView.image = nil;
    self.monthLabel.text = @"";
    self.countLabel.text = @"";
    self.bigMonthLabel.text = @"";
    self.featuredLabel.text = @"";
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    self.card.frame = CGRectMake(0, 0, w, h);

    CGFloat inset = 20;

    self.monthLabel.frame = CGRectMake(inset, 18, w - inset * 2, 34);
    self.countLabel.frame = CGRectMake(inset, CGRectGetMaxY(self.monthLabel.frame) + 2, w - inset * 2, 16);

    self.bigMonthLabel.frame = CGRectMake(w - 160, 10, 140, 100);

    CGFloat coverY = CGRectGetMaxY(self.countLabel.frame) + 14;
    CGFloat coverH = h - coverY - 56;
    self.coverImageView.frame = CGRectMake(inset, coverY, w - inset * 2, coverH);

    self.featuredLabel.frame = CGRectMake(inset,
                                          CGRectGetMaxY(self.coverImageView.frame) + 10,
                                          w - inset * 2 - 44,
                                          36);

    self.arrowButton.frame = CGRectMake(w - inset - 36, h - 18 - 36, 36, 36);

    self.card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.card.bounds cornerRadius:22].CGPath;
}

- (void)configureWithModel:(YALMemoryMonthModel *)model {
    self.monthLabel.text = model.monthName;
    self.countLabel.text = [NSString stringWithFormat:@"%ld MEMORIES", (long)MAX(0, model.memoryCount)];
    self.bigMonthLabel.text = model.monthNumberText;
    self.featuredLabel.text = model.featuredTitle.length > 0 ? model.featuredTitle : @"FEATURED MOMENT";

    UIImage *img = model.coverImage;
    if (!img) img = [UIImage imageNamed:@"WechatIMG395 1.jpg"];
    self.coverImageView.image = img;
}

@end

