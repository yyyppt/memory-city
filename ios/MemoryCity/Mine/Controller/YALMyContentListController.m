//
//  YALMyContentListController.m
//  MemoryCity
//
//  Created by mac on 2026/3/30.
//

#import "YALMyContentListController.h"
#import "YALMyContentModel.h"
#import "YALContentManager.h"
#import "YALAuthManager.h"
#import "YALPostModel.h"
#import "YALPostDetailController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

static BOOL YALBoolFromPublicValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value boolValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *lower = [[(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
        if (lower.length == 0) return NO;
        if ([lower isEqualToString:@"1"] ||
            [lower isEqualToString:@"true"] ||
            [lower isEqualToString:@"yes"] ||
            [lower isEqualToString:@"public"] ||
            [lower isEqualToString:@"公开"]) {
            return YES;
        }
        if ([lower isEqualToString:@"0"] ||
            [lower isEqualToString:@"false"] ||
            [lower isEqualToString:@"no"] ||
            [lower isEqualToString:@"2"] ||
            [lower isEqualToString:@"private"] ||
            [lower isEqualToString:@"only_self"] ||
            [lower isEqualToString:@"self"] ||
            [lower isEqualToString:@"personal"] ||
            [lower isEqualToString:@"私密"] ||
            [lower isEqualToString:@"仅自己可见"]) {
            return NO;
        }
        return NO;
    }
    return NO;
}

static id YALResolvedVisibilityValue(NSDictionary *dict) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id value = dict[@"is_public"];
    return value;
}

@interface YALMyContentCell : UITableViewCell

/// 配置Cell
/// @param model 内容模型
- (void)configureWithModel:(YALMyContentModel *)model;

@end

@interface YALMyContentCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIImageView *moodImageView;
@property (nonatomic, strong) UIView *imageContainerView;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *imageViews;

@end

@implementation YALMyContentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 卡片视图
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [UIColor whiteColor];
    self.cardView.layer.cornerRadius = 12;
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 2);
    self.cardView.layer.shadowOpacity = 0.1;
    self.cardView.layer.shadowRadius = 4;
    [self.contentView addSubview:self.cardView];
    
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor darkTextColor];
    self.titleLabel.numberOfLines = 1;
    [self.cardView addSubview:self.titleLabel];
    
    // 心情图标
    self.moodImageView = [[UIImageView alloc] init];
    self.moodImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.moodImageView.tintColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    [self.cardView addSubview:self.moodImageView];
    
    // 内容标签
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.contentLabel.textColor = [UIColor darkGrayColor];
    self.contentLabel.numberOfLines = 3;
    [self.cardView addSubview:self.contentLabel];
    
    // 信息标签
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.infoLabel.textColor = [UIColor grayColor];
    [self.cardView addSubview:self.infoLabel];
    
    // 图片容器
    self.imageContainerView = [[UIView alloc] init];
    [self.cardView addSubview:self.imageContainerView];
    
    self.imageViews = [NSMutableArray array];
}

- (void)setupConstraints {
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView).offset(-8);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(16);
        make.left.equalTo(self.cardView).offset(16);
        make.right.equalTo(self.moodImageView.mas_left).offset(-8);
    }];
    
    [self.moodImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleLabel);
        make.right.equalTo(self.cardView).offset(-16);
        make.width.height.equalTo(@24);
    }];
    
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.left.equalTo(self.cardView).offset(16);
        make.right.equalTo(self.cardView).offset(-16);
    }];
    
    [self.imageContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(12);
        make.left.equalTo(self.cardView).offset(16);
        make.right.equalTo(self.cardView).offset(-16);
        make.height.equalTo(@80);
    }];
    
    [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageContainerView.mas_bottom).offset(12);
        make.left.equalTo(self.cardView).offset(16);
        make.right.equalTo(self.cardView).offset(-16);
        make.bottom.equalTo(self.cardView).offset(-16);
    }];
}

