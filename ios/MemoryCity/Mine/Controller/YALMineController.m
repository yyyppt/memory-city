//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//
#import "YALMineController.h"
#import "YALMineView.h"
#import "YALMineProfileModel.h"
#import "YALMineSettingsController.h"
#import "YALMemoryController.h"
#import "YALMapController.h"
#import "YALMessageController.h"
#import "YALReleaseController.h"
#import "YALLoginController.h"
#import "YALAuthManager.h"
#import <UserNotifications/UserNotifications.h>

static NSString * const kYALAppAppearanceStyleKey = @"YALAppAppearanceStyle";

typedef NS_ENUM(NSInteger, YALMinePostStatus) {
    YALMinePostStatusPublic = 0,
    YALMinePostStatusPrivate = 1,
    YALMinePostStatusDraft = 2
};

typedef NS_ENUM(NSInteger, YALMinePostsFilter) {
    YALMinePostsFilterAll = 0,
    YALMinePostsFilterPublic = 1,
    YALMinePostsFilterPrivate = 2,
    YALMinePostsFilterDraft = 3
};

@interface YALMineManagedPost : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, assign) YALMinePostStatus status;

+ (instancetype)postWithTitle:(NSString *)title
                      summary:(NSString *)summary
                        status:(YALMinePostStatus)status;

@end

@implementation YALMineManagedPost

+ (instancetype)postWithTitle:(NSString *)title
                      summary:(NSString *)summary
                        status:(YALMinePostStatus)status {
    YALMineManagedPost *post = [[YALMineManagedPost alloc] init];
    post.title = title;
    post.summary = summary;
    post.status = status;
    return post;
}

@end

@interface YALMinePublishedController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<YALMineManagedPost *> *allPosts;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign) YALMinePostsFilter filter;

- (instancetype)initWithFilter:(YALMinePostsFilter)filter;

@end

@implementation YALMinePublishedController

- (instancetype)initWithFilter:(YALMinePostsFilter)filter {
    self = [super init];
    if (self) {
        _filter = filter;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self titleForFilter:self.filter];
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.allPosts = [[self demoPosts] mutableCopy];
    [self buildTableView];
    [self buildEmptyState];
    [self updateEmptyState];
}

- (void)buildTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 76.0;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
}

- (void)buildEmptyState {
    self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.emptyLabel.text = [NSString stringWithFormat:@"还没有“%@”内容", [self titleForFilter:self.filter]];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    self.tableView.backgroundView = self.emptyLabel;
}

- (NSArray<YALMineManagedPost *> *)demoPosts {
    return @[
        [YALMineManagedPost postWithTitle:@"武康路晚霞散步"
                                  summary:@"上海 · 2 小时前 · 城市晚霞与街角散步"
                                   status:YALMinePostStatusPublic],
        [YALMineManagedPost postWithTitle:@"老街早餐铺的热气"
                                  summary:@"苏州 · 昨天 · 只想先留给自己看"
                                   status:YALMinePostStatusPrivate],
        [YALMineManagedPost postWithTitle:@"江边骑行的风"
                                  summary:@"南京 · 3 天前 · 骑行路线与照片记录"
                                   status:YALMinePostStatusPublic],
        [YALMineManagedPost postWithTitle:@"雨后的旧书店门口"
                                  summary:@"杭州 · 待发布 · 还在补充照片和文案"
                                   status:YALMinePostStatusDraft]
    ];
}

