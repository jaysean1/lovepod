# Get User's Saved Tracks

Get a list of the songs saved in the current Spotify user's 'Your Music' library.

-   **OAuth 2.0 Scopes:** `user-library-read`

## Request

`GET /me/tracks`

### Query Parameters

| Name | Type | Description |
| :--- | :--- | :--- |
| `market` | string | *Optional*. An [ISO 3166-1 alpha-2 country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). If a country code is specified, only content that is available in that market will be returned. |
| `limit` | integer | *Optional*. The maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50. |
| `offset` | integer | *Optional*. The index of the first item to return. Default: 0 (the first item). Use with `limit` to get the next set of items. |

## Response

On success, the HTTP status code in the response header is `200 OK` and the response body contains a [Paging Object](https://developer.spotify.com/documentation/web-api/reference/object-model/#paging-object) of [Saved Track Objects](https://developer.spotify.com/documentation/web-api/reference/object-model/#saved-track-object).

### Paging Object Fields

| Name | Type | Description |
| :--- | :--- | :--- |
| `href` | string | A link to the Web API endpoint returning the full result of the request. |
| `limit` | integer | The maximum number of items in the response (as set in the query or by default). |
| `next` | string | URL to the next page of items. (`null` if none) |
| `offset` | integer | The offset of the items returned (as set in the query or by default). |
| `previous` | string | URL to the previous page of items. (`null` if none) |
| `total` | integer | The total number of items available to return. |
| `items` | array of [Saved Track Object] | The requested data. |

### Saved Track Object Fields

| Name | Type | Description |
| :--- | :--- | :--- |
| `added_at` | string | The date and time the track was saved in ISO 8601 format. |
| `track` | [Track Object](https://developer.spotify.com/documentation/web-api/reference/object-model/#track-object) | Information about the track. |

### Example Response

```json
{
  "href": "https://api.spotify.com/v1/me/tracks?offset=0&limit=1",
  "items": [
    {
      "added_at": "2024-01-16T18:34:09Z",
      "track": {
        "album": {
          "album_type": "album",
          "artists": [
            {
              "external_urls": {
                "spotify": "https://open.spotify.com/artist/06HL4z0CvFAxyc27GXpf02"
              },
              "href": "https://api.spotify.com/v1/artists/06HL4z0CvFAxyc27GXpf02",
              "id": "06HL4z0CvFAxyc27GXpf02",
              "name": "Taylor Swift",
              "type": "artist",
              "uri": "spotify:artist:06HL4z0CvFAxyc27GXpf02"
            }
          ],
          "available_markets": ["US", "CA"],
          "external_urls": {
            "spotify": "https://open.spotify.com/album/151w1FgRZfnKk99z5o6r6L"
          },
          "href": "https://api.spotify.com/v1/albums/151w1FgRZfnKk99z5o6r6L",
          "id": "151w1FgRZfnKk99z5o6r6L",
          "images": [
            {
              "height": 640,
              "url": "https://i.scdn.co/image/ab67616d0000b2739532e3593415294845720893",
              "width": 640
            }
          ],
          "name": "folklore",
          "release_date": "2020-07-24",
          "release_date_precision": "day",
          "total_tracks": 16,
          "type": "album",
          "uri": "spotify:album:151w1FgRZfnKk99z5o6r6L"
        },
        "artists": [
          {
            "external_urls": {
              "spotify": "https://open.spotify.com/artist/06HL4z0CvFAxyc27GXpf02"
            },
            "href": "https://api.spotify.com/v1/artists/06HL4z0CvFAxyc27GXpf02",
            "id": "06HL4z0CvFAxyc27GXpf02",
            "name": "Taylor Swift",
            "type": "artist",
            "uri": "spotify:artist:06HL4z0CvFAxyc27GXpf02"
          }
        ],
        "available_markets": ["US", "CA"],
        "disc_number": 1,
        "duration_ms": 241026,
        "explicit": false,
        "external_ids": {
          "isrc": "USUG12001837"
        },
        "external_urls": {
          "spotify": "https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b"
        },
        "href": "https://api.spotify.com/v1/tracks/0VjIjW4GlUZAMYd2vXMi3b",
        "id": "0VjIjW4GlUZAMYd2vXMi3b",
        "is_local": false,
        "name": "cardigan",
        "popularity": 75,
        "preview_url": "https://p.scdn.co/mp3-preview/...",
        "track_number": 2,
        "type": "track",
        "uri": "spotify:track:0VjIjW4GlUZAMYd2vXMi3b"
      }
    }
  ],
  "limit": 1,
  "next": "https://api.spotify.com/v1/me/tracks?offset=1&limit=1",
  "offset": 0,
  "previous": null,
  "total": 50
}
```
