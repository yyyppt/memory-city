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
#import "../../Network/Manager/YALNetworkManager.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

typedef NS_ENUM(NSInteger, YALSearchTabType) {
    YALSearchTabTypeContent = 0,
    YALSearchTabTypeUser = 1
};

static UIColor *YALSearchPageBackgroundColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor systemBackgroundColor];
            }
            return [UIColor colorWithRed:0.98 green:0.97 blue:0.95 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.98 green:0.97 blue:0.95 alpha:1.0];
}

static UIColor *YALSearchSegmentBackgroundColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor tertiarySystemBackgroundColor];
            }
            return [[UIColor whiteColor] colorWithAlphaComponent:0.86];
        }];
    }
    return [[UIColor whiteColor] colorWithAlphaComponent:0.86];
}

static UIColor *YALSearchCardBackgroundColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor secondarySystemBackgroundColor];
            }
            return [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        }];
    }
    return [[UIColor whiteColor] colorWithAlphaComponent:0.92];
}

static UIColor *YALSearchAICardBackgroundColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor secondarySystemBackgroundColor];
            }
            return [UIColor colorWithRed:1.0 green:0.98 blue:0.95 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:1.0 green:0.98 blue:0.95 alpha:1.0];
}

static UIColor *YALSearchSoftCardBorderColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor separatorColor];
    }
    return [[UIColor whiteColor] colorWithAlphaComponent:0.78];
}

static UIColor *YALSearchSecondaryTextColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    }
    return [UIColor colorWithRed:0.45 green:0.40 blue:0.36 alpha:1.0];
}

static UIColor *YALSearchBodyTextColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor secondaryLabelColor];
            }
            return [UIColor colorWithRed:0.32 green:0.28 blue:0.25 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.32 green:0.28 blue:0.25 alpha:1.0];
}

