//
//  YALMessageController.m
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import "YALMessageController.h"
#import "YALMessageCell.h"
#import "YALContentManager.h"
#import "YALPostModel.h"
#import "YALPostDetailController.h"
#import "YALAuthManager.h"
#import <Masonry/Masonry.h>

static NSString * const kYALMessageSnapshotKeyPrefix = @"YALMessageInteractionSnapshot";

@interface YALMessageController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *messages;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign) NSInteger totalLikeCount;
@property (nonatomic, assign) NSInteger totalCommentCount;
@property (nonatomic, assign) NSInteger totalCollectCount;
@property (nonatomic, assign) NSInteger unreadInteractionCount;
@property (nonatomic, assign) NSInteger messageLoadToken;
@property (nonatomic, strong, nullable) NSNumber *serverCollectTotal;
@property (nonatomic, assign) BOOL isRenderingProvisionalMessages;

@end

@implementation YALMessageController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [self pageBackgroundColor];
  self.navigationController.view.backgroundColor = [self pageBackgroundColor];
  self.title = @"互动消息";
  self.navigationController.navigationBar.tintColor = [self accentColor];
  self.messages = @[];

  if (@available(iOS 13.0, *)) {
    UIImage *back = [UIImage systemImageNamed:@"chevron.left"];
    self.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithImage:back
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(backTapped)];

    UIImage *markReadIcon = [self symbolImageNamed:@"checkmark.circle"];
    UIBarButtonItem *markReadItem =
      [[UIBarButtonItem alloc] initWithImage:markReadIcon
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(markAllAsReadTapped)];
    markReadItem.tintColor = [self accentColor];
    self.navigationItem.rightBarButtonItem = markReadItem;
  }

  [self setupTableView];
  [self setupLoadingView];
  [self loadMessages];
}

- (void)setupTableView {
  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.backgroundColor = [self pageBackgroundColor];
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.showsVerticalScrollIndicator = NO;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  [self.tableView registerClass:[YALMessageCell class] forCellReuseIdentifier:@"YALMessageCell"];
  [self.view addSubview:self.tableView];
  [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];

  self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.emptyLabel.numberOfLines = 0;
  self.emptyLabel.textAlignment = NSTextAlignmentCenter;
  self.emptyLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
  self.emptyLabel.textColor = [UIColor secondaryLabelColor];
  self.emptyLabel.hidden = YES;
  self.tableView.backgroundView = self.emptyLabel;

  if (@available(iOS 10.0, *)) {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(loadMessages) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
  }
}

- (void)setupLoadingView {
  self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  self.loadingIndicator.hidesWhenStopped = YES;
  [self.view addSubview:self.loadingIndicator];
  [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(self.view);
  }];
}

