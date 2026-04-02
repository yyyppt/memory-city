//
//  YALPostDetailController.m
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import "YALPostDetailController.h"
#import "YALPostModel.h"
#import "YALCommentCell.h"
#import "YALContentManager.h"
#import "YALAuthManager.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

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
@property (nonatomic, strong) MASConstraint *tableHeightConstraint;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) NSInteger favoriteCount;
@property (nonatomic, assign) NSInteger viewCount;
@property (nonatomic, strong) MASConstraint *bottomBarBottomConstraint;
@property (nonatomic, strong) MASConstraint *bottomBarHeightConstraint;
@property (nonatomic, strong) MASConstraint *inputContainerHeightConstraint;
@property (nonatomic, strong) MASConstraint *publishButtonWidthConstraint;
@property (nonatomic, assign) BOOL inputExpanded;
@property (nonatomic, assign) BOOL isLiked;
@property (nonatomic, assign) BOOL isCollected;
@property (nonatomic, strong) UIView *contentCard;

@end

@implementation YALPostDetailController

static NSString * const kYALLikedStatusCachePrefix = @"YALPostDetailLikedStatus";
static NSString * const kYALCollectedStatusCachePrefix = @"YALPostDetailCollectedStatus";

- (NSString *)cacheKeyForPrefix:(NSString *)prefix {
    NSNumber *contentId = self.post.contentId;
    if (contentId == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@_%@", prefix, contentId];
}

- (void)persistBoolStatus:(BOOL)value prefix:(NSString *)prefix {
    NSString *key = [self cacheKeyForPrefix:prefix];
    if (key.length == 0) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)cachedBoolStatusForPrefix:(NSString *)prefix hasValue:(BOOL *)hasValue {
    NSString *key = [self cacheKeyForPrefix:prefix];
    if (key.length == 0) {
        if (hasValue) { *hasValue = NO; }
        return NO;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:key] == nil) {
        if (hasValue) { *hasValue = NO; }
        return NO;
    }
    if (hasValue) { *hasValue = YES; }
    return [defaults boolForKey:key];
}

- (void)updateActionButtonsAppearance {
    if (@available(iOS 13.0, *)) {
        UIImage *likeImage = [UIImage systemImageNamed:(self.isLiked ? @"heart.fill" : @"heart")];
        UIImage *favoriteImage = [UIImage systemImageNamed:(self.isCollected ? @"star.fill" : @"star")];
        [self.likeButton setImage:likeImage forState:UIControlStateNormal];
        [self.favoriteButton setImage:favoriteImage forState:UIControlStateNormal];
        self.likeButton.tintColor = self.isLiked ? [UIColor systemRedColor] : [UIColor labelColor];
        self.favoriteButton.tintColor = self.isCollected ? [UIColor systemOrangeColor] : [UIColor labelColor];
    }
}

- (BOOL)boolValueFromLikeStatusObject:(id)value fallback:(BOOL)fallback {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [((NSNumber *)value) integerValue] != 0;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [((NSString *)value) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) {
            return fallback;
        }
        return text.integerValue != 0;
    }
    return fallback;
}

