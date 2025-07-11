# Spotify API Usage Guide for LovePod

This document provides a guide on how to use the Spotify Web API to fetch playlists and track cover images, as required for the LovePod application.

## 1. Authorization

Before making any API calls, the application must get the user's permission to access their Spotify data. This is done through OAuth 2.0.

-   **Scope**: To read a user's playlists (both public and private), you need the `playlist-read-private` scope. To read the user's library, you might also need `user-library-read`.

The result of a successful authorization is an **Access Token**, which must be included in the header of all subsequent API requests.

```
Authorization: Bearer <Your_Access_Token>
```

## 2. Fetching User's Playlists

To get a list of the current user's playlists, you make a GET request to the following endpoint.

-   **Endpoint**: `GET https://api.spotify.com/v1/me/playlists`

### Query Parameters:

-   `limit` (Optional): The maximum number of playlists to return. Default: 20, Max: 50.
-   `offset` (Optional): The index of the first playlist to return. Used for pagination.

### Example Response (Simplified):

The response is a paging object containing an array of simplified playlist objects.

```json
{
  "href": "https://api.spotify.com/v1/users/exampleuser/playlists?offset=0&limit=20",
  "items": [
    {
      "id": "37i9dQZF1DXcBWIGoYBM5M",
      "name": "Today's Top Hits",
      "description": "...",
      "images": [
        {
          "url": "https://i.scdn.co/image/ab67616d0000b273b...1",
          "height": 640,
          "width": 640
        }
      ],
      "owner": {
        "display_name": "Spotify"
      },
      "tracks": {
        "href": "https://api.spotify.com/v1/playlists/37i9dQZF1DXcBWIGoYBM5M/tracks",
        "total": 50
      }
    }
    // ... more playlists
  ],
  "total": 50
}
```

-   **Playlist Cover Image**: Each playlist object has an `images` array. You can use the URL from this array to display the playlist's cover art, as required in the "Playlist" screen.

## 3. Fetching a Playlist's Tracks (and their Cover Images)

Once you have a playlist's ID (from the step above), you can fetch the list of tracks within that playlist.

-   **Endpoint**: `GET https://api.spotify.com/v1/playlists/{playlist_id}/tracks`

### Path Parameters:

-   `playlist_id`: The Spotify ID for the playlist.

### Query Parameters:

-   `fields` (Optional): This is a very useful parameter to limit the response to only the data you need. For our use case, we need the track name, artist, and album cover.
    Example: `fields=items(track(name,artists(name),album(name,images)))`
-   `limit` (Optional): The maximum number of tracks to return. Default: 20, Max: 50.
-   `offset` (Optional): The index of the first track to return.

### Example Response (Simplified, using `fields` parameter):

The response contains an array of `playlist track` objects.

```json
{
  "items": [
    {
      "track": {
        "name": "Blinding Lights",
        "artists": [
          {
            "name": "The Weeknd"
          }
        ],
        "album": {
          "name": "After Hours",
          "images": [
            {
              "url": "https://i.scdn.co/image/ab67616d0000b273b...2",
              "height": 640,
              "width": 640
            },
            {
              "url": "https://i.scdn.co/image/ab67616d00001e02b...2",
              "height": 300,
              "width": 300
            },
            {
              "url": "https://i.scdn.co/image/ab67616d00004851b...2",
              "height": 64,
              "width": 64
            }
          ]
        }
      }
    }
    // ... more tracks
  ]
}
```

### How to get the Track's Cover Image:

As you can see in the response:
1.  Each `item` has a `track` object.
2.  The `track` object has an `album` object.
3.  The `album` object has an `images` array.

This `images` array contains the URLs for the album cover in different resolutions. For the "Now Playing" screen, you should select the URL corresponding to the desired image size (e.g., 640x640 for high quality, or a smaller one for thumbnails).

## Summary for Implementation

1.  **Authentication**: Implement OAuth to get an access token with the `playlist-read-private` scope.
2.  **Playlist Screen**:
    -   Call `GET /v1/me/playlists`.
    -   Iterate through the `items` array in the response.
    -   For each playlist, use `item.name` for the title and `item.images[0].url` for the cover art.
3.  **Now Playing Screen**:
    -   When a user selects a playlist, get its ID.
    -   Call `GET /v1/playlists/{playlist_id}/tracks`.
    -   When a track is playing, access `track.album.images` to get an array of cover images.
    -   Select the most appropriate image URL (e.g., `track.album.images[0].url` for the highest resolution) to display as the main album art.
    -   Display `track.name`, `track.artists[0].name`, and `track.album.name` as the song info.
