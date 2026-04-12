//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//
#import "YALMineView.h"
#import "YALAuthUserModel.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

static UIImage * _Nullable YALImageFromDataURLString(NSString *dataURL) {
    if (![dataURL isKindOfClass:[NSString class]]) return nil;
    if (![dataURL hasPrefix:@"data:image"]) return nil;
    NSRange commaRange = [dataURL rangeOfString:@","];
    if (commaRange.location == NSNotFound) return nil;
    NSString *base64Part = [dataURL substringFromIndex:commaRange.location + 1];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Part options:0];
    if (!data) return nil;
    return [UIImage imageWithData:data];
}

@interface YALMineView ()

@property (nonatomic, assign) BOOL guestLoginMode;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *profileCard;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *accountLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UIButton *editProfileButton;

@property (nonatomic, strong) UILabel *statsSectionLabel;
@property (nonatomic, strong) UIView *statsCardView;
@property (nonatomic, strong) UILabel *publicValueLabel;
@property (nonatomic, strong) UILabel *privateValueLabel;

@property (nonatomic, strong) UILabel *personalSectionLabel;
@property (nonatomic, strong) NSArray<UIButton *> *personalButtons;

@end

@implementation YALMineView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [self pageBackgroundColor];
        [self buildUI];
    }
    return self;
}

- (void)buildUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.contentView];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    [self buildProfileCard];
    [self buildStatsSection];
    [self buildPersonalSection];
    [self setupMainConstraints];
}

- (void)buildProfileCard {
    self.profileCard = [[UIView alloc] init];
    self.profileCard.backgroundColor = [self warmCardBackgroundColor];
    self.profileCard.layer.cornerRadius = 28.0;
    self.profileCard.layer.masksToBounds = NO;
    self.profileCard.layer.shadowColor = [UIColor colorWithRed:0.38 green:0.24 blue:0.12 alpha:1.0].CGColor;
    self.profileCard.layer.shadowOpacity = 0.10;
    self.profileCard.layer.shadowRadius = 22.0;
    self.profileCard.layer.shadowOffset = CGSizeMake(0.0, 10.0);
    [self.contentView addSubview:self.profileCard];

    self.avatarContainer = [[UIView alloc] init];
    // 淡黄色外圈，弱化装饰不抢视觉
    self.avatarContainer.backgroundColor = [UIColor clearColor];
    self.avatarContainer.layer.cornerRadius = 40.0;
    self.avatarContainer.layer.borderWidth = 1.5;
    self.avatarContainer.layer.borderColor = [[self accentColor] colorWithAlphaComponent:0.28].CGColor;
    [self.profileCard addSubview:self.avatarContainer];

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.avatarImageView.tintColor = [self accentColor];
    if (@available(iOS 13.0, *)) {
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
    }
    [self.avatarContainer addSubview:self.avatarImageView];

    self.nameLabel = [self labelWithFont:[UIFont systemFontOfSize:24.0 weight:UIFontWeightSemibold]
                                   color:[UIColor labelColor]];
    [self.profileCard addSubview:self.nameLabel];

    self.accountLabel = [self labelWithFont:[UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular]
                                       color:[UIColor secondaryLabelColor]];
    self.accountLabel.numberOfLines = 1;
    [self.profileCard addSubview:self.accountLabel];

    self.bioLabel = [self labelWithFont:[UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular]
                                  color:[UIColor secondaryLabelColor]];
    self.bioLabel.numberOfLines = 2;
    [self.profileCard addSubview:self.bioLabel];

    self.editProfileButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.editProfileButton.backgroundColor = [UIColor systemBackgroundColor];
    self.editProfileButton.layer.cornerRadius = 16.0;
    self.editProfileButton.layer.borderWidth = 1.0;
    self.editProfileButton.layer.borderColor = [[self accentColor] colorWithAlphaComponent:0.12].CGColor;
    self.editProfileButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    [self.editProfileButton setTitle:@"编辑资料" forState:UIControlStateNormal];
    [self.editProfileButton setTitleColor:[self accentColor] forState:UIControlStateNormal];
    [self.editProfileButton addTarget:self
                               action:@selector(editProfileTapped)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.profileCard addSubview:self.editProfileButton];

    [self.avatarContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.profileCard.mas_left).offset(18.0);
        make.centerY.equalTo(self.profileCard.mas_centerY).offset(2.0);
        make.width.height.mas_equalTo(80.0);
    }];
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.avatarContainer);
        make.width.height.mas_equalTo(72.0);
    }];
    [self.editProfileButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.avatarContainer.mas_centerY);
        make.right.equalTo(self.profileCard.mas_right).offset(-18.0);
        make.width.mas_equalTo(84.0);
        make.height.mas_equalTo(32.0);
    }];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarContainer.mas_right).offset(14.0);
        make.top.equalTo(self.profileCard.mas_top).offset(24.0);
        make.right.lessThanOrEqualTo(self.editProfileButton.mas_left).offset(-10.0);
    }];
    [self.accountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nameLabel);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4.0);
        make.right.lessThanOrEqualTo(self.editProfileButton.mas_left).offset(-10.0);
    }];
    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nameLabel);
        make.top.equalTo(self.accountLabel.mas_bottom).offset(4.0);
        make.right.equalTo(self.profileCard.mas_right).offset(-18.0);
    }];
}

