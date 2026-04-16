//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALHomeController.h"
#import "YALPostCell.h"
#import "YALPostModel.h"
#import "YALSearchController.h"
#import "YALMessageController.h"
#import "YALPostDetailController.h"
#import "YALPostManager.h"
#import "YALAuthManager.h"
#import <Masonry/Masonry.h>

static CGFloat const kYALPostCellTextAreaHeight = 84.0;
static CGFloat const kYALWaterfallTextAreaHeight = 84.0; // 与 YALPostCell 内部约束一致
static CGFloat const kYALSingleColumnItemHeight = 336.0;
static CGFloat const kYALHorizontalInset = 14.0;
static CGFloat const kYALItemSpacing = 12.0;
static NSInteger const kYALHomeDisplayCount = 15;
static NSString * const kYALPostDetailLikedStatusCachePrefix = @"YALPostDetailLikedStatus";
static NSString * const kYALPostDetailCollectedStatusCachePrefix = @"YALPostDetailCollectedStatus";
static NSString * const kYALPostDetailInteractionCachePrefix = @"YALPostDetailInteractionCache";

@interface YALHomeController ()

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) BOOL useWaterfall;            
@property (nonatomic, strong) NSMutableArray<YALPostModel *> *data;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *waterfallHeightCache;
@property (nonatomic, assign) CGFloat cachedWaterfallItemWidth;
@property (nonatomic, strong) UIView *titleSearchContainer;
@property (nonatomic, strong) UISearchBar *titleSearchBar;

@end

@implementation YALHomeController

- (NSArray<YALPostModel *> *)publicOnlyPostsFromPosts:(NSArray<YALPostModel *> *)posts {
    if (![posts isKindOfClass:[NSArray class]] || posts.count == 0) {
        return @[];
    }
    NSMutableArray<YALPostModel *> *filtered = [NSMutableArray array];
    for (YALPostModel *model in posts) {
        if (![model isKindOfClass:[YALPostModel class]]) {
            continue;
        }
        if (!model.isPublic) {
            continue;
        }
        [filtered addObject:model];
    }
    return [filtered copy];
}