- (void)loadMessages {
  NSInteger loadToken = ++self.messageLoadToken;
  self.isRenderingProvisionalMessages = NO;

  if (![[YALAuthManager sharedManager] hasLoggedInSession]) {
    self.totalLikeCount = 0;
    self.totalCommentCount = 0;
    self.totalCollectCount = 0;
    self.unreadInteractionCount = 0;
    self.serverCollectTotal = nil;
    self.messages = @[];
    [self.loadingIndicator stopAnimating];
    if (@available(iOS 10.0, *)) {
      [self.tableView.refreshControl endRefreshing];
    }
    [self refreshHeaderView];
    self.emptyLabel.text = @"登录后就能看到别人给你内容的点赞、评论和收藏。";
    self.emptyLabel.hidden = NO;
    self.tableView.backgroundView.hidden = NO;
    [self.tableView reloadData];
    return;
  }

  [self.loadingIndicator startAnimating];
  self.emptyLabel.text = @"互动消息加载中...";
  self.emptyLabel.hidden = NO;
  self.tableView.backgroundView.hidden = NO;
  [self refreshHeaderView];
  if (self.messages.count == 0) {
    [self.tableView reloadData];
  }

  __weak typeof(self) weakSelf = self;
  [[YALContentManager sharedManager] getMyContentListWithPage:1
                                                     pageSize:100
                                                   completion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    [strongSelf.loadingIndicator stopAnimating];
    if (@available(iOS 10.0, *)) {
      [strongSelf.tableView.refreshControl endRefreshing];
    }

    if (!success) {
      strongSelf.messages = @[];
      strongSelf.totalLikeCount = 0;
      strongSelf.totalCommentCount = 0;
      strongSelf.totalCollectCount = 0;
      strongSelf.unreadInteractionCount = 0;
      strongSelf.serverCollectTotal = nil;
      [strongSelf refreshHeaderView];
      NSString *errorText = message.length > 0 ? message : (error.localizedDescription.length > 0 ? error.localizedDescription : @"互动消息加载失败");
      strongSelf.emptyLabel.text = errorText;
      strongSelf.emptyLabel.hidden = NO;
      strongSelf.tableView.backgroundView.hidden = NO;
      [strongSelf.tableView reloadData];
      return;
    }

    NSMutableArray<YALPostModel *> *posts = [NSMutableArray array];
    for (id item in contentList) {
      YALPostModel *model = nil;
      if ([item isKindOfClass:[YALPostModel class]]) {
        model = (YALPostModel *)item;
      } else if ([item isKindOfClass:[NSDictionary class]]) {
        model = [[YALPostModel alloc] initWithDictionary:(NSDictionary *)item];
      }
      if (model && model.contentId.integerValue > 0) {
        [posts addObject:model];
      }
    }

    strongSelf.serverCollectTotal = [YALContentManager sharedManager].lastMyContentCollectCount;
    NSArray<YALPostModel *> *postsSnapshot = [posts copy];
    NSArray<YALPostModel *> *targets = [strongSelf postsNeedingDetailEnrichmentFromPosts:postsSnapshot];
    BOOL needsEnrichment = targets.count > 0;
    strongSelf.isRenderingProvisionalMessages = needsEnrichment;
    [strongSelf buildMessagesFromPosts:postsSnapshot persistSnapshots:!needsEnrichment];

    if (!needsEnrichment) {
      return;
    }

    [strongSelf enrichPosts:targets loadToken:loadToken completion:^(NSArray<YALPostModel *> * _Nonnull enrichedPosts) {
      (void)enrichedPosts;
      strongSelf.isRenderingProvisionalMessages = NO;
      [strongSelf buildMessagesFromPosts:postsSnapshot persistSnapshots:YES];
    }];
  }];
}

- (NSArray<YALPostModel *> *)postsNeedingDetailEnrichmentFromPosts:(NSArray<YALPostModel *> *)posts {
  NSMutableArray<YALPostModel *> *targets = [NSMutableArray array];
  for (YALPostModel *post in posts) {
    if (![post isKindOfClass:[YALPostModel class]] || post.contentId.integerValue <= 0) {
      continue;
    }
    // 消息页重点看互动统计，收藏数异常时补拉详情可与详情页统一。
    if (post.collectCount <= 0 || post.commentCount <= 0 || post.likeCount <= 0) {
      [targets addObject:post];
    }
  }

  return [targets copy];
}

- (void)enrichPosts:(NSArray<YALPostModel *> *)targets
          loadToken:(NSInteger)loadToken
         completion:(void (^)(NSArray<YALPostModel *> *enrichedPosts))completion {
  if (targets.count == 0) {
    if (completion) {
      completion(@[]);
    }
    return;
  }

  dispatch_group_t group = dispatch_group_create();
  __weak typeof(self) weakSelf = self;

  for (YALPostModel *post in targets) {
    dispatch_group_enter(group);
    [[YALContentManager sharedManager] getContentDetailWithId:post.contentId completion:^(BOOL success, NSDictionary * _Nullable content, NSError * _Nullable error) {
      (void)error;
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        dispatch_group_leave(group);
        return;
      }
      if (!success || ![content isKindOfClass:[NSDictionary class]]) {
        dispatch_group_leave(group);
        return;
      }

      [strongSelf applyStatsFromContent:content toPost:post];
      dispatch_group_leave(group);
    }];
  }

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || loadToken != strongSelf.messageLoadToken) {
      return;
    }
    if (completion) {
      completion(targets);
    }
  });
}

