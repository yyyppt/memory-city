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
#import "YALContentManager.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "YALReleaseController.h"
#import <Masonry/Masonry.h>
#import <float.h>
#import <math.h>

@interface YALMapController () <MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) UIButton *locateButton;
@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) MASConstraint *searchBottomConstraint;
@property (nonatomic, assign) BOOL hasLoadedContentPoints;

@end

@implementation YALMapController

- (UIColor *)accentColor {
    return [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
}

- (UIColor *)accentBorderColor {
    return [[self accentColor] colorWithAlphaComponent:0.28];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.geocoder = [[CLGeocoder alloc] init];
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
    [self loadPublishedMemoryPointsIfNeeded:YES];
    static BOOL sDidShowHint = NO;
    if (!self.selectionMode && !sDidShowHint) {
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
    hint.backgroundColor = [[UIColor secondarySystemBackgroundColor] colorWithAlphaComponent:0.96];
    hint.layer.cornerRadius = 16.0;
    hint.layer.borderWidth = 1.0;
    hint.layer.borderColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:0.25].CGColor;
    hint.alpha = 0.0;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = @"长按地图发布作品";
    label.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.2 alpha:1.0];
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;

    [hint addSubview:label];
    [self.view addSubview:hint];

    [hint mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(12.0);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(hint.mas_left).offset(14.0);
        make.right.equalTo(hint.mas_right).offset(-14.0);
        make.top.equalTo(hint.mas_top).offset(8.0);
        make.bottom.equalTo(hint.mas_bottom).offset(-8.0);
    }];

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
    self.title = self.selectionMode ? @"选择地点" : @"Map";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationController.navigationBar.translucent = YES;

    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithDefaultBackground];
        appearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
        appearance.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.7];
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
        self.navigationController.navigationBar.tintColor = [self accentColor];
    } else {
        self.navigationController.navigationBar.barTintColor = [UIColor systemBackgroundColor];
        self.navigationController.navigationBar.tintColor = [self accentColor];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
    }

    self.navigationItem.rightBarButtonItem = nil;
}
- (void)setupBottomSearchBar {
    self.searchContainerView = [[UIView alloc] init];
    self.searchContainerView.backgroundColor = [[UIColor secondarySystemBackgroundColor] colorWithAlphaComponent:0.96];
    self.searchContainerView.layer.cornerRadius = 16.0;
    self.searchContainerView.layer.masksToBounds = YES;
    self.searchContainerView.layer.borderWidth = 1.0;
    self.searchContainerView.layer.borderColor = [self accentBorderColor].CGColor;

    self.searchTextField = [[UITextField alloc] init];
    self.searchTextField.placeholder = @"搜索地点、地址或地标";
    self.searchTextField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.searchTextField.returnKeyType = UIReturnKeySearch;
    self.searchTextField.keyboardType = UIKeyboardTypeDefault;
    self.searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchTextField.delegate = self;
    self.searchTextField.leftViewMode = UITextFieldViewModeAlways;
    self.searchTextField.tintColor = [self accentColor];
    UIView *leftPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 20)];
    self.searchTextField.leftView = leftPadding;

    self.searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.searchButton setTitle:@"搜索" forState:UIControlStateNormal];
    self.searchButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [self.searchButton setTitleColor:[self accentColor] forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(handleSearchButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.searchContainerView addSubview:self.searchTextField];
    [self.searchContainerView addSubview:self.searchButton];
    [self.view addSubview:self.searchContainerView];

    [self.searchContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(14.0);
        make.right.equalTo(self.view.mas_right).offset(-14.0);
        make.height.mas_equalTo(54.0);
        self.searchBottomConstraint = make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12.0);
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

- (void)setupLocateButton {
    self.locateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.locateButton.layer.cornerRadius = 26.0;
    self.locateButton.layer.masksToBounds = YES;
    self.locateButton.tintColor = [self accentColor];
    self.locateButton.backgroundColor = [[UIColor secondarySystemBackgroundColor] colorWithAlphaComponent:0.98];
    self.locateButton.layer.borderWidth = 1.0;
    self.locateButton.layer.borderColor = [self accentBorderColor].CGColor;

    if (@available(iOS 13.0, *)) {
        [self.locateButton setImage:[UIImage systemImageNamed:@"location.fill"] forState:UIControlStateNormal];
    } else {
        [self.locateButton setTitle:@"定位" forState:UIControlStateNormal];
    }

    [self.locateButton addTarget:self
                          action:@selector(handleLocateButtonTapped)
                forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.locateButton];

    [self.locateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.view.mas_trailing).offset(-16.0);
        make.width.height.mas_equalTo(52.0);
        if (self.searchContainerView) {
            make.bottom.equalTo(self.searchContainerView.mas_top).offset(-12.0);
        } else {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24.0);
        }
    }];
}