- (NSString *)displayTimeStringFromRaw:(id)raw {
    if (![raw isKindOfClass:[NSString class]]) {
        return @"刚刚";
    }
    NSString *text = (NSString *)raw;
    if (text.length >= 16 && [text containsString:@"T"]) {
        return [[text substringToIndex:16] stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    }
    return text.length > 0 ? text : @"刚刚";
}

- (NSArray<NSDictionary *> *)flattenCommentTree:(NSArray *)comments {
    NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
    for (id obj in comments) {
        if (![obj isKindOfClass:[NSDictionary class]]) { continue; }
        NSDictionary *item = (NSDictionary *)obj;
        NSString *name = [item[@"user_nickname"] isKindOfClass:[NSString class]] ? item[@"user_nickname"] : @"匿名用户";
        NSString *content = [item[@"content"] isKindOfClass:[NSString class]] ? item[@"content"] : @"";
        NSString *time = [self displayTimeStringFromRaw:item[@"created_at"]];
        [result addObject:@{
            @"name": name,
            @"content": content,
            @"time": time
        }];

        NSArray *replies = [item[@"replies"] isKindOfClass:[NSArray class]] ? item[@"replies"] : nil;
        if (replies.count > 0) {
            [result addObjectsFromArray:[self flattenCommentTree:replies]];
        }
    }
    return result;
}

- (void)refreshTableHeight {
    [self.tableView layoutIfNeeded];
    CGFloat height = self.tableView.contentSize.height;
    self.tableHeightConstraint.offset = MAX(height, 1.0);
    [self.view layoutIfNeeded];
}

- (void)applyDetailData:(NSDictionary *)content {
    if (![content isKindOfClass:[NSDictionary class]]) {
        return;
    }

    NSString *titleText = [content[@"title"] isKindOfClass:[NSString class]] ? content[@"title"] : self.post.title;
    NSString *descText = [content[@"content"] isKindOfClass:[NSString class]] ? content[@"content"] : self.post.desc;
    if (titleText.length == 0) {
        titleText = @"未命名内容";
    }
    self.titleLabel.text = titleText;
    self.descLabel.text = descText ?: @"";

    id likeObj = content[@"like_count"];
    if ([likeObj respondsToSelector:@selector(integerValue)]) {
        self.likeCount = [likeObj integerValue];
    }
    id favoriteObj = content[@"favorite_count"];
    if (![favoriteObj respondsToSelector:@selector(integerValue)]) {
        favoriteObj = content[@"collect_count"];
    }
    if ([favoriteObj respondsToSelector:@selector(integerValue)]) {
        self.favoriteCount = [favoriteObj integerValue];
    } else if (self.favoriteCount < 0) {
        self.favoriteCount = 0;
    }
    id commentObj = content[@"comment_count"];
    if ([commentObj respondsToSelector:@selector(integerValue)]) {
        self.viewCount = [commentObj integerValue];
    }
    BOOL hasLikedValue = NO;
    BOOL hasCollectedValue = NO;
    if ([content[@"is_liked"] respondsToSelector:@selector(boolValue)]) {
        self.isLiked = [self boolValueFromLikeStatusObject:content[@"is_liked"] fallback:self.isLiked];
        hasLikedValue = YES;
    }
    if ([content[@"is_likeed"] respondsToSelector:@selector(boolValue)]) {
        self.isLiked = [self boolValueFromLikeStatusObject:content[@"is_likeed"] fallback:self.isLiked];
        hasLikedValue = YES;
    }
    if ([content[@"is_collected"] respondsToSelector:@selector(boolValue)]) {
        self.isCollected = [content[@"is_collected"] boolValue];
        hasCollectedValue = YES;
    }
    if (!hasLikedValue) {
        self.isLiked = [self cachedBoolStatusForPrefix:kYALLikedStatusCachePrefix hasValue:&hasLikedValue];
    }
    if (!hasCollectedValue) {
        self.isCollected = [self cachedBoolStatusForPrefix:kYALCollectedStatusCachePrefix hasValue:&hasCollectedValue];
    }
    if (hasLikedValue) {
        [self persistBoolStatus:self.isLiked prefix:kYALLikedStatusCachePrefix];
    }
    if (hasCollectedValue) {
        [self persistBoolStatus:self.isCollected prefix:kYALCollectedStatusCachePrefix];
    }
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.likeCount];
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(self.favoriteCount, 0)];
    self.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.viewCount];
    [self updateActionButtonsAppearance];

    NSArray *images = nil;
    if ([content[@"images"] isKindOfClass:[NSArray class]]) {
        images = content[@"images"];
    } else if ([content[@"Images"] isKindOfClass:[NSArray class]]) {
        images = content[@"Images"];
    }
    NSString *detailImageURL = nil;
    for (id obj in images) {
        if ([obj isKindOfClass:[NSString class]] && [obj length] > 0) {
            detailImageURL = (NSString *)obj;
            break;
        }
    }
    if (detailImageURL.length > 0) {
        self.post.imageURLString = detailImageURL;
        self.post.images = images;
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:detailImageURL]
                          placeholderImage:self.post.image
                                   options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages
                                 completed:nil];
    }
}

- (void)loadContentDetailIfNeeded {
    if (self.post.contentId == nil) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] getContentDetailWithId:self.post.contentId completion:^(BOOL success, NSDictionary * _Nullable content, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (success) {
            [strongSelf applyDetailData:content];
        } else {
            NSLog(@"❌ 详情获取失败: %@", error.localizedDescription);
        }
    }];
}

