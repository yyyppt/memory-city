#import "YALMemoryController.h"
#import "YALMemoryView.h"
#import "YALMemoryMonthModel.h"
#import "YALTimeLineController.h"
#import "YALTimelineManager.h"
#import <Masonry/Masonry.h>

static NSString *YALNormalizeDateKeyFromRaw(NSString * _Nullable raw) {
    if (![raw isKindOfClass:[NSString class]] || raw.length == 0) {
        return @"";
    }
    NSString *s = raw;
    // 兼容 "2024-03-30T12:00:00Z"
    if ([s containsString:@"T"] && s.length >= 10) {
        s = [s substringToIndex:10];
    } else if (s.length >= 10) {
        s = [s substringToIndex:10];
    }
    // 确保格式为 "yyyy.MM.dd"
    if ([s containsString:@"-"]) {
        s = [s stringByReplacingOccurrencesOfString:@"-" withString:@"."];
    }
    return s;
}

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

@property (nonatomic, copy) NSDictionary<NSString *, NSArray *> *timelineGrouped; // key=YYYY-MM value=list

@end

@implementation YALMemoryController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Memories";

    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.memoryView = [[YALMemoryView alloc] init];
    self.memoryView.delegate = self;
    [self.view addSubview:self.memoryView];
    [self.memoryView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self setupYearTable];

    [self refreshTimelineAndReloadUI];
}

