//
//  YALReleaseController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALReleaseController.h"
#import "YALCalendarController.h"
#import "../Map/Controller/YALMapController.h"
#import "../Network/Manager/YALContentManager.h"
#import <Masonry/Masonry.h>
#import <AVFoundation/AVFoundation.h>
#import <PhotosUI/PhotosUI.h>
#import <CoreLocation/CoreLocation.h>

static NSInteger const kYALReleaseMaxImageCount = 9;
static NSString * const kYALReleasePhotoCellIdentifier = @"YALReleasePhotoCell";

@interface YALReleasePhotoCell : UICollectionViewCell

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *removeButton;

@end

@implementation YALReleasePhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];

        self.cardView = [[UIView alloc] init];
        self.cardView.layer.cornerRadius = 16.0;
        self.cardView.layer.masksToBounds = YES;
        [self.contentView addSubview:self.cardView];

        self.imageView = [[UIImageView alloc] init];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        [self.cardView addSubview:self.imageView];

        self.iconView = [[UIImageView alloc] init];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.cardView addSubview:self.iconView];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.cardView addSubview:self.titleLabel];

        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        [self.cardView addSubview:self.subtitleLabel];

        self.removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.removeButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        self.removeButton.layer.cornerRadius = 12.0;
        self.removeButton.layer.masksToBounds = YES;
        [self.removeButton setTitle:@"×" forState:UIControlStateNormal];
        [self.removeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.removeButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        [self.cardView addSubview:self.removeButton];

        [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.cardView);
        }];
        [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.cardView);
            make.centerY.equalTo(self.cardView).offset(-14);
            make.width.height.mas_equalTo(30);
        }];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.cardView).offset(8);
            make.right.equalTo(self.cardView).offset(-8);
            make.top.equalTo(self.iconView.mas_bottom).offset(8);
        }];
        [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.titleLabel);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(3);
        }];
        [self.removeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cardView).offset(8);
            make.right.equalTo(self.cardView).offset(-8);
            make.width.height.mas_equalTo(24);
        }];
    }
    return self;
}

@end

@interface YALReleaseController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate, PHPickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong, nullable) UIImage *editCoverImage;
@property (nonatomic, copy, nullable) NSString *editDateText;
@property (nonatomic, copy, nullable) NSString *editTitleText;
@property (nonatomic, copy, nullable) NSString *editBody;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *photoSectionHeaderView;
@property (nonatomic, strong) UILabel *photoSectionLabel;
@property (nonatomic, strong) UILabel *photoHintLabel;
@property (nonatomic, strong) UICollectionView *photoCollectionView;
@property (nonatomic, strong) MASConstraint *photoCollectionHeightConstraint;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIControl *locationControl;
@property (nonatomic, strong) UIImageView *locationIconView;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *visibilityTitleLabel;
@property (nonatomic, strong) UIView *visibilitySegment;
@property (nonatomic, strong) UIView *visibilityIndicator;
@property (nonatomic, strong) UIButton *publicButton;
@property (nonatomic, strong) UIButton *privateButton;
@property (nonatomic, strong) MASConstraint *visibilityIndicatorLeading;
@property (nonatomic, assign) BOOL isPublic;
@property (nonatomic, copy) NSString *bodyPlaceholderText;
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;

@property (nonatomic, strong, nullable) NSDate *selectedDate;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, copy, nullable) NSString *resolvedCityName;
@property (nonatomic, assign) UIEdgeInsets baseScrollIndicatorInsets;
@property (nonatomic, assign) UIEdgeInsets baseScrollContentInsets;

@end

@implementation YALReleaseController

- (UIColor *)accentColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
      if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        return [UIColor systemOrangeColor];
      }
      return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    }];
  }
  return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

- (UIColor *)cardBackgroundColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
      if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        return [UIColor secondarySystemBackgroundColor];
      }
      return [UIColor colorWithRed:1.0 green:0.985 blue:0.965 alpha:1.0];
    }];
  }
  return [UIColor colorWithRed:1.0 green:0.985 blue:0.965 alpha:1.0];
}

- (UIColor *)fieldBackgroundColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
      if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        return [UIColor tertiarySystemBackgroundColor];
      }
      return [[UIColor whiteColor] colorWithAlphaComponent:0.72];
    }];
  }
  return [[UIColor whiteColor] colorWithAlphaComponent:0.72];
}

- (UIColor *)softBorderColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
      if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        return [UIColor separatorColor];
      }
      return [UIColor colorWithRed:0.93 green:0.74 blue:0.5 alpha:1.0];
    }];
  }
  return [UIColor colorWithRed:0.93 green:0.74 blue:0.5 alpha:1.0];
}

- (UIColor *)addPhotoBackgroundColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
      if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        return [UIColor tertiarySystemFillColor];
      }
      return [UIColor colorWithRed:0.98 green:0.93 blue:0.86 alpha:1.0];
    }];
  }
  return [UIColor colorWithRed:0.98 green:0.93 blue:0.86 alpha:1.0];
}

- (UIColor *)photoHintColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
      if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        return [UIColor secondaryLabelColor];
      }
      return [UIColor colorWithRed:0.76 green:0.45 blue:0.16 alpha:1.0];
    }];
  }
  return [UIColor colorWithRed:0.76 green:0.45 blue:0.16 alpha:1.0];
}

- (UIColor *)addPhotoTitleColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
      if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        return [UIColor labelColor];
      }
      return [UIColor colorWithRed:0.45 green:0.29 blue:0.12 alpha:1.0];
    }];
  }
  return [UIColor colorWithRed:0.45 green:0.29 blue:0.12 alpha:1.0];
}

- (instancetype)initWithEditCoverImage:(UIImage *)coverImage
                              dateText:(NSString *)dateText
                                  body:(NSString *)body {
  return [self initWithEditCoverImage:coverImage title:nil dateText:dateText body:body];
}

