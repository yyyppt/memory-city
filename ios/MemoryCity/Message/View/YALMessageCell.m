//
//  YALMessageCell.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/13.
//

#import "YALMessageCell.h"

@implementation YALMessageCell {
  UIView *_avatarContainer;
  UIImageView *_avatarIconView;
  UILabel *_nameLabel;
  UILabel *_summaryLabel;
  UILabel *_timeLabel;
  UILabel *_badgeLabel;
  UIView *_dotView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _avatarContainer = [[UIView alloc] init];
    _avatarContainer.layer.cornerRadius = 24.0;
    _avatarContainer.layer.masksToBounds = YES;
    [self.contentView addSubview:_avatarContainer];

    _avatarIconView = [[UIImageView alloc] init];
    _avatarIconView.contentMode = UIViewContentModeScaleAspectFit;
    [_avatarContainer addSubview:_avatarIconView];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _nameLabel.textColor = [UIColor labelColor];
    [self.contentView addSubview:_nameLabel];

    _summaryLabel = [[UILabel alloc] init];
    _summaryLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    _summaryLabel.textColor = [UIColor secondaryLabelColor];
    [self.contentView addSubview:_summaryLabel];

    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    _timeLabel.textColor = [UIColor secondaryLabelColor];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_timeLabel];

    _badgeLabel = [[UILabel alloc] init];
    _badgeLabel.textColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
      _badgeLabel.backgroundColor = [UIColor systemRedColor];
    } else {
      _badgeLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
    }
    _badgeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    _badgeLabel.textAlignment = NSTextAlignmentCenter;
    _badgeLabel.layer.cornerRadius = 9.0;
    _badgeLabel.layer.masksToBounds = YES;
    [self.contentView addSubview:_badgeLabel];

    _dotView = [[UIView alloc] init];
    if (@available(iOS 13.0, *)) {
      _dotView.backgroundColor = [UIColor systemRedColor];
    } else {
      _dotView.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
    }
    _dotView.layer.cornerRadius = 4.0;
    _dotView.layer.masksToBounds = YES;
    [self.contentView addSubview:_dotView];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat contentWidth = CGRectGetWidth(self.contentView.bounds);
  _avatarContainer.frame = CGRectMake(16, 12, 48, 48);
  _avatarIconView.frame = CGRectMake(12, 12, 24, 24);

  _nameLabel.frame = CGRectMake(76, 14, contentWidth - 160, 22);
  _summaryLabel.frame = CGRectMake(76, 38, contentWidth - 160, 20);
  _timeLabel.frame = CGRectMake(contentWidth - 90, 14, 72, 20);

  _badgeLabel.frame = CGRectMake(contentWidth - 36, 40, 20, 18);
  _dotView.frame = CGRectMake(contentWidth - 24, 45, 8, 8);
}

- (void)configureWithMessage:(NSDictionary *)message {
  _avatarContainer.backgroundColor = message[@"avatarBgColor"];
  _avatarIconView.image = message[@"avatarIcon"];
  _avatarIconView.tintColor = [UIColor whiteColor];

  NSString *name = message[@"name"] ?: @"";
  NSString *highlight = message[@"highlight"] ?: @"";
  NSMutableAttributedString *nameAttr =
    [[NSMutableAttributedString alloc] initWithString:name
                                           attributes:@{
    NSForegroundColorAttributeName: [UIColor labelColor]
  }];
  if (highlight.length > 0) {
    NSRange range = [name rangeOfString:highlight];
    if (range.location != NSNotFound) {
      UIColor *highlightColor;
      if (@available(iOS 13.0, *)) {
        highlightColor = [UIColor systemBlueColor];
      } else {
        highlightColor = [UIColor colorWithRed:0.41 green:0.73 blue:1.0 alpha:1.0];
      }
      [nameAttr addAttribute:NSForegroundColorAttributeName
                       value:highlightColor
                       range:range];
    }
  }
  _nameLabel.attributedText = nameAttr;
  _summaryLabel.text = message[@"summary"];
  _timeLabel.text = message[@"time"];

  NSNumber *unreadCount = message[@"unreadCount"];
  BOOL showDot = [message[@"showDot"] boolValue];
  if (unreadCount.integerValue > 0) {
    _badgeLabel.hidden = NO;
    _dotView.hidden = YES;
    _badgeLabel.text = unreadCount.integerValue > 99 ? @"99+" : unreadCount.stringValue;
    CGFloat width = unreadCount.integerValue > 9 ? 26.0 : 20.0;
    _badgeLabel.frame = CGRectMake(CGRectGetWidth(self.contentView.bounds) - 16 - width, 40, width, 18);
    _badgeLabel.layer.cornerRadius = 9.0;
  } else {
    _badgeLabel.hidden = YES;
    _dotView.hidden = !showDot;
  }
}

@end

