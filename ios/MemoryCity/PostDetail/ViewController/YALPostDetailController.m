//
//  YALPostDetailController.m
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import "YALPostDetailController.h"
#import "YALPostModel.h"
#import "YALCommentCell.h"
#import <Masonry/Masonry.h>

@interface YALPostDetailController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *comments;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIView *inputContainer;
@property (nonatomic, strong) UITextView *inputTextView;
@property (nonatomic, strong) UILabel *inputPlaceholderLabel;
@property (nonatomic, strong) UIButton *publishButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UILabel *likeCountLabel;
@property (nonatomic, strong) UILabel *favoriteCountLabel;
@property (nonatomic, strong) UILabel *commentCountLabel;
@property (nonatomic, strong) UILabel *commentHeader;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *expandedRows;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) NSInteger favoriteCount;
@property (nonatomic, assign) NSInteger viewCount;
@property (nonatomic, strong) MASConstraint *bottomBarBottomConstraint;
@property (nonatomic, strong) MASConstraint *bottomBarHeightConstraint;
@property (nonatomic, strong) MASConstraint *inputContainerHeightConstraint;
@property (nonatomic, strong) MASConstraint *publishButtonWidthConstraint;
@property (nonatomic, assign) BOOL inputExpanded;

@end

@implementation YALPostDetailController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];

    if (@available(iOS 13.0, *)) {
        UIImage *back = [UIImage systemImageNamed:@"chevron.left"];
        self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithImage:back
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(backTapped)];

        UIImage *person = [UIImage systemImageNamed:@"person.circle"];
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithImage:person
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(ownerTapped)];
    }

    self.expandedRows = [NSMutableSet set];
    // 点击空白收起键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(didTapBackground)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];

    // 键盘通知，保证底部栏在键盘上方
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];

    [self setupViews];
    [self setupDummyComments];
}