- (instancetype)initWithEditCoverImage:(nullable UIImage *)coverImage
                                 title:(nullable NSString *)title
                              dateText:(nullable NSString *)dateText
                                  body:(nullable NSString *)body {
    self = [super init];
    if (self) {
        _editCoverImage = coverImage;
        _editTitleText = [title copy];
        _editDateText = [dateText copy];
        _editBody = [body copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.selectedImages = [NSMutableArray array];
    self.geocoder = [[CLGeocoder alloc] init];

    UIColor *accent = [self accentColor];
    self.navigationController.navigationBar.tintColor = accent;

    BOOL isEdit = (self.editCoverImage != nil) || (self.editBody.length > 0) || (self.editDateText.length > 0);
    self.title = isEdit ? @"编辑发布" : @"发布";

    if (@available(iOS 13.0, *)) {
      UIBarButtonItem *submit =
        [[UIBarButtonItem alloc] initWithTitle:(isEdit ? @"重新发布" : @"发布")
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(submitTapped)];
      submit.tintColor = accent;
      self.navigationItem.rightBarButtonItem = submit;
    } else {
      UIBarButtonItem *submit =
        [[UIBarButtonItem alloc] initWithTitle:(isEdit ? @"重新发布" : @"发布")
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(submitTapped)];
      self.navigationItem.rightBarButtonItem = submit;
    }

    [self buildUI];
    self.bodyPlaceholderText = @"写下此刻的心情…";
    [self applyPrefillIfNeeded];
    [self updateTitleForSelectedLocation];
    [self updateLocationUI];
    [self resolveLocationDetailsIfNeeded];
    [self registerForKeyboardNotifications];

    // 点击空白收起键盘
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updatePhotoCollectionHeight];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI

- (void)buildUI {
  self.scrollView = [[UIScrollView alloc] init];
  self.scrollView.alwaysBounceVertical = YES;
  self.scrollView.showsVerticalScrollIndicator = NO;
  [self.view addSubview:self.scrollView];
  [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
  self.baseScrollContentInsets = self.scrollView.contentInset;
  self.baseScrollIndicatorInsets = self.scrollView.verticalScrollIndicatorInsets;

  self.contentView = [[UIView alloc] init];
  self.contentView.backgroundColor = [UIColor clearColor];
  [self.scrollView addSubview:self.contentView];
  [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.scrollView);
    make.width.equalTo(self.scrollView);
  }];

  UIView *card = [[UIView alloc] init];
  card.backgroundColor = [self cardBackgroundColor];
  card.layer.cornerRadius = 24.0;
  card.layer.shadowColor = [UIColor blackColor].CGColor;
  card.layer.shadowOpacity = 0.08;
  card.layer.shadowRadius = 18.0;
  card.layer.shadowOffset = CGSizeMake(0, 10);
  [self.contentView addSubview:card];

  self.photoSectionHeaderView = [[UIView alloc] init];
  [card addSubview:self.photoSectionHeaderView];

  self.photoSectionLabel = [[UILabel alloc] init];
  self.photoSectionLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
  self.photoSectionLabel.textColor = [UIColor labelColor];
  self.photoSectionLabel.text = @"图片";
  [self.photoSectionHeaderView addSubview:self.photoSectionLabel];

  self.photoHintLabel = [[UILabel alloc] init];
  self.photoHintLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
  self.photoHintLabel.textColor = [self photoHintColor];
  self.photoHintLabel.textAlignment = NSTextAlignmentRight;
  [self.photoSectionHeaderView addSubview:self.photoHintLabel];

  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.minimumLineSpacing = 12.0;
  layout.minimumInteritemSpacing = 12.0;
  self.photoCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  self.photoCollectionView.backgroundColor = [UIColor clearColor];
  self.photoCollectionView.showsVerticalScrollIndicator = NO;
  self.photoCollectionView.scrollEnabled = NO;
  self.photoCollectionView.dataSource = self;
  self.photoCollectionView.delegate = self;
  [self.photoCollectionView registerClass:[YALReleasePhotoCell class] forCellWithReuseIdentifier:kYALReleasePhotoCellIdentifier];
  [card addSubview:self.photoCollectionView];

  self.dateLabel = [[UILabel alloc] init];
  self.dateLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
  self.dateLabel.textColor = [UIColor secondaryLabelColor];
  self.dateLabel.backgroundColor = [self fieldBackgroundColor];
  self.dateLabel.layer.cornerRadius = 14.0;
  self.dateLabel.layer.masksToBounds = YES;
  [card addSubview:self.dateLabel];

  self.dateLabel.userInteractionEnabled = YES;
  UITapGestureRecognizer *dateTap =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseDate)];
  dateTap.cancelsTouchesInView = NO;
  [self.dateLabel addGestureRecognizer:dateTap];

  self.locationControl = [[UIControl alloc] init];
  self.locationControl.backgroundColor = [self fieldBackgroundColor];
  self.locationControl.layer.cornerRadius = 14.0;
  self.locationControl.layer.masksToBounds = YES;
  [self.locationControl addTarget:self action:@selector(locationTapped) forControlEvents:UIControlEventTouchUpInside];
  [card addSubview:self.locationControl];

  self.locationIconView = [[UIImageView alloc] init];
  self.locationIconView.contentMode = UIViewContentModeScaleAspectFit;
  if (@available(iOS 13.0, *)) {
    self.locationIconView.image = [UIImage systemImageNamed:@"mappin.and.ellipse"];
  }
  self.locationIconView.tintColor = [self accentColor];
  [self.locationControl addSubview:self.locationIconView];

  self.locationLabel = [[UILabel alloc] init];
  self.locationLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
  self.locationLabel.textColor = [UIColor secondaryLabelColor];
  self.locationLabel.numberOfLines = 1;
  [self.locationControl addSubview:self.locationLabel];

  self.titleField = [[UITextField alloc] init];
  self.titleField.backgroundColor = [self fieldBackgroundColor];
  self.titleField.textColor = [UIColor labelColor];
  self.titleField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
  self.titleField.placeholder = @"输入标题";
  self.titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
  self.titleField.returnKeyType = UIReturnKeyNext;
  self.titleField.layer.cornerRadius = 16.0;
  self.titleField.layer.masksToBounds = YES;
  self.titleField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 10)];
  self.titleField.leftViewMode = UITextFieldViewModeAlways;
  self.titleField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 10)];
  self.titleField.rightViewMode = UITextFieldViewModeAlways;
  if (@available(iOS 12.0, *)) {
      self.titleField.textContentType = UITextContentTypeOneTimeCode; // 关闭自动填充/建议
  }
  [card addSubview:self.titleField];

  self.textView = [[UITextView alloc] init];
  self.textView.backgroundColor = [self fieldBackgroundColor];
  self.textView.textColor = [UIColor labelColor];
  self.textView.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
  self.textView.textContainerInset = UIEdgeInsetsMake(14, 14, 14, 14);
  self.textView.textContainer.lineFragmentPadding = 0;
  self.textView.layer.cornerRadius = 18.0;
  self.textView.layer.masksToBounds = YES;
  self.textView.delegate = self;
  [card addSubview:self.textView];

  self.visibilityTitleLabel = [[UILabel alloc] init];
  self.visibilityTitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
  self.visibilityTitleLabel.textColor = [UIColor secondaryLabelColor];
  [card addSubview:self.visibilityTitleLabel];

  self.visibilitySegment = [[UIView alloc] init];
  self.visibilitySegment.backgroundColor = [UIColor tertiarySystemFillColor];
  self.visibilitySegment.layer.cornerRadius = 15.0;
  self.visibilitySegment.layer.masksToBounds = YES;
  [card addSubview:self.visibilitySegment];

  self.visibilityIndicator = [[UIView alloc] init];
  self.visibilityIndicator.backgroundColor = [self accentColor];
  self.visibilityIndicator.layer.cornerRadius = 13.0;
  self.visibilityIndicator.userInteractionEnabled = NO;
  [self.visibilitySegment addSubview:self.visibilityIndicator];

  self.publicButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.publicButton setTitle:@"公开" forState:UIControlStateNormal];
  self.publicButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
  self.publicButton.tag = 100;
  [self.publicButton addTarget:self action:@selector(visibilityButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
  [self.visibilitySegment addSubview:self.publicButton];

  self.privateButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.privateButton setTitle:@"私密" forState:UIControlStateNormal];
  self.privateButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
  self.privateButton.tag = 101;
  [self.privateButton addTarget:self action:@selector(visibilityButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
  [self.visibilitySegment addSubview:self.privateButton];

  [card mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.contentView.mas_top).offset(14);
    make.left.equalTo(self.contentView.mas_left).offset(16);
    make.right.equalTo(self.contentView.mas_right).offset(-16);
    make.bottom.equalTo(self.contentView.mas_bottom).offset(-18);
  }];
  [self.photoSectionHeaderView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(card.mas_top).offset(18);
    make.left.equalTo(card.mas_left).offset(18);
    make.right.equalTo(card.mas_right).offset(-18);
    make.height.mas_equalTo(24);
  }];
  [self.photoSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.top.bottom.equalTo(self.photoSectionHeaderView);
  }];
  [self.photoHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.top.bottom.equalTo(self.photoSectionHeaderView);
    make.left.greaterThanOrEqualTo(self.photoSectionLabel.mas_right).offset(10);
  }];
  [self.photoCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoSectionHeaderView.mas_bottom).offset(14);
    make.left.equalTo(card.mas_left).offset(18);
    make.right.equalTo(card.mas_right).offset(-18);
    self.photoCollectionHeightConstraint = make.height.mas_equalTo(0);
  }];
  [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoCollectionView.mas_bottom).offset(16);
    make.left.equalTo(self.photoCollectionView);
    make.right.lessThanOrEqualTo(self.visibilityTitleLabel.mas_left).offset(-10);
    make.height.mas_equalTo(42);
  }];
  [self.visibilitySegment mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(self.dateLabel);
    make.right.equalTo(self.photoCollectionView);
    make.width.mas_equalTo(132);
    make.height.mas_equalTo(30);
  }];
  [self.visibilityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.visibilitySegment).offset(2);
    make.bottom.equalTo(self.visibilitySegment).offset(-2);
    make.width.equalTo(self.visibilitySegment).multipliedBy(0.5).offset(-2);
    self.visibilityIndicatorLeading = make.left.equalTo(self.visibilitySegment).offset(2);
  }];
  [self.publicButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.top.bottom.equalTo(self.visibilitySegment);
    make.width.equalTo(self.visibilitySegment).multipliedBy(0.5);
  }];
  [self.privateButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.top.bottom.equalTo(self.visibilitySegment);
    make.width.equalTo(self.visibilitySegment).multipliedBy(0.5);
  }];
  [self.visibilityTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self.visibilitySegment.mas_left).offset(-8);
    make.centerY.equalTo(self.visibilitySegment);
  }];
  [self.locationControl mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.dateLabel.mas_bottom).offset(8);
    make.left.right.equalTo(self.photoCollectionView);
    make.height.mas_equalTo(42);
  }];
  [self.locationIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.locationControl).offset(14);
    make.centerY.equalTo(self.locationControl);
    make.width.height.mas_equalTo(18);
  }];
  [self.locationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.locationIconView.mas_right).offset(8);
    make.right.equalTo(self.locationControl).offset(-14);
    make.centerY.equalTo(self.locationControl);
  }];
  [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.locationControl.mas_bottom).offset(8);
    make.left.right.equalTo(self.photoCollectionView);
    make.height.mas_equalTo(52);
  }];
  [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.titleField.mas_bottom).offset(8);
    make.left.right.equalTo(self.photoCollectionView);
    make.height.mas_equalTo(240);
    make.bottom.equalTo(card.mas_bottom).offset(-18);
  }];

  [self setVisibilityPublic:YES animated:NO source:@"initial"];
  [self updatePhotoSelectionUI];
  [self updateLocationUI];
}

