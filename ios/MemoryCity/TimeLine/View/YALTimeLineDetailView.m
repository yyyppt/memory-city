//
//  YALTimeLineDetailView.m
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "YALTimeLineDetailView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

static NSString * const kYALDetailImageCellIdentifier = @"YALDetailImageCell";

static NSString *YALAbsoluteImageURLString(NSString *raw) {
    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) {
        return nil;
    }
    if ([raw hasPrefix:@"http://"] || [raw hasPrefix:@"https://"]) {
        return raw;
    }
    return [NSString stringWithFormat:@"http://%@", raw];
}

@interface YALDetailImageCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *countBadgeLabel;

- (void)configureWithURLString:(nullable NSString *)urlString placeholderText:(nullable NSString *)placeholderText;

@end

@implementation YALDetailImageCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];

        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.layer.cornerRadius = 18.0;
        _imageView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        [self.contentView addSubview:_imageView];

        _countBadgeLabel = [[UILabel alloc] init];
        _countBadgeLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
        _countBadgeLabel.textColor = [UIColor whiteColor];
        _countBadgeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        _countBadgeLabel.textAlignment = NSTextAlignmentCenter;
        _countBadgeLabel.layer.cornerRadius = 12.0;
        _countBadgeLabel.layer.masksToBounds = YES;
        _countBadgeLabel.hidden = YES;
        [self.contentView addSubview:_countBadgeLabel];

        [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        [_countBadgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(12);
            make.right.equalTo(self.contentView).offset(-12);
            make.height.mas_equalTo(24);
            make.width.mas_greaterThanOrEqualTo(42);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    self.imageView.tintColor = nil;
    self.countBadgeLabel.hidden = YES;
    self.countBadgeLabel.text = @"";
}

- (void)configureWithURLString:(nullable NSString *)urlString placeholderText:(nullable NSString *)placeholderText {
    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"photo.on.rectangle.angled"];
    }

    NSString *fullURLString = YALAbsoluteImageURLString(urlString);
    NSURL *url = fullURLString.length > 0 ? [NSURL URLWithString:fullURLString] : nil;
    if (url) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.backgroundColor = [UIColor clearColor];
        [self.imageView sd_setImageWithURL:url
                          placeholderImage:placeholder
                                   options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
    } else {
        self.imageView.image = placeholder;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        if (@available(iOS 13.0, *)) {
            self.imageView.tintColor = [UIColor tertiaryLabelColor];
        }
    }

    self.countBadgeLabel.hidden = (placeholderText.length == 0);
    self.countBadgeLabel.text = placeholderText ?: @"";
}

@end

@interface YALTimeLineDetailView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIView *heroPanel;
@property (nonatomic, strong) UILabel *memoryTagLabel;
@property (nonatomic, strong) UICollectionView *imageCollectionView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UILabel *imageMetaLabel;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *bodyLabel;

@property (nonatomic, strong) UIView *actionBar;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UILabel *likeCountLabel;

@property (nonatomic, strong) NSArray<NSString *> *displayImageURLs;
@property (nonatomic, strong) MASConstraint *imageCollectionHeightConstraint;

@end

