//
//  YALSearchController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALSearchController.h"
#import "../Model/YALSearchContentModel.h"
#import "../Model/YALSearchUserModel.h"
#import "../Model/YALAIAnalyzeResultModel.h"
#import "../Model/YALPostModel.h"
#import "../../PostDetail/Controller/YALPostDetailController.h"
#import "../../Network/Manager/YALContentManager.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

typedef NS_ENUM(NSInteger, YALSearchTabType) {
    YALSearchTabTypeContent = 0,
    YALSearchTabTypeUser = 1
};

@interface YALSearchResultCardCell : UITableViewCell

- (void)configureWithTitle:(NSString *)title
                  username:(NSString *)username
                  subtitle:(NSString *)subtitle
                      meta:(NSString *)meta
                  coverURL:(NSString *)coverURL
                 avatarURL:(NSString *)avatarURL
                    isUser:(BOOL)isUser;

@end

@interface YALSearchAIResultCell : UITableViewCell

- (void)configureWithKeyword:(NSString *)keyword
                      result:(nullable YALAIAnalyzeResultModel *)result
                     loading:(BOOL)loading
                   errorText:(nullable NSString *)errorText;

@end

@interface YALSearchController ()

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIView *topGlowView;

@property (nonatomic, strong) NSArray<YALSearchContentModel *> *contentResults;
@property (nonatomic, strong) NSArray<YALSearchUserModel *> *userResults;
@property (nonatomic, strong, nullable) YALAIAnalyzeResultModel *aiResult;
@property (nonatomic, copy) NSString *aiErrorText;
@property (nonatomic, copy) NSString *contentErrorText;
@property (nonatomic, copy) NSString *userErrorText;

@property (nonatomic, assign) YALSearchTabType currentTab;
@property (nonatomic, assign) YALSearchTabType initialTab;
@property (nonatomic, assign) BOOL isResultPage;
@property (nonatomic, assign) BOOL isContentLoading;
@property (nonatomic, assign) BOOL isUserLoading;
@property (nonatomic, assign) BOOL isAILoading;
@property (nonatomic, assign) NSUInteger contentRequestToken;
@property (nonatomic, assign) NSUInteger userRequestToken;
@property (nonatomic, assign) NSUInteger aiRequestToken;

@end

@implementation YALSearchController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:0.98 green:0.97 blue:0.95 alpha:1.0];
    self.currentTab = self.initialTab;
    self.contentResults = @[];
    self.userResults = @[];
    self.aiErrorText = @"";
    self.contentErrorText = @"";
    self.userErrorText = @"";
    self.isResultPage = (self.keyword.length > 0);

    [self setupNavigationBar];
    [self setupSegmentedControl];
    [self setupTableView];
    [self setupKeyboardDismissGesture];
    [self updateEmptyState];

    if (self.isResultPage) {
        [self performSearchWithKeyword:self.keyword];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self.searchBar becomeFirstResponder];
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        self.tabBarController.tabBar.hidden = NO;
    }
}

#pragma mark - Setup

- (void)setupNavigationBar {
    UIColor *highlightColor = [self accentColor];
    self.navigationController.navigationBar.tintColor = highlightColor;

    CGFloat titleWidth = self.view.bounds.size.width - 120.0;
    UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, titleWidth, 40.0)];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 4, titleWidth, 32.0)];
    self.searchBar.placeholder = @"搜索内容或用户...";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    self.searchBar.text = self.keyword ?: @"";

    if (@available(iOS 13.0, *)) {
        UITextField *searchField = self.searchBar.searchTextField;
        searchField.layer.cornerRadius = 16.0;
        searchField.layer.masksToBounds = YES;
        searchField.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.05];
        searchField.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
        searchField.borderStyle = UITextBorderStyleNone;
        searchField.tintColor = highlightColor;
    }

    [self.searchBar setPositionAdjustment:UIOffsetMake(10, 0) forSearchBarIcon:UISearchBarIconSearch];
    [titleContainer addSubview:self.searchBar];
    self.navigationItem.titleView = titleContainer;

    if (@available(iOS 13.0, *)) {
        UIBarButtonItem *backItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"]
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

- (void)setupSegmentedControl {
    self.topGlowView = [[UIView alloc] init];
    self.topGlowView.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.10];
    self.topGlowView.layer.cornerRadius = 120.0;
    self.topGlowView.userInteractionEnabled = NO;
    [self.view addSubview:self.topGlowView];

    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"内容", @"用户"]];
    self.segmentedControl.selectedSegmentIndex = self.currentTab == YALSearchTabTypeUser ? 1 : 0;
    self.segmentedControl.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.86];
    self.segmentedControl.selectedSegmentTintColor = [self accentColor];
    self.segmentedControl.layer.cornerRadius = 18.0;
    self.segmentedControl.layer.masksToBounds = YES;
    [self.segmentedControl setTitleTextAttributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.45 green:0.40 blue:0.36 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold]
    } forState:UIControlStateNormal];
    [self.segmentedControl setTitleTextAttributes:@{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold]
    } forState:UIControlStateSelected];
    [self.segmentedControl addTarget:self action:@selector(handleSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];

    [self.topGlowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(-56.0);
        make.centerX.equalTo(self.view);
        make.width.height.mas_equalTo(240.0);
    }];

    [self.segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(12.0);
        make.left.equalTo(self.view).offset(16.0);
        make.right.equalTo(self.view).offset(-16.0);
        make.height.mas_equalTo(44.0);
    }];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 220.0;
    self.tableView.sectionHeaderHeight = 0.01;
    self.tableView.sectionFooterHeight = 8.0;
    self.tableView.contentInset = UIEdgeInsetsMake(6.0, 0, 24.0, 0);
    [self.tableView registerClass:[YALSearchResultCardCell class] forCellReuseIdentifier:@"YALSearchResultCardCell"];
    [self.tableView registerClass:[YALSearchAIResultCell class] forCellReuseIdentifier:@"YALSearchAIResultCell"];
    [self.view addSubview:self.tableView];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom).offset(8.0);
        make.left.right.bottom.equalTo(self.view);
    }];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.tableView.backgroundView = self.emptyLabel;
}

