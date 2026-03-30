//
//  YALEditProfileView.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/29.
//

#import "YALEditProfileView.h"
#import <Masonry/Masonry.h>
#import "YALAuthUserModel.h"

@interface YALEditProfileView ()

// UI Components
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIButton *avatarButton;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *avatarLabel;

@property (nonatomic, strong) UIView *nicknameContainer;
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UITextField *nicknameTextField;
@property (nonatomic, strong) UILabel *nicknameErrorLabel;

@property (nonatomic, strong) UIView *bioContainer;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UITextView *bioTextView;
@property (nonatomic, strong) UILabel *bioErrorLabel;

@property (nonatomic, strong) UIView *passwordContainer;
@property (nonatomic, strong) UILabel *passwordLabel;
@property (nonatomic, strong) UIButton *changePasswordButton;

@property (nonatomic, strong) UIView *buttonContainer;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *cancelButton;

// Data
@property (nonatomic, strong) NSMutableDictionary *editedData;
@property (nonatomic, strong) NSMutableDictionary *passwordData;

@end

@implementation YALEditProfileView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];
        [self setupActions];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor systemBackgroundColor];
    //self.bioTextView.delegate = self;
    // Scroll View
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self addSubview:self.scrollView];
    
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    
    // Avatar Section
    self.avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.avatarButton.backgroundColor = [UIColor systemGray6Color];
    self.avatarButton.layer.cornerRadius = 60;
    self.avatarButton.layer.masksToBounds = YES;
    self.avatarButton.layer.borderWidth = 2;
    self.avatarButton.layer.borderColor = [UIColor systemGray3Color].CGColor;
    
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.layer.cornerRadius = 58;
    self.avatarImageView.layer.masksToBounds = YES;
    [self.avatarButton addSubview:self.avatarImageView];
    
    self.avatarLabel = [[UILabel alloc] init];
    self.avatarLabel.text = @"点击更换头像";
    self.avatarLabel.font = [UIFont systemFontOfSize:14];
    self.avatarLabel.textColor = [UIColor systemGrayColor];
    self.avatarLabel.textAlignment = NSTextAlignmentCenter;
    [self.avatarButton addSubview:self.avatarLabel];
    
    [self.contentView addSubview:self.avatarButton];
    
    // Nickname Section
    self.nicknameContainer = [[UIView alloc] init];
    [self.contentView addSubview:self.nicknameContainer];
    
    self.nicknameLabel = [[UILabel alloc] init];
    self.nicknameLabel.text = @"昵称";
    self.nicknameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.nicknameContainer addSubview:self.nicknameLabel];
    
    self.nicknameTextField = [[UITextField alloc] init];
    self.nicknameTextField.placeholder = @"请输入昵称";
    self.nicknameTextField.font = [UIFont systemFontOfSize:16];
    self.nicknameTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.nicknameTextField.backgroundColor = [UIColor systemGray6Color];
    [self.nicknameContainer addSubview:self.nicknameTextField];
    
    self.nicknameErrorLabel = [[UILabel alloc] init];
    self.nicknameErrorLabel.font = [UIFont systemFontOfSize:13];
    self.nicknameErrorLabel.textColor = [UIColor systemRedColor];
    self.nicknameErrorLabel.hidden = YES;
    [self.nicknameContainer addSubview:self.nicknameErrorLabel];
    
    // Bio Section
    self.bioContainer = [[UIView alloc] init];
    [self.contentView addSubview:self.bioContainer];
    
    self.bioLabel = [[UILabel alloc] init];
    self.bioLabel.text = @"个人简介";
    self.bioLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.bioContainer addSubview:self.bioLabel];
    
    self.bioTextView = [[UITextView alloc] init];
    self.bioTextView.font = [UIFont systemFontOfSize:16];
    self.bioTextView.backgroundColor = [UIColor systemGray6Color];
    self.bioTextView.layer.cornerRadius = 6;
    self.bioTextView.layer.masksToBounds = YES;
    self.bioTextView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
    [self.bioContainer addSubview:self.bioTextView];
    
    self.bioErrorLabel = [[UILabel alloc] init];
    self.bioErrorLabel.font = [UIFont systemFontOfSize:13];
    self.bioErrorLabel.textColor = [UIColor systemRedColor];
    self.bioErrorLabel.hidden = YES;
    [self.bioContainer addSubview:self.bioErrorLabel];
    
    // Password Section
    self.passwordContainer = [[UIView alloc] init];
    [self.contentView addSubview:self.passwordContainer];
    
    self.passwordLabel = [[UILabel alloc] init];
    self.passwordLabel.text = @"密码";
    self.passwordLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.passwordContainer addSubview:self.passwordLabel];
    
    self.changePasswordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.changePasswordButton setTitle:@"修改密码" forState:UIControlStateNormal];
    self.changePasswordButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.passwordContainer addSubview:self.changePasswordButton];
    
    // Buttons
    self.buttonContainer = [[UIView alloc] init];
    [self.contentView addSubview:self.buttonContainer];
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveButton setTitle:@"保存" forState:UIControlStateNormal];
    self.saveButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.saveButton.backgroundColor = [UIColor systemBlueColor];
    self.saveButton.tintColor = [UIColor whiteColor];
    self.saveButton.layer.cornerRadius = 8;
    self.saveButton.layer.masksToBounds = YES;
    [self.buttonContainer addSubview:self.saveButton];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:17];
    self.cancelButton.tintColor = [UIColor systemGrayColor];
    [self.buttonContainer addSubview:self.cancelButton];
    
    // Initialize data containers
    self.editedData = [NSMutableDictionary dictionary];
    self.passwordData = [NSMutableDictionary dictionary];
}