@implementation YALTimeLineDetailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemGroupedBackgroundColor];
        self.displayImageURLs = @[];
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
    _card.backgroundColor = [UIColor colorWithRed:0.995 green:0.985 blue:0.965 alpha:1.0];
    _card.layer.cornerRadius = 28.0;
    _card.layer.masksToBounds = NO;
    _card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    _card.layer.shadowOpacity = 1.0;
    _card.layer.shadowOffset = CGSizeMake(0, 16);
    _card.layer.shadowRadius = 26.0;
    [_contentView addSubview:_card];

    _heroPanel = [[UIView alloc] init];
    _heroPanel.backgroundColor = [UIColor colorWithRed:0.17 green:0.19 blue:0.24 alpha:1.0];
    _heroPanel.layer.cornerRadius = 22.0;
    _heroPanel.layer.masksToBounds = YES;
    [_card addSubview:_heroPanel];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.20 green:0.23 blue:0.30 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.34 green:0.29 blue:0.23 alpha:1.0].CGColor
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    [_heroPanel.layer insertSublayer:gradient atIndex:0];

    _memoryTagLabel = [[UILabel alloc] init];
    _memoryTagLabel.text = @"MEMORY DETAIL";
    _memoryTagLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    _memoryTagLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
    _memoryTagLabel.textAlignment = NSTextAlignmentCenter;
    _memoryTagLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    _memoryTagLabel.layer.cornerRadius = 12.0;
    _memoryTagLabel.layer.masksToBounds = YES;
    [_heroPanel addSubview:_memoryTagLabel];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 12.0;
    layout.minimumInteritemSpacing = 0.0;

    _imageCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _imageCollectionView.backgroundColor = [UIColor clearColor];
    _imageCollectionView.pagingEnabled = YES;
    _imageCollectionView.showsHorizontalScrollIndicator = NO;
    _imageCollectionView.dataSource = self;
    _imageCollectionView.delegate = self;
    [_imageCollectionView registerClass:[YALDetailImageCell class] forCellWithReuseIdentifier:kYALDetailImageCellIdentifier];
    [_heroPanel addSubview:_imageCollectionView];

    _pageControl = [[UIPageControl alloc] init];
    _pageControl.hidesForSinglePage = YES;
    _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    _pageControl.pageIndicatorTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25];
    [_heroPanel addSubview:_pageControl];

    _imageMetaLabel = [[UILabel alloc] init];
    _imageMetaLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    _imageMetaLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
    _imageMetaLabel.textAlignment = NSTextAlignmentRight;
    [_heroPanel addSubview:_imageMetaLabel];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.numberOfLines = 0;
    [_card addSubview:_titleLabel];

    _dateLabel = [[UILabel alloc] init];
    _dateLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _dateLabel.textColor = [UIColor colorWithRed:0.64 green:0.40 blue:0.16 alpha:1.0];
    [_card addSubview:_dateLabel];

    _bodyLabel = [[UILabel alloc] init];
    _bodyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    _bodyLabel.textColor = [UIColor labelColor];
    _bodyLabel.numberOfLines = 0;
    [_card addSubview:_bodyLabel];

    _actionBar = [[UIView alloc] init];
    _actionBar.backgroundColor = [UIColor colorWithWhite:1 alpha:0.78];
    _actionBar.layer.cornerRadius = 18.0;
    [_card addSubview:_actionBar];

    UIColor *accent = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];

    _likeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _likeButton.tintColor = accent;
    _likeButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    if (@available(iOS 13.0, *)) {
        [_likeButton setImage:[UIImage systemImageNamed:@"heart"] forState:UIControlStateNormal];
    }
    [_likeButton setTitle:@"  喜欢" forState:UIControlStateNormal];
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

    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_scrollView);
        make.width.equalTo(_scrollView);
    }];
    [_card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_contentView.mas_top).offset(16);
        make.left.equalTo(_contentView.mas_left).offset(16);
        make.right.equalTo(_contentView.mas_right).offset(-16);
        make.bottom.equalTo(_contentView.mas_bottom).offset(-24);
    }];
    [_heroPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_card.mas_top).offset(16);
        make.left.equalTo(_card.mas_left).offset(16);
        make.right.equalTo(_card.mas_right).offset(-16);
    }];
    [_memoryTagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_heroPanel).offset(14);
        make.left.equalTo(_heroPanel).offset(14);
        make.height.mas_equalTo(24);
        make.width.mas_equalTo(110);
    }];
    [_imageCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_memoryTagLabel.mas_bottom).offset(14);
        make.left.equalTo(_heroPanel).offset(14);
        make.right.equalTo(_heroPanel).offset(-14);
        self.imageCollectionHeightConstraint = make.height.mas_equalTo(256);
    }];
    [_pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_imageCollectionView.mas_bottom).offset(10);
        make.centerX.equalTo(_heroPanel);
        make.height.mas_equalTo(18);
    }];
    [_imageMetaLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_heroPanel).offset(-16);
        make.centerY.equalTo(_pageControl);
        make.left.greaterThanOrEqualTo(_pageControl.mas_right).offset(8);
    }];
    [_heroPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_pageControl.mas_bottom).offset(16);
    }];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_heroPanel.mas_bottom).offset(18);
        make.left.equalTo(_heroPanel);
        make.right.equalTo(_heroPanel);
    }];
    [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(_heroPanel);
    }];
    [_bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_dateLabel.mas_bottom).offset(14);
        make.left.right.equalTo(_heroPanel);
    }];
    [_actionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_bodyLabel.mas_bottom).offset(18);
        make.left.right.equalTo(_heroPanel);
        make.height.mas_equalTo(50);
        make.bottom.equalTo(_card.mas_bottom).offset(-16);
    }];
    [_likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_actionBar).offset(14);
        make.top.bottom.equalTo(_actionBar);
        make.width.mas_equalTo(92);
    }];
    [_likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_likeButton.mas_right).offset(4);
        make.centerY.equalTo(_actionBar);
    }];
    [_commentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_actionBar).offset(-14);
        make.top.bottom.equalTo(_actionBar);
        make.width.mas_equalTo(92);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.card.bounds cornerRadius:28.0].CGPath;
    self.heroPanel.layer.sublayers.firstObject.frame = self.heroPanel.bounds;
}

