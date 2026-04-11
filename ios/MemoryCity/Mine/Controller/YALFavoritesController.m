//
//  YALFavoritesController.m
//  MemoryCity
//
//  Created by mac on 2026/4/1.
//

#import "YALFavoritesController.h"
#import <Masonry/Masonry.h>
#import "YALContentManager.h"
#import "YALPostModel.h"
#import "YALPostDetailController.h"
#import "YALAuthManager.h"

static NSString * const kYALCollectedStatusCachePrefix = @"YALPostDetailCollectedStatus";

@interface YALFavoritesController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<YALPostModel *> *favoritesData;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasLoadedOnce;
@property (nonatomic, assign) NSInteger statsRefreshToken;

@end

@implementation YALFavoritesController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.favoritesData = [NSMutableArray array];
    [self setupUI];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.hasLoadedOnce) {
        [self loadData];
    }
}

- (void)setupUI {
    self.title = @"我的收藏";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 104;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];

    self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.emptyLabel.text = @"还没有收藏内容\n发现喜欢的内容可以收藏起来哦！";
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
        [refreshControl addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
        self.tableView.refreshControl = refreshControl;
    }
}

- (void)loadData {
    if (self.isLoading) {
        return;
    }

    if (![[YALAuthManager sharedManager] hasLoggedInSession]) {
        self.emptyLabel.text = @"登录后可查看我的收藏\n先去登录，再回来看看收藏夹吧。";
        [self.favoritesData removeAllObjects];
        [self.tableView reloadData];
        [self updateEmptyState];
        return;
    }

    self.isLoading = YES;
    [self.loadingIndicator startAnimating];

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] getMyCollectListWithCompletion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        strongSelf.isLoading = NO;
        strongSelf.hasLoadedOnce = YES;
        [strongSelf.loadingIndicator stopAnimating];

        if (@available(iOS 10.0, *)) {
            if (strongSelf.tableView.refreshControl.isRefreshing) {
                [strongSelf.tableView.refreshControl endRefreshing];
            }
        }

        if (!success) {
            if (strongSelf.favoritesData.count == 0) {
                NSString *displayMessage = message.length > 0 ? message : (error.localizedDescription ?: @"加载失败");
                [strongSelf showMessage:displayMessage type:1];
            }
            [strongSelf updateEmptyState];
            return;
        }

        [strongSelf.favoritesData removeAllObjects];
        for (id item in contentList) {
            if (![item isKindOfClass:[YALPostModel class]]) {
                continue;
            }
            YALPostModel *model = (YALPostModel *)item;
            // /interact/collect/my 返回的就是“我的收藏”，这里以后端结果为准，
            // 避免本地旧缓存把已收藏状态覆盖成未收藏。
            model.isCollected = YES;
            if (model.collectCount <= 0) {
                // “我的收藏”列表里，最少也应该包含当前用户这 1 次收藏。
                model.collectCount = 1;
            }
            [strongSelf persistCollectedStatus:YES contentId:model.contentId];
            [strongSelf.favoritesData addObject:model];
        }

        [strongSelf.tableView reloadData];
        [strongSelf updateEmptyState];
        [strongSelf refreshFavoriteStatsFromDetail];
    }];
}

- (void)updateEmptyState {
    self.emptyLabel.hidden = (self.favoritesData.count > 0);
    self.tableView.backgroundView.hidden = self.emptyLabel.hidden;
}

#pragma mark - Detail Stats Sync

- (void)refreshFavoriteStatsFromDetail {
    if (self.favoritesData.count == 0) {
        return;
    }

    NSInteger refreshToken = ++self.statsRefreshToken;
    __weak typeof(self) weakSelf = self;

    for (YALPostModel *model in self.favoritesData) {
        if (![model.contentId respondsToSelector:@selector(integerValue)] || model.contentId.integerValue <= 0) {
            continue;
        }

        [[YALContentManager sharedManager] getContentDetailWithId:model.contentId completion:^(BOOL success, NSDictionary * _Nullable content, NSError * _Nullable error) {
            (void)error;
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (refreshToken != strongSelf.statsRefreshToken) {
                return;
            }
            if (!success || ![content isKindOfClass:[NSDictionary class]]) {
                return;
            }

            BOOL changed = [strongSelf applyStatsFromContent:content toModel:model];
            if (!changed) {
                return;
            }

            NSUInteger index = [strongSelf.favoritesData indexOfObjectPassingTest:^BOOL(YALPostModel * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop) {
                return [obj.contentId isEqual:model.contentId];
            }];

            if (index != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)index inSection:0];
                if ([strongSelf.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                    [strongSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                } else {
                    [strongSelf.tableView reloadData];
                }
            }
        }];
    }
}