- (void)applyStatsFromContent:(NSDictionary *)content toPost:(YALPostModel *)post {
  NSInteger likeCount = [self integerValueRecursivelyFromObject:content keys:@[@"like_count", @"likeCount", @"liked_count", @"likes_count"] fallback:post.likeCount];
  NSInteger commentCount = [self integerValueRecursivelyFromObject:content keys:@[@"comment_count", @"commentCount", @"comments_count"] fallback:post.commentCount];
  NSInteger collectCount = [self integerValueRecursivelyFromObject:content keys:@[@"collect_count", @"favorite_count", @"collected_count", @"collectCount", @"favoriteCount"] fallback:post.collectCount];

  post.likeCount = MAX(likeCount, 0);
  post.commentCount = MAX(commentCount, 0);
  post.collectCount = MAX(collectCount, 0);
}

- (NSInteger)integerValueRecursivelyFromObject:(id)object
                                          keys:(NSArray<NSString *> *)keys
                                      fallback:(NSInteger)fallback {
  if ([object isKindOfClass:[NSDictionary class]]) {
    NSDictionary *dict = (NSDictionary *)object;
    NSInteger directValue = [self integerValueFromDictionary:dict keys:keys fallback:NSNotFound];
    if (directValue != NSNotFound) {
      return directValue;
    }

    NSArray<NSString *> *nestedKeys = @[@"data", @"content", @"item", @"post"];
    for (NSString *nestedKey in nestedKeys) {
      id nested = dict[nestedKey];
      NSInteger nestedValue = [self integerValueRecursivelyFromObject:nested keys:keys fallback:NSNotFound];
      if (nestedValue != NSNotFound) {
        return nestedValue;
      }
    }
  } else if ([object isKindOfClass:[NSArray class]]) {
    for (id item in (NSArray *)object) {
      NSInteger nestedValue = [self integerValueRecursivelyFromObject:item keys:keys fallback:NSNotFound];
      if (nestedValue != NSNotFound) {
        return nestedValue;
      }
    }
  }

  return fallback;
}

- (NSInteger)integerValueFromDictionary:(NSDictionary *)dict
                                   keys:(NSArray<NSString *> *)keys
                               fallback:(NSInteger)fallback {
  if (![dict isKindOfClass:[NSDictionary class]]) {
    return fallback;
  }
  for (NSString *key in keys) {
    id value = dict[key];
    if ([value respondsToSelector:@selector(integerValue)]) {
      return [value integerValue];
    }
  }
  return fallback;
}

