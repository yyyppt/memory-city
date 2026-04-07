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

static UIImage * _Nullable YALPostDetailImageFromDataURLString(NSString *dataURL) {
    if (![dataURL isKindOfClass:[NSString class]]) return nil;
    if (![dataURL hasPrefix:@"data:image"]) return nil;
    NSRange commaRange = [dataURL rangeOfString:@","];
    if (commaRange.location == NSNotFound) return nil;
    NSString *base64Part = [dataURL substringFromIndex:commaRange.location + 1];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Part options:0];
    if (!data) return nil;
    return [UIImage imageWithData:data];
}

@interface YALPostDetailController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *imageContainerView;
@property (nonatomic, strong) UIScrollView *imageGalleryScrollView;
@property (nonatomic, strong) UIPageControl *imagePageControl;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *imageGalleryViews;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *flatComments;
@property (nonatomic, strong) NSArray<NSDictionary *> *comments;
@property (nonatomic, strong, nullable) NSDictionary *pendingInsertedComment;
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
@property (nonatomic, strong) NSMutableSet<NSNumber *> *expandedCommentIds;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *expandedReplyThreads;
@property (nonatomic, strong, nullable) NSDictionary *replyTargetComment;
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
static NSString * const kYALInteractionCachePrefix = @"YALPostDetailInteractionCache";

- (NSArray<NSString *> *)normalizedImageSourceStringsFromArray:(NSArray *)images {
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    for (id obj in images) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString *value = [(NSString *)obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (value.length > 0) {
                [result addObject:value];
            }
        }
    }
    return [result copy];
}

- (void)updateImageGalleryWithSources:(NSArray<NSString *> *)imageSources placeholder:(UIImage *)placeholder {
    for (UIImageView *imageView in self.imageGalleryViews) {
        [imageView sd_cancelCurrentImageLoad];
        [imageView removeFromSuperview];
    }
    [self.imageGalleryViews removeAllObjects];

    NSArray<NSString *> *normalizedSources = [self normalizedImageSourceStringsFromArray:imageSources];
    if (normalizedSources.count == 0 && self.post.imageURLString.length > 0) {
        normalizedSources = @[self.post.imageURLString];
    }

    if (normalizedSources.count == 0) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.image = placeholder;
        imageView.backgroundColor = [UIColor secondarySystemBackgroundColor];
        [self.imageGalleryScrollView addSubview:imageView];
        [self.imageGalleryViews addObject:imageView];
    } else {
        for (NSString *source in normalizedSources) {
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            imageView.backgroundColor = [UIColor secondarySystemBackgroundColor];
            imageView.image = placeholder;

            UIImage *embeddedImage = YALPostDetailImageFromDataURLString(source);
            if (embeddedImage) {
                imageView.image = embeddedImage;
            } else {
                NSURL *imageURL = [NSURL URLWithString:source];
                if (imageURL && imageURL.scheme.length > 0) {
                    [imageView sd_setImageWithURL:imageURL
                                 placeholderImage:placeholder
                                          options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
                }
            }

            [self.imageGalleryScrollView addSubview:imageView];
            [self.imageGalleryViews addObject:imageView];
        }
    }

    NSInteger pageCount = MAX(self.imageGalleryViews.count, 1);
    self.imagePageControl.numberOfPages = pageCount;
    self.imagePageControl.hidden = pageCount <= 1;
    self.imagePageControl.currentPage = 0;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)layoutImageGalleryIfNeeded {
    CGFloat width = CGRectGetWidth(self.imageGalleryScrollView.bounds);
    CGFloat height = CGRectGetHeight(self.imageGalleryScrollView.bounds);
    if (width <= 0 || height <= 0 || self.imageGalleryViews.count == 0) {
        return;
    }

    [self.imageGalleryViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull imageView, NSUInteger idx, __unused BOOL * _Nonnull stop) {
        imageView.frame = CGRectMake(width * idx, 0, width, height);
    }];
    self.imageGalleryScrollView.contentSize = CGSizeMake(width * self.imageGalleryViews.count, height);

    NSInteger currentPage = MIN(MAX(self.imagePageControl.currentPage, 0), MAX(self.imageGalleryViews.count - 1, 0));
    self.imageGalleryScrollView.contentOffset = CGPointMake(width * currentPage, 0);
}

