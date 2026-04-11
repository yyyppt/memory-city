#import "YALMemoryView.h"
#import "YALMemoryMonthCell.h"
#import <Masonry/Masonry.h>

@interface YALMemoryView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UILabel *eyebrowLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *yearLabel;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation YALMemoryView

@synthesize yearsWithContent = _yearsWithContent;

- (void)setYearsWithContent:(NSSet<NSNumber *> *)yearsWithContent {
    _yearsWithContent = [yearsWithContent copy];
    [self reloadYearNavigation];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [self pageBackgroundColor];
        [self buildUI];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)buildUI {
    _header = [[UIView alloc] init];
    _header.backgroundColor = [UIColor clearColor];
    [self addSubview:_header];

    _eyebrowLabel = [[UILabel alloc] init];
    _eyebrowLabel.text = @"";
    _eyebrowLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    _eyebrowLabel.textColor = [UIColor colorWithRed:0.74 green:0.47 blue:0.20 alpha:1.0];
    _eyebrowLabel.hidden = YES;
    [_header addSubview:_eyebrowLabel];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"";
    _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor secondaryLabelColor];
    _titleLabel.hidden = YES;
    [_header addSubview:_titleLabel];

    _yearLabel = [[UILabel alloc] init];
    _yearLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightHeavy];
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

    // Masonry 约束
    [_header mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(12);
        } else {
            make.top.equalTo(self.mas_top).offset(12);
        }
        make.left.right.equalTo(self);
        make.height.mas_equalTo(76.0);
    }];

    [_yearLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_header);
        make.top.equalTo(_header.mas_top).offset(12);
        make.height.mas_equalTo(48);
    }];

    [_prevButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_yearLabel.mas_left).offset(-6);
        make.centerY.equalTo(_yearLabel);
        make.width.height.mas_equalTo(36);
    }];

    [_nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_yearLabel.mas_right).offset(6);
        make.centerY.equalTo(_yearLabel);
        make.width.height.mas_equalTo(36);
    }];

    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_header.mas_bottom);
        make.left.right.bottom.equalTo(self);
    }];
}

- (UIColor *)pageBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:0.075 green:0.068 blue:0.06 alpha:1.0];
            }
            return [UIColor colorWithRed:0.985 green:0.965 blue:0.935 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.985 green:0.965 blue:0.935 alpha:1.0];
}

- (void)setYear:(NSInteger)year {
    _year = year;
    self.yearLabel.text = [NSString stringWithFormat:@"%ld", (long)year];
    [self reloadYearNavigation];
}

- (void)setMonths:(NSArray<YALMemoryMonthModel *> *)months {
    _months = months ?: @[];
    [self.collectionView reloadData];
}

- (void)reload {
    self.yearLabel.text = [NSString stringWithFormat:@"%ld", (long)self.year];
    [self reloadYearNavigation];
    [self.collectionView reloadData];
}

- (void)reloadYearNavigation {
    NSSet *set = self.yearsWithContent ?: [NSSet set];
    BOOL has = [set containsObject:@(self.year)];

    self.yearLabel.textColor = has ? [UIColor labelColor] : [UIColor tertiaryLabelColor];
    self.yearLabel.userInteractionEnabled = has;

    NSArray *sorted = [set.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSInteger idx = [sorted indexOfObject:@(self.year)];
    BOOL canPrev = (idx != NSNotFound && idx > 0);
    BOOL canNext = (idx != NSNotFound && idx < (NSInteger)sorted.count - 1);

    self.prevButton.enabled = canPrev;
    self.nextButton.enabled = canNext;
    self.prevButton.alpha = canPrev ? 1.0 : 0.35;
    self.nextButton.alpha = canNext ? 1.0 : 0.35;
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
    NSSet *set = self.yearsWithContent ?: [NSSet set];
    if (![set containsObject:@(self.year)]) return;
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
    return CGSizeMake(itemW, 320);
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
