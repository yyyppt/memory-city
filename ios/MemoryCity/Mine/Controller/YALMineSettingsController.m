//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//
#import "YALMineSettingsController.h"
#import <Masonry/Masonry.h>

static NSString * const kYALAppAppearanceStyleKey = @"YALAppAppearanceStyle";

typedef NS_ENUM(NSInteger, YALMineSettingsSection) {
    YALMineSettingsSectionCommon = 0,
    YALMineSettingsSectionAccount = 1,
    YALMineSettingsSectionCount = 2
};

typedef NS_ENUM(NSInteger, YALMineSettingsCommonRow) {
    YALMineSettingsCommonRowDarkMode = 0,
    YALMineSettingsCommonRowShuffleProfile = 1,
    YALMineSettingsCommonRowShareApp = 2,
    YALMineSettingsCommonRowClearBadge = 3,
    YALMineSettingsCommonRowCount = 4
};

@interface YALMineSettingsController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<UIButton *> *appearanceButtons;

@end

@implementation YALMineSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 56.0;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle &&
            [self preferredAppStyle] == UIUserInterfaceStyleUnspecified) {
            NSIndexPath *nightModeIndexPath = [NSIndexPath indexPathForRow:YALMineSettingsCommonRowDarkMode
                                                                  inSection:YALMineSettingsSectionCommon];
            [self.tableView reloadRowsAtIndexPaths:@[nightModeIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return YALMineSettingsSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    if (section == YALMineSettingsSectionCommon) {
        return YALMineSettingsCommonRowCount;
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    if (section == YALMineSettingsSectionCommon) {
        return @"常用操作";
    }
    if (section == YALMineSettingsSectionAccount) {
        return @"账号";
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section == YALMineSettingsSectionAccount) {
        return @"退出后将返回登录页。";
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (indexPath.section == YALMineSettingsSectionCommon &&
        indexPath.row == YALMineSettingsCommonRowDarkMode) {
        return 126.0;
    }
    return 56.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == YALMineSettingsSectionCommon &&
        indexPath.row == YALMineSettingsCommonRowDarkMode) {
        return [self appearanceCellForTableView:tableView];
    }

    static NSString *cellId = @"YALMineSettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    cell.textLabel.textColor = [UIColor labelColor];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.detailTextLabel.text = nil;

    if (indexPath.section == YALMineSettingsSectionCommon) {
        switch (indexPath.row) {
            case YALMineSettingsCommonRowShuffleProfile:
                cell.textLabel.text = @"切换昵称风格";
                cell.detailTextLabel.text = @"快速换一组昵称、简介和统计数据";
                break;
            case YALMineSettingsCommonRowShareApp:
                cell.textLabel.text = @"分享 MemoryCity";
                cell.detailTextLabel.text = @"通过系统分享面板发送给朋友";
                break;
            case YALMineSettingsCommonRowClearBadge:
                cell.textLabel.text = @"清空消息提醒";
                cell.detailTextLabel.text = @"重置应用图标角标";
                break;
            default:
                break;
        }
    } else {
        cell.textLabel.text = @"退出登录";
        cell.detailTextLabel.text = @"切换到登录页";
        cell.textLabel.textColor = [UIColor systemRedColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == YALMineSettingsSectionCommon) {
        switch (indexPath.row) {
            case YALMineSettingsCommonRowShuffleProfile:
                if (self.tapShuffleProfileBlock) {
                    self.tapShuffleProfileBlock();
                }
                break;
            case YALMineSettingsCommonRowShareApp:
                if (self.tapShareBlock) {
                    self.tapShareBlock();
                }
                break;
            case YALMineSettingsCommonRowClearBadge:
                if (self.tapClearBadgeBlock) {
                    self.tapClearBadgeBlock();
                }
                break;
            default:
                break;
        }
        return;
    }
    if (self.tapLogoutBlock) {
        self.tapLogoutBlock();
    }
}

- (UITableViewCell *)appearanceCellForTableView:(UITableView *)tableView {
    static NSString *cellId = @"YALMineAppearanceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.tag = 1001;
        titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
        titleLabel.textColor = [UIColor labelColor];
        titleLabel.text = @"外观模式";
        [cell.contentView addSubview:titleLabel];

        UILabel *detailLabel = [[UILabel alloc] init];
        detailLabel.tag = 1002;
        detailLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
        detailLabel.textColor = [UIColor secondaryLabelColor];
        detailLabel.text = @"只影响 MemoryCity，退出登录后会恢复跟随系统。";
        [cell.contentView addSubview:detailLabel];

        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.tag = 1003;
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.spacing = 10.0;
        stackView.distribution = UIStackViewDistributionFillEqually;
        [cell.contentView addSubview:stackView];

        NSArray<NSString *> *titles = @[@"跟随系统", @"浅色", @"深色"];
        NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
        for (NSInteger index = 0; index < titles.count; index++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = 3000 + index;
            button.layer.cornerRadius = 14.0;
            button.layer.borderWidth = 1.0;
            button.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
            [button setTitle:titles[index] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(appearanceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [stackView addArrangedSubview:button];
            [buttons addObject:button];
        }
        self.appearanceButtons = [buttons copy];

        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cell.contentView.mas_top).offset(14.0);
            make.left.equalTo(cell.contentView.mas_left).offset(18.0);
            make.right.equalTo(cell.contentView.mas_right).offset(-18.0);
        }];
        [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleLabel.mas_bottom).offset(4.0);
            make.left.right.equalTo(titleLabel);
        }];
        [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(detailLabel.mas_bottom).offset(14.0);
            make.left.equalTo(cell.contentView.mas_left).offset(18.0);
            make.right.equalTo(cell.contentView.mas_right).offset(-18.0);
            make.height.mas_equalTo(40.0);
        }];
    }

    [self updateAppearanceButtons];
    return cell;
}

