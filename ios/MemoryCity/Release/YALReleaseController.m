//
//  YALReleaseController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALReleaseController.h"

@interface YALReleaseController ()

@property (nonatomic, strong, nullable) UIImage *editCoverImage;
@property (nonatomic, copy, nullable) NSString *editDateText;
@property (nonatomic, copy, nullable) NSString *editBody;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UITextView *textView;

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
}

#pragma mark - UI

- (void)buildUI {
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  self.scrollView.alwaysBounceVertical = YES;
  self.scrollView.showsVerticalScrollIndicator = NO;
  self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:self.scrollView];

  self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 1)];
  self.contentView.backgroundColor = [UIColor clearColor];
  [self.scrollView addSubview:self.contentView];

  CGFloat width = CGRectGetWidth(self.view.bounds);
  CGFloat side = 16.0;

  UIView *card = [[UIView alloc] initWithFrame:CGRectMake(side, 14.0, width - side * 2, 10)];
  card.backgroundColor = [UIColor secondarySystemBackgroundColor];
  card.layer.cornerRadius = 18.0;
  card.layer.masksToBounds = YES;
  [self.contentView addSubview:card];

  self.coverImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
  self.coverImageView.layer.cornerRadius = 14.0;
  self.coverImageView.layer.masksToBounds = YES;
  [card addSubview:self.coverImageView];

  self.dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.dateLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
  self.dateLabel.textColor = [UIColor secondaryLabelColor];
  [card addSubview:self.dateLabel];

  self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
  self.textView.backgroundColor = [UIColor clearColor];
  self.textView.textColor = [UIColor labelColor];
  self.textView.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
  self.textView.textContainerInset = UIEdgeInsetsMake(8, 6, 8, 6);
  [card addSubview:self.textView];

  // layout
  CGFloat inner = 14.0;
  CGFloat cardW = CGRectGetWidth(card.bounds);
  CGFloat imageH = MIN(260.0, width * 0.68);
  self.coverImageView.frame = CGRectMake(inner, inner, cardW - inner * 2, imageH);
  self.dateLabel.frame = CGRectMake(inner, CGRectGetMaxY(self.coverImageView.frame) + 10.0, cardW - inner * 2, 18.0);
  self.textView.frame = CGRectMake(inner,
                                   CGRectGetMaxY(self.dateLabel.frame) + 8.0,
                                   cardW - inner * 2,
                                   220.0);
  CGFloat cardH = CGRectGetMaxY(self.textView.frame) + inner;
  CGRect cardFrame = card.frame;
  cardFrame.size.height = cardH;
  card.frame = cardFrame;

  CGFloat contentH = CGRectGetMaxY(card.frame) + 18.0;
  self.contentView.frame = CGRectMake(0, 0, width, contentH);
  self.scrollView.contentSize = CGSizeMake(width, contentH);
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
  self.textView.text = self.editBody.length > 0 ? self.editBody : @"写下此刻的心情…";
}

#pragma mark - Actions

- (void)submitTapped {
  BOOL isEdit = (self.editCoverImage != nil) || (self.editBody.length > 0) || (self.editDateText.length > 0);
  NSString *title = isEdit ? @"已重新发布（示例）" : @"已发布（示例）";
  UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:@"这里后续接发布/保存接口。"
                                 preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
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
