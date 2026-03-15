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

static CGFloat const kYALPostCellTextAreaHeight = 64.0;
static CGFloat const kYALSingleColumnItemHeight = 320.0;
static CGFloat const kYALHorizontalInset = 12.0;
static CGFloat const kYALItemSpacing = 10.0;

@interface YALMessageCell : UITableViewCell

- (void)configureWithMessage:(NSDictionary *)message;

@end

@interface YALMessageController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *messages;

@end

@interface YALHomeController ()

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) BOOL useWaterfall;              // YES: 瀑布流, NO: 单列
@property (nonatomic, strong) NSMutableArray<YALPostModel *> *data;
@property (nonatomic, strong) UIView *titleSearchContainer;
@property (nonatomic, strong) UISearchBar *titleSearchBar;

@end

@implementation YALMessageCell {
  UIView *_avatarContainer;
  UIImageView *_avatarIconView;
  UILabel *_nameLabel;
  UILabel *_summaryLabel;
  UILabel *_timeLabel;
  UILabel *_badgeLabel;
  UIView *_dotView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _avatarContainer = [[UIView alloc] init];
    _avatarContainer.layer.cornerRadius = 24.0;
    _avatarContainer.layer.masksToBounds = YES;
    [self.contentView addSubview:_avatarContainer];

    _avatarIconView = [[UIImageView alloc] init];
    _avatarIconView.contentMode = UIViewContentModeScaleAspectFit;
    [_avatarContainer addSubview:_avatarIconView];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _nameLabel.textColor = [UIColor labelColor];
    [self.contentView addSubview:_nameLabel];

    _summaryLabel = [[UILabel alloc] init];
    _summaryLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    _summaryLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:_summaryLabel];

    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    _timeLabel.textColor = [UIColor secondaryLabelColor];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_timeLabel];

  _badgeLabel = [[UILabel alloc] init];
  _badgeLabel.textColor = [UIColor whiteColor];
  if (@available(iOS 13.0, *)) {
    _badgeLabel.backgroundColor = [UIColor systemRedColor];
  } else {
    _badgeLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
  }
    _badgeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    _badgeLabel.textAlignment = NSTextAlignmentCenter;
    _badgeLabel.layer.cornerRadius = 9.0;
    _badgeLabel.layer.masksToBounds = YES;
    [self.contentView addSubview:_badgeLabel];

  _dotView = [[UIView alloc] init];
  if (@available(iOS 13.0, *)) {
    _dotView.backgroundColor = [UIColor systemRedColor];
  } else {
    _dotView.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
  }
    _dotView.layer.cornerRadius = 4.0;
    _dotView.layer.masksToBounds = YES;
    [self.contentView addSubview:_dotView];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat contentWidth = CGRectGetWidth(self.contentView.bounds);
  _avatarContainer.frame = CGRectMake(16, 12, 48, 48);
  _avatarIconView.frame = CGRectMake(12, 12, 24, 24);

  _nameLabel.frame = CGRectMake(76, 14, contentWidth - 160, 22);
  _summaryLabel.frame = CGRectMake(76, 38, contentWidth - 160, 20);
  _timeLabel.frame = CGRectMake(contentWidth - 90, 14, 72, 20);

  _badgeLabel.frame = CGRectMake(contentWidth - 36, 40, 20, 18);
  _dotView.frame = CGRectMake(contentWidth - 24, 45, 8, 8);
}

