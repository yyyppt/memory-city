//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//
#import "YALMineView.h"
#import <Masonry/Masonry.h>

@interface YALMineView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *profileCard;
@property (nonatomic, strong) UIView *profileTintView;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UIButton *editProfileButton;

@property (nonatomic, strong) UILabel *publishedValueLabel;
@property (nonatomic, strong) UILabel *memoryValueLabel;
@property (nonatomic, strong) UILabel *trackValueLabel;

@property (nonatomic, strong) UILabel *quickSectionLabel;
@property (nonatomic, strong) NSArray<UIButton *> *quickActionButtons;

@property (nonatomic, strong) UILabel *serviceSectionLabel;
@property (nonatomic, strong) NSArray<UIButton *> *serviceButtons;

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
    [self buildQuickSection];
    [self buildServiceSection];
    [self setupMainConstraints];
}

- (void)buildProfileCard {
    self.profileCard = [[UIView alloc] init];
    if (@available(iOS 13.0, *)) {
        self.profileCard.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
            if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor secondarySystemBackgroundColor];
            }
            return [UIColor colorWithRed:0.998 green:0.992 blue:0.985 alpha:1.0];
        }];
    } else {
        self.profileCard.backgroundColor = [UIColor colorWithRed:0.998 green:0.992 blue:0.985 alpha:1.0];
    }
    self.profileCard.layer.cornerRadius = 24.0;
    self.profileCard.layer.masksToBounds = YES;
    [self.contentView addSubview:self.profileCard];

    self.profileTintView = [[UIView alloc] init];
    self.profileTintView.backgroundColor = [self profilePanelColor];
    self.profileTintView.layer.cornerRadius = 18.0;
    self.profileTintView.layer.borderWidth = 1.0;
    self.profileTintView.layer.borderColor = [self subtleAccentBorderColor].CGColor;
    [self.profileCard addSubview:self.profileTintView];

    self.avatarContainer = [[UIView alloc] init];
    self.avatarContainer.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.10];
    self.avatarContainer.layer.cornerRadius = 38.0;
    self.avatarContainer.layer.borderWidth = 1.0;
    self.avatarContainer.layer.borderColor = [[self accentColor] colorWithAlphaComponent:0.12].CGColor;
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

    UIView *publishedStat = [self makeStatViewWithTitle:@"发布" valueLabel:&_publishedValueLabel];
    UIView *memoryStat = [self makeStatViewWithTitle:@"回忆" valueLabel:&_memoryValueLabel];
    UIView *trackStat = [self makeStatViewWithTitle:@"足迹" valueLabel:&_trackValueLabel];
    UIView *firstSeparator = [self makeStatSeparatorView];
    UIView *secondSeparator = [self makeStatSeparatorView];
    [self.profileTintView addSubview:publishedStat];
    [self.profileTintView addSubview:memoryStat];
    [self.profileTintView addSubview:trackStat];
    [self.profileTintView addSubview:firstSeparator];
    [self.profileTintView addSubview:secondSeparator];

    [self.profileTintView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.profileCard.mas_left).offset(14.0);
        make.right.equalTo(self.profileCard.mas_right).offset(-14.0);
        make.bottom.equalTo(self.profileCard.mas_bottom).offset(-14.0);
        make.height.mas_equalTo(64.0);
    }];
    [self.avatarContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.profileCard.mas_left).offset(18.0);
        make.top.equalTo(self.profileCard.mas_top).offset(22.0);
        make.width.height.mas_equalTo(76.0);
    }];
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.avatarContainer);
        make.width.height.mas_equalTo(48.0);
    }];
    [self.editProfileButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.profileCard.mas_top).offset(24.0);
        make.right.equalTo(self.profileCard.mas_right).offset(-18.0);
        make.width.mas_equalTo(84.0);
        make.height.mas_equalTo(32.0);
    }];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarContainer.mas_right).offset(14.0);
        make.top.equalTo(self.profileCard.mas_top).offset(28.0);
        make.right.lessThanOrEqualTo(self.editProfileButton.mas_left).offset(-12.0);
    }];
    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nameLabel);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4.0);
        make.right.equalTo(self.profileCard.mas_right).offset(-18.0);
    }];
    [publishedStat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.profileTintView);
    }];
    [memoryStat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(firstSeparator.mas_right);
        make.top.bottom.width.equalTo(publishedStat);
    }];
    [trackStat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(secondSeparator.mas_right);
        make.right.top.bottom.equalTo(self.profileTintView);
        make.top.bottom.width.equalTo(publishedStat);
    }];
    [firstSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(publishedStat.mas_right);
        make.width.mas_equalTo(1.0);
        make.centerY.equalTo(self.profileTintView);
        make.height.mas_equalTo(28.0);
    }];
    [secondSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(memoryStat.mas_right);
        make.width.height.centerY.equalTo(firstSeparator);
    }];
}

