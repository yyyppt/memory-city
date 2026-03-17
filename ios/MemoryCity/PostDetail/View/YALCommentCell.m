//
//  YALCommentCell.m
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import "YALCommentCell.h"
#import <Masonry/Masonry.h>

@interface YALCommentCell ()

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, assign) BOOL expanded;

@end

@implementation YALCommentCell

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

        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.textColor = [UIColor labelColor];
        _contentLabel.numberOfLines = 0;

        _contentLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapContent)];
        [_contentLabel addGestureRecognizer:tap];

        [self.contentView addSubview:_avatarView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_timeLabel];
        [self.contentView addSubview:_contentLabel];

        [self setupConstraints];
    }
    return self;
}

- (void)setupConstraints {
    CGFloat padding = 12.0;

    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(padding);
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

    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4.0);
        make.left.equalTo(self.nameLabel.mas_left);
        make.right.equalTo(self.timeLabel.mas_right);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-padding);
    }];
}

- (void)configureWithAvatar:(UIImage *)avatar
                       name:(NSString *)name
                    content:(NSString *)content
                       time:(NSString *)time
                   expanded:(BOOL)expanded {
    self.avatarView.image = avatar;
    self.nameLabel.text = name;
    self.timeLabel.text = time;
    self.expanded = expanded;

    // 富文本：长文时在末尾加“ 展开/收起”
    NSString *suffix = @"";
    if (content.length > 40) {
        suffix = expanded ? @"  收起" : @"  展开";
    }
    NSString *full = [content stringByAppendingString:suffix];
    NSMutableAttributedString *attr =
      [[NSMutableAttributedString alloc] initWithString:full
                                             attributes:@{
        NSForegroundColorAttributeName: [UIColor labelColor],
        NSFontAttributeName: self.contentLabel.font
    }];
    if (suffix.length > 0) {
        NSRange range = [full rangeOfString:suffix];
        if (range.location != NSNotFound) {
            UIColor *accent = (@available(iOS 13.0, *)) ? [UIColor systemBlueColor] : [UIColor colorWithRed:0.2 green:0.4 blue:1 alpha:1];
            [attr addAttributes:@{
                NSForegroundColorAttributeName: accent,
                NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]
            } range:range];
        }
    }
    self.contentLabel.attributedText = attr;
}

- (void)didTapContent {
    if (self.toggleExpandBlock) {
        self.toggleExpandBlock();
    }
}

@end