- (void)setupConstraints {
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    // Avatar
    [self.avatarButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(40);
        make.centerX.equalTo(self.contentView);
        make.width.height.equalTo(@120);
    }];
    
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.avatarButton).insets(UIEdgeInsetsMake(2, 2, 2, 2));
    }];
    
    [self.avatarLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.avatarButton).offset(-10);
        make.centerX.equalTo(self.avatarButton);
    }];
    
    // Nickname
    [self.nicknameContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarButton.mas_bottom).offset(40);
        make.left.right.equalTo(self.contentView).inset(20);
    }];
    
    [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.nicknameContainer);
    }];
    
    [self.nicknameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.nicknameContainer);
        make.height.equalTo(@44);
    }];
    
    [self.nicknameErrorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameTextField.mas_bottom).offset(4);
        make.left.right.equalTo(self.nicknameContainer);
        make.bottom.equalTo(self.nicknameContainer);
    }];
    
    // Bio
    [self.bioContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nicknameContainer.mas_bottom).offset(24);
        make.left.right.equalTo(self.contentView).inset(20);
    }];
    
    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.bioContainer);
    }];
    
    [self.bioTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.bioContainer);
        make.height.equalTo(@120);
    }];
    
    [self.bioErrorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioTextView.mas_bottom).offset(4);
        make.left.right.equalTo(self.bioContainer);
        make.bottom.equalTo(self.bioContainer);
    }];
    
    // Password
    [self.passwordContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bioContainer.mas_bottom).offset(24);
        make.left.right.equalTo(self.contentView).inset(20);
    }];
    
    [self.passwordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.passwordContainer);
    }];
    
    [self.changePasswordButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passwordLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.passwordContainer);
        make.height.equalTo(@44);
        make.bottom.equalTo(self.passwordContainer);
    }];
    
    // Buttons
    [self.buttonContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passwordContainer.mas_bottom).offset(40);
        make.left.right.equalTo(self.contentView).inset(20);
        make.bottom.equalTo(self.contentView).offset(-40);
    }];
    
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.buttonContainer);
        make.left.right.equalTo(self.buttonContainer);
        make.height.equalTo(@50);
    }];
    
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.saveButton.mas_bottom).offset(16);
        make.centerX.equalTo(self.buttonContainer);
        make.bottom.equalTo(self.buttonContainer);
    }];
}

