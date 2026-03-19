//
//  YALMapController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALMapController.h"
#import "YALMemoryPoint.h"
#import "YALPostDetailController.h"
#import "YALPostModel.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "YALReleaseController.h"
#import <Masonry/Masonry.h>

@interface YALMapController () <MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UIButton *locateButton;
@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) NSLayoutConstraint *searchBottomConstraint;

@end

@implementation YALMapController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.extendedLayoutIncludesOpaqueBars = YES;
    [self setupNavigationBar];

    self.mapView = [[MKMapView alloc] initWithFrame:CGRectZero];
    self.mapView.delegate = self;
    // 1. 统一“干净地图”基础风格
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.showsBuildings = YES;
    self.mapView.showsTraffic = NO;
    if (@available(iOS 13.0, *)) {

        // 仅在系统支持时使用 POI 过滤（避免低版本编译报错）
        Class poiClass = NSClassFromString(@"MKPointOfInterestFilter");
        SEL selector = NSSelectorFromString(@"filterExcludingAllPointsOfInterest");
        if (poiClass && [poiClass respondsToSelector:selector]) {
            id filter = ((id (*)(id, SEL))[poiClass methodForSelector:selector])(poiClass, selector);
            self.mapView.pointOfInterestFilter = filter;
        }
    }

    [self.view addSubview:self.mapView];
    [self.mapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self setupBottomSearchBar];
    [self setupLocateButton];

    // 初始化定位
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    UILongPressGestureRecognizer *longPress =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];

    [self.mapView addGestureRecognizer:longPress];

    // Tap blank to dismiss keyboard
    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBlank)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self applyMapStyleForCurrentTrait];
    static BOOL sDidShowHint = NO;
    if (!sDidShowHint) {
        sDidShowHint = YES;
        [self showAddMemoryHint];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
            [self applyMapStyleForCurrentTrait];
        }
    }
}

- (void)applyMapStyleForCurrentTrait {
    self.mapView.mapType = MKMapTypeStandard;
}

- (void)showAddMemoryHint {
    UIView *hint = [[UIView alloc] initWithFrame:CGRectZero];
    hint.backgroundColor = [UIColor colorWithRed:252/255.0 green:251/255.0 blue:248/255.0 alpha:0.96];
    hint.layer.cornerRadius = 16.0;
    hint.layer.borderWidth = 1.0;
    hint.layer.borderColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:0.25].CGColor;
    hint.alpha = 0.0;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = @"长按地图添加回忆点";
    label.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;

    [hint addSubview:label];
    [self.view addSubview:hint];

    hint.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [hint.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [hint.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12.0],
        [label.leadingAnchor constraintEqualToAnchor:hint.leadingAnchor constant:14.0],
        [label.trailingAnchor constraintEqualToAnchor:hint.trailingAnchor constant:-14.0],
        [label.topAnchor constraintEqualToAnchor:hint.topAnchor constant:8.0],
        [label.bottomAnchor constraintEqualToAnchor:hint.bottomAnchor constant:-8.0]
    ]];

    [UIView animateWithDuration:0.25 animations:^{
        hint.alpha = 1.0;
    } completion:^(__unused BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25
                             animations:^{
                hint.alpha = 0.0;
            } completion:^(__unused BOOL finished2) {
                [hint removeFromSuperview];
            }];
        });
    }];
}

- (void)setupNavigationBar {
    self.title = @"Map";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationController.navigationBar.translucent = YES;

    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithDefaultBackground];
        appearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
        appearance.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
        appearance.titleTextAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName: [UIColor labelColor]
        };
        appearance.shadowColor = nil;
        appearance.shadowImage = [UIImage new];

        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController.navigationBar.compactAppearance = appearance;

        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:1.0 alpha:0.7];
        self.navigationController.navigationBar.tintColor = [UIColor systemBlueColor];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
    }

    self.navigationItem.rightBarButtonItem = nil;
}
- (void)setupBottomSearchBar {
    self.searchContainerView = [[UIView alloc] init];
    self.searchContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchContainerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.96];
    self.searchContainerView.layer.cornerRadius = 16.0;
    self.searchContainerView.layer.masksToBounds = YES;
    self.searchContainerView.layer.borderWidth = 1.0;
    self.searchContainerView.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;

    self.searchTextField = [[UITextField alloc] init];
    self.searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchTextField.placeholder = @"搜索地点、地址或地标";
    self.searchTextField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.searchTextField.returnKeyType = UIReturnKeySearch;
    self.searchTextField.keyboardType = UIKeyboardTypeDefault;
    self.searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchTextField.delegate = self;
    self.searchTextField.leftViewMode = UITextFieldViewModeAlways;
    UIView *leftPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 20)];
    self.searchTextField.leftView = leftPadding;

    self.searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.searchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.searchButton setTitle:@"搜索" forState:UIControlStateNormal];
    self.searchButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [self.searchButton addTarget:self action:@selector(handleSearchButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.searchContainerView addSubview:self.searchTextField];
    [self.searchContainerView addSubview:self.searchButton];
    [self.view addSubview:self.searchContainerView];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    self.searchBottomConstraint =
    [self.searchContainerView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-12.0];
    [NSLayoutConstraint activateConstraints:@[self.searchBottomConstraint]];

    // 其余位置和内部布局用 Masonry，和项目整体保持一致
    [self.searchContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view.mas_leading).offset(14.0);
        make.trailing.equalTo(self.view.mas_trailing).offset(-14.0);
        make.height.mas_equalTo(54.0);
    }];

    [self.searchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.searchContainerView.mas_trailing).offset(-12.0);
        make.centerY.equalTo(self.searchContainerView.mas_centerY);
        make.width.mas_equalTo(44.0);
    }];

    [self.searchTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.searchContainerView.mas_leading).offset(10.0);
        make.trailing.equalTo(self.searchButton.mas_leading).offset(-8.0);
        make.centerY.equalTo(self.searchContainerView.mas_centerY);
        make.height.mas_equalTo(40.0);
    }];
}