- (void)setupKeyboardDismissGesture {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTapped)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGesture];
}

#pragma mark - Actions

- (void)backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleBackgroundTapped {
    [self.searchBar resignFirstResponder];
    if (@available(iOS 13.0, *)) {
        [self.searchBar.searchTextField resignFirstResponder];
    }
    [self.view endEditing:YES];
}

- (void)handleSegmentChanged:(UISegmentedControl *)sender {
    self.currentTab = (sender.selectedSegmentIndex == 0) ? YALSearchTabTypeContent : YALSearchTabTypeUser;
    [self.tableView reloadData];
    [self updateEmptyState];
}

- (void)triggerSearch {
    NSString *keyword = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.searchBar resignFirstResponder];
    if (keyword.length == 0) {
        return;
    }

    [self performSearchWithKeyword:keyword];
}

- (void)performSearchWithKeyword:(NSString *)keyword {
    self.isResultPage = YES;
    self.keyword = keyword;
    self.searchBar.text = keyword;
    self.contentResults = @[];
    self.userResults = @[];
    self.aiResult = nil;
    self.aiErrorText = @"";
    self.contentErrorText = @"";
    self.userErrorText = @"";
    self.isContentLoading = NO;
    self.isUserLoading = NO;
    self.isAILoading = NO;
    self.aiRequestToken += 1;
    [self updateEmptyState];
    [self.tableView reloadData];
    [self requestCombinedResultsForKeyword:keyword];
}

- (void)requestCombinedResultsForKeyword:(NSString *)keyword {
    self.isContentLoading = YES;
    self.isUserLoading = YES;
    self.contentResults = @[];
    self.userResults = @[];
    self.contentErrorText = @"";
    self.userErrorText = @"";
    self.contentRequestToken += 1;
    self.userRequestToken += 1;
    NSUInteger requestToken = self.contentRequestToken;
    [self updateEmptyState];
    [self.tableView reloadData];

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] searchAllWithKeyword:keyword
                                                       page:1
                                                   pageSize:20
                                                 completion:^(BOOL success,
                                                              NSArray<YALSearchContentModel *> * _Nullable contentList,
                                                              NSArray<YALSearchUserModel *> * _Nullable userList,
                                                              NSString * _Nullable message,
                                                              NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || requestToken != self.contentRequestToken || ![self.keyword isEqualToString:keyword]) {
            return;
        }

        self.isContentLoading = NO;
        self.isUserLoading = NO;
        if (success) {
            self.contentResults = contentList ?: @[];
            self.userResults = userList ?: @[];
            [self requestAIForSearchResults];
        } else {
            NSString *errorText = error.localizedDescription.length > 0 ? error.localizedDescription : (message.length > 0 ? message : @"搜索失败，请稍后重试");
            self.contentResults = @[];
            self.userResults = @[];
            self.contentErrorText = errorText;
            self.userErrorText = errorText;
            self.isAILoading = NO;
            self.aiResult = nil;
            self.aiErrorText = @"";
        }
        [self updateEmptyState];
        [self.tableView reloadData];
    }];
}

- (void)requestAIForSearchResults {
    NSString *resultText = [self aiAnalysisTextFromCurrentResults];
    if (resultText.length == 0) {
        self.isAILoading = NO;
        self.aiResult = nil;
        self.aiErrorText = @"";
        [self updateEmptyState];
        [self.tableView reloadData];
        return;
    }

    self.isAILoading = YES;
    self.aiResult = nil;
    self.aiErrorText = @"";
    self.aiRequestToken += 1;
    NSUInteger requestToken = self.aiRequestToken;
    [self.tableView reloadData];

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] analyzeText:resultText
                                        completion:^(BOOL success, YALAIAnalyzeResultModel * _Nullable result, NSString * _Nullable message, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || requestToken != self.aiRequestToken) {
            return;
        }

        self.isAILoading = NO;
        if (success) {
            self.aiResult = result;
        } else {
            self.aiResult = nil;
            self.aiErrorText = error.localizedDescription.length > 0 ? error.localizedDescription : (message.length > 0 ? message : @"AI 分析暂时不可用");
        }
        [self.tableView reloadData];
    }];
}

