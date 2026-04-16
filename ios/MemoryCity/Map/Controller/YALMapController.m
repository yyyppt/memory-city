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
#import "YALPostManager.h"
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
@property (nonatomic, strong) NSArray<YALMemoryPoint *> *chronologicalFootprintPoints;
@property (nonatomic, strong) UIView *footprintWalkerView;
@property (nonatomic, strong) MKPolyline *footprintRouteOverlay;
@property (nonatomic, strong) CADisplayLink *footprintDisplayLink;
@property (nonatomic, assign) NSInteger footprintSegmentIndex;
@property (nonatomic, assign) CFTimeInterval footprintSegmentStartTime;
@property (nonatomic, assign) CLLocationCoordinate2D footprintSegmentStartCoordinate;
@property (nonatomic, assign) CLLocationCoordinate2D footprintSegmentEndCoordinate;
@property (nonatomic, assign) CLLocationCoordinate2D footprintWalkerCoordinate;
@property (nonatomic, assign) NSTimeInterval footprintSegmentDuration;
@property (nonatomic, assign) BOOL didPlayFootprintAnimation;
@property (nonatomic, strong) NSMutableSet<NSString *> *pendingGeocodeKeys;

@end

@implementation YALMapController

static CLLocationDegrees YALClamp(CLLocationDegrees value, CLLocationDegrees min, CLLocationDegrees max) {
    return MIN(MAX(value, min), max);
}

static BOOL YALCoordinateIsUsable(CLLocationCoordinate2D coordinate) {
    return CLLocationCoordinate2DIsValid(coordinate) &&
           fabs(coordinate.latitude) <= 90.0 &&
           fabs(coordinate.longitude) <= 180.0;
}

- (MKCoordinateRegion)sanitizedRegionForCenter:(CLLocationCoordinate2D)center
                                          span:(MKCoordinateSpan)span
                               fallbackMeters:(CLLocationDistance)fallbackMeters {
    if (!YALCoordinateIsUsable(center)) {
        return MKCoordinateRegionForMapRect(MKMapRectWorld);
    }

    CLLocationDegrees latDelta = span.latitudeDelta;
    CLLocationDegrees lonDelta = span.longitudeDelta;
    if (!isfinite(latDelta) || latDelta <= 0.0 || !isfinite(lonDelta) || lonDelta <= 0.0) {
        return MKCoordinateRegionMakeWithDistance(center, fallbackMeters, fallbackMeters);
    }

    latDelta = YALClamp(latDelta, 0.005, 170.0);
    lonDelta = YALClamp(lonDelta, 0.005, 170.0);
    return MKCoordinateRegionMake(center, MKCoordinateSpanMake(latDelta, lonDelta));
}

- (void)applySafeRegionWithCenter:(CLLocationCoordinate2D)center
                             span:(MKCoordinateSpan)span
                  fallbackMeters:(CLLocationDistance)fallbackMeters
                         animated:(BOOL)animated {
    if (!YALCoordinateIsUsable(center)) {
        return;
    }
    MKCoordinateRegion region = [self sanitizedRegionForCenter:center span:span fallbackMeters:fallbackMeters];
    [self.mapView setRegion:region animated:animated];
}

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
    self.pendingGeocodeKeys = [NSMutableSet set];
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

- (void)dealloc {
    [self stopFootprintAnimationKeepingWalker:NO];
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
    self.title = self.selectionMode ? @"选择地点" : (self.playsFootprintAnimationOnAppear ? @"我的足迹" : @"Map");
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

    if (!self.playsFootprintAnimationOnAppear) {
        [[YALPostManager shareManager] getPostsWithCache:^(NSArray<YALPostModel *> * _Nullable posts, BOOL fromCache, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) { return; }
                if (posts.count == 0 && error) {
                    return;
                }
                [strongSelf reloadMapAnnotationsWithPosts:posts ?: @[]];
                if (!fromCache || !strongSelf.hasLoadedContentPoints) {
                    strongSelf.hasLoadedContentPoints = YES;
                }
            });
        }];
        return;
    }

    [[YALContentManager sharedManager] getMyContentListWithPage:1
                                                      pageSize:1000
                                                    completion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            if (!success) {
                return;
            }
            NSMutableArray<YALPostModel *> *posts = [NSMutableArray array];
            for (id item in (contentList ?: @[])) {
                if ([item isKindOfClass:[YALPostModel class]]) {
                    [posts addObject:item];
                } else if ([item isKindOfClass:[NSDictionary class]]) {
                    [posts addObject:[[YALPostModel alloc] initWithDictionary:(NSDictionary *)item]];
                }
            }
            [strongSelf reloadMapAnnotationsWithPosts:posts];
            strongSelf.hasLoadedContentPoints = YES;
            [strongSelf startFootprintAnimationIfNeeded];
        });
    }];
}