/// 拉取“我的时间轴”并刷新 Memory 界面（MVC：Controller 只负责拉取/组装 Model，View 只负责展示）
- (void)refreshTimelineAndReloadUI {
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
    self.calendarYearNow = dc.year > 0 ? dc.year : 2026;

    __weak typeof(self) ws = self;
    [[YALTimelineManager sharedManager] fetchMyContentListWithCompletion:^(BOOL success, NSArray * _Nullable list, NSString * _Nullable message, NSError * _Nullable error) {
        __strong typeof(ws) ss = ws;
        if (!ss) return;

        if (!success || ![list isKindOfClass:[NSArray class]]) {
            // 失败时保持空态，但仍允许显示当前年份（不可点）
            ss.timelineGrouped = @{};
            ss.firstPublishYear = ss.calendarYearNow;
            ss.yearsWithContent = [NSSet set];
            [ss applyYearMetaToViewAndReload:ss.calendarYearNow];
            return;
        }

        NSMutableDictionary<NSString *, NSMutableArray *> *grouped = [NSMutableDictionary dictionary];
        for (id obj in list) {
            if (![obj isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *item = (NSDictionary *)obj;
            NSString *raw = nil;
            id yearObj = item[@"year"];
            if ([yearObj isKindOfClass:[NSString class]]) raw = (NSString *)yearObj;
            if (raw.length == 0) {
                id createObj = item[@"create_time"] ?: item[@"date"];
                if ([createObj isKindOfClass:[NSString class]]) raw = (NSString *)createObj;
            }
            NSString *dateKey = YALNormalizeDateKeyFromRaw(raw ?: @"");
            NSArray<NSString *> *parts = [dateKey componentsSeparatedByString:@"."];
            if (parts.count < 2) continue;
            NSInteger y = [parts[0] integerValue];
            NSInteger m = [parts[1] integerValue];
            if (y <= 0 || m <= 0) continue;
            NSString *ym = [NSString stringWithFormat:@"%04ld-%02ld", (long)y, (long)m];
            if (!grouped[ym]) grouped[ym] = [NSMutableArray array];
            [grouped[ym] addObject:item];
        }
        ss.timelineGrouped = [grouped copy];
        [ss rebuildYearMetadataFromGrouped:ss.timelineGrouped];
        NSInteger start = [ss defaultYearToShow];
        [ss applyYearMetaToViewAndReload:start];
    }];
}

- (void)rebuildYearMetadataFromGrouped:(NSDictionary<NSString *, NSArray *> *)grouped {
    NSMutableSet<NSNumber *> *years = [NSMutableSet set];
    __block NSInteger minYear = NSIntegerMax;
    [grouped enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray * _Nonnull obj, BOOL * _Nonnull stop) {
        (void)stop;
        if (![key isKindOfClass:[NSString class]]) return;
        if (![obj isKindOfClass:[NSArray class]] || obj.count == 0) return;
        // key: "2024-03"
        NSArray<NSString *> *parts = [key componentsSeparatedByString:@"-"];
        if (parts.count < 2) return;
        NSInteger y = [parts[0] integerValue];
        if (y <= 0) return;
        [years addObject:@(y)];
        minYear = MIN(minYear, y);
    }];
    self.yearsWithContent = [years copy];
    self.firstPublishYear = (minYear == NSIntegerMax) ? self.calendarYearNow : minYear;
}

- (void)applyYearMetaToViewAndReload:(NSInteger)yearToShow {
    self.memoryView.rangeFirstYear = self.firstPublishYear;
    self.memoryView.rangeLastYear = self.calendarYearNow;
    self.memoryView.yearsWithContent = self.yearsWithContent ?: [NSSet set];
    [self reloadYear:yearToShow];
}

- (NSInteger)defaultYearToShow {
    if ([self.yearsWithContent containsObject:@(self.calendarYearNow)]) {
        return self.calendarYearNow;
    }
    NSArray *sorted = [self sortedYearsWithContent];
    if (sorted.count == 0) {
        return self.calendarYearNow;
    }
    for (NSInteger i = (NSInteger)sorted.count - 1; i >= 0; i--) {
        NSInteger y = [sorted[i] integerValue];
        if (y <= self.calendarYearNow) {
            return y;
        }
    }
    return [sorted.firstObject integerValue];
}

- (NSArray<NSNumber *> *)sortedYearsWithContent {
    NSSet<NSNumber *> *set = self.yearsWithContent ?: [NSSet set];
    return [set.allObjects sortedArrayUsingSelector:@selector(compare:)];
}

- (NSInteger)clampToAvailableYear:(NSInteger)requested {
    NSSet<NSNumber *> *set = self.yearsWithContent ?: [NSSet set];
    if (set.count == 0) {
        // 没有任何内容时，允许停留在当前年份（但不可点/不可切换）
        return requested > 0 ? requested : self.calendarYearNow;
    }
    if ([set containsObject:@(requested)]) {
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
    self.yearTable.backgroundColor = [UIColor secondarySystemBackgroundColor];
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
        NSString *key = [NSString stringWithFormat:@"%ld-%02ld", (long)y, (long)m];
        NSArray *list = [self.timelineGrouped[key] isKindOfClass:[NSArray class]] ? self.timelineGrouped[key] : @[];
        model.memoryCount = (NSInteger)list.count;

        // featuredTitle/封面图：按 year(create_time/date兜底) 升序取“最前面那条”
        NSString *featured = @"FEATURED MOMENT";
        NSString *coverURL = nil;
        NSMutableArray<NSString *> *coverURLs = [NSMutableArray array];

        NSArray *sorted = list;
        if (list.count > 1) {
            sorted = [list sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                if (![obj1 isKindOfClass:[NSDictionary class]] || ![obj2 isKindOfClass:[NSDictionary class]]) {
                    return NSOrderedSame;
                }
                NSDictionary *d1 = (NSDictionary *)obj1;
                NSDictionary *d2 = (NSDictionary *)obj2;
                NSString *k1 = YALNormalizeDateKeyFromRaw(d1[@"year"] ?: d1[@"create_time"] ?: d1[@"date"]);
                NSString *k2 = YALNormalizeDateKeyFromRaw(d2[@"year"] ?: d2[@"create_time"] ?: d2[@"date"]);
                if (k1.length == 0 && k2.length == 0) return NSOrderedSame;
                if (k1.length == 0) return NSOrderedDescending;
                if (k2.length == 0) return NSOrderedAscending;
                return [k1 compare:k2];
            }];
        }

        id first = sorted.firstObject;
        if ([first isKindOfClass:[NSDictionary class]]) {
            NSDictionary *d = (NSDictionary *)first;

            // title/content 取一个作为 featuredTitle
            id t = d[@"title"];
            if (![t isKindOfClass:[NSString class]] || ((NSString *)t).length == 0) {
                t = d[@"content"];
            }
            if ([t isKindOfClass:[NSString class]] && ((NSString *)t).length > 0) {
                featured = (NSString *)t;
            }

            // images[0] 取封面图
            id imagesObj = d[@"images"];
            if ([imagesObj isKindOfClass:[NSArray class]]) {
                for (id imgObj in imagesObj) {
                    if ([imgObj isKindOfClass:[NSString class]] && ((NSString *)imgObj).length > 0) {
                        [coverURLs addObject:(NSString *)imgObj];
                    }
                }
                coverURL = coverURLs.firstObject;
            }
            if (!coverURL) {
                // 兼容单张字段
                id imageObj = d[@"image"];
                if ([imageObj isKindOfClass:[NSString class]] && ((NSString *)imageObj).length > 0) {
                    coverURL = (NSString *)imageObj;
                    [coverURLs addObject:coverURL];
                } else {
                    id imageURLObj = d[@"image_url"];
                    if ([imageURLObj isKindOfClass:[NSString class]] && ((NSString *)imageURLObj).length > 0) {
                        coverURL = (NSString *)imageURLObj;
                        [coverURLs addObject:coverURL];
                    }
                }
            }
        }

        model.featuredTitle = featured;

        model.coverImage = nil;
        model.coverImageURLString = coverURL;
        model.coverImageURLStrings = [coverURLs copy];
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
    CGFloat top = self.view.safeAreaInsets.top + 10 + 76;
    CGFloat maxH = self.view.bounds.size.height - top - 24;
    CGFloat h = MIN(maxH, (CGFloat)self.yearOptions.count * 44 + 8);

    [self.yearTable mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(tableW);
        make.top.equalTo(self.view.mas_top).offset(top);
        make.height.mas_equalTo(h);
    }];

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

    cell.backgroundColor = [UIColor secondarySystemBackgroundColor];

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
