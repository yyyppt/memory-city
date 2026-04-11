//
//  YALLikesController.m
//  MemoryCity
//
//  Created by mac on 2026/4/1.
//

#import "YALLikesController.h"
#import <Masonry/Masonry.h>
#import "YALContentManager.h"
#import "YALPostModel.h"
#import "YALPostDetailController.h"
#import "YALAuthManager.h"

@interface YALLikesController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<YALPostModel *> *likesData;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasMoreData;
@property (nonatomic, assign) BOOL hasLoadedOnce;

@end

@implementation YALLikesController

static NSString * const kYALLikedStatusCachePrefix = @"YALPostDetailLikedStatus";
static NSString * const kYALCollectedStatusCachePrefix = @"YALPostDetailCollectedStatus";
static NSString * const kYALInteractionCachePrefix = @"YALPostDetailInteractionCache";

- (void)viewDidLoad {
    [super viewDidLoad];

    self.likesData = [NSMutableArray array];
    self.currentPage = 1;
    self.hasMoreData = YES;

    [self setupUI];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self syncCachedInteractionStateForLikesData];

    if (self.hasLoadedOnce) {
        [self refreshData];
    }
}

- (void)setupUI {
    self.title = @"我的点赞";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 110;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    // 创建空状态标签
    self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.emptyLabel.text = @"还没有点赞内容\n去首页逛逛，把喜欢的内容点亮吧！";
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.hidden = YES;
    self.tableView.backgroundView = self.emptyLabel;

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];
    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    if (@available(iOS 10.0, *)) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
        self.tableView.refreshControl = refreshControl;
    }
}

- (void)loadData {
    if (self.isLoading) {
        return;
    }

    if (![[YALAuthManager sharedManager] hasLoggedInSession]) {
        self.emptyLabel.text = @"登录后可查看我的点赞\n先去登录，再回来看看喜欢过的内容吧。";
        [self.likesData removeAllObjects];
        [self.tableView reloadData];
        [self updateEmptyState];
        return;
    }

    self.isLoading = YES;
    [self.loadingIndicator startAnimating];

    [[YALContentManager sharedManager] getAllContentListWithPage:self.currentPage
                                                        pageSize:20
                                                      completion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
        self.isLoading = NO;
        self.hasLoadedOnce = YES;
        [self.loadingIndicator stopAnimating];

        if (@available(iOS 10.0, *)) {
            if (self.tableView.refreshControl.isRefreshing) {
                [self.tableView.refreshControl endRefreshing];
            }
        }

        if (!success) {
            if (self.likesData.count == 0) {
                [self showMessage:message.length > 0 ? message : (error.localizedDescription ?: @"加载失败") type:1];
            }
            [self updateEmptyState];
            return;
        }

        if (self.currentPage == 1) {
            [self.likesData removeAllObjects];
        }

        NSMutableArray<YALPostModel *> *likedPosts = [NSMutableArray array];
        for (id item in contentList) {
            if (![item isKindOfClass:[YALPostModel class]]) {
                continue;
            }
            YALPostModel *model = (YALPostModel *)item;
            BOOL hasCachedValue = NO;
            BOOL cachedLiked = [self cachedBoolStatusForPrefix:kYALLikedStatusCachePrefix contentId:model.contentId hasValue:&hasCachedValue];
            if (hasCachedValue) {
                model.isLiked = cachedLiked;
            }
            [self syncCachedInteractionStateForPost:model];
            if (model.isLiked) {
                [likedPosts addObject:model];
            }
        }

        [self.likesData addObjectsFromArray:likedPosts];
        self.hasMoreData = contentList.count >= 20;
        if (self.hasMoreData) {
            self.currentPage += 1;
        }

        if (likedPosts.count == 0 && self.likesData.count == 0 && self.hasMoreData) {
            [self loadData];
            return;
        }

        [self.tableView reloadData];
        [self updateEmptyState];
    }];
}

- (void)refreshData {
    self.currentPage = 1;
    self.hasMoreData = YES;
    [self loadData];
}