- (CLLocationCoordinate2D)fallbackCoordinateForPost:(YALPostModel *)post index:(NSInteger)index {
    CLLocationCoordinate2D baseCoordinate = self.mapView.centerCoordinate;
    if (!CLLocationCoordinate2DIsValid(baseCoordinate) ||
        (fabs(baseCoordinate.latitude) < DBL_EPSILON && fabs(baseCoordinate.longitude) < DBL_EPSILON)) {
        baseCoordinate = CLLocationCoordinate2DMake(39.9042, 116.4074);
    }

    NSString *seedText = post.locationName.length > 0 ? post.locationName : post.city;
    if (seedText.length == 0) {
        seedText = post.title.length > 0 ? post.title : [NSString stringWithFormat:@"%ld", (long)index];
    }

    NSUInteger hash = 2166136261u;
    for (NSUInteger i = 0; i < seedText.length; i++) {
        hash ^= [seedText characterAtIndex:i];
        hash *= 16777619u;
    }
    hash ^= (NSUInteger)(index * 97);

    NSInteger ring = (NSInteger)(hash % 3) + 1;
    CGFloat distance = 0.06 * ring;
    CGFloat angle = ((hash / 3) % 360) * M_PI / 180.0;
    CLLocationDegrees latitude = baseCoordinate.latitude + cos(angle) * distance;
    CLLocationDegrees longitude = baseCoordinate.longitude + sin(angle) * distance;
    return CLLocationCoordinate2DMake(latitude, longitude);
}

- (NSString *)locationQueryForPost:(YALPostModel *)post {
    NSString *locationName = [post.locationName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *city = [post.city stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (locationName.length > 0 && city.length > 0 && [locationName rangeOfString:city].location == NSNotFound) {
        return [NSString stringWithFormat:@"%@ %@", city, locationName];
    }
    if (locationName.length > 0) {
        return locationName;
    }
    if (city.length > 0) {
        return city;
    }
    return @"";
}

- (NSString *)geocodeKeyForPost:(YALPostModel *)post {
    NSString *query = [self locationQueryForPost:post];
    if (query.length == 0) {
        return nil;
    }
    if ([post.contentId respondsToSelector:@selector(integerValue)] && post.contentId.integerValue > 0) {
        return [NSString stringWithFormat:@"%@_%@", post.contentId, query];
    }
    return query;
}

- (void)resolveCoordinateForPostIfNeeded:(YALPostModel *)post point:(YALMemoryPoint *)point {
    if (![post isKindOfClass:[YALPostModel class]] || ![point isKindOfClass:[YALMemoryPoint class]]) {
        return;
    }

    BOOL hasCoordinate = CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(post.latitude, post.longitude)) &&
                         !(fabs(post.latitude) < DBL_EPSILON && fabs(post.longitude) < DBL_EPSILON);
    if (hasCoordinate) {
        return;
    }

    NSString *query = [self locationQueryForPost:post];
    NSString *key = [self geocodeKeyForPost:post];
    if (query.length == 0 || key.length == 0 || [self.pendingGeocodeKeys containsObject:key]) {
        return;
    }

    [self.pendingGeocodeKeys addObject:key];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    __weak typeof(self) weakSelf = self;
    [geocoder geocodeAddressString:query completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            [strongSelf.pendingGeocodeKeys removeObject:key];
            if (error || placemarks.count == 0) {
                return;
            }

            CLPlacemark *placemark = placemarks.firstObject;
            CLLocation *location = placemark.location;
            if (!location) {
                return;
            }

            post.latitude = location.coordinate.latitude;
            post.longitude = location.coordinate.longitude;
            point.coordinate = location.coordinate;

            if (!strongSelf.playsFootprintAnimationOnAppear) {
                NSMutableArray<YALMemoryPoint *> *points = [NSMutableArray array];
                for (id<MKAnnotation> annotation in strongSelf.mapView.annotations) {
                    if ([annotation isKindOfClass:[YALMemoryPoint class]]) {
                        [points addObject:(YALMemoryPoint *)annotation];
                    }
                }
                [strongSelf fitMapToAnnotationsIfNeeded:points];
            }
        });
    }];
}