- (void)updateEmptyState {
    NSString *text = @"";
    if (!self.isResultPage || self.keyword.length == 0) {
        text = (self.currentTab == YALSearchTabTypeContent) ? @"输入关键词后查看内容和 AI 搜索结果" : @"输入关键词后查看相关账号";
    } else if (self.currentTab == YALSearchTabTypeContent) {
        if (self.isContentLoading) {
            text = @"正在搜索内容...";
        } else if (self.contentErrorText.length > 0) {
            text = self.contentErrorText;
        } else if (self.contentResults.count == 0 && ![self hasVisibleAISection]) {
            text = @"什么都没搜到";
        }
    } else {
        if (self.isUserLoading) {
            text = @"正在搜索用户...";
        } else if (self.userErrorText.length > 0) {
            text = self.userErrorText;
        } else if (self.userResults.count == 0) {
            text = @"什么都没搜到";
        }
    }

    self.emptyLabel.text = text;
    self.emptyLabel.hidden = (text.length == 0);
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    if (self.currentTab == YALSearchTabTypeContent) {
        if ([self shouldShowEmptySearchResult]) {
            return 0;
        }
        if (!self.isResultPage) {
            return 1;
        }
        return [self hasContentResultSection] ? 2 : 1;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    if (self.currentTab == YALSearchTabTypeContent) {
        if (!self.isResultPage) {
            return 0;
        }
        if ([self shouldShowEmptySearchResult]) {
            return 0;
        }
        if (section == 0) {
            return 1;
        }
        return [self hasContentResultSection] ? self.contentResults.count : 0;
    }
    if ([self shouldShowEmptySearchResult]) {
        return 0;
    }
    return self.userResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (self.currentTab == YALSearchTabTypeContent && indexPath.section == 0) {
        YALSearchAIResultCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"YALSearchAIResultCell" forIndexPath:indexPath];
        [cell configureWithKeyword:self.keyword ?: @""
                            result:self.aiResult
                           loading:self.isAILoading
                         errorText:self.aiErrorText];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    YALSearchResultCardCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"YALSearchResultCardCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (self.currentTab == YALSearchTabTypeContent) {
        YALSearchContentModel *item = self.contentResults[indexPath.row];
        NSString *title = item.title.length > 0 ? item.title : (item.content.length > 0 ? item.content : @"未命名内容");
        NSString *username = [self displayUserLineWithNickname:item.authorNickname username:item.authorUsername];
        NSString *subtitle = item.content.length > 0 ? item.content : (item.authorBio.length > 0 ? item.authorBio : @"");
        [cell configureWithTitle:title
                        username:username
                        subtitle:subtitle
                            meta:[self contentMetaText:item]
                        coverURL:item.images.firstObject ?: @""
                       avatarURL:item.authorAvatar
                          isUser:NO];
    } else {
        YALSearchUserModel *item = self.userResults[indexPath.row];
        NSString *title = item.nickname.length > 0 ? item.nickname : (item.username.length > 0 ? item.username : @"未命名用户");
        NSString *username = [self displayUserLineWithNickname:item.nickname username:item.username];
        NSString *subtitle = item.bio.length > 0 ? item.bio : (item.title.length > 0 ? item.title : @"这个账号暂时还没有更多介绍");
        NSString *meta = item.mood.length > 0 ? [NSString stringWithFormat:@"情绪标签：%@", item.mood] : @"账号信息";
        [cell configureWithTitle:title
                        username:username
                        subtitle:subtitle
                            meta:meta
                        coverURL:item.coverImage
                       avatarURL:item.avatar
                          isUser:YES];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return section == 0 ? 0.01 : 6.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.currentTab == YALSearchTabTypeUser) {
        if (indexPath.row >= self.userResults.count) {
            return;
        }
        [self showAuthorProfileForSearchUser:self.userResults[indexPath.row]];
        return;
    }

    if (indexPath.section != 1 || indexPath.row >= self.contentResults.count) {
        return;
    }

    [self showPostDetailForSearchContent:self.contentResults[indexPath.row]];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self triggerSearch];
}

#pragma mark - Helpers

- (NSString *)contentMetaText:(YALSearchContentModel *)item {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (item.city.length > 0) {
        [parts addObject:item.city];
    }
    if (item.year.length > 0) {
        [parts addObject:item.year];
    }
    if (item.mood.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"情绪 %@", item.mood]];
    }
    if (item.likeCount > 0) {
        [parts addObject:[NSString stringWithFormat:@"%ld赞", (long)item.likeCount]];
    }
    if (item.commentCount > 0) {
        [parts addObject:[NSString stringWithFormat:@"%ld评", (long)item.commentCount]];
    }
    return [parts componentsJoinedByString:@" · "];
}

- (NSString *)displayUserLineWithNickname:(NSString *)nickname username:(NSString *)username {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (nickname.length > 0) {
        [parts addObject:nickname];
    }
    if (username.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"@%@", username]];
    }
    return [parts componentsJoinedByString:@"  "];
}

