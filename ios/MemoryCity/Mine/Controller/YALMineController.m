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
#import "YALAuthManager.h"
#import "SceneDelegate.h"
#import "YALEditProfileViewController.h"
#import "YALChangePasswordViewController.h"
#import "YALMyContentListController.h"
#import "YALLikesController.h"
#import "YALFavoritesController.h"
#import "YALContentManager.h"
#import <UserNotifications/UserNotifications.h>

static NSString * const kYALAppAppearanceStyleKey = @"YALAppAppearanceStyle";

static BOOL YALMineBoolFromPublicValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value boolValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *lower = [[(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
        if (lower.length == 0) return NO;
        if ([lower isEqualToString:@"1"] ||
            [lower isEqualToString:@"true"] ||
            [lower isEqualToString:@"yes"] ||
            [lower isEqualToString:@"public"] ||
            [lower isEqualToString:@"公开"]) {
            return YES;
        }
        if ([lower isEqualToString:@"0"] ||
            [lower isEqualToString:@"false"] ||
            [lower isEqualToString:@"no"] ||
            [lower isEqualToString:@"2"] ||
            [lower isEqualToString:@"private"] ||
            [lower isEqualToString:@"only_self"] ||
            [lower isEqualToString:@"self"] ||
            [lower isEqualToString:@"personal"] ||
            [lower isEqualToString:@"私密"] ||
            [lower isEqualToString:@"仅自己可见"]) {
            return NO;
        }
        return NO;
    }
    return NO;
}

static id YALMineResolvedVisibilityValue(NSDictionary *dict) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id value = dict[@"is_public"];
    return value;
}







@interface YALMineController () <YALMineViewDelegate>

@property (nonatomic, strong) YALMineView *mineView;
@property (nonatomic, strong) NSArray<YALMineProfileModel *> *profiles;
@property (nonatomic, assign) NSInteger currentProfileIndex;
@property (nonatomic, assign) BOOL isLoadingCreatorStats;
@property (nonatomic, assign) NSInteger creatorStatsRequestToken;

@end

@implementation YALMineController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Mine";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.navigationController.navigationBar.tintColor = [self accentColor];

    // 让从 Mine 推出的页面只显示返回图标，不显示 “Mine” 文本
    if (!self.navigationItem.backBarButtonItem) {
        self.navigationItem.backBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@""
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
    }

    [self setupNavigationItems];
    [self buildView];
    [self setupData];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAuthCurrentUserDidChange:)
                                                 name:YALAuthManagerCurrentUserDidChangeNotification
                                               object:nil];
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
    [self.mineView updateCreatorStatsWithPublicCount:nil privateCount:nil];
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
    settingsVC.tapChangePasswordBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (![[YALAuthManager sharedManager] hasLoggedInSession]) {
            [strongSelf mineViewDidTapLogin:strongSelf.mineView];
            return;
        }
        YALChangePasswordViewController *vc = [[YALChangePasswordViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [strongSelf.navigationController pushViewController:vc animated:YES];
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
    UIWindow *window = [SceneDelegate activeWindow];
    if (!window) {
        [self showPlaceholderAlertOnController:self title:@"退出失败" message:@"未找到可用窗口，请稍后重试。"];
        return;
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kYALAppAppearanceStyleKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[YALAuthManager sharedManager] clearAuthSession];
    [SceneDelegate switchToLoginInterfaceAnimated:YES resetAppearance:YES];
}

#pragma mark - YALMineViewDelegate
- (void)mineViewDidTapEditProfile:(YALMineView *)view {
    if (![[YALAuthManager sharedManager] hasLoggedInSession]) {
        [self mineViewDidTapLogin:view];
        return;
    }

    YALAuthUserModel *user = [YALAuthManager sharedManager].currentUser;

    YALEditProfileViewController *vc = [[YALEditProfileViewController alloc] initWithUser:user];
    vc.hidesBottomBarWhenPushed = YES;

    __weak typeof(self) weakSelf = self;
    vc.onEditComplete = ^(NSString * _Nullable newNickname, NSString * _Nullable newAvatar) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        // 刷新UI（你后面可以接接口）
        [strongSelf refreshLoginState];
    };

    [self.navigationController pushViewController:vc animated:YES];
}

