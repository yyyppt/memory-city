# MemoryCity 作品集项目文档

> 文档版本：v1.0  
> 生成日期：2026-04-11  
> 项目类型：iOS 原生应用 / Objective-C / UIKit  
> 项目名称：MemoryCity / 拾光  
> 团队信息：YD & PT & JX  
> 适用场景：课程设计、毕业设计、作品集展示、项目答辩、简历项目经历整理

---

## 1. 项目概述

MemoryCity 是一款围绕“地点、时间与情绪记忆”构建的 iOS 原生应用。用户可以发布带图片、标题、文字、日期、城市、心情和地理位置的记忆内容，并在首页、地图、时间线、个人中心等多个视角中回看自己的生活足迹。

项目核心目标不是单纯做一个内容发布应用，而是把“记忆”组织成更有空间感和时间感的体验：  

- 在首页以瀑布流方式展示记忆内容，强化图片和内容浏览体验。
- 在地图页通过地点标注展示用户发布过的记忆点。
- 在“我的足迹”场景中，通过 3D 小人沿发布时间顺序走过地点，表达记忆轨迹。
- 在回忆页中按时间维度整理内容，让用户从月份、年份和时间线回看过去。
- 在详情页中支持评论、点赞、收藏、作者信息和评论展开收起。
- 在登录体系中支持注册、登录、修改密码、忘记密码与短信验证码重置密码。

一句话介绍：

> MemoryCity 是一个将图文内容、地理位置和时间线结合起来的 iOS 记忆管理与社交互动应用。

---

## 2. 项目定位

### 2.1 用户痛点

传统相册或社交平台更强调“图片展示”或“动态发布”，但用户真正想回忆某段经历时，往往会从这些线索出发：

- 当时在哪里？
- 是哪一年、哪一天？
- 当时心情如何？
- 这段记忆和哪些地点串联在一起？
- 后来别人有没有点赞、评论或收藏？

MemoryCity 试图把这些线索组织起来，让记忆不只是一条动态，而是一个可以按时间、空间和互动关系回看的个人城市记忆系统。

### 2.2 产品目标

- 提供一个清晰、美观的记忆发布入口。
- 让用户能够按首页瀑布流浏览所有内容。
- 让用户能够按地图查看记忆地点。
- 让用户能够按月份和时间线查看回忆。
- 支持基础社交互动：点赞、评论、收藏、消息提醒。
- 支持完整账户体系：注册、登录、资料编辑、修改密码、忘记密码。

### 2.3 目标用户

- 喜欢记录生活、旅行、城市漫步和日常碎片的用户。
- 希望把照片、文字、日期、地点结合管理的用户。
- 需要课程项目或作品集展示完整 iOS 应用能力的开发者。

---

## 3. 技术栈

### 3.1 iOS 客户端

| 类型 | 技术 |
| --- | --- |
| 开发语言 | Objective-C |
| UI 框架 | UIKit |
| 布局框架 | Masonry |
| 网络请求 | AFNetworking |
| 图片加载 | SDWebImage |
| 模型解析 | YYModel / 手动字典解析 |
| 本地存储 | NSUserDefaults / WCDB.objc |
| 地图能力 | MapKit / CoreLocation |
| 图片选择 | PhotosUI / UIImagePickerController |
| 项目管理 | CocoaPods / Xcode Workspace |
| 最低 iOS 版本 | iOS 13.0 |

### 3.2 服务端能力

项目当前通过 HTTP API 与后端交互，后端主要承担：

- 用户注册与登录。
- access token / refresh token 登录态维护。
- 内容发布、列表、详情、删除。
- 搜索与 AI 分析。
- 点赞、收藏、评论。
- 用户资料编辑、头像、简介。
- 短信验证码与忘记密码。
- 地图/时间线相关内容查询。

### 3.3 第三方依赖

依赖定义位于 `ios/Podfile`。

| 依赖 | 用途 |
| --- | --- |
| SDWebImage | 网络图片异步加载与缓存 |
| YYModel | 模型与 JSON 解析辅助 |
| AFNetworking | HTTP 网络请求封装 |
| Masonry | Objective-C 链式 AutoLayout |
| WCDB.objc | 本地数据库能力预留或缓存能力 |

---

## 4. 项目目录结构

项目主体位于 `ios/MemoryCity`。

