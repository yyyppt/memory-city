//
//  YALContentManager.h
//  MemoryCity
//
//  Created by mac on 2026/3/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALContentManager : NSObject

+ (instancetype)sharedManager;

/// 发布内容
/// @param title 标题
/// @param content 文字内容
/// @param city 城市
/// @param year 年代
/// @param mood 情绪标签
/// @param images 图片URL数组
/// @param locationName 地点名称（可选）
/// @param latitude GPS纬度
/// @param longitude GPS经度
/// @param isPublic 是否公开在地图上
/// @param userId 发布用户ID（可选）
/// @param completion 完成回调
- (void)publishContentWithTitle:(NSString *)title
                       content:(NSString *)content
                          city:(NSString *)city
                          year:(NSString *)year
                          mood:(NSString *)mood
                        images:(NSArray<NSString *> *)images
                  locationName:(nullable NSString *)locationName
                      latitude:(double)latitude
                     longitude:(double)longitude
                      isPublic:(BOOL)isPublic
                        userId:(nullable NSNumber *)userId
                     completion:(void (^)(BOOL success, NSString *message, NSNumber * _Nullable contentId, NSError * _Nullable error))completion;

/// 获取内容详情
/// @param contentId 内容ID
/// @param completion 完成回调
- (void)getContentDetailWithId:(NSNumber *)contentId
                    completion:(void (^)(BOOL success, NSDictionary * _Nullable content, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END