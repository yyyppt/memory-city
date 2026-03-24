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
#import <UserNotifications/UserNotifications.h>

static NSString * const kYALAppAppearanceStyleKey = @"YALAppAppearanceStyle";

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
}

#pragma mark - Settings

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
    [self showPlaceholderAlertOnController:self
                                     title:@"编辑资料"
                                   message:@"这里可以继续接昵称、头像和个性签名编辑。"];
}

- (void)mineView:(YALMineView *)view didTapQuickActionAtIndex:(NSInteger)index {
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
        case 3: {
            YALReleaseController *controller = [[YALReleaseController alloc] init];
            [self pushController:controller];
            break;
        }
        default:
            break;
    }
}

- (void)mineView:(YALMineView *)view didTapServiceAtIndex:(NSInteger)index {
    (void)view;
    switch (index) {
        case 0:
            [self showPlaceholderAlertOnController:self
                                             title:@"收藏灵感"
                                           message:@"适合后续接入你喜欢的帖子、地点或城市清单。"];
            break;
        case 1:
            [self showPlaceholderAlertOnController:self
                                             title:@"草稿箱"
                                           message:@"这里可以承接未发布内容，保持你的发布链路完整。"];
            break;
        case 2:
            [self settingsTapped];
            break;
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

@end
