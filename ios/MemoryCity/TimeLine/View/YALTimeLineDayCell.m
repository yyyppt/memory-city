#import "YALTimeLineDayCell.h"

@interface YALTimeLineDayCell ()

@property (nonatomic, strong) UILabel *dayNumLabel;
@property (nonatomic, strong) UILabel *weekdayLabel;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIImageView *thumbView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@end

@implementation YALTimeLineDayCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        _dayNumLabel = [[UILabel alloc] init];
        _dayNumLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightHeavy];
        _dayNumLabel.textColor = [UIColor labelColor];
        [self.contentView addSubview:_dayNumLabel];

        _weekdayLabel = [[UILabel alloc] init];
        _weekdayLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        _weekdayLabel.textColor = [UIColor secondaryLabelColor];
        [self.contentView addSubview:_weekdayLabel];

        _card = [[UIView alloc] init];
        _card.backgroundColor = [UIColor secondarySystemBackgroundColor];
        _card.layer.cornerRadius = 16;
        _card.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _card.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06].CGColor;
        _card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.06].CGColor;
        _card.layer.shadowOpacity = 1;
        _card.layer.shadowOffset = CGSizeMake(0, 4);
        _card.layer.shadowRadius = 10;
        [self.contentView addSubview:_card];

        _thumbView = [[UIImageView alloc] init];
        _thumbView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbView.clipsToBounds = YES;
        _thumbView.layer.cornerRadius = 12;
        [_card addSubview:_thumbView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [UIColor labelColor];
        _titleLabel.numberOfLines = 2;
        [_card addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont systemFontOfSize:13];
        _subtitleLabel.textColor = [UIColor secondaryLabelColor];
        _subtitleLabel.numberOfLines = 2;
        [_card addSubview:_subtitleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat leftW = 52;
    CGFloat pad = 16;
    CGFloat cardX = leftW + 8;
    CGFloat cardW = w - cardX - pad;
    CGFloat rowH = self.contentView.bounds.size.height;
    CGFloat cardH = rowH - 12;

    self.dayNumLabel.frame = CGRectMake(pad, 8, leftW - 8, 34);
    self.weekdayLabel.frame = CGRectMake(pad, CGRectGetMaxY(self.dayNumLabel.frame) - 2, leftW - 8, 16);

    self.card.frame = CGRectMake(cardX, 6, cardW, cardH);
    CGFloat inner = 12;
    CGFloat thumb = 72;
    self.thumbView.frame = CGRectMake(inner, inner, thumb, thumb);
    CGFloat textX = CGRectGetMaxX(self.thumbView.frame) + 12;
    CGFloat textW = cardW - textX - inner;
    self.titleLabel.frame = CGRectMake(textX, inner + 2, textW, 40);
    self.subtitleLabel.frame = CGRectMake(textX, CGRectGetMaxY(self.titleLabel.frame) + 4, textW, 36);

    self.card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.card.bounds cornerRadius:16].CGPath;
}

- (void)configureWithEntry:(YALTimeLineEntryModel *)entry dayText:(NSString *)dayText weekdayText:(NSString *)weekdayText {
    self.dayNumLabel.text = dayText;
    self.weekdayLabel.text = weekdayText;
    self.titleLabel.text = entry.titleText ?: @"";
    self.subtitleLabel.text = entry.subtitleText ?: @"";
    UIImage *img = entry.image ?: [UIImage imageNamed:@"WechatIMG395 1.jpg"];
    self.thumbView.image = img;
}

@end
