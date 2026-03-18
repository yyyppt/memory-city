//
//  YALMessageCell.m
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import "YALMessageCell.h"
#import <Masonry/Masonry.h>

@implementation YALMessageCell {
  UIView *_cardView;
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
    self.contentView.backgroundColor = [UIColor clearColor];

    _cardView = [[UIView alloc] init];
    _cardView.backgroundColor = [self cardBackgroundColor];
    _cardView.layer.cornerRadius = 18.0;
    _cardView.layer.borderWidth = 1.0;
    _cardView.layer.borderColor = [self softBorderColor].CGColor;
    [self.contentView addSubview:_cardView];

    _avatarContainer = [[UIView alloc] init];
    _avatarContainer.layer.cornerRadius = 24.0;
    _avatarContainer.layer.masksToBounds = YES;
    [_cardView addSubview:_avatarContainer];

    _avatarIconView = [[UIImageView alloc] init];
    _avatarIconView.contentMode = UIViewContentModeScaleAspectFit;
    [_avatarContainer addSubview:_avatarIconView];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _nameLabel.textColor = [UIColor labelColor];
    [_cardView addSubview:_nameLabel];

    _summaryLabel = [[UILabel alloc] init];
    _summaryLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    _summaryLabel.textColor = [UIColor secondaryLabelColor];
    [_cardView addSubview:_summaryLabel];

    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    _timeLabel.textColor = [UIColor secondaryLabelColor];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    [_cardView addSubview:_timeLabel];

    _badgeLabel = [[UILabel alloc] init];
    _badgeLabel.textColor = [UIColor whiteColor];
    _badgeLabel.backgroundColor = [self accentColor];
    _badgeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    _badgeLabel.textAlignment = NSTextAlignmentCenter;
    _badgeLabel.layer.cornerRadius = 9.0;
    _badgeLabel.layer.masksToBounds = YES;
    [_cardView addSubview:_badgeLabel];

    _dotView = [[UIView alloc] init];
    _dotView.backgroundColor = [self accentColor];
    _dotView.layer.cornerRadius = 4.0;
    _dotView.layer.masksToBounds = YES;
    [_cardView addSubview:_dotView];

    [self setupConstraints];
  }
  return self;
}

- (void)setupConstraints {
  [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6.0, 12.0, 6.0, 12.0));
  }];

  [_avatarContainer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(_cardView.mas_left).offset(14.0);
    make.centerY.equalTo(_cardView.mas_centerY);
    make.width.height.mas_equalTo(48.0);
  }];

  [_avatarIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(_avatarContainer);
    make.width.height.mas_equalTo(24.0);
  }];

  [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(_cardView.mas_top).offset(10.0);
    make.right.equalTo(_cardView.mas_right).offset(-14.0);
    make.width.mas_equalTo(60.0);
  }];

  [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(_avatarContainer.mas_right).offset(12.0);
    make.top.equalTo(_cardView.mas_top).offset(10.0);
    make.right.lessThanOrEqualTo(_timeLabel.mas_left).offset(-10.0);
  }];

  [_summaryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(_nameLabel);
    make.top.equalTo(_nameLabel.mas_bottom);
    make.right.lessThanOrEqualTo(_cardView.mas_right).offset(-48.0);
  }];

  [_badgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(_cardView.mas_right).offset(-14.0);
    make.top.equalTo(_cardView.mas_top).offset(32.0);
    make.height.mas_equalTo(18.0);
    make.width.mas_equalTo(20.0);
  }];

  [_dotView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(_cardView.mas_right).offset(-14.0);
    make.top.equalTo(_cardView.mas_top).offset(37.0);
    make.width.height.mas_equalTo(8.0);
  }];
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
      [nameAttr addAttribute:NSForegroundColorAttributeName
                       value:[self accentColor]
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
    [_badgeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
      make.width.mas_equalTo(width);
    }];
    _badgeLabel.layer.cornerRadius = 9.0;
  } else {
    _badgeLabel.hidden = YES;
    _dotView.hidden = !showDot;
    [_badgeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
      make.width.mas_equalTo(20.0);
    }];
  }
}

#pragma mark - Colors

- (UIColor *)accentColor {
  return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

- (UIColor *)cardBackgroundColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor secondarySystemBackgroundColor];
  }
  return [UIColor whiteColor];
}

- (UIColor *)softBorderColor {
  return [UIColor colorWithWhite:0.0 alpha:0.05];
}

@end
