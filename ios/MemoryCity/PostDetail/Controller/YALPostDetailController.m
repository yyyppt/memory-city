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
#import <objc/runtime.h>
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

static const void *kYALAuthorWorkModelKey = &kYALAuthorWorkModelKey;

@interface YALAuthorProfileController : UIViewController

@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic, copy, nullable) NSString *prefilledNickname;
@property (nonatomic, copy, nullable) NSString *prefilledAvatar;
@property (nonatomic, copy, nullable) NSString *prefilledBio;

@end

@interface YALAuthorProfileController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *headerCard;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UILabel *joinDateLabel;
@property (nonatomic, strong) UIView *statsCard;
@property (nonatomic, strong) UILabel *publishedValueLabel;
@property (nonatomic, strong) UILabel *likesValueLabel;
@property (nonatomic, strong) UILabel *identityLabel;
@property (nonatomic, strong) UIView *worksCard;
@property (nonatomic, strong) UILabel *worksTitleLabel;
@property (nonatomic, strong) UILabel *worksHintLabel;
@property (nonatomic, strong) UIView *worksGridContainer;
@property (nonatomic, strong) UIStackView *worksRowsStack;
@property (nonatomic, strong) NSArray<YALPostModel *> *publicWorks;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) BOOL isFetchingPublicStatsFallback;

@end

@implementation YALAuthorProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"作者主页";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self setupViews];
    [self applyPrefilledValues];
    [self fetchProfile];
}

- (void)setupViews {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    self.headerCard = [[UIView alloc] init];
    self.headerCard.backgroundColor = [UIColor colorWithRed:0.995 green:0.985 blue:0.965 alpha:1.0];
    self.headerCard.layer.cornerRadius = 24.0;
    self.headerCard.layer.masksToBounds = YES;
    [self.contentView addSubview:self.headerCard];

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.avatarView.layer.cornerRadius = 38.0;
    self.avatarView.layer.masksToBounds = YES;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    if (@available(iOS 13.0, *)) {
        self.avatarView.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
        self.avatarView.tintColor = [UIColor systemGray2Color];
    }
    [self.headerCard addSubview:self.avatarView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.nameLabel.textColor = [UIColor labelColor];
    self.nameLabel.text = @"作者";
    [self.headerCard addSubview:self.nameLabel];

    self.joinDateLabel = [[UILabel alloc] init];
    self.joinDateLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.joinDateLabel.textColor = [UIColor secondaryLabelColor];
    self.joinDateLabel.text = @"正在加载主页信息";
    [self.headerCard addSubview:self.joinDateLabel];

    self.bioLabel = [[UILabel alloc] init];
    self.bioLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.bioLabel.textColor = [UIColor secondaryLabelColor];
    self.bioLabel.numberOfLines = 0;
    self.bioLabel.text = @"这个作者还没有留下个签。";
    [self.headerCard addSubview:self.bioLabel];

    self.statsCard = [[UIView alloc] init];
    self.statsCard.backgroundColor = [UIColor systemBackgroundColor];
    self.statsCard.layer.cornerRadius = 20.0;
    self.statsCard.layer.masksToBounds = YES;
    [self.contentView addSubview:self.statsCard];

    self.publishedValueLabel = [self statValueLabelWithText:@"--"];
    self.likesValueLabel = [self statValueLabelWithText:@"--"];
    self.identityLabel = [self statValueLabelWithText:@"访客"];
    [self.statsCard addSubview:self.publishedValueLabel];
    [self.statsCard addSubview:self.likesValueLabel];
    [self.statsCard addSubview:self.identityLabel];

    NSArray<UILabel *> *titles = @[
        [self statTitleLabelWithText:@"公开作品"],
        [self statTitleLabelWithText:@"累计获赞"],
        [self statTitleLabelWithText:@"主页类型"]
    ];
    for (UILabel *label in titles) {
        [self.statsCard addSubview:label];
    }

    [self.publishedValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statsCard.mas_top).offset(18.0);
        make.left.equalTo(self.statsCard.mas_left).offset(18.0);
    }];
    [titles[0] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.publishedValueLabel.mas_bottom).offset(4.0);
        make.left.equalTo(self.publishedValueLabel);
        make.bottom.equalTo(self.statsCard.mas_bottom).offset(-18.0);
    }];

    [self.likesValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.publishedValueLabel);
        make.centerX.equalTo(self.statsCard.mas_centerX);
    }];
    [titles[1] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.likesValueLabel.mas_bottom).offset(4.0);
        make.centerX.equalTo(self.likesValueLabel.mas_centerX);
        make.bottom.equalTo(self.statsCard.mas_bottom).offset(-18.0);
    }];

    [self.identityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.publishedValueLabel);
        make.right.equalTo(self.statsCard.mas_right).offset(-18.0);
    }];
    [titles[2] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.identityLabel.mas_bottom).offset(4.0);
        make.centerX.equalTo(self.identityLabel.mas_centerX);
        make.bottom.equalTo(self.statsCard.mas_bottom).offset(-18.0);
    }];

    self.worksCard = [[UIView alloc] init];
    self.worksCard.backgroundColor = [UIColor systemBackgroundColor];
    self.worksCard.layer.cornerRadius = 20.0;
    self.worksCard.layer.masksToBounds = YES;
    [self.contentView addSubview:self.worksCard];

    self.worksTitleLabel = [[UILabel alloc] init];
    self.worksTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.worksTitleLabel.textColor = [UIColor labelColor];
    self.worksTitleLabel.text = @"公开内容";
    [self.worksCard addSubview:self.worksTitleLabel];

    self.worksHintLabel = [[UILabel alloc] init];
    self.worksHintLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.worksHintLabel.textColor = [UIColor secondaryLabelColor];
    self.worksHintLabel.numberOfLines = 0;
    self.worksHintLabel.text = @"作者主页资料已接入。等你补上作者公开内容接口后，这里就能直接展示 Ta 的发布列表。";
    [self.worksCard addSubview:self.worksHintLabel];

    self.worksGridContainer = [[UIView alloc] init];
    self.worksGridContainer.hidden = YES;
    [self.worksCard addSubview:self.worksGridContainer];

    self.worksRowsStack = [[UIStackView alloc] init];
    self.worksRowsStack.axis = UILayoutConstraintAxisVertical;
    self.worksRowsStack.spacing = 10.0;
    self.worksRowsStack.distribution = UIStackViewDistributionFill;
    [self.worksGridContainer addSubview:self.worksRowsStack];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];
    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(18.0);
    }];

    [self.headerCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(18.0);
        make.left.equalTo(self.contentView.mas_left).offset(16.0);
        make.right.equalTo(self.contentView.mas_right).offset(-16.0);
    }];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerCard.mas_top).offset(20.0);
        make.left.equalTo(self.headerCard.mas_left).offset(18.0);
        make.width.height.mas_equalTo(76.0);
    }];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView.mas_top).offset(4.0);
        make.left.equalTo(self.avatarView.mas_right).offset(14.0);
        make.right.equalTo(self.headerCard.mas_right).offset(-18.0);
    }];
    [self.joinDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(6.0);
        make.left.equalTo(self.nameLabel);
        make.right.equalTo(self.nameLabel);
    }];
    [self.bioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView.mas_bottom).offset(16.0);
        make.left.equalTo(self.headerCard.mas_left).offset(18.0);
        make.right.equalTo(self.headerCard.mas_right).offset(-18.0);
        make.bottom.equalTo(self.headerCard.mas_bottom).offset(-20.0);
    }];

    [self.statsCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerCard.mas_bottom).offset(14.0);
        make.left.right.equalTo(self.headerCard);
    }];

    [self.worksCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statsCard.mas_bottom).offset(14.0);
        make.left.right.equalTo(self.headerCard);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-24.0);
    }];
    [self.worksTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.worksCard.mas_top).offset(18.0);
        make.left.equalTo(self.worksCard.mas_left).offset(18.0);
        make.right.equalTo(self.worksCard.mas_right).offset(-18.0);
    }];
    [self.worksHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.worksTitleLabel.mas_bottom).offset(12.0);
        make.left.equalTo(self.worksCard.mas_left).offset(18.0);
        make.right.equalTo(self.worksCard.mas_right).offset(-18.0);
        make.bottom.equalTo(self.worksCard.mas_bottom).offset(-18.0);
    }];
    [self.worksGridContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.worksTitleLabel.mas_bottom).offset(12.0);
        make.left.equalTo(self.worksCard.mas_left).offset(18.0);
        make.right.equalTo(self.worksCard.mas_right).offset(-18.0);
        make.bottom.equalTo(self.worksCard.mas_bottom).offset(-18.0);
    }];
    [self.worksRowsStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.worksGridContainer);
    }];
}

