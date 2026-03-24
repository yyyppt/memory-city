#import "YALMemoryMonthCell.h"
#import <Masonry/Masonry.h>

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

        _card = [[UIView alloc] init];
        _card.layer.cornerRadius = 22;
        _card.layer.masksToBounds = NO;
        _card.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.06].CGColor;
        _card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.35].CGColor;
        _card.layer.shadowOpacity = 1.0;
        _card.layer.shadowOffset = CGSizeMake(0, 18);
        _card.layer.shadowRadius = 26;
        _card.backgroundColor = [UIColor secondarySystemBackgroundColor];
        [self.contentView addSubview:_card];

        _monthLabel = [[UILabel alloc] init];
        _monthLabel.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
        _monthLabel.textColor = [UIColor colorWithRed:1 green:0.74 blue:0.46 alpha:1];
        [_card addSubview:_monthLabel];

        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        _countLabel.textColor = [UIColor secondaryLabelColor];
        [_card addSubview:_countLabel];

        _bigMonthLabel = [[UILabel alloc] init];
        _bigMonthLabel.font = [UIFont systemFontOfSize:96 weight:UIFontWeightHeavy];
        _bigMonthLabel.textColor = [UIColor colorWithWhite:1 alpha:0.04];
        _bigMonthLabel.textAlignment = NSTextAlignmentRight;
        [_card addSubview:_bigMonthLabel];

        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
        _coverImageView.layer.cornerRadius = 18;
        [_card addSubview:_coverImageView];

        _featuredLabel = [[UILabel alloc] init];
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
            _arrowButton.tintColor = [UIColor labelColor];
        }
        [_card addSubview:_arrowButton];

        // Masonry 约束
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];

        CGFloat inset = 20.0;

        [_monthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_card.mas_top).offset(18);
            make.left.equalTo(_card.mas_left).offset(inset);
            make.right.equalTo(_card.mas_right).offset(-inset);
            make.height.mas_equalTo(34);
        }];

        [_countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_monthLabel.mas_bottom).offset(2);
            make.left.right.equalTo(_monthLabel);
            make.height.mas_equalTo(16);
        }];

        [_bigMonthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_card.mas_right).offset(-20);
            make.top.equalTo(_card.mas_top).offset(10);
            make.width.mas_equalTo(140);
            make.height.mas_equalTo(100);
        }];

        [_coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_countLabel.mas_bottom).offset(14);
            make.left.equalTo(_card.mas_left).offset(inset);
            make.right.equalTo(_card.mas_right).offset(-inset);
            make.bottom.equalTo(_arrowButton.mas_top).offset(-10);
        }];

        [_arrowButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_card.mas_right).offset(-inset);
            make.bottom.equalTo(_card.mas_bottom).offset(-18);
            make.width.height.mas_equalTo(36);
        }];

        [_featuredLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_card.mas_left).offset(inset);
            make.right.equalTo(_arrowButton.mas_left).offset(-8);
            make.centerY.equalTo(_arrowButton);
            make.height.mas_equalTo(36);
        }];
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