static UIImage * _Nullable YALSearchImageFromDataURLString(NSString * _Nullable dataURL) {
    if (![dataURL isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *trimmed = [dataURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![trimmed hasPrefix:@"data:image"]) {
        return nil;
    }
    NSRange commaRange = [trimmed rangeOfString:@","];
    if (commaRange.location == NSNotFound || commaRange.location + 1 >= trimmed.length) {
        return nil;
    }
    NSString *base64Part = [trimmed substringFromIndex:commaRange.location + 1];
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64Part options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (imageData.length == 0) {
        return nil;
    }
    return [UIImage imageWithData:imageData];
}

static NSURL * _Nullable YALSearchResolvedImageURL(NSString * _Nullable urlString) {
    if (![urlString isKindOfClass:[NSString class]]) {
        return nil;
    }

    NSString *trimmed = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }

    NSURL *url = [NSURL URLWithString:trimmed];
    if (url.scheme.length > 0) {
        return url;
    }

    NSString *baseURLString = YALAPIRootURLString;
    if (baseURLString.length == 0) {
        return nil;
    }

    NSURL *baseURL = [NSURL URLWithString:baseURLString];
    if (!baseURL) {
        return nil;
    }

    if ([trimmed hasPrefix:@"/"]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:baseURL resolvingAgainstBaseURL:NO];
        if (components.path.length == 0) {
            components.path = trimmed;
        } else {
            components.path = trimmed;
        }
        components.query = nil;
        components.fragment = nil;
        return components.URL;
    }

    return [NSURL URLWithString:trimmed relativeToURL:baseURL].absoluteURL;
}

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

    self.view.backgroundColor = YALSearchPageBackgroundColor();
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
    self.segmentedControl.backgroundColor = YALSearchSegmentBackgroundColor();
    self.segmentedControl.selectedSegmentTintColor = [self accentColor];
    self.segmentedControl.layer.cornerRadius = 18.0;
    self.segmentedControl.layer.masksToBounds = YES;
    [self.segmentedControl setTitleTextAttributes:@{
        NSForegroundColorAttributeName: YALSearchSecondaryTextColor(),
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
    NSString *resultText = [self aiAnalysisPromptFromCurrentResults];
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
        NSInteger sections = 0;
        if ([self hasVisibleAISection]) {
            sections += 1;
        }
        if ([self hasContentResultSection]) {
            sections += 1;
        }
        return sections;
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
        if ([self hasVisibleAISection] && section == 0) {
            return 1;
        }
        return self.contentResults.count;
    }
    if ([self shouldShowEmptySearchResult]) {
        return 0;
    }
    return self.userResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (self.currentTab == YALSearchTabTypeContent && [self hasVisibleAISection] && indexPath.section == 0) {
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

    NSInteger contentSection = [self hasVisibleAISection] ? 1 : 0;
    if (indexPath.section != contentSection || indexPath.row >= self.contentResults.count) {
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

- (NSString *)processedKeywordForAIAnalysis {
    NSString *trimmedKeyword = [self.keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedKeyword.length == 0) {
        return @"当前搜索，请先做简洁介绍，再结合站内结果总结";
    }
    return [NSString stringWithFormat:@"%@，请先做简洁介绍，再结合站内结果总结", trimmedKeyword];
}

- (BOOL)isLikelyLocationKeyword:(NSString *)keyword {
    NSString *trimmedKeyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedKeyword.length == 0) {
        return NO;
    }

    NSArray<NSString *> *locationSuffixes = @[@"市", @"区", @"县", @"镇", @"乡", @"村", @"省", @"路", @"街", @"巷", @"胡同", @"湾", @"湖", @"山", @"江", @"河", @"园", @"宫", @"站", @"机场", @"大学", @"公园", @"广场", @"地铁站", @"博物馆"];
    for (NSString *suffix in locationSuffixes) {
        if ([trimmedKeyword hasSuffix:suffix]) {
            return YES;
        }
    }

    NSSet<NSString *> *commonLocations = [NSSet setWithArray:@[@"北京", @"上海", @"广州", @"深圳", @"杭州", @"南京", @"苏州", @"成都", @"重庆", @"武汉", @"西安", @"天津", @"长沙", @"青岛", @"厦门", @"香港", @"澳门", @"台北"]];
    if ([commonLocations containsObject:trimmedKeyword]) {
        return YES;
    }

    for (YALSearchContentModel *item in self.contentResults) {
        if (![item isKindOfClass:[YALSearchContentModel class]]) {
            continue;
        }
        if (item.city.length > 0 && [item.city isEqualToString:trimmedKeyword]) {
            return YES;
        }
    }

    return NO;
}

- (NSString *)aiAnalysisPromptFromCurrentResults {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    NSString *processedKeyword = [self processedKeywordForAIAnalysis];
    NSString *originalKeyword = [self.keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL isLikelyLocationKeyword = [self isLikelyLocationKeyword:originalKeyword];

    if (originalKeyword.length > 0) {
        [lines addObject:[NSString stringWithFormat:@"原始搜索词：%@", originalKeyword]];
    }
    [lines addObject:[NSString stringWithFormat:@"搜索词类型：%@", isLikelyLocationKeyword ? @"地点/地名倾向" : @"普通主题词"]];
    [lines addObject:[NSString stringWithFormat:@"AI加工搜索词：%@", processedKeyword]];
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
            @"请结合【搜索词】和【搜索结果】，生成偏“百科介绍”风格的搜索辅助信息。\n\n"
            @"要求：\n"
            @"1. summary：用不超过90字输出。默认结构是“先介绍搜索词本身，再概括站内结果”；如果搜索词是地点、城市、景点、街区、地标等地名，开头必须先给出像百科导语一样的地点介绍，再补充站内搜到的内容方向；\n"
            @"2. suggestions：给出3个推荐继续搜索的关键词（中文，英文逗号分隔）；\n"
            @"3. highlights：提取2-3个有代表性的内容点（短句，每条不超过20字）；如果是地点词，前1-2条优先写地点本身的定位、特征、历史文化、城市角色、知名标签，再写站内内容线索；\n"
            @"4. guide：用一句话引导用户继续探索，不超过40字；如果是地点词，优先引导用户继续搜它的历史、街区、地标、美食、生活记忆；\n"
            @"5. 如果搜索词明显是地点词，而站内结果只是零散动态，也必须补一小段该地点的基础介绍，不能只复述搜索结果；\n"
            @"6. 如果搜索结果较少、内容不集中，或用户的问题本身更像常识问答，请优先基于【搜索词】给出简洁清晰的解释，再补充\"扩展搜索建议\"；\n"
            @"7. 优先使用【搜索结果】里的事实；当搜索结果不足时，可以结合【搜索词】做稳定、常识性的通用解释，但不要捏造具体人物、地点、事件细节，也不要写未经验证的冷门数据；\n"
            @"8. 整体语气更像百科导语或旅游目的地简介，不要只写“搜索结果包含了什么”；\n"
            @"9. 如果站内结果与地点关联较弱，也要优先保证地点介绍有信息量；\n"
            @"10. 输出必须是JSON，不能有任何额外文字或说明。\n\n"
            @"请严格按照以下格式返回：\n\n"
            @"{\n"
            @"  \"summary\": \"搜索结果总结\",\n"
            @"  \"suggestions\": \"关键词1,关键词2,关键词3\",\n"
            @"  \"highlights\": [\"亮点1\",\"亮点2\"],\n"
            @"  \"guide\": \"一句探索引导\"\n"
            @"}\n\n"
            @"特别注意：如果搜索词是“北京”“上海”这类地点词，summary 不能只写“搜索结果主要包含相关内容”，而应该像“北京是中国的首都，也是历史文化名城……”这样先做地点介绍，再概括站内内容。\n\n"
            @"搜索词：%@\n\n"
            @"搜索结果内容：\n%@",
            processedKeyword,
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
        self.cardView.backgroundColor = YALSearchCardBackgroundColor();
        self.cardView.layer.cornerRadius = 24.0;
        self.cardView.layer.masksToBounds = NO;
        self.cardView.layer.borderWidth = 1.0;
        self.cardView.layer.borderColor = YALSearchSoftCardBorderColor().CGColor;
        self.cardView.layer.shadowColor = [UIColor colorWithRed:0.38 green:0.26 blue:0.18 alpha:1.0].CGColor;
        self.cardView.layer.shadowOpacity = 0.08;
        self.cardView.layer.shadowRadius = 20.0;
        self.cardView.layer.shadowOffset = CGSizeMake(0, 10.0);
        [self.contentView addSubview:self.cardView];

        self.coverImageView = [[UIImageView alloc] init];
        self.coverImageView.backgroundColor = [UIColor secondarySystemBackgroundColor];
        self.coverImageView.layer.cornerRadius = 20.0;
        self.coverImageView.layer.masksToBounds = YES;
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.cardView addSubview:self.coverImageView];

        self.coverShadeView = [[UIView alloc] init];
        self.coverShadeView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.08];
        self.coverShadeView.userInteractionEnabled = NO;
        [self.coverImageView addSubview:self.coverShadeView];

        self.avatarView = [[UIImageView alloc] init];
        self.avatarView.backgroundColor = [UIColor systemBackgroundColor];
        self.avatarView.layer.cornerRadius = 18.0;
        self.avatarView.layer.masksToBounds = YES;
        self.avatarView.layer.borderWidth = 2.0;
        self.avatarView.layer.borderColor = [UIColor systemBackgroundColor].CGColor;
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
        self.usernameLabel.textColor = YALSearchSecondaryTextColor();
        self.usernameLabel.numberOfLines = 1;
        [self.cardView addSubview:self.usernameLabel];

        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
        self.subtitleLabel.textColor = YALSearchBodyTextColor();
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
    self.avatarView.hidden = !isUser;

    UIImage *coverPlaceholder = [self placeholderImageNamed:isUser ? @"person.crop.square" : @"photo.on.rectangle"];
    UIImage *avatarPlaceholder = [self placeholderImageNamed:@"person.crop.circle.fill"];
    [self loadImageOn:self.coverImageView withURLString:coverURL placeholder:coverPlaceholder];
    if (isUser) {
        [self loadImageOn:self.avatarView withURLString:avatarURL placeholder:avatarPlaceholder];
    } else {
        [self.avatarView sd_cancelCurrentImageLoad];
        self.avatarView.image = nil;
    }
}

- (void)loadImageOn:(UIImageView *)imageView withURLString:(NSString *)urlString placeholder:(UIImage *)placeholder {
    [imageView sd_cancelCurrentImageLoad];
    imageView.image = placeholder;
    UIImage *decodedImage = YALSearchImageFromDataURLString(urlString);
    if (decodedImage) {
        imageView.image = decodedImage;
        return;
    }

    NSURL *url = YALSearchResolvedImageURL(urlString);
    if (url) {
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
@property (nonatomic, assign) NSTimeInterval streamingCharacterInterval;
@property (nonatomic, assign) NSUInteger streamedCharacterCount;

@end

@implementation YALSearchAIResultCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        self.cardView = [[UIView alloc] init];
        self.cardView.backgroundColor = YALSearchAICardBackgroundColor();
        self.cardView.layer.cornerRadius = 28.0;
        self.cardView.layer.masksToBounds = NO;
        self.cardView.layer.borderWidth = 1.0;
        self.cardView.layer.borderColor = YALSearchSoftCardBorderColor().CGColor;
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
        self.summaryLabel.textColor = YALSearchBodyTextColor();
        self.summaryLabel.numberOfLines = 0;

        self.tagsLabel = [[UILabel alloc] init];
        self.tagsLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightSemibold];
        self.tagsLabel.textColor = [UIColor secondaryLabelColor];
        self.tagsLabel.numberOfLines = 0;

        self.highlightsLabel = [[UILabel alloc] init];
        self.highlightsLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightMedium];
        self.highlightsLabel.textColor = YALSearchSecondaryTextColor();
        self.highlightsLabel.numberOfLines = 0;

        self.suggestionsLabel = [[UILabel alloc] init];
        self.suggestionsLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightSemibold];
        self.suggestionsLabel.textColor = [UIColor colorWithRed:0.86 green:0.45 blue:0.19 alpha:1.0];
        self.suggestionsLabel.numberOfLines = 0;

        self.guideLabel = [[UILabel alloc] init];
        self.guideLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightRegular];
        self.guideLabel.textColor = YALSearchSecondaryTextColor();
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
        self.streamingCharacterInterval = 0.06;

        [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(10.0);
            make.left.equalTo(self.contentView).offset(16.0);
            make.right.equalTo(self.contentView).offset(-16.0);
            make.bottom.equalTo(self.contentView).offset(-6.0);
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
            make.bottom.equalTo(self.cardView).offset(-18.0);
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
        self.summaryLabel.text = @"AI 正在补充地点介绍并整理站内相关内容，请稍候片刻。";
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
        NSString *suggestionsText = result.suggestions.length > 0 ? [NSString stringWithFormat:@"推荐搜索：%@", result.suggestions] : @"";
        NSString *guideText = result.guide.length > 0 ? [NSString stringWithFormat:@"搜索提示：%@", result.guide] : @"搜索提示：可以继续从地点、情绪、人物或时间线索展开搜索。";
        self.tagsLabel.text = result.tags.count > 0 ? [NSString stringWithFormat:@"关键词：%@", [result.tags componentsJoinedByString:@" · "]] : @"";
        self.summaryLabel.text = summaryText;
        self.highlightsLabel.text = highlightsText;
        self.suggestionsLabel.text = suggestionsText;
        self.guideLabel.text = guideText;
        [self updateVisibilityForLabel:self.summaryLabel];
        [self updateVisibilityForLabel:self.tagsLabel];
        [self updateVisibilityForLabel:self.highlightsLabel];
        [self updateVisibilityForLabel:self.suggestionsLabel];
        [self updateVisibilityForLabel:self.guideLabel];
        [self startStreaming];
        return;
    }

    self.summaryLabel.text = errorText.length > 0 ? errorText : @"AI 分析暂时不可用，但你仍然可以查看下方内容结果。";
    self.tagsLabel.text = @"";
    self.highlightsLabel.text = @"亮点：暂不可用";
    self.suggestionsLabel.text = @"";
    self.guideLabel.text = @"搜索提示：你仍然可以结合当前结果继续细化搜索。";
    [self updateVisibilityForLabel:self.summaryLabel];
    [self updateVisibilityForLabel:self.tagsLabel];
    [self updateVisibilityForLabel:self.highlightsLabel];
    [self updateVisibilityForLabel:self.suggestionsLabel];
    [self updateVisibilityForLabel:self.guideLabel];
}