- (void)setupViews {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor systemBackgroundColor];
    if (@available(iOS 13.0, *)) {
        self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    }
    [self.view addSubview:self.scrollView];

    UIView *contentView = [[UIView alloc] init];
    [self.scrollView addSubview:contentView];

    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = 12.0;
    self.imageView.backgroundColor = [UIColor secondarySystemBackgroundColor];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor labelColor];
    self.titleLabel.numberOfLines = 0;

    self.descLabel = [[UILabel alloc] init];
    self.descLabel.font = [UIFont systemFontOfSize:14];
    self.descLabel.textColor = [UIColor secondaryLabelColor];
    self.descLabel.numberOfLines = 0;

    self.commentHeader = [[UILabel alloc] init];
    self.commentHeader.text = @"评论";
    self.commentHeader.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.commentHeader.textColor = [UIColor labelColor];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollEnabled = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView registerClass:[YALCommentCell class] forCellReuseIdentifier:@"YALCommentCell"];

    [contentView addSubview:self.imageView];
    [contentView addSubview:self.titleLabel];
    [contentView addSubview:self.descLabel];
    [contentView addSubview:self.commentHeader];
    [contentView addSubview:self.tableView];

    // 底部工具栏：评论输入 + 点赞 / 收藏 / 评论数
    self.bottomBar = [[UIView alloc] init];
    if (@available(iOS 13.0, *)) {
        self.bottomBar.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trait) {
            return trait.userInterfaceStyle == UIUserInterfaceStyleDark ? [UIColor blackColor] : [UIColor secondarySystemBackgroundColor];
        }];
    } else {
        self.bottomBar.backgroundColor = [UIColor blackColor];
    }
    [self.view addSubview:self.bottomBar];

    // 左侧：可增长的评论输入区
    self.inputContainer = [[UIView alloc] init];
    self.inputContainer.layer.cornerRadius = 20.0;
    self.inputContainer.layer.masksToBounds = YES;
    UIColor *pillBg = (@available(iOS 13.0, *)) ? [UIColor systemBackgroundColor] : [UIColor whiteColor];
    UIColor *inputBorderColor = (@available(iOS 13.0, *)) ? [UIColor separatorColor] : [UIColor lightGrayColor];
    self.inputContainer.backgroundColor = pillBg;
    self.inputContainer.layer.borderWidth = 1.0;
    self.inputContainer.layer.borderColor = inputBorderColor.CGColor;
    UIColor *placeholderColor = (@available(iOS 13.0, *)) ? [UIColor secondaryLabelColor] : [UIColor lightGrayColor];
    self.inputTextView = [[UITextView alloc] init];
    self.inputTextView.backgroundColor = [UIColor clearColor];
    self.inputTextView.font = [UIFont systemFontOfSize:15];
    self.inputTextView.textColor = [UIColor labelColor];
    self.inputTextView.tintColor = [UIColor systemBlueColor];
    self.inputTextView.delegate = self;
    self.inputTextView.scrollEnabled = NO;
    self.inputTextView.returnKeyType = UIReturnKeyDefault;
    self.inputTextView.textContainerInset = UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0);
    self.inputTextView.textContainer.lineFragmentPadding = 0;

    self.inputPlaceholderLabel = [[UILabel alloc] init];
    self.inputPlaceholderLabel.text = @"说点什么...";
    self.inputPlaceholderLabel.font = self.inputTextView.font;
    self.inputPlaceholderLabel.textColor = placeholderColor;

    self.publishButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.publishButton setTitle:@"发布" forState:UIControlStateNormal];
    self.publishButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.publishButton.backgroundColor = [UIColor colorWithRed:0.98 green:0.89 blue:0.58 alpha:1.0];
    [self.publishButton setTitleColor:[UIColor colorWithRed:0.42 green:0.30 blue:0.05 alpha:1.0] forState:UIControlStateNormal];
    self.publishButton.layer.cornerRadius = 14.0;
    self.publishButton.layer.masksToBounds = YES;
    self.publishButton.alpha = 0.0;
    self.publishButton.hidden = YES;
    [self.publishButton addTarget:self action:@selector(didTapPublish) forControlEvents:UIControlEventTouchUpInside];

    [self.inputContainer addSubview:self.inputTextView];
    [self.inputContainer addSubview:self.inputPlaceholderLabel];
    [self.inputContainer addSubview:self.publishButton];
    [self.bottomBar addSubview:self.inputContainer];

    // 右侧：点赞 / 收藏 / 评论 数字
    UIColor *iconColor = [UIColor labelColor];
    UIColor *buttonBgColor = (@available(iOS 13.0, *)) ? [UIColor tertiarySystemFillColor] : [UIColor colorWithWhite:0 alpha:0.08];

    self.likeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [self.likeButton setImage:[UIImage systemImageNamed:@"heart"] forState:UIControlStateNormal];
    }
    self.likeButton.tintColor = iconColor;
    [self.likeButton addTarget:self action:@selector(didTapLike) forControlEvents:UIControlEventTouchUpInside];

    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [self.favoriteButton setImage:[UIImage systemImageNamed:@"star"] forState:UIControlStateNormal];
    }
    self.favoriteButton.tintColor = iconColor;
    [self.favoriteButton addTarget:self action:@selector(didTapFavorite) forControlEvents:UIControlEventTouchUpInside];

    self.commentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [self.commentButton setImage:[UIImage systemImageNamed:@"text.bubble"] forState:UIControlStateNormal];
    }
    self.commentButton.tintColor = iconColor;
    [self.commentButton addTarget:self action:@selector(didTapComment) forControlEvents:UIControlEventTouchUpInside];

    NSArray<UIButton *> *actionButtons = @[self.likeButton, self.favoriteButton, self.commentButton];
    for (UIButton *button in actionButtons) {
        button.tintColor = iconColor;
        button.backgroundColor = buttonBgColor;
        button.layer.cornerRadius = 14.0;
        button.layer.masksToBounds = YES;
        button.contentEdgeInsets = UIEdgeInsetsMake(6.0, 6.0, 6.0, 6.0);
    }

    UIFont *countFont = [UIFont systemFontOfSize:12];
    UIColor *countColor = [UIColor secondaryLabelColor];
    self.likeCountLabel = [[UILabel alloc] init];
    self.likeCountLabel.font = countFont;
    self.likeCountLabel.textColor = countColor;

    self.favoriteCountLabel = [[UILabel alloc] init];
    self.favoriteCountLabel.font = countFont;
    self.favoriteCountLabel.textColor = countColor;

    self.commentCountLabel = [[UILabel alloc] init];
    self.commentCountLabel.font = countFont;
    self.commentCountLabel.textColor = countColor;

    [self.bottomBar addSubview:self.likeButton];
    [self.bottomBar addSubview:self.favoriteButton];
    [self.bottomBar addSubview:self.commentButton];
    [self.bottomBar addSubview:self.likeCountLabel];
    [self.bottomBar addSubview:self.favoriteCountLabel];
    [self.bottomBar addSubview:self.commentCountLabel];

    // Layout with Masonry
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        self.bottomBarBottomConstraint = make.bottom.equalTo(self.view.mas_bottom);
        self.bottomBarHeightConstraint = make.height.mas_equalTo(64.0);
    }];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.bottomBar.mas_top);
    }];

    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    CGFloat padding = 16.0;

    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView.mas_top).offset(padding);
        make.left.equalTo(contentView.mas_left).offset(padding);
        make.right.equalTo(contentView.mas_right).offset(-padding);
        make.height.equalTo(self.imageView.mas_width).multipliedBy(4.0/3.0);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageView.mas_bottom).offset(12.0);
        make.left.right.equalTo(self.imageView);
    }];

    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(6.0);
        make.left.right.equalTo(self.imageView);
    }];

    [self.commentHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descLabel.mas_bottom).offset(16.0);
        make.left.right.equalTo(self.imageView);
        make.height.mas_equalTo(22.0);
    }];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.commentHeader.mas_bottom).offset(8.0);
        make.left.right.equalTo(self.imageView);
        make.bottom.equalTo(contentView.mas_bottom).offset(-padding);
    }];

    // 底部四个按钮布局
    CGFloat paddingBar = 12.0;
    CGFloat spacing = 10.0;

    [self.commentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomBar.mas_right).offset(-paddingBar);
        make.centerY.equalTo(self.bottomBar.mas_centerY);
        make.width.height.mas_equalTo(26.0);
    }];
    [self.commentCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.commentButton.mas_left).offset(-4.0);
        make.centerY.equalTo(self.commentButton.mas_centerY);
    }];

    [self.favoriteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.commentCountLabel.mas_left).offset(-spacing);
        make.centerY.equalTo(self.commentButton.mas_centerY);
        make.width.height.mas_equalTo(26.0);
    }];
    [self.favoriteCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.favoriteButton.mas_left).offset(-4.0);
        make.centerY.equalTo(self.favoriteButton.mas_centerY);
    }];

    [self.likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.favoriteCountLabel.mas_left).offset(-spacing);
        make.centerY.equalTo(self.commentButton.mas_centerY);
        make.width.height.mas_equalTo(26.0);
    }];
    [self.likeCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.likeButton.mas_left).offset(-4.0);
        make.centerY.equalTo(self.likeButton.mas_centerY);
    }];

    [self.inputTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.equalTo(self.inputContainer);
        make.right.equalTo(self.publishButton.mas_left).offset(-8.0);
    }];
    [self.inputPlaceholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.inputContainer.mas_left).offset(12.0);
        make.centerY.equalTo(self.inputContainer.mas_centerY);
        make.right.lessThanOrEqualTo(self.publishButton.mas_left).offset(-8.0);
    }];
    [self.publishButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.inputContainer.mas_right).offset(-8.0);
        make.bottom.equalTo(self.inputContainer.mas_bottom).offset(-8.0);
        make.height.mas_equalTo(28.0);
        self.publishButtonWidthConstraint = make.width.mas_equalTo(0.0);
    }];

    if (self.post) {
        self.imageView.image = self.post.image;
        self.titleLabel.text = self.post.title;
        self.descLabel.text = self.post.desc;
    }

    [self updateBottomBarForEditing:NO animated:NO];
}