- (void)configureWithMessage:(NSDictionary *)message {
  _avatarContainer.backgroundColor = message[@"avatarBgColor"];
  _avatarIconView.image = message[@"avatarIcon"];
  _avatarIconView.tintColor = [UIColor whiteColor];

  NSString *name = message[@"name"] ?: @"";
  NSString *highlight = message[@"highlight"] ?: @"";
  NSMutableAttributedString *nameAttr =
    [[NSMutableAttributedString alloc] initWithString:name
                                           attributes:@{
    NSForegroundColorAttributeName: [UIColor labelColor]
  }];
  if (highlight.length > 0) {
    NSRange range = [name rangeOfString:highlight];
    if (range.location != NSNotFound) {
      UIColor *highlightColor;
      if (@available(iOS 13.0, *)) {
        highlightColor = [UIColor systemBlueColor];
      } else {
        highlightColor = [UIColor colorWithRed:0.41 green:0.73 blue:1.0 alpha:1.0];
      }
      [nameAttr addAttribute:NSForegroundColorAttributeName
                       value:highlightColor
                       range:range];
    }
  }
  _nameLabel.attributedText = nameAttr;
  _summaryLabel.text = message[@"summary"];
  _timeLabel.text = message[@"time"];

  NSNumber *unreadCount = message[@"unreadCount"];
  BOOL showDot = [message[@"showDot"] boolValue];
  if (unreadCount.integerValue > 0) {
    _badgeLabel.hidden = NO;
    _dotView.hidden = YES;
    _badgeLabel.text = unreadCount.integerValue > 99 ? @"99+" : unreadCount.stringValue;
    CGFloat width = unreadCount.integerValue > 9 ? 26.0 : 20.0;
    _badgeLabel.frame = CGRectMake(CGRectGetWidth(self.contentView.bounds) - 16 - width, 40, width, 18);
    _badgeLabel.layer.cornerRadius = 9.0;
  } else {
    _badgeLabel.hidden = YES;
    _dotView.hidden = !showDot;
  }
}

@end

@implementation YALMessageController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor systemBackgroundColor];
  self.title = @"消息";
  self.navigationItem.hidesBackButton = YES;
  // 导航栏样式沿用全局设置（奶油白背景 + 橙色图标），不单独覆盖

  if (@available(iOS 13.0, *)) {
    UIImage *back = [UIImage systemImageNamed:@"chevron.left"];
    self.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithImage:back
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(backTapped)];

    UIImage *ellipsis = [UIImage systemImageNamed:@"ellipsis"];
    UIImage *trash = [UIImage systemImageNamed:@"trash"];
    UIBarButtonItem *moreItem =
      [[UIBarButtonItem alloc] initWithImage:ellipsis
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(moreTapped)];
    UIBarButtonItem *trashItem =
      [[UIBarButtonItem alloc] initWithImage:trash
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(trashTapped)];
    self.navigationItem.rightBarButtonItems = @[trashItem, moreItem];
  }

  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  if (@available(iOS 13.0, *)) {
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
  } else {
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
  }
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.showsVerticalScrollIndicator = NO;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.tableView registerClass:[YALMessageCell class] forCellReuseIdentifier:@"YALMessageCell"];
  self.tableView.tableHeaderView = [self buildHeaderView];
  [self.view addSubview:self.tableView];

  self.messages = @[
    @{
      @"name": @"记忆小助手 官方",
      @"highlight": @"官方",
      @"summary": @"你收到了一条新的活动邀请，点击查看详情",
      @"time": @"11:42",
      @"unreadCount": @2,
      @"showDot": @NO,
      @"avatarBgColor": (@available(iOS 13.0, *) ? [UIColor systemBlueColor] : [UIColor colorWithRed:0.22 green:0.56 blue:1 alpha:1]),
      @"avatarIcon": [UIImage systemImageNamed:@"sparkles"]
    },
    @{
      @"name": @"阿城同学",
      @"highlight": @"阿城",
      @"summary": @"回复了你：这条老街记忆我也拍过！",
      @"time": @"昨天",
      @"unreadCount": @0,
      @"showDot": @YES,
      @"avatarBgColor": (@available(iOS 13.0, *) ? [UIColor systemOrangeColor] : [UIColor colorWithRed:0.98 green:0.56 blue:0.32 alpha:1]),
      @"avatarIcon": [UIImage systemImageNamed:@"face.smiling"]
    },
    @{
      @"name": @"猫咪摄影社",
      @"highlight": @"猫咪",
      @"summary": @"赞了你的笔记《巷口的旧时光》",
      @"time": @"周三",
      @"unreadCount": @0,
      @"showDot": @NO,
      @"avatarBgColor": (@available(iOS 13.0, *) ? [UIColor systemPurpleColor] : [UIColor colorWithRed:0.56 green:0.41 blue:1 alpha:1]),
      @"avatarIcon": [UIImage systemImageNamed:@"camera.aperture"]
    },
    @{
      @"name": @"系统通知",
      @"highlight": @"系统",
      @"summary": @"你有 3 位新粉丝，快去看看吧",
      @"time": @"周二",
      @"unreadCount": @12,
      @"showDot": @NO,
      @"avatarBgColor": (@available(iOS 13.0, *) ? [UIColor systemGreenColor] : [UIColor colorWithRed:0.18 green:0.75 blue:0.48 alpha:1]),
      @"avatarIcon": [UIImage systemImageNamed:@"person.2.fill"]
    }
  ];
}