- (void)startStreaming {
    [self cancelStreaming];
    self.streamedCharacterCount = 0;
    NSUInteger generation = ++self.streamingGeneration;
    [self streamLabel:self.summaryLabel delay:0.00 generation:generation];
    [self streamLabel:self.highlightsLabel delay:0.28 generation:generation];
    [self streamLabel:self.suggestionsLabel delay:0.56 generation:generation];
    [self streamLabel:self.guideLabel delay:0.84 generation:generation];
}

- (void)streamLabel:(UILabel *)label
              delay:(NSTimeInterval)delay
         generation:(NSUInteger)generation {
    if (label == nil || label.hidden) {
        return;
    }

    NSString *fullText = label.text ?: @"";
    if (fullText.length == 0) {
        return;
    }

    label.alpha = 1.0;
    label.text = @"";
    [self layoutIfNeeded];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.streamingGeneration != generation) {
            return;
        }
        [self appendCharactersForLabel:label
                              fromText:fullText
                                 index:0
                            generation:generation];
    });
}

- (void)appendCharactersForLabel:(UILabel *)label
                        fromText:(NSString *)fullText
                           index:(NSUInteger)index
                      generation:(NSUInteger)generation {
    if (self.streamingGeneration != generation || label == nil || fullText.length == 0) {
        return;
    }

    __block NSUInteger currentCharacterIndex = 0;
    __block NSString *nextText = nil;
    __block BOOL appended = NO;
    [fullText enumerateSubstringsInRange:NSMakeRange(0, fullText.length)
                                 options:NSStringEnumerationByComposedCharacterSequences
                              usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        (void)substringRange;
        (void)enclosingRange;
        if (currentCharacterIndex == index) {
            nextText = [fullText substringToIndex:NSMaxRange(substringRange)];
            appended = YES;
            *stop = YES;
            return;
        }
        currentCharacterIndex += 1;
    }];

    if (!appended) {
        label.text = fullText;
        [self refreshContainingTableViewLayout];
        return;
    }

    label.text = nextText;
    self.streamedCharacterCount += 1;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    if (self.streamedCharacterCount % 2 == 0 || index == 0) {
        [self refreshContainingTableViewLayout];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.streamingCharacterInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.streamingGeneration != generation) {
            return;
        }
        [self appendCharactersForLabel:label
                              fromText:fullText
                                 index:index + 1
                            generation:generation];
    });
}

- (void)cancelStreaming {
    self.streamingGeneration += 1;
}

- (UITableView *)containingTableView {
    UIView *view = self.superview;
    while (view != nil && ![view isKindOfClass:[UITableView class]]) {
        view = view.superview;
    }
    return (UITableView *)view;
}

- (void)refreshContainingTableViewLayout {
    UITableView *tableView = [self containingTableView];
    if (tableView == nil) {
        return;
    }

    [UIView performWithoutAnimation:^{
        [tableView beginUpdates];
        [tableView endUpdates];
    }];
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