- (void)loadComments {
    if (self.post.contentId == nil) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] getCommentListWithContentId:self.post.contentId
                                                              page:1
                                                          pageSize:50
                                                        completion:^(BOOL success, NSArray * _Nullable comments, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (success) {
            strongSelf.comments = [strongSelf flattenCommentTree:(comments ?: @[])];
            strongSelf.viewCount = strongSelf.comments.count;
            strongSelf.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)strongSelf.viewCount];
            [strongSelf.tableView reloadData];
            [strongSelf refreshTableHeight];
        } else {
            NSLog(@"❌ 评论获取失败: %@", error.localizedDescription);
        }
    }];
}

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
    [self loadContentDetailIfNeeded];
    [self loadComments];
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

    self.contentCard = [[UIView alloc] init];
    self.contentCard.backgroundColor = [UIColor colorWithRed:0.995 green:0.985 blue:0.965 alpha:1.0];
    self.contentCard.layer.cornerRadius = 22.0;
    self.contentCard.layer.masksToBounds = NO;
    self.contentCard.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.10].CGColor;
    self.contentCard.layer.shadowOpacity = 1.0;
    self.contentCard.layer.shadowOffset = CGSizeMake(0, 10);
    self.contentCard.layer.shadowRadius = 20.0;
    [contentView addSubview:self.contentCard];

    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = 16.0;
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

    [self.contentCard addSubview:self.imageView];
    [self.contentCard addSubview:self.titleLabel];
    [self.contentCard addSubview:self.descLabel];
    [self.contentCard addSubview:self.commentHeader];
    [self.contentCard addSubview:self.tableView];

    // 底部工具栏：评论输入 + 点赞 / 收藏 / 评论数
    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.backgroundColor = [UIColor secondarySystemBackgroundColor];
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
    // 使用系统默认键盘，完整支持中文输入
    self.inputTextView.keyboardType = UIKeyboardTypeDefault;
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

    [self.contentCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView.mas_top).offset(16.0);
        make.left.equalTo(contentView.mas_left).offset(16.0);
        make.right.equalTo(contentView.mas_right).offset(-16.0);
        make.bottom.equalTo(contentView.mas_bottom).offset(-padding);
    }];

    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentCard.mas_top).offset(14.0);
        make.left.equalTo(self.contentCard.mas_left).offset(14.0);
        make.right.equalTo(self.contentCard.mas_right).offset(-14.0);
        make.height.equalTo(self.imageView.mas_width).multipliedBy(0.95);
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
        self.tableHeightConstraint = make.height.mas_equalTo(1.0);
        make.bottom.equalTo(self.contentCard.mas_bottom).offset(-padding);
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
        NSString *titleText = [self.post.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *descText = [self.post.desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (titleText.length == 0) {
            titleText = @"未命名内容";
        }

        self.titleLabel.text = titleText;
        self.descLabel.text = descText;

        if (self.post.imageURLString.length > 0) {
            NSURL *url = [NSURL URLWithString:self.post.imageURLString];
            [self.imageView sd_setImageWithURL:url
                              placeholderImage:self.post.image
                                       options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages
                                     completed:nil];
        } else {
            self.imageView.image = self.post.image;
        }
    }

    BOOL hasLikedValue = NO;
    BOOL hasCollectedValue = NO;
    self.isLiked = [self cachedBoolStatusForPrefix:kYALLikedStatusCachePrefix hasValue:&hasLikedValue];
    self.isCollected = [self cachedBoolStatusForPrefix:kYALCollectedStatusCachePrefix hasValue:&hasCollectedValue];
    self.favoriteCount = MAX(self.favoriteCount, 0);
    self.favoriteCountLabel.text = @"0";
    [self updateActionButtonsAppearance];
    [self updateBottomBarForEditing:NO animated:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.contentCard.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.contentCard.bounds cornerRadius:22.0].CGPath;
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
    self.favoriteCount = 0;
    self.favoriteCountLabel.text = @"0";
    self.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.viewCount];
    [self.tableView reloadData];
    [self refreshTableHeight];
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
    [self animateActionButton:self.commentButton];
    CGRect headerFrameInScroll = [self.commentHeader convertRect:self.commentHeader.bounds
                                                          toView:self.scrollView];
    CGPoint offset = CGPointMake(0, MAX(0, headerFrameInScroll.origin.y - 16.0));
    [self.scrollView setContentOffset:offset animated:YES];
}