- (void)fitMapToAnnotationsIfNeeded:(NSArray<YALMemoryPoint *> *)points {
    if (points.count == 0) {
        return;
    }
    if (points.count == 1) {
        CLLocationCoordinate2D coordinate = points.firstObject.coordinate;
        if (!YALCoordinateIsUsable(coordinate)) {
            return;
        }
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 1800.0, 1800.0);
        [self.mapView setRegion:region animated:YES];
        return;
    }

    CLLocationDegrees minLat = DBL_MAX;
    CLLocationDegrees maxLat = -DBL_MAX;
    CLLocationDegrees minLon = DBL_MAX;
    CLLocationDegrees maxLon = -DBL_MAX;
    for (YALMemoryPoint *point in points) {
        if (!YALCoordinateIsUsable(point.coordinate)) {
            continue;
        }
        minLat = MIN(minLat, point.coordinate.latitude);
        maxLat = MAX(maxLat, point.coordinate.latitude);
        minLon = MIN(minLon, point.coordinate.longitude);
        maxLon = MAX(maxLon, point.coordinate.longitude);
    }

    if (minLat == DBL_MAX || minLon == DBL_MAX) {
        return;
    }

    MKCoordinateSpan span = MKCoordinateSpanMake(MAX((maxLat - minLat) * 1.5, 0.25),
                                                 MAX((maxLon - minLon) * 1.5, 0.25));
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake((minLat + maxLat) * 0.5,
                                                               (minLon + maxLon) * 0.5);
    [self applySafeRegionWithCenter:center span:span fallbackMeters:3000.0 animated:YES];
}

- (void)reloadMapAnnotationsWithPosts:(NSArray<YALPostModel *> *)posts {
    [self stopFootprintAnimationKeepingWalker:NO];

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
    NSMutableArray<YALMemoryPoint *> *footprintPoints = [NSMutableArray array];
    NSInteger fallbackIndex = 0;
    for (YALPostModel *post in posts) {
        if (![post isKindOfClass:[YALPostModel class]]) {
            continue;
        }
        BOOL hasLocationName = post.locationName.length > 0 || post.city.length > 0;
        BOOL hasCoordinate = CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(post.latitude, post.longitude)) &&
                             !(fabs(post.latitude) < DBL_EPSILON && fabs(post.longitude) < DBL_EPSILON);
        if (!hasLocationName && !hasCoordinate) {
            continue;
        }

        NSString *resolvedLocation = post.locationName.length > 0 ? post.locationName : post.city;
        NSString *subtitle = resolvedLocation.length > 0 ? resolvedLocation : post.createTime;
        if (subtitle.length == 0) {
            subtitle = post.isPublic ? @"已发布作品" : @"私密作品";
        }

        CLLocationCoordinate2D coordinate = hasCoordinate
            ? CLLocationCoordinate2DMake(post.latitude, post.longitude)
            : [self fallbackCoordinateForPost:post index:fallbackIndex];

        YALMemoryPoint *point = [YALMemoryPoint pointWithCoordinate:coordinate
                                                              title:(post.title.length > 0 ? post.title : @"未命名作品")
                                                           subtitle:subtitle
                                                         detailText:(post.content.length > 0 ? post.content : post.desc)
                                                        userCreated:NO];
        point.postModel = post;
        [points addObject:point];
        if (hasCoordinate) {
            [footprintPoints addObject:point];
        } else {
            [self resolveCoordinateForPostIfNeeded:post point:point];
            fallbackIndex += 1;
        }
    }
    self.chronologicalFootprintPoints = [self chronologicalFootprintPointsFromPoints:footprintPoints];

    if (points.count > 0) {
        [self.mapView addAnnotations:points];
        if (!self.playsFootprintAnimationOnAppear) {
            [self fitMapToAnnotationsIfNeeded:points];
        }
    }
}