- (void)setupActions {
    [self.avatarButton addTarget:self action:@selector(avatarButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.changePasswordButton addTarget:self action:@selector(changePasswordButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.nicknameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

#pragma mark - Public Methods

- (void)applyUser:(YALAuthUserModel *)user {
    if (!user) return;
    
    // Set nickname
    if (user.nickname) {
        self.nicknameTextField.text = user.nickname;
        self.editedData[@"nickname"] = user.nickname;
    }
    
    // Set bio
    if (user.bio) {
        self.bioTextView.text = user.bio;
        self.editedData[@"bio"] = user.bio;
    }
    
    // Set avatar if available
    // Note: This would typically be loaded from a URL
    // For now, we'll just show a placeholder
    if (user.avatar) {
        // In a real app, you would load the image from the URL
        // For now, we'll use a system image as placeholder
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
    }
}

- (NSDictionary *)getEditedData {
    return [self.editedData copy];
}

- (NSDictionary *)getPasswordData {
    return [self.passwordData copy];
}

- (void)setAvatarImage:(UIImage *)image {
    self.avatarImageView.image = image;
    self.editedData[@"avatar"] = image;
}

- (void)showErrorMessage:(NSString *)message forField:(NSString *)field {
    if ([field isEqualToString:@"nickname"]) {
        self.nicknameErrorLabel.text = message;
        self.nicknameErrorLabel.hidden = NO;
        self.nicknameTextField.layer.borderColor = [UIColor systemRedColor].CGColor;
        self.nicknameTextField.layer.borderWidth = 1;
        self.nicknameTextField.layer.cornerRadius = 6;
    } else if ([field isEqualToString:@"bio"]) {
        self.bioErrorLabel.text = message;
        self.bioErrorLabel.hidden = NO;
        self.bioTextView.layer.borderColor = [UIColor systemRedColor].CGColor;
        self.bioTextView.layer.borderWidth = 1;
    }
}

- (void)clearErrorMessageForField:(NSString *)field {
    if ([field isEqualToString:@"nickname"]) {
        self.nicknameErrorLabel.hidden = YES;
        self.nicknameTextField.layer.borderWidth = 0;
    } else if ([field isEqualToString:@"bio"]) {
        self.bioErrorLabel.hidden = YES;
        self.bioTextView.layer.borderWidth = 0;
    }
}

#pragma mark - Actions

- (void)avatarButtonTapped {
    if ([self.delegate respondsToSelector:@selector(editProfileViewDidTapAvatar:)]) {
        [self.delegate editProfileViewDidTapAvatar:self];
    }
}

- (void)saveButtonTapped {
    // Update edited data from text fields
    if (self.nicknameTextField.text.length > 0) {
        self.editedData[@"nickname"] = self.nicknameTextField.text;
    }
    
    if (self.bioTextView.text.length > 0) {
        self.editedData[@"bio"] = self.bioTextView.text;
    }
    
    if ([self.delegate respondsToSelector:@selector(editProfileViewDidTapSave:)]) {
        [self.delegate editProfileViewDidTapSave:self];
    }
}

- (void)cancelButtonTapped {
    if ([self.delegate respondsToSelector:@selector(editProfileViewDidTapCancel:)]) {
        [self.delegate editProfileViewDidTapCancel:self];
    }
}

- (void)changePasswordButtonTapped {
    if ([self.delegate respondsToSelector:@selector(editProfileViewDidTapChangePassword:)]) {
        [self.delegate editProfileViewDidTapChangePassword:self];
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    // Clear error when user starts typing
    if (textField == self.nicknameTextField) {
        [self clearErrorMessageForField:@"nickname"];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if (textView == self.bioTextView) {
        [self clearErrorMessageForField:@"bio"];
    }
}

@end
