//
//  main.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/9.
//

#import <UIKit/UIKit.h>
#import "YALAppDelegate.h"

int main(int argc, char * argv[]) {
  NSString * appDelegateClassName;
  @autoreleasepool {
      // Setup code that might create autoreleased objects goes here.
      appDelegateClassName = NSStringFromClass([YALAppDelegate class]);
  }
  return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
