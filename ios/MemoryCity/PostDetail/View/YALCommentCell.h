//
//  YALCommentCell.h
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALCommentCell : UITableViewCell

- (void)configureWithAvatar:(UIImage *)avatar
                       name:(NSString *)name
                    content:(NSString *)content
                       time:(NSString *)time
                   expanded:(BOOL)expanded;

- (void)configureWithAvatar:(UIImage *)avatar
             avatarURLString:(nullable NSString *)avatarURLString
                        name:(NSString *)name
                     content:(NSString *)content
                        time:(NSString *)time
                     isReply:(BOOL)isReply
                    expanded:(BOOL)expanded;

@property (nonatomic, copy) void (^toggleExpandBlock)(void);

@end

NS_ASSUME_NONNULL_END
