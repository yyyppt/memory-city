#import "YALTimeLineView.h"
#import "YALTimeLineCardView.h"

@interface YALTimeLineView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) CAShapeLayer *curveLayer;
@property (nonatomic, strong) NSMutableArray<UIButton *> *nodeButtons;
@property (nonatomic, strong) NSMutableArray<UILabel *> *nodeLabels;
@property (nonatomic, strong) NSMutableArray<YALTimeLineCardView *> *cardViews;

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
    }
    return self;
}

- (void)setSections:(NSArray<YALTimeLineSectionModel *> *)sections {
    _sections = sections;
    [self reloadData];
}

- (void)reloadData {
    for (UIView *v in _cardViews) { [v removeFromSuperview]; }
    for (UIView *v in _nodeButtons) { [v removeFromSuperview]; }
    for (UIView *v in _nodeLabels) { [v removeFromSuperview]; }
    [_cardViews removeAllObjects];
    [_nodeButtons removeAllObjects];
    [_nodeLabels removeAllObjects];

    NSInteger index = 0;
    for (YALTimeLineSectionModel *section in _sections) {
        UIButton *node = [UIButton buttonWithType:UIButtonTypeCustom];
        node.tag = index;
        node.backgroundColor = [UIColor systemOrangeColor];
        node.layer.cornerRadius = 4;
        node.layer.borderWidth = 2;
        node.layer.borderColor = [UIColor whiteColor].CGColor;
        [node addTarget:self action:@selector(nodeTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:node];
        [_nodeButtons addObject:node];

        UILabel *label = [[UILabel alloc] init];
        label.text = section.monthText;
        label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        label.textColor = [UIColor secondaryLabelColor];
        [_contentView addSubview:label];
        [_nodeLabels addObject:label];

        if (section.isExpanded) {
            for (YALTimeLineEntryModel *entry in section.entries) {
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
    CGFloat y = 20;
    CGFloat cardW = 200;
    CGFloat cardH = 140;
    NSInteger cardIndex = 0;
    NSMutableArray *points = [NSMutableArray array];

    for (int s = 0; s < (int)_sections.count; s++) {
        UIButton *node = _nodeButtons[s];
        UILabel *label = _nodeLabels[s];
        CGPoint center = CGPointMake(centerX, y);
        node.frame = CGRectMake(centerX - 4.5, y - 4.5, 9, 9);
        label.frame = CGRectMake(centerX + 10, y - 10, 100, 20);
        [points addObject:[NSValue valueWithCGPoint:center]];
        y += 40;

        YALTimeLineSectionModel *section = _sections[s];
        if (section.isExpanded) {
            for (int i = 0; i < (int)section.entries.count; i++) {
                BOOL right = i % 2 == 0;
                CGFloat x = right ? centerX + 20 : centerX - cardW - 20;
                YALTimeLineCardView *card = _cardViews[cardIndex];
                card.frame = CGRectMake(x, y, cardW, cardH);
                y += 100;
                cardIndex++;
            }
        } else {
            y += 80;
        }
    }

    _scrollView.contentSize = CGSizeMake(width, y + 40);
    _contentView.frame = CGRectMake(0, 0, width, y + 40);

    [self drawCurve:points];
}

- (void)drawCurve:(NSArray<NSValue *> *)points {
    if (points.count == 0) return;
    CGFloat centerX = self.bounds.size.width * 0.5;
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint first = [points[0] CGPointValue];
    [path moveToPoint:CGPointMake(centerX, first.y - 60)];
    CGPoint prev = CGPointMake(centerX, first.y - 60);
    int wave = 0;
    for (NSValue *v in points) {
        CGPoint p = [v CGPointValue];
        CGFloat dir = wave % 2 == 0 ? 1 : -1;
        CGPoint c = CGPointMake(centerX + dir * 80, (prev.y + p.y) / 2);
        [path addQuadCurveToPoint:p controlPoint:c];
        prev = p;
        wave++;
    }
    _curveLayer.path = path.CGPath;
}

- (void)nodeTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(timeLineView:didToggleSectionAtIndex:)]) {
        [self.delegate timeLineView:self didToggleSectionAtIndex:sender.tag];
    }
}

@end