- (void)buildStatsSection {
    self.statsSectionLabel = [self labelWithFont:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]
                                           color:[UIColor labelColor]];
    self.statsSectionLabel.text = @"创作者数据";
    [self.contentView addSubview:self.statsSectionLabel];

    self.statsCardView = [[UIView alloc] init];
    self.statsCardView.backgroundColor = [self cardBackgroundColor];
    self.statsCardView.layer.cornerRadius = 22.0;
    self.statsCardView.layer.borderWidth = 1.0;
    self.statsCardView.layer.borderColor = [self borderColor].CGColor;
    self.statsCardView.layer.shadowColor = [UIColor colorWithRed:0.38 green:0.24 blue:0.12 alpha:1.0].CGColor;
    self.statsCardView.layer.shadowOpacity = 0.07;
    self.statsCardView.layer.shadowRadius = 16.0;
    self.statsCardView.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    [self.contentView addSubview:self.statsCardView];

    UIControl *publicStat = [self makeStatViewWithTitle:@"公开中" valueLabel:&_publicValueLabel tag:0];
    UIControl *privateStat = [self makeStatViewWithTitle:@"私密中" valueLabel:&_privateValueLabel tag:1];
    self.publicValueLabel.text = @"--";
    self.privateValueLabel.text = @"--";
    
    UIView *firstSeparator = [self makeStatSeparatorView];
    [self.statsCardView addSubview:publicStat];
    [self.statsCardView addSubview:privateStat];
    [self.statsCardView addSubview:firstSeparator];

    [publicStat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.statsCardView);
    }];
    [privateStat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(firstSeparator.mas_right);
        make.right.top.bottom.equalTo(self.statsCardView);
        make.top.bottom.width.equalTo(publicStat);
    }];
    [firstSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(publicStat.mas_right);
        make.width.mas_equalTo(1.0);
        make.centerY.equalTo(self.statsCardView);
        make.height.mas_equalTo(32.0);
    }];
}

- (void)buildPersonalSection {
    self.personalSectionLabel = [self labelWithFont:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]
                                              color:[UIColor labelColor]];
    self.personalSectionLabel.text = @"个人内容";
    [self.contentView addSubview:self.personalSectionLabel];

    self.personalButtons = @[
        [self makeListButtonWithTitle:@"我的回忆"
                             subtitle:@"回看时间线和记忆碎片"
                             iconName:@"clock.arrow.circlepath"
                                  tag:0
                               action:@selector(personalTapped:)],
        [self makeListButtonWithTitle:@"地图足迹"
                             subtitle:@"继续探索去过的地点"
                             iconName:@"location.fill"
                                  tag:1
                               action:@selector(personalTapped:)],
        [self makeListButtonWithTitle:@"我的点赞"
                             subtitle:@"查看收到的点赞记录"
                             iconName:@"heart.fill"
                                  tag:2
                               action:@selector(personalTapped:)],
        [self makeListButtonWithTitle:@"我的收藏"
                             subtitle:@"管理收藏的内容"
                             iconName:@"star.fill"
                                  tag:3
                               action:@selector(personalTapped:)]
    ];
    for (UIButton *button in self.personalButtons) {
        [self.contentView addSubview:button];
    }
}

