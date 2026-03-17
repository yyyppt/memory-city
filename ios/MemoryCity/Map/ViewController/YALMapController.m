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

@interface YALMapController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UIButton *locateButton;

@end

@implementation YALMapController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    // 初始化地图
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;

    [self.view addSubview:self.mapView];
    [self setupLocateButton];

    // 初始化定位
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    // 长按手势（添加回忆）
    UILongPressGestureRecognizer *longPress =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];

    [self.mapView addGestureRecognizer:longPress];
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
    [NSLayoutConstraint activateConstraints:@[
        [self.locateButton.widthAnchor constraintEqualToConstant:52.0],
        [self.locateButton.heightAnchor constraintEqualToConstant:52.0],
        [self.locateButton.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-16.0],
        [self.locateButton.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-24.0]
    ]];
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

    // 创建标记
    YALMemoryPoint *annotation = [YALMemoryPoint pointWithCoordinate:coordinate
                                                               title:@"新的回忆"
                                                            subtitle:@"点气泡后，左删右看"
                                                          detailText:@"刚刚在地图上留下的新记忆"
                                                         userCreated:YES];

    [self.mapView addAnnotation:annotation];
    [self.mapView selectAnnotation:annotation animated:YES];
}

#pragma mark - 自定义标记样式

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