```text
MemoryCity
├── App
│   └── Delegate                 应用入口与 Scene 生命周期
├── Common
│   └── Base                     基础控制器
├── Home                         首页、瀑布流、搜索
├── Login                        登录、忘记密码、重置密码
├── Register                     注册
├── Release                      发布/编辑记忆、图片、日期、地点
├── PostDetail                   内容详情、评论、点赞、收藏
├── Map                          地图、地点选择、足迹动画
├── Memory                       回忆页、月份聚合
├── TimeLine                     时间线详情展示
├── Message                      互动消息
├── Mine                         我的页面、资料、收藏、点赞、设置
├── Network
│   └── Manager                  网络、鉴权、内容、时间线管理
├── TabBar                       自定义 TabBar 与主框架
└── Assets.xcassets              图片与图标资源
```

### 4.1 分层方式

项目整体采用接近 MVC 的模块化分层：

- Controller：负责页面生命周期、状态调度、跳转和用户操作响应。
- View：负责 UI 组件封装和布局。
- Model：负责业务数据结构与接口数据解析。
- Manager：负责网络请求、数据聚合和跨页面基础能力。

这种结构适合 Objective-C UIKit 项目，优点是学习成本低、文件组织清晰、易于答辩解释。

---

## 5. 应用主流程

### 5.1 启动流程

应用启动入口位于 `YALSceneDelegate`。

流程：

1. 创建 UIWindow。
2. 读取本地外观设置，决定浅色/深色/跟随系统。
3. 通过 `YALAuthManager` 判断本地是否存在登录会话。
4. 如果已登录，进入 `YALTabBarController`。
5. 如果未登录，进入 `YALLoginController`。

```text
App Launch
    ↓
YALSceneDelegate
    ↓
检查 hasLoggedInSession
    ↓
已登录 → TabBar 主界面
未登录 → Login 登录页
```

### 5.2 主界面结构

主界面由 `YALTabBarController` 管理五个导航栈：

| Tab | 页面 | 功能 |
| --- | --- | --- |
| Home | YALHomeController | 首页瀑布流内容浏览与搜索入口 |
| Memories | YALMemoryController | 按时间聚合的回忆页 |
| 发布 | YALReleaseController | 中间按钮发布/编辑内容 |
| Map | YALMapController | 地图记忆点与地点选择 |
| Mine | YALMineController | 个人中心、资料、收藏、点赞、设置 |

项目使用自定义 `YALTabBar`，中间发布按钮突出显示，导航栏与 TabBar 采用统一暖色视觉风格。

---

## 6. 核心功能模块

## 6.1 登录与注册模块

相关文件：

- `Login/Controller/YALLoginController`
- `Login/View/YALLoginView`
- `Register/Controller/YALRegisterController`
- `Register/View/YALRegisterView`
- `Login/Model/YALAuthUserModel`
- `Network/Manager/YALAuthManager`

### 登录功能

用户输入账号和密码，前端进行基础校验：

- 账号不能为空。
- 密码不能为空。
- 密码长度需为 6 到 15 位。

校验通过后调用：

```text
POST /api/user/login
```

登录成功后：

- 解析用户信息。
- 保存 access token。
- 保存 refresh token。
- 设置 `currentUser`。
- 切换根控制器进入主界面。

### 注册功能

注册页输入手机号、密码和昵称。

前端校验：

- 手机号至少 11 位。
- 密码至少 6 位。
- 昵称不能为空。

调用：

```text
POST /api/user/register
```

成功后提示“注册成功，请重新登录”，并返回登录页。

### 忘记密码功能

项目已新增忘记密码完整客户端流程：

1. 登录页点击“忘记密码?”。
2. 进入找回密码页。
3. 输入手机号。
4. 调用后端发送验证码。
5. 开启 60 秒倒计时。
6. 输入验证码并校验。
7. 校验成功后进入重置密码页。
8. 输入新密码和确认密码。
9. 两次一致后调用后端重置密码接口。
10. 成功后提示“密码重置成功，请重新登录”，返回登录页。

相关接口：

```text
POST /api/user/password/forgot/send-code
POST /api/user/password/forgot/verify-code
PUT  /api/user/password/forgot/reset
```

后端需要接入阿里云短信服务，负责验证码生成、发送、存储、校验和过期控制。

---

## 6.2 首页瀑布流模块

相关文件：

- `Home/Controller/YALHomeController`
- `Home/View/YALPostCell`
- `Home/View/YALWaterfallLayout`
- `Home/Model/YALPostModel`
- `Home/Manager/YALPostManager`

首页是项目的主要内容浏览入口。