- (void)updateEmptyState {
    self.emptyLabel.hidden = (self.filteredPosts.count > 0);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.filteredPosts.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return @"点进单条内容可调整公开/私人状态或删除；草稿也能直接转成公开或私人。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"YALMinePublishedCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        cell.detailTextLabel.numberOfLines = 2;
    }

    YALMineManagedPost *post = self.filteredPosts[indexPath.row];
    NSString *statusText = [self statusTextForPost:post];
    cell.textLabel.text = post.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"当前：%@\n%@", statusText, post.summary];
    cell.imageView.image = [self iconForPostStatus:post.status];
    cell.imageView.tintColor = [self accentColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self presentActionsForPostAtIndexPath:indexPath sourceView:[tableView cellForRowAtIndexPath:indexPath]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
    (void)tableView;
    YALMineManagedPost *post = self.filteredPosts[indexPath.row];
    NSString *primaryTitle = (post.status == YALMinePostStatusPublic) ? @"设为私人" : @"设为公开";
    YALMinePostStatus nextStatus = (post.status == YALMinePostStatusPublic) ? YALMinePostStatusPrivate : YALMinePostStatusPublic;

    __weak typeof(self) weakSelf = self;
    UIContextualAction *toggleAction =
    [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                            title:primaryTitle
                                          handler:^(__unused UIContextualAction * _Nonnull action,
                                                    __unused UIView * _Nonnull sourceView,
                                                    void (^ _Nonnull completionHandler)(BOOL)) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf updatePostAtIndexPath:indexPath status:nextStatus];
        completionHandler(YES);
    }];
    toggleAction.backgroundColor = [self accentColor];

    UIContextualAction *deleteAction =
    [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                            title:@"删除"
                                          handler:^(__unused UIContextualAction * _Nonnull action,
                                                    __unused UIView * _Nonnull sourceView,
                                                    void (^ _Nonnull completionHandler)(BOOL)) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf deletePostAtIndexPath:indexPath];
        completionHandler(YES);
    }];

    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, toggleAction]];
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (void)presentActionsForPostAtIndexPath:(NSIndexPath *)indexPath sourceView:(UIView *)sourceView {
    if (indexPath.row >= self.filteredPosts.count) {
        return;
    }

    YALMineManagedPost *post = self.filteredPosts[indexPath.row];

    UIAlertController *sheet =
    [UIAlertController alertControllerWithTitle:post.title
                                        message:[NSString stringWithFormat:@"当前状态：%@", [self statusTextForPost:post]]
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"设为公开"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf updatePostAtIndexPath:indexPath status:YALMinePostStatusPublic];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"设为私人"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf updatePostAtIndexPath:indexPath status:YALMinePostStatusPrivate];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"删除"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf deletePostAtIndexPath:indexPath];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = sourceView ?: self.view;
        popover.sourceRect = sourceView ? sourceView.bounds : CGRectMake(CGRectGetMidX(self.view.bounds),
                                                                         CGRectGetMidY(self.view.bounds),
                                                                         1.0,
                                                                         1.0);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)updatePostAtIndexPath:(NSIndexPath *)indexPath status:(YALMinePostStatus)status {
    if (indexPath.row >= self.filteredPosts.count) {
        return;
    }
    YALMineManagedPost *post = self.filteredPosts[indexPath.row];
    post.status = status;
    [self updateEmptyState];
    [self.tableView reloadData];
}

- (void)deletePostAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.filteredPosts.count) {
        return;
    }
    YALMineManagedPost *post = self.filteredPosts[indexPath.row];
    [self.allPosts removeObject:post];
    [self updateEmptyState];
    [self.tableView reloadData];
}

- (NSArray<YALMineManagedPost *> *)filteredPosts {
    NSMutableArray<YALMineManagedPost *> *items = [NSMutableArray array];
    for (YALMineManagedPost *post in self.allPosts) {
        BOOL shouldInclude = NO;
        switch (self.filter) {
            case YALMinePostsFilterAll:
                shouldInclude = (post.status != YALMinePostStatusDraft);
                break;
            case YALMinePostsFilterPublic:
                shouldInclude = (post.status == YALMinePostStatusPublic);
                break;
            case YALMinePostsFilterPrivate:
                shouldInclude = (post.status == YALMinePostStatusPrivate);
                break;
            case YALMinePostsFilterDraft:
                shouldInclude = (post.status == YALMinePostStatusDraft);
                break;
        }
        if (shouldInclude) {
            [items addObject:post];
        }
    }
    return items;
}

- (NSString *)titleForFilter:(YALMinePostsFilter)filter {
    switch (filter) {
        case YALMinePostsFilterPublic:
            return @"公开中";
        case YALMinePostsFilterPrivate:
            return @"私密中";
        case YALMinePostsFilterDraft:
            return @"草稿箱";
        case YALMinePostsFilterAll:
        default:
            return @"我的发布";
    }
}

- (NSString *)statusTextForPost:(YALMineManagedPost *)post {
    switch (post.status) {
        case YALMinePostStatusPrivate:
            return @"私人";
        case YALMinePostStatusDraft:
            return @"草稿";
        case YALMinePostStatusPublic:
        default:
            return @"公开";
    }
}

- (UIImage *)iconForPostStatus:(YALMinePostStatus)status {
    if (@available(iOS 13.0, *)) {
        switch (status) {
            case YALMinePostStatusPrivate:
                return [UIImage systemImageNamed:@"lock.fill"];
            case YALMinePostStatusDraft:
                return [UIImage systemImageNamed:@"doc.fill"];
            case YALMinePostStatusPublic:
            default:
                return [UIImage systemImageNamed:@"eye.fill"];
        }
    }
    return nil;
}

- (UIColor *)accentColor {
    return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

@end

@interface YALMineController () <YALMineViewDelegate>

@property (nonatomic, strong) YALMineView *mineView;
@property (nonatomic, strong) NSArray<YALMineProfileModel *> *profiles;
@property (nonatomic, assign) NSInteger currentProfileIndex;

@end

@implementation YALMineController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Mine";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.navigationController.navigationBar.tintColor = [self accentColor];

    [self setupNavigationItems];
    [self buildView];
    [self setupData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshLoginState];
}

