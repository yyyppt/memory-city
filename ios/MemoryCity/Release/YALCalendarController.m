#import "YALCalendarController.h"
#import <Masonry/Masonry.h>

@interface YALCalendarController ()

@property (nonatomic, strong) UIDatePicker *datePicker;

@end

@implementation YALCalendarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择日期";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UIColor *accent;
    if (@available(iOS 13.0, *)) {
        accent = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor systemOrangeColor];
            }
            return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
        }];
    } else {
        accent = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    }
    self.navigationController.navigationBar.tintColor = accent;
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(doneTapped)];
    self.navigationItem.rightBarButtonItem.tintColor = accent;

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 18;
    card.layer.masksToBounds = YES;
    [self.view addSubview:card];

    _datePicker = [[UIDatePicker alloc] init];
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

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(12);
        make.left.equalTo(self.view.mas_left).offset(16);
        make.right.equalTo(self.view.mas_right).offset(-16);
        make.height.mas_equalTo(370);
    }];
    [_datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card);
    }];
}

- (void)doneTapped {
    NSDate *picked = self.datePicker.date ?: [NSDate date];
    if (self.onDatePicked) {
        self.onDatePicked(picked);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