- (void)startFootprintAnimationIfNeeded {
    if (self.selectionMode ||
        !self.playsFootprintAnimationOnAppear ||
        self.didPlayFootprintAnimation ||
        self.chronologicalFootprintPoints.count == 0) {
        return;
    }
    self.didPlayFootprintAnimation = YES;

    if (self.chronologicalFootprintPoints.count == 1) {
        YALMemoryPoint *onlyPoint = self.chronologicalFootprintPoints.firstObject;
        [self installWalkerAtCoordinate:onlyPoint.coordinate title:onlyPoint.title ?: @"我的足迹"];
        [self flyCameraToCoordinate:onlyPoint.coordinate heading:0.0 distance:900.0 animated:YES];
        [self showFootprintToastWithText:@"只有一个足迹点，小人先停在这里等下一段回忆。"];
        return;
    }

    [self drawFootprintRouteForPoints:self.chronologicalFootprintPoints];
    [self installWalkerAtCoordinate:self.chronologicalFootprintPoints.firstObject.coordinate
                              title:@"足迹回放"];
    [self fitMapToFootprintPoints:self.chronologicalFootprintPoints];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self showFootprintToastWithText:@"正在按发布时间回放你的城市足迹"];
        [self startFootprintSegmentAtIndex:0];
    });
}

- (void)installWalkerAtCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title {
    (void)title;
    self.footprintWalkerCoordinate = coordinate;
    if (!self.footprintWalkerView) {
        self.footprintWalkerView = [self createFootprintWalkerView];
        [self.mapView addSubview:self.footprintWalkerView];
    }
    self.footprintWalkerView.hidden = NO;
    [self.mapView bringSubviewToFront:self.footprintWalkerView];
    [self updateFootprintWalkerViewPosition];
}

- (UIView *)createFootprintWalkerView {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 64.0, 78.0)];
    container.backgroundColor = [UIColor clearColor];
    container.userInteractionEnabled = NO;

    UIView *shadow = [[UIView alloc] initWithFrame:CGRectMake(13.0, 62.0, 38.0, 10.0)];
    shadow.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.24];
    shadow.layer.cornerRadius = 5.0;
    shadow.transform = CGAffineTransformMakeScale(1.18, 0.72);
    [container addSubview:shadow];

    UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(7.0, 0.0, 50.0, 60.0)];
    bubble.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.98];
    bubble.layer.cornerRadius = 25.0;
    bubble.layer.shadowColor = [UIColor blackColor].CGColor;
    bubble.layer.shadowOpacity = 0.28;
    bubble.layer.shadowRadius = 12.0;
    bubble.layer.shadowOffset = CGSizeMake(0.0, 9.0);
    bubble.tag = 7001;
    [container addSubview:bubble];

    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(7.0, 7.0, 36.0, 36.0)];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.tintColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        iconView.image = [UIImage systemImageNamed:@"figure.walk.circle.fill"];
    }
    [bubble addSubview:iconView];

    UILabel *fallbackLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)];
    fallbackLabel.text = @"行";
    fallbackLabel.textColor = [UIColor whiteColor];
    fallbackLabel.font = [UIFont systemFontOfSize:23.0 weight:UIFontWeightBlack];
    fallbackLabel.textAlignment = NSTextAlignmentCenter;
    fallbackLabel.hidden = iconView.image != nil;
    [bubble addSubview:fallbackLabel];

    CABasicAnimation *stepAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    stepAnimation.fromValue = @0.0;
    stepAnimation.toValue = @(-8.0);
    stepAnimation.duration = 0.34;
    stepAnimation.autoreverses = YES;
    stepAnimation.repeatCount = HUGE_VALF;
    stepAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [bubble.layer addAnimation:stepAnimation forKey:@"footprintStep"];

    CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    shadowAnimation.fromValue = @1.18;
    shadowAnimation.toValue = @0.88;
    shadowAnimation.duration = 0.34;
    shadowAnimation.autoreverses = YES;
    shadowAnimation.repeatCount = HUGE_VALF;
    shadowAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [shadow.layer addAnimation:shadowAnimation forKey:@"footprintShadow"];

    return container;
}