- (void)setupDummyComments {
    self.comments = @[
        @{
            @"name": @"旧街拾光",
            @"content": @"这张好有味道，感觉回到了小时候放学的路上。",
            @"time": @"3分钟前"
        },
        @{
            @"name": @"阿城同学",
            @"content": @"这个角度我也拍过，但你这张更有故事感。",
            @"time": @"20分钟前"
        },
        @{
            @"name": @"街角咖啡",
            @"content": @"欢迎下次来店里坐坐，我们就在这条街的拐角 🙂",
            @"time": @"昨天"
        }
    ];
    self.likeCount = 282;
    self.favoriteCount = 128;
    self.viewCount = (NSInteger)self.comments.count;
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.likeCount];
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.favoriteCount];
    self.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.viewCount];
    [self.tableView reloadData];
    [self updateBottomBarForEditing:self.inputExpanded animated:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YALCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YALCommentCell"];
    if (!cell) {
        cell = [[YALCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"YALCommentCell"];
    }
    NSDictionary *comment = self.comments[indexPath.row];
    BOOL expanded = [self.expandedRows containsObject:@(indexPath.row)];

    UIImage *avatar;
    if (@available(iOS 13.0, *)) {
        avatar = [UIImage systemImageNamed:@"person.circle.fill"];
    } else {
        avatar = [[UIImage alloc] init];
    }

    __weak typeof(self) weakSelf = self;
    cell.toggleExpandBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        NSNumber *idx = @(indexPath.row);
        if ([strongSelf.expandedRows containsObject:idx]) {
            [strongSelf.expandedRows removeObject:idx];
        } else {
            [strongSelf.expandedRows addObject:idx];
        }
        [strongSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    };

    [cell configureWithAvatar:avatar
                         name:comment[@"name"]
                      content:comment[@"content"]
                         time:comment[@"time"]
                     expanded:expanded];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    static YALCommentCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [[YALCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    });

    NSDictionary *comment = self.comments[indexPath.row];
    BOOL expanded = [self.expandedRows containsObject:@(indexPath.row)];
    UIImage *avatar = [[UIImage alloc] init];
    [sizingCell configureWithAvatar:avatar
                               name:comment[@"name"]
                            content:comment[@"content"]
                               time:comment[@"time"]
                           expanded:expanded];

    CGFloat width = CGRectGetWidth(tableView.bounds);
    sizingCell.bounds = CGRectMake(0, 0, width, CGFLOAT_MAX);
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];

    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return MAX(60.0, size.height);
}