- (UILabel *)statValueLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:21 weight:UIFontWeightBold];
    label.textColor = [UIColor labelColor];
    label.text = text;
    return label;
}

- (UILabel *)statTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    label.textColor = [UIColor secondaryLabelColor];
    label.text = text;
    return label;
}

- (void)applyPrefilledValues {
    if (self.prefilledNickname.length > 0) {
        self.nameLabel.text = self.prefilledNickname;
    }
    if (self.prefilledBio.length > 0) {
        self.bioLabel.text = self.prefilledBio;
    }
    if (self.prefilledAvatar.length > 0) {
        UIImage *decodedImage = YALPostDetailImageFromDataURLString(self.prefilledAvatar);
        if (decodedImage) {
            self.avatarView.image = decodedImage;
        } else {
            NSURL *avatarURL = [NSURL URLWithString:self.prefilledAvatar];
            if (avatarURL && avatarURL.scheme.length > 0) {
                [self.avatarView sd_setImageWithURL:avatarURL
                                   placeholderImage:self.avatarView.image
                                            options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
            }
        }
    }
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

- (nullable NSNumber *)firstPositiveNumberFromDictionary:(NSDictionary *)dict keys:(NSArray<NSString *> *)keys {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value respondsToSelector:@selector(integerValue)]) {
            NSInteger integerValue = [value integerValue];
            if (integerValue > 0) {
                return @(integerValue);
            }
        }
    }
    return nil;
}

- (nullable NSString *)firstNonEmptyStringRecursivelyFromObject:(id)obj keys:(NSArray<NSString *> *)keys {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSString *direct = [self firstNonEmptyStringFromDictionary:(NSDictionary *)obj keys:keys];
        if (direct.length > 0) {
            return direct;
        }
        for (id value in [(NSDictionary *)obj allValues]) {
            NSString *nested = [self firstNonEmptyStringRecursivelyFromObject:value keys:keys];
            if (nested.length > 0) {
                return nested;
            }
        }
    } else if ([obj isKindOfClass:[NSArray class]]) {
        for (id value in (NSArray *)obj) {
            NSString *nested = [self firstNonEmptyStringRecursivelyFromObject:value keys:keys];
            if (nested.length > 0) {
                return nested;
            }
        }
    }
    return nil;
}

- (nullable NSNumber *)firstPositiveNumberRecursivelyFromObject:(id)obj keys:(NSArray<NSString *> *)keys {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSNumber *direct = [self firstPositiveNumberFromDictionary:(NSDictionary *)obj keys:keys];
        if (direct.integerValue > 0) {
            return direct;
        }
        for (id value in [(NSDictionary *)obj allValues]) {
            NSNumber *nested = [self firstPositiveNumberRecursivelyFromObject:value keys:keys];
            if (nested.integerValue > 0) {
                return nested;
            }
        }
    } else if ([obj isKindOfClass:[NSArray class]]) {
        for (id value in (NSArray *)obj) {
            NSNumber *nested = [self firstPositiveNumberRecursivelyFromObject:value keys:keys];
            if (nested.integerValue > 0) {
                return nested;
            }
        }
    }
    return nil;
}

- (NSInteger)integerValueFromObject:(id)value fallback:(NSInteger)fallback {
    if ([value respondsToSelector:@selector(integerValue)]) {
        return [value integerValue];
    }
    return fallback;
}

- (BOOL)boolValueFromObject:(id)value fallback:(BOOL)fallback {
    if ([value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue];
    }
    return fallback;
}

- (void)fetchPublicStatsFromContentListWithCompletion:(void (^)(BOOL success, NSInteger publishedCount, NSInteger likeTotal))completion {
    if (self.userId.integerValue <= 0) {
        if (completion) {
            completion(NO, 0, 0);
        }
        return;
    }

    __block NSInteger page = 1;
    NSInteger const pageSize = 50;
    NSInteger const maxPages = 20;
    __block NSInteger publishedCount = 0;
    __block NSInteger likeTotal = 0;
    __block BOOL didFetchAnyPage = NO;

    __weak typeof(self) weakSelf = self;
    __block void (^fetchNextPage)(void) = ^{
        if (page > maxPages) {
            if (completion) {
                completion(didFetchAnyPage, publishedCount, likeTotal);
            }
            return;
        }

        [[YALContentManager sharedManager] getAllContentListWithPage:page
                                                            pageSize:pageSize
                                                          completion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            (void)message;
            (void)error;

            if (!success || ![contentList isKindOfClass:[NSArray class]]) {
                if (completion) {
                    completion(didFetchAnyPage, publishedCount, likeTotal);
                }
                return;
            }

            didFetchAnyPage = YES;
            for (id item in contentList) {
                if (![item isKindOfClass:[YALPostModel class]]) {
                    continue;
                }
                YALPostModel *model = (YALPostModel *)item;
                if (!model.isPublic) {
                    continue;
                }
                if (model.authorUserId.integerValue != strongSelf.userId.integerValue) {
                    continue;
                }
                publishedCount += 1;
                likeTotal += MAX(model.likeCount, 0);
            }

            if (contentList.count < pageSize) {
                if (completion) {
                    completion(YES, publishedCount, likeTotal);
                }
                return;
            }

            page += 1;
            fetchNextPage();
        }];
    };

    fetchNextPage();
}

- (void)fetchPublicStatsFallbackIfNeededForMissingPublished:(BOOL)needPublished
                                                missingLikes:(BOOL)needLikes {
    if ((!needPublished && !needLikes) || self.isFetchingPublicStatsFallback) {
        return;
    }
    self.isFetchingPublicStatsFallback = YES;

    __weak typeof(self) weakSelf = self;
    [self fetchPublicStatsFromContentListWithCompletion:^(BOOL success, NSInteger publishedCount, NSInteger likeTotal) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.isFetchingPublicStatsFallback = NO;
            if (!success) {
                return;
            }
            if (needPublished) {
                strongSelf.publishedValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(publishedCount, 0)];
            }
            if (needLikes) {
                strongSelf.likesValueLabel.text = [NSString stringWithFormat:@"%ld", (long)MAX(likeTotal, 0)];
            }
        });
    }];
}