- (void)applyPrefillIfNeeded {
  if (self.editCoverImage) {
    [self.selectedImages addObject:self.editCoverImage];
  }
  [self updatePhotoSelectionUI];

  self.dateLabel.text = self.editDateText.length > 0 ? self.editDateText : @"选择日期";
  if (self.editDateText.length > 0) {
      NSDate *parsed = [self dateFromDateText:self.editDateText];
      self.selectedDate = parsed;
  } else {
      self.selectedDate = nil;
  }
  self.resolvedCityName = nil;
  self.titleField.text = self.editTitleText.length > 0 ? self.editTitleText : @"";
  if (self.editBody.length > 0) {
    self.textView.text = self.editBody;
    self.textView.textColor = [UIColor labelColor];
  } else {
    self.textView.text = self.bodyPlaceholderText;
    self.textView.textColor = [UIColor placeholderTextColor];
  }
  [self updateLocationUI];
}

- (void)setVisibilityPublic:(BOOL)isPublic animated:(BOOL)animated source:(NSString *)source {
  self.isPublic = isPublic;
  self.publicButton.selected = isPublic;
  self.privateButton.selected = !isPublic;
  [self updateVisibilitySegmentAnimated:animated];
}

- (void)updatePhotoSelectionUI {
  self.photoHintLabel.text = [NSString stringWithFormat:@"%lu/%ld · 最多上传 9 张",
                              (unsigned long)self.selectedImages.count,
                              (long)kYALReleaseMaxImageCount];
  [self.photoCollectionView reloadData];
  [self updatePhotoCollectionHeight];
}