- (void)configureWithModel:(YALMyContentModel *)model {
    // 设置标题
    self.titleLabel.text = model.title ?: @"无标题";
    
    // 设置心情图标
    NSString *moodIcon = [self moodIconForMood:model.mood];
    if (@available(iOS 13.0, *)) {
        self.moodImageView.image = [UIImage systemImageNamed:moodIcon];
    }
    
    // 设置内容
    self.contentLabel.text = model.content ?: @"";
    
    // 设置信息
    NSString *infoText = [NSString stringWithFormat:@"%@ · %s · %@",
                         model.city ?: @"未知城市",
                         model.year ? [model.year UTF8String] : "未知年份",
                         model.createTime ?: @""];
    self.infoLabel.text = infoText;
    
    // 清除旧图片
    for (UIImageView *imageView in self.imageViews) {
        [imageView sd_cancelCurrentImageLoad];
        [imageView removeFromSuperview];
    }
    [self.imageViews removeAllObjects];
    
    // 添加新图片
    if (model.images.count > 0) {
        CGFloat imageWidth = 60;
        CGFloat spacing = 8;
        
        for (NSInteger i = 0; i < MIN(model.images.count, 3); i++) {
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            imageView.layer.cornerRadius = 6;
            imageView.backgroundColor = [UIColor systemGray6Color];

            if (@available(iOS 13.0, *)) {
                imageView.image = [UIImage systemImageNamed:@"photo"];
                imageView.tintColor = [UIColor systemGray3Color];
            }

            NSString *imageURLString = model.images[i];
            if ([imageURLString isKindOfClass:[NSString class]] && imageURLString.length > 0) {
                NSURL *imageURL = [NSURL URLWithString:imageURLString];
                if (imageURL && imageURL.scheme.length > 0) {
                    [imageView sd_setImageWithURL:imageURL
                                 placeholderImage:imageView.image
                                          options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
                }
            }
            
            [self.imageContainerView addSubview:imageView];
            [self.imageViews addObject:imageView];
            
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.imageContainerView).offset(i * (imageWidth + spacing));
                make.top.bottom.equalTo(self.imageContainerView);
                make.width.equalTo(@(imageWidth));
            }];
        }
    }
}

- (NSString *)moodIconForMood:(NSString *)mood {
    NSDictionary *moodIcons = @{
        @"治愈": @"heart.fill",
        @"开心": @"face.smiling",
        @"平静": @"wind",
        @"感动": @"heart",
        @"怀念": @"clock.arrow.circlepath",
        @"兴奋": @"star.fill",
        @"放松": @"leaf.fill",
        @"思考": @"brain.head.profile",
        @"孤独": @"moon.stars.fill",
        @"期待": @"sparkles"
    };
    
    return moodIcons[mood] ?: @"heart";
}

@end

#pragma mark - 我的内容列表控制器实现

@interface YALMyContentListController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSString *pageTitle;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<YALMyContentModel *> *contentList;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMoreData;
@property (nonatomic, assign) BOOL hasPresentedEmptyPrivateAlert;

@end

@implementation YALMyContentListController

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _pageTitle = [title copy];
        _contentList = [NSMutableArray array];
        _currentPage = 1;
        _hasMoreData = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self loadData];
}

- (void)setupUI {
    self.title = self.pageTitle;
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 200;
    [self.tableView registerClass:[YALMyContentCell class] forCellReuseIdentifier:@"YALMyContentCell"];
    [self.view addSubview:self.tableView];
    
    // 创建空状态标签
    self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    self.emptyLabel.text = @"还没有发布内容\n快去发布你的第一条记忆吧！";
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.hidden = YES;
    self.tableView.backgroundView = self.emptyLabel;
    
    // 创建加载指示器
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];
    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    // 添加下拉刷新
    if (@available(iOS 10.0, *)) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
        self.tableView.refreshControl = refreshControl;
    }
}

#pragma mark - 数据加载