- (nullable NSDate *)dateFromRawString:(NSString *)raw {
    if (![raw isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *trimmed = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }
    if (@available(iOS 10.0, *)) {
        NSISO8601DateFormatter *isoFormatter = [[NSISO8601DateFormatter alloc] init];
        isoFormatter.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
        NSDate *isoDate = [isoFormatter dateFromString:trimmed];
        if (!isoDate) {
            isoFormatter.formatOptions = NSISO8601DateFormatWithInternetDateTime;
            isoDate = [isoFormatter dateFromString:trimmed];
        }
        if (isoDate) {
            return isoDate;
        }
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    NSDate *date = [formatter dateFromString:trimmed];
    if (date) {
        return date;
    }
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    date = [formatter dateFromString:trimmed];
    if (date) {
        return date;
    }
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    date = [formatter dateFromString:trimmed];
    if (date) {
        return date;
    }
    formatter.dateFormat = @"yyyy-MM-dd";
    return [formatter dateFromString:trimmed];
}

- (NSString *)displayDateTextFromRaw:(NSString *)raw fallback:(NSString *)fallback {
    NSDate *date = [self dateFromRawString:raw];
    if (!date) {
        if (raw.length >= 10) {
            return [raw substringToIndex:10];
        }
        return fallback;
    }
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    outputFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    outputFormatter.dateFormat = @"yyyy-MM-dd";
    return [outputFormatter stringFromDate:date];
}

- (UIView *)workCardViewForModel:(YALPostModel *)model {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 12.0;
    card.layer.masksToBounds = YES;

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.backgroundColor = [UIColor tertiarySystemFillColor];
    [card addSubview:imageView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.numberOfLines = 1;
    titleLabel.text = model.title.length > 0 ? model.title : @"未命名内容";
    [card addSubview:titleLabel];

    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    timeLabel.textColor = [UIColor secondaryLabelColor];
    timeLabel.text = [self displayDateTextFromRaw:model.createTime fallback:@"刚刚发布"];
    [card addSubview:timeLabel];

    UIImage *placeholder = nil;
    if (@available(iOS 13.0, *)) {
        placeholder = [UIImage systemImageNamed:@"photo"];
    } else {
        placeholder = [[UIImage alloc] init];
    }
    NSString *imageURL = model.imageURLString;
    if (imageURL.length == 0 && model.images.count > 0) {
        imageURL = model.images.firstObject;
    }
    UIImage *embeddedImage = imageURL.length > 0 ? YALPostDetailImageFromDataURLString(imageURL) : nil;
    if (embeddedImage) {
        imageView.image = embeddedImage;
    } else {
        NSURL *url = [NSURL URLWithString:imageURL ?: @""];
        if (url && url.scheme.length > 0) {
            [imageView sd_setImageWithURL:url
                         placeholderImage:placeholder
                                  options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
        } else {
            imageView.image = placeholder;
        }
    }

    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(card);
        make.height.equalTo(imageView.mas_width).multipliedBy(0.72);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imageView.mas_bottom).offset(6.0);
        make.left.equalTo(card.mas_left).offset(8.0);
        make.right.equalTo(card.mas_right).offset(-8.0);
    }];
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(3.0);
        make.left.equalTo(titleLabel);
        make.right.equalTo(titleLabel);
        make.bottom.equalTo(card.mas_bottom).offset(-8.0);
    }];

    UIButton *tapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tapButton.backgroundColor = [UIColor clearColor];
    [tapButton addTarget:self action:@selector(didTapAuthorWorkCard:) forControlEvents:UIControlEventTouchUpInside];
    objc_setAssociatedObject(tapButton, kYALAuthorWorkModelKey, model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [card addSubview:tapButton];
    [tapButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card);
    }];

    return card;
}

- (void)renderPublicWorksPreview:(NSArray<YALPostModel *> *)works {
    self.publicWorks = [works copy];
    for (UIView *arranged in [self.worksRowsStack.arrangedSubviews copy]) {
        [self.worksRowsStack removeArrangedSubview:arranged];
        [arranged removeFromSuperview];
    }

    if (works.count == 0) {
        self.worksTitleLabel.text = @"公开内容";
        self.worksGridContainer.hidden = YES;
        self.worksHintLabel.hidden = NO;
        self.worksHintLabel.text = @"暂时还没有公开内容。";
        return;
    }

    self.worksTitleLabel.text = [NSString stringWithFormat:@"公开内容 %lu", (unsigned long)works.count];
    self.worksHintLabel.hidden = YES;
    self.worksHintLabel.text = @"";
    self.worksGridContainer.hidden = NO;

    NSInteger maxCount = works.count;
    for (NSInteger i = 0; i < maxCount; i += 2) {
        UIStackView *rowStack = [[UIStackView alloc] init];
        rowStack.axis = UILayoutConstraintAxisHorizontal;
        rowStack.spacing = 10.0;
        rowStack.distribution = UIStackViewDistributionFillEqually;

        UIView *leftCard = [self workCardViewForModel:works[i]];
        [rowStack addArrangedSubview:leftCard];

        if (i + 1 < maxCount) {
            UIView *rightCard = [self workCardViewForModel:works[i + 1]];
            [rowStack addArrangedSubview:rightCard];
        } else {
            UIView *placeholder = [[UIView alloc] init];
            placeholder.backgroundColor = [UIColor clearColor];
            [rowStack addArrangedSubview:placeholder];
        }

        [self.worksRowsStack addArrangedSubview:rowStack];
    }
}

- (void)didTapAuthorWorkCard:(UIButton *)sender {
    YALPostModel *model = objc_getAssociatedObject(sender, kYALAuthorWorkModelKey);
    if (![model isKindOfClass:[YALPostModel class]]) {
        return;
    }
    YALPostDetailController *detail = [[YALPostDetailController alloc] init];
    detail.post = model;
    detail.openedFromAuthorProfile = YES;
    detail.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detail animated:YES];
}

- (void)fetchPublicWorksPreview {
    if (self.userId.integerValue <= 0) {
        return;
    }

    __block NSInteger page = 1;
    NSInteger const pageSize = 30;
    NSInteger const maxPages = 12;
    NSMutableArray<YALPostModel *> *matchedWorks = [NSMutableArray array];

    __weak typeof(self) weakSelf = self;
    __block void (^fetchNextPage)(void) = ^{
        if (page > maxPages) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                [strongSelf renderPublicWorksPreview:[matchedWorks copy]];
            });
            return;
        }

        [[YALContentManager sharedManager] getAllContentListWithPage:page
                                                            pageSize:pageSize
                                                          completion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            (void)message;
            (void)error;
            if (!success || ![contentList isKindOfClass:[NSArray class]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf renderPublicWorksPreview:[matchedWorks copy]];
                });
                return;
            }

            for (id item in contentList) {
                if (![item isKindOfClass:[YALPostModel class]]) {
                    continue;
                }
                YALPostModel *model = (YALPostModel *)item;
                if (!model.isPublic) {
                    continue;
                }
                if (model.authorUserId.integerValue != strongSelf.userId.integerValue) {
                    continue;
                }
                [matchedWorks addObject:model];
            }

            if (contentList.count < pageSize) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf renderPublicWorksPreview:[matchedWorks copy]];
                });
                return;
            }

            page += 1;
            fetchNextPage();
        }];
    };

    fetchNextPage();
}

