//
//  YALTimeLineCardView.m
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "YALTimeLineCardView.h"

@interface YALTimeLineCardView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIView *moreDot;

@end

@implementation YALTimeLineCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemBackgroundColor];
        self.layer.cornerRadius = 14;
        self.layer.masksToBounds = NO;
        self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        self.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06].CGColor;
        self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
        self.layer.shadowOpacity = 1;
        self.layer.shadowOffset = CGSizeMake(0, 6);
        self.layer.shadowRadius = 14;

        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.layer.cornerRadius = 11;
        [self addSubview:_imageView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [UIColor labelColor];
        [self addSubview:_titleLabel];

        _dateLabel = [[UILabel alloc] init];
        _dateLabel.font = [UIFont systemFontOfSize:12];
        _dateLabel.textColor = [UIColor secondaryLabelColor];
        [self addSubview:_dateLabel];

        _moreDot = [[UIView alloc] init];
        _moreDot.backgroundColor = [UIColor tertiaryLabelColor];
        _moreDot.layer.cornerRadius = 3;
        _moreDot.alpha = 0.6;
        [self addSubview:_moreDot];

        [self addTarget:self action:@selector(cardTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

+ (CGFloat)imageHeightForImage:(UIImage *)img fitWidth:(CGFloat)fitWidth {
    if (!img || img.size.width <= 0) return 0;
    CGFloat h = fitWidth * (img.size.height / img.size.width);
    return MIN(h, fitWidth * 1.8);
}

+ (CGFloat)cardHeightForEntry:(YALTimeLineEntryModel *)entry width:(CGFloat)cardWidth {
    UIImage *img = entry.image ?: [UIImage imageNamed:@"WechatIMG395 1.jpg"];
    CGFloat imageH = [self imageHeightForImage:img fitWidth:cardWidth - 20];
    // 10(top) + image + 8(gap) + 20(title) + 4(gap) + 16(date) + 10(bottom)
    return 10 + imageH + 8 + 20 + 4 + 16 + 10;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.bounds.size.width;

    CGFloat imageH = [[self class] imageHeightForImage:_imageView.image fitWidth:w - 20];

    _imageView.frame = CGRectMake(10, 10, w - 20, imageH);

    _titleLabel.frame = CGRectMake(12,
                                  CGRectGetMaxY(_imageView.frame) + 8,
                                  w - 24,
                                  20);

    _dateLabel.frame = CGRectMake(12,
                                 CGRectGetMaxY(_titleLabel.frame) + 4,
                                 w - 24,
                                 16);

    _moreDot.frame = CGRectMake(w - 18, 14, 6, 6);

    self.layer.shadowPath =
        [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:14].CGPath;
}

- (void)setEntry:(YALTimeLineEntryModel *)entry {
    _entry = entry;
    _titleLabel.text = entry.titleText.length > 0 ? entry.titleText : entry.dateText;
    _dateLabel.text = entry.subtitleText.length > 0 ? entry.subtitleText : entry.dateText;
    if (entry.image) {
        _imageView.image = entry.image;
    } else {
        _imageView.image = [UIImage imageNamed:@"WechatIMG395 1.jpg"];
    }
}

- (void)cardTapped {
    if (self.tapAction) {
        self.tapAction(self.entry);
    }
}

@end