- (void)updateFootprintWalkerViewPosition {
    if (!self.footprintWalkerView ||
        !CLLocationCoordinate2DIsValid(self.footprintWalkerCoordinate)) {
        return;
    }
    CGPoint point = [self.mapView convertCoordinate:self.footprintWalkerCoordinate toPointToView:self.mapView];
    self.footprintWalkerView.center = CGPointMake(point.x, point.y - 36.0);
}

- (void)drawFootprintRouteForPoints:(NSArray<YALMemoryPoint *> *)points {
    if (self.footprintRouteOverlay) {
        [self.mapView removeOverlay:self.footprintRouteOverlay];
        self.footprintRouteOverlay = nil;
    }
    if (points.count < 2) {
        return;
    }

    CLLocationCoordinate2D *coordinates = calloc(points.count, sizeof(CLLocationCoordinate2D));
    if (!coordinates) {
        return;
    }
    for (NSUInteger i = 0; i < points.count; i++) {
        coordinates[i] = points[i].coordinate;
    }
    self.footprintRouteOverlay = [MKPolyline polylineWithCoordinates:coordinates count:points.count];
    free(coordinates);
    [self.mapView addOverlay:self.footprintRouteOverlay level:MKOverlayLevelAboveRoads];
}

- (void)fitMapToFootprintPoints:(NSArray<YALMemoryPoint *> *)points {
    if (points.count == 0) {
        return;
    }
    MKMapRect routeRect = MKMapRectNull;
    for (YALMemoryPoint *point in points) {
        MKMapPoint mapPoint = MKMapPointForCoordinate(point.coordinate);
        MKMapRect pointRect = MKMapRectMake(mapPoint.x, mapPoint.y, 1.0, 1.0);
        routeRect = MKMapRectIsNull(routeRect) ? pointRect : MKMapRectUnion(routeRect, pointRect);
    }
    if (MKMapRectIsNull(routeRect)) {
        return;
    }
    [self.mapView setVisibleMapRect:routeRect
                         edgePadding:UIEdgeInsetsMake(120.0, 56.0, 160.0, 56.0)
                            animated:YES];
}

- (void)startFootprintSegmentAtIndex:(NSInteger)index {
    if (index >= (NSInteger)self.chronologicalFootprintPoints.count - 1) {
        [self stopFootprintAnimationKeepingWalker:YES];
        [self showFootprintToastWithText:@"足迹回放完成"];
        return;
    }

    self.footprintSegmentIndex = index;
    self.footprintSegmentStartCoordinate = self.chronologicalFootprintPoints[index].coordinate;
    self.footprintSegmentEndCoordinate = self.chronologicalFootprintPoints[index + 1].coordinate;
    CLLocation *startLocation = [[CLLocation alloc] initWithLatitude:self.footprintSegmentStartCoordinate.latitude
                                                           longitude:self.footprintSegmentStartCoordinate.longitude];
    CLLocation *endLocation = [[CLLocation alloc] initWithLatitude:self.footprintSegmentEndCoordinate.latitude
                                                         longitude:self.footprintSegmentEndCoordinate.longitude];
    CLLocationDistance distance = [startLocation distanceFromLocation:endLocation];
    self.footprintSegmentDuration = MIN(3.2, MAX(1.15, distance / 180.0));
    self.footprintSegmentStartTime = CACurrentMediaTime();

    [self.footprintDisplayLink invalidate];
    self.footprintDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFootprintWalker:)];
    [self.footprintDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)updateFootprintWalker:(CADisplayLink *)displayLink {
    CFTimeInterval elapsed = displayLink.timestamp - self.footprintSegmentStartTime;
    CGFloat rawProgress = self.footprintSegmentDuration <= 0 ? 1.0 : MIN(1.0, elapsed / self.footprintSegmentDuration);
    CGFloat progress = rawProgress * rawProgress * (3.0 - 2.0 * rawProgress);

    CLLocationCoordinate2D coordinate = [self coordinateBetween:self.footprintSegmentStartCoordinate
                                                           end:self.footprintSegmentEndCoordinate
                                                      progress:progress];
    self.footprintWalkerCoordinate = coordinate;
    [self updateFootprintWalkerViewPosition];

    CLLocationDirection heading = [self headingFromCoordinate:self.footprintSegmentStartCoordinate
                                                           to:self.footprintSegmentEndCoordinate];
    CLLocation *startLocation = [[CLLocation alloc] initWithLatitude:self.footprintSegmentStartCoordinate.latitude
                                                           longitude:self.footprintSegmentStartCoordinate.longitude];
    CLLocation *endLocation = [[CLLocation alloc] initWithLatitude:self.footprintSegmentEndCoordinate.latitude
                                                         longitude:self.footprintSegmentEndCoordinate.longitude];
    CLLocationDistance distance = [startLocation distanceFromLocation:endLocation];
    [self flyCameraToCoordinate:coordinate
                        heading:heading
                       distance:MIN(2200.0, MAX(650.0, distance * 1.8))
                       animated:NO];
    [self updateFootprintWalkerViewPosition];

    if (rawProgress >= 1.0) {
        [displayLink invalidate];
        self.footprintDisplayLink = nil;
        [self startFootprintSegmentAtIndex:self.footprintSegmentIndex + 1];
    }
}

