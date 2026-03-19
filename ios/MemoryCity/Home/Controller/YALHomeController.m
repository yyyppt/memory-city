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

static CGFloat const kYALPostCellTextAreaHeight = 64.0;
static CGFloat const kYALSingleColumnItemHeight = 320.0;
static CGFloat const kYALHorizontalInset = 12.0;
static CGFloat const kYALItemSpacing = 10.0;

@interface YALHomeController ()

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) BOOL useWaterfall;              // YES: 瀑布流, NO: 单列
@property (nonatomic, strong) NSMutableArray<YALPostModel *> *data;
@property (nonatomic, strong) UIView *titleSearchContainer;
@property (nonatomic, strong) UISearchBar *titleSearchBar;

@end

@implementation YALHomeController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Home";
    self.useWaterfall = YES;

    UIColor *highlightColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];

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
    CGFloat titleWidth = self.view.bounds.size.width - 120.0; // 两侧各预留更大空间给按钮
    UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, titleWidth, 40.0)];
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 4, titleWidth, 32.0)];
    searchBar.placeholder = @"探索老街记忆...";
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.delegate = self;

    if (@available(iOS 13.0, *)) {
        UITextField *searchField = searchBar.searchTextField;
        searchField.layer.cornerRadius = 16.0;
        searchField.layer.masksToBounds = YES;

        UIColor *fieldBackground = [UIColor colorWithWhite:0.0 alpha:0.05]; // 极浅暗色层
        searchField.backgroundColor = fieldBackground;
        searchField.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightLight];
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

    // 右上角消息按钮（信封）
    if (@available(iOS 13.0, *)) {
        UIImage *messageIcon = [UIImage systemImageNamed:@"envelope"];
        UIBarButtonItem *messageItem =
        [[UIBarButtonItem alloc] initWithImage:messageIcon
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(messageTapped)];
        messageItem.tintColor = highlightColor;
        self.navigationItem.rightBarButtonItem = messageItem;
    }

    // 示例数据：不同高度比例，模拟后端返回的宽高
    self.data = [NSMutableArray array];
    for (NSInteger i = 0; i < 20; i++) {
        YALPostModel *model = [[YALPostModel alloc] init];
        UIImage *image = [UIImage systemImageNamed:@"photo"] ?: [[UIImage alloc] init];
        model.image = image;
        model.imageWidth = 100.0;
        model.imageHeight = (CGFloat)(arc4random_uniform(100) + 100); // 100~199 随机高度
        model.title = @"Memory";
        model.desc = @"记录今天的瞬间";
        [self.data addObject:model];
    }

    [self setupCollectionView];
}

- (void)setupCollectionView {
    UICollectionViewLayout *layout = [self currentLayout];

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                             collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.showsVerticalScrollIndicator = NO;

    [self.collectionView registerClass:[YALPostCell class]
            forCellWithReuseIdentifier:@"YALPostCell"];

    [self.view addSubview:self.collectionView];
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
        [self.collectionView reloadData];
    }];
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
    CGFloat fixedImageHeight = kYALSingleColumnItemHeight - kYALPostCellTextAreaHeight;
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

    // 单列模式：固定高度，保持信息流浏览节奏稳定
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
    YALPostModel *model = self.data[indexPath.item];
    if (model.imageWidth <= 0) {
        return width * 1.0 + kYALPostCellTextAreaHeight;
    }

    CGFloat imageHeight = width * (model.imageHeight / model.imageWidth);
    return imageHeight + kYALPostCellTextAreaHeight;
}

- (void)messageTapped {
    YALMessageController *vc = [[YALMessageController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];

    YALSearchController *vc = [[YALSearchController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end

