//
//  SceneDelegate.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic, nullable) UIWindow *window;

+ (UIWindow * _Nullable)activeWindow;
+ (void)switchRootForCurrentAuthStateAnimated:(BOOL)animated;
+ (void)switchToLoginInterfaceAnimated:(BOOL)animated resetAppearance:(BOOL)resetAppearance;
+ (void)switchToMainInterfaceAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
