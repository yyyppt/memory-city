//
//  YALSearchController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALSearchController.h"
#import <Masonry/Masonry.h>

@interface YALSearchController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray<NSDictionary *> *results;

@property (nonatomic, strong) UIView *aiHeaderView;
@property (nonatomic, strong) UIView *aiCardView;
@property (nonatomic, strong) UILabel *aiTitleLabel;
@property (nonatomic, strong) UILabel *aiDescLabel;
@property (nonatomic, strong) UILabel *emptyLabel;

@property (nonatomic, strong) NSTimer *streamTimer;
@property (nonatomic, copy) NSString *fullAIText;
@property (nonatomic, copy) NSString *displayedAIText;
@property (nonatomic, assign) NSInteger streamIndex;
@property (nonatomic, assign) BOOL isResultPage;

@end

@implementation YALSearchController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.results = @[];
    self.isResultPage = (self.keyword.length > 0);

    [self setupNavigationBar];
    [self setupTableView];
    [self setupAIHeaderView];
    [self setupEmptyState];

    if (self.isResultPage) {
        [self performSearchWithKeyword:self.keyword];
    } else {
        [self updateAIHeaderWithText:@""];
        self.emptyLabel.hidden = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self.searchBar becomeFirstResponder];
        });
    }
}

- (void)dealloc {
    [self.streamTimer invalidate];
    self.streamTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tabBarController.tabBar.hidden = NO;
}

#pragma mark - Setup

- (void)setupNavigationBar {
    UIColor *highlightColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    self.navigationController.navigationBar.tintColor = highlightColor;

    CGFloat titleWidth = self.view.bounds.size.width - 120.0;
    UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, titleWidth, 40.0)];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 4, titleWidth, 32.0)];

    self.searchBar.placeholder = @"搜索记忆内容...";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    self.searchBar.text = self.keyword ?: @"";

    if (@available(iOS 13.0, *)) {
        UITextField *searchField = self.searchBar.searchTextField;
        searchField.layer.cornerRadius = 16.0;
        searchField.layer.masksToBounds = YES;
        searchField.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.05];
        searchField.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightLight];
        searchField.borderStyle = UITextBorderStyleNone;
        searchField.tintColor = highlightColor;
        searchField.keyboardType = UIKeyboardTypeDefault;

        UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration configurationWithPointSize:14
                                                        weight:UIImageSymbolWeightRegular];
        UIImage *searchIcon = [UIImage systemImageNamed:@"magnifyingglass"
                                      withConfiguration:config];
        [self.searchBar setImage:searchIcon
                forSearchBarIcon:UISearchBarIconSearch
                           state:UIControlStateNormal];
        searchField.leftView.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    }

    [self.searchBar setPositionAdjustment:UIOffsetMake(10, 0) forSearchBarIcon:UISearchBarIconSearch];
    [titleContainer addSubview:self.searchBar];
    self.navigationItem.titleView = titleContainer;

    if (@available(iOS 13.0, *)) {
        UIImage *backIcon = [UIImage systemImageNamed:@"chevron.left"];
        UIBarButtonItem *backItem =
        [[UIBarButtonItem alloc] initWithImage:backIcon
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(backTapped)];
        self.navigationItem.leftBarButtonItem = backItem;
    }

    UIBarButtonItem *searchItem =
    [[UIBarButtonItem alloc] initWithTitle:@"搜索"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(triggerSearch)];
    searchItem.tintColor = highlightColor;
    self.navigationItem.rightBarButtonItem = searchItem;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if (@available(iOS 13.0, *)) {
        self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
        self.tableView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    }
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupAIHeaderView {
    CGFloat width = CGRectGetWidth(self.view.bounds);
    self.aiHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0.01)];
    self.aiHeaderView.backgroundColor = [UIColor clearColor];

    self.aiCardView = [[UIView alloc] init];
    self.aiCardView.backgroundColor = [self cardBackgroundColor];
    self.aiCardView.layer.cornerRadius = 18.0;
    self.aiCardView.layer.masksToBounds = YES;
    self.aiCardView.layer.borderWidth = 1.0;
    self.aiCardView.layer.borderColor = [self borderColor].CGColor;
    [self.aiHeaderView addSubview:self.aiCardView];

    UIView *iconBadge = [[UIView alloc] init];
    iconBadge.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.12];
    iconBadge.layer.cornerRadius = 17.0;
    iconBadge.layer.masksToBounds = YES;
    [self.aiCardView addSubview:iconBadge];

    UIImageView *iconView = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        iconView.image = [UIImage systemImageNamed:@"sparkles"];
    }
    iconView.tintColor = [self accentColor];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [iconBadge addSubview:iconView];

    self.aiTitleLabel = [[UILabel alloc] init];
    self.aiTitleLabel.text = @"AI说明";
    self.aiTitleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    self.aiTitleLabel.textColor = [UIColor labelColor];
    [self.aiCardView addSubview:self.aiTitleLabel];

    self.aiDescLabel = [[UILabel alloc] init];
    self.aiDescLabel.numberOfLines = 0;
    self.aiDescLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    self.aiDescLabel.textColor = [UIColor secondaryLabelColor];
    [self.aiCardView addSubview:self.aiDescLabel];

    [iconBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.aiCardView.mas_left).offset(16.0);
        make.top.equalTo(self.aiCardView.mas_top).offset(16.0);
        make.width.height.mas_equalTo(34.0);
    }];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(iconBadge);
        make.width.height.mas_equalTo(20.0);
    }];
    [self.aiTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(iconBadge.mas_right).offset(10.0);
        make.centerY.equalTo(iconBadge);
        make.right.equalTo(self.aiCardView.mas_right).offset(-16.0);
        make.height.mas_equalTo(20.0);
    }];
    [self.aiDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(iconBadge.mas_left);
        make.top.equalTo(iconBadge.mas_bottom).offset(10.0);
        make.right.equalTo(self.aiCardView.mas_right).offset(-16.0);
    }];

    self.tableView.tableHeaderView = self.aiHeaderView;
}