- (void)updatePhotoCollectionHeight {
  NSInteger displayCount = self.selectedImages.count < kYALReleaseMaxImageCount ? self.selectedImages.count + 1 : self.selectedImages.count;
  displayCount = MAX(displayCount, 1);
  NSInteger rows = (NSInteger)ceil(displayCount / 3.0);
  CGFloat itemSize = [self photoItemSize];
  CGFloat spacing = 12.0;
  CGFloat height = rows * itemSize + MAX(rows - 1, 0) * spacing;
  [self.photoCollectionHeightConstraint setOffset:height];
  [self.view layoutIfNeeded];
}

- (CGFloat)photoItemSize {
  CGFloat availableWidth = CGRectGetWidth(self.photoCollectionView.bounds);
  if (availableWidth <= 0) {
    availableWidth = CGRectGetWidth(self.view.bounds) - 32.0 - 36.0;
  }
  CGFloat spacing = 24.0;
  return floor((availableWidth - spacing) / 3.0);
}

#pragma mark - Actions

- (void)submitTapped {
  self.editTitleText = self.titleField.text ?: @"";
  NSString *bodyText = self.textView.text ?: @"";
  if ([bodyText isEqualToString:self.bodyPlaceholderText]) {
    bodyText = @"";
  }
  self.editBody = bodyText;

  // 未选择日期：直接提示并中断发布
  NSString *dateText = self.editDateText ?: @"";
  if (dateText.length == 0 && self.selectedDate == nil) {
    UIAlertController *a =
      [UIAlertController alertControllerWithTitle:@"未选择日期"
                                          message:@"还未添加时间，请先选择日期后再发布。"
                                   preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
    return;
  }

  NSString *locationNameForValidation =
      [[self currentLocationDisplayName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (!self.hasPresetCoordinate ||
      !CLLocationCoordinate2DIsValid(self.presetCoordinate) ||
      locationNameForValidation.length == 0) {
    UIAlertController *a =
      [UIAlertController alertControllerWithTitle:@"未添加地点"
                                          message:@"还未添加地点，请先选择地点后再发布。"
                                   preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
    return;
  }

  // 未选择图片：直接提示并中断发布
  if (self.selectedImages.count == 0) {
    UIAlertController *a =
        [UIAlertController alertControllerWithTitle:@"未选择图片"
                                            message:@"还未添加图片，请先选择图片后再发布。"
                                     preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
    return;
  }

  // 如果 selectedDate 有值但 editDateText 为空，补齐 editDateText
  if (dateText.length == 0 && self.selectedDate) {
    dateText = [self dateStringFromDate:self.selectedDate];
    self.editDateText = dateText;
  }

  // 标题必填
  NSString *title = [self.editTitleText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (title.length == 0) {
    UIAlertController *a =
      [UIAlertController alertControllerWithTitle:@"未填写标题"
                                          message:@"请输入标题后再发布。"
                                   preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
    return;
  }

  // 内容必填
  NSString *content = [self.editBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (content.length == 0) {
    UIAlertController *a =
      [UIAlertController alertControllerWithTitle:@"未填写内容"
                                          message:@"请输入内容后再发布。"
                                   preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
    return;
  }

  NSString *city = self.resolvedCityName.length > 0 ? self.resolvedCityName : @"";
  // year 参数承载发布时间（你的 dateStringFromDate 格式为 yyyy.MM.dd）
  NSString *year = dateText;
  NSString *mood = @"开心";
  NSString *locationName = [self currentLocationDisplayName];
  double latitude = self.hasPresetCoordinate ? self.presetCoordinate.latitude : 0.0;
  double longitude = self.hasPresetCoordinate ? self.presetCoordinate.longitude : 0.0;
  BOOL isPublic = self.publicButton.selected ? YES : (self.privateButton.selected ? NO : self.isPublic);
  NSLog(@"[Publish VC] visibility publicSelected=%d privateSelected=%d finalIsPublic=%d",
        self.publicButton.selected,
        self.privateButton.selected,
        isPublic);

  // 图片处理：如果有选择的图片，转换为Base64
  NSMutableArray *images = [NSMutableArray array];
  for (UIImage *selectedImage in self.selectedImages) {
      UIImage *compressedImage = [self compressImage:selectedImage toMaxFileSize:1024*500];
      NSData *imageData = UIImageJPEGRepresentation(compressedImage, 0.7); // 70%质量压缩
      if (imageData) {
          NSString *base64String = [imageData base64EncodedStringWithOptions:0];
          if (base64String) {
              [images addObject:base64String];
          }
      }
  }

  // 显示加载提示
  UIAlertController *loadingAlert = [UIAlertController alertControllerWithTitle:@"发布中" message:@"正在发送网络请求，请稍候..." preferredStyle:UIAlertControllerStyleAlert];
  [self presentViewController:loadingAlert animated:YES completion:nil];

  // 调用发布接口
  [[YALContentManager sharedManager] publishContentWithTitle:title
                                                     content:content
                                                        city:city
                                                        year:year
                                                        mood:mood
                                                      images:images
                                                locationName:locationName
                                                    latitude:latitude
                                                   longitude:longitude
                                                    isPublic:isPublic
                                                      userId:nil
                                                   completion:^(BOOL success, NSString *message, NSNumber * _Nullable contentId, NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      // 关闭加载提示
      [loadingAlert dismissViewControllerAnimated:YES completion:^{
        if (success) {
          UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"发布成功" message:[NSString stringWithFormat:@"%@\n内容ID: %@\n\n发布内容已保存到服务器", message, contentId] preferredStyle:UIAlertControllerStyleAlert];
          [successAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self resetPublishForm];
            // 发布成功后跳转主页。仅公开内容主动刷新首页，私密内容只清理首页现有数据里的私密项。
            dispatch_async(dispatch_get_main_queue(), ^{
              UIViewController *rootVC = self.view.window.rootViewController;
              if ([rootVC isKindOfClass:[UITabBarController class]]) {
                UITabBarController *tab = (UITabBarController *)rootVC;
                tab.selectedIndex = 0; // Home
                UINavigationController *homeNav = nil;
                if (tab.viewControllers.count > 0 && [tab.viewControllers.firstObject isKindOfClass:[UINavigationController class]]) {
                  homeNav = (UINavigationController *)tab.viewControllers.firstObject;
                }
                UIViewController *homeVC = homeNav.viewControllers.firstObject ?: nil;
                if (isPublic && homeVC && [homeVC respondsToSelector:@selector(loadPosts)]) {
                  [homeVC performSelector:@selector(loadPosts)];
                } else if (!isPublic && homeVC && [homeVC respondsToSelector:@selector(removePrivatePostsFromCurrentData)]) {
                  [homeVC performSelector:@selector(removePrivatePostsFromCurrentData)];
                }
                if (tab.viewControllers.count > 1 && [tab.viewControllers[1] isKindOfClass:[UINavigationController class]]) {
                  UINavigationController *memoryNav = (UINavigationController *)tab.viewControllers[1];
                  UIViewController *memoryVC = memoryNav.viewControllers.firstObject ?: nil;
                  if (memoryVC && [memoryVC respondsToSelector:@selector(refreshTimelineAndReloadUI)]) {
                    [memoryVC performSelector:@selector(refreshTimelineAndReloadUI)];
                  }
                }
              }
            });
          }]];
          [self presentViewController:successAlert animated:YES completion:nil];
        } else {
          NSString *errorMsg = error ? error.localizedDescription : message;

          UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"发布失败" message:[NSString stringWithFormat:@"%@\n\n请检查网络连接或稍后重试", errorMsg] preferredStyle:UIAlertControllerStyleAlert];
          [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
          [self presentViewController:errorAlert animated:YES completion:nil];
        }
      }];
    });
  }];
}

- (void)resetPublishForm {
  self.editCoverImage = nil;
  self.editDateText = nil;
  self.editTitleText = @"";
  self.editBody = @"";
  self.selectedDate = nil;
  [self setVisibilityPublic:YES animated:NO source:@"reset"];
  self.hasPresetCoordinate = NO;
  self.presetCoordinate = kCLLocationCoordinate2DInvalid;
  self.presetLocationName = nil;
  self.resolvedCityName = nil;
  [self.selectedImages removeAllObjects];
  self.titleField.text = @"";
  self.dateLabel.text = @"选择日期";
  self.textView.text = self.bodyPlaceholderText;
  self.textView.textColor = [UIColor placeholderTextColor];
  [self updatePhotoSelectionUI];
  [self updateTitleForSelectedLocation];
  [self updateLocationUI];
}

- (void)updateTitleForSelectedLocation {
  if (self.hasPresetCoordinate) {
    self.navigationItem.prompt = self.presetLocationName.length > 0
      ? self.presetLocationName
      : [NSString stringWithFormat:@"地图选点 %.4f, %.4f",
         self.presetCoordinate.latitude,
         self.presetCoordinate.longitude];
  } else {
    self.navigationItem.prompt = nil;
  }
}

- (NSString *)cityNameFromPlacemark:(CLPlacemark *)placemark {
  if (placemark.locality.length > 0) {
    return placemark.locality;
  }
  if (placemark.administrativeArea.length > 0) {
    return placemark.administrativeArea;
  }
  return @"";
}

- (NSString *)currentLocationDisplayName {
  if (self.presetLocationName.length > 0) {
    return self.presetLocationName;
  }
  if (self.hasPresetCoordinate) {
    return [NSString stringWithFormat:@"地图选点 %.4f, %.4f",
            self.presetCoordinate.latitude,
            self.presetCoordinate.longitude];
  }
  return @"";
}

- (BOOL)isFallbackCoordinateLocationName:(NSString *)locationName {
  if (locationName.length == 0) {
    return NO;
  }
  return [locationName hasPrefix:@"地图选点 "] || [locationName hasPrefix:@"当前位置 "];
}

- (void)updateLocationUI {
  NSString *displayName = [self currentLocationDisplayName];
  if (displayName.length > 0) {
    if (self.hasPresetCoordinate) {
      self.locationLabel.text = [NSString stringWithFormat:@"%@（%.4f, %.4f）",
                                 displayName,
                                 self.presetCoordinate.latitude,
                                 self.presetCoordinate.longitude];
    } else {
      self.locationLabel.text = displayName;
    }
    self.locationLabel.textColor = [UIColor labelColor];
    return;
  }

  self.locationLabel.text = @"添加定位";
  self.locationLabel.textColor = [UIColor secondaryLabelColor];
}

#pragma mark - Keyboard

- (void)registerForKeyboardNotifications {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(handleKeyboardWillShow:)
                 name:UIKeyboardWillShowNotification
               object:nil];
  [center addObserver:self
             selector:@selector(handleKeyboardWillHide:)
                 name:UIKeyboardWillHideNotification
               object:nil];
}

- (UIView *)currentFirstResponderInView:(UIView *)view {
  if (view.isFirstResponder) {
    return view;
  }
  for (UIView *subview in view.subviews) {
    UIView *firstResponder = [self currentFirstResponderInView:subview];
    if (firstResponder) {
      return firstResponder;
    }
  }
  return nil;
}

- (void)handleKeyboardWillShow:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo ?: @{};
  CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  UIViewAnimationOptions options = ([userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
  CGRect keyboardFrameInView = [self.view convertRect:keyboardEndFrame fromView:nil];
  CGFloat keyboardHeight = MAX(CGRectGetHeight(self.view.bounds) - CGRectGetMinY(keyboardFrameInView), 0.0);
  CGFloat bottomInset = keyboardHeight + 16.0;

  UIEdgeInsets contentInsets = self.baseScrollContentInsets;
  contentInsets.bottom = bottomInset;
  UIEdgeInsets indicatorInsets = self.baseScrollIndicatorInsets;
  indicatorInsets.bottom = bottomInset;

  [UIView animateWithDuration:duration delay:0 options:options animations:^{
    self.scrollView.contentInset = contentInsets;
    self.scrollView.verticalScrollIndicatorInsets = indicatorInsets;
  } completion:nil];

  UIView *activeView = [self currentFirstResponderInView:self.view];
  if (!activeView) {
    return;
  }

  CGRect targetRect = [self.scrollView convertRect:activeView.bounds fromView:activeView];
  targetRect = CGRectInset(targetRect, 0, -24.0);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.scrollView scrollRectToVisible:targetRect animated:YES];
  });
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo ?: @{};
  NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  UIViewAnimationOptions options = ([userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);

  [UIView animateWithDuration:duration delay:0 options:options animations:^{
    self.scrollView.contentInset = self.baseScrollContentInsets;
    self.scrollView.verticalScrollIndicatorInsets = self.baseScrollIndicatorInsets;
  } completion:nil];
}

- (void)dismissKeyboard {
  [self.view endEditing:YES];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
  if ([textView.text isEqualToString:self.bodyPlaceholderText]) {
    textView.text = @"";
    textView.textColor = [UIColor labelColor];
  }
  CGRect targetRect = [self.scrollView convertRect:textView.bounds fromView:textView];
  targetRect = CGRectInset(targetRect, 0, -24.0);
  [self.scrollView scrollRectToVisible:targetRect animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
  if (textView.text.length == 0) {
    textView.text = self.bodyPlaceholderText;
    textView.textColor = [UIColor placeholderTextColor];
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldReceiveTouch:(UITouch *)touch {
  UIView *v = touch.view;
  if (!v) return YES;
  while (v && v != self.view) {
    if ([v isKindOfClass:[UIControl class]] ||
        [v isKindOfClass:[UITextView class]] ||
        [v isKindOfClass:[UIImageView class]] ||
        [v isKindOfClass:[UILabel class]]) {
      return NO; // 交给自身控件手势/交互处理
    }
    v = v.superview;
  }
  return YES;
}

#pragma mark - Date & Image

- (void)visibilityButtonTapped:(UIButton *)sender {
  BOOL shouldPublic = (sender == self.publicButton) || (sender.tag == 100);
  [self setVisibilityPublic:shouldPublic animated:YES source:@"tap"];
}

- (void)updateVisibilitySegmentAnimated:(BOOL)animated {
  self.visibilityTitleLabel.text = self.isPublic ? @"公开显示" : @"仅自己可见";
  [self.publicButton setTitleColor:(self.isPublic ? [UIColor whiteColor] : [UIColor labelColor]) forState:UIControlStateNormal];
  [self.privateButton setTitleColor:(self.isPublic ? [UIColor labelColor] : [UIColor whiteColor]) forState:UIControlStateNormal];

  [self.visibilityIndicatorLeading uninstall];
  [self.visibilityIndicator mas_updateConstraints:^(MASConstraintMaker *make) {
    if (self.isPublic) {
      self.visibilityIndicatorLeading = make.left.equalTo(self.visibilitySegment).offset(2);
    } else {
      self.visibilityIndicatorLeading = make.left.equalTo(self.visibilitySegment.mas_centerX);
    }
  }];

  void (^animations)(void) = ^{
    [self.visibilitySegment layoutIfNeeded];
  };
  if (animated) {
    [UIView animateWithDuration:0.22 animations:animations];
  } else {
    animations();
  }
}

- (NSString *)dateStringFromDate:(NSDate *)date {
  NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
  fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
  fmt.dateFormat = @"yyyy.MM.dd";
  return [fmt stringFromDate:date ?: [NSDate date]];
}

- (NSDate *)dateFromDateText:(NSString *)text {
  if (text.length == 0) return nil;
  NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
  fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
  fmt.dateFormat = @"yyyy.MM.dd";
  return [fmt dateFromString:text];
}

- (void)chooseDate {
  [self.view endEditing:YES];
  YALCalendarController *cal = [[YALCalendarController alloc] init];
  cal.selectedDate = self.selectedDate ?: [NSDate date];
  __weak typeof(self) ws = self;
  cal.onDatePicked = ^(NSDate *date) {
    __strong typeof(ws) ss = ws;
    if (!ss) return;
    ss.selectedDate = date;
    ss.editDateText = [ss dateStringFromDate:date];
    ss.dateLabel.text = ss.editDateText;
  };
  [self.navigationController pushViewController:cal animated:YES];
}

- (void)locationTapped {
  [self.view endEditing:YES];
  YALMapController *mapController = [[YALMapController alloc] init];
  mapController.selectionMode = YES;

  __weak typeof(self) ws = self;
  mapController.onLocationSelected = ^(CLLocationCoordinate2D coordinate, NSString *locationName) {
    __strong typeof(ws) ss = ws;
    if (!ss) return;
    ss.presetCoordinate = coordinate;
    ss.hasPresetCoordinate = YES;
    ss.presetLocationName = locationName;
    ss.resolvedCityName = nil;
    [ss updateTitleForSelectedLocation];
    [ss updateLocationUI];
    [ss resolveLocationDetailsIfNeeded];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加成功"
                                                                     message:[NSString stringWithFormat:@"%@（%.4f, %.4f）", locationName, coordinate.latitude, coordinate.longitude]
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
      [ss presentViewController:alert animated:YES completion:nil];
    });
  };
  [self.navigationController pushViewController:mapController animated:YES];
}

- (void)resolveLocationDetailsIfNeeded {
  if (!self.hasPresetCoordinate || !CLLocationCoordinate2DIsValid(self.presetCoordinate)) {
    return;
  }
  BOOL shouldReplaceFallbackName = [self isFallbackCoordinateLocationName:self.presetLocationName];
  if (self.resolvedCityName.length > 0 && self.presetLocationName.length > 0 && !shouldReplaceFallbackName) {
    return;
  }

  CLLocation *location = [[CLLocation alloc] initWithLatitude:self.presetCoordinate.latitude
                                                    longitude:self.presetCoordinate.longitude];
  __weak typeof(self) ws = self;
  [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(ws) ss = ws;
      if (!ss || error) return;

      CLPlacemark *placemark = placemarks.firstObject;
      if (!placemark) return;

      NSString *cityName = [ss cityNameFromPlacemark:placemark];
      if (cityName.length > 0) {
        ss.resolvedCityName = cityName;
      }
      if (ss.presetLocationName.length == 0 || [ss isFallbackCoordinateLocationName:ss.presetLocationName]) {
        NSString *locationName = [ss locationNameFromPlacemark:placemark];
        if (locationName.length > 0) {
          ss.presetLocationName = locationName;
          [ss updateTitleForSelectedLocation];
          [ss updateLocationUI];
        }
      }
    });
  }];
}

