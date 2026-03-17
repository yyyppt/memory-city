//
//  YALTimeLineDetailController.m
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "YALTimeLineDetailController.h"
#import "YALTimeLineDetailView.h"
#import "YALReleaseController.h"

@interface YALTimeLineDetailController ()

@property (nonatomic, strong) YALTimeLineDetailView *detailView;
@property (nonatomic, assign) NSInteger likeCount;

@end

@implementation YALTimeLineDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.likeCount = 128; // 先写死一组示例数据

    UIColor *accent = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
    self.navigationController.navigationBar.tintColor = accent;

    self.title = self.dateText.length > 0 ? self.dateText : @"详情";

    if (@available(iOS 13.0, *)) {
      UIBarButtonItem *edit =
        [[UIBarButtonItem alloc] initWithTitle:@"编辑"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(editTapped)];
      edit.tintColor = accent;
      self.navigationItem.rightBarButtonItem = edit;
    } else {
      UIBarButtonItem *edit =
        [[UIBarButtonItem alloc] initWithTitle:@"编辑"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(editTapped)];
      self.navigationItem.rightBarButtonItem = edit;
    }

    self.detailView = [[YALTimeLineDetailView alloc] initWithFrame:self.view.bounds];
    self.detailView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.detailView];

    NSString *fixedBody =
      @"那天的风很轻，街角的光落在墙上像一张旧照片。我们把不舍藏进笑里，把温柔留给时间。";

    [self.detailView configureWithDateText:(self.dateText ?: @"")
                                     image:self.coverImage
                                      body:fixedBody
                                 likeCount:self.likeCount];

    [self.detailView.likeButton addTarget:self action:@selector(likeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.detailView.commentButton addTarget:self action:@selector(commentTapped) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Actions

- (void)editTapped {
  NSString *body = self.detailView.bodyLabel.text ?: @"";
  YALReleaseController *release =
    [[YALReleaseController alloc] initWithEditCoverImage:self.coverImage
                                                dateText:self.dateText
                                                    body:body];
  release.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:release animated:YES];
}

- (void)likeTapped {
  self.likeCount += 1;
  [self.detailView configureWithDateText:(self.dateText ?: @"")
                                   image:self.coverImage
                                    body:self.detailView.bodyLabel.text ?: @""
                               likeCount:self.likeCount];
}

- (void)commentTapped {
  UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"评论"
                                        message:@"这里后续接评论列表/输入框。"
                                 preferredStyle:UIAlertControllerStyleActionSheet];
  [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
