//
//  YALLikesController.m
//  MemoryCity
//
//  Created by mac on 2026/4/1.
//

#import "YALLikesController.h"
#import <Masonry/Masonry.h>

@interface YALLikesController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *likesData;
@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation YALLikesController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupData];
}

- (void)setupUI {
    self.title = @"我的点赞";
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
    self.emptyLabel.text = @"还没有收到点赞\n快去发布内容与大家互动吧！";
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [UIColor secondaryLabelColor];
    self.emptyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.hidden = YES;
    self.tableView.backgroundView = self.emptyLabel;
}

- (void)setupData {
    // 模拟点赞数据
    self.likesData = @[
        @{
            @"userName": @"城市探索者",
            @"userAvatar": @"person.crop.circle.fill",
            @"contentTitle": @"武康路晚霞散步",
            @"contentPreview": @"上海 · 2小时前",
            @"time": @"刚刚"
        },
        @{
            @"userName": @"摄影爱好者",
            @"userAvatar": @"person.crop.circle.fill",
            @"contentTitle": @"老街早餐铺的热气",
            @"contentPreview": @"苏州 · 昨天",
            @"time": @"1小时前"
        },
        @{
            @"userName": @"骑行达人",
            @"userAvatar": @"person.crop.circle.fill",
            @"contentTitle": @"江边骑行的风",
            @"contentPreview": @"南京 · 3天前",
            @"time": @"3小时前"
        },
        @{
            @"userName": @"书店常客",
            @"userAvatar": @"person.crop.circle.fill",
            @"contentTitle": @"雨后的旧书店门口",
            @"contentPreview": @"杭州 · 待发布",
            @"time": @"昨天"
        }
    ];
    
    [self updateEmptyState];
    [self.tableView reloadData];
}

- (void)updateEmptyState {
    self.emptyLabel.hidden = (self.likesData.count > 0);
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
        cell.detailTextLabel.numberOfLines = 2;
    }
    
    if (indexPath.row < self.likesData.count) {
        NSDictionary *like = self.likesData[indexPath.row];
        
        // 设置头像
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:like[@"userAvatar"]];
            cell.imageView.tintColor = [self accentColor];
        }
        
        // 设置用户名和内容标题
        NSString *userName = like[@"userName"] ?: @"用户";
        NSString *contentTitle = like[@"contentTitle"] ?: @"内容";
        cell.textLabel.text = [NSString stringWithFormat:@"%@ 赞了你的《%@》", userName, contentTitle];
        
        // 设置详细信息和时间
        NSString *contentPreview = like[@"contentPreview"] ?: @"";
        NSString *time = like[@"time"] ?: @"";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@", contentPreview, time];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.likesData.count) {
        NSDictionary *like = self.likesData[indexPath.row];
        [self showLikeDetail:like];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"这里显示其他用户对你内容的点赞记录";
}

- (void)showLikeDetail:(NSDictionary *)like {
    NSString *userName = like[@"userName"] ?: @"用户";
    NSString *contentTitle = like[@"contentTitle"] ?: @"内容";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"点赞详情"
                                                                   message:[NSString stringWithFormat:@"%@ 赞了你的《%@》\n\n%@", 
                                                                            userName, 
                                                                            contentTitle,
                                                                            like[@"contentPreview"] ?: @""]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"查看内容"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        // 这里可以跳转到被点赞的内容详情页面
        [self showMessage:@"跳转到内容详情页面" type:0];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
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