- (NSString *)cacheKeyForPrefix:(NSString *)prefix {
    NSNumber *contentId = self.post.contentId;
    if (contentId == nil) {
        return nil;
    }
    NSInteger userId = [YALAuthManager sharedManager].currentUser.userId;
    if (userId > 0) {
        return [NSString stringWithFormat:@"%@_%ld_%@", prefix, (long)userId, contentId];
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

- (NSString *)interactionCacheKey {
    return [self cacheKeyForPrefix:kYALInteractionCachePrefix];
}

- (void)persistInteractionCache {
    NSString *key = [self interactionCacheKey];
    if (key.length == 0) {
        return;
    }
    NSDictionary *cache = @{
        @"like_count": @(MAX(self.likeCount, 0)),
        @"favorite_count": @(MAX(self.favoriteCount, 0)),
        @"comment_count": @(MAX(self.viewCount, 0)),
        @"is_liked": @(self.isLiked),
        @"is_collected": @(self.isCollected)
    };
    [[NSUserDefaults standardUserDefaults] setObject:cache forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applyCachedInteractionIfAvailable {
    NSString *key = [self interactionCacheKey];
    if (key.length == 0) {
        return;
    }
    NSDictionary *cache = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (![cache isKindOfClass:[NSDictionary class]]) {
        return;
    }
    id likeObj = cache[@"like_count"];
    if ([likeObj respondsToSelector:@selector(integerValue)]) {
        self.likeCount = MAX([likeObj integerValue], 0);
    }
    id favoriteObj = cache[@"favorite_count"];
    if ([favoriteObj respondsToSelector:@selector(integerValue)]) {
        self.favoriteCount = MAX([favoriteObj integerValue], 0);
    }
    id commentObj = cache[@"comment_count"];
    if ([commentObj respondsToSelector:@selector(integerValue)]) {
        self.viewCount = MAX([commentObj integerValue], 0);
    }
    if ([cache[@"is_liked"] respondsToSelector:@selector(boolValue)]) {
        self.isLiked = [self boolValueFromLikeStatusObject:cache[@"is_liked"] fallback:self.isLiked];
    }
    if ([cache[@"is_collected"] respondsToSelector:@selector(boolValue)]) {
        self.isCollected = [self boolValueFromLikeStatusObject:cache[@"is_collected"] fallback:self.isCollected];
    }
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
        NSString *lower = [text lowercaseString];
        if ([lower isEqualToString:@"true"] || [lower isEqualToString:@"yes"]) {
            return YES;
        }
        if ([lower isEqualToString:@"false"] || [lower isEqualToString:@"no"]) {
            return NO;
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

- (nullable NSString *)firstNonEmptyStringFromDictionary:(NSDictionary *)dict keys:(NSArray<NSString *> *)keys {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (text.length > 0) {
                return text;
            }
        }
    }
    return nil;
}

- (NSArray<NSDictionary *> *)flattenCommentTree:(NSArray *)comments {
    return [self flattenCommentTree:comments replyTargetName:nil];
}

- (NSArray<NSDictionary *> *)flattenCommentTree:(NSArray *)comments replyTargetName:(nullable NSString *)replyTargetName {
    NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
    for (id obj in comments) {
        if (![obj isKindOfClass:[NSDictionary class]]) { continue; }
        NSDictionary *item = (NSDictionary *)obj;
        NSDictionary *userInfo = [item[@"user"] isKindOfClass:[NSDictionary class]] ? item[@"user"] : nil;
        NSDictionary *userInfo2 = [item[@"user_info"] isKindOfClass:[NSDictionary class]] ? item[@"user_info"] : nil;
        NSDictionary *userInfo3 = [item[@"author"] isKindOfClass:[NSDictionary class]] ? item[@"author"] : nil;
        NSDictionary *userInfo4 = [item[@"comment_user"] isKindOfClass:[NSDictionary class]] ? item[@"comment_user"] : nil;
        NSString *name = [self firstNonEmptyStringFromDictionary:item
                                                            keys:@[@"user_nickname", @"nickname", @"user_name", @"username", @"name", @"author_name"]];
        if (name.length == 0) {
            name = [self firstNonEmptyStringFromDictionary:userInfo
                                                      keys:@[@"nickname", @"user_nickname", @"user_name", @"username", @"name", @"author_name"]];
        }
        if (name.length == 0) {
            name = [self firstNonEmptyStringFromDictionary:userInfo2
                                                      keys:@[@"nickname", @"user_nickname", @"user_name", @"username", @"name", @"author_name"]];
        }
        if (name.length == 0) {
            name = [self firstNonEmptyStringFromDictionary:userInfo3
                                                      keys:@[@"nickname", @"user_nickname", @"user_name", @"username", @"name", @"author_name"]];
        }
        if (name.length == 0) {
            name = [self firstNonEmptyStringFromDictionary:userInfo4
                                                      keys:@[@"nickname", @"user_nickname", @"user_name", @"username", @"name", @"author_name"]];
        }
        if (name.length == 0) {
            name = @"匿名用户";
        }
        NSString *content = [item[@"content"] isKindOfClass:[NSString class]] ? item[@"content"] : @"";
        NSString *time = [self displayTimeStringFromRaw:item[@"created_at"]];
        NSString *avatar = [self firstNonEmptyStringFromDictionary:item
                                                              keys:@[@"user_avatar", @"avatar", @"avatar_url", @"userAvatar", @"author_avatar"]];
        if (avatar.length == 0) {
            avatar = [self firstNonEmptyStringFromDictionary:userInfo
                                                        keys:@[@"avatar", @"avatar_url", @"user_avatar", @"userAvatar", @"author_avatar"]];
        }
        if (avatar.length == 0) {
            avatar = [self firstNonEmptyStringFromDictionary:userInfo2
                                                        keys:@[@"avatar", @"avatar_url", @"user_avatar", @"userAvatar", @"author_avatar"]];
        }
        if (avatar.length == 0) {
            avatar = [self firstNonEmptyStringFromDictionary:userInfo3
                                                        keys:@[@"avatar", @"avatar_url", @"user_avatar", @"userAvatar", @"author_avatar"]];
        }
        if (avatar.length == 0) {
            avatar = [self firstNonEmptyStringFromDictionary:userInfo4
                                                        keys:@[@"avatar", @"avatar_url", @"user_avatar", @"userAvatar", @"author_avatar"]];
        }
        NSMutableDictionary *commentDict = [@{
            @"name": name,
            @"content": content,
            @"time": time
        } mutableCopy];
        id commentId = item[@"comment_id"];
        if ([commentId respondsToSelector:@selector(integerValue)]) {
            commentDict[@"comment_id"] = @([commentId integerValue]);
        }
        id parentId = item[@"parent_id"];
        if (![parentId respondsToSelector:@selector(integerValue)]) {
            parentId = item[@"ParentID"];
        }
        if ([parentId respondsToSelector:@selector(integerValue)]) {
            commentDict[@"parent_id"] = @([parentId integerValue]);
        }
        if (replyTargetName.length > 0) {
            commentDict[@"reply_to_name"] = replyTargetName;
        }
        if (avatar.length > 0) {
            commentDict[@"avatar"] = avatar;
        }
        [result addObject:[commentDict copy]];

        NSArray *replies = [item[@"replies"] isKindOfClass:[NSArray class]] ? item[@"replies"] : nil;
        if (replies.count > 0) {
            [result addObjectsFromArray:[self flattenCommentTree:replies replyTargetName:name]];
        }
    }
    return result;
}

- (NSArray<NSDictionary *> *)normalizedCommentsForDisplayFromFlatComments:(NSArray<NSDictionary *> *)flatComments {
    if (flatComments.count == 0) {
        return @[];
    }

    NSMutableDictionary<NSNumber *, NSDictionary *> *commentMap = [NSMutableDictionary dictionary];
    for (NSDictionary *comment in flatComments) {
        id commentId = comment[@"comment_id"];
        if ([commentId respondsToSelector:@selector(integerValue)]) {
            commentMap[@([commentId integerValue])] = comment;
        }
    }

    NSMutableArray<NSDictionary *> *normalized = [NSMutableArray arrayWithCapacity:flatComments.count];
    for (NSDictionary *comment in flatComments) {
        NSMutableDictionary *mutableComment = [comment mutableCopy];
        NSNumber *rootCommentId = [comment[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([comment[@"comment_id"] integerValue]) : nil;
        id parentId = comment[@"parent_id"];
        if ([parentId respondsToSelector:@selector(integerValue)]) {
            NSInteger parentValue = [parentId integerValue];
            if (parentValue > 0) {
                NSDictionary *parentComment = commentMap[@(parentValue)];
                NSString *parentName = [parentComment[@"name"] isKindOfClass:[NSString class]] ? parentComment[@"name"] : nil;
                if (parentName.length > 0) {
                    mutableComment[@"reply_to_name"] = parentName;
                }
                NSNumber *parentRootId = [parentComment[@"root_comment_id"] respondsToSelector:@selector(integerValue)] ? @([parentComment[@"root_comment_id"] integerValue]) : nil;
                rootCommentId = parentRootId ?: @(parentValue);
            }
        }
        if (rootCommentId) {
            mutableComment[@"root_comment_id"] = rootCommentId;
        }
        [normalized addObject:[mutableComment copy]];
    }
    return normalized;
}

- (NSArray<NSDictionary *> *)displayRowsFromFlatComments:(NSArray<NSDictionary *> *)flatComments {
    if (flatComments.count == 0) {
        return @[];
    }

    NSMutableDictionary<NSNumber *, NSDictionary *> *commentMap = [NSMutableDictionary dictionary];
    for (NSDictionary *comment in flatComments) {
        id commentId = comment[@"comment_id"];
        if ([commentId respondsToSelector:@selector(integerValue)]) {
            commentMap[@([commentId integerValue])] = comment;
        }
    }

    NSMutableArray<NSDictionary *> *rootComments = [NSMutableArray array];
    NSMutableDictionary<NSNumber *, NSMutableArray<NSDictionary *> *> *repliesByRootId = [NSMutableDictionary dictionary];

    for (NSDictionary *comment in flatComments) {
        NSNumber *commentId = [comment[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([comment[@"comment_id"] integerValue]) : nil;
        NSInteger parentId = [comment[@"parent_id"] respondsToSelector:@selector(integerValue)] ? [comment[@"parent_id"] integerValue] : 0;
        if (parentId <= 0 || commentId == nil) {
            [rootComments addObject:comment];
            continue;
        }

        NSNumber *rootId = @(parentId);
        NSMutableSet<NSNumber *> *visited = [NSMutableSet set];
        while (rootId && ![visited containsObject:rootId]) {
            [visited addObject:rootId];
            NSDictionary *parentComment = commentMap[rootId];
            NSInteger nextParentId = [parentComment[@"parent_id"] respondsToSelector:@selector(integerValue)] ? [parentComment[@"parent_id"] integerValue] : 0;
            if (nextParentId <= 0) {
                break;
            }
            rootId = @(nextParentId);
        }

        if (rootId) {
            if (!repliesByRootId[rootId]) {
                repliesByRootId[rootId] = [NSMutableArray array];
            }
            [repliesByRootId[rootId] addObject:comment];
        }
    }

    [rootComments sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        NSString *time1 = [obj1[@"time"] isKindOfClass:[NSString class]] ? obj1[@"time"] : @"";
        NSString *time2 = [obj2[@"time"] isKindOfClass:[NSString class]] ? obj2[@"time"] : @"";
        return [time2 compare:time1];
    }];

    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    for (NSDictionary *rootComment in rootComments) {
        [rows addObject:@{
            @"row_type": @"comment",
            @"comment": rootComment,
            @"is_reply": @NO
        }];

        NSNumber *rootId = [rootComment[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([rootComment[@"comment_id"] integerValue]) : nil;
        NSArray<NSDictionary *> *replies = rootId ? repliesByRootId[rootId] : nil;
        if (replies.count == 0) {
            continue;
        }

        replies = [replies sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSString *time1 = [obj1[@"time"] isKindOfClass:[NSString class]] ? obj1[@"time"] : @"";
            NSString *time2 = [obj2[@"time"] isKindOfClass:[NSString class]] ? obj2[@"time"] : @"";
            return [time1 compare:time2];
        }];

        BOOL expandedThread = rootId ? [self.expandedReplyThreads containsObject:rootId] : NO;
        NSInteger defaultVisibleCount = 0;
        NSInteger visibleCount = expandedThread ? replies.count : MIN(defaultVisibleCount, replies.count);
        for (NSInteger i = 0; i < visibleCount; i++) {
            [rows addObject:@{
                @"row_type": @"comment",
                @"comment": replies[i],
                @"is_reply": @YES
            }];
        }

        if (replies.count > defaultVisibleCount) {
            NSString *title = expandedThread ? @"收起回复" : [NSString stringWithFormat:@"展开 %ld 条回复", (long)(replies.count - defaultVisibleCount)];
            [rows addObject:@{
                @"row_type": @"toggle",
                @"root_comment_id": rootId ?: @(0),
                @"title": title
            }];
        }
    }

    return rows;
}

- (void)beginReplyToComment:(NSDictionary *)comment {
    if (![comment isKindOfClass:[NSDictionary class]]) {
        return;
    }
    self.replyTargetComment = comment;
    NSString *name = [comment[@"name"] isKindOfClass:[NSString class]] ? comment[@"name"] : @"Ta";
    self.inputPlaceholderLabel.text = [NSString stringWithFormat:@"回复 %@...", name];
    [self.inputTextView becomeFirstResponder];
}

- (void)resetReplyTargetIfNeededPreservingText:(BOOL)preserveText {
    if (preserveText && self.inputTextView.text.length > 0) {
        return;
    }
    self.replyTargetComment = nil;
    self.inputPlaceholderLabel.text = @"说点什么...";
}

- (CGFloat)calculatedCommentsHeight {
    if (self.comments.count == 0) {
        return 1.0;
    }
    CGFloat totalHeight = 0;
    for (NSInteger i = 0; i < self.comments.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        totalHeight += [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
    }
    return MAX(totalHeight, 1.0);
}

- (void)refreshTableHeight {
    if (self.tableView.window == nil) {
        return;
    }
    [self.tableView layoutIfNeeded];
    CGFloat height = [self calculatedCommentsHeight];
    self.tableHeightConstraint.offset = MAX(height, 1.0);
    [self.contentView layoutIfNeeded];
    [self.scrollView layoutIfNeeded];
    [self.view layoutIfNeeded];
    CGFloat contentHeight = CGRectGetMaxY(self.contentCard.frame);
    UIEdgeInsets adjustedInset = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        adjustedInset = self.scrollView.adjustedContentInset;
    }
    CGFloat visibleHeight = CGRectGetHeight(self.scrollView.bounds) - adjustedInset.top - adjustedInset.bottom;
    visibleHeight = MAX(visibleHeight, 0.0);
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds), MAX(contentHeight, visibleHeight));
    BOOL canScroll = (contentHeight > visibleHeight + 0.5);
    self.scrollView.alwaysBounceVertical = canScroll;
    self.scrollView.bounces = canScroll;
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
    if (![favoriteObj respondsToSelector:@selector(integerValue)]) {
        favoriteObj = content[@"collected_count"];
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
    if (!hasLikedValue && [content[@"is_like"] respondsToSelector:@selector(boolValue)]) {
        self.isLiked = [self boolValueFromLikeStatusObject:content[@"is_like"] fallback:self.isLiked];
        hasLikedValue = YES;
    }
    if (!hasLikedValue && [content[@"liked"] respondsToSelector:@selector(boolValue)]) {
        self.isLiked = [self boolValueFromLikeStatusObject:content[@"liked"] fallback:self.isLiked];
        hasLikedValue = YES;
    }
    id collectedStatusObj = content[@"is_collected"];
    if (![collectedStatusObj respondsToSelector:@selector(boolValue)]) {
        collectedStatusObj = content[@"is_collect"];
    }
    if (![collectedStatusObj respondsToSelector:@selector(boolValue)]) {
        collectedStatusObj = content[@"collected"];
    }
    if (![collectedStatusObj respondsToSelector:@selector(boolValue)]) {
        collectedStatusObj = content[@"collect_status"];
    }
    if ([collectedStatusObj respondsToSelector:@selector(boolValue)]) {
        self.isCollected = [self boolValueFromLikeStatusObject:collectedStatusObj fallback:self.isCollected];
        hasCollectedValue = YES;
    }
    // 详情页状态尽量以后端返回为准，仅在后端未返回时才使用本地缓存兜底
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
    [self persistInteractionCache];

    NSArray *images = nil;
    if ([content[@"images"] isKindOfClass:[NSArray class]]) {
        images = content[@"images"];
    } else if ([content[@"Images"] isKindOfClass:[NSArray class]]) {
        images = content[@"Images"];
    }
    NSArray<NSString *> *normalizedImages = [self normalizedImageSourceStringsFromArray:images];
    if (normalizedImages.count > 0) {
        self.post.imageURLString = normalizedImages.firstObject;
        self.post.images = normalizedImages;
        [self updateImageGalleryWithSources:normalizedImages placeholder:self.post.image];
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
            NSArray<NSDictionary *> *flatComments = [strongSelf flattenCommentTree:(comments ?: @[])];
            NSMutableArray<NSDictionary *> *normalized = [[strongSelf normalizedCommentsForDisplayFromFlatComments:flatComments] mutableCopy];
            NSNumber *pendingCommentId = [strongSelf.pendingInsertedComment[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([strongSelf.pendingInsertedComment[@"comment_id"] integerValue]) : nil;
            BOOL containsPending = NO;
            if (pendingCommentId) {
                for (NSDictionary *item in normalized) {
                    if ([item[@"comment_id"] respondsToSelector:@selector(integerValue)] &&
                        [@([item[@"comment_id"] integerValue]) isEqualToNumber:pendingCommentId]) {
                        containsPending = YES;
                        break;
                    }
                }
            }
            if (strongSelf.pendingInsertedComment && !containsPending) {
                [normalized addObject:strongSelf.pendingInsertedComment];
            }
            strongSelf.flatComments = [normalized copy];
            strongSelf.comments = [strongSelf displayRowsFromFlatComments:strongSelf.flatComments];
            strongSelf.viewCount = strongSelf.flatComments.count;
            strongSelf.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)strongSelf.viewCount];
            [strongSelf persistInteractionCache];
            [strongSelf.tableView reloadData];
            [strongSelf refreshTableHeight];
            if (containsPending) {
                strongSelf.pendingInsertedComment = nil;
            }
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

    self.expandedCommentIds = [NSMutableSet set];
    self.expandedReplyThreads = [NSMutableSet set];
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
    self.scrollView.alwaysBounceVertical = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 13.0, *)) {
        self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    }
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    self.contentCard = [[UIView alloc] init];
    self.contentCard.backgroundColor = [UIColor colorWithRed:0.995 green:0.985 blue:0.965 alpha:1.0];
    self.contentCard.layer.cornerRadius = 22.0;
    self.contentCard.layer.masksToBounds = NO;
    self.contentCard.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.10].CGColor;
    self.contentCard.layer.shadowOpacity = 1.0;
    self.contentCard.layer.shadowOffset = CGSizeMake(0, 10);
    self.contentCard.layer.shadowRadius = 20.0;
    [self.contentView addSubview:self.contentCard];

    self.imageContainerView = [[UIView alloc] init];
    self.imageContainerView.layer.cornerRadius = 16.0;
    self.imageContainerView.layer.masksToBounds = YES;
    self.imageContainerView.backgroundColor = [UIColor secondarySystemBackgroundColor];

    self.imageGalleryScrollView = [[UIScrollView alloc] init];
    self.imageGalleryScrollView.pagingEnabled = YES;
    self.imageGalleryScrollView.showsHorizontalScrollIndicator = NO;
    self.imageGalleryScrollView.delegate = self;
    self.imageGalleryScrollView.backgroundColor = [UIColor secondarySystemBackgroundColor];

    self.imagePageControl = [[UIPageControl alloc] init];
    self.imagePageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.96 green:0.73 blue:0.20 alpha:1.0];
    self.imagePageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1.0 alpha:0.45];
    self.imagePageControl.hidesForSinglePage = YES;
    self.imageGalleryViews = [NSMutableArray array];

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
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView registerClass:[YALCommentCell class] forCellReuseIdentifier:@"YALCommentCell"];

    [self.contentCard addSubview:self.imageContainerView];
    [self.imageContainerView addSubview:self.imageGalleryScrollView];
    [self.imageContainerView addSubview:self.imagePageControl];
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

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    CGFloat padding = 16.0;

    [self.contentCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(16.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-padding);
    }];

    [self.imageContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentCard.mas_top).offset(14.0);
        make.left.equalTo(self.contentCard.mas_left).offset(14.0);
        make.right.equalTo(self.contentCard.mas_right).offset(-14.0);
        make.height.equalTo(self.imageContainerView.mas_width).multipliedBy(0.95);
    }];

    [self.imageGalleryScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.imageContainerView);
    }];

    [self.imagePageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.imageContainerView.mas_centerX);
        make.bottom.equalTo(self.imageContainerView.mas_bottom).offset(-8.0);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageContainerView.mas_bottom).offset(12.0);
        make.left.right.equalTo(self.imageContainerView);
    }];

    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(6.0);
        make.left.right.equalTo(self.imageContainerView);
    }];

    [self.commentHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descLabel.mas_bottom).offset(16.0);
        make.left.right.equalTo(self.imageContainerView);
        make.height.mas_equalTo(22.0);
    }];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.commentHeader.mas_bottom).offset(8.0);
        make.left.right.equalTo(self.imageContainerView);
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

        [self updateImageGalleryWithSources:self.post.images placeholder:self.post.image];

        self.likeCount = MAX(self.post.likeCount, 0);
        self.favoriteCount = MAX(self.post.collectCount, 0);
        self.viewCount = MAX(self.post.commentCount, 0);
        self.isLiked = self.post.isLiked;
        self.isCollected = self.post.isCollected;
    }

    [self applyCachedInteractionIfAvailable];
    self.likeCount = MAX(self.likeCount, 0);
    self.favoriteCount = MAX(self.favoriteCount, 0);
    self.viewCount = MAX(self.viewCount, 0);
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.likeCount];
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.favoriteCount];
    self.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.viewCount];
    [self updateActionButtonsAppearance];
    [self persistInteractionCache];
    [self updateBottomBarForEditing:NO animated:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.view.window && self.comments.count > 0) {
        self.tableHeightConstraint.offset = MAX([self calculatedCommentsHeight], 1.0);
    }
    [self.view layoutIfNeeded];
    [self layoutImageGalleryIfNeeded];
    self.contentCard.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.contentCard.bounds cornerRadius:22.0].CGPath;
    CGFloat contentHeight = CGRectGetMaxY(self.contentCard.frame);
    UIEdgeInsets adjustedInset = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        adjustedInset = self.scrollView.adjustedContentInset;
    }
    CGFloat visibleHeight = CGRectGetHeight(self.scrollView.bounds) - adjustedInset.top - adjustedInset.bottom;
    visibleHeight = MAX(visibleHeight, 0.0);
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds), MAX(contentHeight, visibleHeight));
    BOOL canScroll = (contentHeight > visibleHeight + 0.5);
    self.scrollView.alwaysBounceVertical = canScroll;
    self.scrollView.bounces = canScroll;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.imageGalleryScrollView) {
        return;
    }
    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0) {
        return;
    }
    NSInteger currentPage = (NSInteger)lround(scrollView.contentOffset.x / width);
    currentPage = MIN(MAX(currentPage, 0), MAX(self.imageGalleryViews.count - 1, 0));
    self.imagePageControl.currentPage = currentPage;
}

