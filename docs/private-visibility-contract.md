# 内容可见性接口对接文档

## 目的

保证“私密内容”满足这三个结果：

1. 发布为私密后，不出现在首页推荐
2. 发布为私密后，出现在“我的 -> 私密内容”
3. 发布为公开后，出现在首页推荐和“我的 -> 公开内容”

---

## 一、发布接口

### 路径

`POST /content/publish`

### 前端当前会传的可见性字段

当用户选择“公开”时：

```json
{
  "is_public": true,
  "isPublic": true,
  "visible": true,
  "visibility": "public",
  "public_status": 1,
  "scope": "public",
  "permission": "public",
  "is_private": false,
  "private": false
}
```

当用户选择“私密”时：

```json
{
  "is_public": false,
  "isPublic": false,
  "visible": false,
  "visibility": "private",
  "public_status": 0,
  "scope": "private",
  "permission": "private",
  "is_private": true,
  "private": true
}
```

### 后端要求

后端收到这些字段后，必须按它们的语义真正入库，不能忽略。

尤其是私密发布时，最终数据库里必须能明确落成“非公开”。

---

## 二、我的内容列表接口

### 路径

`GET /content/my`

### 前端当前会传的参数

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

这个接口必须返回**当前用户的全部内容**，包括：

- 公开内容
- 私密内容

不能只返回公开内容。

---

## 三、首页内容列表接口

### 路径

`GET /content/list`

### 后端要求

这个接口只能返回公开内容。

如果后端当前实现里已经可能混入私密内容，那么至少必须在每条内容对象里带清楚可见性字段，让前端可以正确过滤。

---

## 四、后端返回时每条内容必须带的可见性字段

后端返回内容对象时，至少保证下面任意一组字段稳定存在。

### 推荐优先

```json
{
  "is_public": true
}
```

或

```json
{
  "is_public": false
}
```

### 兼容可识别字段

前端当前可识别下面这些字段：

- `is_public`
- `isPublic`
- `visible`
- `visibility`
- `public_status`
- `scope`
- `permission`
- `is_private`
- `isPrivate`
- `private`
- `private_status`

---

## 五、字段值规范

### 表示公开的值

后端返回以下任意值，前端会识别为公开：

- `true`
- `1`
- `"true"`
- `"1"`
- `"yes"`
- `"public"`
- `"公开"`

### 表示私密的值

后端返回以下任意值，前端会识别为私密：

- `false`
- `0`
- `"false"`
- `"0"`
- `"no"`
- `"2"`
- `"private"`
- `"only_self"`
- `"self"`
- `"personal"`
- `"私密"`
- `"仅自己可见"`

---

## 六、推荐的返回示例

### 私密内容

```json
{
  "content_id": 101,
  "title": "我的私密记忆",
  "content": "今天不想公开。",
  "is_public": false
}
```

### 公开内容

```json
{
  "content_id": 102,
  "title": "今天去了大雁塔",
  "content": "天气很好。",
  "is_public": true
}
```

---

## 七、联调验收标准

### 场景 1：发布私密内容

用户发布时选择“私密”

期望：

1. `/content/publish` 成功
2. `/content/my` 返回中能看到这条内容
3. 这条内容的可见性字段明确为私密
4. `/content/list` 中不应出现这条内容

### 场景 2：发布公开内容

用户发布时选择“公开”

期望：

1. `/content/publish` 成功
2. `/content/my` 返回中能看到这条内容
3. 这条内容的可见性字段明确为公开
4. `/content/list` 中可以出现这条内容

---

## 八、可以直接发给后端的话

请确保 `/content/publish` 真正保存可见性字段；`/content/my` 必须返回当前用户的全部内容（包括私密）；`/content/list` 只返回公开内容。每条内容对象至少稳定返回 `is_public`，私密时为 `false`，公开时为 `true`。