### 功能点

- UICollectionView 内容展示。
- 自定义瀑布流布局。
- 支持单列/瀑布流布局切换。
- 卡片展示图片、标题、描述、点赞数、评论数。
- 网络图片通过 SDWebImage 异步加载。
- 下拉刷新。
- 点击卡片进入详情页。
- 顶部搜索栏进入搜索页面。

### 卡片设计

首页卡片采用暖色卡片风格，包含：

- 图片区域。
- 标题。
- 描述或城市/心情/年份兜底信息。
- 底部互动信息条：爱心、点赞数、评论数。

这种设计既强化内容信息密度，也避免卡片底部留白过多。

### 瀑布流计算

瀑布流高度根据 item width 和模拟比例计算图片高度，再叠加固定文本区域高度。这样可以实现错落排布，增强视觉节奏。

---

## 6.3 搜索模块

相关文件：

- `Home/Controller/YALSearchController`
- `Home/Model/YALSearchContentModel`
- `Home/Model/YALSearchUserModel`
- `Network/Manager/YALContentManager`

### 功能点

- 支持内容搜索。
- 支持用户昵称搜索。
- 支持切换内容结果与用户结果。
- 内容搜索可展示 AI 分析结果。
- 点击内容结果进入详情。
- 点击用户结果进入作者主页。

### 设计思路

搜索页采用：

```text
UISegmentedControl + 单 UITableView
```

Segment 负责切换搜索域，TableView 作为统一结果容器。这样比多个列表切换更容易维护状态，也更符合 MVC 中“控制器协调状态、视图负责展示”的思路。

---

## 6.4 发布模块

相关文件：

- `Release/YALReleaseController`
- `Release/YALCalendarController`
- `Network/Manager/YALContentManager`

### 功能点

- 选择图片。
- 输入标题。
- 输入正文。
- 选择日期。
- 选择城市。
- 选择心情。
- 添加地点。
- 发布内容。
- 编辑已发布内容。
- 发布后刷新首页/回忆页。

### 参数校验

发布前必须校验：

- 标题不能为空。
- 正文不能为空。
- 日期不能为空。
- 地点不能为空。
- 至少选择一张图片或满足项目当前发布规则。

地点是记忆系统的关键字段，因此发布时必须添加地点，否则会像缺少日期一样弹出警告。

### 地点选择

地点选择会进入地图选择模式，用户可以在地图上选择坐标和地点名称，发布时将经纬度和地点名称一起传给后端。

---

## 6.5 详情与评论模块

相关文件：

- `PostDetail/Controller/YALPostDetailController`
- `PostDetail/View/YALCommentCell`
- `Network/Manager/YALContentManager`

### 功能点

- 展示内容详情。
- 展示图片、标题、正文、作者信息、城市、年份、心情。
- 支持点赞。
- 支持收藏。
- 支持评论列表。
- 支持发表评论。
- 支持删除评论。
- 支持作者主页跳转。
- 评论内容超过两行时显示展开/收起。

### 评论展开收起

评论区根据 label 实际行数判断是否需要展开收起：

- 不超过两行：直接显示。
- 超过两行：默认收起为两行，并显示“展开”。
- 点击展开：显示完整内容，并切换为“收起”。

该实现解决了单纯按字数判断不准确的问题，因为不同屏幕宽度、字体大小和中文换行都会影响真实行数。

---

## 6.6 地图与足迹模块

相关文件：

- `Map/Controller/YALMapController`
- `Map/Model/YALMemoryPoint`
- `Mine/Controller/YALMineController`

### 功能点

- 展示所有有经纬度的记忆点。
- 支持地图定位权限。
- 支持选择地点模式。
- 支持点击标注进入详情。
- 支持从“我的”页面进入“足迹”场景。
- 从“我的”页面 push 进入地图时，播放 3D 小人按发布时间走过所有地点的动画。
- 从其他入口进入地图时不播放足迹动画。

### 足迹动画设计

足迹动画只在特定入口触发：

```text
Mine → 足迹 → Map
```

其他入口进入 `Map` 不播放，避免干扰用户普通地图浏览和地点选择。

动画核心思路：

1. 获取用户发布过的地点数据。
2. 按发布时间排序。
3. 在地图上绘制或移动一个 3D 小人/立体人物视图。
4. 按顺序从第一个地点移动到最后一个地点。
5. 动画结束后保留地图标注。

