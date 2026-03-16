//
//  YALSearchController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALSearchController.h"

@interface YALSearchController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *results;

@end

@implementation YALSearchController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];


    CGFloat titleWidth = self.view.bounds.size.width - 120.0;
    UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, titleWidth, 40.0)];
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 4, titleWidth, 32.0)];
    searchBar.placeholder = @"搜索记忆内容...";
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.delegate = self;

    UIColor *highlightColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
    self.navigationController.navigationBar.tintColor = highlightColor;

    if (@available(iOS 13.0, *)) {
        UITextField *searchField = searchBar.searchTextField;
        searchField.layer.cornerRadius = 16.0;
        searchField.layer.masksToBounds = YES;
        searchField.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.05];
        searchField.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightLight];
        searchField.borderStyle = UITextBorderStyleNone;
        searchField.tintColor = highlightColor;

        // 统一放大镜图标样式（颜色 + 粗细），与首页一致
        UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration configurationWithPointSize:14
                                                        weight:UIImageSymbolWeightRegular];
        UIImage *searchIcon = [UIImage systemImageNamed:@"magnifyingglass"
                                      withConfiguration:config];
        [searchBar setImage:searchIcon
           forSearchBarIcon:UISearchBarIconSearch
                      state:UIControlStateNormal];
        searchField.leftView.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    }

    [searchBar setPositionAdjustment:UIOffsetMake(10, 0) forSearchBarIcon:UISearchBarIconSearch];
    [titleContainer addSubview:searchBar];
    self.navigationItem.titleView = titleContainer;

    // 左上角自定义返回按钮（替代系统长返回）
    if (@available(iOS 13.0, *)) {
        UIImage *backIcon = [UIImage systemImageNamed:@"chevron.left"];
        UIBarButtonItem *backItem =
        [[UIBarButtonItem alloc] initWithImage:backIcon
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(backTapped)];
        self.navigationItem.leftBarButtonItem = backItem;
    }

    // 右上角“搜索”按钮
    UIBarButtonItem *searchItem =
    [[UIBarButtonItem alloc] initWithTitle:@"搜索"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(triggerSearch)];
    searchItem.tintColor = highlightColor;
    self.navigationItem.rightBarButtonItem = searchItem;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    self.results = @[]; // 初始为空，输入后刷新
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 进入搜索页时强制隐藏底部 TabBar
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 离开搜索页时还原 TabBar 显示
    self.tabBarController.tabBar.hidden = NO;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *keyword = searchBar.text ?: @"";
    [searchBar resignFirstResponder];

    // 这里先做一个简单示例：用关键字生成几条假数据
    if (keyword.length == 0) {
        self.results = @[];
    } else {
        self.results = @[
            [NSString stringWithFormat:@"与「%@」相关的记忆 1", keyword],
            [NSString stringWithFormat:@"与「%@」相关的记忆 2", keyword],
            [NSString stringWithFormat:@"与「%@」相关的记忆 3", keyword],
        ];
    }
    [self.tableView reloadData];
}

- (void)triggerSearch {
    UISearchBar *searchBar = (UISearchBar *)self.navigationItem.titleView.subviews.firstObject;
    if ([searchBar isKindOfClass:[UISearchBar class]]) {
        [self searchBarSearchButtonClicked:searchBar];
    }
}

- (void)backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"SearchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    cell.textLabel.text = self.results[indexPath.row];
    cell.detailTextLabel.text = @"搜索结果示例，后续可跳转到详情页";
    return cell;
}

@end

