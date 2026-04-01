//
//  YALTimeLineController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALTimeLineController.h"
#import "YALTimeLineDetailController.h"
#import "YALTimeLineDayCell.h"
#import "YALTimeLineEntryModel.h"
#import "YALReleaseController.h"
#import "YALTimelineManager.h"
#import <Masonry/Masonry.h>

@interface YALTimeLineController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<YALTimeLineEntryModel *> *entries;
@property (nonatomic, strong) UIView *emptyMonthContainer;

@end

@implementation YALTimeLineController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UIColor *highlightColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
    self.navigationController.navigationBar.tintColor = highlightColor;
    self.navigationItem.leftBarButtonItem.tintColor = highlightColor;

    if (@available(iOS 13.0, *)) {
        UIImage *back = [UIImage systemImageNamed:@"chevron.left"];
        self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithImage:back
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(backTapped)];
    }

    // 只保留“月份日列表”，避免出现你不想要的曲线/多月份回忆记线界面。
    BOOL validMonth = (self.displayYear > 0 && self.displayMonth >= 1 && self.displayMonth <= 12);
    if (!validMonth) {
        NSDateComponents *dc =
            [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth
                                              fromDate:[NSDate date]];
        self.displayYear = dc.year;
        self.displayMonth = dc.month;
    }

    self.title = [NSString stringWithFormat:@"%ld · %02ld", (long)self.displayYear, (long)self.displayMonth];
    self.entries = @[];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 108;
    self.tableView.contentInset = UIEdgeInsetsMake(8, 0, 24, 0);
    [self.tableView registerClass:[YALTimeLineDayCell class] forCellReuseIdentifier:@"YALTimeLineDayCell"];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    if (!self.emptyMonthContainer) {
        self.emptyMonthContainer = [[UIView alloc] init];
        self.emptyMonthContainer.backgroundColor = [UIColor clearColor];
        self.emptyMonthContainer.hidden = YES;
        [self.view addSubview:self.emptyMonthContainer];
        [self.emptyMonthContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];

        UILabel *label = [[UILabel alloc] init];
        label.text = @"还没有任何东西";
        label.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        label.textColor = [UIColor labelColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        [self.emptyMonthContainer addSubview:label];

        UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        if (@available(iOS 13.0, *)) {
            addBtn.backgroundColor = [UIColor systemOrangeColor];
        } else {
            addBtn.backgroundColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
        }
        [addBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [addBtn setTitle:@"添加" forState:UIControlStateNormal];
        addBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        addBtn.layer.cornerRadius = 12;
        [addBtn addTarget:self action:@selector(addTappedOnEmptyMonth) forControlEvents:UIControlEventTouchUpInside];
        [self.emptyMonthContainer addSubview:addBtn];

        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.emptyMonthContainer);
            make.centerY.equalTo(self.emptyMonthContainer).offset(-30);
            make.left.right.equalTo(self.emptyMonthContainer).inset(24);
        }];
        [addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(label.mas_bottom).offset(16);
            make.centerX.equalTo(self.emptyMonthContainer);
            make.width.mas_equalTo(140);
            make.height.mas_equalTo(44);
        }];
    }

    [self loadMonthEntriesFromAPI];
}

#pragma mark - Month list (daily cells)

- (NSString *)normalizedDateTextFromRaw:(NSString *)raw {
    if (raw.length == 0) return @"";
    NSString *s = raw;
    // 兼容 "2024-03-30T12:00:00Z"
    if ([s containsString:@"T"] && s.length >= 10) {
        s = [s substringToIndex:10];
    } else if (s.length >= 10) {
        s = [s substringToIndex:10];
    }
    // 分隔符统一为点
    s = [s stringByReplacingOccurrencesOfString:@"-" withString:@"."];
    NSArray<NSString *> *parts = [s componentsSeparatedByString:@"."];
    if (parts.count < 3) return s;
    NSInteger y = [parts[0] integerValue];
    NSInteger m = [parts[1] integerValue];
    NSInteger d = [parts[2] integerValue];
    if (y <= 0 || m <= 0 || d <= 0) return s;
    return [NSString stringWithFormat:@"%04ld.%02ld.%02ld", (long)y, (long)m, (long)d];
}

