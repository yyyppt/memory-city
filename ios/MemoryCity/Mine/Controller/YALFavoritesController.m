//
//  YALFavoritesController.m
//  MemoryCity
//
//  Created by mac on 2026/4/1.
//

#import "YALFavoritesController.h"
#import <Masonry/Masonry.h>

@interface YALFavoritesController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *favoritesData;
@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation YALFavoritesController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupData];
}

- (void)setupUI {
    self.title = @"我的收藏";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 80;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    // 创建空状态标签
    self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.emptyLabel.text = @"还没有收藏内容\n发现喜欢的内容可以收藏起来哦！";
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.hidden = YES;
    self.tableView.backgroundView = self.emptyLabel;
}

- (void)setupData {
    // 模拟收藏数据
    self.favoritesData = @[
        @{
            @"title": @"城市天际线夜景",
            @"author": @"摄影爱好者",
            @"preview": @"上海 · 外滩视角 · 昨天",
            @"category": @"摄影",
            @"isPrivate": @NO
        },
        @{
            @"title": @"老街巷弄的美食地图",
            @"author": @"美食探索家",
            @"preview": @"苏州 · 平江路 · 3天前",
            @"category": @"美食",
            @"isPrivate": @NO
        },
        @{
            @"title": @"骑行路线分享：环湖美景",
            @"author": @"骑行达人",
            @"preview": @"南京 · 玄武湖 · 1周前",
            @"category": @"运动",
            @"isPrivate": @YES
        },
        @{
            @"title": @"独立书店巡礼",
            @"author": @"书店常客",
            @"preview": @"杭州 · 多家书店 · 2周前",
            @"category": @"文化",
            @"isPrivate": @NO
        }
    ];
    
    [self updateEmptyState];
    [self.tableView reloadData];
}

- (void)updateEmptyState {
    self.emptyLabel.hidden = (self.favoritesData.count > 0);
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
        cell.detailTextLabel.numberOfLines = 2;
    }
    
    if (indexPath.row < self.favoritesData.count) {
        NSDictionary *favorite = self.favoritesData[indexPath.row];
        
        // 设置图标
        if (@available(iOS 13.0, *)) {
            NSString *iconName = [favorite[@"isPrivate"] boolValue] ? @"lock.fill" : @"heart.fill";
            cell.imageView.image = [UIImage systemImageNamed:iconName];
            cell.imageView.tintColor = [favorite[@"isPrivate"] boolValue] ? [UIColor systemGrayColor] : [self accentColor];
        }
        
        // 设置标题
        cell.textLabel.text = favorite[@"title"] ?: @"收藏内容";
        
        // 设置详细信息
        NSString *author = favorite[@"author"] ?: @"作者";
        NSString *preview = favorite[@"preview"] ?: @"";
        NSString *category = favorite[@"category"] ?: @"";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@\n%@", author, category, preview];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.favoritesData.count) {
        NSDictionary *favorite = self.favoritesData[indexPath.row];
        [self showFavoriteDetail:favorite];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"这里显示你收藏的其他用户的内容";
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
    if (indexPath.row >= self.favoritesData.count) {
        return nil;
    }

    __weak typeof(self) weakSelf = self;
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                                title:@"取消收藏"
                                                                              handler:^(__unused UIContextualAction * _Nonnull action, __unused UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf confirmUnfavoriteAtIndexPath:indexPath completion:completionHandler];
    }];
    deleteAction.backgroundColor = [UIColor systemOrangeColor];

    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (void)showFavoriteDetail:(NSDictionary *)favorite {
    NSString *title = favorite[@"title"] ?: @"收藏内容";
    NSString *author = favorite[@"author"] ?: @"作者";
    NSString *category = favorite[@"category"] ?: @"";
    NSString *preview = favorite[@"preview"] ?: @"";
    BOOL isPrivate = [favorite[@"isPrivate"] boolValue];
    
    NSString *privacyStatus = isPrivate ? @"私密内容" : @"公开内容";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:[NSString stringWithFormat:@"作者：%@\n分类：%@\n状态：%@\n\n%@", 
                                                                            author, 
                                                                            category,
                                                                            privacyStatus,
                                                                            preview]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"查看内容"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        // 这里可以跳转到收藏的内容详情页面
        [self showMessage:@"跳转到内容详情页面" type:0];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消收藏"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self confirmUnfavoriteForFavorite:favorite];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmUnfavoriteAtIndexPath:(NSIndexPath *)indexPath completion:(void (^)(BOOL finished))completion {
    if (indexPath.row >= self.favoritesData.count) {
        if (completion) completion(NO);
        return;
    }
    
    NSDictionary *favorite = self.favoritesData[indexPath.row];
    [self showUnfavoriteConfirmAlertWithFavorite:favorite confirmHandler:^{
        // 在实际项目中，这里应该调用API取消收藏
        // 这里模拟取消收藏操作
        NSMutableArray *mutableData = [self.favoritesData mutableCopy];
        [mutableData removeObjectAtIndex:indexPath.row];
        self.favoritesData = [mutableData copy];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self updateEmptyState];
        
        [self showMessage:@"已取消收藏" type:0];
        if (completion) completion(YES);
    } cancelHandler:^{
        if (completion) completion(NO);
    }];
}

- (void)confirmUnfavoriteForFavorite:(NSDictionary *)favorite {
    [self showUnfavoriteConfirmAlertWithFavorite:favorite confirmHandler:^{
        // 在实际项目中，这里应该调用API取消收藏
        // 这里模拟取消收藏操作
        NSUInteger index = [self.favoritesData indexOfObject:favorite];
        if (index != NSNotFound) {
            NSMutableArray *mutableData = [self.favoritesData mutableCopy];
            [mutableData removeObjectAtIndex:index];
            self.favoritesData = [mutableData copy];
            
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] 
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [self updateEmptyState];
            
            [self showMessage:@"已取消收藏" type:0];
        }
    } cancelHandler:nil];
}

- (void)showUnfavoriteConfirmAlertWithFavorite:(NSDictionary *)favorite
                                confirmHandler:(dispatch_block_t)confirmHandler
                                 cancelHandler:(nullable dispatch_block_t)cancelHandler {
    NSString *title = @"确认取消收藏";
    NSString *message = [NSString stringWithFormat:@"确定取消收藏《%@》吗？", favorite[@"title"] ?: @"这条内容"];
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
    [alert addAction:[UIAlertAction actionWithTitle:@"取消收藏"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction * _Nonnull action) {
        if (confirmHandler) {
            confirmHandler();
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
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