- (NSString *)locationNameFromPlacemark:(CLPlacemark *)placemark {
  NSMutableArray<NSString *> *parts = [NSMutableArray array];
  if (placemark.locality.length > 0) {
    [parts addObject:placemark.locality];
  } else if (placemark.administrativeArea.length > 0) {
    [parts addObject:placemark.administrativeArea];
  }
  if (placemark.subLocality.length > 0) {
    [parts addObject:placemark.subLocality];
  }
  if (placemark.name.length > 0 && ![parts containsObject:placemark.name]) {
    [parts addObject:placemark.name];
  }
  if (parts.count == 0 && placemark.thoroughfare.length > 0) {
    [parts addObject:placemark.thoroughfare];
  }
  return parts.count > 0 ? [parts componentsJoinedByString:@" "] : @"";
}

- (void)chooseCoverFromLibrary {
  [self.view endEditing:YES];

  if (@available(iOS 14.0, *)) {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.filter = [PHPickerFilter imagesFilter];
    configuration.selectionLimit = 0;

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
    return;
  }

  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  picker.allowsEditing = NO;
  
  [self presentViewController:picker animated:YES completion:nil];
}

- (void)chooseCoverFromCamera {
  [self.view endEditing:YES];

  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    UIAlertController *a =
        [UIAlertController alertControllerWithTitle:@"无法使用相机"
                                            message:@"当前设备不支持拍照功能"
                                     preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
    return;
  }

  // 先检查相机权限，避免出现“黑屏但不弹授权框”的情况
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  if (status == AVAuthorizationStatusNotDetermined) {
    __weak typeof(self) ws = self;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(__unused BOOL granted) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(ws) ss = ws;
        if (!ss) return;
        if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] != AVAuthorizationStatusAuthorized) {
          UIAlertController *a =
              [UIAlertController alertControllerWithTitle:@"没有相机权限"
                                                  message:@"请到系统设置中为该 App 打开“相机”权限后再试。"
                                           preferredStyle:UIAlertControllerStyleAlert];
          [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
          [ss presentViewController:a animated:YES completion:nil];
          return;
        }

        [ss presentCameraPicker];
      });
    }];
    return;
  }

  if (status != AVAuthorizationStatusAuthorized) {
    UIAlertController *a =
        [UIAlertController alertControllerWithTitle:@"没有相机权限"
                                            message:@"请到系统设置中为该 App 打开“相机”权限后再试。"
                                     preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
    return;
  }

  [self presentCameraPicker];
}

