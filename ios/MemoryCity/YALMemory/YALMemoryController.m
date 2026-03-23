#import "YALMemoryController.h"
#import "YALMemoryView.h"
#import "YALMemoryMonthModel.h"
#import "YALTimeLineController.h"

@interface YALMemoryController () <YALMemoryViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) YALMemoryView *memoryView;
@property (nonatomic, assign) NSInteger currentYear;

@property (nonatomic, assign) NSInteger firstPublishYear;
@property (nonatomic, assign) NSInteger calendarYearNow;
@property (nonatomic, copy) NSSet<NSNumber *> *yearsWithContent;

@property (nonatomic, strong) NSArray<YALMemoryMonthModel *> *months;
@property (nonatomic, strong) UITableView *yearTable;
@property (nonatomic, strong) NSArray<NSNumber *> *yearOptions;
@property (nonatomic, assign) BOOL yearPickerVisible;

@end

@implementation YALMemoryController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Memories";

    [self buildYearMetadataDemo];

    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.memoryView = [[YALMemoryView alloc] initWithFrame:self.view.bounds];
    self.memoryView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.memoryView.delegate = self;
    self.memoryView.rangeFirstYear = self.firstPublishYear;
    self.memoryView.rangeLastYear = self.calendarYearNow;
    self.memoryView.yearsWithContent = self.yearsWithContent;
    [self.view addSubview:self.memoryView];

    [self setupYearTable];

    NSInteger start = [self defaultYearToShow];
    [self reloadYear:start];
}

/// Demo：最早有发布年 ～ 今年；无发布的年份不可点（示例：2024 无内容）
- (void)buildYearMetadataDemo {
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
    self.calendarYearNow = dc.year > 0 ? dc.year : 2026;
    self.firstPublishYear = 2022;

    NSMutableSet *set = [NSMutableSet set];
    for (NSInteger y = self.firstPublishYear; y <= self.calendarYearNow; y++) {
        if (y == 2024) {
            continue;
        }
        [set addObject:@(y)];
    }
    self.yearsWithContent = [set copy];
}

- (NSInteger)defaultYearToShow {
    if ([self.yearsWithContent containsObject:@(self.calendarYearNow)]) {
        return self.calendarYearNow;
    }
    NSArray *sorted = [self sortedYearsWithContent];
    for (NSInteger i = (NSInteger)sorted.count - 1; i >= 0; i--) {
        NSInteger y = [sorted[i] integerValue];
        if (y <= self.calendarYearNow) {
            return y;
        }
    }
    return [sorted.firstObject integerValue];
}

- (NSArray<NSNumber *> *)sortedYearsWithContent {
    return [self.yearsWithContent.allObjects sortedArrayUsingSelector:@selector(compare:)];
}

- (NSInteger)clampToAvailableYear:(NSInteger)requested {
    if ([self.yearsWithContent containsObject:@(requested)]) {
        return requested;
    }
    NSArray *sorted = [self sortedYearsWithContent];
    for (NSInteger i = (NSInteger)sorted.count - 1; i >= 0; i--) {
        NSInteger y = [sorted[i] integerValue];
        if (y <= requested) {
            return y;
        }
    }
    return [sorted.firstObject integerValue];
}

- (void)setupYearTable {
    self.yearTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    if (@available(iOS 13.0, *)) {
        self.yearTable.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
            return trait.userInterfaceStyle == UIUserInterfaceStyleDark
                ? [UIColor secondarySystemBackgroundColor]
                : [UIColor whiteColor];
        }];
    } else {
        self.yearTable.backgroundColor = [UIColor whiteColor];
    }
    self.yearTable.layer.cornerRadius = 12;
    self.yearTable.clipsToBounds = YES;
    self.yearTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.yearTable.separatorInset = UIEdgeInsetsZero;
    if (@available(iOS 13.0, *)) {
        self.yearTable.separatorColor = [UIColor separatorColor];
    }
    self.yearTable.dataSource = self;
    self.yearTable.delegate = self;
    self.yearTable.rowHeight = 44;
    self.yearTable.alpha = 0.0;
    self.yearTable.scrollEnabled = YES;
    self.yearTable.showsVerticalScrollIndicator = YES;
    [self.view addSubview:self.yearTable];
}