- (void)openReleaseController {
    [self openReleaseControllerWithCoordinate:kCLLocationCoordinate2DInvalid locationName:nil];
}

- (void)openReleaseControllerWithCoordinate:(CLLocationCoordinate2D)coordinate
                               locationName:(NSString *)locationName {
    YALReleaseController *release = [[YALReleaseController alloc] init];
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        release.presetCoordinate = coordinate;
        release.hasPresetCoordinate = YES;
        release.presetLocationName = locationName.length > 0
            ? locationName
            : [NSString stringWithFormat:@"地图选点 %.4f, %.4f", coordinate.latitude, coordinate.longitude];
    }
    release.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:release animated:YES];
}

- (void)loadPublishedMemoryPointsIfNeeded:(BOOL)forceReload {
    if (self.hasLoadedContentPoints && !forceReload) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[YALContentManager sharedManager] getMyContentListWithPage:1
                                                      pageSize:1000
                                                    completion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            if (!success) {
                NSLog(@"❌ 地图加载我的作品失败: %@ %@", message, error);
                return;
            }
            [strongSelf reloadMapAnnotationsWithContentList:contentList ?: @[]];
            strongSelf.hasLoadedContentPoints = YES;
        });
    }];
}

- (void)reloadMapAnnotationsWithContentList:(NSArray *)contentList {
    NSMutableArray<id<MKAnnotation>> *removableAnnotations = [NSMutableArray array];
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if (![annotation isKindOfClass:[MKUserLocation class]]) {
            [removableAnnotations addObject:annotation];
        }
    }
    if (removableAnnotations.count > 0) {
        [self.mapView removeAnnotations:removableAnnotations];
    }

    NSMutableArray<YALMemoryPoint *> *points = [NSMutableArray array];
    for (id item in contentList) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        YALPostModel *post = [[YALPostModel alloc] initWithDictionary:(NSDictionary *)item];
        BOOL hasLocationName = post.locationName.length > 0;
        BOOL hasCoordinate = CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(post.latitude, post.longitude)) &&
                             !(fabs(post.latitude) < DBL_EPSILON && fabs(post.longitude) < DBL_EPSILON);
        if (!hasLocationName && !hasCoordinate) {
            continue;
        }

        NSString *subtitle = post.locationName.length > 0 ? post.locationName : post.createTime;
        if (subtitle.length == 0) {
            subtitle = post.isPublic ? @"已发布作品" : @"私密作品";
        }

        YALMemoryPoint *point = [YALMemoryPoint pointWithCoordinate:CLLocationCoordinate2DMake(post.latitude, post.longitude)
                                                              title:(post.title.length > 0 ? post.title : @"未命名作品")
                                                           subtitle:subtitle
                                                         detailText:(post.content.length > 0 ? post.content : post.desc)
                                                        userCreated:NO];
        if (!hasCoordinate) {
            // 只有地址没有经纬度时，放在当前可视区域中心附近，避免丢失此类作品。
            CLLocationCoordinate2D fallbackCoordinate = self.mapView.centerCoordinate;
            if (!CLLocationCoordinate2DIsValid(fallbackCoordinate) ||
                (fabs(fallbackCoordinate.latitude) < DBL_EPSILON && fabs(fallbackCoordinate.longitude) < DBL_EPSILON)) {
                fallbackCoordinate = CLLocationCoordinate2DMake(39.9042, 116.4074);
            }
            point.coordinate = fallbackCoordinate;
        }
        point.postModel = post;
        [points addObject:point];
    }

    if (points.count > 0) {
        [self.mapView addAnnotations:points];
    }
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
    [self.searchContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        self.searchBottomConstraint = make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12.0);
    }];
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

    if (self.selectionMode) {
        [self handleLocationSelectionAtCoordinate:coordinate];
        return;
    }

    UIAlertController *sheet =
        [UIAlertController alertControllerWithTitle:@"长按操作"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"发布作品"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (strongSelf.navigationController) {
            [strongSelf openReleaseControllerWithCoordinate:coordinate locationName:nil];
        } else {
            YALReleaseController *release = [[YALReleaseController alloc] init];
            release.hidesBottomBarWhenPushed = YES;
            release.presetCoordinate = coordinate;
            release.hasPresetCoordinate = YES;
            release.presetLocationName = [NSString stringWithFormat:@"地图选点 %.4f, %.4f", coordinate.latitude, coordinate.longitude];
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

- (void)handleLocationSelectionAtCoordinate:(CLLocationCoordinate2D)coordinate {
    __weak typeof(self) weakSelf = self;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    NSLog(@"📍 地图页开始反向解析坐标：%.4f, %.4f", coordinate.latitude, coordinate.longitude);
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }

            if (error) {
                NSLog(@"❌ 地图页反向地理解析失败: %@", error);
            } else {
                NSLog(@"✅ 地图页反向地理解析成功，placemarks: %@", placemarks);
            }

            CLPlacemark *placemark = placemarks.firstObject;
            if (placemark) {
                NSLog(@"📍 地图页首个 placemark: %@", placemark);
                NSLog(@"📍 placemark.name = %@", placemark.name);
                NSLog(@"📍 placemark.locality = %@", placemark.locality);
                NSLog(@"📍 placemark.subLocality = %@", placemark.subLocality);
                NSLog(@"📍 placemark.administrativeArea = %@", placemark.administrativeArea);
                NSLog(@"📍 placemark.thoroughfare = %@", placemark.thoroughfare);
            }
            NSString *name = [strongSelf displayNameForPlacemark:placemark coordinate:coordinate];
            NSLog(@"📍 地图页最终回传地点名: %@", name);
            NSString *message = [NSString stringWithFormat:@"%@\n\n经纬度：%.4f, %.4f", name, coordinate.latitude, coordinate.longitude];
            if (error && name.length == 0) {
                message = [NSString stringWithFormat:@"经纬度：%.4f, %.4f", coordinate.latitude, coordinate.longitude];
            }

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加这个地点？"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"添加" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
                if (strongSelf.onLocationSelected) {
                    strongSelf.onLocationSelected(coordinate, name);
                }
                [strongSelf.navigationController popViewControllerAnimated:YES];
            }]];
            [strongSelf presentViewController:alert animated:YES completion:nil];
        });
    }];
}

- (NSString *)displayNameForPlacemark:(CLPlacemark *)placemark coordinate:(CLLocationCoordinate2D)coordinate {
    if (placemark) {
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
        if (parts.count > 0) {
            return [parts componentsJoinedByString:@" "];
        }
    }
    return [NSString stringWithFormat:@"地图选点 %.4f, %.4f", coordinate.latitude, coordinate.longitude];
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
        view.markerTintColor = [self accentColor];
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
    detailBtn.tintColor = [self accentColor];
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
    if (annotation.postModel) {
        YALPostDetailController *detail = [[YALPostDetailController alloc] init];
        detail.post = annotation.postModel;
        detail.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:detail animated:YES];
        return;
    }

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

    [self.searchContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        self.searchBottomConstraint = make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(offset - 12.0);
    }];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

@end
