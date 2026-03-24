//
//  YALMessageController.m
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import "YALMessageController.h"
#import "YALMessageCell.h"
#import <Masonry/Masonry.h>

@interface YALMessageController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *messages;

@end

@implementation YALMessageController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [self pageBackgroundColor];
  self.title = @"消息";
  self.navigationItem.hidesBackButton = YES;
  self.navigationController.navigationBar.tintColor = [self accentColor];

  if (@available(iOS 13.0, *)) {
    UIImage *back = [UIImage systemImageNamed:@"chevron.left"];
    self.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithImage:back
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(backTapped)];

    UIImage *ellipsis = [UIImage systemImageNamed:@"ellipsis"];
    UIImage *trash = [UIImage systemImageNamed:@"trash"];
    UIBarButtonItem *moreItem =
      [[UIBarButtonItem alloc] initWithImage:ellipsis
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(moreTapped)];
    UIBarButtonItem *trashItem =
      [[UIBarButtonItem alloc] initWithImage:trash
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(trashTapped)];
    moreItem.tintColor = [self accentColor];
    trashItem.tintColor = [self accentColor];
    self.navigationItem.rightBarButtonItems = @[trashItem, moreItem];
  }

  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.backgroundColor = [self pageBackgroundColor];
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.showsVerticalScrollIndicator = NO;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  [self.tableView registerClass:[YALMessageCell class] forCellReuseIdentifier:@"YALMessageCell"];
  self.tableView.tableHeaderView = [self buildHeaderView];
  [self.view addSubview:self.tableView];
  [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];

  self.messages = @[
    @{
      @"name": @"记忆小助手 官方",
      @"highlight": @"官方",
      @"summary": @"你收到了一条新的活动邀请，点击查看详情",
      @"time": @"11:42",
      @"unreadCount": @2,
      @"showDot": @NO,
      @"avatarBgColor": [self accentColor],
      @"avatarIcon": [UIImage systemImageNamed:@"sparkles"]
    },
    @{
      @"name": @"阿城同学",
      @"highlight": @"阿城",
      @"summary": @"回复了你：这条老街记忆我也拍过！",
      @"time": @"昨天",
      @"unreadCount": @0,
      @"showDot": @YES,
      @"avatarBgColor": [self warmBrownColor],
      @"avatarIcon": [UIImage systemImageNamed:@"face.smiling"]
    },
    @{
      @"name": @"猫咪摄影社",
      @"highlight": @"猫咪",
      @"summary": @"赞了你的笔记《巷口的旧时光》",
      @"time": @"周三",
      @"unreadCount": @0,
      @"showDot": @NO,
      @"avatarBgColor": [self accentSoftColor],
      @"avatarIcon": [UIImage systemImageNamed:@"camera.aperture"]
    },
    @{
      @"name": @"系统通知",
      @"highlight": @"系统",
      @"summary": @"你有 3 位新粉丝，快去看看吧",
      @"time": @"周二",
      @"unreadCount": @12,
      @"showDot": @NO,
      @"avatarBgColor": [self mutedAccentColor],
      @"avatarIcon": [UIImage systemImageNamed:@"person.2.fill"]
    }
  ];
}

- (UIView *)buildHeaderView {
  CGFloat width = CGRectGetWidth(self.view.bounds);
  UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 114)];
  header.backgroundColor = [UIColor clearColor];

  NSArray<NSDictionary *> *items = @[
    @{
      @"title": @"回复与@",
      @"icon": @"bubble.left.and.bubble.right.fill",
      @"bgColor": [UIColor colorWithRed:1.0 green:0.97 blue:0.93 alpha:1.0],
      @"iconColor": [self accentColor]
    },
    @{
      @"title": @"收到喜欢",
      @"icon": @"heart.fill",
      @"bgColor": [UIColor colorWithRed:0.995 green:0.955 blue:0.91 alpha:1.0],
      @"iconColor": [self warmBrownColor]
    },
    @{
      @"title": @"新增粉丝",
      @"icon": @"person.2.fill",
      @"bgColor": [UIColor colorWithRed:1.0 green:0.975 blue:0.945 alpha:1.0],
      @"iconColor": [self mutedAccentColor]
    }
  ];

  CGFloat gap = 10.0;
  NSMutableArray<UIView *> *cards = [NSMutableArray array];
  for (NSInteger i = 0; i < items.count; i++) {
    NSDictionary *item = items[i];
    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.backgroundColor = item[@"bgColor"];
    card.layer.cornerRadius = 14.0;
    card.layer.masksToBounds = YES;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [self softBorderColor].CGColor;

    UIView *iconBadge = [[UIView alloc] initWithFrame:CGRectZero];
    iconBadge.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.62];
    iconBadge.layer.cornerRadius = 17.0;

    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 13.0, *)) {
      iconView.image = [UIImage systemImageNamed:item[@"icon"]];
    }
    iconView.tintColor = item[@"iconColor"];
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = item[@"title"];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor colorWithRed:0.34 green:0.28 blue:0.20 alpha:1.0];

    [iconBadge addSubview:iconView];
    [card addSubview:iconBadge];
    [card addSubview:titleLabel];
    [header addSubview:card];
    [cards addObject:card];

    [iconBadge mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(card.mas_top).offset(13.0);
      make.centerX.equalTo(card.mas_centerX);
      make.width.height.mas_equalTo(34.0);
    }];

    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.center.equalTo(iconBadge);
      make.width.height.mas_equalTo(20.0);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.right.equalTo(card);
      make.top.equalTo(iconBadge.mas_bottom).offset(4.0);
    }];
  }

  UIView *firstCard = cards.firstObject;
  UIView *secondCard = cards.count > 1 ? cards[1] : nil;
  UIView *thirdCard = cards.count > 2 ? cards[2] : nil;

  [firstCard mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(header.mas_left).offset(16.0);
    make.top.equalTo(header.mas_top).offset(16.0);
    make.bottom.equalTo(header.mas_bottom).offset(-16.0);
  }];
  [secondCard mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(firstCard.mas_right).offset(gap);
    make.top.bottom.width.equalTo(firstCard);
  }];
  [thirdCard mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(secondCard.mas_right).offset(gap);
    make.right.equalTo(header.mas_right).offset(-16.0);
    make.top.bottom.width.equalTo(firstCard);
  }];

  return header;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  YALMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YALMessageCell" forIndexPath:indexPath];
  [cell configureWithMessage:self.messages[indexPath.row]];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  (void)indexPath;
  return 72.0;
}

- (void)backTapped {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)moreTapped {

}

- (void)trashTapped {}

#pragma mark - Colors

- (UIColor *)accentColor {
  return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

- (UIColor *)accentSoftColor {
  return [UIColor colorWithRed:0.95 green:0.73 blue:0.47 alpha:1.0];
}

- (UIColor *)mutedAccentColor {
  return [UIColor colorWithRed:0.79 green:0.62 blue:0.45 alpha:1.0];
}

- (UIColor *)warmBrownColor {
  return [UIColor colorWithRed:0.69 green:0.52 blue:0.35 alpha:1.0];
}

- (UIColor *)pageBackgroundColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor systemGroupedBackgroundColor];
  }
  return [UIColor colorWithWhite:0.97 alpha:1.0];
}

- (UIColor *)softBorderColor {
  return [UIColor colorWithWhite:0.0 alpha:0.05];
}

@end
