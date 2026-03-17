//
//  YALLoginController.m
//  MemoryCity
//
//  Created by mac on 2026/3/15.
//

#import "YALLoginController.h"

@interface YALLoginController ()

@end

@implementation YALLoginController

- (void)viewDidLoad {
    [super viewDidLoad];
    _loginView = [[YALLoginView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.loginView];
    
    __weak typeof(self) weakSelf = self;
    _loginView.tapLoginBlock = ^{
        NSLog(@"ioaewfieauifuadeifa");
        YALTabBarController *tabBarController = [[YALTabBarController alloc] init];
        NSLog(@"tab = %@", tabBarController);
        [weakSelf.navigationController pushViewController:tabBarController animated:YES];
    };
}

@end