- (CLLocationCoordinate2D)coordinateBetween:(CLLocationCoordinate2D)start
                                        end:(CLLocationCoordinate2D)end
                                   progress:(CGFloat)progress {
    return CLLocationCoordinate2DMake(start.latitude + (end.latitude - start.latitude) * progress,
                                      start.longitude + (end.longitude - start.longitude) * progress);
}

- (CLLocationDirection)headingFromCoordinate:(CLLocationCoordinate2D)start
                                          to:(CLLocationCoordinate2D)end {
    double lat1 = start.latitude * M_PI / 180.0;
    double lat2 = end.latitude * M_PI / 180.0;
    double deltaLon = (end.longitude - start.longitude) * M_PI / 180.0;
    double y = sin(deltaLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon);
    double heading = atan2(y, x) * 180.0 / M_PI;
    return fmod(heading + 360.0, 360.0);
}

- (void)flyCameraToCoordinate:(CLLocationCoordinate2D)coordinate
                      heading:(CLLocationDirection)heading
                     distance:(CLLocationDistance)distance
                     animated:(BOOL)animated {
    MKMapCamera *camera = [MKMapCamera cameraLookingAtCenterCoordinate:coordinate
                                                          fromDistance:distance
                                                                 pitch:62.0
                                                               heading:heading];
    [self.mapView setCamera:camera animated:animated];
}

- (void)stopFootprintAnimationKeepingWalker:(BOOL)keepWalker {
    [self.footprintDisplayLink invalidate];
    self.footprintDisplayLink = nil;
    if (!keepWalker && self.footprintWalkerView) {
        [self.footprintWalkerView removeFromSuperview];
        self.footprintWalkerView = nil;
    }
    if (!keepWalker && self.footprintRouteOverlay) {
        [self.mapView removeOverlay:self.footprintRouteOverlay];
        self.footprintRouteOverlay = nil;
    }
}