- (NSString *)aiAnalysisTextFromCurrentResults {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    [lines addObject:[NSString stringWithFormat:@"内容结果数：%lu", (unsigned long)self.contentResults.count]];
    [lines addObject:[NSString stringWithFormat:@"用户结果数：%lu", (unsigned long)self.userResults.count]];

    for (YALSearchContentModel *item in self.contentResults) {
        if (![item isKindOfClass:[YALSearchContentModel class]]) {
            continue;
        }

        NSMutableArray<NSString *> *parts = [NSMutableArray array];
        if (item.title.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"标题：%@", item.title]];
        }
        if (item.content.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"内容：%@", item.content]];
        }
        if (item.city.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"城市：%@", item.city]];
        }
        if (item.year.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"时间：%@", item.year]];
        }
        if (item.mood.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"情绪：%@", item.mood]];
        }
        if (item.createdAt.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"发布时间：%@", item.createdAt]];
        }
        if (item.authorNickname.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"作者：%@", item.authorNickname]];
        }
        if (item.likeCount >= 0) {
            [parts addObject:[NSString stringWithFormat:@"点赞：%ld", (long)item.likeCount]];
        }
        if (item.commentCount >= 0) {
            [parts addObject:[NSString stringWithFormat:@"评论：%ld", (long)item.commentCount]];
        }
        [parts addObject:[NSString stringWithFormat:@"图片数：%lu", (unsigned long)item.images.count]];
        [parts addObject:[NSString stringWithFormat:@"公开状态：%@", item.contentId.integerValue > 0 ? @"可查看详情" : @"信息不完整"]];
        if (parts.count > 0) {
            [lines addObject:[parts componentsJoinedByString:@"；"]];
        }
    }

    for (YALSearchUserModel *item in self.userResults) {
        if (![item isKindOfClass:[YALSearchUserModel class]]) {
            continue;
        }

        NSMutableArray<NSString *> *parts = [NSMutableArray array];
        if (item.nickname.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"用户：%@", item.nickname]];
        } else if (item.username.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"用户：%@", item.username]];
        }
        if (item.title.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"标题：%@", item.title]];
        }
        if (item.bio.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"简介：%@", item.bio]];
        }
        if (item.mood.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"情绪：%@", item.mood]];
        }
        if (item.userId.integerValue > 0) {
            [parts addObject:[NSString stringWithFormat:@"用户ID：%@", item.userId]];
        }
        if (parts.count > 0) {
            [lines addObject:[parts componentsJoinedByString:@"；"]];
        }
    }

    NSString *resultBody = [lines componentsJoinedByString:@"\n"];
    if (resultBody.length == 0) {
        return @"";
    }

    return [NSString stringWithFormat:
            @"你是一个\"城市记忆搜索助手\"，需要帮助用户更好地探索内容。\n\n"
            @"请根据【搜索结果】，生成搜索辅助信息。\n\n"
            @"要求：\n"
            @"1. summary：用1段完整自然的中文总结当前搜索结果，尽量写得具体一些，长度控制在90到140字；\n"
            @"2. suggestions：给出3个推荐继续搜索的关键词（中文，英文逗号分隔）；\n"
            @"3. highlights：提取2-3个有代表性的内容点（短句，每条不超过20字）；\n"
            @"4. guide：用1句更自然、更完整的搜索提示引导用户继续探索，长度控制在40到70字；\n"
            @"5. 如果搜索结果较少或内容不集中，请明确说明结果较少，并优先生成扩展搜索建议；\n"
            @"6. 优先关注并提炼城市、地点、时间、情绪、人物、内容主题这些线索；如果结果里出现城市或时间，不要忽略；\n"
            @"7. 如果结果中出现点赞数、评论数、发布时间、作者、图片数量等信息，可以用于辅助概括内容热度和特征；\n"
            @"8. suggestions 尽量围绕城市、地点、时间、情绪或主题做延展，避免只给空泛词；\n"
            @"9. 严禁编造不存在的信息；\n"
            @"10. 输出必须是JSON，不能有任何额外文字或说明。\n\n"
            @"请严格按照以下格式返回：\n\n"
            @"{\n"
            @"  \"summary\": \"较完整的搜索结果总结\",\n"
            @"  \"suggestions\": \"关键词1,关键词2,关键词3\",\n"
            @"  \"highlights\": [\"亮点1\",\"亮点2\"],\n"
            @"  \"guide\": \"一句较完整的搜索提示\"\n"
            @"}\n\n"
            @"请特别注意：如果搜索结果中有城市、时间或情绪信息，summary、highlights 和 guide 应尽量体现这些线索。\n\n"
            @"搜索结果内容：\n%@",
            resultBody];
}

