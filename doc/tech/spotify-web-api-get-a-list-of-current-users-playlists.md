# Spotify Web API - 获取当前用户的播放列表列表

## 概述

获取当前Spotify用户拥有或关注的播放列表列表。

## 授权范围

- **playlist-read-private**：访问您的私人播放列表

## 请求

### HTTP方法
```
GET /me/playlists
```

### 查询参数

| 参数 | 类型 | 描述 |
|---|---|---|
| limit | integer | 要返回的最大项目数。默认值：20。最小值：1。最大值：50。默认值：`limit=20` 范围：`0-50` 示例：`limit=10` |
| offset | integer | 要返回的第一个播放列表的索引。默认值：0（第一个对象）。最大偏移量：100,000。与`limit`一起使用以获取下一组播放列表。默认值：`offset=0` 示例：`offset=5` |

## 响应

### 状态码
- 200：成功
- 401：访问令牌无效或已过期
- 403：访问令牌无效或缺少所需范围
- 429：超出速率限制

### 响应体结构

#### 分页播放列表集合
| 字段 | 类型 | 描述 |
|---|---|---|
| href | string | 返回请求完整结果的Web API端点的链接。示例：`"https://api.spotify.com/v1/me/shows?offset=0&limit=20"` |
| limit | integer | 响应中的最大项目数（如查询中设置或默认设置）。示例：`20` |
| next | string | 下一页项目的URL。（如果没有则为`null`）。示例：`"https://api.spotify.com/v1/me/shows?offset=1&limit=1"` |
| offset | integer | 返回项目的偏移量（如查询中设置或默认设置）。示例：`0` |
| previous | string | 上一页项目的URL。（如果没有则为`null`）。示例：`"https://api.spotify.com/v1/me/shows?offset=1&limit=1"` |
| total | integer | 可返回的项目总数。示例：`4` |
| items | array of SimplifiedPlaylistObject | 播放列表对象数组 |

#### 简化播放列表对象 (SimplifiedPlaylistObject)
| 字段 | 类型 | 描述 |
|---|---|---|
| collaborative | boolean | 如果所有者允许其他用户修改播放列表，则为`true`。 |
| description | string | 播放列表描述。仅针对修改过的、已验证的播放列表返回，否则为`null`。 |
| external_urls | object | 此播放列表的已知外部URL。 |
| href | string | 提供播放列表完整详细信息的Web API端点的链接。 |
| id | string | 播放列表的Spotify ID。 |
| images | array of ImageObject | 播放列表的图像。数组可能为空或包含最多三个图像。图像按大小降序返回。注意：如果返回，图像的源URL（`url`）是临时的，将在不到一天内过期。 |
| name | string | 播放列表的名称。 |
| owner | object | 拥有播放列表的用户。 |
| public | boolean | 播放列表的公开/私有状态（如果已添加到用户个人资料中）：`true`表示播放列表是公开的，`false`表示播放列表是私有的，`null`表示播放列表状态不相关。 |
| snapshot_id | string | 当前播放列表的版本标识符。可以在其他请求中提供以定位特定播放列表版本。 |
| tracks | object | 包含指向Web API端点的链接（`href`），可在其中检索播放列表曲目的完整详细信息，以及播放列表中的曲目`total`数量。注意，曲目对象可能为`null`。如果曲目不再可用，则可能发生这种情况。 |
| type | string | 对象类型："playlist"。 |
| uri | string | 播放列表的Spotify URI。 |

#### 所有者对象 (owner)
| 字段 | 类型 | 描述 |
|---|---|---|
| external_urls | object | 此用户的已知公共外部URL。 |
| href | string | 此用户的Web API端点的链接。 |
| id | string | 此用户的Spotify用户ID。 |
| type | string | 对象类型。允许值："user"。 |
| uri | string | 此用户的Spotify URI。 |
| display_name | string | 用户个人资料上显示的名称。如果不可用则为`null`。 |

#### 图像对象 (ImageObject)
| 字段 | 类型 | 描述 |
|---|---|---|
| url | string | 图像的源URL。示例：`"https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228"` |
| height | integer | 图像高度（像素）。示例：`300` |
| width | integer | 图像宽度（像素）。示例：`300` |

#### 曲目集合对象 (tracks)
| 字段 | 类型 | 描述 |
|---|---|---|
| href | string | 可检索播放列表曲目完整详细信息的Web API端点的链接。 |
| total | integer | 播放列表中的曲目数量。 |

## 端点

```
https://api.spotify.com/v1/me/playlists
```

## 响应示例

```json
{
  "href": "https://api.spotify.com/v1/me/shows?offset=0&limit=20",
  "limit": 20,
  "next": "https://api.spotify.com/v1/me/shows?offset=1&limit=1",
  "offset": 0,
  "previous": "https://api.spotify.com/v1/me/shows?offset=1&limit=1",
  "total": 4,
  "items": [
    {
      "collaborative": false,
      "description": "string",
      "external_urls": {
        "spotify": "string"
      },
      "href": "string",
      "id": "string",
      "images": [
        {
          "url": "https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228",
          "height": 300,
          "width": 300
        }
      ],
      "name": "string",
      "owner": {
        "external_urls": {
          "spotify": "string"
        },
        "href": "string",
        "id": "string",
        "type": "user",
        "uri": "string",
        "display_name": "string"
      },
      "public": false,
      "snapshot_id": "string",
      "tracks": {
        "href": "string",
        "total": 0
      },
      "type": "string",
      "uri": "string"
    }
  ]
}
```

## 使用场景

此API端点适用于：
- 获取用户拥有的所有播放列表
- 获取用户关注的所有播放列表
- 在应用中显示用户的播放列表库
- 实现播放列表选择功能
- 分页加载大量播放列表

## 注意事项

- 返回的播放列表包括用户拥有和关注的所有播放列表
- 支持分页，每次最多返回50个播放列表
- 图像URL是临时的，将在不到一天内过期
- 私人播放列表需要playlist-read-private授权范围
- 可以通过limit和offset参数实现分页加载
- total字段表示用户拥有的播放列表总数，可用于计算分页