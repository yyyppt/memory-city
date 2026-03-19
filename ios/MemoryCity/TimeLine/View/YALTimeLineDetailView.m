//
//  YALTimeLineDetailView.m
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "YALTimeLineDetailView.h"

@interface YALTimeLineDetailView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *bodyLabel;

@property (nonatomic, strong) UIView *actionBar;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UILabel *likeCountLabel;

@end

@implementation YALTimeLineDetailView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    if (@available(iOS 13.0, *)) {
      self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
        if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) { return [UIColor systemBackgroundColor]; }
        return [UIColor colorWithRed:252/255.0 green:251/255.0 blue:248/255.0 alpha:1.0];
      }];
    } else {
      self.backgroundColor = [UIColor colorWithRed:252/255.0 green:251/255.0 blue:248/255.0 alpha:1.0];
    }

    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_scrollView];

    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), 1)];
    _contentView.backgroundColor = [UIColor clearColor];
    [_scrollView addSubview:_contentView];

    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 18.0;
    card.layer.masksToBounds = NO;
    card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.10].CGColor;
    card.layer.shadowOpacity = 1.0;
    card.layer.shadowOffset = CGSizeMake(0, 10);
    card.layer.shadowRadius = 18.0;
    [_contentView addSubview:card];

    _coverImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    _coverImageView.layer.cornerRadius = 14.0;
    _coverImageView.layer.masksToBounds = YES;
    [card addSubview:_coverImageView];

    _dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _dateLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _dateLabel.textColor = [UIColor secondaryLabelColor];
    [card addSubview:_dateLabel];

    _bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _bodyLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    _bodyLabel.textColor = [UIColor labelColor];
    _bodyLabel.numberOfLines = 0;
    [card addSubview:_bodyLabel];

    _actionBar = [[UIView alloc] initWithFrame:CGRectZero];
    _actionBar.backgroundColor = [UIColor clearColor];
    [card addSubview:_actionBar];

    UIColor *accent = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];

    _likeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _likeButton.tintColor = accent;
    _likeButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    if (@available(iOS 13.0, *)) {
      [_likeButton setImage:[UIImage systemImageNamed:@"heart"] forState:UIControlStateNormal];
    }
    [_likeButton setTitle:@"  赞" forState:UIControlStateNormal];
    [_actionBar addSubview:_likeButton];

    _likeCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
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

    // store card via tag to layout later
    card.tag = 9001;
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat width = CGRectGetWidth(self.bounds);
  CGFloat side = 16.0;
  CGFloat y = 14.0;

  UIView *card = [self.contentView viewWithTag:9001];
  CGFloat cardW = width - side * 2;
  CGFloat cardX = side;

  CGFloat inner = 14.0;

  CGFloat imageH = 200.0;
  UIImage *img = self.coverImageView.image;
  if (img && img.size.width > 0) {
      imageH = (cardW - inner * 2) * (img.size.height / img.size.width);
      imageH = MIN(imageH, width * 1.2);
  }

  self.coverImageView.frame = CGRectMake(inner, inner, cardW - inner * 2, imageH);

  self.dateLabel.frame = CGRectMake(inner, CGRectGetMaxY(self.coverImageView.frame) + 10.0, cardW - inner * 2, 18.0);

  CGSize bodySize = [self.bodyLabel sizeThatFits:CGSizeMake(cardW - inner * 2, CGFLOAT_MAX)];
  self.bodyLabel.frame = CGRectMake(inner,
                                    CGRectGetMaxY(self.dateLabel.frame) + 10.0,
                                    cardW - inner * 2,
                                    bodySize.height);

  CGFloat barY = CGRectGetMaxY(self.bodyLabel.frame) + 14.0;
  CGFloat barH = 44.0;
  self.actionBar.frame = CGRectMake(inner, barY, cardW - inner * 2, barH);

  CGFloat buttonW = 88.0;
  self.likeButton.frame = CGRectMake(0, 0, buttonW, barH);
  self.likeCountLabel.frame = CGRectMake(CGRectGetMaxX(self.likeButton.frame) + 6.0, 0, 60.0, barH);
  self.commentButton.frame = CGRectMake(CGRectGetWidth(self.actionBar.bounds) - buttonW, 0, buttonW, barH);

  CGFloat cardH = CGRectGetMaxY(self.actionBar.frame) + inner;
  card.frame = CGRectMake(cardX, y, cardW, cardH);
  card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:card.bounds cornerRadius:18.0].CGPath;

  CGFloat contentH = CGRectGetMaxY(card.frame) + 18.0;
  self.contentView.frame = CGRectMake(0, 0, width, contentH);
  self.scrollView.contentSize = CGSizeMake(width, contentH);
}

- (void)configureWithDateText:(NSString *)dateText
                        image:(UIImage *)image
                         body:(NSString *)body
                    likeCount:(NSInteger)likeCount {
  self.dateLabel.text = dateText ?: @"";
  self.bodyLabel.text = body ?: @"";

  if (image) {
    self.coverImageView.image = image;
    self.coverImageView.backgroundColor = [UIColor clearColor];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
  } else {
    if (@available(iOS 13.0, *)) {
      self.coverImageView.image = [UIImage systemImageNamed:@"photo"];
      self.coverImageView.tintColor = [UIColor tertiaryLabelColor];
      self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
      self.coverImageView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    } else {
      self.coverImageView.image = nil;
      self.coverImageView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    }
  }

  self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(0, likeCount)];

  [self setNeedsLayout];
}

@end

