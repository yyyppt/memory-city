#import "YALTimeLineView.h"
#import "YALTimeLineCardView.h"

@interface YALTimeLineView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) CAShapeLayer *curveLayer;
@property (nonatomic, strong) NSMutableArray<UIButton *> *nodeButtons;
@property (nonatomic, strong) NSMutableArray<UILabel *> *nodeLabels;
@property (nonatomic, strong) NSMutableArray<YALTimeLineCardView *> *cardViews;
@property (nonatomic, strong) NSMutableArray<UIView *> *entryDots;

@end

@implementation YALTimeLineView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemGroupedBackgroundColor];

        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_scrollView];

        _contentView = [[UIView alloc] initWithFrame:self.bounds];
        [_scrollView addSubview:_contentView];

        _curveLayer = [CAShapeLayer layer];
        _curveLayer.fillColor = [UIColor clearColor].CGColor;
        _curveLayer.lineWidth = 1.6;
        _curveLayer.strokeColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
        [_contentView.layer addSublayer:_curveLayer];

        _nodeButtons = [NSMutableArray array];
        _nodeLabels = [NSMutableArray array];
        _cardViews = [NSMutableArray array];
        _entryDots = [NSMutableArray array];
    }
    return self;
}

- (void)setSections:(NSArray<YALTimeLineSectionModel *> *)sections {
    _sections = sections;
    [self reloadData];
}

- (void)reloadData {
    for (UIView *v in _cardViews)   { [v removeFromSuperview]; }
    for (UIView *v in _nodeButtons) { [v removeFromSuperview]; }
    for (UIView *v in _nodeLabels)  { [v removeFromSuperview]; }
    for (UIView *v in _entryDots)   { [v removeFromSuperview]; }
    [_cardViews removeAllObjects];
    [_nodeButtons removeAllObjects];
    [_nodeLabels removeAllObjects];
    [_entryDots removeAllObjects];

    NSInteger index = 0;
    for (YALTimeLineSectionModel *section in _sections) {
        UIButton *node = [UIButton buttonWithType:UIButtonTypeCustom];
        node.tag = index;
        node.backgroundColor = [UIColor systemOrangeColor];
        node.layer.cornerRadius = 5;
        node.layer.borderWidth = 2.5;
        node.layer.borderColor = [UIColor whiteColor].CGColor;
        [node addTarget:self action:@selector(nodeTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:node];
        [_nodeButtons addObject:node];

        UILabel *label = [[UILabel alloc] init];
        label.text = section.monthText;
        label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        label.textColor = [UIColor secondaryLabelColor];
        [_contentView addSubview:label];
        [_nodeLabels addObject:label];

        if (section.isExpanded) {
            for (YALTimeLineEntryModel *entry in section.entries) {
                UIView *dot = [[UIView alloc] init];
                dot.backgroundColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:0.7];
                dot.layer.cornerRadius = 3.5;
                [_contentView addSubview:dot];
                [_entryDots addObject:dot];

                YALTimeLineCardView *card = [[YALTimeLineCardView alloc] init];
                card.entry = entry;
                __weak typeof(self) weakSelf = self;
                card.tapAction = ^(YALTimeLineEntryModel *entryModel) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if ([strongSelf.delegate respondsToSelector:@selector(timeLineView:didSelectEntry:)]) {
                        [strongSelf.delegate timeLineView:strongSelf didSelectEntry:entryModel];
                    }
                };
                [_contentView addSubview:card];
                [_cardViews addObject:card];
            }
        }
        index++;
    }
    [self setNeedsLayout];
}

- (void)reloadDataAnimated:(BOOL)animated {
    if (!animated) {
        [self reloadData];
        return;
    }
    [UIView animateWithDuration:0.3 animations:^{
        [self reloadData];
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = self.bounds.size.width;
    CGFloat centerX = width * 0.5;
    CGFloat y = 30;
    CGFloat cardW = width * 0.52;
    NSInteger cardIndex = 0;
    NSInteger dotIndex  = 0;
    NSMutableArray *points = [NSMutableArray array];

    for (int s = 0; s < (int)_sections.count; s++) {
        UIButton *node = _nodeButtons[s];
        UILabel  *label = _nodeLabels[s];

        node.frame = CGRectMake(centerX - 5, y - 5, 10, 10);
        [label sizeToFit];
        label.frame = CGRectMake(centerX + 14, y - 9, label.bounds.size.width + 4, 18);
        [points addObject:[NSValue valueWithCGPoint:CGPointMake(centerX, y)]];
        y += 36;

        YALTimeLineSectionModel *section = _sections[s];
        if (section.isExpanded) {
            for (int i = 0; i < (int)section.entries.count; i++) {
                if (cardIndex >= (int)_cardViews.count) break;

                BOOL right = (i % 2 == 0);
                YALTimeLineEntryModel *entry = section.entries[i];
                CGFloat cardH = [YALTimeLineCardView cardHeightForEntry:entry width:cardW];
                CGFloat x = right ? (centerX + 20) : (centerX - cardW - 20);

                YALTimeLineCardView *card = _cardViews[cardIndex];
                card.frame = CGRectMake(x, y, cardW, cardH);

                CGFloat midY = y + cardH * 0.5;
                [points addObject:[NSValue valueWithCGPoint:CGPointMake(centerX, midY)]];

                if (dotIndex < (int)_entryDots.count) {
                    UIView *dot = _entryDots[dotIndex];
                    dot.frame = CGRectMake(centerX - 3.5, midY - 3.5, 7, 7);
                    dotIndex++;
                }

                y += cardH + 16;
                cardIndex++;
            }
        } else {
            y += 70;
        }
    }

    _scrollView.contentSize = CGSizeMake(width, y + 50);
    _contentView.frame = CGRectMake(0, 0, width, y + 50);

    [self drawCurve:points totalHeight:y + 50];
}

- (void)drawCurve:(NSArray<NSValue *> *)points totalHeight:(CGFloat)totalHeight {
    if (points.count == 0) return;
    CGFloat centerX = self.bounds.size.width * 0.5;
    UIBezierPath *path = [UIBezierPath bezierPath];

    CGPoint first = [points[0] CGPointValue];
    CGPoint start = CGPointMake(centerX, first.y - 40);
    [path moveToPoint:start];
    CGPoint prev = start;

    for (NSInteger i = 0; i < (NSInteger)points.count; i++) {
        CGPoint p = [points[i] CGPointValue];
        CGFloat dir = (i % 2 == 0) ? 1.0 : -1.0;
        CGFloat amp = 45;
        CGPoint c = CGPointMake(centerX + dir * amp, (prev.y + p.y) / 2.0);
        [path addQuadCurveToPoint:p controlPoint:c];
        prev = p;
    }

    [path addLineToPoint:CGPointMake(centerX, totalHeight)];
    _curveLayer.path = path.CGPath;
}

- (void)nodeTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(timeLineView:didToggleSectionAtIndex:)]) {
        [self.delegate timeLineView:self didToggleSectionAtIndex:sender.tag];
    }
}

@end
