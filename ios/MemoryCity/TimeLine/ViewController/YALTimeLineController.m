//
//  YALTimeLineController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALTimeLineController.h"
#import "YALTimeLineView.h"
#import "YALTimeLineDetailController.h"

@interface YALTimeLineController () <YALTimeLineViewDelegate>

@property (nonatomic, strong) YALTimeLineView *timeLineView;
@property (nonatomic, strong) NSMutableArray<YALTimeLineSectionModel *> *sections;

@end

@implementation YALTimeLineController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"回忆记线";

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

    self.timeLineView = [[YALTimeLineView alloc] initWithFrame:self.view.bounds];
    self.timeLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.timeLineView.delegate = self;
    [self.view addSubview:self.timeLineView];

    self.sections = [[self buildDemoSections] mutableCopy];
    self.timeLineView.sections = self.sections;
}

#pragma mark - Demo Data

- (NSArray<YALTimeLineSectionModel *> *)buildDemoSections {
  NSMutableArray<YALTimeLineSectionModel *> *result = [NSMutableArray array];

  NSDate *now = [NSDate date];
  NSCalendar *cal = [NSCalendar currentCalendar];
  NSDateComponents *base = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:now];

  for (NSInteger i = 0; i < 6; i++) {
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.year = base.year;
    c.month = base.month - i;
    c.day = 1;
    NSDate *monthDate = [cal dateFromComponents:c] ?: now;

    NSDateFormatter *monthFmt = [[NSDateFormatter alloc] init];
    monthFmt.dateFormat = @"yyyy.MM";

    NSDateFormatter *dayFmt = [[NSDateFormatter alloc] init];
    dayFmt.dateFormat = @"yyyy.MM.dd";

    YALTimeLineSectionModel *section = [[YALTimeLineSectionModel alloc] init];
    section.monthText = [monthFmt stringFromDate:monthDate];
    section.expanded = (i == 0); // 默认展开最近一个月

    NSInteger count = 4 + (arc4random_uniform(2)); // 4~5 条，更接近设计
    NSMutableArray<YALTimeLineEntryModel *> *entries = [NSMutableArray array];
    for (NSInteger d = 0; d < count; d++) {
      NSDateComponents *dc = [[NSDateComponents alloc] init];
      dc.year = c.year;
      dc.month = c.month;
      dc.day = 3 + d * 5;
      NSDate *dayDate = [cal dateFromComponents:dc] ?: monthDate;

      YALTimeLineEntryModel *e = [[YALTimeLineEntryModel alloc] init];
      e.dateText = [dayFmt stringFromDate:dayDate];
      e.image = nil;
      // Demo 文本，更接近你给的英文 sample
      switch (d % 4) {
        case 0:
          e.titleText = @"Rainy Afternoon";
          e.subtitleText = @"Old street, soft drizzle";
          break;
        case 1:
          e.titleText = @"Grandma's Garden";
          e.subtitleText = @"Blooming memories";
          break;
        case 2:
          e.titleText = @"Summer Solstice";
          e.subtitleText = @"July 21 · Seaside";
          break;
        default:
          e.titleText = @"Autumn Leaves";
          e.subtitleText = @"Nov 05 · Theater Hill Park";
          break;
      }
      [entries addObject:e];
    }
    section.entries = entries;
    [result addObject:section];
  }
  return result;
}

#pragma mark - Actions

- (void)backTapped {
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - YALTimeLineViewDelegate

- (void)timeLineView:(YALTimeLineView *)view didToggleSectionAtIndex:(NSInteger)sectionIndex {
  if (sectionIndex < 0 || sectionIndex >= self.sections.count) { return; }

  YALTimeLineSectionModel *section = self.sections[sectionIndex];
  section.expanded = !section.isExpanded;

  // 更自然的展开/收起：带弹性的 cross-fade + layout 过渡
  view.sections = self.sections;
  [view reloadData];
}

- (void)timeLineView:(YALTimeLineView *)view didSelectEntry:(YALTimeLineEntryModel *)entry {
  (void)view;
  YALTimeLineDetailController *detail = [[YALTimeLineDetailController alloc] init];
  detail.dateText = entry.dateText ?: @"";
  detail.coverImage = entry.image;
  detail.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:detail animated:YES];
}

@end