- (UIView *)buildHeaderView {
  CGFloat width = CGRectGetWidth(self.view.bounds);
  UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 100)];
  header.backgroundColor = [UIColor clearColor];

  NSArray<NSDictionary *> *items = @[
    @{
      @"title": @"回复与@",
      @"icon": @"bubble.left.and.bubble.right.fill",
      @"bgColor": (@available(iOS 13.0, *) ? [UIColor secondarySystemBackgroundColor] : [UIColor colorWithRed:0.90 green:0.98 blue:0.93 alpha:1]),
      @"iconColor": (@available(iOS 13.0, *) ? [UIColor systemGreenColor] : [UIColor colorWithRed:0.16 green:0.67 blue:0.42 alpha:1])
    },
    @{
      @"title": @"收到喜欢",
      @"icon": @"heart.fill",
      @"bgColor": (@available(iOS 13.0, *) ? [UIColor secondarySystemBackgroundColor] : [UIColor colorWithRed:1.0 green:0.93 blue:0.95 alpha:1.0]),
      @"iconColor": (@available(iOS 13.0, *) ? [UIColor systemPinkColor] : [UIColor colorWithRed:0.95 green:0.38 blue:0.59 alpha:1.0])
    },
    @{
      @"title": @"新增粉丝",
      @"icon": @"person.2.fill",
      @"bgColor": (@available(iOS 13.0, *) ? [UIColor secondarySystemBackgroundColor] : [UIColor colorWithRed:0.92 green:0.95 blue:1.0 alpha:1.0]),
      @"iconColor": (@available(iOS 13.0, *) ? [UIColor systemBlueColor] : [UIColor colorWithRed:0.30 green:0.56 blue:0.96 alpha:1.0])
    }
  ];

  CGFloat gap = 10.0;
  CGFloat cardWidth = (width - 16.0 * 2 - gap * 2) / 3.0;
  for (NSInteger i = 0; i < items.count; i++) {
    NSDictionary *item = items[i];
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(16 + i * (cardWidth + gap), 12, cardWidth, 74)];
    card.backgroundColor = item[@"bgColor"];
    card.layer.cornerRadius = 14.0;
    card.layer.masksToBounds = YES;

    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake((cardWidth - 22) / 2.0, 14, 22, 22)];
    if (@available(iOS 13.0, *)) {
      iconView.image = [UIImage systemImageNamed:item[@"icon"]];
    }
    iconView.tintColor = item[@"iconColor"];
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 43, cardWidth, 20)];
    titleLabel.text = item[@"title"];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor labelColor];

    [card addSubview:iconView];
    [card addSubview:titleLabel];
    [header addSubview:card];
  }
  return header;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  YALMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YALMessageCell" forIndexPath:indexPath];
  [cell configureWithMessage:self.messages[indexPath.row]];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  (void)indexPath;
  return 72.0;
}

- (void)backTapped {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)moreTapped {}

- (void)trashTapped {}

@end

@implementation YALHomeController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor systemBackgroundColor];
  self.title = @"Home";
  self.useWaterfall = YES;

  UIColor *highlightColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];

  // 左上角布局切换按钮（初始为瀑布流：用四宫格图标）
  if (@available(iOS 13.0, *)) {
    UIImage *icon = [UIImage systemImageNamed:@"square.grid.2x2"];
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
    // 瀑布流时用四宫格图标，单列时用列表图标
    NSString *iconName = self.useWaterfall ? @"square.grid.2x2" : @"line.3.horizontal";
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // 保持搜索栏静止不变，不做缩放和透明度动画，营造稳定的高级感
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  // 首页搜索栏只负责“跳转”，不在当前页输入
  [searchBar resignFirstResponder];

  YALSearchController *vc = [[YALSearchController alloc] init];
  vc.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:vc animated:YES];
}

@end

