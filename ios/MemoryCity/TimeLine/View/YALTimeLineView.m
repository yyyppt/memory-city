#import "YALTimeLineView.h"
#import "YALTimeLineCardView.h"
#import <Masonry/Masonry.h>

static const CGFloat kCurveX        = 36.0;
static const CGFloat kCardLeft      = 62.0;
static const CGFloat kCardRight     = 16.0;
static const CGFloat kTopPadding    = 28.0;
static const CGFloat kCardGap       = 14.0;
static const CGFloat kSectionToCard = 20.0;
static const CGFloat kCollapsedGap  = 44.0;
static const CGFloat kBottomPad     = 50.0;

@interface YALTimeLineView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) CAShapeLayer *curveLayer;
@property (nonatomic, strong) CAShapeLayer *connectorLayer;
@property (nonatomic, strong) NSMutableArray<UIButton *> *nodeButtons;
@property (nonatomic, strong) NSMutableArray<UILabel *> *nodeLabels;
@property (nonatomic, strong) NSMutableArray<YALTimeLineCardView *> *cardViews;
@property (nonatomic, strong) NSMutableArray<UIView *> *entryDots;

@end

@implementation YALTimeLineView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor systemGroupedBackgroundColor];

        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.alwaysBounceVertical = YES;
        [self addSubview:_scrollView];
        [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        _contentView = [[UIView alloc] init];
        [_scrollView addSubview:_contentView];

        _curveLayer = [CAShapeLayer layer];
        _curveLayer.fillColor   = [UIColor clearColor].CGColor;
        _curveLayer.lineWidth   = 2.0;
        _curveLayer.strokeColor = [UIColor colorWithWhite:0.80 alpha:1].CGColor;
        _curveLayer.lineCap     = kCALineCapRound;
        [_contentView.layer addSublayer:_curveLayer];

        _connectorLayer = [CAShapeLayer layer];
        _connectorLayer.fillColor   = [UIColor clearColor].CGColor;
        _connectorLayer.lineWidth   = 1.0;
        _connectorLayer.strokeColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:0.35].CGColor;
        _connectorLayer.lineDashPattern = @[@4, @3];
        [_contentView.layer addSublayer:_connectorLayer];

        _nodeButtons = [NSMutableArray array];
        _nodeLabels  = [NSMutableArray array];
        _cardViews   = [NSMutableArray array];
        _entryDots   = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Data

- (void)setSections:(NSArray<YALTimeLineSectionModel *> *)sections {
    _sections = sections;
    [self reloadData];
}

- (void)reloadData {
    for (UIView *v in _cardViews)   [v removeFromSuperview];
    for (UIView *v in _nodeButtons) [v removeFromSuperview];
    for (UIView *v in _nodeLabels)  [v removeFromSuperview];
    for (UIView *v in _entryDots)   [v removeFromSuperview];
    [_cardViews   removeAllObjects];
    [_nodeButtons removeAllObjects];
    [_nodeLabels  removeAllObjects];
    [_entryDots   removeAllObjects];

    NSInteger idx = 0;
    for (YALTimeLineSectionModel *section in _sections) {
        UIButton *node = [UIButton buttonWithType:UIButtonTypeCustom];
        node.tag = idx;
        node.layer.cornerRadius = 6;
        node.layer.borderWidth  = 2.5;
        if (section.isExpanded) {
            node.backgroundColor    = [UIColor systemOrangeColor];
            node.layer.borderColor  = [UIColor whiteColor].CGColor;
        } else {
            node.backgroundColor    = [UIColor systemGroupedBackgroundColor];
            node.layer.borderColor  = [UIColor systemOrangeColor].CGColor;
        }
        [node addTarget:self action:@selector(nodeTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:node];
        [_nodeButtons addObject:node];

        NSString *labelText = section.monthText;
        if (!section.isExpanded) {
            labelText = [NSString stringWithFormat:@"%@  ·  %ld条记忆",
                         section.monthText, (long)section.entries.count];
        }
        UILabel *label = [[UILabel alloc] init];
        label.text      = labelText;
        label.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        label.textColor = section.isExpanded
            ? [UIColor labelColor]
            : [UIColor secondaryLabelColor];
        [_contentView addSubview:label];
        [_nodeLabels addObject:label];

        if (section.isExpanded) {
            for (YALTimeLineEntryModel *entry in section.entries) {
                UIView *dot = [[UIView alloc] init];
                dot.backgroundColor    = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:0.8];
                dot.layer.cornerRadius = 3.5;
                [_contentView addSubview:dot];
                [_entryDots addObject:dot];

                YALTimeLineCardView *card = [[YALTimeLineCardView alloc] init];
                card.entry = entry;
                __weak typeof(self) ws = self;
                card.tapAction = ^(YALTimeLineEntryModel *e) {
                    __strong typeof(ws) ss = ws;
                    if ([ss.delegate respondsToSelector:@selector(timeLineView:didSelectEntry:)]) {
                        [ss.delegate timeLineView:ss didSelectEntry:e];
                    }
                };
                [_contentView addSubview:card];
                [_cardViews addObject:card];
            }
        }
        idx++;
    }
    [self setNeedsLayout];
}