- (void)addMemoryPointAtCoordinate:(CLLocationCoordinate2D)coordinate {
    YALMemoryPoint *annotation = [YALMemoryPoint pointWithCoordinate:coordinate
                                                               title:@"新的回忆"
                                                            subtitle:@"点气泡后，左删右看"
                                                          detailText:@"刚刚在地图上留下的新记忆"
                                                         userCreated:YES];

    [self.mapView addAnnotation:annotation];
    [self.mapView selectAnnotation:annotation animated:YES];
}

- (void)setupLocateButton {
    self.locateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.locateButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.locateButton.layer.cornerRadius = 26.0;
    self.locateButton.layer.masksToBounds = YES;
    self.locateButton.tintColor = [UIColor systemBlueColor];
    self.locateButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.98];
    self.locateButton.layer.borderWidth = 1.0;
    self.locateButton.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;

    if (@available(iOS 13.0, *)) {
        [self.locateButton setImage:[UIImage systemImageNamed:@"location.fill"] forState:UIControlStateNormal];
    } else {
        [self.locateButton setTitle:@"定位" forState:UIControlStateNormal];
    }

    [self.locateButton addTarget:self
                          action:@selector(handleLocateButtonTapped)
                forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.locateButton];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    NSLayoutYAxisAnchor *bottomAnchorTarget = self.searchContainerView ? self.searchContainerView.topAnchor : safeArea.bottomAnchor;
    CGFloat bottomConstant = self.searchContainerView ? -12.0 : -24.0;
    // 底部约束保持用系统 anchor，保证和 safeArea 行为一致
    [NSLayoutConstraint activateConstraints:@[
        [self.locateButton.bottomAnchor constraintEqualToAnchor:bottomAnchorTarget constant:bottomConstant]
    ]];

    // 其余宽高与水平位置使用 Masonry
    [self.locateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.view.mas_trailing).offset(-16.0);
        make.width.height.mas_equalTo(52.0);
    }];
}

- (void)openReleaseController {
    YALReleaseController *release = [[YALReleaseController alloc] init];
    release.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:release animated:YES];
}

- (void)handleSearchButtonTapped {
    NSString *query = [self.searchTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (query.length == 0) {
        return;
    }
    [self.searchTextField resignFirstResponder];

    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = query;
    request.region = self.mapView.region;

    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    __weak typeof(self) weakSelf = self;
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }

        MKMapItem *firstItem = response.mapItems.firstObject;
        if (error || !firstItem) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"未找到地点"
                                                                           message:@"换个关键词试试，例如商圈、地铁站、景点名。"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
            [strongSelf presentViewController:alert animated:YES completion:nil];
            return;
        }

        CLLocationCoordinate2D coordinate = firstItem.placemark.coordinate;
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 1200, 1200);
        [strongSelf.mapView setRegion:region animated:YES];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self handleSearchButtonTapped];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    (void)textField;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrameForMap:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    (void)textField;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    self.searchBottomConstraint.constant = -12.0;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)handleLocateButtonTapped {
    CLAuthorizationStatus status;
    if (@available(iOS 14.0, *)) {
        status = self.locationManager.authorizationStatus;
    } else {
        status = [CLLocationManager authorizationStatus];
    }

    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
        return;
    }

    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        [self activateUserLocationTracking];
    }
}

- (void)activateUserLocationTracking {
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    [self.locationManager startUpdatingLocation];

    CLLocation *currentLocation = self.locationManager.location ?: self.mapView.userLocation.location;
    if (currentLocation) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 800, 800);
        [self.mapView setRegion:region animated:YES];
    }
}


- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {

    if (gesture.state != UIGestureRecognizerStateBegan) return;

    CGPoint point = [gesture locationInView:self.mapView];

    CLLocationCoordinate2D coordinate =
    [self.mapView convertPoint:point toCoordinateFromView:self.mapView];

    UIAlertController *sheet =
        [UIAlertController alertControllerWithTitle:@"长按操作"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"添加标点"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        [strongSelf addMemoryPointAtCoordinate:coordinate];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"去发布"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        YALReleaseController *release = [[YALReleaseController alloc] init];
        release.hidesBottomBarWhenPushed = YES;
        if (strongSelf.navigationController) {
            [strongSelf.navigationController pushViewController:release animated:YES];
        } else {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:release];
            [strongSelf presentViewController:nav animated:YES completion:nil];
        }
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    // iPad 上 ActionSheet 必须设置锚点
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.mapView;
        popover.sourceRect = CGRectMake(point.x, point.y, 1, 1);
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }

    [self presentViewController:sheet animated:YES completion:nil];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {

    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }

    static NSString *identifier = @"memoryAnnotation";

    MKMarkerAnnotationView *view =
    (MKMarkerAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];

    if (!view) {

        view = [[MKMarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];

        view.canShowCallout = YES;
        view.markerTintColor = [UIColor systemOrangeColor];
        view.clusteringIdentifier = @"memory";

    }

    view.annotation = annotation;

    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImage *trash = [UIImage systemImageNamed:@"trash"];
        if (trash) {
            [deleteBtn setImage:trash forState:UIControlStateNormal];
        }
    }
    if (@available(iOS 13.0, *)) {
        if (!deleteBtn.currentImage) {
            [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        }
    } else {
        [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    }
    deleteBtn.tintColor = [UIColor systemRedColor];
    deleteBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    deleteBtn.contentEdgeInsets = UIEdgeInsetsMake(4.0, 6.0, 4.0, 6.0);
    deleteBtn.frame = CGRectMake(0, 0, 30, 30);
    view.leftCalloutAccessoryView = deleteBtn;

    UIButton *detailBtn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    view.rightCalloutAccessoryView = detailBtn;

    if ([annotation isKindOfClass:[YALMemoryPoint class]]) {
        YALMemoryPoint *memoryAnnotation = (YALMemoryPoint *)annotation;
        view.leftCalloutAccessoryView.hidden = !memoryAnnotation.userCreated;
    }

    return view;
}



- (void)mapView:(MKMapView *)mapView
annotationView:(MKAnnotationView *)view
calloutAccessoryControlTapped:(UIControl *)control {
    id<MKAnnotation> annotation = view.annotation;
    if (![annotation isKindOfClass:[YALMemoryPoint class]]) {
        return;
    }

    YALMemoryPoint *memoryAnnotation = (YALMemoryPoint *)annotation;
    if (control == view.leftCalloutAccessoryView && memoryAnnotation.userCreated) {
        [self confirmDeleteAnnotation:memoryAnnotation];
        return;    }

    if (control == view.rightCalloutAccessoryView) {
        [self showDetailForAnnotation:memoryAnnotation];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    id<MKAnnotation> annotation = view.annotation;
    if (![annotation isKindOfClass:[YALMemoryPoint class]]) {
        return;
    }

    YALMemoryPoint *memoryAnnotation = (YALMemoryPoint *)annotation;
    if (memoryAnnotation.userCreated) {
        memoryAnnotation.subtitle = @"左边垃圾桶删除，右边进入详情";
    } else {
        memoryAnnotation.subtitle = @"右边进入详情";
    }
}


- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {

    CLAuthorizationStatus status = manager.authorizationStatus;

    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        [self activateUserLocationTracking];
    }
}

- (void)confirmDeleteAnnotation:(YALMemoryPoint *)annotation {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除这条记忆？"
                                                                   message:@"删除后将从地图上移除这个记忆点。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction *action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        [strongSelf.mapView removeAnnotation:annotation];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showDetailForAnnotation:(YALMemoryPoint *)annotation {
    YALPostModel *post = [[YALPostModel alloc] init];
    if (@available(iOS 13.0, *)) {
        post.image = [UIImage systemImageNamed:@"photo"];
    } else {
        post.image = [[UIImage alloc] init];
    }
    post.imageWidth = MAX(post.image.size.width, 1.0);
    post.imageHeight = MAX(post.image.size.height, 1.0);
    post.title = annotation.title.length > 0 ? annotation.title : @"地图记忆";
    post.desc = annotation.detailText.length > 0
        ? annotation.detailText
        : [NSString stringWithFormat:@"经纬度：%.4f, %.4f", annotation.coordinate.latitude, annotation.coordinate.longitude];

    YALPostDetailController *detail = [[YALPostDetailController alloc] init];
    detail.post = post;
    detail.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detail animated:YES];
}


- (void)handleTapBlank {
    [self.view endEditing:YES];
}


- (void)keyboardWillChangeFrameForMap:(NSNotification *)note {
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
    // Map 里搜索条更贴近键盘一点
    CGFloat gap = 4.0;
    CGFloat offset = -MAX(0, keyboardHeightInView - safeBottom + gap);
    self.searchBottomConstraint.constant = offset - 12.0;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

@end