- (BOOL)applyStatsFromContent:(NSDictionary *)content toModel:(YALPostModel *)model {
    NSInteger previousLike = MAX(model.likeCount, 0);
    NSInteger previousComment = MAX(model.commentCount, 0);
    NSInteger previousCollect = MAX(model.collectCount, 0);

    NSInteger likeCount = [self integerValueRecursivelyFromObject:content keys:@[@"like_count", @"likeCount", @"liked_count", @"likes_count"] fallback:previousLike];
    NSInteger commentCount = [self integerValueRecursivelyFromObject:content keys:@[@"comment_count", @"commentCount", @"comments_count"] fallback:previousComment];
    NSInteger collectCount = [self integerValueRecursivelyFromObject:content keys:@[@"collect_count", @"favorite_count", @"collected_count", @"collectCount", @"favoriteCount"] fallback:previousCollect];

    model.likeCount = MAX(likeCount, 0);
    model.commentCount = MAX(commentCount, 0);
    model.collectCount = MAX(collectCount, 0);
    if (model.isCollected && model.collectCount <= 0) {
        model.collectCount = 1;
    }

    return (model.likeCount != previousLike ||
            model.commentCount != previousComment ||
            model.collectCount != previousCollect);
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

- (NSInteger)integerValueRecursivelyFromObject:(id)object
                                          keys:(NSArray<NSString *> *)keys
                                      fallback:(NSInteger)fallback {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        NSInteger directValue = [self integerValueFromDictionary:dict keys:keys fallback:NSNotFound];
        if (directValue != NSNotFound) {
            return directValue;
        }

        // 优先向常见嵌套结构继续查找
        NSArray *nestedKeys = @[@"data", @"content", @"item", @"post"];
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

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.favoritesData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"YALFavoritesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        cell.detailTextLabel.numberOfLines = 0;
    }

    if (indexPath.row < self.favoritesData.count) {
        YALPostModel *favorite = self.favoritesData[indexPath.row];

        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"star.fill"];
            cell.imageView.tintColor = [UIColor systemOrangeColor];
        }

        NSString *title = favorite.title.length > 0 ? favorite.title : @"收藏内容";
        cell.textLabel.text = title;

        NSMutableArray<NSString *> *details = [NSMutableArray array];
        if (favorite.city.length > 0) {
            [details addObject:favorite.city];
        }
        if (favorite.year.length > 0) {
            [details addObject:favorite.year];
        }
        NSString *metaText = details.count > 0 ? [details componentsJoinedByString:@" · "] : @"已收藏";
        NSString *preview = favorite.content.length > 0 ? favorite.content : @"点击查看内容详情";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n❤️ %ld  💬 %ld  ⭐️ %ld\n%@",
                                     metaText,
                                     (long)MAX(favorite.likeCount, 0),
                                     (long)MAX(favorite.commentCount, 0),
                                     (long)MAX(favorite.collectCount, 0),
                                     preview];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row < self.favoritesData.count) {
        YALPostModel *favorite = self.favoritesData[indexPath.row];
        [self showFavoriteDetail:favorite];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"这里显示你收藏过的内容";
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
    if (indexPath.row >= self.favoritesData.count) {
        return nil;
    }

    __weak typeof(self) weakSelf = self;
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                                title:@"取消收藏"
                                                                              handler:^(__unused UIContextualAction * _Nonnull action, __unused UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            completionHandler(NO);
            return;
        }
        [strongSelf confirmUnfavoriteAtIndexPath:indexPath completion:completionHandler];
    }];
    deleteAction.backgroundColor = [UIColor systemOrangeColor];

    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

#pragma mark - Detail / Unfavorite

- (void)showFavoriteDetail:(YALPostModel *)favorite {
    YALPostDetailController *detailController = [[YALPostDetailController alloc] init];
    detailController.post = favorite;
    detailController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detailController animated:YES];
}