- (void)setupDummyComments {
    // 避免先展示假数据造成数值闪动，初始统一置空，等待接口回填
    self.flatComments = @[];
    self.comments = @[];
    [self.tableView reloadData];
    [self updateBottomBarForEditing:self.inputExpanded animated:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *row = self.comments[indexPath.row];
    NSString *rowType = [row[@"row_type"] isKindOfClass:[NSString class]] ? row[@"row_type"] : @"comment";
    if ([rowType isEqualToString:@"toggle"]) {
        static NSString *toggleCellId = @"YALCommentToggleCell";
        UITableViewCell *toggleCell = [tableView dequeueReusableCellWithIdentifier:toggleCellId];
        if (!toggleCell) {
            toggleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:toggleCellId];
            toggleCell.selectionStyle = UITableViewCellSelectionStyleNone;
            toggleCell.backgroundColor = [UIColor clearColor];
            UILabel *toggleLabel = [[UILabel alloc] init];
            toggleLabel.tag = 1001;
            toggleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
            toggleLabel.textColor = [UIColor colorWithRed:0.82 green:0.58 blue:0.18 alpha:1.0];
            toggleLabel.numberOfLines = 1;
            [toggleCell.contentView addSubview:toggleLabel];
            [toggleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(toggleCell.contentView.mas_left).offset(56.0);
                make.centerY.equalTo(toggleCell.contentView.mas_centerY);
                make.right.lessThanOrEqualTo(toggleCell.contentView.mas_right).offset(-12.0);
            }];
        }
        UILabel *toggleLabel = [toggleCell.contentView viewWithTag:1001];
        if ([toggleLabel isKindOfClass:[UILabel class]]) {
            toggleLabel.text = [row[@"title"] isKindOfClass:[NSString class]] ? row[@"title"] : @"展开回复";
        }
        toggleCell.separatorInset = UIEdgeInsetsMake(0, 999, 0, 0);
        return toggleCell;
    }

    YALCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YALCommentCell"];
    if (!cell) {
        cell = [[YALCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"YALCommentCell"];
    }

    NSDictionary *comment = [row[@"comment"] isKindOfClass:[NSDictionary class]] ? row[@"comment"] : @{};
    NSNumber *commentId = [comment[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([comment[@"comment_id"] integerValue]) : nil;
    BOOL expanded = commentId ? [self.expandedCommentIds containsObject:commentId] : NO;

    UIImage *avatar;
    if (@available(iOS 13.0, *)) {
        avatar = [UIImage systemImageNamed:@"person.circle.fill"];
    } else {
        avatar = [[UIImage alloc] init];
    }
    NSString *avatarURLString = [comment[@"avatar"] isKindOfClass:[NSString class]] ? comment[@"avatar"] : nil;
    UIImage *decodedAvatar = avatarURLString.length > 0 ? YALPostDetailImageFromDataURLString(avatarURLString) : nil;
    if (decodedAvatar) {
        avatar = decodedAvatar;
        avatarURLString = nil;
    }

    __weak typeof(self) weakSelf = self;
    cell.toggleExpandBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (!commentId) { return; }
        if ([strongSelf.expandedCommentIds containsObject:commentId]) {
            [strongSelf.expandedCommentIds removeObject:commentId];
        } else {
            [strongSelf.expandedCommentIds addObject:commentId];
        }
        [strongSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf refreshTableHeight];
        });
    };

    [cell configureWithAvatar:avatar
              avatarURLString:avatarURLString
                         name:comment[@"name"]
                      content:[self displayContentForComment:comment]
                         time:comment[@"time"]
                      isReply:[row[@"is_reply"] boolValue]
                     expanded:expanded];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    static YALCommentCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [[YALCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    });

    NSDictionary *row = self.comments[indexPath.row];
    NSString *rowType = [row[@"row_type"] isKindOfClass:[NSString class]] ? row[@"row_type"] : @"comment";
    if ([rowType isEqualToString:@"toggle"]) {
        return 40.0;
    }

    NSDictionary *comment = [row[@"comment"] isKindOfClass:[NSDictionary class]] ? row[@"comment"] : @{};
    NSNumber *commentId = [comment[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([comment[@"comment_id"] integerValue]) : nil;
    BOOL expanded = commentId ? [self.expandedCommentIds containsObject:commentId] : NO;
    UIImage *avatar = [[UIImage alloc] init];
    [sizingCell configureWithAvatar:avatar
                    avatarURLString:nil
                               name:comment[@"name"]
                            content:[self displayContentForComment:comment]
                               time:comment[@"time"]
                            isReply:[row[@"is_reply"] boolValue]
                           expanded:expanded];

    CGFloat width = CGRectGetWidth(tableView.bounds);
    sizingCell.bounds = CGRectMake(0, 0, width, CGFLOAT_MAX);
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];

    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return MAX(60.0, size.height);
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= self.comments.count) {
        return;
    }
    NSDictionary *row = self.comments[indexPath.row];
    NSString *rowType = [row[@"row_type"] isKindOfClass:[NSString class]] ? row[@"row_type"] : @"comment";
    if ([rowType isEqualToString:@"toggle"]) {
        NSNumber *rootCommentId = [row[@"root_comment_id"] respondsToSelector:@selector(integerValue)] ? @([row[@"root_comment_id"] integerValue]) : nil;
        if (rootCommentId) {
            if ([self.expandedReplyThreads containsObject:rootCommentId]) {
                [self.expandedReplyThreads removeObject:rootCommentId];
            } else {
                [self.expandedReplyThreads addObject:rootCommentId];
            }
            self.comments = [self displayRowsFromFlatComments:self.flatComments];
            [self.tableView reloadData];
            [self refreshTableHeight];
        }
        return;
    }
    NSDictionary *comment = [row[@"comment"] isKindOfClass:[NSDictionary class]] ? row[@"comment"] : nil;
    [self beginReplyToComment:comment];
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
    [self scrollToCommentSectionIfNeededAnimated:YES];
}