- (NSArray<YALPostModel *> *)shuffledPostsFromPosts:(NSArray<YALPostModel *> *)posts {
    if (![posts isKindOfClass:[NSArray class]] || posts.count < 2) {
        return posts ?: @[];
    }
    NSMutableArray<YALPostModel *> *shuffled = [posts mutableCopy];
    for (NSInteger i = shuffled.count - 1; i > 0; i--) {
        u_int32_t j = arc4random_uniform((u_int32_t)(i + 1));
        [shuffled exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    return [shuffled copy];
}

- (NSArray<YALPostModel *> *)limitedPostsFromPosts:(NSArray<YALPostModel *> *)posts {
    if (![posts isKindOfClass:[NSArray class]] || posts.count == 0) {
        return @[];
    }
    NSInteger limit = MIN((NSInteger)posts.count, kYALHomeDisplayCount);
    return [posts subarrayWithRange:NSMakeRange(0, limit)];
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

- (UIColor *)accentColor {
    return [UIColor colorWithRed:0.98 green:0.52 blue:0.18 alpha:1.0];
}

#pragma mark - Waterfall Height Simulation

/// 用内容本身生成稳定 hash，避免同屏出现太多相同高度。
- (NSUInteger)stableWaterfallSeedForItem:(NSInteger)item model:(YALPostModel *)model {
    NSMutableString *source = [NSMutableString string];
    if ([model.contentId respondsToSelector:@selector(integerValue)] && model.contentId.integerValue > 0) {
        [source appendFormat:@"%@_", model.contentId];
    }
    if (model.title.length > 0) {
        [source appendString:model.title];
    }
    if (model.city.length > 0) {
        [source appendFormat:@"_%@", model.city];
    }
    if (model.imageURLString.length > 0) {
        [source appendFormat:@"_%@", model.imageURLString];
    }
    if (model.content.length > 0) {
        NSUInteger sampleLength = MIN((NSUInteger)24, model.content.length);
        [source appendFormat:@"_%@", [model.content substringToIndex:sampleLength]];
    }
    if (source.length == 0) {
        [source appendFormat:@"fallback_%ld", (long)item];
    }

    NSUInteger hash = 2166136261u;
    for (NSUInteger i = 0; i < source.length; i++) {
        unichar ch = [source characterAtIndex:i];
        hash ^= (NSUInteger)ch;
        hash *= 16777619u;
    }
    hash ^= (NSUInteger)(item * 131);
    return hash;
}

/// 生成“稳定但不死板”的伪瀑布流比例，禁止随机数。
- (CGFloat)simulatedRatioForItem:(NSInteger)item model:(YALPostModel *)model {
    static CGFloat const kBaseRatios[] = {
        0.86, 0.92, 0.98, 1.04, 1.10, 1.16, 1.24, 1.32, 1.40, 1.50, 1.62
    };
    static NSInteger const kBaseRatioCount = sizeof(kBaseRatios) / sizeof(CGFloat);

    NSUInteger seed = [self stableWaterfallSeedForItem:item model:model];
    CGFloat ratio = kBaseRatios[seed % kBaseRatioCount];

    NSInteger contentLength = model.content.length;
    CGFloat contentBoost = MIN(0.16, contentLength / 260.0 * 0.16);
    ratio += contentBoost;

    // 轻微扰动，让高度分布更自然，但仍然是稳定值。
    CGFloat fineTuning = ((seed / kBaseRatioCount) % 7) * 0.025;
    ratio += fineTuning;

    // 相邻项做轻微错位，减少连续“齐平”感。
    NSInteger columnBiasSeed = (NSInteger)((seed / 17) % 3);
    if ((item % 2 == 0 && columnBiasSeed == 1) || (item % 2 != 0 && columnBiasSeed == 2)) {
        ratio += 0.05;
    }

    return MAX(0.86, MIN(ratio, 1.68));
}

- (CGFloat)waterfallItemWidth {
    CGFloat collectionWidth = CGRectGetWidth(self.collectionView.bounds);
    if (collectionWidth <= 0) {
        collectionWidth = [UIScreen mainScreen].bounds.size.width;
    }
    CGFloat totalSpacing = kYALHorizontalInset * 2 + kYALItemSpacing;
    return floor((collectionWidth - totalSpacing) / 2.0);
}

- (void)prepareWaterfallMetricsIfNeeded {
    if (self.data.count == 0) { return; }

    CGFloat itemWidth = [self waterfallItemWidth];
    if (itemWidth <= 0) { return; }

    BOOL shouldRebuild = (self.waterfallHeightCache.count != self.data.count) ||
                         (fabs(self.cachedWaterfallItemWidth - itemWidth) > 0.5);
    if (!shouldRebuild) { return; }

    [self.waterfallHeightCache removeAllObjects];
    self.cachedWaterfallItemWidth = itemWidth;

    for (NSInteger i = 0; i < self.data.count; i++) {
        YALPostModel *model = self.data[i];
        CGFloat ratio = [self simulatedRatioForItem:i model:model];
        CGFloat imageHeight = floor(itemWidth * ratio);
        CGFloat totalHeight = imageHeight + kYALWaterfallTextAreaHeight;
        self.waterfallHeightCache[@(i)] = @(totalHeight);

        // 后端图片优先：仅当无后端图或本身是 picsum 时，才使用模拟图 URL。
        BOOL hasBackendURL = (model.imageURLString.length > 0 &&
                              [model.imageURLString rangeOfString:@"picsum.photos"].location == NSNotFound);
        if (!hasBackendURL) {
            NSInteger imageW = (NSInteger)round(itemWidth);
            NSInteger imageH = (NSInteger)round(imageHeight);
            model.imageURLString = [NSString stringWithFormat:@"https://picsum.photos/%ld/%ld?seed=%ld",
                                    (long)imageW, (long)imageH, (long)(i + 1)];
        }
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    

    self.view.backgroundColor = [self pageBackgroundColor];
    self.navigationController.view.backgroundColor = [self pageBackgroundColor];
    self.title = @"MemoryCity";
    self.useWaterfall = YES;

    UIColor *highlightColor = [self accentColor];

    // 左上角布局切换按钮：显示“下一步可切换到的布局”
    if (@available(iOS 13.0, *)) {
        NSString *iconName = self.useWaterfall ? @"line.3.horizontal" : @"square.grid.2x2";
        UIImage *icon = [UIImage systemImageNamed:iconName];
        UIBarButtonItem *toggleButton =
        [[UIBarButtonItem alloc] initWithImage:icon
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(toggleLayout)];
        self.navigationItem.leftBarButtonItem = toggleButton;
    } else {
        UIBarButtonItem *toggleButton =
        [[UIBarButtonItem alloc] initWithTitle:@"单列"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(toggleLayout)];
        self.navigationItem.leftBarButtonItem = toggleButton;
    }

    self.navigationItem.leftBarButtonItem.tintColor = highlightColor;
    self.navigationController.navigationBar.tintColor = highlightColor;

    // 中间搜索栏：稍微短一点、两侧圆润
    CGFloat titleWidth = self.view.bounds.size.width - 120.0;
    UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, titleWidth, 40.0)];
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 4, titleWidth, 32.0)];
    searchBar.placeholder = @"探索老街记忆...";
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.delegate = self;

    if (@available(iOS 13.0, *)) {
        UITextField *searchField = searchBar.searchTextField;
        searchField.layer.cornerRadius = 16.0;
        searchField.layer.masksToBounds = YES;

        UIColor *fieldBackground = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.72];
        searchField.backgroundColor = fieldBackground;
        searchField.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        searchField.borderStyle = UITextBorderStyleNone;
        searchField.tintColor = highlightColor; // 光标颜色
        searchField.keyboardType = UIKeyboardTypeDefault;

        // 统一放大镜图标样式（颜色 + 粗细）
        UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration configurationWithPointSize:14
                                                        weight:UIImageSymbolWeightRegular];
        UIImage *searchIcon = [UIImage systemImageNamed:@"magnifyingglass"
                                      withConfiguration:config];
        [searchBar setImage:searchIcon
           forSearchBarIcon:UISearchBarIconSearch
                      state:UIControlStateNormal];
        searchField.leftView.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    }

    // 调整放大镜图标位置，让其在扁圆框内更居中
    [searchBar setPositionAdjustment:UIOffsetMake(10, 0) forSearchBarIcon:UISearchBarIconSearch];

    [titleContainer addSubview:searchBar];
    self.navigationItem.titleView = titleContainer;
    self.titleSearchContainer = titleContainer;
    self.titleSearchBar = searchBar;

    // 右上角互动消息按钮
    if (@available(iOS 13.0, *)) {
        UIImage *messageIcon = [UIImage systemImageNamed:@"bell.badge"];
        UIBarButtonItem *messageItem =
        [[UIBarButtonItem alloc] initWithImage:messageIcon style:UIBarButtonItemStylePlain target:self action:@selector(messageTapped)];
        messageItem.tintColor = highlightColor;
        self.navigationItem.rightBarButtonItem = messageItem;
    }

    // 先置空等待后端数据刷新
    self.data = [NSMutableArray array];
    self.waterfallHeightCache = [NSMutableDictionary dictionary];
    self.cachedWaterfallItemWidth = 0;

    [self setupCollectionView];

    // 下拉刷新
    if (@available(iOS 10.0, *)) {
      UIRefreshControl *rc = [[UIRefreshControl alloc] init];
      [rc addTarget:self action:@selector(refreshPosts) forControlEvents:UIControlEventValueChanged];
      self.collectionView.refreshControl = rc;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePostInteractionDidChange:)
                                                 name:YALPostInteractionDidChangeNotification
                                               object:nil];
    [self loadPosts];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshPosts {
    __weak typeof(self) weakSelf = self;
    [[YALPostManager shareManager] refreshPostsWithRandomSample:^(NSArray<YALPostModel *> * _Nullable posts, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (posts) {
            NSArray<YALPostModel *> *publicPosts = [strongSelf publicOnlyPostsFromPosts:posts];
            NSArray<YALPostModel *> *displayPosts = [strongSelf shuffledPostsFromPosts:publicPosts];
            strongSelf.data = [[strongSelf limitedPostsFromPosts:displayPosts] mutableCopy];
        } else {
            YALPostModel *placeholder = [[YALPostModel alloc] init];
            placeholder.image = [UIImage systemImageNamed:@"photo"] ?: [[UIImage alloc] init];
            placeholder.imageWidth = 300.0;
            placeholder.imageHeight = 400.0;
            placeholder.title = @"刷新失败";
            placeholder.desc = (error.localizedDescription.length > 0) ? error.localizedDescription : @"请稍后再试。";
            strongSelf.data = [@[placeholder] mutableCopy];
        }

        [strongSelf syncCachedInteractionStateForVisibleList];
        [strongSelf.waterfallHeightCache removeAllObjects];
        strongSelf.cachedWaterfallItemWidth = 0;
        [strongSelf prepareWaterfallMetricsIfNeeded];
        [strongSelf.collectionView reloadData];
        if (@available(iOS 10.0, *)) {
            if (strongSelf.collectionView.refreshControl.isRefreshing) {
                [strongSelf.collectionView.refreshControl endRefreshing];
            }
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self syncCachedInteractionStateForVisibleList];
}

- (void)loadPosts {
    __weak typeof(self) ws = self;
    [[YALPostManager shareManager] getPostsWithCache:^(NSArray<YALPostModel *> * _Nullable posts, BOOL fromCache, NSError * _Nullable error) {
        if (!ws) return;

        if (posts) {
            NSArray<YALPostModel *> *publicPosts = [ws publicOnlyPostsFromPosts:posts];
            ws.data = [[ws limitedPostsFromPosts:publicPosts] mutableCopy];
        } else if (!fromCache) {
            // 拉取失败时保底显示一条占位数据，避免页面完全空白
            YALPostModel *placeholder = [[YALPostModel alloc] init];
            placeholder.image = [UIImage systemImageNamed:@"photo"] ?: [[UIImage alloc] init];
            placeholder.imageWidth = 300.0;
            placeholder.imageHeight = 400.0;
            placeholder.title = @"加载失败";
            placeholder.desc = (error.localizedDescription.length > 0) ? error.localizedDescription : @"请检查网络或接口地址。";
            ws.data = [@[placeholder] mutableCopy];
        }
        [ws syncCachedInteractionStateForVisibleList];
        [ws.waterfallHeightCache removeAllObjects];
        ws.cachedWaterfallItemWidth = 0;
        [ws prepareWaterfallMetricsIfNeeded];
        [ws.collectionView reloadData];
        if (@available(iOS 10.0, *)) {
            if (ws.collectionView.refreshControl.isRefreshing) {
                [ws.collectionView.refreshControl endRefreshing];
            }
        }
    }];
}

- (void)removePrivatePostsFromCurrentData {
    NSArray<YALPostModel *> *publicPosts = [self publicOnlyPostsFromPosts:self.data];
    self.data = [publicPosts mutableCopy];
    [self.waterfallHeightCache removeAllObjects];
    self.cachedWaterfallItemWidth = 0;
    [self prepareWaterfallMetricsIfNeeded];
    [self.collectionView reloadData];
}

- (void)setupCollectionView {
    UICollectionViewLayout *layout = [self currentLayout];

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                             collectionViewLayout:layout];
    self.collectionView.backgroundColor = [self pageBackgroundColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(8.0, 0, 18.0, 0);

    [self.collectionView registerClass:[YALPostCell class]
            forCellWithReuseIdentifier:@"YALPostCell"];

    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (UICollectionViewLayout *)currentLayout {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;

    if (self.useWaterfall) {
        YALWaterfallLayout *layout = [[YALWaterfallLayout alloc] init];
        layout.delegate = self;
        layout.columnCount = 2;
        layout.columnSpacing = kYALItemSpacing;
        layout.rowSpacing = kYALItemSpacing;
        layout.sectionInset = UIEdgeInsetsMake(kYALItemSpacing, kYALHorizontalInset, kYALItemSpacing, kYALHorizontalInset);
        // item 宽度会在 layout 里计算，这里只需要保证列数和间距
        (void)screenWidth;
        return layout;
    } else {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemWidth = screenWidth - kYALHorizontalInset * 2;
        layout.minimumLineSpacing = kYALItemSpacing;
        layout.sectionInset =
        UIEdgeInsetsMake(kYALItemSpacing, kYALHorizontalInset, kYALItemSpacing, kYALHorizontalInset);
        layout.itemSize = CGSizeMake(itemWidth, kYALSingleColumnItemHeight);
        return layout;
    }
}

- (void)toggleLayout {
    self.useWaterfall = !self.useWaterfall;

    if (@available(iOS 13.0, *)) {

        NSString *iconName = self.useWaterfall ? @"line.3.horizontal" : @"square.grid.2x2";
        UIImage *icon = [UIImage systemImageNamed:iconName];
        self.navigationItem.leftBarButtonItem.image = icon;
    } else {
        self.navigationItem.leftBarButtonItem.title = self.useWaterfall ? @"单列" : @"瀑布";
    }

    UICollectionViewLayout *newLayout = [self currentLayout];
    [self.collectionView setCollectionViewLayout:newLayout animated:YES];
    [UIView animateWithDuration:0.25
                     animations:^{
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self.collectionView layoutIfNeeded];
    } completion:^(__unused BOOL finished) {
        [self prepareWaterfallMetricsIfNeeded];
        [self.collectionView reloadData];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self prepareWaterfallMetricsIfNeeded];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.data.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YALPostCell *cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:@"YALPostCell"
                                              forIndexPath:indexPath];

    YALPostModel *model = self.data[indexPath.item];
    CGFloat fixedImageHeight = 0.0;
    if (self.useWaterfall) {
        [self prepareWaterfallMetricsIfNeeded];
        NSNumber *totalHeight = self.waterfallHeightCache[@(indexPath.item)];
        if (totalHeight) {
            fixedImageHeight = MAX(120.0, totalHeight.doubleValue - kYALWaterfallTextAreaHeight);
        }
    } else {
        fixedImageHeight = kYALSingleColumnItemHeight - kYALPostCellTextAreaHeight;
    }

    [cell configureWithModel:model
                useWaterfall:self.useWaterfall
            fixedImageHeight:fixedImageHeight];

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (self.useWaterfall) {
        // 瀑布流模式下高度由 layout delegate 决定，这里返回一个占位值即可
        return CGSizeMake(100, 100);
    }

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat itemWidth = screenWidth - kYALHorizontalInset * 2;
    return CGSizeMake(itemWidth, kYALSingleColumnItemHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    (void)collectionView;
    YALPostModel *model = self.data[indexPath.item];
    YALPostDetailController *detail = [[YALPostDetailController alloc] init];
    detail.post = model;
    detail.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detail animated:YES];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(YALWaterfallLayout *)layout
 heightForItemAtIndexPath:(NSIndexPath *)indexPath
                itemWidth:(CGFloat)width {
    (void)collectionView;
    (void)layout;
    (void)width;
    [self prepareWaterfallMetricsIfNeeded];
    NSNumber *cachedHeight = self.waterfallHeightCache[@(indexPath.item)];
    if (cachedHeight) {
        return cachedHeight.doubleValue;
    }

    // 兜底：缓存未命中时即时计算并写回，确保高度稳定。
    YALPostModel *model = self.data[indexPath.item];
    CGFloat itemWidth = [self waterfallItemWidth];
    CGFloat ratio = [self simulatedRatioForItem:indexPath.item model:model];
    CGFloat imageHeight = floor(itemWidth * ratio);
    CGFloat totalHeight = imageHeight + kYALWaterfallTextAreaHeight;
    self.waterfallHeightCache[@(indexPath.item)] = @(totalHeight);
    return totalHeight;
}

- (void)messageTapped {
    YALMessageController *vc = [[YALMessageController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

}

- (void)handlePostInteractionDidChange:(NSNotification *)notification {
    NSDictionary *userInfo = [notification.userInfo isKindOfClass:[NSDictionary class]] ? notification.userInfo : nil;
    NSNumber *contentId = [userInfo[@"content_id"] respondsToSelector:@selector(integerValue)] ? @([userInfo[@"content_id"] integerValue]) : nil;
    if (contentId.integerValue <= 0 || self.data.count == 0) {
        return;
    }

    __block NSInteger targetIndex = NSNotFound;
    [self.data enumerateObjectsUsingBlock:^(YALPostModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentId respondsToSelector:@selector(integerValue)] &&
            obj.contentId.integerValue == contentId.integerValue) {
            targetIndex = (NSInteger)idx;
            *stop = YES;
        }
    }];

    if (targetIndex == NSNotFound || targetIndex >= (NSInteger)self.data.count) {
        return;
    }

    YALPostModel *model = self.data[targetIndex];
    if ([userInfo[@"like_count"] respondsToSelector:@selector(integerValue)]) {
        model.likeCount = MAX([userInfo[@"like_count"] integerValue], 0);
    }
    if ([userInfo[@"collect_count"] respondsToSelector:@selector(integerValue)]) {
        model.collectCount = MAX([userInfo[@"collect_count"] integerValue], 0);
    }
    if ([userInfo[@"comment_count"] respondsToSelector:@selector(integerValue)]) {
        model.commentCount = MAX([userInfo[@"comment_count"] integerValue], 0);
    }
    if ([userInfo[@"is_liked"] respondsToSelector:@selector(boolValue)]) {
        model.isLiked = [userInfo[@"is_liked"] boolValue];
    }
    if ([userInfo[@"is_collected"] respondsToSelector:@selector(boolValue)]) {
        model.isCollected = [userInfo[@"is_collected"] boolValue];
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:targetIndex inSection:0];
    if ([self.collectionView numberOfSections] > 0 &&
        targetIndex < (NSInteger)[self.collectionView numberOfItemsInSection:0]) {
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        [self.collectionView reloadData];
    }
}

- (NSString *)interactionCacheKeyWithPrefix:(NSString *)prefix contentId:(NSNumber *)contentId {
    if (![contentId respondsToSelector:@selector(integerValue)] || contentId.integerValue <= 0) {
        return nil;
    }
    NSInteger userId = [YALAuthManager sharedManager].currentUser.userId;
    if (userId > 0) {
        return [NSString stringWithFormat:@"%@_%ld_%@", prefix, (long)userId, contentId];
    }
    return [NSString stringWithFormat:@"%@_%@", prefix, contentId];
}

- (BOOL)syncCachedInteractionStateForPost:(YALPostModel *)post {
    if (![post isKindOfClass:[YALPostModel class]]) {
        return NO;
    }

    BOOL changed = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *likedKey = [self interactionCacheKeyWithPrefix:kYALPostDetailLikedStatusCachePrefix contentId:post.contentId];
    if (likedKey.length > 0 && [defaults objectForKey:likedKey] != nil) {
        BOOL cachedLiked = [defaults boolForKey:likedKey];
        if (post.isLiked != cachedLiked) {
            post.isLiked = cachedLiked;
            changed = YES;
        }
    }

    NSString *collectedKey = [self interactionCacheKeyWithPrefix:kYALPostDetailCollectedStatusCachePrefix contentId:post.contentId];
    if (collectedKey.length > 0 && [defaults objectForKey:collectedKey] != nil) {
        BOOL cachedCollected = [defaults boolForKey:collectedKey];
        if (post.isCollected != cachedCollected) {
            post.isCollected = cachedCollected;
            changed = YES;
        }
    }

    NSString *interactionKey = [self interactionCacheKeyWithPrefix:kYALPostDetailInteractionCachePrefix contentId:post.contentId];
    NSDictionary *interactionCache = interactionKey.length > 0 ? [defaults objectForKey:interactionKey] : nil;
    if ([interactionCache isKindOfClass:[NSDictionary class]]) {
        id likeCountObj = interactionCache[@"like_count"];
        if ([likeCountObj respondsToSelector:@selector(integerValue)]) {
            NSInteger likeCount = MAX([likeCountObj integerValue], 0);
            if (post.likeCount != likeCount) {
                post.likeCount = likeCount;
                changed = YES;
            }
        }
        id collectCountObj = interactionCache[@"favorite_count"];
        if ([collectCountObj respondsToSelector:@selector(integerValue)]) {
            NSInteger collectCount = MAX([collectCountObj integerValue], 0);
            if (post.collectCount != collectCount) {
                post.collectCount = collectCount;
                changed = YES;
            }
        }
    }

    return changed;
}

- (void)syncCachedInteractionStateForVisibleList {
    if (self.data.count == 0) {
        return;
    }

    BOOL hasChange = NO;
    for (YALPostModel *model in self.data) {
        hasChange = [self syncCachedInteractionStateForPost:model] || hasChange;
    }
    if (hasChange && self.isViewLoaded) {
        [self.collectionView reloadData];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];

    YALSearchController *vc = [[YALSearchController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