这部分是项目的个性化亮点，体现了“时间 + 空间 + 记忆路径”的产品表达。

---

## 6.7 回忆与时间线模块

相关文件：

- `Memory/Controller/YALMemoryController`
- `Memory/View/YALMemoryView`
- `Memory/View/YALMemoryMonthCell`
- `Memory/Model/YALMemoryMonthModel`
- `TimeLine/Controller/YALTimeLineController`
- `TimeLine/View/YALTimeLineView`
- `TimeLine/View/YALTimeLineDayCell`
- `TimeLine/View/YALTimeLineCardView`
- `TimeLine/Controller/YALTimeLineDetailController`
- `Network/Manager/YALTimelineManager`

### 功能点

- 按年份、月份组织用户记忆。
- 展示月份回忆卡片。
- 点击月份进入时间线。
- 时间线按日期展示记忆条目。
- 支持进入时间线详情页。

### 设计价值

首页更适合“浏览”，地图更适合“定位”，回忆页更适合“复盘”。  
这三个入口共同构成 MemoryCity 的核心信息结构：

```text
首页：内容流
地图：空间流
回忆：时间流
```

---

## 6.8 消息模块

相关文件：

- `Message/Controller/YALMessageController`
- `Message/View/YALMessageCell`

### 功能点

- 展示互动消息。
- 汇总点赞、评论、收藏等互动数据。
- 支持下拉刷新。
- 根据用户内容统计互动变化。

消息模块让用户能感知自己的内容被别人互动，增强应用的社交反馈。

---

## 6.9 我的模块

相关文件：

- `Mine/Controller/YALMineController`
- `Mine/View/YALMineView`
- `Mine/Controller/YALEditProfileViewController`
- `Mine/View/YALEditProfileView`
- `Mine/Controller/YALMineSettingsController`
- `Mine/Controller/YALChangePasswordViewController`
- `Mine/Controller/YALFavoritesController`
- `Mine/Controller/YALLikesController`
- `Mine/Controller/YALMyContentListController`

### 功能点

- 展示当前用户资料。
- 编辑昵称、头像、简介。
- 查看我的内容。
- 查看我的收藏。
- 查看我的点赞。
- 进入足迹地图。
- 修改密码。
- 退出登录。
- 未登录状态下显示游客模式并引导登录。

### 我的内容管理

`YALMyContentListController` 支持展示当前用户发布的内容，并支持进入详情、删除内容等操作。

### 设置页

设置页提供：

- 修改密码。
- 退出登录。

修改密码与忘记密码不同：  

- 修改密码要求用户已登录，并输入旧密码。
- 忘记密码不要求登录，通过手机号验证码验证身份。

---

## 7. 网络与鉴权设计

相关文件：

- `Network/Manager/YALNetworkManager`
- `Network/Manager/YALAuthManager`
- `Network/Manager/YALContentManager`
- `Network/Manager/YALTimelineManager`

### 7.1 网络基础封装

`YALNetworkManager` 基于 AFNetworking 封装：

- GET
- POST
- PUT
- DELETE

统一使用 JSON request serializer 和 JSON response serializer，设置超时时间与可接受响应类型。

### 7.2 鉴权管理

`YALAuthManager` 负责：

- 登录。
- 注册。
- 当前用户缓存。
- access token 保存。
- refresh token 保存。
- 请求头生成。
- 用户资料更新。
- 修改密码。
- 忘记密码。

请求头格式：

```http
Authorization: Bearer {accessToken}
Refresh-Authorization: Bearer {refreshToken}
```

### 7.3 双 Token 机制现状

当前项目已经具备：

- 登录后保存 access token。
- 登录后保存 refresh token。
- 请求时携带双 token。
- 存在 `refreshAccessTokenWithCompletion` 方法。

但当前仍建议后续优化：

- 在 `YALNetworkManager` 中统一拦截 401。
- access token 过期时自动 refresh。
- refresh 成功后重放原请求。
- 多个请求同时过期时只发起一次 refresh，其余请求排队等待。
- refresh 失败后统一清理登录态并返回登录页。

这部分可以作为项目后续优化点写入答辩，体现对真实线上鉴权机制的理解。

---

## 8. 接口清单

### 8.1 用户接口

