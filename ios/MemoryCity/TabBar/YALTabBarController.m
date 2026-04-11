//
//  YALTabBarController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALTabBarController.h"
#import "YALTabBar.h"
#import "YALHomeController.h"
#import "YALMemoryController.h"
#import "YALReleaseController.h"
#import "YALMapController.h"
#import "YALMineController.h"

@interface YALTabBarController ()

@end

@implementation YALTabBarController

- (void)viewDidLoad {
  [super viewDidLoad];

  // 使用自定义 TabBar
  YALTabBar *tabBar = [[YALTabBar alloc] init];
  [self setValue:tabBar forKey:@"tabBar"];

  [self setupNavigationAppearance];
  [self setupViewControllers];
  [self setupTabBarAppearance];
  [self setupCenterButton];
}

- (UIColor *)yalAccentColor {
  return [UIColor colorWithRed:0.98 green:0.52 blue:0.18 alpha:1.0];
}

- (UIColor *)yalChromeBackgroundColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
      if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        return [[UIColor colorWithRed:0.12 green:0.105 blue:0.09 alpha:1.0] colorWithAlphaComponent:0.92];
      }
      return [[UIColor colorWithRed:1.0 green:0.985 blue:0.955 alpha:1.0] colorWithAlphaComponent:0.94];
    }];
  }
  return [[UIColor colorWithRed:1.0 green:0.985 blue:0.955 alpha:1.0] colorWithAlphaComponent:0.94];
}

- (void)setupNavigationAppearance {
  UIColor *accent = [self yalAccentColor];
  UINavigationBar *navigationBar = [UINavigationBar appearance];
  navigationBar.tintColor = accent;
  navigationBar.translucent = YES;

  if (@available(iOS 13.0, *)) {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithTransparentBackground];
    appearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
    appearance.backgroundColor = [self yalChromeBackgroundColor];
    appearance.shadowColor = [[UIColor colorWithRed:0.58 green:0.38 blue:0.20 alpha:1.0] colorWithAlphaComponent:0.10];
    appearance.titleTextAttributes = @{
      NSForegroundColorAttributeName: [UIColor labelColor],
      NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]
    };
    appearance.largeTitleTextAttributes = @{
      NSForegroundColorAttributeName: [UIColor labelColor],
      NSFontAttributeName: [UIFont systemFontOfSize:32 weight:UIFontWeightHeavy]
    };

    navigationBar.standardAppearance = appearance;
    navigationBar.scrollEdgeAppearance = appearance;
    navigationBar.compactAppearance = appearance;
  } else {
    navigationBar.barTintColor = [UIColor colorWithRed:1.0 green:0.985 blue:0.955 alpha:1.0];
    [navigationBar setShadowImage:[UIImage new]];
    [navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
  }
}

- (void)setupViewControllers {
  YALHomeController *homeVC = [[YALHomeController alloc] init];
  YALMemoryController *memoriesVC = [[YALMemoryController alloc] init];
  YALReleaseController *releaseVC = [[YALReleaseController alloc] init];
  YALMapController *mapVC = [[YALMapController alloc] init];
  YALMineController *mineVC = [[YALMineController alloc] init];

  UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeVC];
  UINavigationController *memoriesNav = [[UINavigationController alloc] initWithRootViewController:memoriesVC];
  UINavigationController *releaseNav = [[UINavigationController alloc] initWithRootViewController:releaseVC];
  UINavigationController *mapNav = [[UINavigationController alloc] initWithRootViewController:mapVC];
  UINavigationController *mineNav = [[UINavigationController alloc] initWithRootViewController:mineVC];

  if (@available(iOS 13.0, *)) {
    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home"
                                                      image:[UIImage systemImageNamed:@"house"]
                                              selectedImage:[UIImage systemImageNamed:@"house.fill"]];

    memoriesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Memories"
                                                           image:[UIImage systemImageNamed:@"wand.and.stars.inverse"]
                                                   selectedImage:[UIImage systemImageNamed:@"wand.and.stars"]];

    UITabBarItem *releaseItem =
    [[UITabBarItem alloc] initWithTitle:nil image:[[UIImage alloc] init] tag:2];
    releaseItem.enabled = NO;
    releaseNav.tabBarItem = releaseItem;

    mapNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Map"
                                                     image:[UIImage systemImageNamed:@"location"]
                                             selectedImage:[UIImage systemImageNamed:@"location.fill"]];

    mineNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Mine"
                                                      image:[UIImage systemImageNamed:@"person"]
                                              selectedImage:[UIImage systemImageNamed:@"person.fill"]];
  } else {
    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home" image:nil tag:0];
    memoriesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Memories" image:nil tag:1];
    UITabBarItem *releaseItem = [[UITabBarItem alloc] initWithTitle:nil image:nil tag:2];
    releaseNav.tabBarItem = releaseItem;
    mapNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Map" image:nil tag:3];
    mineNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Mine" image:nil tag:4];
  }

  self.viewControllers = @[homeNav, memoriesNav, releaseNav, mapNav, mineNav];
}