- (void)didTapLike {
    [self animateActionButton:self.likeButton];
    if (self.post.contentId == nil) {
        self.likeCount += 1;
        self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.likeCount];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] toggleLikeContentWithId:self.post.contentId completion:^(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (success) {
            BOOL previousLiked = strongSelf.isLiked;
            if ([result[@"is_liked"] respondsToSelector:@selector(boolValue)]) {
                strongSelf.isLiked = [strongSelf boolValueFromLikeStatusObject:result[@"is_liked"] fallback:previousLiked];
            } else if ([result[@"is_likeed"] respondsToSelector:@selector(boolValue)]) {
                strongSelf.isLiked = [strongSelf boolValueFromLikeStatusObject:result[@"is_likeed"] fallback:previousLiked];
            } else {
                strongSelf.isLiked = !previousLiked;
            }
            NSInteger likeCount = [result[@"like_count"] respondsToSelector:@selector(integerValue)] ? [result[@"like_count"] integerValue] : MAX(0, strongSelf.likeCount + (strongSelf.isLiked ? 1 : -1));
            strongSelf.likeCount = likeCount;
            strongSelf.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)strongSelf.likeCount];
            [strongSelf persistBoolStatus:strongSelf.isLiked prefix:kYALLikedStatusCachePrefix];
            [strongSelf updateActionButtonsAppearance];
        } else {
            NSLog(@"❌ 点赞失败: %@", error.localizedDescription);
        }
    }];
}

- (void)didTapFavorite {
    [self animateActionButton:self.favoriteButton];
    if (self.post.contentId == nil) {
        self.favoriteCountLabel.text = @"0";
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] toggleCollectContentWithId:self.post.contentId completion:^(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (success) {
            strongSelf.isCollected = [result[@"is_collected"] respondsToSelector:@selector(boolValue)] ? [result[@"is_collected"] boolValue] : !strongSelf.isCollected;
            id favoriteObj = result[@"favorite_count"];
            if (![favoriteObj respondsToSelector:@selector(integerValue)]) {
                favoriteObj = result[@"collect_count"];
            }
            if ([favoriteObj respondsToSelector:@selector(integerValue)]) {
                strongSelf.favoriteCount = [favoriteObj integerValue];
            } else {
                strongSelf.favoriteCount = MAX(strongSelf.favoriteCount, 0);
            }
            strongSelf.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(strongSelf.favoriteCount, 0)];
            [strongSelf persistBoolStatus:strongSelf.isCollected prefix:kYALCollectedStatusCachePrefix];
            [strongSelf updateActionButtonsAppearance];
        } else {
            NSLog(@"❌ 收藏失败: %@", error.localizedDescription);
        }
    }];
}

- (void)animateActionButton:(UIButton *)button {
    [UIView animateWithDuration:0.12 animations:^{
        button.transform = CGAffineTransformMakeScale(0.84, 0.84);
    } completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:0.20
                              delay:0
             usingSpringWithDamping:0.52
              initialSpringVelocity:3.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            button.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
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
        // 再多抬一点，确保整个输入框完全露出
        CGFloat desiredGap = [self targetInputHeightForEditing:self.inputExpanded] * 0.55;
        keyboardGap = MIN(32.0, MAX(20.0, desiredGap));
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

    if (self.post.contentId == nil) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] publishCommentWithContentId:self.post.contentId
                                                           content:text
                                                          parentId:@(0)
                                                        completion:^(BOOL success, NSDictionary * _Nullable comment, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (success) {
            NSString *name = [comment[@"user_nickname"] isKindOfClass:[NSString class]] ? comment[@"user_nickname"] : ([YALAuthManager sharedManager].currentUser.nickname ?: @"我");
            NSDictionary *newComment = @{
                @"name": name,
                @"content": text,
                @"time": [strongSelf displayTimeStringFromRaw:comment[@"created_at"]]
            };
            NSMutableArray *mutable = [strongSelf.comments mutableCopy] ?: [NSMutableArray array];
            [mutable insertObject:newComment atIndex:0];
            strongSelf.comments = mutable;
            strongSelf.viewCount = strongSelf.comments.count;
            strongSelf.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)strongSelf.viewCount];
            [strongSelf.expandedRows addObject:@0];
            [strongSelf.tableView reloadData];
            [strongSelf refreshTableHeight];

            strongSelf.inputTextView.text = @"";
            strongSelf.inputPlaceholderLabel.hidden = NO;
            [strongSelf updatePublishButtonState];
            [strongSelf updateBottomBarForEditing:YES animated:NO];
            [strongSelf.inputTextView resignFirstResponder];
        } else {
            NSLog(@"❌ 评论发布失败: %@", error.localizedDescription);
        }
    }];
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
        // 无论是否在编辑，都保持占据输入框的垂直中间
        make.centerY.equalTo(self.inputContainer.mas_centerY);
    }];

    // 编辑时稍微更圆一点，整体更像一颗气泡
    self.inputContainer.layer.cornerRadius = editing ? 22.0 : 20.0;
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