- (void)scrollToCommentSectionIfNeededAnimated:(BOOL)animated {
    if (self.comments.count == 0) {
        return;
    }
    [self.view layoutIfNeeded];
    CGRect headerFrameInScroll = [self.commentHeader convertRect:self.commentHeader.bounds toView:self.scrollView];
    CGFloat targetY = MAX(0, headerFrameInScroll.origin.y - 12.0);
    UIEdgeInsets adjustedInset = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        adjustedInset = self.scrollView.adjustedContentInset;
    } else {
        adjustedInset = self.scrollView.contentInset;
    }
    CGFloat maxOffsetY = MAX(0, self.scrollView.contentSize.height - CGRectGetHeight(self.scrollView.bounds) + adjustedInset.bottom);
    CGPoint offset = CGPointMake(0, MIN(targetY, maxOffsetY));
    [self.scrollView setContentOffset:offset animated:animated];
}

- (void)didTapLike {
    [self animateActionButton:self.likeButton];
    if (self.post.contentId == nil) {
        self.likeCount += 1;
        self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.likeCount];
        return;
    }

    BOOL previousLiked = self.isLiked;
    NSInteger previousLikeCount = self.likeCount;
    self.isLiked = !previousLiked;
    self.likeCount = MAX(0, previousLikeCount + (self.isLiked ? 1 : -1));
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.likeCount];
    [self persistBoolStatus:self.isLiked prefix:kYALLikedStatusCachePrefix];
    [self updateActionButtonsAppearance];
    [self persistInteractionCache];

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] toggleLikeContentWithId:self.post.contentId completion:^(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (success) {
            BOOL optimisticLiked = strongSelf.isLiked;
            if ([result[@"is_liked"] respondsToSelector:@selector(boolValue)]) {
                strongSelf.isLiked = [strongSelf boolValueFromLikeStatusObject:result[@"is_liked"] fallback:optimisticLiked];
            } else if ([result[@"is_likeed"] respondsToSelector:@selector(boolValue)]) {
                strongSelf.isLiked = [strongSelf boolValueFromLikeStatusObject:result[@"is_likeed"] fallback:optimisticLiked];
            }
            if ([result[@"like_count"] respondsToSelector:@selector(integerValue)]) {
                strongSelf.likeCount = MAX(0, [result[@"like_count"] integerValue]);
            } else if (strongSelf.isLiked != optimisticLiked) {
                strongSelf.likeCount = MAX(0, previousLikeCount + (strongSelf.isLiked ? 1 : -1));
            }
            strongSelf.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)strongSelf.likeCount];
            [strongSelf persistBoolStatus:strongSelf.isLiked prefix:kYALLikedStatusCachePrefix];
            [strongSelf updateActionButtonsAppearance];
            [strongSelf persistInteractionCache];
            [strongSelf loadContentDetailIfNeeded];
        } else {
            NSLog(@"❌ 点赞失败: %@", error.localizedDescription);
            strongSelf.isLiked = previousLiked;
            strongSelf.likeCount = previousLikeCount;
            strongSelf.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)strongSelf.likeCount];
            [strongSelf persistBoolStatus:strongSelf.isLiked prefix:kYALLikedStatusCachePrefix];
            [strongSelf updateActionButtonsAppearance];
            [strongSelf persistInteractionCache];
        }
    }];
}