- (void)setupTabBarAppearance {
  UIColor *highlightColor = [self yalAccentColor];
  self.tabBar.tintColor = highlightColor;
  self.tabBar.unselectedItemTintColor = [UIColor colorWithRed:0.55 green:0.46 blue:0.38 alpha:1.0];

  if (@available(iOS 13.0, *)) {
      UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
      [appearance configureWithTransparentBackground];
      appearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
      appearance.backgroundColor = [self yalChromeBackgroundColor];
      appearance.selectionIndicatorImage = [[UIImage alloc] init];
      appearance.shadowColor = [[UIColor colorWithRed:0.58 green:0.38 blue:0.20 alpha:1.0] colorWithAlphaComponent:0.10];
      appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{
        NSForegroundColorAttributeName: self.tabBar.unselectedItemTintColor,
        NSFontAttributeName: [UIFont systemFontOfSize:11 weight:UIFontWeightMedium]
      };
      appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{
        NSForegroundColorAttributeName: highlightColor,
        NSFontAttributeName: [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold]
      };

      self.tabBar.standardAppearance = appearance;
      if (@available(iOS 15.0, *)) {
        self.tabBar.scrollEdgeAppearance = appearance;
      }
  }
  self.tabBar.selectionIndicatorImage = [UIImage new];

  // 顶部淡淡的分割线（中间为空出一段给按钮）
  UITabBar *tabBar = self.tabBar;
  tabBar.clipsToBounds = NO;

  CGFloat diameter = 64.0; // 与中间按钮直径保持一致
  // 只给白色圆环留空（borderWidth = 4，边框向内绘制）
  CGFloat borderWidth = 4.0;
  CGFloat gapWidth = diameter - borderWidth * 2.0;
  CGFloat tabBarWidth = CGRectGetWidth(tabBar.bounds);
  CGFloat centerX = tabBarWidth / 2.0;

  CALayer *leftLine = [CALayer layer];
  leftLine.backgroundColor = [UIColor separatorColor].CGColor;
  leftLine.frame = CGRectMake(0, 0, centerX - gapWidth / 2.0, 0.5);

  CALayer *rightLine = [CALayer layer];
  rightLine.backgroundColor = [UIColor separatorColor].CGColor;
  rightLine.frame = CGRectMake(centerX + gapWidth / 2.0,
                               0,
                               tabBarWidth - (centerX + gapWidth / 2.0),
                               0.5);

  [tabBar.layer addSublayer:leftLine];
  [tabBar.layer addSublayer:rightLine];
}

- (void)setupCenterButton {
  if (![self.tabBar isKindOfClass:[YALTabBar class]]) {
    return;
  }

  YALTabBar *tabBar = (YALTabBar *)self.tabBar;
  UIButton *centerButton = tabBar.centerButton;

  if (@available(iOS 13.0, *)) {
    UIImageSymbolConfiguration *plusConfig =
      [UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightBold];
    UIImage *plusImage = [UIImage systemImageNamed:@"plus" withConfiguration:plusConfig];
    [centerButton setImage:plusImage forState:UIControlStateNormal];
    centerButton.tintColor = [UIColor whiteColor]; // 中间白色十字
  }

  [centerButton addTarget:self
                   action:@selector(centerButtonTapped)
         forControlEvents:UIControlEventTouchUpInside];
}

- (void)centerButtonTapped {
  self.selectedIndex = 2;
}

@end