- (void)reloadYear:(NSInteger)year {
    NSInteger y = [self clampToAvailableYear:year];
    self.currentYear = y;

    self.memoryView.rangeFirstYear = self.firstPublishYear;
    self.memoryView.rangeLastYear = self.calendarYearNow;
    self.memoryView.yearsWithContent = self.yearsWithContent;
    self.memoryView.year = y;

    NSMutableArray *arr = [NSMutableArray array];
    for (NSInteger m = 1; m <= 12; m++) {
        YALMemoryMonthModel *model = [[YALMemoryMonthModel alloc] init];
        model.year = y;
        model.month = m;
        model.memoryCount = 6 + (arc4random_uniform(10));
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
    NSArray *sorted = [self sortedYearsWithContent];
    NSInteger idx = [sorted indexOfObject:@(self.currentYear)];
    if (idx == NSNotFound || idx <= 0) {
        return;
    }
    [self reloadYear:[sorted[(NSUInteger)(idx - 1)] integerValue]];
}

- (void)memoryViewDidTapNextYear:(YALMemoryView *)view {
    (void)view;
    NSArray *sorted = [self sortedYearsWithContent];
    NSInteger idx = [sorted indexOfObject:@(self.currentYear)];
    if (idx == NSNotFound || idx >= (NSInteger)sorted.count - 1) {
        return;
    }
    [self reloadYear:[sorted[(NSUInteger)(idx + 1)] integerValue]];
}

- (void)memoryView:(YALMemoryView *)view didSelectMonth:(YALMemoryMonthModel *)month {
    (void)view;

    YALTimeLineController *vc = [[YALTimeLineController alloc] init];
    vc.displayYear = month.year;
    vc.displayMonth = month.month;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)memoryViewDidTapYear:(YALMemoryView *)view {
    (void)view;
    if (![self.yearsWithContent containsObject:@(self.currentYear)]) {
        return;
    }

    NSMutableArray *years = [NSMutableArray array];
    for (NSInteger y = self.firstPublishYear; y <= self.calendarYearNow; y++) {
        [years addObject:@(y)];
    }
    self.yearOptions = years;
    [self.yearTable reloadData];

    CGFloat w = self.view.bounds.size.width;
    CGFloat tableW = MIN(200, w - 48);
    CGFloat x = (w - tableW) / 2.0;
    CGFloat top = self.view.safeAreaInsets.top + 10 + 76;
    CGFloat maxH = self.view.bounds.size.height - top - 24;
    CGFloat h = MIN(maxH, (CGFloat)self.yearOptions.count * 44 + 8);

    self.yearTable.frame = CGRectMake(x, top, tableW, h);

    self.yearPickerVisible = !self.yearPickerVisible;
    [UIView animateWithDuration:0.25 animations:^{
        self.yearTable.alpha = self.yearPickerVisible ? 1.0 : 0.0;
    }];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.yearOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"yearCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSInteger year = [self.yearOptions[indexPath.row] integerValue];
    BOOL has = [self.yearsWithContent containsObject:@(year)];

    cell.textLabel.text = [NSString stringWithFormat:@"%ld", (long)year];
    cell.userInteractionEnabled = has;

    if (self.view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        cell.backgroundColor = [UIColor secondarySystemBackgroundColor];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }

    UIColor *accent = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
    if (has) {
        cell.textLabel.textColor = (year == self.currentYear) ? accent : [UIColor labelColor];
    } else {
        cell.textLabel.textColor = [UIColor tertiaryLabelColor];
    }

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSInteger year = [self.yearOptions[indexPath.row] integerValue];
    if (![self.yearsWithContent containsObject:@(year)]) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSInteger year = [self.yearOptions[indexPath.row] integerValue];
    if (![self.yearsWithContent containsObject:@(year)]) {
        return;
    }
    [self reloadYear:year];
    self.yearPickerVisible = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.yearTable.alpha = 0.0;
    }];
}

@end