- (void)buildQuickSection {
    self.quickSectionLabel = [self labelWithFont:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]
                                           color:[UIColor labelColor]];
    self.quickSectionLabel.text = @"常用入口";
    [self.contentView addSubview:self.quickSectionLabel];

    self.quickActionButtons = @[
        [self makeQuickActionButtonWithTitle:@"我的回忆" subtitle:@"回看时间线" iconName:@"wand.and.stars" tag:0],
        [self makeQuickActionButtonWithTitle:@"地图足迹" subtitle:@"继续探索地点" iconName:@"location.fill" tag:1],
        [self makeQuickActionButtonWithTitle:@"消息中心" subtitle:@"查看互动提醒" iconName:@"envelope.fill" tag:2],
        [self makeQuickActionButtonWithTitle:@"继续发布" subtitle:@"记录新的瞬间" iconName:@"plus.circle.fill" tag:3]
    ];
    for (UIButton *button in self.quickActionButtons) {
        [self.contentView addSubview:button];
    }
}

- (void)buildServiceSection {
    self.serviceSectionLabel = [self labelWithFont:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]
                                             color:[UIColor labelColor]];
    self.serviceSectionLabel.text = @"更多服务";
    [self.contentView addSubview:self.serviceSectionLabel];

    self.serviceButtons = @[
        [self makeServiceButtonWithTitle:@"收藏灵感" subtitle:@"把喜欢的城市碎片先收起来" iconName:@"heart.fill" tag:0],
        [self makeServiceButtonWithTitle:@"草稿箱" subtitle:@"发布前先留一份待编辑草稿" iconName:@"doc.text.fill" tag:1],
        [self makeServiceButtonWithTitle:@"账号与设置" subtitle:@"通知、隐私和账号管理" iconName:@"gearshape.fill" tag:2]
    ];
    for (UIButton *button in self.serviceButtons) {
        [self.contentView addSubview:button];
    }
}

- (void)setupMainConstraints {
    [self.profileCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(12.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
        make.height.mas_equalTo(190.0);
    }];
    [self.quickSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.profileCard.mas_bottom).offset(26.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
    }];

    UIButton *quickFirst = self.quickActionButtons.firstObject;
    UIButton *quickSecond = self.quickActionButtons.count > 1 ? self.quickActionButtons[1] : nil;
    UIButton *quickThird = self.quickActionButtons.count > 2 ? self.quickActionButtons[2] : nil;
    UIButton *quickFourth = self.quickActionButtons.count > 3 ? self.quickActionButtons[3] : nil;

    [quickFirst mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.quickSectionLabel.mas_bottom).offset(14.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.height.mas_equalTo(94.0);
    }];
    [quickSecond mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.height.width.equalTo(quickFirst);
        make.left.equalTo(quickFirst.mas_right).offset(12.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
    }];
    [quickThird mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(quickFirst.mas_bottom).offset(12.0);
        make.left.height.width.equalTo(quickFirst);
    }];
    [quickFourth mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.height.width.equalTo(quickThird);
        make.left.equalTo(quickThird.mas_right).offset(12.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
    }];

    [self.serviceSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(quickThird.mas_bottom).offset(26.0);
        make.left.right.equalTo(self.quickSectionLabel);
    }];

    UIButton *firstService = self.serviceButtons.firstObject;
    UIButton *secondService = self.serviceButtons.count > 1 ? self.serviceButtons[1] : nil;
    UIButton *thirdService = self.serviceButtons.count > 2 ? self.serviceButtons[2] : nil;

    [firstService mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.serviceSectionLabel.mas_bottom).offset(14.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
        make.height.mas_equalTo(72.0);
    }];
    [secondService mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(firstService.mas_bottom).offset(10.0);
        make.left.right.height.equalTo(firstService);
    }];
    [thirdService mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(secondService.mas_bottom).offset(10.0);
        make.left.right.height.equalTo(firstService);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-24.0);
    }];
}

