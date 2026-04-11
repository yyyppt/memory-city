//
//  YALCommentCell.m
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import "YALCommentCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface YALCommentCell () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, assign) BOOL expandable;
@property (nonatomic, strong) MASConstraint *avatarLeftConstraint;
@property (nonatomic, strong) MASConstraint *bubbleLeftConstraint;

@end

@implementation YALCommentCell

- (UIColor *)topLevelBubbleColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:0.16 alpha:1.0];
            }
            return [UIColor colorWithRed:0.985 green:0.985 blue:0.985 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.985 green:0.985 blue:0.985 alpha:1.0];
}

- (UIColor *)replyBubbleColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:0.24 green:0.19 blue:0.12 alpha:1.0];
            }
            return [UIColor colorWithRed:1.0 green:0.976 blue:0.925 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:1.0 green:0.976 blue:0.925 alpha:1.0];
}

- (UIColor *)bubbleBorderColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:1.0 alpha:0.14];
            }
            return [UIColor colorWithWhite:0.0 alpha:0.08];
        }];
    }
    return [UIColor colorWithWhite:0.0 alpha:0.08];
}

- (UIColor *)replyPrefixColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:0.96 green:0.78 blue:0.40 alpha:1.0];
            }
            return [UIColor colorWithRed:0.82 green:0.58 blue:0.18 alpha:1.0];
        }];
    }
    return [UIColor colorWithRed:0.82 green:0.58 blue:0.18 alpha:1.0];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor systemBackgroundColor];

        _avatarView = [[UIImageView alloc] init];
        _avatarView.layer.cornerRadius = 16.0;
        _avatarView.layer.masksToBounds = YES;
        _avatarView.contentMode = UIViewContentModeScaleAspectFill;

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        _nameLabel.textColor = [UIColor labelColor];

        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor secondaryLabelColor];
        _timeLabel.textAlignment = NSTextAlignmentRight;

        _bubbleView = [[UIView alloc] init];
        _bubbleView.layer.cornerRadius = 14.0;
        _bubbleView.layer.masksToBounds = YES;
        _bubbleView.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
        _bubbleView.layer.borderColor = [self bubbleBorderColor].CGColor;

        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.textColor = [UIColor labelColor];
        _contentLabel.numberOfLines = 0;

        _contentLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapContent)];
        tap.cancelsTouchesInView = YES;
        tap.delegate = self;
        [_contentLabel addGestureRecognizer:tap];

        [self.contentView addSubview:_avatarView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_timeLabel];
        [self.contentView addSubview:_bubbleView];
        [self.bubbleView addSubview:_contentLabel];

        [self setupConstraints];
    }
    return self;
}

- (void)setupConstraints {
    CGFloat padding = 12.0;

    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.avatarLeftConstraint = make.left.equalTo(self.contentView.mas_left).offset(padding);
        make.top.equalTo(self.contentView.mas_top).offset(padding);
        make.width.height.mas_equalTo(32.0);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView.mas_top);
        make.left.equalTo(self.avatarView.mas_right).offset(8.0);
        make.right.lessThanOrEqualTo(self.timeLabel.mas_left).offset(-8.0);
    }];

    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.nameLabel.mas_centerY);
        make.right.equalTo(self.contentView.mas_right).offset(-padding);
    }];

    [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4.0);
        self.bubbleLeftConstraint = make.left.equalTo(self.nameLabel.mas_left);
        make.right.equalTo(self.timeLabel.mas_right);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-padding);
    }];

    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bubbleView).insets(UIEdgeInsetsMake(9.0, 12.0, 9.0, 16.0));
    }];
}

- (void)configureWithAvatar:(UIImage *)avatar
                       name:(NSString *)name
                     content:(NSString *)content
                        time:(NSString *)time
                   expanded:(BOOL)expanded {
    [self configureWithAvatar:avatar
              avatarURLString:nil
                         name:name
                      content:content
                         time:time
                      isReply:NO
                   replyLevel:0
                     expanded:expanded];
}

- (NSMutableParagraphStyle *)commentParagraphStyle {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 3.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    return paragraphStyle;
}

- (CGFloat)availableContentWidthForReplyLevel:(NSInteger)replyLevel {
    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    if (width <= 0) {
        width = CGRectGetWidth(UIScreen.mainScreen.bounds);
    }
    CGFloat normalizedLevel = MAX(0, MIN((CGFloat)replyLevel, 3.0));
    CGFloat avatarAndNameLeft = 12.0 + normalizedLevel * 24.0 + 32.0 + 8.0;
    CGFloat replyBubbleExtraOffset = replyLevel > 0 ? 12.0 + normalizedLevel * 6.0 : 0.0;
    CGFloat rightPadding = 12.0;
    CGFloat contentInsets = 12.0 + 16.0;
    return MAX(80.0, width - avatarAndNameLeft - replyBubbleExtraOffset - rightPadding - contentInsets);
}

- (CGFloat)heightForText:(NSString *)text
                   width:(CGFloat)width
          paragraphStyle:(NSParagraphStyle *)paragraphStyle {
    if (text.length == 0 || width <= 0) {
        return 0.0;
    }
    NSAttributedString *attr =
        [[NSAttributedString alloc] initWithString:text
                                        attributes:@{
        NSFontAttributeName: self.contentLabel.font,
        NSParagraphStyleAttributeName: paragraphStyle
    }];
    CGRect rect = [attr boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     context:nil];
    return ceil(CGRectGetHeight(rect));
}

