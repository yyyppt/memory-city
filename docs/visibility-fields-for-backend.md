# 公开 / 私密 对接字段文档

这份文档只写前端当前实际用于判断“公开 / 私密”的接口和字段。

后端只要按这里返回，前端现有逻辑就能正确分到：

- 首页推荐
- 我的公开内容
- 我的私密内容

---

## 一、发布接口

### 接口

`POST /content/publish`

### 前端会传的核心可见性字段

## 公开时

```json
{
  "is_public": true
}
```

## 私密时

```json
{
  "is_public": false
}
```

### 后端要求

发布时必须真正保存 `is_public`，不要忽略。

---

## 二、我的内容接口

### 接口

`GET /content/my`

### 前端请求参数

```json
{
  "page": 1,
  "pageSize": 10,
  "size": 10,
  "limit": 10,
  "include_private": true,
  "includePrivate": true,
  "visibility": "all",
  "scope": "all"
}
```

### 后端要求

这个接口必须返回当前用户的：

- 公开内容
- 私密内容

不能只返回公开内容。

---

## 三、首页内容接口

### 接口

`GET /content/list`

### 后端要求

这个接口只能返回公开内容。

如果返回了私密内容，前端首页就会出现私密内容。

---

## 四、内容对象必须返回的可见性字段

后端返回每条内容时，前端当前按下面字段判断：

- `is_public`

兼容历史数据时，前端也会兜底读取：

- `isPublic`

---

## 五、前端如何判断

前端优先看：

- `is_public`

如果没有，再兼容看：

- `isPublic`

#### 这些值会被判定为公开

- `true`
- `1`
- `"true"`
- `"1"`
- `"yes"`
- `"public"`
- `"公开"`

#### 这些值会被判定为私密

- `false`
- `0`
- `"false"`
- `"0"`
- `"no"`

---

## 六、后端最稳的返回方式

最稳的方式就是每条内容都稳定返回：

### 公开内容

```json
{
  "content_id": 1001,
  "title": "公开内容",
  "content": "这是一条公开内容",
  "is_public": true
}
```

### 私密内容

```json
{
  "content_id": 1002,
  "title": "私密内容",
  "content": "这是一条私密内容",
  "is_public": false
}
```

最重要的是：

- 公开：`is_public = true`
- 私密：`is_public = false`

---

## 七、接口返回要求总结

### `/content/publish`

必须正确保存可见性。

### `/content/my`

必须返回当前用户全部内容，包括私密。

### `/content/list`

只能返回公开内容。

### 每条内容对象

至少稳定返回：

```json
{
  "is_public": true_or_false
}
```

---

## 八、可以直接发给后端

请按下面规则对接：

1. `/content/publish` 必须真正保存可见性字段  
2. `/content/my` 必须返回当前用户全部内容，包括私密  
3. `/content/list` 只能返回公开内容  
4. 每条内容对象稳定返回 `is_public`
   - 公开时：`true`
   - 私密时：`false`
