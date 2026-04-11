//
//  YALContentManager.h
//  MemoryCity
//
//  Created by mac on 2026/3/29.
//

#import <Foundation/Foundation.h>

@class YALSearchContentModel;
@class YALAIAnalyzeResultModel;
@class YALSearchUserModel;

NS_ASSUME_NONNULL_BEGIN

@interface YALContentManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong, nullable) NSNumber *lastMyContentCollectCount;

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

/// 点赞/取消点赞内容
- (void)toggleLikeContentWithId:(NSNumber *)contentId
                     completion:(void (^)(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error))completion;

/// 获取内容评论列表
- (void)getCommentListWithContentId:(NSNumber *)contentId
                               page:(NSInteger)page
                           pageSize:(NSInteger)pageSize
                         completion:(void (^)(BOOL success, NSArray * _Nullable comments, NSError * _Nullable error))completion;

/// 发布评论
- (void)publishCommentWithContentId:(NSNumber *)contentId
                            content:(NSString *)content
                           parentId:(NSNumber *)parentId
                         completion:(void (^)(BOOL success, NSDictionary * _Nullable comment, NSError * _Nullable error))completion;

/// 删除评论（仅评论作者可删除）
- (void)deleteCommentWithId:(NSNumber *)commentId
                 completion:(void (^)(BOOL success, NSString *message, NSError * _Nullable error))completion;

// 收藏/取消收藏内容
- (void)toggleCollectContentWithId:(NSNumber *)contentId
                        completion:(void (^)(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error))completion;

// 获取我的收藏列表
- (void)getMyCollectListWithCompletion:(void (^)(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error))completion;


- (void)getMyContentListWithPage:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                      completion:(void (^)(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error))completion;

- (void)getAllContentListWithPage:(NSInteger)page
                         pageSize:(NSInteger)pageSize
                       completion:(void (^)(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error))completion;

// 搜索内容
- (void)searchContentWithKeyword:(NSString *)keyword
                            page:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                      completion:(void (^)(BOOL success, NSArray<YALSearchContentModel *> * _Nullable contentList, NSInteger total, NSString * _Nullable message, NSError * _Nullable error))completion;

// 搜索用户
- (void)searchUsersWithKeyword:(NSString *)keyword
                          page:(NSInteger)page
                      pageSize:(NSInteger)pageSize
                    completion:(void (^)(BOOL success, NSArray<YALSearchUserModel *> * _Nullable userList, NSInteger total, NSString * _Nullable message, NSError * _Nullable error))completion;

// AI 文本分析
- (void)analyzeText:(NSString *)text
         completion:(void (^)(BOOL success, YALAIAnalyzeResultModel * _Nullable result, NSString * _Nullable message, NSError * _Nullable error))completion;

/// 删除内容（仅作者可删除）
/// @param contentId 内容ID
/// @param completion 完成回调
- (void)deleteContentWithId:(NSNumber *)contentId
                 completion:(void (^)(BOOL success, NSString *message, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