- (void)confirmUnfavoriteAtIndexPath:(NSIndexPath *)indexPath completion:(void (^)(BOOL finished))completion {
    if (indexPath.row >= self.favoritesData.count) {
        if (completion) {
            completion(NO);
        }
        return;
    }

    YALPostModel *favorite = self.favoritesData[indexPath.row];
    [self showUnfavoriteConfirmAlertWithFavorite:favorite confirmHandler:^{
        [self unfavoritePost:favorite indexPath:indexPath completion:completion];
    } cancelHandler:^{
        if (completion) {
            completion(NO);
        }
    }];
}

- (void)showUnfavoriteConfirmAlertWithFavorite:(YALPostModel *)favorite
                                confirmHandler:(dispatch_block_t)confirmHandler
                                 cancelHandler:(nullable dispatch_block_t)cancelHandler {
    NSString *message = [NSString stringWithFormat:@"确定取消收藏《%@》吗？", favorite.title.length > 0 ? favorite.title : @"这条内容"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认取消收藏"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        if (cancelHandler) {
            cancelHandler();
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消收藏"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        if (confirmHandler) {
            confirmHandler();
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)unfavoritePost:(YALPostModel *)favorite
             indexPath:(nullable NSIndexPath *)indexPath
            completion:(void (^ _Nullable)(BOOL finished))completion {
    if (favorite.contentId.integerValue <= 0) {
        [self showMessage:@"内容ID无效，无法取消收藏" type:1];
        if (completion) {
            completion(NO);
        }
        return;
    }

    [self.loadingIndicator startAnimating];

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] toggleCollectContentWithId:favorite.contentId completion:^(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        [strongSelf.loadingIndicator stopAnimating];

        BOOL isCollected = NO;
        id collectedStatusObj = result[@"is_collected"];
        if (![collectedStatusObj respondsToSelector:@selector(boolValue)]) {
            collectedStatusObj = result[@"is_collect"];
        }
        if (![collectedStatusObj respondsToSelector:@selector(boolValue)]) {
            collectedStatusObj = result[@"collected"];
        }
        if (![collectedStatusObj respondsToSelector:@selector(boolValue)]) {
            collectedStatusObj = result[@"collect_status"];
        }
        if ([collectedStatusObj respondsToSelector:@selector(boolValue)]) {
            isCollected = [collectedStatusObj boolValue];
        }

        if (success && !isCollected) {
            NSUInteger index = NSNotFound;
            if (indexPath && indexPath.row < strongSelf.favoritesData.count) {
                YALPostModel *target = strongSelf.favoritesData[indexPath.row];
                if ([target.contentId isEqual:favorite.contentId]) {
                    index = indexPath.row;
                }
            }
            if (index == NSNotFound) {
                index = [strongSelf.favoritesData indexOfObjectPassingTest:^BOOL(YALPostModel * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop) {
                    return [obj.contentId isEqual:favorite.contentId];
                }];
            }

            if (index != NSNotFound && index < strongSelf.favoritesData.count) {
                [strongSelf.favoritesData removeObjectAtIndex:index];
                [strongSelf.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                             withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [strongSelf.tableView reloadData];
            }
            [strongSelf persistCollectedStatus:NO contentId:favorite.contentId];
            [strongSelf updateEmptyState];
            [strongSelf showMessage:@"已取消收藏" type:0];
            if (completion) {
                completion(YES);
            }
            return;
        }

        NSString *displayMessage = error.localizedDescription.length > 0 ? error.localizedDescription : @"取消收藏失败";
        [strongSelf showMessage:displayMessage type:1];
        if (completion) {
            completion(NO);
        }
    }];
}

#pragma mark - Cache

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

- (void)persistCollectedStatus:(BOOL)value contentId:(NSNumber *)contentId {
    if (contentId.integerValue <= 0) {
        return;
    }

    NSInteger userId = [YALAuthManager sharedManager].currentUser.userId;
    NSString *key = userId > 0 ? [NSString stringWithFormat:@"%@_%ld_%@", kYALCollectedStatusCachePrefix, (long)userId, contentId]
                               : [NSString stringWithFormat:@"%@_%@", kYALCollectedStatusCachePrefix, contentId];
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Helpers

- (void)showMessage:(NSString *)message type:(NSInteger)type {
    (void)type;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
