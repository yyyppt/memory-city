//
//  YALTimeLineCardView.m
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "YALTimeLineCardView.h"
#import <Masonry/Masonry.h>

@interface YALTimeLineCardView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIView *moreDot;
@property (nonatomic, strong) MASConstraint *imageHeightConstraint;

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

        // Masonry 约束
        [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_top).offset(10);
            make.left.equalTo(self.mas_left).offset(10);
            make.right.equalTo(self.mas_right).offset(-10);
            self.imageHeightConstraint = make.height.mas_equalTo(0);
        }];

        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_imageView.mas_bottom).offset(8);
            make.left.equalTo(self.mas_left).offset(12);
            make.right.equalTo(self.mas_right).offset(-24);
            make.height.mas_equalTo(20);
        }];

        [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_titleLabel.mas_bottom).offset(4);
            make.left.right.equalTo(_titleLabel);
            make.height.mas_equalTo(16);
        }];

        [_moreDot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.mas_right).offset(-12);
            make.top.equalTo(self.mas_top).offset(14);
            make.width.height.mas_equalTo(6);
        }];
    }
    return self;
}

+ (CGFloat)imageHeightForImage:(UIImage *)img fitWidth:(CGFloat)fitWidth {
    if (!img || img.size.width <= 0) return 0;
    CGFloat h = fitWidth * (img.size.height / img.size.width);
    return MIN(h, fitWidth * 1.8);
}

+ (CGFloat)cardHeightForEntry:(YALTimeLineEntryModel *)entry width:(CGFloat)cardWidth {
    UIImage *img = entry.image;
    CGFloat imageH = [self imageHeightForImage:img fitWidth:cardWidth - 20];
    return 10 + imageH + 8 + 20 + 4 + 16 + 10;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:14].CGPath;
}

- (void)setEntry:(YALTimeLineEntryModel *)entry {
    _entry = entry;
    _titleLabel.text = entry.titleText.length > 0 ? entry.titleText : entry.dateText;
    _dateLabel.text = entry.subtitleText.length > 0 ? entry.subtitleText : entry.dateText;

    UIImage *img = entry.image;
    if (img) {
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.image = img;
    } else {
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        if (@available(iOS 13.0, *)) {
            _imageView.image = [UIImage systemImageNamed:@"photo"];
            _imageView.tintColor = [UIColor tertiaryLabelColor];
        } else {
            _imageView.image = nil;
        }
    }

    // 根据图片更新高度约束
    CGFloat imgH = [[self class] imageHeightForImage:img fitWidth:self.bounds.size.width - 20];
    [self.imageHeightConstraint uninstall];
    [_imageView mas_updateConstraints:^(MASConstraintMaker *make) {
        // 没有图片就不占高度（更符合“无内容用默认图”的紧凑显示）
        self.imageHeightConstraint = make.height.mas_equalTo(imgH);
    }];
}

- (void)cardTapped {
    if (self.tapAction) {
        self.tapAction(self.entry);
    }
}

@end
