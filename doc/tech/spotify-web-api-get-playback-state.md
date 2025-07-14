# Spotify Web API - 获取用户当前播放状态

## 概述

获取用户当前播放状态的详细信息，包括正在播放的曲目或剧集、播放进度以及活动设备信息。

## 重要政策说明

- **流媒体应用不得商业化**：Spotify平台不能用于开发商业流媒体集成
- **保持音频内容原始形式**：不得开发修改Spotify内容的应用
- **不得同步Spotify内容**：不得将任何录音与视觉媒体同步
- **Spotify内容不得广播**：不能用于非交互式广播

## 授权范围

- **user-read-playback-state**：读取当前播放内容和Spotify Connect设备信息

## 请求

### HTTP方法
```
GET /me/player
```

### 查询参数

| 参数 | 类型 | 描述 |
|---|---|---|
| market | string | ISO 3166-1 alpha-2国家代码。如果指定国家代码，则只返回该市场可用的内容。如果请求头中指定了有效的用户访问令牌，则与用户账户关联的国家将优先于此参数。注意：如果未提供市场或用户国家，则认为内容对客户端不可用。用户可以在账户设置中查看与其账户关联的国家。示例：`market=ES` |
| additional_types | string | 客户端支持的除默认`track`类型外的项目类型列表，以逗号分隔。有效类型为：`track`和`episode`。注意：引入此参数是为了允许现有客户端保持其当前行为，将来可能会弃用。除了提供此参数外，请确保您的客户端通过检查每个对象的`type`字段来正确处理将来新类型的情况。 |

## 响应

### 状态码
- 200：成功
- 204：当前没有可用的设备
- 401：访问令牌无效或已过期
- 403：访问令牌无效或缺少所需范围
- 429：超出速率限制

### 响应体结构

#### 设备信息 (device)
| 字段 | 类型 | 描述 |
|---|---|---|
| id | string | 设备ID。此ID是唯一的且在一定程度上是持久的。但是，这不能保证，任何缓存的`device_id`应定期清除并根据需要重新获取。 |
| is_active | boolean | 此设备是否为当前活动设备 |
| is_private_session | boolean | 此设备是否处于私人会话模式 |
| is_restricted | boolean | 控制此设备是否受限。如果为"true"，则此设备将不接受任何Web API命令 |
| name | string | 设备的人类可读名称。某些设备具有用户可以配置的名称（例如"最响的扬声器"），某些设备具有与制造商或设备型号关联的通用名称。示例："Kitchen speaker" |
| type | string | 设备类型，如"computer"、"smartphone"或"speaker"。示例："computer" |
| volume_percent | integer | 当前音量百分比。范围：0-100。示例：59 |
| supports_volume | boolean | 此设备是否可以用于设置音量 |

#### 播放状态
| 字段 | 类型 | 描述 |
|---|---|---|
| repeat_state | string | 重复模式：off、track、context |
| shuffle_state | boolean | 随机播放是否开启 |
| context | object | 上下文对象。可以为`null` |
| timestamp | integer | 播放状态最后更改时的Unix毫秒时间戳（播放、暂停、跳过、拖动、新歌曲等） |
| progress_ms | integer | 当前播放曲目或剧集的进度（毫秒）。可以为`null` |
| is_playing | boolean | 如果有内容正在播放，返回`true` |
| item | object | 当前播放的曲目或剧集。可以为`null` |
| currently_playing_type | string | 当前播放项目的对象类型。可以是`track`、`episode`、`ad`或`unknown` |
| actions | object | 允许根据当前上下文中可用的播放操作来更新用户界面 |

#### 上下文对象 (context)
| 字段 | 类型 | 描述 |
|---|---|---|
| type | string | 对象类型，如"artist"、"playlist"、"album"、"show" |
| href | string | 提供曲目完整详细信息的Web API端点的链接 |
| external_urls | object | 此上下文的外部URL |
| uri | string | 上下文的Spotify URI |

#### 动作对象 (actions)
| 字段 | 类型 | 描述 |
|---|---|---|
| interrupting_playback | boolean | 中断播放 |
| pausing | boolean | 暂停 |
| resuming | boolean | 恢复 |
| seeking | boolean | 定位播放位置 |
| skipping_next | boolean | 跳到下一个上下文 |
| skipping_prev | boolean | 跳到上一个上下文 |
| toggling_repeat_context | boolean | 切换重复上下文标志 |
| toggling_shuffle | boolean | 切换随机播放标志 |
| toggling_repeat_track | boolean | 切换重复曲目标志 |
| transferring_playback | boolean | 在设备间传输播放 |

## 曲目对象 (TrackObject)

包含专辑信息、艺术家信息、曲目元数据等完整信息。

## 剧集对象 (EpisodeObject)

包含剧集描述、时长、语言、发布日期等完整信息。

## 端点

```
https://api.spotify.com/v1/me/player
```

## 响应示例

```json
{
  "device": {
    "id": "string",
    "is_active": false,
    "is_private_session": false,
    "is_restricted": false,
    "name": "Kitchen speaker",
    "type": "computer",
    "volume_percent": 59,
    "supports_volume": false
  },
  "repeat_state": "string",
  "shuffle_state": false,
  "context": {
    "type": "string",
    "href": "string",
    "external_urls": {
      "spotify": "string"
    },
    "uri": "string"
  },
  "timestamp": 0,
  "progress_ms": 0,
  "is_playing": false,
  "item": {
    "album": {
      "album_type": "compilation",
      "total_tracks": 9,
      "available_markets": ["CA", "BR", "IT"],
      "external_urls": {
        "spotify": "string"
      },
      "href": "string",
      "id": "2up3OPMp9Tb4dAKM2erWXQ",
      "images": [
        {
          "url": "https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228",
          "height": 300,
          "width": 300
        }
      ],
      "name": "string",
      "release_date": "1981-12",
      "release_date_precision": "year",
      "restrictions": {
        "reason": "market"
      },
      "type": "album",
      "uri": "spotify:album:2up3OPMp9Tb4dAKM2erWXQ",
      "artists": [
        {
          "external_urls": {
            "spotify": "string"
          },
          "href": "string",
          "id": "string",
          "name": "string",
          "type": "artist",
          "uri": "string"
        }
      ]
    },
    "artists": [
      {
        "external_urls": {
          "spotify": "string"
        },
        "href": "string",
        "id": "string",
        "name": "string",
        "type": "artist",
        "uri": "string"
      }
    ],
    "available_markets": ["string"],
    "disc_number": 0,
    "duration_ms": 0,
    "explicit": false,
    "external_ids": {
      "isrc": "string",
      "ean": "string",
      "upc": "string"
    },
    "external_urls": {
      "spotify": "string"
    },
    "href": "string",
    "id": "string",
    "is_playable": false,
    "linked_from": {},
    "restrictions": {
      "reason": "string"
    },
    "name": "string",
    "popularity": 0,
    "preview_url": "string",
    "track_number": 0,
    "type": "track",
    "uri": "string",
    "is_local": false
  },
  "currently_playing_type": "string",
  "actions": {
    "interrupting_playback": false,
    "pausing": false,
    "resuming": false,
    "seeking": false,
    "skipping_next": false,
    "skipping_prev": false,
    "toggling_repeat_context": false,
    "toggling_shuffle": false,
    "toggling_repeat_track": false,
    "transferring_playback": false
  }
}
```

## 使用场景

此API端点适用于：
- 获取用户当前播放状态
- 显示正在播放的曲目信息
- 获取当前活动设备信息
- 检查播放进度和播放模式
- 确定可用的播放控制操作