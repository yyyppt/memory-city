//
//  YALSearchUserModel.m
//  MemoryCity
//
//  Created by Codex on 2026/4/10.
//

#import "YALSearchUserModel.h"

static NSString *YALSearchUserTrimmedString(id value) {
    if (![value isKindOfClass:[NSString class]]) {
        return @"";
    }
    return [((NSString *)value) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSNumber * _Nullable YALSearchUserNumberValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = YALSearchUserTrimmedString(value);
        if (text.length > 0) {
            return @([text integerValue]);
        }
    }
    return nil;
}

static NSString *YALSearchUserFirstString(NSDictionary *dict, NSArray<NSString *> *keys) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    for (NSString *key in keys) {
        NSString *text = YALSearchUserTrimmedString(dict[key]);
        if (text.length > 0) {
            return text;
        }
    }
    return @"";
}

static NSNumber * _Nullable YALSearchUserFirstNumber(NSDictionary *dict, NSArray<NSString *> *keys) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        NSNumber *value = YALSearchUserNumberValue(dict[key]);
        if (value != nil) {
            return value;
        }
    }
    return nil;
}

@implementation YALSearchUserModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        NSDictionary *nestedUser = [dict[@"user"] isKindOfClass:[NSDictionary class]] ? dict[@"user"] : nil;
        if (!nestedUser) {
            nestedUser = [dict[@"author"] isKindOfClass:[NSDictionary class]] ? dict[@"author"] : nil;
        }
        if (!nestedUser) {
            nestedUser = [dict[@"user_info"] isKindOfClass:[NSDictionary class]] ? dict[@"user_info"] : nil;
        }

        _userId = YALSearchUserFirstNumber(dict, @[@"user_id", @"userId", @"id", @"uid", @"author_id"]);
        if (_userId == nil) {
            _userId = YALSearchUserFirstNumber(nestedUser, @[@"user_id", @"userId", @"id", @"uid"]);
        }

        _nickname = YALSearchUserFirstString(dict, @[@"nickname", @"nickName", @"user_nickname", @"userNickname", @"user_nick_name", @"name"]);
        if (_nickname.length == 0) {
            _nickname = YALSearchUserFirstString(nestedUser, @[@"nickname", @"nickName", @"user_nickname", @"userNickname", @"user_nick_name", @"name"]);
        }

        _username = YALSearchUserFirstString(dict, @[@"username", @"userName", @"user_name", @"account", @"phone", @"email"]);
        if (_username.length == 0) {
            _username = YALSearchUserFirstString(nestedUser, @[@"username", @"userName", @"user_name", @"account", @"phone", @"email"]);
        }

        _title = YALSearchUserFirstString(dict, @[@"title", @"headline", @"signature"]);
        if (_title.length == 0) {
            _title = YALSearchUserFirstString(nestedUser, @[@"title", @"headline", @"signature"]);
        }
        if (_title.length == 0) {
            _title = _nickname.length > 0 ? _nickname : _username;
        }

        _avatar = YALSearchUserFirstString(dict, @[@"avatar", @"avatarUrl", @"avatar_url", @"user_avatar", @"userAvatar"]);
        if (_avatar.length == 0) {
            _avatar = YALSearchUserFirstString(nestedUser, @[@"avatar", @"avatarUrl", @"avatar_url", @"user_avatar", @"userAvatar"]);
        }

        _coverImage = YALSearchUserFirstString(dict, @[@"cover", @"coverUrl", @"cover_url", @"background", @"photo", @"image"]);
        if (_coverImage.length == 0) {
            _coverImage = YALSearchUserFirstString(nestedUser, @[@"cover", @"coverUrl", @"cover_url", @"background", @"photo", @"image"]);
        }
        if (_coverImage.length == 0) {
            _coverImage = _avatar;
        }

        _bio = YALSearchUserFirstString(dict, @[@"bio", @"signature", @"intro", @"introduction", @"content", @"desc"]);
        if (_bio.length == 0) {
            _bio = YALSearchUserFirstString(nestedUser, @[@"bio", @"signature", @"intro", @"introduction", @"desc"]);
        }

        _mood = YALSearchUserFirstString(dict, @[@"mood", @"emotion"]);
        if (_mood.length == 0) {
            _mood = YALSearchUserFirstString(nestedUser, @[@"mood", @"emotion"]);
        }
    }
    return self;
}

@end