- (void)showPostDetailForSearchContent:(YALSearchContentModel *)item {
    if (![item isKindOfClass:[YALSearchContentModel class]] || item.contentId == nil) {
        return;
    }

    YALPostModel *post = [[YALPostModel alloc] init];
    post.contentId = item.contentId;
    post.title = item.title ?: @"";
    post.desc = item.content ?: @"";
    post.content = item.content ?: @"";
    post.city = item.city ?: @"";
    post.year = item.year ?: @"";
    post.mood = item.mood ?: @"";
    post.images = item.images ?: @[];
    post.imageURLString = item.images.firstObject ?: @"";
    post.likeCount = item.likeCount;
    post.commentCount = item.commentCount;
    post.createTime = item.createdAt ?: @"";
    post.authorUserId = item.userId;
    post.authorNickname = item.authorNickname;
    post.authorAvatar = item.authorAvatar;
    post.authorBio = item.authorBio;

    YALPostDetailController *detailVC = [[YALPostDetailController alloc] init];
    detailVC.post = post;
    detailVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (void)showAuthorProfileForSearchUser:(YALSearchUserModel *)item {
    if (![item isKindOfClass:[YALSearchUserModel class]] || item.userId.integerValue <= 0) {
        return;
    }

    Class profileControllerClass = NSClassFromString(@"YALAuthorProfileController");
    if (![profileControllerClass isSubclassOfClass:[UIViewController class]]) {
        return;
    }

    UIViewController *controller = [[profileControllerClass alloc] init];
    [controller setValue:item.userId forKey:@"userId"];
    if (item.nickname.length > 0) {
        [controller setValue:item.nickname forKey:@"prefilledNickname"];
    }
    if (item.avatar.length > 0) {
        [controller setValue:item.avatar forKey:@"prefilledAvatar"];
    }
    if (item.bio.length > 0) {
        [controller setValue:item.bio forKey:@"prefilledBio"];
    }
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (UIColor *)accentColor {
    return [UIColor colorWithRed:0.98 green:0.49 blue:0.18 alpha:1.0];
}

- (BOOL)shouldShowEmptySearchResult {
    if (!self.isResultPage || self.keyword.length == 0) {
        return NO;
    }
    if (self.currentTab == YALSearchTabTypeContent) {
        return !self.isContentLoading &&
               self.contentErrorText.length == 0 &&
               self.contentResults.count == 0 &&
               ![self hasVisibleAISection];
    }
    return !self.isUserLoading && self.userErrorText.length == 0 && self.userResults.count == 0;
}

- (BOOL)hasContentResultSection {
    return self.contentResults.count > 0;
}

- (BOOL)hasVisibleAISection {
    return self.isAILoading || self.aiResult != nil || self.aiErrorText.length > 0;
}

@end

#pragma mark - Result Card Cell

@interface YALSearchResultCardCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIView *coverShadeView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) UILabel *typeBadgeLabel;
@property (nonatomic, strong) UIView *metaDotView;

@end

@implementation YALSearchResultCardCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        self.cardView = [[UIView alloc] init];
        self.cardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        self.cardView.layer.cornerRadius = 24.0;
        self.cardView.layer.masksToBounds = NO;
        self.cardView.layer.borderWidth = 1.0;
        self.cardView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.78].CGColor;
        self.cardView.layer.shadowColor = [UIColor colorWithRed:0.38 green:0.26 blue:0.18 alpha:1.0].CGColor;
        self.cardView.layer.shadowOpacity = 0.08;
        self.cardView.layer.shadowRadius = 20.0;
        self.cardView.layer.shadowOffset = CGSizeMake(0, 10.0);
        [self.contentView addSubview:self.cardView];

        self.coverImageView = [[UIImageView alloc] init];
        self.coverImageView.backgroundColor = [UIColor colorWithRed:0.95 green:0.92 blue:0.89 alpha:1.0];
        self.coverImageView.layer.cornerRadius = 20.0;
        self.coverImageView.layer.masksToBounds = YES;
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.cardView addSubview:self.coverImageView];

        self.coverShadeView = [[UIView alloc] init];
        self.coverShadeView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.08];
        self.coverShadeView.userInteractionEnabled = NO;
        [self.coverImageView addSubview:self.coverShadeView];

        self.avatarView = [[UIImageView alloc] init];
        self.avatarView.backgroundColor = [UIColor whiteColor];
        self.avatarView.layer.cornerRadius = 18.0;
        self.avatarView.layer.masksToBounds = YES;
        self.avatarView.layer.borderWidth = 2.0;
        self.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
        [self.cardView addSubview:self.avatarView];

        self.typeBadgeLabel = [[UILabel alloc] init];
        self.typeBadgeLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold];
        self.typeBadgeLabel.textAlignment = NSTextAlignmentCenter;
        self.typeBadgeLabel.layer.cornerRadius = 12.0;
        self.typeBadgeLabel.layer.masksToBounds = YES;
        [self.cardView addSubview:self.typeBadgeLabel];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
        self.titleLabel.numberOfLines = 2;
        self.titleLabel.textColor = [UIColor labelColor];
        [self.cardView addSubview:self.titleLabel];

        self.usernameLabel = [[UILabel alloc] init];
        self.usernameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
        self.usernameLabel.textColor = [UIColor colorWithRed:0.46 green:0.40 blue:0.36 alpha:1.0];
        self.usernameLabel.numberOfLines = 1;
        [self.cardView addSubview:self.usernameLabel];

        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
        self.subtitleLabel.textColor = [UIColor colorWithRed:0.34 green:0.31 blue:0.28 alpha:1.0];
        self.subtitleLabel.numberOfLines = 2;
        [self.cardView addSubview:self.subtitleLabel];

        self.metaLabel = [[UILabel alloc] init];
        self.metaLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightSemibold];
        self.metaLabel.textColor = [UIColor colorWithRed:0.86 green:0.45 blue:0.19 alpha:1.0];
        self.metaLabel.numberOfLines = 2;
        [self.cardView addSubview:self.metaLabel];

        self.metaDotView = [[UIView alloc] init];
        self.metaDotView.backgroundColor = [UIColor colorWithRed:0.97 green:0.56 blue:0.26 alpha:1.0];
        self.metaDotView.layer.cornerRadius = 3.0;
        self.metaDotView.layer.masksToBounds = YES;
        [self.cardView addSubview:self.metaDotView];

        [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6.0, 16.0, 8.0, 16.0));
        }];
        [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(self.cardView).offset(14.0);
            make.width.mas_equalTo(96.0);
            make.height.mas_equalTo(108.0);
            make.bottom.lessThanOrEqualTo(self.cardView).offset(-16.0);
        }];
        [self.coverShadeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.coverImageView);
        }];
        [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(36.0);
            make.left.equalTo(self.coverImageView).offset(8.0);
            make.bottom.equalTo(self.coverImageView).offset(-8.0);
        }];
        [self.typeBadgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(14.0);
            make.right.equalTo(self.cardView).offset(-14.0);
            make.height.mas_equalTo(24.0);
            make.width.mas_greaterThanOrEqualTo(50.0);
        }];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(16.0);
            make.left.equalTo(self.coverImageView.mas_right).offset(14.0);
            make.right.lessThanOrEqualTo(self.typeBadgeLabel.mas_left).offset(-8.0);
        }];
        [self.usernameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(6.0);
            make.left.equalTo(self.titleLabel);
            make.right.equalTo(self.cardView).offset(-14.0);
        }];
        [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.usernameLabel.mas_bottom).offset(8.0);
            make.left.equalTo(self.titleLabel);
            make.right.equalTo(self.cardView).offset(-14.0);
        }];
        [self.metaDotView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.titleLabel);
            make.top.equalTo(self.subtitleLabel.mas_bottom).offset(12.0);
            make.width.height.mas_equalTo(6.0);
        }];
        [self.metaLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.metaDotView.mas_right).offset(8.0);
            make.centerY.equalTo(self.metaDotView);
            make.right.equalTo(self.cardView).offset(-14.0);
            make.bottom.lessThanOrEqualTo(self.cardView).offset(-16.0);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.coverImageView sd_cancelCurrentImageLoad];
    [self.avatarView sd_cancelCurrentImageLoad];
}

