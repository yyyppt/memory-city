//
//  YALEditProfileViewController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/29.
#import "YALEditProfileViewController.h"
#import "YALEditProfileView.h"
#import "YALAuthUserModel.h"

@interface YALEditProfileViewController () <YALEditProfileViewDelegate>

@property (nonatomic, strong) YALEditProfileView *editView;
@property (nonatomic, strong) YALAuthUserModel *user;

@end

@implementation YALEditProfileViewController

- (instancetype)initWithUser:(YALAuthUserModel *)user {
    self = [super init];
    if (self) {
        _user = user;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"编辑资料";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // 创建 View
    self.editView = [[YALEditProfileView alloc] initWithFrame:self.view.bounds];
    self.editView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.editView.delegate = self; // ⭐️关键
    [self.view addSubview:self.editView];

    // 填充数据
    [self.editView applyUser:self.user];
}

#pragma mark - YALEditProfileViewDelegate

- (void)editProfileViewDidTapSave:(YALEditProfileView *)view {
    NSDictionary *data = [view getEditedData];

    NSString *nickname = data[@"nickname"];
    NSString *bio = data[@"bio"];

    // 简单校验
    if (nickname.length == 0) {
        [view showErrorMessage:@"昵称不能为空" forField:@"nickname"];
        return;
    }

    // 👉 这里未来接接口
    NSLog(@"保存数据：%@", data);

    if (self.onEditComplete) {
        self.onEditComplete(nickname, nil);
    }

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editProfileViewDidTapCancel:(YALEditProfileView *)view {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editProfileViewDidTapAvatar:(YALEditProfileView *)view {
    NSLog(@"点了头像（后面接图片选择器）");
}

- (void)editProfileViewDidTapChangePassword:(YALEditProfileView *)view {
    NSLog(@"点了修改密码");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