- (UIView *)makeStatViewWithTitle:(NSString *)title valueLabel:(UILabel * __strong *)valueLabel {
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [UIColor clearColor];

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
        make.top.equalTo(container.mas_top);
        make.left.right.equalTo(container);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(value.mas_bottom).offset(2.0);
        make.left.right.equalTo(container);
        make.bottom.equalTo(container.mas_bottom).offset(-4.0);
    }];
    return container;
}

- (UIView *)makeStatSeparatorView {
    UIView *separatorView = [[UIView alloc] init];
    separatorView.backgroundColor = [self borderColor];
    return separatorView;
}

- (UIButton *)makeQuickActionButtonWithTitle:(NSString *)title
                                    subtitle:(NSString *)subtitle
                                    iconName:(NSString *)iconName
                                         tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = tag;
    button.backgroundColor = [self cardBackgroundColor];
    button.layer.cornerRadius = 20.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [self borderColor].CGColor;
    [button addTarget:self action:@selector(quickActionTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIView *iconBadge = [[UIView alloc] init];
    iconBadge.userInteractionEnabled = NO;
    iconBadge.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.12];
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

    [iconBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(button.mas_left).offset(14.0);
        make.top.equalTo(button.mas_top).offset(16.0);
        make.width.height.mas_equalTo(36.0);
    }];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(iconBadge);
        make.width.height.mas_equalTo(18.0);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(button.mas_left).offset(14.0);
        make.right.equalTo(button.mas_right).offset(-14.0);
        make.top.equalTo(iconBadge.mas_bottom).offset(6.0);
    }];
    [subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(titleLabel);
        make.top.equalTo(titleLabel.mas_bottom).offset(1.0);
    }];

    return button;
}

- (UIButton *)makeServiceButtonWithTitle:(NSString *)title
                                subtitle:(NSString *)subtitle
                                iconName:(NSString *)iconName
                                     tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = tag;
    button.backgroundColor = [self cardBackgroundColor];
    button.layer.cornerRadius = 18.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [self borderColor].CGColor;
    [button addTarget:self action:@selector(serviceTapped:) forControlEvents:UIControlEventTouchUpInside];

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

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    return label;
}

#pragma mark - Actions

- (void)editProfileTapped {
    if ([self.delegate respondsToSelector:@selector(mineViewDidTapEditProfile:)]) {
        [self.delegate mineViewDidTapEditProfile:self];
    }
}

- (void)quickActionTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(mineView:didTapQuickActionAtIndex:)]) {
        [self.delegate mineView:self didTapQuickActionAtIndex:sender.tag];
    }
}

- (void)serviceTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(mineView:didTapServiceAtIndex:)]) {
        [self.delegate mineView:self didTapServiceAtIndex:sender.tag];
    }
}

- (void)applyProfile:(YALMineProfileModel *)profile {
    self.nameLabel.text = profile.name;
    self.bioLabel.text = profile.bio;
    self.publishedValueLabel.text = profile.publishedCount;
    self.memoryValueLabel.text = profile.memoryCount;
    self.trackValueLabel.text = profile.trackCount;
}

#pragma mark - Colors

- (UIColor *)accentColor {
    return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

- (UIColor *)pageBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGroupedBackgroundColor];
    }
    return [UIColor colorWithWhite:0.97 alpha:1.0];
}

- (UIColor *)cardBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondarySystemBackgroundColor];
    }
    return [UIColor whiteColor];
}

- (UIColor *)profilePanelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
            if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [[UIColor tertiarySystemFillColor] colorWithAlphaComponent:0.55];
            }
            return [UIColor colorWithRed:0.995 green:0.972 blue:0.945 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.995 green:0.972 blue:0.945 alpha:1.0];
}

- (UIColor *)subtleAccentBorderColor {
    return [[self accentColor] colorWithAlphaComponent:0.08];
}

- (UIColor *)borderColor {
    return [UIColor colorWithWhite:0.0 alpha:0.05];
}

@end