- (void)fetchProfile {
    if (self.userId.integerValue <= 0) {
        self.joinDateLabel.text = @"缺少作者ID，暂时无法拉取主页";
        return;
    }

    [self.loadingIndicator startAnimating];
    __weak typeof(self) weakSelf = self;
    [[YALAuthManager sharedManager] fetchUserProfileWithUserId:self.userId completion:^(NSDictionary * _Nullable profile, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.loadingIndicator stopAnimating];
            if (![profile isKindOfClass:[NSDictionary class]]) {
                strongSelf.joinDateLabel.text = error.localizedDescription.length > 0 ? error.localizedDescription : @"主页信息加载失败";
                [strongSelf fetchPublicStatsFallbackIfNeededForMissingPublished:YES missingLikes:YES];
                return;
            }

            NSString *nickname = [strongSelf firstNonEmptyStringFromDictionary:profile keys:@[@"nickname", @"user_nickname", @"name"]];
            if (nickname.length > 0) {
                strongSelf.nameLabel.text = nickname;
            }

            NSString *bio = [strongSelf firstNonEmptyStringFromDictionary:profile keys:@[@"bio", @"signature", @"intro"]];
            strongSelf.bioLabel.text = bio.length > 0 ? bio : @"这个作者还没有留下个签。";

            NSString *avatar = [strongSelf firstNonEmptyStringFromDictionary:profile keys:@[@"avatar", @"user_avatar", @"avatar_url"]];
            if (avatar.length > 0) {
                UIImage *decodedImage = YALPostDetailImageFromDataURLString(avatar);
                if (decodedImage) {
                    strongSelf.avatarView.image = decodedImage;
                } else {
                    NSURL *avatarURL = [NSURL URLWithString:avatar];
                    if (avatarURL && avatarURL.scheme.length > 0) {
                        [strongSelf.avatarView sd_setImageWithURL:avatarURL
                                                  placeholderImage:strongSelf.avatarView.image
                                                           options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
                    }
                }
            }

            NSString *createTime = [strongSelf firstNonEmptyStringFromDictionary:profile keys:@[@"create_time", @"created_at", @"join_time"]];
            NSString *joinDateText = [strongSelf displayDateTextFromRaw:createTime fallback:@""];
            strongSelf.joinDateLabel.text = joinDateText.length > 0 ? [NSString stringWithFormat:@"加入于 %@", joinDateText] : @"主页资料已加载";

            id publishedCountObj = profile[@"public_content_count"];
            if (![publishedCountObj respondsToSelector:@selector(integerValue)]) {
                publishedCountObj = profile[@"content_count"];
            }
            BOOL hasPublishedCount = [publishedCountObj respondsToSelector:@selector(integerValue)];
            NSInteger publishedCount = hasPublishedCount ? MAX([publishedCountObj integerValue], 0) : 0;

            id likeTotalObj = profile[@"like_total"];
            if (![likeTotalObj respondsToSelector:@selector(integerValue)]) {
                likeTotalObj = profile[@"likes_total"];
            }
            BOOL hasLikeTotal = [likeTotalObj respondsToSelector:@selector(integerValue)];
            NSInteger likeTotal = hasLikeTotal ? MAX([likeTotalObj integerValue], 0) : 0;
            BOOL isSelf = [strongSelf boolValueFromObject:profile[@"is_self"] fallback:([YALAuthManager sharedManager].currentUser.userId > 0 && [YALAuthManager sharedManager].currentUser.userId == strongSelf.userId.integerValue)];

            strongSelf.publishedValueLabel.text = hasPublishedCount ? [NSString stringWithFormat:@"%ld", (long)publishedCount] : @"--";
            strongSelf.likesValueLabel.text = hasLikeTotal ? [NSString stringWithFormat:@"%ld", (long)likeTotal] : @"--";
            strongSelf.identityLabel.text = isSelf ? @"我自己" : @"作者";
            strongSelf.worksHintLabel.hidden = NO;
            strongSelf.worksHintLabel.text = @"正在加载公开内容...";
            strongSelf.worksGridContainer.hidden = YES;

            [strongSelf fetchPublicStatsFallbackIfNeededForMissingPublished:!hasPublishedCount
                                                                missingLikes:!hasLikeTotal];
            [strongSelf fetchPublicWorksPreview];
        });
    }];
}

@end

@interface YALPostDetailController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *imageContainerView;
@property (nonatomic, strong) UIScrollView *imageGalleryScrollView;
@property (nonatomic, strong) UIPageControl *imagePageControl;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *imageGalleryViews;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *flatComments;
@property (nonatomic, strong) NSArray<NSDictionary *> *comments;
@property (nonatomic, strong, nullable) NSDictionary *pendingInsertedComment;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIView *bottomBarContentView;
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
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *visibleReplyCountByRoot;
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
@property (nonatomic, strong, nullable) NSNumber *authorUserId;
@property (nonatomic, copy, nullable) NSString *authorNickname;
@property (nonatomic, copy, nullable) NSString *authorAvatar;
@property (nonatomic, copy, nullable) NSString *authorBio;

@end

@implementation YALPostDetailController

static NSString * const kYALLikedStatusCachePrefix = @"YALPostDetailLikedStatus";
static NSString * const kYALCollectedStatusCachePrefix = @"YALPostDetailCollectedStatus";
static NSString * const kYALInteractionCachePrefix = @"YALPostDetailInteractionCache";
static NSInteger const kYALReplyExpandStep = 3;
static const void *kYALToggleRootIdKey = &kYALToggleRootIdKey;
static const void *kYALToggleTotalCountKey = &kYALToggleTotalCountKey;
static const void *kYALToggleVisibleCountKey = &kYALToggleVisibleCountKey;

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

- (nullable NSNumber *)firstPositiveNumberFromDictionary:(NSDictionary *)dict keys:(NSArray<NSString *> *)keys {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value respondsToSelector:@selector(integerValue)]) {
            NSInteger integerValue = [value integerValue];
            if (integerValue > 0) {
                return @(integerValue);
            }
        }
    }
    return nil;
}

- (nullable NSString *)firstNonEmptyStringRecursivelyFromObject:(id)obj keys:(NSArray<NSString *> *)keys {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSString *direct = [self firstNonEmptyStringFromDictionary:(NSDictionary *)obj keys:keys];
        if (direct.length > 0) {
            return direct;
        }
        for (id value in [(NSDictionary *)obj allValues]) {
            NSString *nested = [self firstNonEmptyStringRecursivelyFromObject:value keys:keys];
            if (nested.length > 0) {
                return nested;
            }
        }
    } else if ([obj isKindOfClass:[NSArray class]]) {
        for (id value in (NSArray *)obj) {
            NSString *nested = [self firstNonEmptyStringRecursivelyFromObject:value keys:keys];
            if (nested.length > 0) {
                return nested;
            }
        }
    }
    return nil;
}

- (nullable NSNumber *)firstPositiveNumberRecursivelyFromObject:(id)obj keys:(NSArray<NSString *> *)keys {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSNumber *direct = [self firstPositiveNumberFromDictionary:(NSDictionary *)obj keys:keys];
        if (direct.integerValue > 0) {
            return direct;
        }
        for (id value in [(NSDictionary *)obj allValues]) {
            NSNumber *nested = [self firstPositiveNumberRecursivelyFromObject:value keys:keys];
            if (nested.integerValue > 0) {
                return nested;
            }
        }
    } else if ([obj isKindOfClass:[NSArray class]]) {
        for (id value in (NSArray *)obj) {
            NSNumber *nested = [self firstPositiveNumberRecursivelyFromObject:value keys:keys];
            if (nested.integerValue > 0) {
                return nested;
            }
        }
    }
    return nil;
}

- (NSArray<NSDictionary *> *)flattenCommentTree:(NSArray *)comments {
    return [self flattenCommentTree:comments replyTargetName:nil depth:0];
}

