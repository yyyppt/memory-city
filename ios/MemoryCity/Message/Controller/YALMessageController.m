//
//  YALMessageController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/13.
//

#import "YALMessageController.h"
#import "YALMessageCell.h"

@interface YALMessageController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *messages;

@end

@implementation YALMessageController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor systemBackgroundColor];
  self.title = @"消息";
  self.navigationItem.hidesBackButton = YES;

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
    self.navigationItem.rightBarButtonItems = @[trashItem, moreItem];
  }

  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  if (@available(iOS 13.0, *)) {
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
  } else {
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
  }
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.showsVerticalScrollIndicator = NO;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.tableView registerClass:[YALMessageCell class] forCellReuseIdentifier:@"YALMessageCell"];
  self.tableView.tableHeaderView = [self buildHeaderView];
  [self.view addSubview:self.tableView];

  self.messages = @[
    @{
      @"name": @"记忆小助手 官方",
      @"highlight": @"官方",
      @"summary": @"你收到了一条新的活动邀请，点击查看详情",
      @"time": @"11:42",
      @"unreadCount": @2,
      @"showDot": @NO,
      @"avatarBgColor": [UIColor systemBlueColor],
      @"avatarIcon": [UIImage systemImageNamed:@"sparkles"]
    },
    @{
      @"name": @"阿城同学",
      @"highlight": @"阿城",
      @"summary": @"回复了你：这条老街记忆我也拍过！",
      @"time": @"昨天",
      @"unreadCount": @0,
      @"showDot": @YES,
      @"avatarBgColor": [UIColor systemOrangeColor],
      @"avatarIcon": [UIImage systemImageNamed:@"face.smiling"]
    },
    @{
      @"name": @"猫咪摄影社",
      @"highlight": @"猫咪",
      @"summary": @"赞了你的笔记《巷口的旧时光》",
      @"time": @"周三",
      @"unreadCount": @0,
      @"showDot": @NO,
      @"avatarBgColor": [UIColor systemPurpleColor],
      @"avatarIcon": [UIImage systemImageNamed:@"camera.aperture"]
    },
    @{
      @"name": @"系统通知",
      @"highlight": @"系统",
      @"summary": @"你有 3 位新粉丝，快去看看吧",
      @"time": @"周二",
      @"unreadCount": @12,
      @"showDot": @NO,
      @"avatarBgColor": [UIColor systemGreenColor],
      @"avatarIcon": [UIImage systemImageNamed:@"person.2.fill"]
    }
  ];
}

- (UIView *)buildHeaderView {
  CGFloat width = CGRectGetWidth(self.view.bounds);
  UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 100)];
  header.backgroundColor = [UIColor clearColor];

  NSArray<NSDictionary *> *items = @[
    @{
      @"title": @"回复与@",
      @"icon": @"bubble.left.and.bubble.right.fill",
      @"bgColor": [UIColor secondarySystemBackgroundColor],
      @"iconColor": [UIColor systemGreenColor]
    },
    @{
      @"title": @"收到喜欢",
      @"icon": @"heart.fill",
      @"bgColor": [UIColor secondarySystemBackgroundColor],
      @"iconColor": [UIColor systemPinkColor]
    },
    @{
      @"title": @"新增粉丝",
      @"icon": @"person.2.fill",
      @"bgColor": [UIColor secondarySystemBackgroundColor],
      @"iconColor": [UIColor systemBlueColor]
    }
  ];

  CGFloat gap = 10.0;
  CGFloat cardWidth = (width - 16.0 * 2 - gap * 2) / 3.0;
  for (NSInteger i = 0; i < items.count; i++) {
    NSDictionary *item = items[i];
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(16 + i * (cardWidth + gap), 12, cardWidth, 74)];
    card.backgroundColor = item[@"bgColor"];
    card.layer.cornerRadius = 14.0;
    card.layer.masksToBounds = YES;

    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake((cardWidth - 22) / 2.0, 14, 22, 22)];
    if (@available(iOS 13.0, *)) {
      iconView.image = [UIImage systemImageNamed:item[@"icon"]];
    }
    iconView.tintColor = item[@"iconColor"];
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 43, cardWidth, 20)];
    titleLabel.text = item[@"title"];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor labelColor];

    [card addSubview:iconView];
    [card addSubview:titleLabel];
    [header addSubview:card];
  }
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

@end
