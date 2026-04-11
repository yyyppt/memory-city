//
//  SceneDelegate.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/9.
//

#import "SceneDelegate.h"

#import "YALAuthManager.h"
#import "YALLoginController.h"
#import "YALTabBarController.h"

static NSString * const kYALAppAppearanceStyleKey = @"YALAppAppearanceStyle";

@interface SceneDelegate ()

@property (nonatomic, assign) BOOL lastKnownLoggedInState;

@end

@implementation SceneDelegate

+ (UIWindow *)activeWindow {
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

+ (void)switchRootForCurrentAuthStateAnimated:(BOOL)animated {
    if ([[YALAuthManager sharedManager] hasLoggedInSession]) {
        [self switchToMainInterfaceAnimated:animated];
    } else {
        [self switchToLoginInterfaceAnimated:animated resetAppearance:NO];
    }
}

+ (void)switchToLoginInterfaceAnimated:(BOOL)animated resetAppearance:(BOOL)resetAppearance {
    UIWindow *window = [self activeWindow];
    if (!window) {
        return;
    }

    if (@available(iOS 13.0, *)) {
        if (resetAppearance) {
            window.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
        } else {
            NSInteger style = [[NSUserDefaults standardUserDefaults] integerForKey:kYALAppAppearanceStyleKey];
            if (style == UIUserInterfaceStyleDark || style == UIUserInterfaceStyleLight) {
                window.overrideUserInterfaceStyle = (UIUserInterfaceStyle)style;
            } else {
                window.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
            }
        }
    }

    UINavigationController *loginNav = [[UINavigationController alloc] initWithRootViewController:[[YALLoginController alloc] init]];
    [self setRootViewController:loginNav onWindow:window animated:animated];
}

+ (void)switchToMainInterfaceAnimated:(BOOL)animated {
    UIWindow *window = [self activeWindow];
    if (!window) {
        return;
    }

    [self setRootViewController:[[YALTabBarController alloc] init] onWindow:window animated:animated];
}

+ (void)setRootViewController:(UIViewController *)rootViewController
                     onWindow:(UIWindow *)window
                     animated:(BOOL)animated {
    if (!window || !rootViewController) {
        return;
    }

    if (window.rootViewController &&
        [window.rootViewController isMemberOfClass:[rootViewController class]]) {
        [window makeKeyAndVisible];
        return;
    }

    void (^applyRoot)(void) = ^{
        BOOL oldState = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        window.rootViewController = rootViewController;
        [UIView setAnimationsEnabled:oldState];
    };

    if (animated) {
        [UIView transitionWithView:window
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:applyRoot
                        completion:nil];
    } else {
        applyRoot();
    }
    [window makeKeyAndVisible];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    if (@available(iOS 13.0, *)) {
        NSInteger style = [[NSUserDefaults standardUserDefaults] integerForKey:kYALAppAppearanceStyleKey];
        if (style == UIUserInterfaceStyleDark || style == UIUserInterfaceStyleLight) {
            self.window.overrideUserInterfaceStyle = (UIUserInterfaceStyle)style;
        } else {
            self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
        }
    }

#if DEBUG
    // 开发调试时每次重新运行都清掉登录态，避免旧 token 干扰联调。
    [[YALAuthManager sharedManager] clearAuthSession];
#endif

    self.lastKnownLoggedInState = [[YALAuthManager sharedManager] hasLoggedInSession];
    self.window.rootViewController = self.lastKnownLoggedInState ? [[YALTabBarController alloc] init] : [[UINavigationController alloc] initWithRootViewController:[[YALLoginController alloc] init]];
    [self.window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAuthStateDidChange:)
                                                 name:YALAuthManagerCurrentUserDidChangeNotification
                                               object:nil];
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    (void)scene;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:YALAuthManagerCurrentUserDidChangeNotification
                                                  object:nil];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    (void)scene;
}

- (void)sceneWillResignActive:(UIScene *)scene {
    (void)scene;
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    (void)scene;
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    (void)scene;
}

- (void)handleAuthStateDidChange:(NSNotification *)notification {
    (void)notification;
    BOOL isLoggedIn = [[YALAuthManager sharedManager] hasLoggedInSession];
    if (isLoggedIn == self.lastKnownLoggedInState) {
        return;
    }
    self.lastKnownLoggedInState = isLoggedIn;

    if (isLoggedIn) {
        [SceneDelegate switchToMainInterfaceAnimated:YES];
    } else {
        [SceneDelegate switchToLoginInterfaceAnimated:YES resetAppearance:NO];
    }
}

@end