#pragma mark - Camera Picker

- (void)presentCameraPicker {
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.sourceType = UIImagePickerControllerSourceTypeCamera;
  picker.allowsEditing = NO;
  if (@available(iOS 13.0, *)) {
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
  }
  [self presentViewController:picker animated:YES completion:nil];
}

- (void)chooseCover {
  [self.view endEditing:YES];

  UIAlertController *sheet =
      [UIAlertController alertControllerWithTitle:nil
                                          message:nil
                                   preferredStyle:UIAlertControllerStyleActionSheet];

  __weak typeof(self) ws = self;
  [sheet addAction:[UIAlertAction actionWithTitle:@"从相册选择"
                                            style:UIAlertActionStyleDefault
                                          handler:^(__unused UIAlertAction * _Nonnull action) {
    __strong typeof(ws) ss = ws;
    if (!ss) return;
    [ss chooseCoverFromLibrary];
  }]];

  [sheet addAction:[UIAlertAction actionWithTitle:@"拍照"
                                            style:UIAlertActionStyleDefault
                                          handler:^(__unused UIAlertAction * _Nonnull action) {
    __strong typeof(ws) ss = ws;
    if (!ss) return;
    [ss chooseCoverFromCamera];
  }]];

  [sheet addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  // iPad 需要 source
  if (sheet.popoverPresentationController) {
    sheet.popoverPresentationController.sourceView = self.photoCollectionView;
    sheet.popoverPresentationController.sourceRect = self.photoCollectionView.bounds;
  }

  [self presentViewController:sheet animated:YES completion:nil];
}

- (void)appendImages:(NSArray<UIImage *> *)images showLimitAlertIfNeeded:(BOOL)showAlert {
  if (images.count == 0) {
    return;
  }

  NSInteger remainingCount = kYALReleaseMaxImageCount - self.selectedImages.count;
  if (remainingCount <= 0) {
    if (showAlert) {
      [self showImageLimitAlertWithMessage:@"最多只能上传 9 张图片，请先删除后再继续添加。"];
    }
    return;
  }

  NSArray<UIImage *> *allowedImages = images;
  if (images.count > remainingCount) {
    allowedImages = [images subarrayWithRange:NSMakeRange(0, remainingCount)];
    if (showAlert) {
      [self showImageLimitAlertWithMessage:[NSString stringWithFormat:@"最多只能上传 9 张图片，本次已保留前 %ld 张。", (long)remainingCount]];
    }
  }

  [self.selectedImages addObjectsFromArray:allowedImages];
  [self updatePhotoSelectionUI];
}

- (void)showImageLimitAlertWithMessage:(NSString *)message {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"图片数量超出限制"
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
  UIImage *img = info[UIImagePickerControllerOriginalImage];
  if (img) {
    [self appendImages:@[img] showLimitAlertIfNeeded:YES];
  }
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14.0)) {
  if (results.count == 0) {
    [picker dismissViewControllerAnimated:YES completion:nil];
    return;
  }

  dispatch_group_t group = dispatch_group_create();
  NSMutableArray<UIImage *> *loadedImages = [NSMutableArray array];
  NSLock *lock = [[NSLock alloc] init];

  for (PHPickerResult *result in results) {
    NSItemProvider *provider = result.itemProvider;
    if (![provider canLoadObjectOfClass:[UIImage class]]) {
      continue;
    }
    dispatch_group_enter(group);
    [provider loadObjectOfClass:[UIImage class] completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
      if (image && !error) {
        [lock lock];
        [loadedImages addObject:image];
        [lock unlock];
      }
      dispatch_group_leave(group);
    }];
  }

  __weak typeof(self) ws = self;
  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    __strong typeof(ws) ss = ws;
    [picker dismissViewControllerAnimated:YES completion:^{
      if (!ss) return;
      [ss appendImages:loadedImages showLimitAlertIfNeeded:YES];
    }];
  });
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (self.selectedImages.count >= kYALReleaseMaxImageCount) {
    return self.selectedImages.count;
  }
  return self.selectedImages.count + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  YALReleasePhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kYALReleasePhotoCellIdentifier forIndexPath:indexPath];
  cell.removeButton.hidden = YES;
  [cell.removeButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];

  BOOL isAddCell = (indexPath.item == self.selectedImages.count && self.selectedImages.count < kYALReleaseMaxImageCount);
  if (isAddCell) {
    cell.cardView.backgroundColor = [self addPhotoBackgroundColor];
    cell.cardView.layer.borderWidth = 1.0;
    cell.cardView.layer.borderColor = [self softBorderColor].CGColor;
    cell.imageView.image = nil;
    if (@available(iOS 13.0, *)) {
      cell.iconView.image = [UIImage systemImageNamed:@"plus.circle.fill"];
    } else {
      cell.iconView.image = nil;
    }
    cell.iconView.tintColor = [self accentColor];
    cell.iconView.hidden = NO;
    cell.titleLabel.text = @"添加图片";
    cell.titleLabel.textColor = [self addPhotoTitleColor];
    cell.subtitleLabel.text = @"相册多选 / 拍照追加";
    cell.subtitleLabel.textColor = [UIColor secondaryLabelColor];
    return cell;
  }

  cell.cardView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
  cell.cardView.layer.borderWidth = 0.0;
  cell.cardView.layer.borderColor = nil;
  cell.imageView.image = self.selectedImages[indexPath.item];
  cell.iconView.hidden = YES;
  cell.titleLabel.text = @"";
  cell.subtitleLabel.text = @"";
  cell.removeButton.hidden = NO;
  cell.removeButton.tag = indexPath.item;
  [cell.removeButton addTarget:self action:@selector(removeSelectedImage:) forControlEvents:UIControlEventTouchUpInside];
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  BOOL isAddCell = (indexPath.item == self.selectedImages.count && self.selectedImages.count < kYALReleaseMaxImageCount);
  if (isAddCell) {
    [self chooseCover];
  }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  CGFloat itemSize = [self photoItemSize];
  return CGSizeMake(itemSize, itemSize);
}

- (void)removeSelectedImage:(UIButton *)sender {
  NSInteger index = sender.tag;
  if (index < 0 || index >= self.selectedImages.count) {
    return;
  }
  [self.selectedImages removeObjectAtIndex:index];
  [self updatePhotoSelectionUI];
}

#pragma mark - 图片压缩工具方法

// 压缩图片到指定文件大小
- (UIImage *)compressImage:(UIImage *)image toMaxFileSize:(NSInteger)maxFileSize {
    CGFloat compression = 0.9f;
    CGFloat maxCompression = 0.1f;
    NSData *imageData = UIImageJPEGRepresentation(image, compression);

    while ([imageData length] > maxFileSize && compression > maxCompression) {
        compression -= 0.1;
        imageData = UIImageJPEGRepresentation(image, compression);
    }

    UIImage *compressedImage = [UIImage imageWithData:imageData];
    return compressedImage;
}

// 调整图片尺寸
- (UIImage *)resizeImage:(UIImage *)image toWidth:(CGFloat)width {
    CGFloat oldWidth = image.size.width;
    CGFloat scaleFactor = width / oldWidth;
    CGFloat newHeight = image.size.height * scaleFactor;
    CGFloat newWidth = oldWidth * scaleFactor;

    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

@end