#pragma mark - Actions

- (void)backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)ownerTapped {
    // 预留：跳转到作品主人的主页
}

- (void)didTapComment {
    CGRect headerFrameInScroll = [self.commentHeader convertRect:self.commentHeader.bounds
                                                          toView:self.scrollView];
    CGPoint offset = CGPointMake(0, MAX(0, headerFrameInScroll.origin.y - 16.0));
    [self.scrollView setContentOffset:offset animated:YES];
}

- (void)didTapLike {
    self.likeCount += 1;
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.likeCount];
}

- (void)didTapFavorite {
    self.favoriteCount += 1;
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.favoriteCount];
}

- (void)didTapInput {
    [self.inputTextView becomeFirstResponder];
}

- (void)didTapBackground {
    [self.view endEditing:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *touchedView = touch.view;
    if ([touchedView isKindOfClass:[UIControl class]]) {
        return NO;
    }
    if ([touchedView isDescendantOfView:self.bottomBar]) {
        return NO;
    }
    return YES;
}

- (void)keyboardWillChangeFrame:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    CGFloat keyboardHeightInView = CGRectGetMaxY(self.view.bounds) - [self.view convertRect:endFrame fromView:nil].origin.y;
    if (keyboardHeightInView < 0) keyboardHeightInView = 0;

    CGFloat safeBottom = 0;
    if (@available(iOS 11.0, *)) {
        safeBottom = self.view.safeAreaInsets.bottom;
    }
    CGFloat keyboardGap = 0;
    if (keyboardHeightInView > 0) {
        CGFloat desiredGap = [self targetInputHeightForEditing:self.inputExpanded] / 3.0;
        keyboardGap = MIN(20.0, MAX(12.0, desiredGap));
    }
    CGFloat offset = -MAX(0, keyboardHeightInView - safeBottom + keyboardGap);

    [self.bottomBarBottomConstraint uninstall];
    [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
        self.bottomBarBottomConstraint = make.bottom.equalTo(self.view.mas_bottom).offset(offset);
    }];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self updateBottomBarForEditing:YES animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self updateBottomBarForEditing:NO animated:YES];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.inputPlaceholderLabel.hidden = textView.text.length > 0;
    [self updatePublishButtonState];
    [self updateBottomBarForEditing:YES animated:NO];
}

- (void)didTapPublish {
    [self submitComment];
}

