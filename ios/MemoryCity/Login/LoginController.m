//
//  LoginController.m
//  MemoryCity
//
//  Created by mac on 2026/3/15.
//

#import "LoginController.h"

@interface LoginController ()

@end

@implementation LoginController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginView = [[LoginView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.loginView];
}

@end