| 方法 | 路径 | 功能 |
| --- | --- | --- |
| POST | `/api/user/login` | 登录 |
| POST | `/api/user/register` | 注册 |
| POST | `/api/user/refresh` | 刷新 access token |
| GET | `/api/user/info` | 获取当前用户信息 |
| PUT | `/api/user/info` | 更新用户信息 |
| GET/POST | `/api/user/profile` | 获取指定用户主页 |
| PUT | `/api/user/info/updatepassword` | 登录态修改密码 |
| POST | `/api/user/password/forgot/send-code` | 忘记密码发送验证码 |
| POST | `/api/user/password/forgot/verify-code` | 忘记密码校验验证码 |
| PUT | `/api/user/password/forgot/reset` | 忘记密码重置密码 |

### 8.2 内容接口

| 方法 | 路径 | 功能 |
| --- | --- | --- |
| POST | `/api/content/publish` | 发布内容 |
| GET | `/api/content/list` | 获取内容列表 |
| GET | `/api/content/my` | 获取我的内容 |
| GET | `/api/content/detail` | 获取内容详情 |
| GET | `/api/content/search` | 搜索内容或用户 |
| DELETE | `/api/content/delete` | 删除内容 |
| GET | `/api/content/filter` | 根据城市/年份/心情筛选内容 |

### 8.3 互动接口

| 方法 | 路径 | 功能 |
| --- | --- | --- |
| POST | `/api/interact/like` | 点赞/取消点赞 |
| POST | `/api/interact/collect` | 收藏/取消收藏 |
| GET | `/api/interact/collect/my` | 我的收藏 |
| GET | `/api/interact/comment/list` | 评论列表 |
| POST | `/api/interact/comment` | 发布评论 |
| DELETE | `/api/interact/comment/delete` | 删除评论 |

### 8.4 AI 与时间线接口

| 方法 | 路径 | 功能 |
| --- | --- | --- |
| POST | `/api/ai/analyze` | AI 内容分析 |
| GET | `/api/timeline/my` | 获取我的时间线 |

---

## 9. 数据模型总结

### 9.1 用户模型

`YALAuthUserModel` 表示登录用户信息。

主要字段：

- userId
- username
- nickname
- avatar
- bio
- token

### 9.2 内容模型

`YALPostModel` 表示首页和详情内容。

主要字段：

- contentId
- title
- desc/content
- city
- year
- mood
- images
- imageURLString
- createTime
- likeCount
- collectCount
- commentCount
- isLiked
- isCollected
- locationName
- latitude
- longitude
- authorUserId
- authorNickname
- authorAvatar
- authorBio

### 9.3 搜索模型

`YALSearchContentModel` 表示搜索到的内容。  
`YALSearchUserModel` 表示搜索到的用户。

### 9.4 地图模型

`YALMemoryPoint` 继承自 `MKPointAnnotation`，用于地图标注记忆点。

### 9.5 我的内容模型

`YALMyContentModel` 用于个人中心中的我的内容列表。

---

## 10. UI 设计风格

### 10.1 视觉方向

项目整体采用暖色、轻拟物和卡片式风格。

关键词：

- 温暖。
- 记忆感。
- 柔和。
- 卡片化。
- 城市漫步。
- 时间沉淀。

### 10.2 全局组件

- 导航栏使用半透明模糊背景。
- TabBar 使用自定义中间发布按钮。
- 首页卡片使用圆角、阴影和暖色背景。
- 评论区使用富文本式展开收起体验。
- 我的页面和回忆页面保持统一的暖色设计语言。

### 10.3 设计亮点

- 首页瀑布流让图片内容更有视觉节奏。
- 地图足迹动画让“记忆轨迹”具象化。
- 评论超过两行自动展开收起，更符合真实阅读体验。
- 发布页强制地点校验，保证地图和足迹功能的数据完整性。

---

## 11. 关键技术亮点

### 11.1 自定义瀑布流布局

项目通过自定义 `UICollectionViewLayout` 和 delegate 高度计算实现瀑布流，而不是简单使用固定网格。  
这体现了对 CollectionView 布局机制的掌握。

可在答辩中这样讲：

> 首页内容以图片为主，不同图片比例差异较大。如果使用普通网格，会产生大量裁切或留白。因此我实现了瀑布流布局，根据 item 宽度与图片比例计算高度，让内容呈现更自然。

### 11.2 地图足迹动画

项目将发布时间顺序和地理坐标结合，实现了“从我的页面进入地图时，小人按时间走过所有地点”的动画效果。

可在答辩中这样讲：

> 这个功能不是单纯展示地图标注，而是把用户的记忆点按时间排序，形成一条可视化路径。它表达的是用户和城市之间的关系，也是 MemoryCity 区别于普通相册应用的核心亮点。

