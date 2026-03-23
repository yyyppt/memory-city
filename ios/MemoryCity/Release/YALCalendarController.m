#import "YALCalendarController.h"

@interface YALCalendarController ()

@property (nonatomic, strong) UIDatePicker *datePicker;

@end

@implementation YALCalendarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择日期";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UIColor *accent = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
    self.navigationController.navigationBar.tintColor = accent;
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(doneTapped)];
    self.navigationItem.rightBarButtonItem.tintColor = accent;

    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 18;
    card.layer.masksToBounds = YES;
    [self.view addSubview:card];

    _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
    _datePicker.datePickerMode = UIDatePickerModeDate;
    _datePicker.maximumDate = [NSDate date];
    _datePicker.backgroundColor = [UIColor clearColor];
    if (self.selectedDate) {
        _datePicker.date = self.selectedDate;
    }
    if (@available(iOS 14.0, *)) {
        _datePicker.preferredDatePickerStyle = UIDatePickerStyleInline;
    } else {
        if (@available(iOS 13.4, *)) {
            _datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
        }
    }
    [card addSubview:_datePicker];

    _datePicker.layer.masksToBounds = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat side = 16;
    CGFloat top = self.view.safeAreaInsets.top + 12;
    CGFloat w = self.view.bounds.size.width;
    UIView *card = self.view.subviews.firstObject;
    card.frame = CGRectMake(side, top, w - side * 2, 370);
    self.datePicker.frame = CGRectMake(0, 0, card.bounds.size.width, card.bounds.size.height);
}

- (void)doneTapped {
    NSDate *picked = self.datePicker.date ?: [NSDate date];
    if (self.onDatePicked) {
        self.onDatePicked(picked);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end