- (void)setupNavigationItems {
    if (@available(iOS 13.0, *)) {
        UIImage *settingsImage = [UIImage systemImageNamed:@"slider.horizontal.3"];
        UIBarButtonItem *settingsItem =
        [[UIBarButtonItem alloc] initWithImage:settingsImage
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(settingsTapped)];
        settingsItem.tintColor = [self accentColor];
        self.navigationItem.rightBarButtonItem = settingsItem;
    } else {
        UIBarButtonItem *settingsItem =
        [[UIBarButtonItem alloc] initWithTitle:@"设置"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(settingsTapped)];
        self.navigationItem.rightBarButtonItem = settingsItem;
    }
}

- (void)buildView {
    self.mineView = [[YALMineView alloc] initWithFrame:self.view.bounds];
    self.mineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mineView.delegate = self;
    [self.view addSubview:self.mineView];
}

- (void)setupData {
    self.profiles = [YALMineProfileModel defaultProfiles];
    self.currentProfileIndex = 0;
    if (self.profiles.count > 0) {
        [self.mineView applyProfile:self.profiles.firstObject];
    }
    [self refreshLoginState];
}

- (void)refreshLoginState {
    YALAuthManager *auth = [YALAuthManager sharedManager];
    if ([auth hasLoggedInSession] && auth.currentUser) {
        [self updateUIWithUser:auth.currentUser];
    } else {
        [self showNotLoggedInState];
    }
}


- (void)settingsTapped {
    YALMineSettingsController *settingsVC = [[YALMineSettingsController alloc] init];
    settingsVC.hidesBottomBarWhenPushed = YES;
    __weak typeof(self) weakSelf = self;
    __weak typeof(settingsVC) weakSettingsVC = settingsVC;
    settingsVC.tapShuffleProfileBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakSettingsVC) strongSettings = weakSettingsVC;
        if (!strongSelf) { return; }
        [strongSelf shuffleProfileStyle];
        [strongSelf showPlaceholderAlertOnController:(strongSettings ?: strongSelf)
                                               title:@"已更新主页样式"
                                             message:@"昵称、简介和统计数据已切换。"];
    };
    settingsVC.tapShareBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakSettingsVC) strongSettings = weakSettingsVC;
        if (!strongSelf) { return; }
        [strongSelf shareAppFromController:(strongSettings ?: strongSelf)];
    };
    settingsVC.tapClearBadgeBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakSettingsVC) strongSettings = weakSettingsVC;
        if (!strongSelf) { return; }
        [strongSelf clearMessageBadgeOnController:(strongSettings ?: strongSelf)];
    };
    settingsVC.tapLogoutBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakSettingsVC) strongSettings = weakSettingsVC;
        if (!strongSelf) { return; }
        [strongSelf confirmLogoutOnController:(strongSettings ?: strongSelf)];
    };
    [self.navigationController pushViewController:settingsVC animated:YES];
}

- (void)shuffleProfileStyle {
    if (self.profiles.count == 0) {
        return;
    }
    if (self.profiles.count == 1) {
        [self.mineView applyProfile:self.profiles.firstObject];
        return;
    }
    NSInteger nextIndex = self.currentProfileIndex;
    while (nextIndex == self.currentProfileIndex) {
        nextIndex = arc4random_uniform((uint32_t)self.profiles.count);
    }
    self.currentProfileIndex = nextIndex;
    [self.mineView applyProfile:self.profiles[nextIndex]];
    YALAuthManager *auth = [YALAuthManager sharedManager];
    if ([auth hasLoggedInSession] && auth.currentUser) {
        [self updateUIWithUser:auth.currentUser];
    } else {
        [self showNotLoggedInState];
    }
}

- (void)shareAppFromController:(UIViewController *)controller {
    NSString *text = @"我在 MemoryCity 记录城市记忆，来一起看看吧。";
    NSURL *url = [NSURL URLWithString:@"https://example.com/memorycity"];
    NSMutableArray *items = [NSMutableArray arrayWithObject:text];
    if (url) {
        [items addObject:url];
    }
    UIActivityViewController *activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    UIPopoverPresentationController *popover = activityVC.popoverPresentationController;
    if (popover) {
        popover.barButtonItem = controller.navigationItem.rightBarButtonItem ?: self.navigationItem.rightBarButtonItem;
    }
    [controller presentViewController:activityVC animated:YES completion:nil];
}

