//
//  YALTimeLineCardView.m
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "YALTimeLineCardView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

static NSString *YALCardAbsoluteURLString(NSString *raw) {
    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) {
        return nil;
    }
    if ([raw hasPrefix:@"http://"] || [raw hasPrefix:@"https://"]) {
        return raw;
    }
    return [NSString stringWithFormat:@"http://%@", raw];
}

@interface YALTimeLineCardView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *stackImageView;
@property (nonatomic, strong) UILabel *countBadgeLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) MASConstraint *imageHeightConstraint;

@end

@implementation YALTimeLineCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:1.0 green:0.995 blue:0.985 alpha:1.0];
        self.layer.cornerRadius = 18.0;
        self.layer.masksToBounds = NO;
        self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        self.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.05].CGColor;
        self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowOffset = CGSizeMake(0, 10);
        self.layer.shadowRadius = 18.0;

        _stackImageView = [[UIImageView alloc] init];
        _stackImageView.contentMode = UIViewContentModeScaleAspectFill;
        _stackImageView.clipsToBounds = YES;
        _stackImageView.layer.cornerRadius = 13.0;
        _stackImageView.layer.borderWidth = 2.0;
        _stackImageView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.75].CGColor;
        _stackImageView.alpha = 0.0;
        [self addSubview:_stackImageView];

        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.layer.cornerRadius = 15.0;
        [self addSubview:_imageView];

        _countBadgeLabel = [[UILabel alloc] init];
        _countBadgeLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
        _countBadgeLabel.textColor = [UIColor whiteColor];
        _countBadgeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        _countBadgeLabel.textAlignment = NSTextAlignmentCenter;
        _countBadgeLabel.layer.cornerRadius = 12.0;
        _countBadgeLabel.layer.masksToBounds = YES;
        _countBadgeLabel.hidden = YES;
        [self addSubview:_countBadgeLabel];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [UIColor labelColor];
        _titleLabel.numberOfLines = 2;
        [self addSubview:_titleLabel];

        _dateLabel = [[UILabel alloc] init];
        _dateLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        _dateLabel.textColor = [UIColor colorWithRed:0.65 green:0.42 blue:0.18 alpha:1.0];
        [self addSubview:_dateLabel];

        _summaryLabel = [[UILabel alloc] init];
        _summaryLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        _summaryLabel.textColor = [UIColor secondaryLabelColor];
        _summaryLabel.numberOfLines = 2;
        [self addSubview:_summaryLabel];

        [self addTarget:self action:@selector(cardTapped) forControlEvents:UIControlEventTouchUpInside];

        [_stackImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(18);
            make.left.equalTo(self).offset(18);
            make.right.equalTo(self).offset(-18);
            make.height.mas_equalTo(138);
        }];
        [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(10);
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self).offset(-10);
            self.imageHeightConstraint = make.height.mas_equalTo(146);
        }];
        [_countBadgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_imageView).offset(-10);
            make.bottom.equalTo(_imageView).offset(-10);
            make.height.mas_equalTo(24);
            make.width.mas_greaterThanOrEqualTo(30);
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_imageView.mas_bottom).offset(10);
            make.left.equalTo(self).offset(14);
            make.right.equalTo(self).offset(-14);
        }];
        [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_titleLabel.mas_bottom).offset(6);
            make.left.right.equalTo(_titleLabel);
        }];
        [_summaryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_dateLabel.mas_bottom).offset(6);
            make.left.right.equalTo(_titleLabel);
        }];
    }
    return self;
}

+ (CGFloat)imageHeightForImage:(UIImage *)img fitWidth:(CGFloat)fitWidth {
    if (!img || img.size.width <= 0) return 146.0;
    CGFloat h = fitWidth * (img.size.height / img.size.width);
    return MIN(MAX(h, 132.0), fitWidth * 1.25);
}

+ (CGFloat)cardHeightForEntry:(YALTimeLineEntryModel *)entry width:(CGFloat)cardWidth {
    CGFloat imageH = 146.0;
    if (entry.image) {
        imageH = [self imageHeightForImage:entry.image fitWidth:cardWidth - 20];
    }
    CGFloat summaryH = entry.subtitleText.length > 0 ? 38.0 : 0.0;
    return 10 + imageH + 10 + 42 + 6 + 16 + summaryH + 14;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:18.0].CGPath;
}

- (void)setEntry:(YALTimeLineEntryModel *)entry {
    _entry = entry;
    self.titleLabel.text = entry.titleText.length > 0 ? entry.titleText : entry.dateText;
    self.dateLabel.text = entry.dateText ?: @"";
    self.summaryLabel.text = entry.subtitleText ?: @"";

    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"photo"];
    }

    NSString *firstURLStr = entry.imageURLStrings.count > 0 ? YALCardAbsoluteURLString(entry.imageURLStrings.firstObject) : nil;
    NSString *secondURLStr = entry.imageURLStrings.count > 1 ? YALCardAbsoluteURLString(entry.imageURLStrings[1]) : nil;
    if (secondURLStr.length > 0) {
        self.stackImageView.alpha = 1.0;
        [self.stackImageView sd_setImageWithURL:[NSURL URLWithString:secondURLStr]
                               placeholderImage:placeholder
                                        options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
    } else {
        self.stackImageView.alpha = 0.0;
        self.stackImageView.image = nil;
    }

    if (firstURLStr.length > 0) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.backgroundColor = [UIColor clearColor];
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:firstURLStr]
                          placeholderImage:placeholder
                                   options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
    } else if (entry.image) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.image = entry.image;
    } else {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        self.imageView.image = placeholder;
        if (@available(iOS 13.0, *)) {
            self.imageView.tintColor = [UIColor tertiaryLabelColor];
        }
    }

    NSInteger imageCount = entry.imageURLStrings.count;
    if (entry.image && imageCount == 0) {
        imageCount = 1;
    }
    self.countBadgeLabel.hidden = (imageCount <= 1);
    self.countBadgeLabel.text = imageCount > 1 ? [NSString stringWithFormat:@"+%ld", (long)(imageCount - 1)] : @"";

    CGFloat imgH = entry.image ? [[self class] imageHeightForImage:entry.image fitWidth:self.bounds.size.width - 20] : 146.0;
    [self.imageHeightConstraint uninstall];
    [self.imageView mas_updateConstraints:^(MASConstraintMaker *make) {
        self.imageHeightConstraint = make.height.mas_equalTo(imgH);
    }];
}

- (void)cardTapped {
    if (self.tapAction) {
        self.tapAction(self.entry);
    }
}

@end
