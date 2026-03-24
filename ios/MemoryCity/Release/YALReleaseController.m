//
//  YALReleaseController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALReleaseController.h"
#import "YALCalendarController.h"
#import <Masonry/Masonry.h>

@interface YALReleaseController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, nullable) UIImage *editCoverImage;
@property (nonatomic, copy, nullable) NSString *editDateText;
@property (nonatomic, copy, nullable) NSString *editBody;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong, nullable) NSDate *selectedDate;

@end

@implementation YALReleaseController

- (instancetype)initWithEditCoverImage:(UIImage *)coverImage
                              dateText:(NSString *)dateText
                                  body:(NSString *)body {
  self = [super init];
  if (self) {
    _editCoverImage = coverImage;
    _editDateText = [dateText copy];
    _editBody = [body copy];
  }
  return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UIColor *accent = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
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
    [self applyPrefillIfNeeded];

    // 点击空白收起键盘
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
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

  self.contentView = [[UIView alloc] init];
  self.contentView.backgroundColor = [UIColor clearColor];
  [self.scrollView addSubview:self.contentView];
  [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.scrollView);
    make.width.equalTo(self.scrollView);
  }];

  UIView *card = [[UIView alloc] init];
  card.backgroundColor = [UIColor secondarySystemBackgroundColor];
  card.layer.cornerRadius = 18.0;
  card.layer.masksToBounds = YES;
  [self.contentView addSubview:card];

  self.coverImageView = [[UIImageView alloc] init];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
  self.coverImageView.layer.cornerRadius = 14.0;
  self.coverImageView.layer.masksToBounds = YES;
  [card addSubview:self.coverImageView];

  self.coverImageView.userInteractionEnabled = YES;
  UITapGestureRecognizer *imgTap =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseCoverFromLibrary)];
  imgTap.cancelsTouchesInView = NO;
  [self.coverImageView addGestureRecognizer:imgTap];

  self.dateLabel = [[UILabel alloc] init];
  self.dateLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
  self.dateLabel.textColor = [UIColor secondaryLabelColor];
  [card addSubview:self.dateLabel];

  self.dateLabel.userInteractionEnabled = YES;
  UITapGestureRecognizer *dateTap =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseDate)];
  dateTap.cancelsTouchesInView = NO;
  [self.dateLabel addGestureRecognizer:dateTap];

  self.textView = [[UITextView alloc] init];
  self.textView.backgroundColor = [UIColor clearColor];
  self.textView.textColor = [UIColor labelColor];
  self.textView.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
  self.textView.textContainerInset = UIEdgeInsetsMake(8, 6, 8, 6);
  [card addSubview:self.textView];

  CGFloat imageH = MIN(260.0, [UIScreen mainScreen].bounds.size.width * 0.68);

  [card mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.contentView.mas_top).offset(14);
    make.left.equalTo(self.contentView.mas_left).offset(16);
    make.right.equalTo(self.contentView.mas_right).offset(-16);
    make.bottom.equalTo(self.contentView.mas_bottom).offset(-18);
  }];
  [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(card.mas_top).offset(14);
    make.left.equalTo(card.mas_left).offset(14);
    make.right.equalTo(card.mas_right).offset(-14);
    make.height.mas_equalTo(imageH);
  }];
  [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.coverImageView.mas_bottom).offset(10);
    make.left.right.equalTo(self.coverImageView);
    make.height.mas_equalTo(18);
  }];
  [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.dateLabel.mas_bottom).offset(8);
    make.left.right.equalTo(self.coverImageView);
    make.height.mas_equalTo(220);
    make.bottom.equalTo(card.mas_bottom).offset(-14);
  }];
}

- (void)applyPrefillIfNeeded {
  if (self.editCoverImage) {
    self.coverImageView.image = self.editCoverImage;
  } else {
    if (@available(iOS 13.0, *)) {
      self.coverImageView.image = [UIImage systemImageNamed:@"photo"];
      self.coverImageView.tintColor = [UIColor tertiaryLabelColor];
      self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
      self.coverImageView.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    } else {
      self.coverImageView.image = nil;
      self.coverImageView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    }
  }

  self.dateLabel.text = self.editDateText.length > 0 ? self.editDateText : @"选择日期";
  if (self.editDateText.length > 0) {
      NSDate *parsed = [self dateFromDateText:self.editDateText];
      self.selectedDate = parsed;
  } else {
      self.selectedDate = nil;
  }
  self.textView.text = self.editBody.length > 0 ? self.editBody : @"写下此刻的心情…";
}

#pragma mark - Actions

- (void)submitTapped {
  self.editBody = self.textView.text ?: @"";
  BOOL isEdit = (self.editCoverImage != nil) || (self.editBody.length > 0) || (self.editDateText.length > 0);
  NSString *title = isEdit ? @"已重新发布（示例）" : @"已发布（示例）";
  UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:@"这里后续接发布/保存接口。"
                                 preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Keyboard

- (void)dismissKeyboard {
  [self.view endEditing:YES];
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

- (void)chooseCoverFromLibrary {
  [self.view endEditing:YES];

  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
    return;
  }

  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  picker.allowsEditing = NO;
  [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
  UIImage *img = info[UIImagePickerControllerOriginalImage];
  if (img) {
    self.editCoverImage = img;
    self.coverImageView.image = img;
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
  }
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