- (void)mineView:(YALMineView *)view didTapStatAtIndex:(NSInteger)index {
    (void)view;
    switch (index) {
        case 0:
            // 公开内容
            [self pushController:[[YALMyContentListController alloc] initWithTitle:@"公开内容"]];
            break;
        case 1:
            // 私人内容
            [self pushController:[[YALMyContentListController alloc] initWithTitle:@"私人内容"]];
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
            controller.playsFootprintAnimationOnAppear = YES;
            [self pushController:controller];
            break;
        }
        case 2: {
            YALLikesController *controller = [[YALLikesController alloc] init];
            [self pushController:controller];
            break;
        }
        case 3: {
            YALFavoritesController *controller = [[YALFavoritesController alloc] init];
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleAuthCurrentUserDidChange:(NSNotification *)note {
    (void)note;
    [self refreshLoginState];
}

- (void)updateUIWithUser:(YALAuthUserModel *)user {
    [self.mineView applyAuthUser:user];
    [self refreshCreatorStats];
}
- (void)showNotLoggedInState {
    self.creatorStatsRequestToken += 1;
    self.isLoadingCreatorStats = NO;
    [self.mineView setGuestLoginModeEnabled:YES];
}

- (void)refreshCreatorStats {
    YALAuthManager *auth = [YALAuthManager sharedManager];
    if (![auth hasLoggedInSession] || auth.currentUser.userId <= 0) {
        [self.mineView updateCreatorStatsWithPublicCount:nil privateCount:nil];
        return;
    }
    if (self.isLoadingCreatorStats) {
        return;
    }

    [self.mineView updateCreatorStatsWithPublicCount:nil privateCount:nil];
    self.isLoadingCreatorStats = YES;
    NSInteger requestToken = ++self.creatorStatsRequestToken;
    NSInteger const pageSize = 50;
    NSInteger const maxPages = 20;
    __block NSInteger page = 1;
    __block NSInteger publicCount = 0;
    __block NSInteger privateCount = 0;
    __block BOOL didFetchAnyPage = NO;

    __weak typeof(self) weakSelf = self;
    __block void (^fetchNextPage)(void) = ^{
        [[YALContentManager sharedManager] getMyContentListWithPage:page
                                                           pageSize:pageSize
                                                         completion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            (void)message;
            (void)error;

            if (requestToken != strongSelf.creatorStatsRequestToken) {
                strongSelf.isLoadingCreatorStats = NO;
                return;
            }

            if (!success || ![contentList isKindOfClass:[NSArray class]]) {
                strongSelf.isLoadingCreatorStats = NO;
                if (!didFetchAnyPage) {
                    [strongSelf.mineView updateCreatorStatsWithPublicCount:nil privateCount:nil];
                }
                return;
            }

            didFetchAnyPage = YES;
            for (id item in contentList) {
                if (![item isKindOfClass:[NSDictionary class]]) {
                    continue;
                }
                NSDictionary *dict = (NSDictionary *)item;
                id publicValue = YALMineResolvedVisibilityValue(dict);
                BOOL isPublic = YALMineBoolFromPublicValue(publicValue);
                if (isPublic) {
                    publicCount += 1;
                } else {
                    privateCount += 1;
                }
            }

            BOOL isLastPageBySize = contentList.count < pageSize;
            BOOL hitMaxPages = page >= maxPages;
            if (isLastPageBySize || hitMaxPages) {
                strongSelf.isLoadingCreatorStats = NO;
                [strongSelf.mineView updateCreatorStatsWithPublicCount:@(publicCount) privateCount:@(privateCount)];
                return;
            }

            page += 1;
            fetchNextPage();
        }];
    };

    fetchNextPage();
}

@end
