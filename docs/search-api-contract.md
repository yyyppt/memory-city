# MemoryCity 搜索接口对接文档

## 目标

解决当前“AI 搜索里正文为空”以及“搜索结果列表/详情页正文偶发不显示”的问题。

这份文档基于当前 iOS 前端实现整理，给后端一个明确、稳定、可执行的返回协议。  
建议后端后续**统一按本文的推荐字段返回**，不要再让同一含义混用多套字段名。

---

## 结论先说

前端现在对“正文”的核心语义只有一个：

- 内容正文字段请统一返回为：`content`

如果后端搜索接口没有把正文放在 `content` 里，而是放在 `body`、`desc`、`text`、`summary`，甚至放在嵌套对象里，前端虽然已经做了兼容，但这会带来两个问题：

1. 搜索列表里正文摘要不稳定
2. AI 搜索拼装提示词时，正文可能拿不到或拿不全

所以后端最佳做法是：

- 搜索列表接口：每条内容结果都直接返回 `content`
- 内容详情接口：详情对象也直接返回 `content`
- 不要把正文只放在嵌套结构里而顶层不放

---

## 当前前端实际使用的接口

### 1. 组合搜索接口

- 路径：`GET /content/search`
- 用途：搜索页一次拿内容结果和用户结果
- 前端代码：[/Users/mac/Desktop/memory-city/ios/MemoryCity/Network/Manager/YALContentManager.m#L1449](/Users/mac/Desktop/memory-city/ios/MemoryCity/Network/Manager/YALContentManager.m#L1449)

请求参数：

```json
{
  "keyword": "上海",
  "page": 1,
  "size": 20
}
```

### 2. 内容详情接口

- 路径：`GET /content/detail`
- 用途：点击搜索结果后进入详情页
- 前端要求详情正文字段为 `content`
- 前端代码：
  - [/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Model/YALPostModel.m#L109](/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Model/YALPostModel.m#L109)
  - [/Users/mac/Desktop/memory-city/ios/MemoryCity/PostDetail/Controller/YALPostDetailController.m#L1617](/Users/mac/Desktop/memory-city/ios/MemoryCity/PostDetail/Controller/YALPostDetailController.m#L1617)

---

## 前端当前对内容搜索结果的字段要求

前端内容搜索模型定义：

- [/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Model/YALSearchContentModel.h](/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Model/YALSearchContentModel.h)

前端当前会尝试兼容这些字段来源：

- 内容 ID：`content_id` / `id` / `post_id` / `memory_id`
- 正文：`content` / `body` / `desc` / `description` / `text` / `detail` / `content_text` / `summary`
- 标题：`title` / `name` / `subject`
- 城市：`city` / `location_city` / `locationName` / `location_name`
- 时间：`year` / `publish_year` / `created_year`
- 情绪：`mood` / `emotion` / `feeling`
- 发布时间：`created_at` / `create_time` / `createdAt` / `publish_time`
- 点赞数：`like_count` / `likes_count` / `liked_count` / `likeCount`
- 评论数：`comment_count` / `comments_count` / `commentCount`
- 图片：`Images` / `images` / `image_urls` / `image`
- 作者信息：
  - 顶层：`user_nickname` / `username` / `user_avatar` / `user_bio`
  - 或嵌套：`user` / `author` / `publisher` / `user_info`

兼容代码位置：

- [/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Model/YALSearchContentModel.m#L119](/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Model/YALSearchContentModel.m#L119)

但请注意：  
**这只是兜底兼容，不是推荐协议。推荐协议见下一节。**

---

## 推荐给后端的正式返回协议

## 一、`GET /content/search` 推荐响应结构

外层统一：

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "content_list": [],
    "user_list": [],
    "total": 0
  }
}
```

### `content_list` 每一项推荐字段

```json
{
  "content_id": 101,
  "user_id": 12,
  "title": "在上海旧街区散步",
  "content": "傍晚沿着老马路走，风有点潮，路边小店的灯一个个亮起来。",
  "city": "上海",
  "year": "2024",
  "mood": "怀旧",
  "created_at": "2026-04-20 14:32:11",
  "like_count": 18,
  "comment_count": 5,
  "images": [
    "https://example.com/uploads/1.jpg",
    "https://example.com/uploads/2.jpg"
  ],
  "user": {
    "user_id": 12,
    "nickname": "阿言",
    "username": "ayan",
    "avatar": "https://example.com/avatar/12.png",
    "bio": "记录城市里的个人记忆"
  }
}
```

### `user_list` 每一项推荐字段

```json
{
  "user_id": 12,
  "nickname": "阿言",
  "username": "ayan",
  "avatar": "https://example.com/avatar/12.png",
  "cover": "https://example.com/cover/12.png",
  "bio": "记录城市里的个人记忆",
  "mood": "怀旧"
}
```

---

## 二、正文字段必须怎么返回

这是这次联调最关键的要求。

### 必须满足

对于 `content_list` 中的每一条内容：

- 必须直接返回顶层字段：`content`
- `content` 必须是字符串
- 即使为空，也要返回空字符串 `""`
- 不要只放在 `body`、`desc`、`text`、`summary`
- 不要只放在 `content.data.content`、`item.content_text` 这类嵌套路径里

### 正确示例

```json
{
  "content_id": 101,
  "title": "在上海旧街区散步",
  "content": "傍晚沿着老马路走，风有点潮，路边小店的灯一个个亮起来。"
}
```

### 不推荐示例

```json
{
  "content_id": 101,
  "title": "在上海旧街区散步",
  "body": "傍晚沿着老马路走，风有点潮，路边小店的灯一个个亮起来。"
}
```

```json
{
  "content_id": 101,
  "title": "在上海旧街区散步",
  "content": {
    "text": "傍晚沿着老马路走，风有点潮，路边小店的灯一个个亮起来。"
  }
}
```

---

## 三、为什么正文必须是顶层 `content`

前端当前有三处直接依赖正文：

### 1. 搜索列表摘要显示

搜索结果卡片副标题直接优先显示 `item.content`

- 代码：[/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Controller/YALSearchController.m#L640](/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Controller/YALSearchController.m#L640)

等价逻辑：

```objc
subtitle = item.content.length > 0 ? item.content : item.authorBio
```

如果后端不返回 `content`，列表就会看起来像“没有正文”。

### 2. AI 搜索分析提示词

AI 搜索会把每条搜索结果里的正文拼进提示词：

- 代码：[/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Controller/YALSearchController.m#L809](/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Controller/YALSearchController.m#L809)

等价逻辑：

```objc
if (item.content.length > 0) {
    [parts addObject:[NSString stringWithFormat:@"内容：%@", item.content]];
}
```

如果 `content` 为空，AI 就会失去正文上下文，于是你看到的就是“AI 搜索像没拿到正文”。

### 3. 点进详情页

搜索结果点击后会把 `item.content` 传给详情页：

- 代码：[/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Controller/YALSearchController.m#L915](/Users/mac/Desktop/memory-city/ios/MemoryCity/Home/Controller/YALSearchController.m#L915)

详情页再次请求接口时，也优先读取详情对象里的 `content`：

- 代码：[/Users/mac/Desktop/memory-city/ios/MemoryCity/PostDetail/Controller/YALPostDetailController.m#L1622](/Users/mac/Desktop/memory-city/ios/MemoryCity/PostDetail/Controller/YALPostDetailController.m#L1622)

所以搜索接口和详情接口最好统一用同一个字段名：`content`

---

## 四、`GET /content/detail` 推荐响应结构

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "content_id": 101,
    "user_id": 12,
    "title": "在上海旧街区散步",
    "content": "傍晚沿着老马路走，风有点潮，路边小店的灯一个个亮起来。",
    "city": "上海",
    "year": "2024",
    "mood": "怀旧",
    "create_time": "2026-04-20 14:32:11",
    "location_name": "武康路",
    "latitude": 31.205,
    "longitude": 121.432,
    "like_count": 18,
    "comment_count": 5,
    "collect_count": 2,
    "is_liked": false,
    "is_collected": false,
    "images": [
      "https://example.com/uploads/1.jpg",
      "https://example.com/uploads/2.jpg"
    ],
    "user": {
      "user_id": 12,
      "nickname": "阿言",
      "username": "ayan",
      "avatar": "https://example.com/avatar/12.png",
      "bio": "记录城市里的个人记忆"
    }
  }
}
```

详情接口里正文同样请固定使用：

- `content`

---

## 五、后端联调时的硬性规则

建议后端按下面这些规则执行：

1. 同一语义只保留一个主字段名  
   正文统一 `content`，不要一会儿 `body` 一会儿 `desc`

2. 顶层直接给字段，不要只放嵌套对象  
   搜索结果是给列表和 AI 用的，顶层拿值最稳定

3. 空值也返回空字符串或空数组  
   - 字符串：`""`
   - 数组：`[]`
   - 数字：`0`

4. 图片字段统一 `images`

5. 作者字段统一放在 `user` 对象内

6. 时间字段统一优先 `created_at` 或 `create_time`，不要两边完全不一样

---

## 六、给后端的最小必改清单

如果这次你只想让后端最快修好“正文不显示”，那至少改这几个点：

1. `GET /content/search` 返回的 `data.content_list[*]` 中，必须补上顶层 `content`
2. `content` 必须是真实正文字符串，不要是对象，不要是 null
3. `GET /content/detail` 返回的详情对象里，也必须补上顶层 `content`
4. 搜索结果里的 `content_id` 也必须稳定返回，否则点详情会出问题

---

## 七、给后端的验收样例

后端改完后，你们可以用下面这组标准验收：

### 搜索接口验收

搜索关键词：`上海`

期望：

1. `data.content_list` 是数组
2. 每个内容对象里都有 `content_id`
3. 每个内容对象里都有 `content`
4. `content` 是字符串，不是对象，不是 null
5. 至少一条搜索结果里 `content.length > 0`

### 详情接口验收

取搜索结果第一条的 `content_id` 调详情接口

期望：

1. `data.content_id` 与搜索结果一致
2. `data.content` 为字符串
3. `data.content.length > 0`

### 前端现象验收

1. 搜索结果列表副标题能看到正文摘要
2. AI 搜索卡片不再像“没拿到正文”
3. 点击搜索结果进入详情后，正文正常显示

---

## 八、可以直接发给后端的一句话版本

请把 `/content/search` 返回的 `data.content_list` 中每条内容的正文统一放到顶层字段 `content`，并保证 `/content/detail` 详情接口里正文字段也同样叫 `content`；不要只返回 `body/desc/text` 或放在嵌套对象里，否则前端搜索列表、AI 搜索、详情页都会拿不到稳定正文。
