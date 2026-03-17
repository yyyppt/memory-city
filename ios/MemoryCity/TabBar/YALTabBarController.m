//
//  YALTabBarController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALTabBarController.h"
#import "YALTabBar.h"
#import "YALHomeController.h"
#import "YALTimeLineController.h"
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

  [self setupViewControllers];
  [self setupTabBarAppearance];
  [self setupCenterButton];

//  // 顶部导航栏使用奶油白 + 橙色图标（支持深色模式）
//  UIColor *highlightColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
//  UINavigationBar *navigationBar = [UINavigationBar appearance];
//  navigationBar.tintColor = highlightColor;
//
//  if (@available(iOS 13.0, *)) {
//    UIColor *dynamicBackground = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
//      if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
//        // 深色模式：接近 systemBackground，略带透明
//        return [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.95];
//      } else {
//        // 浅色模式：奶油白
//        return [UIColor colorWithRed:252/255.0 green:251/255.0 blue:248/255.0 alpha:0.95];
//      }
//    }];
//
//    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
//    [appearance configureWithDefaultBackground];
//    appearance.backgroundColor = dynamicBackground;
//    appearance.shadowColor = [UIColor clearColor];
//    appearance.titleTextAttributes = @{ NSForegroundColorAttributeName: [UIColor labelColor] };
//
//    navigationBar.standardAppearance = appearance;
//    navigationBar.scrollEdgeAppearance = appearance;
//    navigationBar.compactAppearance = appearance;
//  } else {
//    navigationBar.barTintColor = [UIColor whiteColor];
//    navigationBar.translucent = YES;
//    [navigationBar setShadowImage:[UIImage new]];
//    [navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
//  }
}

- (void)setupViewControllers {
  YALHomeController *homeVC = [[YALHomeController alloc] init];
  YALTimeLineController *memoriesVC = [[YALTimeLineController alloc] init];
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
  UIColor *highlightColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
  self.tabBar.tintColor = highlightColor;

  if (@available(iOS 15.0, *)) {
      UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
      [appearance configureWithOpaqueBackground];
      appearance.backgroundColor = UIColor.systemBackgroundColor;
      appearance.selectionIndicatorImage = [[UIImage alloc] init];

      self.tabBar.standardAppearance = appearance;
      self.tabBar.scrollEdgeAppearance = appearance;
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
  leftLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
  leftLine.frame = CGRectMake(0, 0, centerX - gapWidth / 2.0, 0.5);

  CALayer *rightLine = [CALayer layer];
  rightLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
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
