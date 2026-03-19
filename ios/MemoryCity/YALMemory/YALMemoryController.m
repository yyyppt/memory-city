#import "YALMemoryController.h"
#import "YALMemoryView.h"
#import "YALMemoryMonthModel.h"
#import "YALTimeLineController.h"

@interface YALMemoryController () <YALMemoryViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) YALMemoryView *memoryView;
@property (nonatomic, assign) NSInteger currentYear;
@property (nonatomic, strong) NSArray<YALMemoryMonthModel *> *months;
@property (nonatomic, strong) UITableView *yearTable;
@property (nonatomic, strong) NSArray<NSNumber *> *yearOptions;
@property (nonatomic, assign) BOOL yearPickerVisible;

@end

@implementation YALMemoryController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Memories";

    NSDateComponents *c = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
    self.currentYear = c.year > 0 ? c.year : 2024;

    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.memoryView = [[YALMemoryView alloc] initWithFrame:self.view.bounds];
    self.memoryView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.memoryView.delegate = self;
    [self.view addSubview:self.memoryView];

    [self setupYearTable];

    [self reloadYear:self.currentYear];
}

- (void)setupYearTable {
    self.yearTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.yearTable.backgroundColor = [UIColor clearColor];
    self.yearTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.yearTable.dataSource = self;
    self.yearTable.delegate = self;
    self.yearTable.rowHeight = 40;
    self.yearTable.alpha = 0.0;
    self.yearTable.clipsToBounds = YES;
    [self.view addSubview:self.yearTable];
}

- (void)reloadYear:(NSInteger)year {
    self.currentYear = year;
    self.memoryView.year = year;

    NSMutableArray *arr = [NSMutableArray array];
    for (NSInteger m = 1; m <= 12; m++) {
        YALMemoryMonthModel *model = [[YALMemoryMonthModel alloc] init];
        model.year = year;
        model.month = m;
        model.memoryCount = 6 + (arc4random_uniform(10)); // demo
        model.featuredTitle = @"FEATURED MOMENT\nSummer Golden Hour at the Coast";
        model.coverImage = [UIImage imageNamed:@"WechatIMG395 1.jpg"];
        [arr addObject:model];
    }
    self.months = arr;
    self.memoryView.months = self.months;
}

#pragma mark - YALMemoryViewDelegate

- (void)memoryViewDidTapPrevYear:(YALMemoryView *)view {
    (void)view;
    [self reloadYear:self.currentYear - 1];
}

- (void)memoryViewDidTapNextYear:(YALMemoryView *)view {
    (void)view;
    [self reloadYear:self.currentYear + 1];
}

- (void)memoryView:(YALMemoryView *)view didSelectMonth:(YALMemoryMonthModel *)month {
    (void)view;

    YALTimeLineController *vc = [[YALTimeLineController alloc] init];
    if ([vc respondsToSelector:@selector(setDisplayYear:)]) {
        [vc setValue:@(month.year) forKey:@"displayYear"];
    }
    if ([vc respondsToSelector:@selector(setDisplayMonth:)]) {
        [vc setValue:@(month.month) forKey:@"displayMonth"];
    }
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)memoryViewDidTapYear:(YALMemoryView *)view {
    (void)view;
    NSInteger base = self.currentYear;
    NSMutableArray *years = [NSMutableArray array];
    for (NSInteger i = -4; i <= 4; i++) {
        [years addObject:@(base + i)];
    }
    self.yearOptions = years;
    [self.yearTable reloadData];

    CGFloat w = self.view.bounds.size.width;
    CGFloat tableW = 140;
    CGFloat x = (w - tableW) / 2.0;
    CGFloat y = self.view.safeAreaInsets.top + 100;
    CGFloat h = MIN(9 * 40, self.view.bounds.size.height - y - 40);
    self.yearTable.frame = CGRectMake(x, y, tableW, h);

    self.yearPickerVisible = !self.yearPickerVisible;
    [UIView animateWithDuration:0.25 animations:^{
        self.yearTable.alpha = self.yearPickerVisible ? 1.0 : 0.0;
    }];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)section;
    return self.yearOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"yearCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    NSInteger year = [self.yearOptions[indexPath.row] integerValue];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld", (long)year];
    cell.textLabel.textColor = (year == self.currentYear) ? [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1] : [UIColor labelColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSInteger year = [self.yearOptions[indexPath.row] integerValue];
    [self reloadYear:year];
    self.yearPickerVisible = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.yearTable.alpha = 0.0;
    }];
}

@end

