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
    self.loginView = [[YALLoginView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.loginView];
}

@end
