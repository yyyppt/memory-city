# `/ai/analyze` 流式接口文档

## 请求

### Method

`POST /ai/analyze`

### Headers

```http
Accept: text/event-stream, application/json
Content-Type: application/json
Authorization: Bearer <token>
Cache-Control: no-cache
```

### Body

```json
{
  "text": "前端传入的完整提示词"
}
```

请求体只需要一个字段：

- `text`: string

---

## 响应

后端返回 **SSE**。

### Headers

```http
Content-Type: text/event-stream; charset=utf-8
Cache-Control: no-cache
Connection: keep-alive
```

### 返回规则

每条流消息格式固定为：

```text
data: {"summary_delta":"一小段文本"}

```

注意：

1. 必须以 `data:` 开头
2. 每条消息后面必须有一个空行
3. `summary_delta` 是字符串
4. 每次只返回新增的那一小段，不要返回整段全文
5. 流结束时返回：

```text
data: [DONE]

```

---

## 唯一必需字段

后端只需要返回这个字段：

- `summary_delta`

类型：

```json
{
  "summary_delta": "string"
}
```

这个字段的含义是：

- 当前新增的一小段回答文本

前端会把每一次收到的 `summary_delta` 按顺序直接拼到后面。

也就是：

第一次收到：

```json
{"summary_delta":"上海是中国的"}
```

第二次收到：

```json
{"summary_delta":"经济中心之一，"}
```

第三次收到：

```json
{"summary_delta":"站内结果主要集中在街区生活。"}
```

前端最终显示为：

```text
上海是中国的经济中心之一，站内结果主要集中在街区生活。
```

---

## 标准示例

```text
data: {"summary_delta":"上海是中国的"}

data: {"summary_delta":"经济中心之一，"}

data: {"summary_delta":"站内结果主要集中在"}

data: {"summary_delta":"街区生活和城市记忆。"}

data: [DONE]

```

---

## 后端实现要求

1. 不要返回整段全文反复覆盖
2. 不要把字段名写成 `content`、`answer`、`text`
3. 只用 `summary_delta`
4. 每一段返回新增字符
5. 按 SSE 标准发送
6. 最后返回 `[DONE]`

---

## 错误示例

### 错误 1

```text
data: {"summary":"完整回答全文"}

```

这个不是当前要对接的流式增量协议。

### 错误 2

```text
data: {"content":"一小段文本"}

```

字段名不对。

### 错误 3

```text
{"summary_delta":"一小段文本"}
```

缺少 `data:` 和空行，不是 SSE。

### 错误 4

```text
data: {"summary_delta":"第一段"}
data: {"summary_delta":"第二段"}
```

消息之间缺少空行。

---

## 交付给后端的话

`/ai/analyze` 请按 SSE 返回，响应头使用 `text/event-stream`。每条消息固定返回 `data: {"summary_delta":"..."}`，每次只给新增的几个字，消息之间空一行，结束时返回 `data: [DONE]`。这就是当前前端流式追加显示使用的协议。