- (void)configureWithTitle:(NSString *)title
                  username:(NSString *)username
                  subtitle:(NSString *)subtitle
                      meta:(NSString *)meta
                  coverURL:(NSString *)coverURL
                 avatarURL:(NSString *)avatarURL
                    isUser:(BOOL)isUser {
    self.titleLabel.text = title.length > 0 ? title : @"未命名";
    self.usernameLabel.text = username.length > 0 ? username : @"@memory-city";
    self.subtitleLabel.text = subtitle.length > 0 ? subtitle : @"";
    self.metaLabel.text = meta.length > 0 ? meta : @"";

    self.typeBadgeLabel.text = isUser ? @"用户" : @"内容";
    self.typeBadgeLabel.textColor = isUser ? [UIColor colorWithRed:0.18 green:0.48 blue:0.92 alpha:1.0] : [UIColor colorWithRed:0.93 green:0.44 blue:0.16 alpha:1.0];
    self.typeBadgeLabel.backgroundColor = isUser ? [[UIColor colorWithRed:0.18 green:0.48 blue:0.92 alpha:1.0] colorWithAlphaComponent:0.10] : [[UIColor colorWithRed:0.93 green:0.44 blue:0.16 alpha:1.0] colorWithAlphaComponent:0.10];

    UIImage *coverPlaceholder = [self placeholderImageNamed:isUser ? @"person.crop.square" : @"photo.on.rectangle"];
    UIImage *avatarPlaceholder = [self placeholderImageNamed:@"person.crop.circle.fill"];
    [self loadImageOn:self.coverImageView withURLString:coverURL placeholder:coverPlaceholder];
    [self loadImageOn:self.avatarView withURLString:avatarURL placeholder:avatarPlaceholder];
}