### 11.3 评论动态展开收起

评论展开收起不是按文字长度判断，而是根据 UILabel 实际行数判断。

可在答辩中这样讲：

> 中文文本换行受到屏幕宽度、字体、标点和 AutoLayout 的影响，按字数判断并不准确。因此我通过 label 的实际渲染行数来判断是否需要展示展开按钮，保证不同设备上表现一致。

### 11.4 统一网络管理

项目将鉴权、内容、时间线等请求下沉到 Manager 层，控制器不直接拼复杂请求。

可在答辩中这样讲：

> 控制器只负责页面状态和用户交互，网络请求和数据解析放到 Manager 和 Model 中，减少页面代码耦合，也方便后续扩展和调试。

### 11.5 忘记密码短信验证流程

忘记密码流程拆成发送验证码、校验验证码、重置密码三个步骤，安全性高于直接凭手机号重置。

可在答辩中这样讲：

> 发送验证码前后端会先判断手机号是否存在，验证码正确后再进入重置密码页。后端可以返回一次性 reset token，避免只凭手机号直接改密码。

---

## 12. 后端需要重点支持的能力

### 12.1 阿里云短信验证码

后端需要完成：

- 接入阿里云短信 SDK。
- 配置 AccessKey、签名和短信模板。
- 生成 6 位验证码。
- 设置验证码有效期，建议 5 分钟。
- 限制同一手机号发送频率，建议 60 秒一次。
- 手机号不存在时返回“该账号不存在”。
- 验证成功后生成一次性 `reset_token`。
- 重置密码成功后删除验证码和 reset token。

### 12.2 密码安全

后端必须做到：

- 密码不能明文存储。
- 建议使用 BCrypt 或其他安全哈希。
- 修改密码或重置密码后，旧 token 可以选择失效。
- 忘记密码接口需要防刷和限流。

### 12.3 Token 安全

建议后端实现：

- access token 短有效期。
- refresh token 长有效期。
- refresh token 可轮换。
- refresh token 泄露时可主动失效。
- access token 过期返回统一 401 或固定业务 code。

---

## 13. 运行方式

### 13.1 环境要求

- macOS。
- Xcode。
- CocoaPods。
- iOS 13.0 及以上。

### 13.2 安装依赖

```bash
cd ios
pod install
```

### 13.3 打开项目

```bash
open MemoryCity.xcworkspace
```

### 13.4 命令行构建

