#import "YALTimeLineDayCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

static NSString *YALTimeLineFullImageURLString(NSString *raw) {
    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) {
        return nil;
    }
    if ([raw hasPrefix:@"http://"] || [raw hasPrefix:@"https://"]) {
        return raw;
    }
    return [NSString stringWithFormat:@"http://%@", raw];
}

static UIColor *YALTimeLineDayPillColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor tertiarySystemBackgroundColor];
            }
            return [UIColor colorWithRed:0.99 green:0.95 blue:0.89 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.99 green:0.95 blue:0.89 alpha:1.0];
}

static UIColor *YALTimeLineDayCardColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor secondarySystemBackgroundColor];
            }
            return [UIColor colorWithRed:1.0 green:0.995 blue:0.985 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:1.0 green:0.995 blue:0.985 alpha:1.0];
}

static UIColor *YALTimeLineDayPrimaryAccentTextColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor systemOrangeColor];
            }
            return [UIColor colorWithRed:0.40 green:0.24 blue:0.08 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.40 green:0.24 blue:0.08 alpha:1.0];
}

static UIColor *YALTimeLineDaySecondaryAccentTextColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemOrangeColor];
    }
    return [UIColor colorWithRed:0.69 green:0.46 blue:0.22 alpha:1.0];
}

@interface YALTimeLineDayCell ()

@property (nonatomic, strong) UIView *dayPill;
@property (nonatomic, strong) UILabel *dayNumLabel;
@property (nonatomic, strong) UILabel *weekdayLabel;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIView *thumbContainer;
@property (nonatomic, strong) UIImageView *thumbView;
@property (nonatomic, strong) UIImageView *stackPreviewView;
@property (nonatomic, strong) UILabel *stackCountLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) UIView *accentBar;

@end

@implementation YALTimeLineDayCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        _dayPill = [[UIView alloc] init];
        _dayPill.backgroundColor = YALTimeLineDayPillColor();
        _dayPill.layer.cornerRadius = 18.0;
        [self.contentView addSubview:_dayPill];

        _dayNumLabel = [[UILabel alloc] init];
        _dayNumLabel.font = [UIFont systemFontOfSize:26 weight:UIFontWeightHeavy];
        _dayNumLabel.textColor = YALTimeLineDayPrimaryAccentTextColor();
        _dayNumLabel.textAlignment = NSTextAlignmentCenter;
        [_dayPill addSubview:_dayNumLabel];

        _weekdayLabel = [[UILabel alloc] init];
        _weekdayLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        _weekdayLabel.textColor = YALTimeLineDaySecondaryAccentTextColor();
        _weekdayLabel.textAlignment = NSTextAlignmentCenter;
        [_dayPill addSubview:_weekdayLabel];

        _card = [[UIView alloc] init];
        _card.backgroundColor = YALTimeLineDayCardColor();
        _card.layer.cornerRadius = 22.0;
        _card.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _card.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.05].CGColor;
        _card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
        _card.layer.shadowOpacity = 1.0;
        _card.layer.shadowOffset = CGSizeMake(0, 10);
        _card.layer.shadowRadius = 20.0;
        [self.contentView addSubview:_card];

        _accentBar = [[UIView alloc] init];
        _accentBar.backgroundColor = [UIColor colorWithRed:1 green:0.67 blue:0.34 alpha:1.0];
        _accentBar.layer.cornerRadius = 2.0;
        [_card addSubview:_accentBar];

        _thumbContainer = [[UIView alloc] init];
        _thumbContainer.backgroundColor = [UIColor clearColor];
        [_card addSubview:_thumbContainer];

        _stackPreviewView = [[UIImageView alloc] init];
        _stackPreviewView.contentMode = UIViewContentModeScaleAspectFill;
        _stackPreviewView.clipsToBounds = YES;
        _stackPreviewView.layer.cornerRadius = 14.0;
        _stackPreviewView.layer.borderWidth = 2.0;
        _stackPreviewView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.75].CGColor;
        _stackPreviewView.alpha = 0.0;
        [_thumbContainer addSubview:_stackPreviewView];

        _thumbView = [[UIImageView alloc] init];
        _thumbView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbView.clipsToBounds = YES;
        _thumbView.layer.cornerRadius = 16.0;
        [_thumbContainer addSubview:_thumbView];

        _stackCountLabel = [[UILabel alloc] init];
        _stackCountLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.58];
        _stackCountLabel.textColor = [UIColor whiteColor];
        _stackCountLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
        _stackCountLabel.textAlignment = NSTextAlignmentCenter;
        _stackCountLabel.layer.cornerRadius = 12.0;
        _stackCountLabel.layer.masksToBounds = YES;
        _stackCountLabel.hidden = YES;
        [_thumbContainer addSubview:_stackCountLabel];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [UIColor labelColor];
        _titleLabel.numberOfLines = 2;
        [_card addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        _subtitleLabel.textColor = [UIColor secondaryLabelColor];
        _subtitleLabel.numberOfLines = 2;
        [_card addSubview:_subtitleLabel];

        _metaLabel = [[UILabel alloc] init];
        _metaLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
        _metaLabel.textColor = YALTimeLineDaySecondaryAccentTextColor();
        [_card addSubview:_metaLabel];

        [_dayPill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView.mas_left).offset(16);
            make.top.equalTo(self.contentView.mas_top).offset(10);
            make.width.mas_equalTo(56);
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-10);
        }];
        [_dayNumLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_dayPill).offset(10);
            make.left.right.equalTo(_dayPill);
        }];
        [_weekdayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_dayPill);
            make.top.equalTo(_dayNumLabel.mas_bottom).offset(2);
            make.bottom.lessThanOrEqualTo(_dayPill).offset(-10);
        }];
        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_dayPill.mas_right).offset(12);
            make.top.equalTo(self.contentView.mas_top).offset(6);
            make.right.equalTo(self.contentView.mas_right).offset(-16);
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-6);
        }];
        [_accentBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_card).offset(18);
            make.top.equalTo(_card).offset(16);
            make.width.mas_equalTo(28);
            make.height.mas_equalTo(4);
        }];
        [_thumbContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_card).offset(18);
            make.top.equalTo(_accentBar.mas_bottom).offset(10);
            make.bottom.equalTo(_card).offset(-16);
            make.width.mas_equalTo(84);
        }];
        [_stackPreviewView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_thumbContainer).offset(8);
            make.top.equalTo(_thumbContainer).offset(8);
            make.width.height.mas_equalTo(68);
        }];
        [_thumbView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(_thumbContainer);
            make.width.height.mas_equalTo(72);
        }];
        [_stackCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_thumbView).offset(-6);
            make.bottom.equalTo(_thumbView).offset(-6);
            make.height.mas_equalTo(24);
            make.width.mas_greaterThanOrEqualTo(28);
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_thumbContainer.mas_right).offset(12);
            make.top.equalTo(_card).offset(20);
            make.right.equalTo(_card).offset(-16);
        }];
        [_subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_titleLabel);
            make.top.equalTo(_titleLabel.mas_bottom).offset(6);
            make.bottom.lessThanOrEqualTo(_metaLabel.mas_top).offset(-8);
        }];
        [_metaLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_titleLabel);
            make.bottom.equalTo(_card).offset(-18);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.thumbView.image = nil;
    self.stackPreviewView.image = nil;
    self.stackPreviewView.alpha = 0.0;
    self.stackCountLabel.hidden = YES;
    self.stackCountLabel.text = @"";
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.card.bounds cornerRadius:22.0].CGPath;
}

