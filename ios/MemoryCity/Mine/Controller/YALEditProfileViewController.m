//
//  YALEditProfileViewController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/29.
#import "YALEditProfileViewController.h"
#import "YALEditProfileView.h"
#import "YALAuthUserModel.h"
#import "YALAuthManager.h"

@interface YALEditProfileViewController () <YALEditProfileViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

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
    id avatarObj = data[@"avatar"];
    NSString *avatar = ([avatarObj isKindOfClass:[NSString class]] ? avatarObj : nil);
    nickname = [nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    bio = [bio stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (avatar.length == 0) {
        avatar = nil;
    }

    // 简单校验
    if (nickname.length == 0) {
        [view showErrorMessage:@"昵称不能为空" forField:@"nickname"];
        return;
    }

    // 防止重复点击
    self.view.userInteractionEnabled = NO;

    [[YALAuthManager sharedManager] updateUserInfoWithNickname:nickname
                                                         avatar:avatar
                                                            bio:bio
                                                  completion:^(YALAuthUserModel * _Nullable user, NSError * _Nullable error) {
        self.view.userInteractionEnabled = YES;
        if (!user || error) {
            NSString *msg = error.localizedDescription.length > 0 ? error.localizedDescription : @"保存失败";
            [view showErrorMessage:msg forField:@"nickname"];
            return;
        }

        self.user = user;
        if (self.onEditComplete) {
            self.onEditComplete(user.nickname, user.avatar);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)editProfileViewDidTapCancel:(YALEditProfileView *)view {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editProfileViewDidTapAvatar:(YALEditProfileView *)view {
    [self.view endEditing:YES];

    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        return;
    }

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    if (img) {
        [self.editView setAvatarImage:img];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
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