```bash
cd ios
xcodebuild -workspace MemoryCity.xcworkspace \
  -scheme MemoryCity \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath /tmp/memory-city-derived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

---

## 14. 测试清单

### 14.1 登录注册

- 输入空账号密码时是否提示。
- 密码长度不足时是否提示。
- 登录成功是否进入主页面。
- 注册成功是否返回登录页。
- 已登录状态下冷启动是否进入主页面。

### 14.2 忘记密码

- 点击“忘记密码?”是否进入找回密码页。
- 手机号为空或格式错误是否提示。
- 手机号不存在时是否提示“该账号不存在”。
- 验证码发送成功后是否开始 60 秒倒计时。
- 验证码错误是否提示。
- 验证码正确是否进入重置密码页。
- 两次密码不一致是否提示。
- 重置成功是否返回登录页。

### 14.3 首页

- 首页列表是否正常加载。
- 瀑布流高度是否错落展示。
- 卡片底部点赞数、评论数是否显示。
- 下拉刷新是否正常。
- 点击卡片是否进入详情页。

### 14.4 发布

- 标题为空是否拦截。
- 日期为空是否拦截。
- 地点为空是否拦截。
- 添加地点后是否能发布。
- 发布成功后首页/回忆页是否刷新。

### 14.5 详情与评论

- 点赞是否更新状态。
- 收藏是否更新状态。
- 评论是否能发布。
- 评论超过两行是否出现展开按钮。
- 展开后是否显示全部内容。
- 收起后是否回到两行。

### 14.6 地图

- 地图权限弹窗是否正常。
- 记忆点是否能显示。
- 点击标注是否进入详情。
- 从我的页面进入足迹是否播放动画。
- 从普通地图入口进入是否不播放足迹动画。

### 14.7 我的

- 用户资料是否显示。
- 编辑资料是否更新。
- 我的内容是否加载。
- 我的收藏是否加载。
- 我的点赞是否加载。
- 退出登录是否回到登录页。

---

## 15. 当前已知问题与优化方向

### 15.1 双 Token 自动刷新机制待完善

当前项目已经保存并携带双 token，也存在刷新 access token 的方法，但尚未统一接入所有业务请求的 401 自动刷新和请求重试。

优化方案：

- 在 `YALNetworkManager` 统一拦截 401。
- 如果 access token 过期，调用 refresh 接口。
- refresh 成功后更新 access token。
- 自动重放原请求。
- 并发请求只触发一次 refresh。
- refresh 失败后清理登录态并返回登录页。

### 15.2 API Base URL 可配置化

当前多个 Manager 中各自维护 `kYALAPIBaseURL`。  
后续可以抽成统一配置文件，例如：

```text
YALAPIConfig.h / YALAPIConfig.m
```

支持开发环境、测试环境、生产环境切换。

### 15.3 错误提示统一化

目前各页面有自己的 alert 逻辑。  
后续可封装统一 Toast/Alert 工具，减少重复代码。

### 15.4 图片上传体验优化

后续可加入：

- 图片压缩进度。
- 上传进度条。
- 上传失败重试。
- 多图排序。

### 15.5 地图动画增强

后续可加入：

- 路径线渐进绘制。
- 关键地点暂停展示卡片。
- 动画速度控制。
- 支持按年份播放足迹。

---

## 16. 作品集展示模板

下面这部分可以直接复制到作品集网站、简历项目页或答辩 PPT。

### 16.1 项目标题

MemoryCity：基于时间与地理位置的 iOS 记忆记录应用

### 16.2 项目简介

MemoryCity 是一款使用 Objective-C 和 UIKit 开发的 iOS 原生应用，围绕“内容、时间、地点、互动”构建个人记忆管理体验。用户可以发布带图片、日期、心情和位置的记忆内容，并通过首页瀑布流、地图足迹、月份回忆和详情评论等方式回看自己的生活轨迹。

### 16.3 我的职责

可根据实际分工选择：

- 负责 iOS 客户端整体架构设计与模块拆分。
- 负责首页瀑布流、详情页、评论展开收起等核心 UI 与交互实现。
- 负责登录、注册、忘记密码、修改密码等账户体系。
- 负责内容发布、地点选择、地图足迹动画和时间线展示。
- 负责 AFNetworking 网络层封装、接口联调与数据模型解析。
- 负责项目整体视觉风格统一与页面体验优化。

### 16.4 技术栈描述

Objective-C、UIKit、Masonry、AFNetworking、SDWebImage、YYModel、MapKit、CoreLocation、PhotosUI、CocoaPods。

### 16.5 核心亮点

- 自定义瀑布流布局，提升图片内容浏览体验。
- 结合 MapKit 实现地图记忆点和足迹动画。
- 评论区按真实行数判断展开收起，适配不同屏幕宽度。
- 发布流程强制地点和日期校验，保证时间线和地图数据完整。
- 登录体系支持双 token、修改密码和短信验证码找回密码。
- 模块按 Controller/View/Model/Manager 拆分，结构清晰，便于维护。

### 16.6 项目难点

- 如何在 Objective-C 中维护多个业务模块的状态和跳转关系。
- 如何让瀑布流布局在图片比例不一致时仍保持自然美观。
- 如何将内容数据同时服务于首页、地图、时间线和个人中心。
- 如何处理评论文本在不同设备宽度下的动态展开收起。
- 如何设计忘记密码流程，避免只凭手机号直接重置密码。

### 16.7 解决方案

- 采用 MVC 模块化结构，将页面、视图、模型和网络请求拆开。
- 首页自定义布局并缓存瀑布流高度，减少重复计算。
- 内容模型中统一保留城市、年份、心情、经纬度、互动数量等字段，供不同模块复用。
- 评论区通过 UILabel 实际渲染行数判断是否显示展开按钮。
- 忘记密码拆分为发送验证码、验证码校验和重置密码三个接口，后端可通过一次性 reset token 提高安全性。

### 16.8 项目成果

- 完成 iOS 端主要业务闭环。
- 实现登录、注册、忘记密码、内容发布、首页浏览、详情互动、地图展示、回忆时间线和个人中心。
- 项目可通过 Xcode 构建运行。
- 具备继续扩展线上产品的基础架构。

---

## 17. 简历项目经历模板

可直接放入简历：

```text
MemoryCity - 基于时间与地理位置的 iOS 记忆记录应用

