//
//  YALMineController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALMineController.h"
#import "YALMemoryController.h"
#import "YALMapController.h"
#import "YALMessageController.h"
#import "YALReleaseController.h"
#import <Masonry/Masonry.h>

@interface YALMineController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *profileCard;
@property (nonatomic, strong) UIView *profileTintView;
@property (nonatomic, strong) NSArray<UIView *> *decorativeViews;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UIButton *editProfileButton;
@property (nonatomic, strong) NSArray<UIView *> *statViews;

@property (nonatomic, strong) UILabel *quickSectionLabel;
@property (nonatomic, strong) NSArray<UIButton *> *quickActionButtons;

@property (nonatomic, strong) UILabel *serviceSectionLabel;
@property (nonatomic, strong) NSArray<UIButton *> *serviceButtons;

@end

@implementation YALMineController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [self pageBackgroundColor];
    self.title = @"Mine";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationController.navigationBar.tintColor = [self accentColor];

    [self setupNavigationItems];
    [self buildUI];
}

- (void)setupNavigationItems {
    if (@available(iOS 13.0, *)) {
        UIImage *settingsImage = [UIImage systemImageNamed:@"slider.horizontal.3"];
        UIBarButtonItem *settingsItem =
        [[UIBarButtonItem alloc] initWithImage:settingsImage
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(settingsTapped)];
        settingsItem.tintColor = [self accentColor];
        self.navigationItem.rightBarButtonItem = settingsItem;
    } else {
        UIBarButtonItem *settingsItem =
        [[UIBarButtonItem alloc] initWithTitle:@"设置"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(settingsTapped)];
        self.navigationItem.rightBarButtonItem = settingsItem;
    }
}

- (void)buildUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.contentView];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
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
    self.profileCard.backgroundColor = [UIColor colorWithRed:1.0 green:0.98 blue:0.95 alpha:1.0];
    self.profileCard.layer.cornerRadius = 24.0;
    self.profileCard.layer.masksToBounds = YES;
    [self.contentView addSubview:self.profileCard];

    self.profileTintView = [[UIView alloc] init];
    self.profileTintView.backgroundColor = [UIColor colorWithRed:0.995 green:0.945 blue:0.88 alpha:0.9];
    self.profileTintView.alpha = 0.95;
    [self.profileCard addSubview:self.profileTintView];

    UIView *bubbleLarge = [[UIView alloc] init];
    bubbleLarge.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.12];
    bubbleLarge.layer.cornerRadius = 48.0;
    [self.profileCard addSubview:bubbleLarge];

    UIView *bubbleSmall = [[UIView alloc] init];
    bubbleSmall.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.45];
    bubbleSmall.layer.cornerRadius = 20.0;
    [self.profileCard addSubview:bubbleSmall];
    self.decorativeViews = @[bubbleLarge, bubbleSmall];

    self.avatarContainer = [[UIView alloc] init];
    self.avatarContainer.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.14];
    self.avatarContainer.layer.cornerRadius = 38.0;
    self.avatarContainer.layer.borderWidth = 1.0;
    self.avatarContainer.layer.borderColor = [[self accentColor] colorWithAlphaComponent:0.18].CGColor;
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
    self.nameLabel.text = @"老街漫游者";
    [self.profileCard addSubview:self.nameLabel];

    self.bioLabel = [self labelWithFont:[UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular]
                                  color:[UIColor secondaryLabelColor]];
    self.bioLabel.text = @"把旧巷、地图和日常瞬间，慢慢收进 MemoryCity。";
    self.bioLabel.numberOfLines = 2;
    [self.profileCard addSubview:self.bioLabel];

    self.editProfileButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.editProfileButton.backgroundColor = [UIColor whiteColor];
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

    self.statViews = @[
        [self makeStatViewWithValue:@"24" title:@"发布"],
        [self makeStatViewWithValue:@"86" title:@"回忆"],
        [self makeStatViewWithValue:@"12" title:@"足迹"]
    ];
    for (UIView *statView in self.statViews) {
        [self.profileCard addSubview:statView];
    }

    UIView *firstStat = self.statViews.firstObject;
    UIView *secondStat = self.statViews.count > 1 ? self.statViews[1] : nil;
    UIView *thirdStat = self.statViews.count > 2 ? self.statViews[2] : nil;

    [self.profileTintView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.equalTo(self.profileCard);
        make.width.equalTo(self.profileCard.mas_width).multipliedBy(0.58);
    }];

    [bubbleLarge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.profileCard.mas_top).offset(16.0);
        make.right.equalTo(self.profileCard.mas_right).offset(-22.0);
        make.width.height.mas_equalTo(96.0);
    }];

    [bubbleSmall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.profileCard.mas_top).offset(108.0);
        make.right.equalTo(self.profileCard.mas_right).offset(-24.0);
        make.width.height.mas_equalTo(40.0);
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

    [firstStat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.profileCard.mas_left).offset(18.0);
        make.top.equalTo(self.avatarContainer.mas_bottom).offset(26.0);
        make.bottom.equalTo(self.profileCard.mas_bottom).offset(-18.0);
    }];
    [secondStat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(firstStat.mas_right).offset(10.0);
        make.top.bottom.width.equalTo(firstStat);
    }];
    [thirdStat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(secondStat.mas_right).offset(10.0);
        make.right.equalTo(self.profileCard.mas_right).offset(-18.0);
        make.top.bottom.width.equalTo(firstStat);
    }];
}

