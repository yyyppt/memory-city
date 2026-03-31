#import "YALTimeLineDayCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

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

        // Masonry 约束
        [_dayNumLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView.mas_left).offset(16);
            make.top.equalTo(self.contentView.mas_top).offset(8);
            make.width.mas_equalTo(44);
            make.height.mas_equalTo(34);
        }];

        [_weekdayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.width.equalTo(_dayNumLabel);
            make.top.equalTo(_dayNumLabel.mas_bottom).offset(-2);
            make.height.mas_equalTo(16);
        }];

        [_card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_dayNumLabel.mas_right).offset(8);
            make.top.equalTo(self.contentView.mas_top).offset(6);
            make.right.equalTo(self.contentView.mas_right).offset(-16);
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-6);
        }];

        [_thumbView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_card.mas_left).offset(12);
            make.top.equalTo(_card.mas_top).offset(12);
            make.width.height.mas_equalTo(72);
        }];

        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_thumbView.mas_right).offset(12);
            make.top.equalTo(_card.mas_top).offset(14);
            make.right.equalTo(_card.mas_right).offset(-12);
            make.height.mas_equalTo(40);
        }];

        [_subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_titleLabel);
            make.top.equalTo(_titleLabel.mas_bottom).offset(4);
            make.height.mas_equalTo(36);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.card.bounds cornerRadius:16].CGPath;
}

- (void)configureWithEntry:(YALTimeLineEntryModel *)entry dayText:(NSString *)dayText weekdayText:(NSString *)weekdayText {
    self.dayNumLabel.text = dayText;
    self.weekdayLabel.text = weekdayText;
    self.titleLabel.text = entry.titleText ?: @"";
    self.subtitleLabel.text = entry.subtitleText ?: @"";

    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"photo"];
    }

    NSString *firstURLStr = (entry.imageURLStrings.count > 0) ? entry.imageURLStrings.firstObject : nil;
    if (firstURLStr.length > 0) {
        // 兼容后端返回无协议域名/路径
        if (![firstURLStr hasPrefix:@"http://"] && ![firstURLStr hasPrefix:@"https://"]) {
            firstURLStr = [NSString stringWithFormat:@"http://%@", firstURLStr];
        }
        NSURL *url = [NSURL URLWithString:firstURLStr];
        self.thumbView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbView.backgroundColor = [UIColor clearColor];
        [self.thumbView sd_setImageWithURL:url
                             placeholderImage:placeholder
                                      options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
        if (@available(iOS 13.0, *)) {
            self.thumbView.tintColor = [UIColor tertiaryLabelColor];
        }
        return;
    }

    if (entry.image) {
        self.thumbView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbView.backgroundColor = [UIColor clearColor];
        self.thumbView.image = entry.image;
        return;
    }

    // 没有图片数据：显示默认占位
    self.thumbView.contentMode = UIViewContentModeScaleAspectFit;
    self.thumbView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    self.thumbView.image = placeholder;
    if (@available(iOS 13.0, *)) {
        self.thumbView.tintColor = [UIColor tertiaryLabelColor];
    }
}

@end