- (void)setupMainConstraints {
    [self.profileCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(12.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
        make.height.mas_equalTo(128.0);
    }];

    [self.statsSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.profileCard.mas_bottom).offset(26.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
    }];
    [self.statsCardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statsSectionLabel.mas_bottom).offset(14.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
        make.height.mas_equalTo(82.0);
    }];

    [self.personalSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statsCardView.mas_bottom).offset(26.0);
        make.left.right.equalTo(self.statsSectionLabel);
    }];

    UIButton *personalFirst = self.personalButtons.firstObject;
    UIButton *personalSecond = self.personalButtons.count > 1 ? self.personalButtons[1] : nil;
    UIButton *personalThird = self.personalButtons.count > 2 ? self.personalButtons[2] : nil;
    UIButton *personalFourth = self.personalButtons.count > 3 ? self.personalButtons[3] : nil;

    [personalFirst mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.personalSectionLabel.mas_bottom).offset(14.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
        make.height.mas_equalTo(72.0);
    }];
    [personalSecond mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(personalFirst.mas_bottom).offset(10.0);
        make.left.right.height.equalTo(personalFirst);
    }];
    [personalThird mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(personalSecond.mas_bottom).offset(10.0);
        make.left.right.height.equalTo(personalFirst);
    }];
    [personalFourth mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(personalThird.mas_bottom).offset(10.0);
        make.left.right.height.equalTo(personalFirst);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-24.0);
    }];
}

- (UIButton *)makeListButtonWithTitle:(NSString *)title
                             subtitle:(NSString *)subtitle
                             iconName:(NSString *)iconName
                                  tag:(NSInteger)tag
                               action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = tag;
    button.backgroundColor = [self cardBackgroundColor];
    button.layer.cornerRadius = 22.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [self borderColor].CGColor;
    button.layer.shadowColor = [UIColor colorWithRed:0.38 green:0.24 blue:0.12 alpha:1.0].CGColor;
    button.layer.shadowOpacity = 0.06;
    button.layer.shadowRadius = 14.0;
    button.layer.shadowOffset = CGSizeMake(0.0, 7.0);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

    UIView *iconBadge = [[UIView alloc] init];
    iconBadge.userInteractionEnabled = NO;
    iconBadge.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.10];
    iconBadge.layer.cornerRadius = 18.0;
    [button addSubview:iconBadge];

    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.userInteractionEnabled = NO;
    iconView.tintColor = [self accentColor];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    if (@available(iOS 13.0, *)) {
        iconView.image = [UIImage systemImageNamed:iconName];
    }
    [iconBadge addSubview:iconView];

    UILabel *titleLabel = [self labelWithFont:[UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold]
                                        color:[UIColor labelColor]];
    titleLabel.userInteractionEnabled = NO;
    titleLabel.text = title;
    [button addSubview:titleLabel];

    UILabel *subtitleLabel = [self labelWithFont:[UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular]
                                           color:[UIColor secondaryLabelColor]];
    subtitleLabel.userInteractionEnabled = NO;
    subtitleLabel.text = subtitle;
    [button addSubview:subtitleLabel];

    UIImageView *chevronView = [[UIImageView alloc] init];
    chevronView.userInteractionEnabled = NO;
    chevronView.tintColor = [UIColor tertiaryLabelColor];
    chevronView.contentMode = UIViewContentModeScaleAspectFit;
    if (@available(iOS 13.0, *)) {
        chevronView.image = [UIImage systemImageNamed:@"chevron.right"];
    }
    [button addSubview:chevronView];

    [iconBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(button.mas_left).offset(16.0);
        make.centerY.equalTo(button.mas_centerY);
        make.width.height.mas_equalTo(36.0);
    }];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(iconBadge);
        make.width.height.mas_equalTo(18.0);
    }];
    [chevronView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(button.mas_right).offset(-18.0);
        make.centerY.equalTo(button.mas_centerY);
        make.width.mas_equalTo(12.0);
        make.height.mas_equalTo(20.0);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(iconBadge.mas_right).offset(12.0);
        make.top.equalTo(button.mas_top).offset(16.0);
        make.right.lessThanOrEqualTo(chevronView.mas_left).offset(-10.0);
    }];
    [subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel);
        make.top.equalTo(titleLabel.mas_bottom).offset(1.0);
        make.right.lessThanOrEqualTo(chevronView.mas_left).offset(-10.0);
    }];

    return button;
}