- (NSArray<NSDictionary *> *)flattenCommentTree:(NSArray *)comments
                                replyTargetName:(nullable NSString *)replyTargetName
                                          depth:(NSInteger)depth {
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
            @"time": time,
            @"depth": @(MAX(depth, 0))
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
        NSNumber *userId = [self firstPositiveNumberFromDictionary:item keys:@[@"user_id", @"uid", @"userid", @"author_id"]];
        if (!userId) {
            userId = [self firstPositiveNumberFromDictionary:userInfo keys:@[@"user_id", @"uid", @"id"]];
        }
        if (!userId) {
            userId = [self firstPositiveNumberFromDictionary:userInfo2 keys:@[@"user_id", @"uid", @"id"]];
        }
        if (!userId) {
            userId = [self firstPositiveNumberFromDictionary:userInfo3 keys:@[@"user_id", @"uid", @"id"]];
        }
        if (!userId) {
            userId = [self firstPositiveNumberFromDictionary:userInfo4 keys:@[@"user_id", @"uid", @"id"]];
        }
        if (userId.integerValue > 0) {
            commentDict[@"user_id"] = userId;
        }
        if (replyTargetName.length > 0) {
            commentDict[@"reply_to_name"] = replyTargetName;
        }
        NSString *rawTime = [item[@"created_at"] isKindOfClass:[NSString class]] ? item[@"created_at"] : @"";
        if (rawTime.length > 0) {
            commentDict[@"raw_time"] = rawTime;
        }
        if (avatar.length > 0) {
            commentDict[@"avatar"] = avatar;
        }
        [result addObject:[commentDict copy]];

        NSArray *replies = [item[@"replies"] isKindOfClass:[NSArray class]] ? item[@"replies"] : nil;
        if (replies.count > 0) {
            [result addObjectsFromArray:[self flattenCommentTree:replies replyTargetName:name depth:depth + 1]];
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
                NSInteger parentDepth = [parentComment[@"depth"] respondsToSelector:@selector(integerValue)] ? [parentComment[@"depth"] integerValue] : 0;
                mutableComment[@"depth"] = @(parentDepth + 1);
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

    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    for (NSDictionary *rootComment in rootComments) {
        [rows addObject:@{
            @"row_type": @"comment",
            @"comment": rootComment,
            @"is_reply": @NO,
            @"reply_level": @0
        }];

        NSNumber *rootId = [rootComment[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([rootComment[@"comment_id"] integerValue]) : nil;
        if (rootId.integerValue <= 0) {
            rootId = nil;
        }
        NSArray<NSDictionary *> *replies = rootId ? repliesByRootId[rootId] : nil;
        if (replies.count == 0) {
            continue;
        }

        NSInteger visibleCount = rootId ? 0 : replies.count;
        if (rootId) {
            NSNumber *savedVisible = self.visibleReplyCountByRoot[rootId];
            if ([savedVisible respondsToSelector:@selector(integerValue)]) {
                visibleCount = [savedVisible integerValue];
            }
            if ([self.expandedReplyThreads containsObject:rootId]) {
                visibleCount = replies.count;
            }
        }
        visibleCount = MIN(MAX(visibleCount, 0), (NSInteger)replies.count);
        for (NSInteger i = 0; i < visibleCount; i++) {
            NSDictionary *replyComment = replies[i];
            NSInteger replyLevel = [replyComment[@"depth"] respondsToSelector:@selector(integerValue)] ? [replyComment[@"depth"] integerValue] : 1;
            // 避免首发临时评论与接口回流评论的缩进层级不一致，统一限制缩进层级
            NSInteger indentLevel = MIN(MAX(replyLevel, 1), 2);
            [rows addObject:@{
                @"row_type": @"comment",
                @"comment": replyComment,
                @"is_reply": @YES,
                @"reply_level": @(indentLevel)
            }];
        }

        if (!rootId) {
            continue;
        }

        BOOL fullyExpanded = (visibleCount >= replies.count);
        NSString *title = fullyExpanded ? @"" : @"展开回复";
        BOOL showRightCollapse = (visibleCount > 0);
        [rows addObject:@{
            @"row_type": @"toggle",
            @"root_comment_id": rootId ?: @(0),
            @"title": title ?: @"展开回复",
            @"visible_reply_count": @(visibleCount),
            @"total_reply_count": @(replies.count),
            @"show_right_collapse": @(showRightCollapse)
        }];
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

    NSLog(@"📄 详情接口回填原始数据: title=%@ location_name=%@ locationName=%@ latitude=%@ longitude=%@ raw=%@",
          content[@"title"],
          content[@"location_name"],
          content[@"locationName"],
          content[@"latitude"],
          content[@"longitude"],
          content);

    NSString *titleText = [content[@"title"] isKindOfClass:[NSString class]] ? content[@"title"] : self.post.title;
    NSString *descText = [content[@"content"] isKindOfClass:[NSString class]] ? content[@"content"] : self.post.desc;
    if (titleText.length == 0) {
        titleText = @"加载中...";
    }
    self.titleLabel.text = titleText;
    self.descLabel.text = descText.length > 0 ? descText : @"正在加载内容详情";
    NSString *locationText = [content[@"location_name"] isKindOfClass:[NSString class]] ? content[@"location_name"] : self.post.locationName;
    if (locationText.length == 0 && [content[@"locationName"] isKindOfClass:[NSString class]]) {
        locationText = content[@"locationName"];
    }
    if (locationText.length == 0 && [content[@"city"] isKindOfClass:[NSString class]]) {
        locationText = content[@"city"];
    }
    locationText = [locationText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.locationLabel.text = locationText;
    self.locationLabel.hidden = (locationText.length == 0);
    NSLog(@"📄 详情地址渲染: resolvedLocation=%@ hidden=%@", self.locationLabel.text ?: @"", self.locationLabel.hidden ? @"YES" : @"NO");

    NSDictionary *authorInfo = [content[@"user"] isKindOfClass:[NSDictionary class]] ? content[@"user"] : nil;
    if (!authorInfo) {
        authorInfo = [content[@"author"] isKindOfClass:[NSDictionary class]] ? content[@"author"] : nil;
    }
    if (!authorInfo) {
        authorInfo = [content[@"publisher"] isKindOfClass:[NSDictionary class]] ? content[@"publisher"] : nil;
    }
    if (!authorInfo) {
        authorInfo = [content[@"user_info"] isKindOfClass:[NSDictionary class]] ? content[@"user_info"] : nil;
    }
    if (!authorInfo) {
        authorInfo = [content[@"profile"] isKindOfClass:[NSDictionary class]] ? content[@"profile"] : nil;
    }
    self.authorUserId = self.post.authorUserId;
    if (!self.authorUserId) {
        self.authorUserId = [self firstPositiveNumberRecursivelyFromObject:content keys:@[@"user_id", @"author_id", @"publisher_id", @"uid", @"userid", @"id"]];
    }
    if (!self.authorUserId) {
        self.authorUserId = [self firstPositiveNumberFromDictionary:authorInfo keys:@[@"user_id", @"author_id", @"id", @"uid", @"userid"]];
    }
    self.authorNickname = self.post.authorNickname;
    if (self.authorNickname.length == 0) {
        self.authorNickname = [self firstNonEmptyStringRecursivelyFromObject:content keys:@[@"user_nickname", @"nickname", @"author_name", @"publisher_name", @"user_name", @"username", @"name"]];
    }
    if (self.authorNickname.length == 0) {
        self.authorNickname = [self firstNonEmptyStringFromDictionary:authorInfo keys:@[@"nickname", @"user_nickname", @"name", @"author_name", @"user_name", @"username"]];
    }
    self.authorAvatar = self.post.authorAvatar;
    if (self.authorAvatar.length == 0) {
        self.authorAvatar = [self firstNonEmptyStringRecursivelyFromObject:content keys:@[@"user_avatar", @"avatar", @"avatar_url", @"author_avatar"]];
    }
    if (self.authorAvatar.length == 0) {
        self.authorAvatar = [self firstNonEmptyStringFromDictionary:authorInfo keys:@[@"avatar", @"avatar_url", @"user_avatar", @"author_avatar"]];
    }
    self.authorBio = self.post.authorBio;
    if (self.authorBio.length == 0) {
        self.authorBio = [self firstNonEmptyStringRecursivelyFromObject:content keys:@[@"user_bio", @"bio", @"author_bio", @"signature", @"intro"]];
    }
    if (self.authorBio.length == 0) {
        self.authorBio = [self firstNonEmptyStringFromDictionary:authorInfo keys:@[@"bio", @"user_bio", @"signature", @"intro"]];
    }
    NSLog(@"📥 详情页解析作者信息: user_id=%@ nickname=%@", self.authorUserId, self.authorNickname ?: @"");

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
    self.visibleReplyCountByRoot = [NSMutableDictionary dictionary];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateBottomBarForEditing:self.inputExpanded animated:NO];
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
    UIColor *contentCardBackgroundColor;
    UIColor *contentCardShadowColor;
    UIColor *contentCardBorderColor;
    if (@available(iOS 13.0, *)) {
        contentCardBackgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:0.12 green:0.12 blue:0.13 alpha:1.0];
            }
            return [UIColor colorWithRed:0.995 green:0.985 blue:0.965 alpha:1.0];
        }];
        contentCardShadowColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:0.0 alpha:0.45];
            }
            return [UIColor colorWithWhite:0.0 alpha:0.10];
        }];
        contentCardBorderColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:1.0 alpha:0.16];
            }
            return [UIColor colorWithWhite:0.0 alpha:0.06];
        }];
    } else {
        contentCardBackgroundColor = [UIColor colorWithRed:0.995 green:0.985 blue:0.965 alpha:1.0];
        contentCardShadowColor = [UIColor colorWithWhite:0 alpha:0.10];
        contentCardBorderColor = [UIColor colorWithWhite:0 alpha:0.06];
    }
    self.contentCard.backgroundColor = contentCardBackgroundColor;
    self.contentCard.layer.cornerRadius = 22.0;
    self.contentCard.layer.masksToBounds = NO;
    self.contentCard.layer.shadowColor = contentCardShadowColor.CGColor;
    self.contentCard.layer.shadowOpacity = 1.0;
    self.contentCard.layer.shadowOffset = CGSizeMake(0, 10);
    self.contentCard.layer.shadowRadius = 20.0;
    self.contentCard.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    self.contentCard.layer.borderColor = contentCardBorderColor.CGColor;
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

    self.locationLabel = [[UILabel alloc] init];
    self.locationLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    self.locationLabel.textColor = [UIColor labelColor];
    self.locationLabel.numberOfLines = 1;
    self.locationLabel.textAlignment = NSTextAlignmentRight;
    self.locationLabel.hidden = YES;
    self.locationLabel.lineBreakMode = NSLineBreakByTruncatingTail;

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
    [self.contentCard addSubview:self.locationLabel];
    [self.contentCard addSubview:self.descLabel];
    [self.contentCard addSubview:self.commentHeader];
    [self.contentCard addSubview:self.tableView];

    // 底部工具栏：评论输入 + 点赞 / 收藏 / 评论数
    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBar.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [self.view addSubview:self.bottomBar];
    self.bottomBarContentView = [[UIView alloc] init];
    self.bottomBarContentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBarContentView.backgroundColor = [UIColor clearColor];
    [self.bottomBar addSubview:self.bottomBarContentView];

    // 左侧：可增长的评论输入区
    self.inputContainer = [[UIView alloc] init];
    self.inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainer.layer.cornerRadius = 20.0;
    self.inputContainer.layer.masksToBounds = YES;
    UIColor *pillBg = (@available(iOS 13.0, *)) ? [UIColor systemBackgroundColor] : [UIColor whiteColor];
    UIColor *inputBorderColor = (@available(iOS 13.0, *)) ? [UIColor separatorColor] : [UIColor lightGrayColor];
    self.inputContainer.backgroundColor = pillBg;
    self.inputContainer.layer.borderWidth = 1.0;
    self.inputContainer.layer.borderColor = inputBorderColor.CGColor;
    UIColor *placeholderColor = (@available(iOS 13.0, *)) ? [UIColor secondaryLabelColor] : [UIColor lightGrayColor];
    self.inputTextView = [[UITextView alloc] init];
    self.inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
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
    self.inputPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputPlaceholderLabel.text = @"说点什么...";
    self.inputPlaceholderLabel.font = self.inputTextView.font;
    self.inputPlaceholderLabel.textColor = placeholderColor;

    self.publishButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.publishButton.translatesAutoresizingMaskIntoConstraints = NO;
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
    [self.bottomBarContentView addSubview:self.inputContainer];

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

    [self.bottomBarContentView addSubview:self.likeButton];
    [self.bottomBarContentView addSubview:self.favoriteButton];
    [self.bottomBarContentView addSubview:self.commentButton];
    [self.bottomBarContentView addSubview:self.likeCountLabel];
    [self.bottomBarContentView addSubview:self.favoriteCountLabel];
    [self.bottomBarContentView addSubview:self.commentCountLabel];

    // Layout with Masonry
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        self.bottomBarBottomConstraint = make.bottom.equalTo(self.view.mas_bottom);
        self.bottomBarHeightConstraint = make.height.mas_equalTo([self targetBottomBarHeightForEditing:NO]);
    }];
    [self.bottomBarContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.bottomBar);
        make.bottom.equalTo(self.bottomBar.mas_safeAreaLayoutGuideBottom);
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
        make.left.equalTo(self.imageContainerView.mas_left);
        make.right.lessThanOrEqualTo(self.locationLabel.mas_left).offset(-8.0);
    }];

    [self.locationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.firstBaseline.equalTo(self.titleLabel.mas_firstBaseline);
        make.right.equalTo(self.imageContainerView.mas_right);
        make.width.lessThanOrEqualTo(self.imageContainerView.mas_width).multipliedBy(0.42);
    }];

    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10.0);
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
        make.right.equalTo(self.bottomBarContentView.mas_right).offset(-paddingBar);
        make.centerY.equalTo(self.bottomBarContentView.mas_centerY);
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
        NSLog(@"📄 进入详情页初始模型: contentId=%@ title=%@ locationName=%@ latitude=%.6f longitude=%.6f post=%@",
              self.post.contentId,
              self.post.title ?: @"",
              self.post.locationName ?: @"",
              self.post.latitude,
              self.post.longitude,
              self.post);
        self.authorUserId = self.post.authorUserId;
        self.authorNickname = self.post.authorNickname;
        self.authorAvatar = self.post.authorAvatar;
        self.authorBio = self.post.authorBio;
        NSString *titleText = [self.post.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *descText = [self.post.desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (titleText.length == 0) {
            titleText = @"加载中...";
        }

        self.titleLabel.text = titleText;
        self.descLabel.text = descText.length > 0 ? descText : @"正在加载内容详情";
        NSString *locationText = [self.post.locationName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (locationText.length == 0) {
            locationText = [self.post.city stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        self.locationLabel.text = locationText;
        self.locationLabel.hidden = (locationText.length == 0);

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

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self updateBottomBarForEditing:self.inputExpanded animated:NO];
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
    [self.expandedReplyThreads removeAllObjects];
    [self.visibleReplyCountByRoot removeAllObjects];
    [self.tableView reloadData];
    [self updateBottomBarForEditing:self.inputExpanded animated:NO];
}

- (NSNumber *)currentLoginUserId {
    YALAuthUserModel *currentUser = [YALAuthManager sharedManager].currentUser;
    if (currentUser.userId > 0) {
        return @(currentUser.userId);
    }
    return nil;
}

- (BOOL)isCommentOwnedByCurrentUser:(NSDictionary *)comment {
    NSNumber *commentUserId = [comment[@"user_id"] respondsToSelector:@selector(integerValue)] ? @([comment[@"user_id"] integerValue]) : nil;
    NSNumber *currentUserId = [self currentLoginUserId];
    if (commentUserId.integerValue > 0 && currentUserId.integerValue > 0) {
        return [commentUserId isEqualToNumber:currentUserId];
    }
    NSString *commentName = [comment[@"name"] isKindOfClass:[NSString class]] ? comment[@"name"] : @"";
    NSString *myNickname = [YALAuthManager sharedManager].currentUser.nickname ?: @"";
    return (myNickname.length > 0 && [commentName isEqualToString:myNickname]);
}

- (void)deleteComment:(NSDictionary *)comment {
    NSNumber *commentId = [comment[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([comment[@"comment_id"] integerValue]) : nil;
    if (commentId.integerValue <= 0) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] deleteCommentWithId:commentId completion:^(BOOL success, NSString *message, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSMutableArray<NSDictionary *> *filtered = [NSMutableArray array];
                for (NSDictionary *item in strongSelf.flatComments) {
                    NSNumber *itemCommentId = [item[@"comment_id"] respondsToSelector:@selector(integerValue)] ? @([item[@"comment_id"] integerValue]) : nil;
                    NSNumber *rootCommentId = [item[@"root_comment_id"] respondsToSelector:@selector(integerValue)] ? @([item[@"root_comment_id"] integerValue]) : nil;
                    NSNumber *parentId = [item[@"parent_id"] respondsToSelector:@selector(integerValue)] ? @([item[@"parent_id"] integerValue]) : nil;
                    if ([itemCommentId isEqualToNumber:commentId] ||
                        [rootCommentId isEqualToNumber:commentId] ||
                        [parentId isEqualToNumber:commentId]) {
                        continue;
                    }
                    [filtered addObject:item];
                }
                strongSelf.flatComments = [filtered copy];
                strongSelf.comments = [strongSelf displayRowsFromFlatComments:strongSelf.flatComments];
                strongSelf.viewCount = strongSelf.flatComments.count;
                strongSelf.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)strongSelf.viewCount];
                [strongSelf.tableView reloadData];
                [strongSelf refreshTableHeight];
                return;
            }
            NSString *errorText = error.localizedDescription.length > 0 ? error.localizedDescription : (message.length > 0 ? message : @"删除失败，后端可能尚未提供评论删除接口");
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除失败"
                                                                           message:errorText
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
            [strongSelf presentViewController:alert animated:YES completion:nil];
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.comments.count;
}

- (nullable UIContextMenuConfiguration *)tableView:(UITableView *)tableView
                      contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                                          point:(CGPoint)point API_AVAILABLE(ios(13.0)) {
    (void)tableView;
    (void)point;
    if (indexPath.row >= self.comments.count) {
        return nil;
    }
    NSDictionary *row = self.comments[indexPath.row];
    NSString *rowType = [row[@"row_type"] isKindOfClass:[NSString class]] ? row[@"row_type"] : @"comment";
    if (![rowType isEqualToString:@"comment"]) {
        return nil;
    }
    NSDictionary *comment = [row[@"comment"] isKindOfClass:[NSDictionary class]] ? row[@"comment"] : nil;
    if (![comment isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    if (![self isCommentOwnedByCurrentUser:comment]) {
        return nil;
    }

    __weak typeof(self) weakSelf = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                   previewProvider:nil
                                                    actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        (void)suggestedActions;
        UIAction *deleteAction = [UIAction actionWithTitle:@"删除评论"
                                                     image:[UIImage systemImageNamed:@"trash"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            (void)action;
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除这条评论？"
                                                                           message:@"删除后将无法恢复。"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"删除"
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(__unused UIAlertAction * _Nonnull action2) {
                [strongSelf deleteComment:comment];
            }]];
            [strongSelf presentViewController:alert animated:YES completion:nil];
        }];
        return [UIMenu menuWithTitle:@"" children:@[deleteAction]];
    }];
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
            UIButton *expandButton = [UIButton buttonWithType:UIButtonTypeSystem];
            expandButton.tag = 1001;
            expandButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
            [expandButton setTitleColor:[UIColor colorWithRed:0.82 green:0.58 blue:0.18 alpha:1.0] forState:UIControlStateNormal];
            expandButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            [expandButton addTarget:self action:@selector(didTapReplyExpandButton:) forControlEvents:UIControlEventTouchUpInside];
            [toggleCell.contentView addSubview:expandButton];
            [expandButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(toggleCell.contentView.mas_left).offset(56.0);
                make.centerY.equalTo(toggleCell.contentView.mas_centerY);
                make.right.lessThanOrEqualTo(toggleCell.contentView.mas_right).offset(-84.0);
            }];

            UIButton *collapseButton = [UIButton buttonWithType:UIButtonTypeSystem];
            collapseButton.tag = 1003;
            collapseButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
            [collapseButton setTitleColor:[UIColor colorWithRed:0.82 green:0.58 blue:0.18 alpha:1.0] forState:UIControlStateNormal];
            collapseButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            [collapseButton addTarget:self action:@selector(didTapReplyCollapseButton:) forControlEvents:UIControlEventTouchUpInside];
            [toggleCell.contentView addSubview:collapseButton];
            [collapseButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(toggleCell.contentView.mas_right).offset(-12.0);
                make.centerY.equalTo(toggleCell.contentView.mas_centerY);
                make.width.mas_equalTo(64.0);
            }];
        }
        UIButton *expandButton = [toggleCell.contentView viewWithTag:1001];
        if ([expandButton isKindOfClass:[UIButton class]]) {
            NSString *expandTitle = [row[@"title"] isKindOfClass:[NSString class]] ? row[@"title"] : @"展开回复";
            [expandButton setTitle:expandTitle forState:UIControlStateNormal];
            expandButton.hidden = (expandTitle.length == 0);
        }
        UIButton *collapseButton = [toggleCell.contentView viewWithTag:1003];
        if ([collapseButton isKindOfClass:[UIButton class]]) {
            BOOL showRightCollapse = [row[@"show_right_collapse"] respondsToSelector:@selector(boolValue)] ? [row[@"show_right_collapse"] boolValue] : NO;
            collapseButton.hidden = !showRightCollapse;
            [collapseButton setTitle:(showRightCollapse ? @"收起" : @"") forState:UIControlStateNormal];
        }
        NSNumber *rootCommentId = [row[@"root_comment_id"] respondsToSelector:@selector(integerValue)] ? @([row[@"root_comment_id"] integerValue]) : nil;
        NSNumber *totalReplyCount = [row[@"total_reply_count"] respondsToSelector:@selector(integerValue)] ? @([row[@"total_reply_count"] integerValue]) : @(0);
        NSNumber *visibleReplyCount = [row[@"visible_reply_count"] respondsToSelector:@selector(integerValue)] ? @([row[@"visible_reply_count"] integerValue]) : @(0);
        if ([expandButton isKindOfClass:[UIButton class]]) {
            objc_setAssociatedObject(expandButton, kYALToggleRootIdKey, rootCommentId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(expandButton, kYALToggleTotalCountKey, totalReplyCount, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(expandButton, kYALToggleVisibleCountKey, visibleReplyCount, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if ([collapseButton isKindOfClass:[UIButton class]]) {
            objc_setAssociatedObject(collapseButton, kYALToggleRootIdKey, rootCommentId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(collapseButton, kYALToggleTotalCountKey, totalReplyCount, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(collapseButton, kYALToggleVisibleCountKey, visibleReplyCount, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    NSInteger replyLevel = [row[@"reply_level"] respondsToSelector:@selector(integerValue)] ? [row[@"reply_level"] integerValue] : ([row[@"is_reply"] boolValue] ? 1 : 0);

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
                   replyLevel:replyLevel
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
    NSInteger replyLevel = [row[@"reply_level"] respondsToSelector:@selector(integerValue)] ? [row[@"reply_level"] integerValue] : ([row[@"is_reply"] boolValue] ? 1 : 0);
    UIImage *avatar = [[UIImage alloc] init];
    [sizingCell configureWithAvatar:avatar
                    avatarURLString:nil
                               name:comment[@"name"]
                            content:[self displayContentForComment:comment]
                               time:comment[@"time"]
                            isReply:[row[@"is_reply"] boolValue]
                        replyLevel:replyLevel
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

- (void)applyReplyToggleForRootCommentId:(NSNumber *)rootCommentId
                         totalReplyCount:(NSInteger)totalReplyCount
                        visibleReplyCount:(NSInteger)visibleCount
                            forceCollapse:(BOOL)forceCollapse {
    if (rootCommentId.integerValue <= 0 || totalReplyCount <= 0) {
        return;
    }

    NSInteger currentVisible = visibleCount;
    NSNumber *savedVisible = self.visibleReplyCountByRoot[rootCommentId];
    if ([savedVisible respondsToSelector:@selector(integerValue)]) {
        currentVisible = [savedVisible integerValue];
    }
    if ([self.expandedReplyThreads containsObject:rootCommentId]) {
        currentVisible = totalReplyCount;
    }
    currentVisible = MIN(MAX(currentVisible, 0), totalReplyCount);

    if (forceCollapse || currentVisible >= totalReplyCount) {
        [self.visibleReplyCountByRoot removeObjectForKey:rootCommentId];
        [self.expandedReplyThreads removeObject:rootCommentId];
    } else {
        NSInteger nextCount = MIN(totalReplyCount, currentVisible + kYALReplyExpandStep);
        self.visibleReplyCountByRoot[rootCommentId] = @(nextCount);
        if (nextCount >= totalReplyCount) {
            [self.expandedReplyThreads addObject:rootCommentId];
        } else {
            [self.expandedReplyThreads removeObject:rootCommentId];
        }
    }

    self.comments = [self displayRowsFromFlatComments:self.flatComments];
    [self.tableView reloadData];
    [self refreshTableHeight];
}

- (void)didTapReplyExpandButton:(UIButton *)sender {
    NSNumber *rootCommentId = objc_getAssociatedObject(sender, kYALToggleRootIdKey);
    NSNumber *totalCount = objc_getAssociatedObject(sender, kYALToggleTotalCountKey);
    NSNumber *visibleCount = objc_getAssociatedObject(sender, kYALToggleVisibleCountKey);
    [self applyReplyToggleForRootCommentId:rootCommentId
                           totalReplyCount:[totalCount respondsToSelector:@selector(integerValue)] ? [totalCount integerValue] : 0
                          visibleReplyCount:[visibleCount respondsToSelector:@selector(integerValue)] ? [visibleCount integerValue] : 0
                              forceCollapse:NO];
}

- (void)didTapReplyCollapseButton:(UIButton *)sender {
    NSNumber *rootCommentId = objc_getAssociatedObject(sender, kYALToggleRootIdKey);
    NSNumber *totalCount = objc_getAssociatedObject(sender, kYALToggleTotalCountKey);
    NSNumber *visibleCount = objc_getAssociatedObject(sender, kYALToggleVisibleCountKey);
    [self applyReplyToggleForRootCommentId:rootCommentId
                           totalReplyCount:[totalCount respondsToSelector:@selector(integerValue)] ? [totalCount integerValue] : 0
                          visibleReplyCount:[visibleCount respondsToSelector:@selector(integerValue)] ? [visibleCount integerValue] : 0
                              forceCollapse:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= self.comments.count) {
        return;
    }
    NSDictionary *row = self.comments[indexPath.row];
    NSString *rowType = [row[@"row_type"] isKindOfClass:[NSString class]] ? row[@"row_type"] : @"comment";
    if ([rowType isEqualToString:@"toggle"]) {
        // 展开/收起由 cell 内左右按钮分别处理，避免整行点击歧义
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
    if (self.openedFromAuthorProfile && [self popBackToAuthorProfileIfPresent]) {
        return;
    }

    if (@available(iOS 14.0, *)) {
        self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:nil
                                                                              action:nil];
    NSNumber *targetUserId = self.authorUserId;
    if (targetUserId.integerValue > 0) {
        NSLog(@"👤 ownerTapped 直进用户页: user_id=%@", targetUserId);
        YALAuthorProfileController *controller = [[YALAuthorProfileController alloc] init];
        controller.userId = targetUserId;
        controller.prefilledNickname = self.authorNickname;
        controller.prefilledAvatar = self.authorAvatar;
        controller.prefilledBio = self.authorBio;
        [self.navigationController pushViewController:controller animated:YES];
        return;
    }

    if (self.post.contentId.integerValue <= 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"暂时无法进入"
                                                                       message:@"这条内容还没有拿到发布人信息。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] getContentDetailWithId:self.post.contentId completion:^(BOOL success, NSDictionary * _Nullable content, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success && [content isKindOfClass:[NSDictionary class]]) {
                [strongSelf applyDetailData:content];
            }
            if (strongSelf.authorUserId.integerValue > 0) {
                NSLog(@"👤 ownerTapped 详情回填后进用户页: user_id=%@", strongSelf.authorUserId);
                YALAuthorProfileController *controller = [[YALAuthorProfileController alloc] init];
                controller.userId = strongSelf.authorUserId;
                controller.prefilledNickname = strongSelf.authorNickname;
                controller.prefilledAvatar = strongSelf.authorAvatar;
                controller.prefilledBio = strongSelf.authorBio;
                [strongSelf.navigationController pushViewController:controller animated:YES];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"暂时无法进入"
                                                                               message:(error.localizedDescription.length > 0 ? error.localizedDescription : @"后端还没有返回发布人 user_id。")
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
                [strongSelf presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
}

- (BOOL)popBackToAuthorProfileIfPresent {
    NSArray<UIViewController *> *viewControllers = self.navigationController.viewControllers;
    for (UIViewController *controller in [viewControllers reverseObjectEnumerator]) {
        if (controller == self) {
            continue;
        }
        if ([controller isKindOfClass:[YALAuthorProfileController class]]) {
            [self.navigationController popToViewController:controller animated:YES];
            return YES;
        }
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已经在作者作品里"
                                                                   message:@"返回上一页可以继续查看这个作者的公开内容。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    return YES;
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

    CGFloat offset = -MAX(0, keyboardHeightInView);

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
                strongSelf.visibleReplyCountByRoot[rootCommentId] = @(NSIntegerMax);
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
                @"parent_id": [comment[@"parent_id"] respondsToSelector:@selector(integerValue)] ? @([comment[@"parent_id"] integerValue]) : ([comment[@"ParentID"] respondsToSelector:@selector(integerValue)] ? @([comment[@"ParentID"] integerValue]) : parentId),
                @"root_comment_id": rootCommentId ?: @(0),
                @"user_id": [strongSelf currentLoginUserId] ?: @(0),
                @"name": name.length > 0 ? name : ([YALAuthManager sharedManager].currentUser.nickname ?: @"我"),
                @"content": text,
                @"time": [strongSelf displayTimeStringFromRaw:comment[@"created_at"]],
                @"reply_to_name": [strongSelf.replyTargetComment[@"name"] isKindOfClass:[NSString class]] ? strongSelf.replyTargetComment[@"name"] : @"",
                @"depth": @(([strongSelf.replyTargetComment[@"depth"] respondsToSelector:@selector(integerValue)] ? [strongSelf.replyTargetComment[@"depth"] integerValue] : -1) + 1)
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
        self.bottomBarHeightConstraint = make.height.mas_equalTo([self targetBottomBarHeightForEditing:editing]);
    }];

    [self.inputContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomBarContentView.mas_left).offset(12.0);
        make.centerY.equalTo(self.bottomBarContentView.mas_centerY);
        if (editing) {
            make.right.equalTo(self.bottomBarContentView.mas_right).offset(-12.0);
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

- (CGFloat)targetBottomBarHeightForEditing:(BOOL)editing {
    CGFloat safeBottom = 0.0;
    if (@available(iOS 11.0, *)) {
        safeBottom = self.view.safeAreaInsets.bottom;
    }
    return [self targetInputHeightForEditing:editing] + 20.0 + safeBottom;
}

- (void)updatePublishButtonState {
    NSString *text = [self.inputTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL hasText = text.length > 0;
    self.publishButton.enabled = hasText;
    self.publishButton.alpha = self.inputExpanded ? (hasText ? 1.0 : 0.65) : 0.0;
}


@end