- (void)loadImageOn:(UIImageView *)imageView withURLString:(NSString *)urlString placeholder:(UIImage *)placeholder {
    imageView.image = placeholder;
    NSURL *url = [NSURL URLWithString:urlString ?: @""];
    if (url && url.scheme.length > 0) {
        [imageView sd_setImageWithURL:url
                     placeholderImage:placeholder
                              options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
    }
}

- (UIImage *)placeholderImageNamed:(NSString *)name {
    if (@available(iOS 13.0, *)) {
        UIImage *image = [UIImage systemImageNamed:name];
        return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return [[UIImage alloc] init];
}

@end

#pragma mark - AI Cell

@interface YALSearchAIResultCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *badgeLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UILabel *tagsLabel;
@property (nonatomic, strong) UILabel *highlightsLabel;
@property (nonatomic, strong) UILabel *suggestionsLabel;
@property (nonatomic, strong) UILabel *guideLabel;
@property (nonatomic, strong) UIView *topAccentBar;
@property (nonatomic, strong) UIView *glowBubble;
@property (nonatomic, assign) NSUInteger streamingGeneration;

@end

@implementation YALSearchAIResultCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        self.cardView = [[UIView alloc] init];
        self.cardView.backgroundColor = [UIColor colorWithRed:1.0 green:0.98 blue:0.95 alpha:1.0];
        self.cardView.layer.cornerRadius = 28.0;
        self.cardView.layer.masksToBounds = NO;
        self.cardView.layer.borderWidth = 1.0;
        self.cardView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.78].CGColor;
        self.cardView.layer.shadowColor = [UIColor colorWithRed:0.60 green:0.35 blue:0.16 alpha:1.0].CGColor;
        self.cardView.layer.shadowOpacity = 0.10;
        self.cardView.layer.shadowRadius = 24.0;
        self.cardView.layer.shadowOffset = CGSizeMake(0, 12.0);
        [self.contentView addSubview:self.cardView];

        self.glowBubble = [[UIView alloc] init];
        self.glowBubble.backgroundColor = [[UIColor colorWithRed:1.0 green:0.70 blue:0.42 alpha:1.0] colorWithAlphaComponent:0.18];
        self.glowBubble.layer.cornerRadius = 56.0;
        [self.cardView addSubview:self.glowBubble];

        self.topAccentBar = [[UIView alloc] init];
        self.topAccentBar.backgroundColor = [UIColor colorWithRed:0.97 green:0.56 blue:0.24 alpha:1.0];
        self.topAccentBar.layer.cornerRadius = 2.0;
        [self.cardView addSubview:self.topAccentBar];

        self.badgeLabel = [[UILabel alloc] init];
        self.badgeLabel.text = @"AI 搜索";
        self.badgeLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold];
        self.badgeLabel.textColor = [UIColor colorWithRed:0.92 green:0.41 blue:0.11 alpha:1.0];
        self.badgeLabel.backgroundColor = [[UIColor colorWithRed:0.92 green:0.41 blue:0.11 alpha:1.0] colorWithAlphaComponent:0.10];
        self.badgeLabel.textAlignment = NSTextAlignmentCenter;
        self.badgeLabel.layer.cornerRadius = 10.0;
        self.badgeLabel.layer.masksToBounds = YES;
        [self.cardView addSubview:self.badgeLabel];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
        self.titleLabel.numberOfLines = 2;
        self.titleLabel.textColor = [UIColor labelColor];
        [self.cardView addSubview:self.titleLabel];

        self.summaryLabel = [[UILabel alloc] init];
        self.summaryLabel.font = [UIFont systemFontOfSize:14.5 weight:UIFontWeightRegular];
        self.summaryLabel.textColor = [UIColor colorWithRed:0.32 green:0.28 blue:0.25 alpha:1.0];
        self.summaryLabel.numberOfLines = 0;

        self.tagsLabel = [[UILabel alloc] init];
        self.tagsLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightSemibold];
        self.tagsLabel.textColor = [UIColor secondaryLabelColor];
        self.tagsLabel.numberOfLines = 0;

        self.highlightsLabel = [[UILabel alloc] init];
        self.highlightsLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightMedium];
        self.highlightsLabel.textColor = [UIColor colorWithRed:0.45 green:0.36 blue:0.28 alpha:1.0];
        self.highlightsLabel.numberOfLines = 0;

        self.suggestionsLabel = [[UILabel alloc] init];
        self.suggestionsLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightSemibold];
        self.suggestionsLabel.textColor = [UIColor colorWithRed:0.86 green:0.45 blue:0.19 alpha:1.0];
        self.suggestionsLabel.numberOfLines = 0;

        self.guideLabel = [[UILabel alloc] init];
        self.guideLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightRegular];
        self.guideLabel.textColor = [UIColor colorWithRed:0.38 green:0.33 blue:0.29 alpha:1.0];
        self.guideLabel.numberOfLines = 0;

        self.contentStack = [[UIStackView alloc] initWithArrangedSubviews:@[
            self.summaryLabel,
            self.tagsLabel,
            self.highlightsLabel,
            self.suggestionsLabel,
            self.guideLabel
        ]];
        self.contentStack.axis = UILayoutConstraintAxisVertical;
        self.contentStack.spacing = 10.0;
        self.contentStack.alignment = UIStackViewAlignmentFill;
        self.contentStack.distribution = UIStackViewDistributionFill;
        [self.cardView addSubview:self.contentStack];

        [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(10.0);
            make.left.equalTo(self.contentView).offset(16.0);
            make.right.equalTo(self.contentView).offset(-16.0);
            make.bottom.lessThanOrEqualTo(self.contentView).offset(-6.0);
        }];
        [self.glowBubble mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(-18.0);
            make.right.equalTo(self.cardView).offset(24.0);
            make.width.height.mas_equalTo(112.0);
        }];
        [self.topAccentBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(18.0);
            make.left.equalTo(self.cardView).offset(18.0);
            make.width.mas_equalTo(42.0);
            make.height.mas_equalTo(4.0);
        }];
        [self.badgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.cardView).offset(18.0);
            make.top.equalTo(self.topAccentBar.mas_bottom).offset(14.0);
            make.height.mas_equalTo(20.0);
            make.width.mas_equalTo(58.0);
        }];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.badgeLabel.mas_bottom).offset(12.0);
            make.left.equalTo(self.badgeLabel);
            make.right.equalTo(self.cardView).offset(-18.0);
        }];
        [self.contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(10.0);
            make.left.equalTo(self.badgeLabel);
            make.right.equalTo(self.cardView).offset(-18.0);
            make.bottom.lessThanOrEqualTo(self.cardView).offset(-18.0);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self cancelStreaming];
    [self resetContentVisibility];
}