- (void)showFootprintToastWithText:(NSString *)text {
    if (text.length == 0 || self.selectionMode) {
        return;
    }
    UIView *toast = [[UIView alloc] initWithFrame:CGRectZero];
    toast.backgroundColor = [[UIColor secondarySystemBackgroundColor] colorWithAlphaComponent:0.96];
    toast.layer.cornerRadius = 18.0;
    toast.layer.borderWidth = 1.0;
    toast.layer.borderColor = [self accentBorderColor].CGColor;
    toast.alpha = 0.0;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.textColor = [UIColor labelColor];
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;

    [toast addSubview:label];
    [self.view addSubview:toast];
    [toast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(12.0);
        make.left.greaterThanOrEqualTo(self.view.mas_left).offset(20.0);
        make.right.lessThanOrEqualTo(self.view.mas_right).offset(-20.0);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(toast).insets(UIEdgeInsetsMake(9.0, 16.0, 9.0, 16.0));
    }];

    [UIView animateWithDuration:0.22 animations:^{
        toast.alpha = 1.0;
    } completion:^(__unused BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.22 animations:^{
                toast.alpha = 0.0;
            } completion:^(__unused BOOL finished2) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

- (NSArray<YALMemoryPoint *> *)chronologicalFootprintPointsFromPoints:(NSArray<YALMemoryPoint *> *)points {
    return [points sortedArrayUsingComparator:^NSComparisonResult(YALMemoryPoint * _Nonnull first, YALMemoryPoint * _Nonnull second) {
        NSDate *firstDate = [self dateForPost:first.postModel];
        NSDate *secondDate = [self dateForPost:second.postModel];
        if (firstDate && secondDate) {
            return [firstDate compare:secondDate];
        }
        if (firstDate) {
            return NSOrderedAscending;
        }
        if (secondDate) {
            return NSOrderedDescending;
        }
        NSNumber *firstId = first.postModel.contentId ?: @(0);
        NSNumber *secondId = second.postModel.contentId ?: @(0);
        return [firstId compare:secondId];
    }];
}

- (NSDate *)dateForPost:(YALPostModel *)post {
    NSArray<NSString *> *candidates = @[
        post.createTime ?: @"",
        post.year ?: @""
    ];
    NSArray<NSString *> *formats = @[
        @"yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        @"yyyy-MM-dd'T'HH:mm:ssZ",
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd",
        @"yyyy.MM.dd",
        @"yyyy/MM/dd",
        @"yyyy"
    ];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    for (NSString *raw in candidates) {
        NSString *text = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) {
            continue;
        }
        NSDate *isoDate = nil;
        if (@available(iOS 10.0, *)) {
            NSISO8601DateFormatter *isoFormatter = [[NSISO8601DateFormatter alloc] init];
            isoDate = [isoFormatter dateFromString:text];
        }
        if (isoDate) {
            return isoDate;
        }
        for (NSString *format in formats) {
            formatter.dateFormat = format;
            NSDate *date = [formatter dateFromString:text];
            if (date) {
                return date;
            }
        }
    }
    return nil;
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
        if (!YALCoordinateIsUsable(coordinate)) {
            return;
        }
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
        CLLocationCoordinate2D coordinate = currentLocation.coordinate;
        if (YALCoordinateIsUsable(coordinate)) {
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 800, 800);
            [self.mapView setRegion:region animated:YES];
        }
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
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) { return; }

            CLPlacemark *placemark = placemarks.firstObject;
            NSString *name = [strongSelf displayNameForPlacemark:placemark coordinate:coordinate];
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
    }

    view.annotation = annotation;
    view.markerTintColor = [self accentColor];
    if (@available(iOS 11.0, *)) {
        view.glyphTintColor = [UIColor whiteColor];
    }
    view.canShowCallout = !self.playsFootprintAnimationOnAppear;
    view.clusteringIdentifier = self.playsFootprintAnimationOnAppear ? nil : @"memory";
    if (@available(iOS 11.0, *)) {
        view.displayPriority = MKFeatureDisplayPriorityRequired;
    }

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
    view.rightCalloutAccessoryView = self.playsFootprintAnimationOnAppear ? nil : detailBtn;

    if ([annotation isKindOfClass:[YALMemoryPoint class]]) {
        YALMemoryPoint *memoryAnnotation = (YALMemoryPoint *)annotation;
        view.leftCalloutAccessoryView.hidden = self.playsFootprintAnimationOnAppear || !memoryAnnotation.userCreated;
    }

    return view;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    (void)mapView;
    if (overlay == self.footprintRouteOverlay && [overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline *)overlay];
        renderer.strokeColor = [[self accentColor] colorWithAlphaComponent:0.92];
        renderer.lineWidth = 5.0;
        renderer.lineJoin = kCGLineJoinRound;
        renderer.lineCap = kCGLineCapRound;
        renderer.lineDashPattern = @[@10.0, @7.0];
        return renderer;
    }
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline *)overlay];
        renderer.strokeColor = [self accentColor];
        renderer.lineWidth = 4.0;
        return renderer;
    }
    return [[MKOverlayRenderer alloc] initWithOverlay:overlay];
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
    if (self.playsFootprintAnimationOnAppear) {
        [mapView deselectAnnotation:annotation animated:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showDetailForAnnotation:memoryAnnotation];
        });
        return;
    }

    if (memoryAnnotation.userCreated) {
        memoryAnnotation.subtitle = @"左边垃圾桶删除，右边进入详情";
    } else {
        memoryAnnotation.subtitle = @"右边进入详情";
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    (void)mapView;
    (void)animated;
    [self updateFootprintWalkerViewPosition];
    if (self.footprintWalkerView) {
        [self.mapView bringSubviewToFront:self.footprintWalkerView];
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
