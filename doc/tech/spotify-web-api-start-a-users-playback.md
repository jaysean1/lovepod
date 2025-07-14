# Spotify Web API - 开始/恢复用户播放

## 概述

在用户活动设备上开始新的上下文或恢复当前播放。此API仅适用于拥有Spotify Premium的用户。当您将此API与其他播放器API端点一起使用时，执行顺序无法保证。

## 重要政策说明

- **流媒体应用不得商业化**：Spotify平台不能用于开发商业流媒体集成
- **保持音频内容原始形式**：不得开发修改Spotify内容的应用
- **不得同步Spotify内容**：不得将任何录音与视觉媒体同步
- **Spotify内容不得广播**：不能用于非交互式广播

## 授权范围

- **user-modify-playback-state**：控制Spotify客户端和Spotify Connect设备上的播放

## 请求

### HTTP方法
```
PUT /me/player/play
```

### 查询参数

| 参数 | 类型 | 描述 |
|---|---|---|
| device_id | string | 此命令目标的设备ID。如果未提供，则用户的当前活动设备为目标。示例：`device_id=0d1841b0976bae2a3a310dd74c0f3df354899bc8` |

### 请求体 (application/json)

支持自由格式的附加属性

| 字段 | 类型 | 描述 |
|---|---|---|
| context_uri | string | 可选。要播放的上下文的Spotify URI。有效上下文为专辑、艺术家和播放列表。示例：`{"context_uri":"spotify:album:1Je1IMUlBXcx1Fz0WE7oPT"}` |
| uris | array of strings | 可选。要播放的Spotify曲目URI的JSON数组。例如：`{"uris": ["spotify:track:4iV5W9uYEdYUVa79Axb7Rh", "spotify:track:1301WleyT98MSxVHPZCA6M"]}` |
| offset | object | 可选。指示应从上下文的何处开始播放。仅当context_uri对应于专辑或播放列表对象时可用。"position"是基于0的且不能为负。示例：`"offset": {"position": 5}`。"uri"是表示要开始的项目的uri的字符串。示例：`"offset": {"uri": "spotify:track:1301WleyT98MSxVHPZCA6M"}` |
| position_ms | integer | 可选。开始播放的位置（毫秒）。示例：`"position_ms": 0` |

## 响应

### 状态码
- 204：播放已开始
- 401：访问令牌无效或已过期
- 403：访问令牌无效或缺少所需范围，或用户不是Premium用户
- 429：超出速率限制

## 端点

```
https://api.spotify.com/v1/me/player/play
```

## 请求示例

### 从专辑特定位置开始播放
```json
{
  "context_uri": "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
  "offset": {
    "position": 5
  },
  "position_ms": 0
}
```

### 播放特定曲目列表
```json
{
  "uris": [
    "spotify:track:4iV5W9uYEdYUVa79Axb7Rh",
    "spotify:track:1301WleyT98MSxVHPZCA6M"
  ]
}
```

### 从特定曲目的特定位置开始播放
```json
{
  "context_uri": "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M",
  "offset": {
    "uri": "spotify:track:1301WleyT98MSxVHPZCA6M"
  },
  "position_ms": 30000
}
```

## 使用场景

此API端点适用于：
- 开始播放专辑、播放列表或艺术家页面
- 恢复暂停的播放
- 从特定曲目或位置开始播放
- 播放用户指定的曲目列表
- 在特定设备上控制播放

## 注意事项

- 需要Spotify Premium账户
- 当与其他播放器API端点一起使用时，执行顺序无法保证
- 如果未指定device_id，则命令将发送到当前活动设备
- 可以同时使用context_uri或uris参数，但不能同时使用两者