- (void)configureWithKeyword:(NSString *)keyword
                      result:(YALAIAnalyzeResultModel *)result
                     loading:(BOOL)loading
                   errorText:(NSString *)errorText {
    self.titleLabel.text = [NSString stringWithFormat:@"关于“%@”的 AI 搜索结论", keyword.length > 0 ? keyword : @"当前搜索"];
    [self cancelStreaming];
    [self resetContentVisibility];

    if (loading) {
        self.summaryLabel.text = @"AI 正在整理与你搜索最相关的内容、语义和情绪倾向，请稍候片刻。";
        self.tagsLabel.text = @"";
        self.highlightsLabel.text = @"";
        self.suggestionsLabel.text = @"";
        self.guideLabel.text = @"";
        [self updateVisibilityForLabel:self.summaryLabel];
        [self updateVisibilityForLabel:self.tagsLabel];
        [self updateVisibilityForLabel:self.highlightsLabel];
        [self updateVisibilityForLabel:self.suggestionsLabel];
        [self updateVisibilityForLabel:self.guideLabel];
        return;
    }

    if (result != nil) {
        NSString *summaryText = result.summary.length > 0 ? result.summary : @"AI 已完成搜索理解，当前关键词已经匹配到相关内容。";
        NSString *highlightsText = result.highlights.count > 0 ? [NSString stringWithFormat:@"亮点：%@", [result.highlights componentsJoinedByString:@" · "]] : @"亮点：暂无";
        NSString *suggestionsText = result.suggestions.length > 0 ? [NSString stringWithFormat:@"推荐搜索：%@", result.suggestions] : @"推荐搜索：暂无";
        NSString *guideText = result.guide.length > 0 ? [NSString stringWithFormat:@"搜索提示：%@", result.guide] : @"搜索提示：可以继续从地点、情绪、人物或时间线索展开搜索。";
        self.tagsLabel.text = result.tags.count > 0 ? [NSString stringWithFormat:@"关键词：%@", [result.tags componentsJoinedByString:@" · "]] : @"";
        self.summaryLabel.text = @"";
        self.highlightsLabel.text = @"";
        self.suggestionsLabel.text = @"";
        self.guideLabel.text = @"";
        [self updateVisibilityForLabel:self.tagsLabel];
        [self startStreamingWithSummaryText:summaryText highlightsText:highlightsText suggestionsText:suggestionsText guideText:guideText];
        return;
    }

    self.summaryLabel.text = errorText.length > 0 ? errorText : @"AI 分析暂时不可用，但你仍然可以查看下方内容结果。";
    self.tagsLabel.text = @"";
    self.highlightsLabel.text = @"亮点：暂不可用";
    self.suggestionsLabel.text = @"推荐搜索：暂不可用";
    self.guideLabel.text = @"搜索提示：你仍然可以结合当前结果继续细化搜索。";
    [self updateVisibilityForLabel:self.summaryLabel];
    [self updateVisibilityForLabel:self.tagsLabel];
    [self updateVisibilityForLabel:self.highlightsLabel];
    [self updateVisibilityForLabel:self.suggestionsLabel];
    [self updateVisibilityForLabel:self.guideLabel];
}

- (void)startStreamingWithSummaryText:(NSString *)summaryText
                       highlightsText:(NSString *)highlightsText
                      suggestionsText:(NSString *)suggestionsText
                            guideText:(NSString *)guideText {
    [self cancelStreaming];
    self.summaryLabel.alpha = 0.0;
    self.highlightsLabel.alpha = 0.0;
    self.suggestionsLabel.alpha = 0.0;
    self.guideLabel.alpha = 0.0;
    [self updateVisibilityForLabel:self.summaryLabel];
    [self updateVisibilityForLabel:self.highlightsLabel];
    [self updateVisibilityForLabel:self.suggestionsLabel];
    [self updateVisibilityForLabel:self.guideLabel];

    NSUInteger generation = ++self.streamingGeneration;
    [self revealLabel:self.summaryLabel withText:summaryText delay:0.00 generation:generation];
    [self revealLabel:self.highlightsLabel withText:highlightsText delay:0.32 generation:generation];
    [self revealLabel:self.suggestionsLabel withText:suggestionsText delay:0.64 generation:generation];
    [self revealLabel:self.guideLabel withText:guideText delay:0.96 generation:generation];
}

- (void)revealLabel:(UILabel *)label
           withText:(NSString *)text
              delay:(NSTimeInterval)delay
         generation:(NSUInteger)generation {
    NSString *safeText = text ?: @"";
    if (safeText.length == 0 || label == nil) {
        label.text = @"";
        [self updateVisibilityForLabel:label];
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.streamingGeneration != generation) {
            return;
        }
        label.text = safeText;
        label.hidden = NO;
        [UIView animateWithDuration:0.22 animations:^{
            label.alpha = 1.0;
        }];
    });
}

- (void)cancelStreaming {
    self.streamingGeneration += 1;
}

- (void)resetContentVisibility {
    self.summaryLabel.alpha = 1.0;
    self.tagsLabel.alpha = 1.0;
    self.highlightsLabel.alpha = 1.0;
    self.suggestionsLabel.alpha = 1.0;
    self.guideLabel.alpha = 1.0;
    self.summaryLabel.hidden = NO;
    self.tagsLabel.hidden = YES;
    self.highlightsLabel.hidden = YES;
    self.suggestionsLabel.hidden = YES;
    self.guideLabel.hidden = YES;
}

- (void)updateVisibilityForLabel:(UILabel *)label {
    if (label == nil) {
        return;
    }
    NSString *text = label.text ?: @"";
    label.hidden = (text.length == 0);
}

@end