- (NSString *)subtitlePreviewFromContent:(NSString *)content {
    NSString *c = content ?: @"";
    if (c.length == 0) return @"";
    NSInteger maxLen = 28;
    if (c.length <= maxLen) return c;
    return [NSString stringWithFormat:@"%@...", [c substringToIndex:maxLen]];
}

- (void)addTappedOnEmptyMonth {
    // 默认取当月的 1 号发布
    NSString *dateText = [NSString stringWithFormat:@"%04ld.%02ld.%02ld",
                           (long)self.displayYear, (long)self.displayMonth, 1L];
    YALReleaseController *release = [[YALReleaseController alloc] initWithEditCoverImage:nil
                                                                                         title:nil
                                                                                      dateText:dateText
                                                                                          body:@""];
    release.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:release animated:YES];
}

- (NSInteger)daysInMonthForYear:(NSInteger)year month:(NSInteger)month {
    if (year <= 0 || month < 1 || month > 12) return 0;
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.year = year;
    c.month = month;
    c.day = 1;
    NSDate *d = [cal dateFromComponents:c];
    if (!d) return 0;
    NSRange r = [cal rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:d];
    return (NSInteger)r.length;
}

- (void)loadMonthEntriesFromAPI {
    NSInteger year = self.displayYear;
    NSInteger month = self.displayMonth;
    if (year <= 0 || month < 1 || month > 12) return;

    self.emptyMonthContainer.hidden = YES;

    __weak typeof(self) ws = self;
    [[YALTimelineManager sharedManager] fetchMyContentListWithCompletion:^(BOOL success, NSArray * _Nullable list, NSString * _Nullable message, NSError * _Nullable error) {
        __strong typeof(ws) ss = ws;
        if (!ss) return;

        if (!success || ![list isKindOfClass:[NSArray class]]) {
            NSLog(@"❌ 获取我的内容失败：%@ %@", message, error);
            ss.emptyMonthContainer.hidden = NO;
            ss.entries = @[];
            [ss.tableView reloadData];
            return;
        }

        NSMutableArray *rawList = [NSMutableArray array];
        for (id obj in list) {
            if (![obj isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *item = (NSDictionary *)obj;
            NSString *rawDate = nil;
            if ([item[@"year"] isKindOfClass:[NSString class]]) rawDate = item[@"year"];
            if (rawDate.length == 0 && [item[@"create_time"] isKindOfClass:[NSString class]]) rawDate = item[@"create_time"];
            if (rawDate.length == 0 && [item[@"date"] isKindOfClass:[NSString class]]) rawDate = item[@"date"];
            NSString *dateText = [ss normalizedDateTextFromRaw:(rawDate ?: @"")];
            NSArray *parts = [dateText componentsSeparatedByString:@"."];
            if (parts.count < 3) continue;
            NSInteger y = [parts[0] integerValue];
            NSInteger m = [parts[1] integerValue];
            if (y == year && m == month) {
                [rawList addObject:item];
            }
        }

        // 整个月没有内容：显示空态 + 添加按钮
        if (rawList.count == 0) {
            ss.entries = @[];
            ss.emptyMonthContainer.hidden = NO;
            [ss.tableView reloadData];
            return;
        }

        // 有内容：只展示有内容的天（不展示空天）
        NSMutableArray<YALTimeLineEntryModel *> *entries = [NSMutableArray array];
        NSInteger fallbackDay = 1;
        for (id obj in rawList) {
            if (![obj isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *item = (NSDictionary *)obj;

            NSString *title = @"";
            NSString *content = @"";
            NSMutableArray<NSString *> *imageURLs = [NSMutableArray array];

            id tObj = item[@"title"] ?: item[@"content_title"];
            if ([tObj isKindOfClass:[NSString class]]) title = (NSString *)tObj;
            id cObj = item[@"content"] ?: item[@"body"];
            if ([cObj isKindOfClass:[NSString class]]) content = (NSString *)cObj;

            NSString *rawDate = nil;
            if ([item[@"year"] isKindOfClass:[NSString class]]) rawDate = item[@"year"];
            if (rawDate.length == 0 && [item[@"create_time"] isKindOfClass:[NSString class]]) rawDate = item[@"create_time"];
            if (rawDate.length == 0 && [item[@"date"] isKindOfClass:[NSString class]]) rawDate = item[@"date"];
            NSString *dateText = [ss normalizedDateTextFromRaw:(rawDate ?: @"")];
            // 如果后端没返回我识别的日期字段，则用兜底日期保证 entry 不会被跳过
            if (dateText.length == 0) {
                NSInteger day = MAX(1, MIN(28, fallbackDay));
                dateText = [NSString stringWithFormat:@"%04ld.%02ld.%02ld",
                             (long)year, (long)month, (long)day];
                fallbackDay++;
            }

            id imagesObj = item[@"images"];
            if ([imagesObj isKindOfClass:[NSArray class]]) {
                for (id img in imagesObj) {
                    if ([img isKindOfClass:[NSString class]] && ((NSString *)img).length > 0) {
                        [imageURLs addObject:(NSString *)img];
                    }
                }
            } else if ([imagesObj isKindOfClass:[NSString class]] && ((NSString *)imagesObj).length > 0) {
                [imageURLs addObject:(NSString *)imagesObj];
            } else {
                id imageObj = item[@"image"] ?: item[@"image_url"];
                if ([imageObj isKindOfClass:[NSString class]] && ((NSString *)imageObj).length > 0) {
                    [imageURLs addObject:(NSString *)imageObj];
                }
            }

            NSString *preview = [ss subtitlePreviewFromContent:content];
            YALTimeLineEntryModel *filled =
                [[YALTimeLineEntryModel alloc] initWithTitle:(title.length > 0 ? title : @"无标题")
                                                    subtitle:preview
                                                        date:dateText
                                                     content:content
                                                  imageURLs:imageURLs];
            [entries addObject:filled];
        }

        // 按时间升序（最早的内容排前面）
        [entries sortUsingComparator:^NSComparisonResult(YALTimeLineEntryModel *a, YALTimeLineEntryModel *b) {
            return [a.dateText compare:b.dateText];
        }];

        ss.entries = [entries copy];
        ss.emptyMonthContainer.hidden = (ss.entries.count > 0);
        [ss.tableView reloadData];
    }];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YALTimeLineDayCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YALTimeLineDayCell" forIndexPath:indexPath];
    YALTimeLineEntryModel *entry = self.entries[indexPath.row];

    NSArray *parts = [entry.dateText componentsSeparatedByString:@"."];
    NSString *dayText = @"--";
    if (parts.count >= 3) {
        NSInteger day = [parts[2] integerValue];
        if (day > 0) {
            dayText = [NSString stringWithFormat:@"%02ld", (long)day];
        }
    }
    NSString *weekdayText = @"";
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy.MM.dd";
    NSDate *d = [df dateFromString:entry.dateText];
    if (d) {
        NSDateFormatter *wdf = [[NSDateFormatter alloc] init];
        wdf.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
        wdf.dateFormat = @"EEEE";
        weekdayText = [wdf stringFromDate:d];
    }
    [cell configureWithEntry:entry dayText:dayText weekdayText:weekdayText];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    YALTimeLineEntryModel *entry = self.entries[indexPath.row];

    YALTimeLineDetailController *detail = [[YALTimeLineDetailController alloc] init];
    detail.dateText = entry.dateText ?: @"";
    detail.titleText = entry.titleText ?: @"";
    detail.contentText = entry.contentText ?: @"";
    detail.coverImageURLString = (entry.imageURLStrings.count > 0) ? entry.imageURLStrings.firstObject : nil;
    detail.coverImage = entry.image;
    detail.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detail animated:YES];
}

#pragma mark - Actions

- (void)backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
