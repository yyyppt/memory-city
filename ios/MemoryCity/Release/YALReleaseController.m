//
//  YALReleaseController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALReleaseController.h"
#import "YALCalendarController.h"
#import "../Network/NetworkManager/YALContentManager.h"
#import <Masonry/Masonry.h>

@interface YALReleaseController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, nullable) UIImage *editCoverImage;
@property (nonatomic, copy, nullable) NSString *editDateText;
@property (nonatomic, copy, nullable) NSString *editTitleText;
@property (nonatomic, copy, nullable) NSString *editBody;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong, nullable) NSDate *selectedDate;

@end

@implementation YALReleaseController

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

  self.titleField = [[UITextField alloc] init];
  self.titleField.backgroundColor = [UIColor clearColor];
  self.titleField.textColor = [UIColor labelColor];
  self.titleField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
  self.titleField.placeholder = @"输入标题";
  self.titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
  self.titleField.returnKeyType = UIReturnKeyNext;
  if (@available(iOS 12.0, *)) {
      self.titleField.textContentType = UITextContentTypeOneTimeCode; // 关闭自动填充/建议
  }
  [card addSubview:self.titleField];

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
  [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.dateLabel.mas_bottom).offset(8);
    make.left.right.equalTo(self.coverImageView);
    make.height.mas_equalTo(40);
  }];
  [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.titleField.mas_bottom).offset(8);
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
  self.titleField.text = self.editTitleText.length > 0 ? self.editTitleText : @"";
  self.textView.text = self.editBody.length > 0 ? self.editBody : @"写下此刻的心情…";
}

#pragma mark - Actions

- (void)submitTapped {
  self.editTitleText = self.titleField.text ?: @"";
  self.editBody = self.textView.text ?: @"";
  BOOL isEdit = (self.editCoverImage != nil) || (self.editBody.length > 0) || (self.editDateText.length > 0);

  // 收集发布参数（这里使用固定值，实际应用中应该从用户输入获取）
  NSString *title = [self.editTitleText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (title.length == 0) {
      title = isEdit ? @"编辑后的标题" : @"新发布的标题";
  }
  NSString *content = self.editBody;
  NSString *city = @"北京";
  NSString *year = @"2026";
  NSString *mood = @"开心";
  NSString *locationName = @"北京市海淀区";
  double latitude = 39.9042;
  double longitude = 116.4074;
  BOOL isPublic = YES;

  // 打印发布参数
  NSLog(@"🚀 开始发布内容：");
  NSLog(@"📝 标题: %@", title);
  NSLog(@"📄 内容: %@", content);
  NSLog(@"🏙️ 城市: %@", city);
  NSLog(@"📅 年代: %@", year);
  NSLog(@"😊 情绪: %@", mood);
  NSLog(@"📍 地点: %@", locationName);
  NSLog(@"🌍 经纬度: %f, %f", latitude, longitude);
  NSLog(@"🔓 公开: %@", isPublic ? @"是" : @"否");

  // 图片处理：如果有选择的图片，转换为Base64
  NSMutableArray *images = [NSMutableArray array];
  if (self.editCoverImage) {
      // 将图片转换为Base64字符串
      // 先压缩图片，避免Base64字符串过大
      UIImage *compressedImage = [self compressImage:self.editCoverImage toMaxFileSize:1024*500]; // 最大500KB
      NSData *imageData = UIImageJPEGRepresentation(compressedImage, 0.7); // 70%质量压缩
      if (imageData) {
          NSString *base64String = [imageData base64EncodedStringWithOptions:0];
          if (base64String) {
              [images addObject:base64String];
              NSLog(@"🖼️ 图片已转换为Base64，原始大小: %.2fKB，压缩后: %.2fKB，Base64长度: %lu字符",
                    UIImageJPEGRepresentation(self.editCoverImage, 1.0).length/1024.0,
                    imageData.length/1024.0,
                    (unsigned long)base64String.length);
          }
      }
  }
  NSLog(@"🖼️ 图片数量: %lu", (unsigned long)images.count);

  // 显示加载提示
  UIAlertController *loadingAlert = [UIAlertController alertControllerWithTitle:@"发布中" message:@"正在发送网络请求，请稍候..." preferredStyle:UIAlertControllerStyleAlert];
  [self presentViewController:loadingAlert animated:YES completion:nil];

  // 调用发布接口
  NSLog(@"📡 发送网络请求到 /content/publish");
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
          // 打印发布成功日志
          NSLog(@"✅ 发布成功！");
          NSLog(@"📌 内容ID: %@", contentId);
          NSLog(@"💬 服务器消息: %@", message);
          NSLog(@"🎯 发布内容已保存到服务器");

          UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"发布成功" message:[NSString stringWithFormat:@"%@\n内容ID: %@\n\n发布内容已保存到服务器", message, contentId] preferredStyle:UIAlertControllerStyleAlert];
          [successAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 发布成功后返回上一页
            [self.navigationController popViewControllerAnimated:YES];
          }]];
          [self presentViewController:successAlert animated:YES completion:nil];
        } else {
          // 打印发布失败日志
          NSString *errorMsg = error ? error.localizedDescription : message;
          NSLog(@"❌ 发布失败！");
          NSLog(@"💥 错误: %@", error);
          NSLog(@"💬 错误消息: %@", message);

          UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"发布失败" message:[NSString stringWithFormat:@"%@\n\n请检查网络连接或稍后重试", errorMsg] preferredStyle:UIAlertControllerStyleAlert];
          [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
          [self presentViewController:errorAlert animated:YES completion:nil];
        }
      }];
    });
  }];
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