- (void)buildMessagesFromPosts:(NSArray<YALPostModel *> *)posts
              persistSnapshots:(BOOL)persistSnapshots {
  NSMutableArray<NSDictionary *> *items = [NSMutableArray array];
  NSMutableDictionary<NSString *, NSDictionary *> *snapshotsToSave = [NSMutableDictionary dictionary];
  NSDictionary<NSString *, NSDictionary *> *savedSnapshots = [self savedInteractionSnapshots];

  self.totalLikeCount = 0;
  self.totalCommentCount = 0;
  self.totalCollectCount = 0;
  self.unreadInteractionCount = 0;

  for (YALPostModel *post in posts) {
    NSInteger likeCount = MAX(post.likeCount, 0);
    NSInteger commentCount = MAX(post.commentCount, 0);
    NSInteger collectCount = MAX(post.collectCount, 0);
    NSInteger totalCount = likeCount + commentCount + collectCount;

    self.totalLikeCount += likeCount;
    self.totalCommentCount += commentCount;
    self.totalCollectCount += collectCount;

    NSString *contentIdKey = [NSString stringWithFormat:@"%@", post.contentId ?: @(0)];
    NSDictionary *previousSnapshot = [savedSnapshots[contentIdKey] isKindOfClass:[NSDictionary class]] ? savedSnapshots[contentIdKey] : nil;
    NSInteger previousLikeCount = [previousSnapshot[@"like_count"] respondsToSelector:@selector(integerValue)] ? [previousSnapshot[@"like_count"] integerValue] : 0;
    NSInteger previousCommentCount = [previousSnapshot[@"comment_count"] respondsToSelector:@selector(integerValue)] ? [previousSnapshot[@"comment_count"] integerValue] : 0;
    NSInteger previousCollectCount = [previousSnapshot[@"collect_count"] respondsToSelector:@selector(integerValue)] ? [previousSnapshot[@"collect_count"] integerValue] : 0;

    NSInteger newLikeCount = MAX(0, likeCount - previousLikeCount);
    NSInteger newCommentCount = MAX(0, commentCount - previousCommentCount);
    NSInteger newCollectCount = MAX(0, collectCount - previousCollectCount);
    NSInteger deltaCount = newLikeCount + newCommentCount + newCollectCount;

    snapshotsToSave[contentIdKey] = @{
      @"like_count": @(likeCount),
      @"comment_count": @(commentCount),
      @"collect_count": @(collectCount)
    };

    if (totalCount <= 0) {
      continue;
    }

    self.unreadInteractionCount += deltaCount;

    NSDictionary *iconConfig = [self iconConfigForNewLikeCount:newLikeCount
                                               newCommentCount:newCommentCount
                                               newCollectCount:newCollectCount
                                                     likeCount:likeCount
                                                  commentCount:commentCount
                                                  collectCount:collectCount];

    NSString *name = [NSString stringWithFormat:@"《%@》", [self safeTitleForPost:post]];
    NSString *summary = nil;
    if (deltaCount > 0) {
      summary = [NSString stringWithFormat:@"新收到 %ld 个赞，%ld 条评论，%ld 次收藏",
                 (long)newLikeCount,
                 (long)newCommentCount,
                 (long)newCollectCount];
    } else {
      summary = [NSString stringWithFormat:@"累计收到 %ld 个赞，%ld 条评论，%ld 次收藏",
                 (long)likeCount,
                 (long)commentCount,
                 (long)collectCount];
    }

    NSString *timeText = deltaCount > 0 ? @"有更新" : @"总览";
    NSDictionary *message = @{
      @"name": name,
      @"highlight": @"",
      @"summary": summary,
      @"time": timeText,
      @"unreadCount": @(deltaCount),
      @"showDot": @NO,
      @"avatarBgColor": iconConfig[@"bgColor"],
      @"avatarIcon": iconConfig[@"icon"],
      @"post": post,
      @"weight": @(deltaCount * 1000 + totalCount)
    };
    [items addObject:message];
  }

  if ([self.serverCollectTotal respondsToSelector:@selector(integerValue)]) {
    self.totalCollectCount = MAX(self.serverCollectTotal.integerValue, 0);
  }

  NSArray<NSDictionary *> *sortedItems =
    [items sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
      NSInteger weight1 = [obj1[@"weight"] integerValue];
      NSInteger weight2 = [obj2[@"weight"] integerValue];
      if (weight1 == weight2) {
        return NSOrderedSame;
      }
      return weight1 < weight2 ? NSOrderedDescending : NSOrderedAscending;
    }];

  self.messages = sortedItems;
  if (persistSnapshots) {
    [self saveInteractionSnapshots:snapshotsToSave];
  }
  [self refreshHeaderView];

  if (self.messages.count == 0) {
    if (self.isRenderingProvisionalMessages) {
      self.emptyLabel.text = @"正在整理互动统计...";
    } else {
      self.emptyLabel.text = posts.count > 0 ? @"你已经发布内容了，等大家来点赞评论后，这里就会热闹起来。" : @"你还没有发布内容，先去首页或发布页留下第一条记忆吧。";
    }
    self.emptyLabel.hidden = NO;
    self.tableView.backgroundView.hidden = NO;
  } else {
    self.emptyLabel.hidden = YES;
    self.tableView.backgroundView.hidden = YES;
  }

  [self.tableView reloadData];
}

