#import "YALMemoryView.h"
#import "YALMemoryMonthCell.h"

@interface YALMemoryView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *yearLabel;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation YALMemoryView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if (@available(iOS 13.0, *)) {
            self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
                if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    return [UIColor systemBackgroundColor];
                }
                return [UIColor colorWithRed:252/255.0 green:251/255.0 blue:248/255.0 alpha:1.0];
            }];
        } else {
            self.backgroundColor = [UIColor whiteColor];
        }

        _header = [[UIView alloc] initWithFrame:CGRectZero];
        _header.backgroundColor = [UIColor clearColor];
        [self addSubview:_header];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.text = @"";

        _yearLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _yearLabel.font = [UIFont systemFontOfSize:52 weight:UIFontWeightHeavy];
        _yearLabel.textColor = [UIColor labelColor];
        _yearLabel.textAlignment = NSTextAlignmentCenter;
        _yearLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(yearTapped)];
        [_yearLabel addGestureRecognizer:tap];
        [_header addSubview:_yearLabel];

        _prevButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _prevButton.tintColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
        if (@available(iOS 13.0, *)) {
            [_prevButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
        }
        [_prevButton addTarget:self action:@selector(prevTapped) forControlEvents:UIControlEventTouchUpInside];
        [_header addSubview:_prevButton];

        _nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _nextButton.tintColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
        if (@available(iOS 13.0, *)) {
            [_nextButton setImage:[UIImage systemImageNamed:@"chevron.right"] forState:UIControlStateNormal];
        }
        [_nextButton addTarget:self action:@selector(nextTapped) forControlEvents:UIControlEventTouchUpInside];
        [_header addSubview:_nextButton];

        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 16;
        layout.sectionInset = UIEdgeInsetsMake(10, 16, 24, 16);

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[YALMemoryMonthCell class] forCellWithReuseIdentifier:@"YALMemoryMonthCell"];
        [self addSubview:_collectionView];
    }
    return self;
}

- (void)setYear:(NSInteger)year {
    _year = year;
    self.yearLabel.text = [NSString stringWithFormat:@"%ld", (long)year];
}

- (void)setMonths:(NSArray<YALMemoryMonthModel *> *)months {
    _months = months ?: @[];
    [self.collectionView reloadData];
}

- (void)reload {
    self.yearLabel.text = [NSString stringWithFormat:@"%ld", (long)self.year];
    [self.collectionView reloadData];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.bounds.size.width;
    CGFloat top = 10;
    if (@available(iOS 11.0, *)) top += self.safeAreaInsets.top;

    self.header.frame = CGRectMake(0, top, w, 120);

    // year centered, arrows next to it (left/right)
    self.yearLabel.frame = CGRectMake(16, 38, w - 32, 62);
    CGSize yearFit = [self.yearLabel sizeThatFits:CGSizeMake(w - 32, 62)];
    CGFloat yearW = MIN(yearFit.width, w - 32);
    CGFloat yearX = (w - yearW) / 2.0;
    self.yearLabel.frame = CGRectMake(yearX, 38, yearW, 62);

    CGFloat btn = 40;
    CGFloat gap = 8;
    self.prevButton.frame = CGRectMake(MAX(12, yearX - gap - btn), 46, btn, btn);
    self.nextButton.frame = CGRectMake(MIN(w - 12 - btn, CGRectGetMaxX(self.yearLabel.frame) + gap), 46, btn, btn);

    CGFloat listY = CGRectGetMaxY(self.header.frame);
    self.collectionView.frame = CGRectMake(0, listY, w, self.bounds.size.height - listY);
}

#pragma mark - Actions

- (void)prevTapped {
    if ([self.delegate respondsToSelector:@selector(memoryViewDidTapPrevYear:)]) {
        [self.delegate memoryViewDidTapPrevYear:self];
    }
}

- (void)nextTapped {
    if ([self.delegate respondsToSelector:@selector(memoryViewDidTapNextYear:)]) {
        [self.delegate memoryViewDidTapNextYear:self];
    }
}

- (void)yearTapped {
    if ([self.delegate respondsToSelector:@selector(memoryViewDidTapYear:)]) {
        [self.delegate memoryViewDidTapYear:self];
    }
}

#pragma mark - Collection

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    (void)collectionView; (void)section;
    return self.months.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YALMemoryMonthCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YALMemoryMonthCell" forIndexPath:indexPath];
    [cell configureWithModel:self.months[indexPath.item]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    (void)collectionView; (void)collectionViewLayout; (void)indexPath;
    CGFloat w = self.bounds.size.width;
    CGFloat itemW = w - 16 * 2;
    return CGSizeMake(itemW, 260);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    (void)collectionView;
    if (indexPath.item < 0 || indexPath.item >= (NSInteger)self.months.count) return;
    YALMemoryMonthModel *m = self.months[indexPath.item];
    if ([self.delegate respondsToSelector:@selector(memoryView:didSelectMonth:)]) {
        [self.delegate memoryView:self didSelectMonth:m];
    }
}

@end