- (UIControl *)makeStatViewWithTitle:(NSString *)title
                          valueLabel:(UILabel * __strong *)valueLabel
                                 tag:(NSInteger)tag {
    UIControl *container = [[UIControl alloc] init];
    container.backgroundColor = [UIColor clearColor];
    container.tag = tag;
    [container addTarget:self action:@selector(statTapped:) forControlEvents:UIControlEventTouchUpInside];

    UILabel *value = [self labelWithFont:[UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold]
                                   color:[UIColor labelColor]];
    value.textAlignment = NSTextAlignmentCenter;
    [container addSubview:value];
    if (valueLabel) {
        *valueLabel = value;
    }

    UILabel *titleLabel = [self labelWithFont:[UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium]
                                        color:[UIColor secondaryLabelColor]];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = title;
    [container addSubview:titleLabel];

    [value mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(container.mas_top).offset(14.0);
        make.left.right.equalTo(container);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(value.mas_bottom).offset(2.0);
        make.left.right.equalTo(container);
        make.bottom.equalTo(container.mas_bottom).offset(-12.0);
    }];
    return container;
}

- (UIView *)makeStatSeparatorView {
    UIView *separatorView = [[UIView alloc] init];
    separatorView.backgroundColor = [self borderColor];
    return separatorView;
}

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    return label;
}

#pragma mark - Actions

- (void)editProfileTapped {
    if (self.guestLoginMode) {
        if ([self.delegate respondsToSelector:@selector(mineViewDidTapLogin:)]) {
            [self.delegate mineViewDidTapLogin:self];
        }
        return;
    }
    if ([self.delegate respondsToSelector:@selector(mineViewDidTapEditProfile:)]) {
        [self.delegate mineViewDidTapEditProfile:self];
    }
}

- (void)statTapped:(UIControl *)sender {
    if ([self.delegate respondsToSelector:@selector(mineView:didTapStatAtIndex:)]) {
        [self.delegate mineView:self didTapStatAtIndex:sender.tag];
    }
}

- (void)personalTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(mineView:didTapPersonalItemAtIndex:)]) {
        [self.delegate mineView:self didTapPersonalItemAtIndex:sender.tag];
    }
}

- (void)applyProfile:(YALMineProfileModel *)profile {
    self.nameLabel.text = profile.name;
    self.bioLabel.text = profile.bio;
    self.accountLabel.text = @"";
    [self updateCreatorStatsWithPublicCount:nil privateCount:nil];
}