- (void)setupEmptyState {
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.numberOfLines = 2;
    self.emptyLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.text = @"输入关键词后点击右上角搜索\n再进入结果页查看 AI 说明";
    self.tableView.backgroundView = self.emptyLabel;
}

#pragma mark - Search Flow

- (void)triggerSearch {
    NSString *keyword = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.searchBar resignFirstResponder];

    if (keyword.length == 0) {
        return;
    }

    if (!self.isResultPage) {
        YALSearchController *resultVC = [[YALSearchController alloc] init];
        resultVC.keyword = keyword;
        resultVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:resultVC animated:YES];
        return;
    }

    [self performSearchWithKeyword:keyword];
}

- (void)performSearchWithKeyword:(NSString *)keyword {
    self.isResultPage = YES;
    self.keyword = keyword;
    self.searchBar.text = keyword;

    [self.streamTimer invalidate];
    self.streamTimer = nil;

    self.results = [self fakeResultsForKeyword:keyword];
    self.emptyLabel.hidden = (self.results.count > 0);
    [self.tableView reloadData];

    self.fullAIText = [NSString stringWithFormat:@"我帮你找到了与「%@」相关的记忆，一起来看看吧。", keyword];
    self.displayedAIText = @"";
    self.streamIndex = 0;
    [self updateAIHeaderWithText:self.displayedAIText];

    self.streamTimer = [NSTimer scheduledTimerWithTimeInterval:0.045
                                                        target:self
                                                      selector:@selector(handleStreamTimer)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (NSArray<NSDictionary *> *)fakeResultsForKeyword:(NSString *)keyword {
    return @[
        @{
            @"title": [NSString stringWithFormat:@"与「%@」相关的老街记忆", keyword],
            @"desc": @"巷口的风、旧招牌和傍晚的光线，都会把回忆慢慢拉回来。"
        },
        @{
            @"title": [NSString stringWithFormat:@"关于「%@」的地图足迹", keyword],
            @"desc": @"一些地点并不显眼，但它们在记忆里总有自己的坐标。"
        },
        @{
            @"title": [NSString stringWithFormat:@"你可能会喜欢的「%@」瞬间", keyword],
            @"desc": @"从照片、时间线到地图标点，都可以继续延展成完整故事。"
        }
    ];
}

- (void)handleStreamTimer {
    if (self.streamIndex >= self.fullAIText.length) {
        [self.streamTimer invalidate];
        self.streamTimer = nil;
        return;
    }

    self.streamIndex += 1;
    self.displayedAIText = [self.fullAIText substringToIndex:self.streamIndex];
    [self updateAIHeaderWithText:self.displayedAIText];
}


- (void)updateAIHeaderWithText:(NSString *)text {
    self.aiDescLabel.text = text;

    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat cardWidth = width - 32.0;

    if (text.length == 0) {
        self.aiCardView.frame = CGRectMake(16.0, 0.0, cardWidth, 0.01);
        self.aiHeaderView.frame = CGRectMake(0, 0, width, 0.01);
        self.tableView.tableHeaderView = self.aiHeaderView;
        return;
    }

    // tableHeaderView 需要手动计算高度后更新 frame 触发 UITableView 重排
    [self.aiCardView layoutIfNeeded];
    CGSize textSize = [self.aiDescLabel sizeThatFits:CGSizeMake(cardWidth - 32.0, CGFLOAT_MAX)];
    CGFloat descHeight = MAX(20.0, ceil(textSize.height));
    // iconBadge 高度 34 + top 16 + gap 10 = 60，再加 descHeight + bottom 16
    CGFloat cardHeight = 60.0 + descHeight + 16.0;
    self.aiCardView.frame = CGRectMake(16.0, 12.0, cardWidth, cardHeight);
    self.aiHeaderView.frame = CGRectMake(0, 0, width, CGRectGetMaxY(self.aiCardView.frame) + 8.0);
    self.tableView.tableHeaderView = self.aiHeaderView;
}


- (void)backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self triggerSearch];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"SearchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.backgroundColor = [self cardBackgroundColor];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        cell.detailTextLabel.numberOfLines = 2;
    }

    NSDictionary *item = self.results[indexPath.row];
    cell.textLabel.text = item[@"title"];
    cell.detailTextLabel.text = item[@"desc"];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    (void)indexPath;
    return 82.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return 8.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (UIColor *)accentColor {
    return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

- (UIColor *)cardBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondarySystemBackgroundColor];
    }
    return [UIColor whiteColor];
}

- (UIColor *)borderColor {
    return [UIColor colorWithWhite:0.0 alpha:0.05];
}

@end