- (void)buildQuickSection {
    self.quickSectionLabel = [self labelWithFont:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]
                                           color:[UIColor labelColor]];
    self.quickSectionLabel.text = @"常用入口";
    [self.contentView addSubview:self.quickSectionLabel];

    self.quickActionButtons = @[
        [self makeQuickActionButtonWithTitle:@"我的回忆"
                                    subtitle:@"回看时间线"
                                    iconName:@"wand.and.stars"
                                         tag:0],
        [self makeQuickActionButtonWithTitle:@"地图足迹"
                                    subtitle:@"继续探索地点"
                                    iconName:@"location.fill"
                                         tag:1],
        [self makeQuickActionButtonWithTitle:@"消息中心"
                                    subtitle:@"查看互动提醒"
                                    iconName:@"envelope.fill"
                                         tag:2],
        [self makeQuickActionButtonWithTitle:@"继续发布"
                                    subtitle:@"记录新的瞬间"
                                    iconName:@"plus.circle.fill"
                                         tag:3]
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
        [self makeServiceButtonWithTitle:@"收藏灵感"
                                subtitle:@"把喜欢的城市碎片先收起来"
                                iconName:@"heart.fill"
                                     tag:10],
        [self makeServiceButtonWithTitle:@"草稿箱"
                                subtitle:@"发布前先留一份待编辑草稿"
                                iconName:@"doc.text.fill"
                                     tag:11],
        [self makeServiceButtonWithTitle:@"账号与设置"
                                subtitle:@"保持页面风格和使用习惯一致"
                                iconName:@"gearshape.fill"
                                     tag:12]
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


- (UIView *)makeStatViewWithValue:(NSString *)value title:(NSString *)title {
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.72];
    container.layer.cornerRadius = 16.0;

    UILabel *valueLabel = [self labelWithFont:[UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold]
                                        color:[UIColor labelColor]];
    valueLabel.textAlignment = NSTextAlignmentCenter;
    valueLabel.text = value;
    [container addSubview:valueLabel];

    UILabel *titleLabel = [self labelWithFont:[UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium]
                                        color:[UIColor secondaryLabelColor]];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = title;
    [container addSubview:titleLabel];

    [valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(container.mas_top);
        make.left.right.equalTo(container);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(valueLabel.mas_bottom).offset(2.0);
        make.left.right.equalTo(container);
        make.bottom.equalTo(container.mas_bottom).offset(-4.0);
    }];

    return container;
}

- (UIButton *)makeQuickActionButtonWithTitle:(NSString *)title
                                    subtitle:(NSString *)subtitle
                                    iconName:(NSString *)iconName
                                         tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = tag;
    button.userInteractionEnabled = YES;
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
    button.userInteractionEnabled = YES;
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

- (void)settingsTapped {
    UIAlertController *sheet =
    [UIAlertController alertControllerWithTitle:@"页面设置"
                                        message:@"后续可以在这里接入主题、通知和资料管理。"
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"知道了"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.barButtonItem = self.navigationItem.rightBarButtonItem;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)editProfileTapped {
    [self showPlaceholderAlertWithTitle:@"编辑资料"
                                message:@"这里可以继续接昵称、头像和个性签名编辑。"];
}

- (void)quickActionTapped:(UIButton *)sender {
    switch (sender.tag) {
        case 0: {
            // "我的回忆" 入口直接进入 Memories(月/年)页
            YALMemoryController *controller = [[YALMemoryController alloc] init];
            [self pushController:controller];
            break;
        }
        case 1: {
            YALMapController *controller = [[YALMapController alloc] init];
            [self pushController:controller];
            break;
        }
        case 2: {
            YALMessageController *controller = [[YALMessageController alloc] init];
            [self pushController:controller];
            break;
        }
        case 3: {
            YALReleaseController *controller = [[YALReleaseController alloc] init];
            [self pushController:controller];
            break;
        }
        default:
            break;
    }
}

- (void)serviceTapped:(UIButton *)sender {
    switch (sender.tag) {
        case 10:
            [self showPlaceholderAlertWithTitle:@"收藏灵感"
                                        message:@"适合后续接入你喜欢的帖子、地点或城市清单。"];
            break;
        case 11:
            [self showPlaceholderAlertWithTitle:@"草稿箱"
                                        message:@"这里可以承接未发布内容，保持你的发布链路完整。"];
            break;
        case 12:
            [self showPlaceholderAlertWithTitle:@"账号与设置"
                                        message:@"这里可以继续扩展通知、隐私和账号信息设置。"];
            break;
        default:
            break;
    }
}

- (void)pushController:(UIViewController *)controller {
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPlaceholderAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
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

- (UIColor *)borderColor {
    return [UIColor colorWithWhite:0.0 alpha:0.05];
}

@end
