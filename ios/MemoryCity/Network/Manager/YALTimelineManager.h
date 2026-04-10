//
//  YALTimelineManager.h
//  MemoryCity
//
//  Created by Cursor on 2026/3/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 时间轴相关接口：/timeline/my、/content/filter
@interface YALTimelineManager : NSObject

+ (instancetype)sharedManager;

/// 获取“我的时间轴”（按 YYYY-MM 分组）
/// @param year 可选；传 nil 表示不筛选年份
/// @param completion 返回 data 字典：key=@"2024-03"，value=NSArray(内容列表)
- (void)fetchMyTimelineWithYear:(nullable NSNumber *)year
                     completion:(void (^)(BOOL success,
                                          NSDictionary<NSString *, NSArray *> * _Nullable groupedByYearMonth,
                                          NSString * _Nullable message,
                                          NSError * _Nullable error))completion;

/// 内容筛选 /content/filter
- (void)filterContentWithCity:(nullable NSString *)city
                         year:(nullable NSString *)year
                         mood:(nullable NSString *)mood
                   completion:(void (^)(BOOL success,
                                        NSArray * _Nullable list,
                                        NSString * _Nullable message,
                                        NSError * _Nullable error))completion;

/// 获取我的全部内容（基于 /content/my，返回 list 原始数组）
- (void)fetchMyContentListWithCompletion:(void (^)(BOOL success,
                                                   NSArray * _Nullable list,
                                                   NSString * _Nullable message,
                                                   NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