- (NSDictionary *)iconConfigForNewLikeCount:(NSInteger)newLikeCount
                            newCommentCount:(NSInteger)newCommentCount
                            newCollectCount:(NSInteger)newCollectCount
                                  likeCount:(NSInteger)likeCount
                               commentCount:(NSInteger)commentCount
                               collectCount:(NSInteger)collectCount {
  BOOL highlightNewComment = newCommentCount > 0;
  BOOL highlightNewLike = !highlightNewComment && newLikeCount > 0;
  BOOL highlightNewCollect = !highlightNewComment && !highlightNewLike && newCollectCount > 0;

  if (highlightNewComment || (commentCount >= likeCount && commentCount >= collectCount && commentCount > 0)) {
    return @{
      @"bgColor": [self warmBrownColor],
      @"icon": [self symbolImageNamed:@"bubble.left.and.bubble.right.fill"]
    };
  }

  if (highlightNewCollect || (collectCount >= likeCount && collectCount > 0)) {
    return @{
      @"bgColor": [self mutedAccentColor],
      @"icon": [self symbolImageNamed:@"bookmark.fill"]
    };
  }

  return @{
    @"bgColor": [self accentColor],
    @"icon": [self symbolImageNamed:@"heart.fill"]
  };
}

- (NSString *)safeTitleForPost:(YALPostModel *)post {
  if (post.title.length > 0) {
    return post.title;
  }
  if (post.content.length > 0) {
    NSString *trimmed = [post.content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length > 12) {
      return [[trimmed substringToIndex:12] stringByAppendingString:@"..."];
    }
    if (trimmed.length > 0) {
      return trimmed;
    }
  }
  return @"未命名记忆";
}

- (NSDictionary<NSString *, NSDictionary *> *)savedInteractionSnapshots {
  NSString *key = [self interactionSnapshotStorageKey];
  NSDictionary *saved = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
  return [saved isKindOfClass:[NSDictionary class]] ? saved : @{};
}

- (void)saveInteractionSnapshots:(NSDictionary<NSString *, NSDictionary *> *)snapshots {
  if (![snapshots isKindOfClass:[NSDictionary class]]) {
    return;
  }
  NSString *key = [self interactionSnapshotStorageKey];
  [[NSUserDefaults standardUserDefaults] setObject:snapshots forKey:key];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)interactionSnapshotStorageKey {
  NSInteger userId = [YALAuthManager sharedManager].currentUser.userId;
  if (userId <= 0) {
    userId = 0;
  }
  return [NSString stringWithFormat:@"%@_%ld", kYALMessageSnapshotKeyPrefix, (long)userId];
}

- (void)refreshHeaderView {
  UIView *headerView = [self buildHeaderView];
  self.tableView.tableHeaderView = headerView;
}

