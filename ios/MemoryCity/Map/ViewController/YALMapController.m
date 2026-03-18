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

@interface YALMapController () <MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UIButton *locateButton;
@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UIButton *searchButton;

@end

@implementation YALMapController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.extendedLayoutIncludesOpaqueBars = YES;
    [self setupNavigationBar];

    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;

    [self.view addSubview:self.mapView];
    [self setupBottomSearchBar];
    [self setupLocateButton];

    // 初始化定位
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    UILongPressGestureRecognizer *longPress =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];

    [self.mapView addGestureRecognizer:longPress];
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

        // 移除分隔线
        appearance.shadowColor = nil;
        appearance.shadowImage = [UIImage new];

        // 应用到所有状态
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController.navigationBar.compactAppearance = appearance;

        // 当滚动到边缘时的效果
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        // iOS 13以下版本的设置
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
    [NSLayoutConstraint activateConstraints:@[
        [self.searchContainerView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:14.0],
        [self.searchContainerView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-14.0],
        [self.searchContainerView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-12.0],
        [self.searchContainerView.heightAnchor constraintEqualToConstant:54.0],

        [self.searchButton.trailingAnchor constraintEqualToAnchor:self.searchContainerView.trailingAnchor constant:-12.0],
        [self.searchButton.centerYAnchor constraintEqualToAnchor:self.searchContainerView.centerYAnchor],
        [self.searchButton.widthAnchor constraintEqualToConstant:44.0],

        [self.searchTextField.leadingAnchor constraintEqualToAnchor:self.searchContainerView.leadingAnchor constant:10.0],
        [self.searchTextField.trailingAnchor constraintEqualToAnchor:self.searchButton.leadingAnchor constant:-8.0],
        [self.searchTextField.centerYAnchor constraintEqualToAnchor:self.searchContainerView.centerYAnchor],
        [self.searchTextField.heightAnchor constraintEqualToConstant:40.0]
    ]];
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
    [NSLayoutConstraint activateConstraints:@[
        [self.locateButton.widthAnchor constraintEqualToConstant:52.0],
        [self.locateButton.heightAnchor constraintEqualToConstant:52.0],
        [self.locateButton.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-16.0],
        [self.locateButton.bottomAnchor constraintEqualToAnchor:bottomAnchorTarget constant:bottomConstant]
    ]];
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
        return;
    }

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

@end