- (void)reloadDataAnimated:(BOOL)animated {
    [self reloadData];
    if (animated) {
        self.contentView.alpha = 0.92;
        [UIView animateWithDuration:0.28 animations:^{
            self.contentView.alpha = 1.0;
            [self layoutIfNeeded];
        }];
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = self.bounds.size.width;
    CGFloat cardW = width - kCardLeft - kCardRight;
    CGFloat y = kTopPadding;

    NSInteger cardIdx = 0;
    NSInteger dotIdx  = 0;
    NSMutableArray<NSValue *> *curvePoints = [NSMutableArray array];
    NSMutableArray<NSValue *> *connSegs    = [NSMutableArray array];

    for (int s = 0; s < (int)_sections.count; s++) {
        UIButton *node  = _nodeButtons[s];
        UILabel  *label = _nodeLabels[s];
        YALTimeLineSectionModel *section = _sections[s];

        node.frame = CGRectMake(kCurveX - 6, y - 6, 12, 12);
        [label sizeToFit];
        label.frame = CGRectMake(kCardLeft, y - 9, label.bounds.size.width + 2, 18);
        [curvePoints addObject:[NSValue valueWithCGPoint:CGPointMake(kCurveX, y)]];

        y += kSectionToCard;

        if (section.isExpanded) {
            for (int i = 0; i < (int)section.entries.count; i++) {
                if (cardIdx >= (int)_cardViews.count) break;

                YALTimeLineEntryModel *entry = section.entries[i];
                CGFloat cardH = [YALTimeLineCardView cardHeightForEntry:entry width:cardW];

                YALTimeLineCardView *card = _cardViews[cardIdx];
                card.frame = CGRectMake(kCardLeft, y, cardW, cardH);

                CGFloat midY = y + cardH * 0.5;
                [curvePoints addObject:[NSValue valueWithCGPoint:CGPointMake(kCurveX, midY)]];

                [connSegs addObject:[NSValue valueWithCGPoint:CGPointMake(kCurveX + 5, midY)]];
                [connSegs addObject:[NSValue valueWithCGPoint:CGPointMake(kCardLeft - 4, midY)]];

                if (dotIdx < (int)_entryDots.count) {
                    _entryDots[dotIdx].frame = CGRectMake(kCurveX - 3.5, midY - 3.5, 7, 7);
                    dotIdx++;
                }

                y += cardH + kCardGap;
                cardIdx++;
            }
        } else {
            y += kCollapsedGap;
        }
    }

    CGFloat totalH = y + kBottomPad;
    _scrollView.contentSize = CGSizeMake(width, totalH);
    _contentView.frame      = CGRectMake(0, 0, width, totalH);

    [self drawCurve:curvePoints totalHeight:totalH];
    [self drawConnectors:connSegs];
}

#pragma mark - Drawing

- (void)drawCurve:(NSArray<NSValue *> *)points totalHeight:(CGFloat)totalHeight {
    if (points.count == 0) { _curveLayer.path = nil; return; }

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(kCurveX, 0)];

    CGPoint prev = CGPointMake(kCurveX, 0);
    for (NSInteger i = 0; i < (NSInteger)points.count; i++) {
        CGPoint p   = [points[i] CGPointValue];
        CGFloat dir = (i % 2 == 0) ? 1.0 : -1.0;
        CGFloat amp = 12.0;
        CGPoint c   = CGPointMake(kCurveX + dir * amp, (prev.y + p.y) / 2.0);
        [path addQuadCurveToPoint:p controlPoint:c];
        prev = p;
    }

    [path addLineToPoint:CGPointMake(kCurveX, totalHeight)];
    _curveLayer.path = path.CGPath;
}

- (void)drawConnectors:(NSArray<NSValue *> *)segments {
    if (segments.count < 2) { _connectorLayer.path = nil; return; }

    UIBezierPath *path = [UIBezierPath bezierPath];
    for (NSInteger i = 0; i + 1 < (NSInteger)segments.count; i += 2) {
        [path moveToPoint:[segments[i] CGPointValue]];
        [path addLineToPoint:[segments[i + 1] CGPointValue]];
    }
    _connectorLayer.path = path.CGPath;
}

#pragma mark - Actions

- (void)nodeTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(timeLineView:didToggleSectionAtIndex:)]) {
        [self.delegate timeLineView:self didToggleSectionAtIndex:sender.tag];
    }
}

@end