- (void)submitComment {
    NSString *text = [self.inputTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) {
        [self.inputTextView resignFirstResponder];
        return;
    }

    NSMutableArray *mutable = [self.comments mutableCopy] ?: [NSMutableArray array];
    NSDictionary *newComment = @{
        @"name": @"我",
        @"content": text,
        @"time": @"刚刚"
    };
    [mutable insertObject:newComment atIndex:0];
    self.comments = mutable;
    self.viewCount = self.comments.count;
    self.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.viewCount];

    [self.expandedRows addObject:@0];
    [self.tableView reloadData];

    self.inputTextView.text = @"";
    self.inputPlaceholderLabel.hidden = NO;
    [self updatePublishButtonState];
    [self updateBottomBarForEditing:YES animated:NO];
    [self.inputTextView resignFirstResponder];
}

- (void)updateBottomBarForEditing:(BOOL)editing animated:(BOOL)animated {
    self.inputExpanded = editing;
    self.inputTextView.textContainerInset = editing
        ? UIEdgeInsetsMake(10.0, 12.0, 10.0, 12.0)
        : UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0);

    NSArray<UIView *> *actionViews = @[
        self.likeButton,
        self.favoriteButton,
        self.commentButton,
        self.likeCountLabel,
        self.favoriteCountLabel,
        self.commentCountLabel
    ];

    if (!editing) {
        for (UIView *view in actionViews) {
            view.hidden = NO;
        }
    }

    [self.bottomBarHeightConstraint uninstall];
    [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
        CGFloat inputHeight = [self targetInputHeightForEditing:editing];
        self.bottomBarHeightConstraint = make.height.mas_equalTo(inputHeight + 20.0);
    }];

    [self.inputContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomBar.mas_left).offset(12.0);
        make.top.equalTo(self.bottomBar.mas_top).offset(8.0);
        if (editing) {
            make.right.equalTo(self.bottomBar.mas_right).offset(-12.0);
        } else {
            make.right.equalTo(self.likeCountLabel.mas_left).offset(-8.0);
        }
        self.inputContainerHeightConstraint = make.height.mas_equalTo([self targetInputHeightForEditing:editing]);
    }];

    [self.inputPlaceholderLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.inputContainer.mas_left).offset(12.0);
        make.right.lessThanOrEqualTo(self.publishButton.mas_left).offset(-8.0);
        if (editing) {
            make.top.equalTo(self.inputContainer.mas_top).offset(10.0);
        } else {
            make.centerY.equalTo(self.inputContainer.mas_centerY);
        }
    }];

    self.inputContainer.layer.cornerRadius = editing ? 18.0 : 20.0;
    self.publishButton.hidden = NO;
    [self.publishButtonWidthConstraint uninstall];
    [self.publishButton mas_updateConstraints:^(MASConstraintMaker *make) {
        self.publishButtonWidthConstraint = make.width.mas_equalTo(editing ? 52.0 : 0.0);
    }];
    [self updatePublishButtonState];

    void (^animations)(void) = ^{
        CGFloat alpha = editing ? 0.0 : 1.0;
        for (UIView *view in actionViews) {
            view.alpha = alpha;
        }
        self.publishButton.alpha = editing ? 1.0 : 0.0;
        [self.view layoutIfNeeded];
    };

    void (^completion)(BOOL) = ^(BOOL finished) {
        if (editing) {
            for (UIView *view in actionViews) {
                view.hidden = YES;
            }
        } else {
            self.publishButton.hidden = YES;
        }
    };

    if (animated) {
        [UIView animateWithDuration:0.25
                         animations:animations
                         completion:completion];
    } else {
        animations();
        completion(YES);
    }
}

- (CGFloat)targetInputHeightForEditing:(BOOL)editing {
    if (!editing) {
        self.inputTextView.scrollEnabled = NO;
        return 44.0;
    }

    CGFloat availableWidth = CGRectGetWidth(self.view.bounds) - 24.0 - 60.0;
    if (availableWidth <= 0) {
        availableWidth = CGRectGetWidth([UIScreen mainScreen].bounds) - 24.0 - 60.0;
    }

    CGSize fittingSize = [self.inputTextView sizeThatFits:CGSizeMake(availableWidth, CGFLOAT_MAX)];
    CGFloat height = MAX(44.0, ceil(fittingSize.height));
    CGFloat maxHeight = 108.0;
    self.inputTextView.scrollEnabled = height > maxHeight;
    return MIN(height, maxHeight);
}

- (void)updatePublishButtonState {
    NSString *text = [self.inputTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL hasText = text.length > 0;
    self.publishButton.enabled = hasText;
    self.publishButton.alpha = self.inputExpanded ? (hasText ? 1.0 : 0.65) : 0.0;
}


@end