- (void)loadData {
    if (self.isLoading) return;
    
    self.isLoading = YES;
    [self.loadingIndicator startAnimating];
    BOOL isFirstPageRequest = (self.currentPage == 1);

    [[YALContentManager sharedManager] getMyContentListWithPage:self.currentPage
                                                       pageSize:10
                                                     completion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isLoading = NO;
            [self.loadingIndicator stopAnimating];
            
            if (self.tableView.refreshControl.isRefreshing) {
                [self.tableView.refreshControl endRefreshing];
            }
            
            if (success) {
                if (self.currentPage == 1) {
                    [self.contentList removeAllObjects];
                }
                
                if (contentList.count > 0) {
                    // 将字典数组转换为模型数组
                    NSMutableArray *modelArray = [NSMutableArray array];
                    for (NSDictionary *dict in contentList) {
                        if ([dict isKindOfClass:[NSDictionary class]]) {
                            if (![self shouldIncludeContentDict:dict]) {
                                continue;
                            }
                            YALMyContentModel *model = [[YALMyContentModel alloc] initWithDictionary:dict];
                            [modelArray addObject:model];
                        }
                    }
                    
                    [self.contentList addObjectsFromArray:modelArray];
                    self.hasMoreData = contentList.count >= 10; // 按接口原始返回数量判断是否还有下一页
                    self.currentPage++;
                } else {
                    self.hasMoreData = NO;
                }
                
                [self updateEmptyState];
                [self.tableView reloadData];

                if (isFirstPageRequest && self.contentList.count == 0 && [self isPrivateContentPage]) {
                    [self presentEmptyPrivateAlertIfNeeded];
                    return;
                }
                
                if (contentList.count == 0 && isFirstPageRequest) {
                    [self showMessage:@"暂无发布内容" type:0];
                }
            } else {
                [self showMessage:message ?: @"加载失败" type:1];
                
                if (self.contentList.count == 0) {
                    [self updateEmptyState];
                }
            }
        });
    }];
}

- (BOOL)shouldIncludeContentDict:(NSDictionary *)dict {
    BOOL shouldShowPublicOnly = [self.pageTitle isEqualToString:@"公开内容"];
    BOOL shouldShowPrivateOnly = [self.pageTitle isEqualToString:@"私人内容"] || [self.pageTitle isEqualToString:@"私密内容"];
    if (!shouldShowPublicOnly && !shouldShowPrivateOnly) {
        return YES;
    }

    BOOL isPublic = YALBoolFromPublicValue(YALResolvedVisibilityValue(dict));
    return shouldShowPublicOnly ? isPublic : !isPublic;
}

- (BOOL)isPrivateContentPage {
    return [self.pageTitle isEqualToString:@"私人内容"] || [self.pageTitle isEqualToString:@"私密内容"];
}

- (void)presentEmptyPrivateAlertIfNeeded {
    if (self.hasPresentedEmptyPrivateAlert) {
        return;
    }
    self.hasPresentedEmptyPrivateAlert = YES;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"暂无私密内容"
                                                                   message:@"你当前还没有私密发布，先返回上一页看看公开内容吧。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)refreshData {
    self.currentPage = 1;
    self.hasMoreData = YES;
    [self loadData];
}