- (void)didTapFavorite {
    [self animateActionButton:self.favoriteButton];
    if (self.post.contentId == nil) {
        self.favoriteCountLabel.text = @"0";
        return;
    }

    BOOL previousCollected = self.isCollected;
    NSInteger previousFavoriteCount = self.favoriteCount;
    self.isCollected = !previousCollected;
    self.favoriteCount = MAX(0, previousFavoriteCount + (self.isCollected ? 1 : -1));
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.favoriteCount];
    [self persistBoolStatus:self.isCollected prefix:kYALCollectedStatusCachePrefix];
    [self updateActionButtonsAppearance];
    [self persistInteractionCache];

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] toggleCollectContentWithId:self.post.contentId completion:^(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (success) {
            BOOL optimisticCollected = strongSelf.isCollected;
            id collectedStatusObj = result[@"is_collected"];
            if (![collectedStatusObj respondsToSelector:@selector(boolValue)]) {
                collectedStatusObj = result[@"is_collect"];
            }
            if (![collectedStatusObj respondsToSelector:@selector(boolValue)]) {
                collectedStatusObj = result[@"collected"];
            }
            if (![collectedStatusObj respondsToSelector:@selector(boolValue)]) {
                collectedStatusObj = result[@"collect_status"];
            }
            strongSelf.isCollected = [collectedStatusObj respondsToSelector:@selector(boolValue)] ? [strongSelf boolValueFromLikeStatusObject:collectedStatusObj fallback:optimisticCollected] : optimisticCollected;
            id favoriteObj = result[@"favorite_count"];
            if (![favoriteObj respondsToSelector:@selector(integerValue)]) {
                favoriteObj = result[@"collect_count"];
            }
            if (![favoriteObj respondsToSelector:@selector(integerValue)]) {
                favoriteObj = result[@"collected_count"];
            }
            if ([favoriteObj respondsToSelector:@selector(integerValue)]) {
                strongSelf.favoriteCount = MAX(0, [favoriteObj integerValue]);
            } else {
                strongSelf.favoriteCount = MAX(0, previousFavoriteCount + (strongSelf.isCollected ? 1 : -1));
            }
            strongSelf.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(strongSelf.favoriteCount, 0)];
            [strongSelf persistBoolStatus:strongSelf.isCollected prefix:kYALCollectedStatusCachePrefix];
            [strongSelf updateActionButtonsAppearance];
            [strongSelf persistInteractionCache];
        } else {
            NSLog(@"❌ 收藏失败: %@", error.localizedDescription);
            strongSelf.isCollected = previousCollected;
            strongSelf.favoriteCount = previousFavoriteCount;
            strongSelf.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(strongSelf.favoriteCount, 0)];
            [strongSelf persistBoolStatus:strongSelf.isCollected prefix:kYALCollectedStatusCachePrefix];
            [strongSelf updateActionButtonsAppearance];
            [strongSelf persistInteractionCache];
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
    [self resetReplyTargetIfNeededPreservingText:NO];
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
    // 键盘弹起时同步把页面滚到评论区，避免只有输入栏上移、正文不动。
    if (keyboardHeightInView > 0 && self.inputTextView.isFirstResponder) {
        [self scrollToCommentSectionIfNeededAnimated:NO];
    }
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    (void)textView;
    [self updateBottomBarForEditing:YES animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self updateBottomBarForEditing:NO animated:YES];
    [self resetReplyTargetIfNeededPreservingText:YES];
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

    NSNumber *parentId = @(0);
    if ([self.replyTargetComment[@"comment_id"] respondsToSelector:@selector(integerValue)]) {
        parentId = @([self.replyTargetComment[@"comment_id"] integerValue]);
    }

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] publishCommentWithContentId:self.post.contentId
                                                           content:text
                                                          parentId:parentId
                                                        completion:^(BOOL success, NSDictionary * _Nullable comment, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (success) {
            NSNumber *rootCommentId = [strongSelf.replyTargetComment[@"root_comment_id"] respondsToSelector:@selector(integerValue)] ? @([strongSelf.replyTargetComment[@"root_comment_id"] integerValue]) : nil;
            if (!rootCommentId && [strongSelf.replyTargetComment[@"comment_id"] respondsToSelector:@selector(integerValue)]) {
                rootCommentId = @([strongSelf.replyTargetComment[@"comment_id"] integerValue]);
            }
            if (rootCommentId.integerValue > 0) {
                [strongSelf.expandedReplyThreads addObject:rootCommentId];
            }
            NSString *name = [comment[@"user_nickname"] isKindOfClass:[NSString class]] ? comment[@"user_nickname"] : nil;
            if (name.length == 0 && [comment[@"user"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *user = (NSDictionary *)comment[@"user"];
                name = [user[@"nickname"] isKindOfClass:[NSString class]] ? user[@"nickname"] : nil;
            }
            NSString *avatar = @"";
            if ([comment[@"user"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *user = (NSDictionary *)comment[@"user"];
                avatar = [user[@"avatar"] isKindOfClass:[NSString class]] ? user[@"avatar"] : @"";
            }
            NSMutableDictionary *pendingComment = [@{
                @"comment_id": [comment[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([comment[@"comment_id"] integerValue]) : @(0),
                @"parent_id": [comment[@"ParentID"] respondsToSelector:@selector(integerValue)] ? @([comment[@"ParentID"] integerValue]) : parentId,
                @"root_comment_id": rootCommentId ?: @(0),
                @"name": name.length > 0 ? name : ([YALAuthManager sharedManager].currentUser.nickname ?: @"我"),
                @"content": text,
                @"time": [strongSelf displayTimeStringFromRaw:comment[@"created_at"]],
                @"reply_to_name": [strongSelf.replyTargetComment[@"name"] isKindOfClass:[NSString class]] ? strongSelf.replyTargetComment[@"name"] : @""
            } mutableCopy];
            if (avatar.length > 0) {
                pendingComment[@"avatar"] = avatar;
            }
            strongSelf.pendingInsertedComment = [pendingComment copy];
            strongSelf.inputTextView.text = @"";
            strongSelf.inputPlaceholderLabel.hidden = NO;
            [strongSelf resetReplyTargetIfNeededPreservingText:NO];
            [strongSelf updatePublishButtonState];
            [strongSelf updateBottomBarForEditing:YES animated:NO];
            [strongSelf.inputTextView resignFirstResponder];
            [strongSelf loadComments];
        } else {
            NSLog(@"❌ 评论发布失败: %@", error.localizedDescription);
        }
    }];
}

- (NSString *)displayContentForComment:(NSDictionary *)comment {
    NSString *content = [comment[@"content"] isKindOfClass:[NSString class]] ? comment[@"content"] : @"";
    NSString *replyToName = [comment[@"reply_to_name"] isKindOfClass:[NSString class]] ? comment[@"reply_to_name"] : @"";
    if (replyToName.length > 0) {
        return [NSString stringWithFormat:@"回复 %@：%@", replyToName, content];
    }
    return content;
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