- (void)configureWithEntry:(YALTimeLineEntryModel *)entry dayText:(NSString *)dayText weekdayText:(NSString *)weekdayText {
    self.dayNumLabel.text = dayText;
    self.weekdayLabel.text = weekdayText;
    self.titleLabel.text = entry.titleText.length > 0 ? entry.titleText : @"无标题";
    self.subtitleLabel.text = entry.subtitleText.length > 0 ? entry.subtitleText : @"这一天没有填写正文预览";

    NSInteger imageCount = entry.imageURLStrings.count;
    if (entry.image && imageCount == 0) {
        imageCount = 1;
    }
    self.metaLabel.text = imageCount > 0
        ? [NSString stringWithFormat:@"%ld 张照片", (long)imageCount]
        : @"纯文字记忆";

    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"photo"];
    }

    NSString *firstURLStr = (entry.imageURLStrings.count > 0) ? YALTimeLineFullImageURLString(entry.imageURLStrings.firstObject) : nil;
    NSString *secondURLStr = (entry.imageURLStrings.count > 1) ? YALTimeLineFullImageURLString(entry.imageURLStrings[1]) : nil;

    if (firstURLStr.length > 0) {
        NSURL *url = [NSURL URLWithString:firstURLStr];
        self.thumbView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbView.backgroundColor = [UIColor clearColor];
        [self.thumbView sd_setImageWithURL:url
                          placeholderImage:placeholder
                                   options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
    } else if (entry.image) {
        self.thumbView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbView.backgroundColor = [UIColor clearColor];
        self.thumbView.image = entry.image;
    } else {
        self.thumbView.contentMode = UIViewContentModeScaleAspectFit;
        self.thumbView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        self.thumbView.image = placeholder;
        if (@available(iOS 13.0, *)) {
            self.thumbView.tintColor = [UIColor tertiaryLabelColor];
        }
    }

    if (secondURLStr.length > 0) {
        self.stackPreviewView.alpha = 1.0;
        NSURL *url = [NSURL URLWithString:secondURLStr];
        [self.stackPreviewView sd_setImageWithURL:url
                                 placeholderImage:placeholder
                                          options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
    } else {
        self.stackPreviewView.alpha = 0.0;
        self.stackPreviewView.image = nil;
    }

    self.stackCountLabel.hidden = (imageCount <= 1);
    self.stackCountLabel.text = imageCount > 1 ? [NSString stringWithFormat:@"+%ld", (long)(imageCount - 1)] : @"";
}

@end