- (void)clearMessageBadgeOnController:(UIViewController *)controller {
    if (@available(iOS 16.0, *)) {
        [UNUserNotificationCenter.currentNotificationCenter setBadgeCount:0 withCompletionHandler:nil];
    } else {
        UIApplication.sharedApplication.applicationIconBadgeNumber = 0;
    }
    [self showPlaceholderAlertOnController:controller
                                     title:@"已清空提醒"
                                   message:@"消息角标已重置，你可以继续浏览新的互动。"];
}

- (void)confirmLogoutOnController:(UIViewController *)controller {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"退出登录"
                                        message:@"退出后将返回登录页，确定继续吗？"
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"退出登录"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        [self performLogout];
    }]];
    [controller presentViewController:alert animated:YES completion:nil];
}

- (void)performLogout {
    UIWindow *window = [self activeWindow];
    if (!window) {
        [self showPlaceholderAlertOnController:self title:@"退出失败" message:@"未找到可用窗口，请稍后重试。"];
        return;
    }
    if (@available(iOS 13.0, *)) {
        window.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kYALAppAppearanceStyleKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[YALAuthManager sharedManager] clearAuthSession];
    YALLoginController *loginVC = [[YALLoginController alloc] init];
    UINavigationController *loginNav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    [UIView transitionWithView:window
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        BOOL oldState = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        window.rootViewController = loginNav;
        [UIView setAnimationsEnabled:oldState];
    } completion:nil];
    [window makeKeyAndVisible];
}

- (UIWindow *)activeWindow {
    UIWindow *window = self.view.window;
    if (window) {
        return window;
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        if (windowScene.activationState != UISceneActivationStateForegroundActive &&
            windowScene.activationState != UISceneActivationStateForegroundInactive) {
            continue;
        }
        for (UIWindow *candidate in windowScene.windows) {
            if (candidate.isKeyWindow) {
                return candidate;
            }
        }
        if (windowScene.windows.count > 0) {
            return windowScene.windows.firstObject;
        }
    }
    return nil;
}

#pragma mark - YALMineViewDelegate

- (void)mineViewDidTapEditProfile:(YALMineView *)view {
    (void)view;
    if (![[YALAuthManager sharedManager] hasLoggedInSession]) {
        [self mineViewDidTapLogin:view];
        return;
    }
    [self showPlaceholderAlertOnController:self
                                     title:@"编辑资料"
                                   message:@"这里可以继续接昵称、头像和个性签名编辑。"];
}

- (void)mineViewDidTapLogin:(YALMineView *)view {
    (void)view;
    YALLoginController *loginVC = [[YALLoginController alloc] init];
    loginVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:loginVC animated:YES];
}

- (void)mineView:(YALMineView *)view didTapWorkspaceItemAtIndex:(NSInteger)index {
    (void)view;
    switch (index) {
        case 0:
            [self pushController:[[YALMinePublishedController alloc] initWithFilter:YALMinePostsFilterAll]];
            break;
        case 1:
            [self pushController:[[YALMinePublishedController alloc] initWithFilter:YALMinePostsFilterDraft]];
            break;
        case 2: {
            YALReleaseController *controller = [[YALReleaseController alloc] init];
            [self pushController:controller];
            break;
        }
        default:
            break;
    }
}

- (void)mineView:(YALMineView *)view didTapStatAtIndex:(NSInteger)index {
    (void)view;
    switch (index) {
        case 0:
            [self pushController:[[YALMinePublishedController alloc] initWithFilter:YALMinePostsFilterPublic]];
            break;
        case 1:
            [self pushController:[[YALMinePublishedController alloc] initWithFilter:YALMinePostsFilterPrivate]];
            break;
        case 2:
            [self pushController:[[YALMinePublishedController alloc] initWithFilter:YALMinePostsFilterDraft]];
            break;
        default:
            break;
    }
}

- (void)mineView:(YALMineView *)view didTapPersonalItemAtIndex:(NSInteger)index {
    (void)view;
    switch (index) {
        case 0: {
            YALMemoryController *controller = [[YALMemoryController alloc] init];
            [self pushController:controller];
            break;
        }
        case 1: {
            YALMapController *controller = [[YALMapController alloc] init];
            [self pushController:controller];
            break;
        }
        case 2: {
            YALMessageController *controller = [[YALMessageController alloc] init];
            [self pushController:controller];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Common

- (void)pushController:(UIViewController *)controller {
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPlaceholderAlertOnController:(UIViewController *)controller
                                   title:(NSString *)title
                                 message:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [controller presentViewController:alert animated:YES completion:nil];
}

- (UIColor *)accentColor {
    return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

#pragma mark - Login State Handling

- (void)updateUIWithUser:(YALAuthUserModel *)user {
    [self.mineView applyAuthUser:user];
}

- (void)showNotLoggedInState {
    [self.mineView setGuestLoginModeEnabled:YES];
}

@end