- (void)configureWithTitle:(NSString *)title
                  dateText:(NSString *)dateText
                 imageURLs:(NSArray<NSString *> *)imageURLs
                      body:(NSString *)body
                 likeCount:(NSInteger)likeCount {
    self.titleLabel.text = title.length > 0 ? title : @"";
    self.dateLabel.text = dateText ?: @"";
    self.bodyLabel.text = body ?: @"";
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(0, likeCount)];

    self.displayImageURLs = [imageURLs isKindOfClass:[NSArray class]] ? imageURLs : @[];
    self.pageControl.numberOfPages = MAX(self.displayImageURLs.count, 1);
    self.pageControl.currentPage = 0;
    self.imageMetaLabel.text = self.displayImageURLs.count > 0
        ? [NSString stringWithFormat:@"%lu 张照片", (unsigned long)self.displayImageURLs.count]
        : @"无图片";

    CGFloat width = CGRectGetWidth(self.bounds);
    if (width <= 0) {
        width = CGRectGetWidth([UIScreen mainScreen].bounds);
    }
    CGFloat heroHeight = width > 390 ? 290.0 : 248.0;
    [self.imageCollectionHeightConstraint uninstall];
    [self.imageCollectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        self.imageCollectionHeightConstraint = make.height.mas_equalTo(heroHeight);
    }];

    [self.imageCollectionView setContentOffset:CGPointZero animated:NO];
    [self.imageCollectionView reloadData];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    (void)collectionView;
    (void)section;
    return MAX(self.displayImageURLs.count, 1);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YALDetailImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kYALDetailImageCellIdentifier forIndexPath:indexPath];
    NSString *urlString = (indexPath.item < (NSInteger)self.displayImageURLs.count) ? self.displayImageURLs[indexPath.item] : nil;
    NSString *badgeText = nil;
    if (self.displayImageURLs.count > 1 && indexPath.item == 0) {
        badgeText = [NSString stringWithFormat:@"1 / %lu", (unsigned long)self.displayImageURLs.count];
    }
    [cell configureWithURLString:urlString placeholderText:badgeText];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    (void)collectionViewLayout;
    CGFloat width = CGRectGetWidth(collectionView.bounds);
    CGFloat height = CGRectGetHeight(collectionView.bounds);
    return CGSizeMake(MAX(0, width), MAX(0, height));
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.imageCollectionView) {
        return;
    }
    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0) {
        return;
    }
    NSInteger page = (NSInteger)lround(scrollView.contentOffset.x / width);
    self.pageControl.currentPage = MAX(0, MIN(page, self.pageControl.numberOfPages - 1));

    NSArray<YALDetailImageCell *> *visibleCells = [self.imageCollectionView visibleCells];
    for (YALDetailImageCell *cell in visibleCells) {
        NSIndexPath *indexPath = [self.imageCollectionView indexPathForCell:cell];
        if (!indexPath) {
            continue;
        }
        NSString *badgeText = nil;
        if (self.displayImageURLs.count > 1) {
            badgeText = [NSString stringWithFormat:@"%ld / %lu", (long)indexPath.item + 1, (unsigned long)self.displayImageURLs.count];
        }
        cell.countBadgeLabel.hidden = (badgeText.length == 0);
        cell.countBadgeLabel.text = badgeText ?: @"";
    }
}

@end