- (void)updateEmptyState {
    self.emptyLabel.hidden = (self.likesData.count > 0);
    self.tableView.backgroundView.hidden = self.emptyLabel.hidden;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.likesData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"YALLikesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        cell.detailTextLabel.numberOfLines = 0;
    }
    
    if (indexPath.row < self.likesData.count) {
        YALPostModel *like = self.likesData[indexPath.row];
        
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"heart.fill"];
            cell.imageView.tintColor = [UIColor systemRedColor];
        }
        
        NSString *contentTitle = like.title.length > 0 ? like.title : @"未命名内容";
        cell.textLabel.text = contentTitle;

        NSMutableArray<NSString *> *details = [NSMutableArray array];
        if (like.city.length > 0) {
            [details addObject:like.city];
        }
        if (like.year.length > 0) {
            [details addObject:like.year];
        }
        NSString *metaText = details.count > 0 ? [details componentsJoinedByString:@" · "] : @"已点赞";
        NSString *contentPreview = like.content.length > 0 ? like.content : @"点击查看内容详情";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n❤️ %ld  💬 %ld  ⭐️ %ld\n%@",
                                     metaText,
                                     (long)MAX(like.likeCount, 0),
                                     (long)MAX(like.commentCount, 0),
                                     (long)MAX(like.collectCount, 0),
                                     contentPreview];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.likesData.count) {
        YALPostModel *like = self.likesData[indexPath.row];
        [self showLikeDetail:like];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"这里显示你点赞过的内容";
}

- (void)showLikeDetail:(YALPostModel *)like {
    YALPostDetailController *detailController = [[YALPostDetailController alloc] init];
    detailController.post = like;
    detailController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detailController animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    (void)cell;
    if (indexPath.row == self.likesData.count - 1 && self.hasMoreData && !self.isLoading) {
        [self loadData];
    }
}

- (BOOL)cachedBoolStatusForPrefix:(NSString *)prefix contentId:(NSNumber *)contentId hasValue:(BOOL *)hasValue {
    if (prefix.length == 0 || contentId.integerValue <= 0) {
        if (hasValue) {
            *hasValue = NO;
        }
        return NO;
    }

    NSInteger userId = [YALAuthManager sharedManager].currentUser.userId;
    NSString *key = userId > 0 ? [NSString stringWithFormat:@"%@_%ld_%@", prefix, (long)userId, contentId]
                               : [NSString stringWithFormat:@"%@_%@", prefix, contentId];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:key] == nil) {
        if (hasValue) {
            *hasValue = NO;
        }
        return NO;
    }
    if (hasValue) {
        *hasValue = YES;
    }
    return [defaults boolForKey:key];
}

- (NSString *)interactionCacheKeyForPrefix:(NSString *)prefix contentId:(NSNumber *)contentId {
    if (prefix.length == 0 || contentId.integerValue <= 0) {
        return nil;
    }

    NSInteger userId = [YALAuthManager sharedManager].currentUser.userId;
    if (userId > 0) {
        return [NSString stringWithFormat:@"%@_%ld_%@", prefix, (long)userId, contentId];
    }
    return [NSString stringWithFormat:@"%@_%@", prefix, contentId];
}

- (void)syncCachedInteractionStateForPost:(YALPostModel *)post {
    if (![post isKindOfClass:[YALPostModel class]]) {
        return;
    }

    BOOL hasCollectedValue = NO;
    BOOL cachedCollected = [self cachedBoolStatusForPrefix:kYALCollectedStatusCachePrefix contentId:post.contentId hasValue:&hasCollectedValue];
    if (hasCollectedValue) {
        post.isCollected = cachedCollected;
    }

    NSString *interactionKey = [self interactionCacheKeyForPrefix:kYALInteractionCachePrefix contentId:post.contentId];
    NSDictionary *interactionCache = interactionKey.length > 0 ? [[NSUserDefaults standardUserDefaults] objectForKey:interactionKey] : nil;
    if (![interactionCache isKindOfClass:[NSDictionary class]]) {
        return;
    }

    id likeCountObj = interactionCache[@"like_count"];
    if ([likeCountObj respondsToSelector:@selector(integerValue)]) {
        post.likeCount = MAX([likeCountObj integerValue], 0);
    }

    id favoriteCountObj = interactionCache[@"favorite_count"];
    if ([favoriteCountObj respondsToSelector:@selector(integerValue)]) {
        post.collectCount = MAX([favoriteCountObj integerValue], 0);
    }

    id commentCountObj = interactionCache[@"comment_count"];
    if ([commentCountObj respondsToSelector:@selector(integerValue)]) {
        post.commentCount = MAX([commentCountObj integerValue], 0);
    }
}

- (void)syncCachedInteractionStateForLikesData {
    if (self.likesData.count == 0) {
        return;
    }

    for (YALPostModel *post in self.likesData) {
        [self syncCachedInteractionStateForPost:post];
    }
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

#pragma mark - 工具方法

- (UIColor *)accentColor {
    return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

- (void)showMessage:(NSString *)message type:(NSInteger)type {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
