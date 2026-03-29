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
#import <Masonry/Masonry.h>


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
            
            // 在实际项目中，这里应该使用SDWebImage等库加载图片
            // 这里使用占位图
            if (@available(iOS 13.0, *)) {
                imageView.image = [UIImage systemImageNamed:@"photo"];
                imageView.tintColor = [UIColor systemGray3Color];
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
    
    NSLog(@"📡 开始加载第 %ld 页数据", (long)self.currentPage);
    
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
                NSLog(@"✅ 成功加载 %lu 条内容", (unsigned long)contentList.count);
                
                if (self.currentPage == 1) {
                    [self.contentList removeAllObjects];
                }
                
                if (contentList.count > 0) {
                    // 将字典数组转换为模型数组
                    NSMutableArray *modelArray = [NSMutableArray array];
                    for (NSDictionary *dict in contentList) {
                        if ([dict isKindOfClass:[NSDictionary class]]) {
                            YALMyContentModel *model = [[YALMyContentModel alloc] initWithDictionary:dict];
                            [modelArray addObject:model];
                        }
                    }
                    
                    [self.contentList addObjectsFromArray:modelArray];
                    self.hasMoreData = contentList.count >= 10; // 如果返回的数量等于pageSize，认为还有更多数据
                    self.currentPage++;
                } else {
                    self.hasMoreData = NO;
                }
                
                [self updateEmptyState];
                [self.tableView reloadData];
                
                if (contentList.count == 0 && self.currentPage == 1) {
                    [self showMessage:@"暂无发布内容" type:0];
                }
            } else {
                NSLog(@"❌ 加载失败: %@, 错误: %@", message, error);
                [self showMessage:message ?: @"加载失败" type:1];
                
                if (self.contentList.count == 0) {
                    [self updateEmptyState];
                }
            }
        });
    }];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 滚动到底部时加载更多
    if (indexPath.row == self.contentList.count - 1 && self.hasMoreData && !self.isLoading) {
        [self loadData];
    }
}

#pragma mark - 内容详情

- (void)showContentDetail:(YALMyContentModel *)model {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:model.title
                                                                   message:[NSString stringWithFormat:@"%@\n\n地点：%@\n时间：%@\n心情：%@",
                                                                            model.content ?: @"",
                                                                            model.city ?: @"",
                                                                            model.year ?: @"",
                                                                            model.mood ?: @""]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"查看详情"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        // 这里可以跳转到内容详情页面
        [self showMessage:@"跳转到内容详情页面" type:0];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 工具方法

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
