//
//  YALTimeLineDetailView.m
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "YALTimeLineDetailView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface YALTimeLineDetailView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *card;

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *bodyLabel;

@property (nonatomic, strong) UIView *actionBar;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UILabel *likeCountLabel;

@property (nonatomic, strong) MASConstraint *coverImageHeightConstraint;

@end

@implementation YALTimeLineDetailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemGroupedBackgroundColor];
        [self buildUI];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)buildUI {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:_scrollView];

    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];
    [_scrollView addSubview:_contentView];

    _card = [[UIView alloc] init];
    _card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    _card.layer.cornerRadius = 18.0;
    _card.layer.masksToBounds = NO;
    _card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.10].CGColor;
    _card.layer.shadowOpacity = 1.0;
    _card.layer.shadowOffset = CGSizeMake(0, 10);
    _card.layer.shadowRadius = 18.0;
    [_contentView addSubview:_card];

    _coverImageView = [[UIImageView alloc] init];
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    _coverImageView.layer.cornerRadius = 14.0;
    _coverImageView.layer.masksToBounds = YES;
    [_card addSubview:_coverImageView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.numberOfLines = 0;
    [_card addSubview:_titleLabel];

    _dateLabel = [[UILabel alloc] init];
    _dateLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _dateLabel.textColor = [UIColor secondaryLabelColor];
    [_card addSubview:_dateLabel];

    _bodyLabel = [[UILabel alloc] init];
    _bodyLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    _bodyLabel.textColor = [UIColor labelColor];
    _bodyLabel.numberOfLines = 0;
    [_card addSubview:_bodyLabel];

    _actionBar = [[UIView alloc] init];
    _actionBar.backgroundColor = [UIColor clearColor];
    [_card addSubview:_actionBar];

    UIColor *accent = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];

    _likeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _likeButton.tintColor = accent;
    _likeButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    if (@available(iOS 13.0, *)) {
        [_likeButton setImage:[UIImage systemImageNamed:@"heart"] forState:UIControlStateNormal];
    }
    [_likeButton setTitle:@"  赞" forState:UIControlStateNormal];
    [_actionBar addSubview:_likeButton];

    _likeCountLabel = [[UILabel alloc] init];
    _likeCountLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _likeCountLabel.textColor = [UIColor secondaryLabelColor];
    [_actionBar addSubview:_likeCountLabel];

    _commentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _commentButton.tintColor = accent;
    _commentButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    if (@available(iOS 13.0, *)) {
        [_commentButton setImage:[UIImage systemImageNamed:@"bubble.left"] forState:UIControlStateNormal];
    }
    [_commentButton setTitle:@"  评论" forState:UIControlStateNormal];
    [_actionBar addSubview:_commentButton];

    // Masonry 约束
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_scrollView);
        make.width.equalTo(_scrollView);
    }];

    [_card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_contentView.mas_top).offset(14);
        make.left.equalTo(_contentView.mas_left).offset(16);
        make.right.equalTo(_contentView.mas_right).offset(-16);
        make.bottom.equalTo(_contentView.mas_bottom).offset(-18);
    }];

    [_coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_card.mas_top).offset(14);
        make.left.equalTo(_card.mas_left).offset(14);
        make.right.equalTo(_card.mas_right).offset(-14);
        self.coverImageHeightConstraint = make.height.mas_equalTo(200);
    }];

    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_coverImageView.mas_bottom).offset(10);
        make.left.right.equalTo(_coverImageView);
        make.height.mas_greaterThanOrEqualTo(18);
    }];

    [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_titleLabel.mas_bottom).offset(6);
        make.left.right.equalTo(_coverImageView);
        make.height.mas_equalTo(18);
    }];

    [_bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_dateLabel.mas_bottom).offset(10);
        make.left.right.equalTo(_coverImageView);
    }];

    [_actionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_bodyLabel.mas_bottom).offset(14);
        make.left.right.equalTo(_coverImageView);
        make.height.mas_equalTo(44);
        make.bottom.equalTo(_card.mas_bottom).offset(-14);
    }];

    [_likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(_actionBar);
        make.width.mas_equalTo(88);
    }];

    [_likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_likeButton.mas_right).offset(6);
        make.centerY.equalTo(_actionBar);
        make.width.mas_equalTo(60);
    }];

    [_commentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.equalTo(_actionBar);
        make.width.mas_equalTo(88);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.card.bounds cornerRadius:18.0].CGPath;
}

- (void)configureWithTitle:(NSString *)title
                   dateText:(NSString *)dateText
                     imageURL:(NSString *)imageURL
                        body:(NSString *)body
                   likeCount:(NSInteger)likeCount {
    self.titleLabel.text = (title.length > 0) ? title : @"";
    self.dateLabel.text = dateText ?: @"";
    self.bodyLabel.text = body ?: @"";

    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"photo"];
    }

    NSString *urlStr = (imageURL.length > 0) ? imageURL : nil;
    if (urlStr && ![urlStr hasPrefix:@"http://"] && ![urlStr hasPrefix:@"https://"]) {
        urlStr = [NSString stringWithFormat:@"http://%@", urlStr];
    }
    NSURL *url = (urlStr.length > 0) ? [NSURL URLWithString:urlStr] : nil;

    if (url) {
        self.coverImageView.backgroundColor = [UIColor clearColor];
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        // 使用 SDWebImage 异步加载
        [self.coverImageView sd_setImageWithURL:url
                               placeholderImage:placeholder
                                        options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
    } else {
        if (@available(iOS 13.0, *)) {
            self.coverImageView.image = placeholder;
            self.coverImageView.tintColor = [UIColor tertiaryLabelColor];
            self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.coverImageView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        } else {
            self.coverImageView.image = nil;
            self.coverImageView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        }
    }

    // 根据图片更新封面高度约束
    // URL 图片加载后尺寸不易实时获知：保持 200 的布局稳定性
    CGFloat imageH = 200.0;
    [self.coverImageHeightConstraint uninstall];
    [self.coverImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        self.coverImageHeightConstraint = make.height.mas_equalTo(imageH);
    }];

    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(0, likeCount)];

    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