- (void)updateEmptyState {
    self.emptyLabel.hidden = (self.contentList.count > 0);
    self.tableView.backgroundView.hidden = !self.emptyLabel.hidden;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.contentList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YALMyContentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YALMyContentCell" forIndexPath:indexPath];
    
    if (indexPath.row < self.contentList.count) {
        YALMyContentModel *model = self.contentList[indexPath.row];
        [cell configureWithModel:model];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.contentList.count) {
        YALMyContentModel *model = self.contentList[indexPath.row];
        [self showContentDetail:model];
    }
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
    if (indexPath.row >= self.contentList.count) {
        return nil;
    }

    __weak typeof(self) weakSelf = self;
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                                title:@"删除"
                                                                              handler:^(__unused UIContextualAction * _Nonnull action, __unused UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf confirmDeleteAtIndexPath:indexPath completion:completionHandler];
    }];
    deleteAction.backgroundColor = [UIColor systemRedColor];

    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.row < self.contentList.count) {
        [self confirmDeleteAtIndexPath:indexPath completion:^(BOOL finished) {
            if (!finished) {
                [tableView setEditing:NO animated:YES];
            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 滚动到底部时加载更多
    if (indexPath.row == self.contentList.count - 1 && self.hasMoreData && !self.isLoading) {
        [self loadData];
    }
}

#pragma mark - 内容详情

- (void)showContentDetail:(YALMyContentModel *)model {
    if (!model) {
        return;
    }
    YALPostDetailController *detailController = [[YALPostDetailController alloc] init];
    detailController.post = [self postModelFromMyContent:model];
    detailController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detailController animated:YES];
}

- (YALPostModel *)postModelFromMyContent:(YALMyContentModel *)model {
    YALPostModel *post = [[YALPostModel alloc] init];
    post.contentId = model.contentId;
    post.title = model.title ?: @"";
    post.content = model.content ?: @"";
    post.desc = model.content ?: @"";
    post.city = model.city ?: @"";
    post.year = model.year ?: @"";
    post.mood = model.mood ?: @"";
    post.images = model.images ?: @[];
    post.createTime = model.createTime ?: @"";
    post.imageURLString = model.images.firstObject ?: @"";
    if (@available(iOS 13.0, *)) {
        post.image = [UIImage systemImageNamed:@"photo"];
    } else {
        post.image = [[UIImage alloc] init];
    }
    post.imageWidth = MAX(post.image.size.width, 1.0);
    post.imageHeight = MAX(post.image.size.height, 1.0);
    return post;
}

#pragma mark - 工具方法

- (void)confirmDeleteAtIndexPath:(NSIndexPath *)indexPath completion:(void (^)(BOOL finished))completion {
    if (indexPath.row >= self.contentList.count) {
        if (completion) completion(NO);
        return;
    }
    YALMyContentModel *model = self.contentList[indexPath.row];
    [self showDeleteConfirmAlertWithModel:model confirmHandler:^{
        [self deleteContent:model indexPath:indexPath completion:completion];
    } cancelHandler:^{
        if (completion) completion(NO);
    }];
}

- (void)confirmDeleteForModel:(YALMyContentModel *)model {
    NSUInteger index = [self.contentList indexOfObject:model];
    NSIndexPath *indexPath = (index != NSNotFound) ? [NSIndexPath indexPathForRow:index inSection:0] : nil;
    [self showDeleteConfirmAlertWithModel:model confirmHandler:^{
        [self deleteContent:model indexPath:indexPath completion:nil];
    } cancelHandler:nil];
}

- (void)showDeleteConfirmAlertWithModel:(YALMyContentModel *)model
                         confirmHandler:(dispatch_block_t)confirmHandler
                          cancelHandler:(nullable dispatch_block_t)cancelHandler {
    NSString *title = @"确认删除";
    NSString *message = [NSString stringWithFormat:@"确定删除《%@》吗？删除后不可恢复。", model.title.length > 0 ? model.title : @"这条内容"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        if (cancelHandler) {
            cancelHandler();
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        if (confirmHandler) {
            confirmHandler();
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteContent:(YALMyContentModel *)model
            indexPath:(nullable NSIndexPath *)indexPath
           completion:(void (^ _Nullable)(BOOL finished))completion {
    if (!model.contentId || model.contentId.integerValue <= 0) {
        [self showMessage:@"内容ID无效，无法删除" type:1];
        if (completion) completion(NO);
        return;
    }

    [self.loadingIndicator startAnimating];
    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] deleteContentWithId:model.contentId completion:^(BOOL success, NSString *message, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.loadingIndicator stopAnimating];
        if (!strongSelf) return;

        if (success) {
            NSUInteger index = NSNotFound;
            if (indexPath && indexPath.row < strongSelf.contentList.count) {
                YALMyContentModel *target = strongSelf.contentList[indexPath.row];
                if ([target.contentId isEqual:model.contentId]) {
                    index = indexPath.row;
                }
            }
            if (index == NSNotFound) {
                index = [strongSelf.contentList indexOfObjectPassingTest:^BOOL(YALMyContentModel * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop) {
                    return [obj.contentId isEqual:model.contentId];
                }];
            }

            if (index != NSNotFound && index < strongSelf.contentList.count) {
                [strongSelf.contentList removeObjectAtIndex:index];
                [strongSelf.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                            withRowAnimation:UITableViewRowAnimationAutomatic];
                [strongSelf updateEmptyState];
            } else {
                [strongSelf.tableView reloadData];
                [strongSelf updateEmptyState];
            }
            [strongSelf showMessage:message.length > 0 ? message : @"删除成功" type:0];
            if (completion) completion(YES);
        } else {
            NSString *errorMessage = message.length > 0 ? message : (error.localizedDescription ?: @"删除失败");
            [strongSelf showMessage:errorMessage type:1];
            if (completion) completion(NO);
        }
    }];
}

- (void)showMessage:(NSString *)message type:(NSInteger)type {
    // 在实际项目中，可以使用更完善的提示组件
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