技术栈：Objective-C、UIKit、Masonry、AFNetworking、SDWebImage、MapKit、CoreLocation、CocoaPods

项目描述：
MemoryCity 是一款围绕图文内容、地理位置和时间线构建的 iOS 原生应用。用户可以发布带图片、日期、心情和地点的记忆内容，并通过首页瀑布流、地图足迹、月份回忆、详情评论和个人中心进行浏览与管理。

负责内容：
1. 负责首页瀑布流布局和内容卡片 UI，实现图片、标题、描述、点赞数和评论数展示。
2. 负责发布流程，支持图片选择、日期选择、地点选择和发布参数校验。
3. 负责详情页互动能力，实现点赞、收藏、评论列表、发表评论和评论展开收起。
4. 负责 MapKit 地图记忆点展示，并实现从个人中心进入地图时的足迹动画。
5. 负责账户体系，包括登录、注册、修改密码和短信验证码找回密码。
6. 封装 AFNetworking 网络请求和鉴权管理，统一处理用户、内容、互动和时间线接口。

项目亮点：
通过“首页内容流 + 地图空间流 + 回忆时间流”的产品结构，将普通图文内容组织为可回看的城市记忆；同时使用自定义瀑布流、地图足迹动画和动态评论展开收起提升用户体验。
```

---

## 18. 答辩讲稿模板

### 18.1 开场介绍

各位老师好，我的项目叫 MemoryCity，是一个基于 iOS 原生 Objective-C 开发的记忆记录应用。它的核心想法是把用户发布的图文内容和时间、地点、心情结合起来，让用户可以从首页、地图和时间线三个维度回看自己的生活记录。

### 18.2 为什么做这个项目

普通相册只能按时间看图片，普通社交平台更强调动态流。我希望做一个更偏个人记忆管理的应用，让每条内容都带有地点和时间。这样用户不仅能看到“我发了什么”，还能看到“我在哪些地方留下过记忆”。

### 18.3 系统架构

项目采用 MVC 分层，每个业务模块内部按 Controller、View、Model、Manager 拆分。页面控制器负责交互和跳转，View 负责 UI 布局，Model 负责数据结构，Manager 负责网络请求和数据解析。

### 18.4 主要功能

项目包含登录注册、忘记密码、首页瀑布流、搜索、发布、详情评论、地图足迹、回忆时间线、互动消息和个人中心等功能。用户可以完成从注册登录到发布内容、浏览内容、互动评论、查看足迹和管理个人资料的完整流程。

### 18.5 技术亮点

技术上我重点实现了三个部分：第一是首页自定义瀑布流布局；第二是地图足迹动画，将用户发布地点按时间顺序串起来；第三是评论区根据真实行数判断展开收起，提升长评论阅读体验。

### 18.6 后续优化

后续我会继续完善双 token 自动刷新机制、统一错误提示组件、优化图片上传体验，并增强地图足迹动画，比如加入路径线和按年份播放功能。

---

## 19. 页面截图占位模板

作品集里可以按下面结构放截图：

| 页面 | 截图 | 说明 |
| --- | --- | --- |
| 登录页 | TODO | 展示登录、注册和忘记密码入口 |
| 找回密码页 | TODO | 展示手机号验证码和倒计时 |
| 首页瀑布流 | TODO | 展示内容卡片、点赞数、评论数 |
| 发布页 | TODO | 展示图片、标题、日期、地点选择 |
| 详情页 | TODO | 展示内容详情、点赞收藏和评论 |
| 地图页 | TODO | 展示记忆点和足迹动画 |
| 回忆页 | TODO | 展示月份聚合 |
| 我的页 | TODO | 展示用户资料、收藏、点赞、足迹 |

---

## 20. 可替换信息模板

如果要提交给老师或放进作品集，可以替换这些内容：

```text
项目名称：MemoryCity / 拾光
项目周期：YYYY.MM - YYYY.MM
团队人数：X 人
我的角色：iOS 开发 / 客户端负责人 / 全栈开发
后端技术栈：填写你的后端技术，例如 Spring Boot / Flask / Node.js
数据库：填写你的数据库，例如 MySQL / PostgreSQL / Redis
部署地址：填写接口服务器地址
GitHub 地址：填写仓库地址
演示视频：填写视频链接
```

---

## 21. 项目一句话卖点

> MemoryCity 不只是记录一张照片，而是把照片背后的时间、地点和情绪连接起来，让用户在城市地图和时间线中重新走过自己的记忆。