- (BOOL)textNeedsExpansion:(NSString *)text
                     width:(CGFloat)width
            paragraphStyle:(NSParagraphStyle *)paragraphStyle {
    CGFloat twoLineHeight = ceil(self.contentLabel.font.lineHeight * 2.0 + paragraphStyle.lineSpacing + 1.0);
    return [self heightForText:text width:width paragraphStyle:paragraphStyle] > twoLineHeight;
}

- (NSString *)prefixOfString:(NSString *)text length:(NSInteger)length {
    if (length <= 0 || text.length == 0) {
        return @"";
    }
    NSRange wantedRange = NSMakeRange(0, MIN((NSUInteger)length, text.length));
    NSRange safeRange = [text rangeOfComposedCharacterSequencesForRange:wantedRange];
    return [text substringWithRange:safeRange];
}

- (NSString *)collapsedPrefixForContent:(NSString *)content
                                  suffix:(NSString *)suffix
                                   width:(CGFloat)width
                          paragraphStyle:(NSParagraphStyle *)paragraphStyle {
    NSInteger low = 0;
    NSInteger high = (NSInteger)content.length;
    NSInteger best = 0;
    while (low <= high) {
        NSInteger mid = (low + high) / 2;
        NSString *candidate = [[self prefixOfString:content length:mid] stringByAppendingString:suffix];
        if (![self textNeedsExpansion:candidate width:width paragraphStyle:paragraphStyle]) {
            best = mid;
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    return [[self prefixOfString:content length:best] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)configureWithAvatar:(UIImage *)avatar
             avatarURLString:(nullable NSString *)avatarURLString
                        name:(NSString *)name
                     content:(NSString *)content
                        time:(NSString *)time
                     isReply:(BOOL)isReply
                   replyLevel:(NSInteger)replyLevel
                    expanded:(BOOL)expanded {
    [self.avatarView sd_cancelCurrentImageLoad];
    self.avatarView.image = avatar;
    if (avatarURLString.length > 0) {
        NSURL *avatarURL = [NSURL URLWithString:avatarURLString];
        if (avatarURL && avatarURL.scheme.length > 0) {
            [self.avatarView sd_setImageWithURL:avatarURL
                               placeholderImage:avatar
                                        options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
        }
    }
    self.nameLabel.text = name;
    self.timeLabel.text = time;
    self.expanded = expanded;
    NSInteger normalizedLevel = MAX(0, replyLevel);
    CGFloat indent = normalizedLevel > 0 ? MIN((CGFloat)normalizedLevel, 3.0) * 24.0 : 0.0;
    self.avatarLeftConstraint.offset = 12.0 + indent;
    self.bubbleLeftConstraint.offset = normalizedLevel > 0 ? 12.0 + MIN((CGFloat)normalizedLevel, 3.0) * 6.0 : 0.0;
    self.bubbleView.backgroundColor = normalizedLevel > 0
        ? [self replyBubbleColor]
        : [self topLevelBubbleColor];
    self.bubbleView.layer.borderColor = [self bubbleBorderColor].CGColor;
    self.nameLabel.textColor = [UIColor labelColor];

    // 根据 UILabel 实际宽度排版后的行数决定：超过两行才展示展开/收起。
    NSString *safeContent = content ?: @"";
    NSMutableParagraphStyle *paragraphStyle = [self commentParagraphStyle];
    CGFloat availableWidth = [self availableContentWidthForReplyLevel:normalizedLevel];
    self.expandable = [self textNeedsExpansion:safeContent width:availableWidth paragraphStyle:paragraphStyle];
    NSString *visibleContent = safeContent;
    NSString *suffix = @"";
    NSString *operationText = @"";
    if (self.expandable) {
        if (expanded) {
            suffix = @"  收起";
            operationText = @"收起";
        } else {
            suffix = @"... 展开全文";
            operationText = @"展开全文";
            visibleContent = [self collapsedPrefixForContent:safeContent
                                                      suffix:suffix
                                                       width:availableWidth
                                              paragraphStyle:paragraphStyle];
        }
    }

    NSString *full = [visibleContent stringByAppendingString:suffix];
    NSMutableAttributedString *attr =
      [[NSMutableAttributedString alloc] initWithString:full
                                             attributes:@{
        NSForegroundColorAttributeName: [UIColor labelColor],
        NSFontAttributeName: self.contentLabel.font,
        NSParagraphStyleAttributeName: paragraphStyle
    }];
    if (operationText.length > 0) {
        NSRange range = [full rangeOfString:operationText options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            UIColor *accent = nil;
            if (@available(iOS 13.0, *)) {
                accent = [UIColor systemBlueColor];
            } else {
                accent = [UIColor colorWithRed:0.2 green:0.4 blue:1 alpha:1];
            }
            [attr addAttributes:@{
                NSForegroundColorAttributeName: accent,
                NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]
            } range:range];
        }
    }
    if (normalizedLevel > 0 && [safeContent hasPrefix:@"回复 "]) {
        NSRange colonRange = [visibleContent rangeOfString:@"："];
        if (colonRange.location != NSNotFound) {
            NSRange prefixRange = NSMakeRange(0, colonRange.location + 1);
            [attr addAttributes:@{
                NSForegroundColorAttributeName: [self replyPrefixColor],
                NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]
            } range:prefixRange];
        }
    }
    self.contentLabel.attributedText = attr;
    self.contentLabel.preferredMaxLayoutWidth = availableWidth;
    self.contentLabel.numberOfLines = (self.expandable && !expanded) ? 2 : 0;
    self.contentLabel.userInteractionEnabled = self.expandable;
    [self.contentLabel invalidateIntrinsicContentSize];
}

- (void)didTapContent {
    if (self.expandable && self.toggleExpandBlock) {
        self.toggleExpandBlock();
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    (void)gestureRecognizer;
    (void)otherGestureRecognizer;
    return NO;
}

@end
