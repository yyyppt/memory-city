//
//  YALTimeLineController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALTimeLineController.h"
#import "YALTimeLineDetailController.h"
#import "YALTimeLineDayCell.h"

@interface YALTimeLineController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *dayTableView;
@property (nonatomic, strong) NSArray<YALTimeLineEntryModel *> *monthDayEntries;

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
    self.monthDayEntries = [self buildSortedMonthEntries];

    self.dayTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.dayTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.dayTableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.dayTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.dayTableView.dataSource = self;
    self.dayTableView.delegate = self;
    // `YALTimeLineDayCell` 目前是基于固定布局的 frame 模式，不依赖 Auto Layout，自定义高度由 rowHeight 控制。
    self.dayTableView.rowHeight = 108;
    self.dayTableView.contentInset = UIEdgeInsetsMake(8, 0, 24, 0);
    [self.dayTableView registerClass:[YALTimeLineDayCell class] forCellReuseIdentifier:@"YALTimeLineDayCell"];
    [self.view addSubview:self.dayTableView];
}

#pragma mark - Month list (daily cells)

- (NSArray<YALTimeLineEntryModel *> *)buildSortedMonthEntries {
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.year = self.displayYear;
    c.month = self.displayMonth;
    c.day = 1;
    NSDate *monthDate = [cal dateFromComponents:c] ?: now;

    NSDateFormatter *dayFmt = [[NSDateFormatter alloc] init];
    dayFmt.dateFormat = @"yyyy.MM.dd";

    NSMutableArray<YALTimeLineEntryModel *> *entries = [NSMutableArray array];
    NSMutableSet<NSNumber *> *usedDays = [NSMutableSet set];

    NSInteger count = 10;
    for (NSInteger i = 0; i < count; i++) {
        NSInteger day = 1 + (NSInteger)(arc4random_uniform(27));
        if ([usedDays containsObject:@(day)]) {
            i--;
            continue;
        }
        [usedDays addObject:@(day)];

        NSDateComponents *dc = [[NSDateComponents alloc] init];
        dc.year = self.displayYear;
        dc.month = self.displayMonth;
        dc.day = day;
        NSDate *dayDate = [cal dateFromComponents:dc] ?: monthDate;

        YALTimeLineEntryModel *e = [[YALTimeLineEntryModel alloc] init];
        e.dateText = [dayFmt stringFromDate:dayDate];
        e.image = [UIImage imageNamed:@"WechatIMG395 1.jpg"];
        e.titleText = @"今日记忆";
        NSInteger cnt = 1 + (arc4random_uniform(5));
        e.subtitleText = [NSString stringWithFormat:@"这天有 %ld 个记点 · 点击查看", (long)cnt];
        [entries addObject:e];
    }

    [entries sortUsingComparator:^NSComparisonResult(YALTimeLineEntryModel *a, YALTimeLineEntryModel *b) {
        return [a.dateText compare:b.dateText];
    }];
    return entries;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.monthDayEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YALTimeLineDayCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YALTimeLineDayCell" forIndexPath:indexPath];
    YALTimeLineEntryModel *entry = self.monthDayEntries[indexPath.row];

    NSArray *parts = [entry.dateText componentsSeparatedByString:@"."];
    NSString *dayText = parts.count >= 3 ? parts[2] : @"--";
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
    YALTimeLineEntryModel *entry = self.monthDayEntries[indexPath.row];
    YALTimeLineDetailController *detail = [[YALTimeLineDetailController alloc] init];
    detail.dateText = entry.dateText ?: @"";
    detail.coverImage = entry.image ?: [UIImage imageNamed:@"WechatIMG395 1.jpg"];
    detail.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detail animated:YES];
}

#pragma mark - Actions

- (void)backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