- (void)appearanceButtonTapped:(UIButton *)sender {
    UIUserInterfaceStyle style = UIUserInterfaceStyleUnspecified;
    if (sender.tag == 3001) {
        style = UIUserInterfaceStyleLight;
    } else if (sender.tag == 3002) {
        style = UIUserInterfaceStyleDark;
    }
    [self applyAppStyle:style];
}

- (void)updateAppearanceButtons {
    UIUserInterfaceStyle selectedStyle = [self preferredAppStyle];
    for (UIButton *button in self.appearanceButtons) {
        UIUserInterfaceStyle buttonStyle = UIUserInterfaceStyleUnspecified;
        if (button.tag == 3001) {
            buttonStyle = UIUserInterfaceStyleLight;
        } else if (button.tag == 3002) {
            buttonStyle = UIUserInterfaceStyleDark;
        }

        BOOL isSelected = (selectedStyle == buttonStyle);
        UIColor *accent = [self accentColor];
        button.backgroundColor = isSelected ? [accent colorWithAlphaComponent:0.14] : [self buttonBackgroundColor];
        button.layer.borderColor = isSelected ? accent.CGColor : [self buttonBorderColor].CGColor;
        [button setTitleColor:isSelected ? accent : [UIColor labelColor] forState:UIControlStateNormal];
    }
}

- (void)applyAppStyle:(UIUserInterfaceStyle)style {
    if (@available(iOS 13.0, *)) {
        UIWindow *window = [self activeWindow];
        if (window) {
            window.overrideUserInterfaceStyle = style;
        }
        [[NSUserDefaults standardUserDefaults] setInteger:style forKey:kYALAppAppearanceStyleKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self updateAppearanceButtons];
    }
}

- (UIUserInterfaceStyle)preferredAppStyle {
    if (@available(iOS 13.0, *)) {
        NSInteger style = [[NSUserDefaults standardUserDefaults] integerForKey:kYALAppAppearanceStyleKey];
        if (style == UIUserInterfaceStyleDark || style == UIUserInterfaceStyleLight) {
            return (UIUserInterfaceStyle)style;
        }
    }
    return UIUserInterfaceStyleUnspecified;
}

- (NSString *)appAppearanceText {
    if (@available(iOS 13.0, *)) {
        UIUserInterfaceStyle style = [self preferredAppStyle];
        if (style == UIUserInterfaceStyleDark) {
            return @"仅本 App：深色";
        }
        if (style == UIUserInterfaceStyleLight) {
            return @"仅本 App：浅色";
        }
        UIUserInterfaceStyle systemStyle = self.traitCollection.userInterfaceStyle;
        if (systemStyle == UIUserInterfaceStyleDark) {
            return @"跟随系统：深色";
        }
        if (systemStyle == UIUserInterfaceStyleLight) {
            return @"跟随系统：浅色";
        }
    }
    return @"跟随系统：浅色";
}

- (UIColor *)accentColor {
    return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

- (UIColor *)buttonBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondarySystemBackgroundColor];
    }
    return [UIColor whiteColor];
}

- (UIColor *)buttonBorderColor {
    return [UIColor colorWithWhite:0.0 alpha:0.08];
}

- (UIWindow *)activeWindow {
    UIWindow *window = self.view.window;
    if (window) {
        return window;
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        if (windowScene.activationState != UISceneActivationStateForegroundActive &&
            windowScene.activationState != UISceneActivationStateForegroundInactive) {
            continue;
        }
        for (UIWindow *candidate in windowScene.windows) {
            if (candidate.isKeyWindow) {
                return candidate;
            }
        }
        if (windowScene.windows.count > 0) {
            return windowScene.windows.firstObject;
        }
    }
    return nil;
}

@end