- (UIView *)buildHeaderView {
  CGFloat width = CGRectGetWidth(self.view.bounds);
  if (width <= 0) {
    width = [UIScreen mainScreen].bounds.size.width;
  }

  UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 142.0)];
  header.backgroundColor = [UIColor clearColor];

  UILabel *introLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  introLabel.text = self.unreadInteractionCount > 0 ? [NSString stringWithFormat:@"这次新收到 %ld 条互动", (long)self.unreadInteractionCount] : @"最近没有新增互动";
  introLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
  introLabel.textColor = [UIColor colorWithRed:0.34 green:0.28 blue:0.20 alpha:1.0];
  [header addSubview:introLabel];

  [introLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(header.mas_left).offset(16.0);
    make.top.equalTo(header.mas_top).offset(22.0);
  }];

  NSArray<NSDictionary *> *items = @[
    @{
      @"title": @"收到喜欢",
      @"count": [NSString stringWithFormat:@"%ld", (long)self.totalLikeCount],
      @"icon": @"heart.fill",
      @"bgColor": [UIColor colorWithRed:0.995 green:0.955 blue:0.91 alpha:1.0],
      @"iconColor": [self accentColor]
    },
    @{
      @"title": @"收到评论",
      @"count": [NSString stringWithFormat:@"%ld", (long)self.totalCommentCount],
      @"icon": @"bubble.left.and.bubble.right.fill",
      @"bgColor": [UIColor colorWithRed:1.0 green:0.97 blue:0.93 alpha:1.0],
      @"iconColor": [self warmBrownColor]
    },
    @{
      @"title": @"收到收藏",
      @"count": [NSString stringWithFormat:@"%ld", (long)self.totalCollectCount],
      @"icon": @"bookmark.fill",
      @"bgColor": [UIColor colorWithRed:1.0 green:0.975 blue:0.945 alpha:1.0],
      @"iconColor": [self mutedAccentColor]
    }
  ];

  CGFloat gap = 10.0;
  NSMutableArray<UIView *> *cards = [NSMutableArray array];
  for (NSDictionary *item in items) {
    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.backgroundColor = item[@"bgColor"];
    card.layer.cornerRadius = 16.0;
    card.layer.masksToBounds = YES;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [self softBorderColor].CGColor;

    UIView *iconBadge = [[UIView alloc] initWithFrame:CGRectZero];
    iconBadge.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
    iconBadge.layer.cornerRadius = 15.0;

    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 13.0, *)) {
      iconView.image = [UIImage systemImageNamed:item[@"icon"]];
    }
    iconView.tintColor = item[@"iconColor"];
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = item[@"title"];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithRed:0.42 green:0.34 blue:0.25 alpha:1.0];

    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    countLabel.text = item[@"count"];
    countLabel.textAlignment = NSTextAlignmentLeft;
    countLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    countLabel.textColor = [UIColor colorWithRed:0.28 green:0.22 blue:0.16 alpha:1.0];

    UILabel *unitLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    unitLabel.text = @"累计";
    unitLabel.textAlignment = NSTextAlignmentLeft;
    unitLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    unitLabel.textColor = [UIColor colorWithRed:0.55 green:0.45 blue:0.34 alpha:1.0];

    [iconBadge addSubview:iconView];
    [card addSubview:iconBadge];
    [card addSubview:titleLabel];
    [card addSubview:countLabel];
    [card addSubview:unitLabel];
    [header addSubview:card];
    [cards addObject:card];

    [iconBadge mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(card.mas_top).offset(12.0);
      make.right.equalTo(card.mas_right).offset(-12.0);
      make.width.height.mas_equalTo(30.0);
    }];

    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.center.equalTo(iconBadge);
      make.width.height.mas_equalTo(16.0);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(card.mas_top).offset(14.0);
      make.left.equalTo(card.mas_left).offset(12.0);
      make.right.lessThanOrEqualTo(iconBadge.mas_left).offset(-8.0);
    }];

    [countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(titleLabel);
      make.right.equalTo(card.mas_right).offset(-12.0);
      make.top.equalTo(titleLabel.mas_bottom).offset(14.0);
    }];

    [unitLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(titleLabel);
      make.top.equalTo(countLabel.mas_bottom).offset(4.0);
      make.right.equalTo(card.mas_right).offset(-12.0);
    }];
  }

  UIView *firstCard = cards.firstObject;
  UIView *secondCard = cards.count > 1 ? cards[1] : nil;
  UIView *thirdCard = cards.count > 2 ? cards[2] : nil;

  [firstCard mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(header.mas_left).offset(16.0);
    make.top.equalTo(introLabel.mas_bottom).offset(14.0);
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
  (void)tableView;
  (void)section;
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
  return 82.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (indexPath.row >= self.messages.count) {
    return;
  }

  YALPostModel *post = self.messages[indexPath.row][@"post"];
  if (![post isKindOfClass:[YALPostModel class]]) {
    return;
  }

  YALPostDetailController *detailController = [[YALPostDetailController alloc] init];
  detailController.post = post;
  detailController.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:detailController animated:YES];
}

- (void)backTapped {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)markAllAsReadTapped {
  NSMutableDictionary<NSString *, NSDictionary *> *snapshots = [NSMutableDictionary dictionary];
  for (NSDictionary *message in self.messages) {
    YALPostModel *post = message[@"post"];
    if (![post isKindOfClass:[YALPostModel class]] || post.contentId.integerValue <= 0) {
      continue;
    }
    snapshots[[NSString stringWithFormat:@"%@", post.contentId]] = @{
      @"like_count": @(MAX(post.likeCount, 0)),
      @"comment_count": @(MAX(post.commentCount, 0)),
      @"collect_count": @(MAX(post.collectCount, 0))
    };
  }
  [self saveInteractionSnapshots:snapshots];
  [self loadMessages];
}

#pragma mark - Colors

- (UIImage *)symbolImageNamed:(NSString *)name {
  if (@available(iOS 13.0, *)) {
    UIImage *image = [UIImage systemImageNamed:name];
    if (image) {
      return image;
    }
  }
  return [[UIImage alloc] init];
}

- (UIColor *)accentColor {
  return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
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