- (void)applyAuthUser:(YALAuthUserModel *)user {
    if (!user) {
        return;
    }
    [self setGuestLoginModeEnabled:NO];
    
    // 设置显示名称：显示nickname，如果没有则显示"用户"
    NSString *name = user.nickname.length > 0 ? user.nickname : @"用户";
    self.nameLabel.text = name;
    
    // 账号行：优先显示 username，并附带 userId
    NSString *username = [user.username isKindOfClass:[NSString class]] ? [user.username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
    BOOL hasUsername = (username.length > 0);
    if (hasUsername && user.userId > 0) {
        self.accountLabel.text = [NSString stringWithFormat:@"账号：%@", username];
    } else if (hasUsername) {
        self.accountLabel.text = [NSString stringWithFormat:@"账号：%@", username];
    } else if (user.userId > 0) {
        self.accountLabel.text = [NSString stringWithFormat:@"账号ID：%ld", (long)user.userId];
    } else {
        self.accountLabel.text = @"账号ID：暂无";
    }

    // bio：显示在昵称下面
    if (user.bio.length > 0) {
        self.bioLabel.text = user.bio;
    } else {
        self.bioLabel.text = @"暂无个性签名";
    }

    if (user.avatar.length > 0) {
        UIImage *decodedImage = YALImageFromDataURLString(user.avatar);
        if (decodedImage) {
            self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.avatarImageView.layer.cornerRadius = 34.0;
            self.avatarImageView.clipsToBounds = YES;
            self.avatarImageView.tintColor = nil;
            self.avatarImageView.image = decodedImage;
            return;
        }

        NSURL *avatarURL = [NSURL URLWithString:user.avatar];
        if (avatarURL && avatarURL.scheme.length > 0) {
            self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.avatarImageView.tintColor = nil;
            self.avatarImageView.layer.cornerRadius = 34.0;
            self.avatarImageView.clipsToBounds = YES;
            UIImage *placeholder = nil;
            if (@available(iOS 13.0, *)) {
                placeholder = [UIImage systemImageNamed:@"person.crop.circle.fill"];
            }
            [self.avatarImageView sd_setImageWithURL:avatarURL
                                    placeholderImage:placeholder
                                             options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
            return;
        }
    }

    // fallback
    [self.avatarImageView sd_cancelCurrentImageLoad];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.avatarImageView.layer.cornerRadius = 34.0;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.tintColor = [self accentColor];
    if (@available(iOS 13.0, *)) {
        self.avatarImageView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
    } else {
        self.avatarImageView.image = nil;
    }
}

- (void)setGuestLoginModeEnabled:(BOOL)enabled {
    self.guestLoginMode = enabled;
    if (enabled) {
        [self.avatarImageView sd_cancelCurrentImageLoad];
        self.avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.avatarImageView.layer.cornerRadius = 34.0;
        self.avatarImageView.clipsToBounds = YES;
        self.avatarImageView.tintColor = [self accentColor];
        if (@available(iOS 13.0, *)) {
            self.avatarImageView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        }
        self.nameLabel.text = @"未登录";
        self.accountLabel.text = @"账号ID：暂无";
        self.bioLabel.text = @"登录后可同步资料，请求将自动携带双 token";
        [self updateCreatorStatsWithPublicCount:nil privateCount:nil];
        [self.editProfileButton setTitle:@"立即登录" forState:UIControlStateNormal];
    } else {
        [self.editProfileButton setTitle:@"编辑资料" forState:UIControlStateNormal];
    }
}

- (void)updateCreatorStatsWithPublicCount:(nullable NSNumber *)publicCount
                              privateCount:(nullable NSNumber *)privateCount {
    self.publicValueLabel.text = [publicCount respondsToSelector:@selector(integerValue)]
        ? [NSString stringWithFormat:@"%ld", (long)MAX(publicCount.integerValue, 0)]
        : @"--";
    self.privateValueLabel.text = [privateCount respondsToSelector:@selector(integerValue)]
        ? [NSString stringWithFormat:@"%ld", (long)MAX(privateCount.integerValue, 0)]
        : @"--";
}

#pragma mark - Colors

- (UIColor *)accentColor {
    return [UIColor colorWithRed:0.98 green:0.52 blue:0.18 alpha:1.0];
}

- (UIColor *)pageBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:0.075 green:0.068 blue:0.06 alpha:1.0];
            }
            return [UIColor colorWithRed:0.985 green:0.965 blue:0.935 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.985 green:0.965 blue:0.935 alpha:1.0];
}

- (UIColor *)cardBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor secondarySystemBackgroundColor];
            }
            return [UIColor colorWithRed:1.0 green:0.995 blue:0.985 alpha:1.0];
        }];
    }
    return [UIColor whiteColor];
}

- (UIColor *)warmCardBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
            if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor secondarySystemBackgroundColor];
            }
            return [UIColor colorWithRed:0.998 green:0.992 blue:0.985 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.998 green:0.992 blue:0.985 alpha:1.0];
}

- (UIColor *)borderColor {
    return [UIColor colorWithWhite:0.0 alpha:0.05];
}

@end
