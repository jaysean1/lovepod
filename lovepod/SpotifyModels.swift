// lovepod/SpotifyModels.swift
// Spotify 数据模型定义，包含播放列表、歌曲、专辑等结构
// 用于封装 Spotify Web API 和 iOS SDK 返回的数据

import Foundation
import SwiftUI

// MARK: - Spotify Image Model
struct SpotifyImage: Codable, Identifiable {
    let id = UUID()
    let url: String
    let height: Int?
    let width: Int?
    
    enum CodingKeys: String, CodingKey {
        case url, height, width
    }
    
    /// 获取最适合指定尺寸的图片 URL
    static func bestImageURL(from images: [SpotifyImage], targetSize: CGFloat = 300) -> String? {
        guard !images.isEmpty else { return nil }
        
        // 按尺寸排序，找到最接近目标尺寸的图片
        let sortedImages = images.sorted { img1, img2 in
            let size1 = img1.width ?? 0
            let size2 = img2.width ?? 0
            let diff1 = abs(size1 - Int(targetSize))
            let diff2 = abs(size2 - Int(targetSize))
            return diff1 < diff2
        }
        
        return sortedImages.first?.url
    }
}

// MARK: - Spotify Artist Model
struct SpotifyArtist: Codable, Identifiable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, images
    }
}

// MARK: - Spotify Album Model
struct SpotifyAlbum: Codable, Identifiable {
    let id: String
    let name: String
    let images: [SpotifyImage]
    let artists: [SpotifyArtist]
    let releaseDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, images, artists
        case releaseDate = "release_date"
    }
    
    /// 获取专辑封面 URL
    var imageURL: String? {
        return SpotifyImage.bestImageURL(from: images, targetSize: 300)
    }
    
    /// 获取主要艺术家名称
    var primaryArtistName: String {
        return artists.first?.name ?? "Unknown Artist"
    }
}

// MARK: - Spotify Track Model
struct SpotifyTrack: Codable, Identifiable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let durationMs: Int?
    let explicit: Bool?
    let previewUrl: String?
    let uri: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, artists, album, explicit, uri
        case durationMs = "duration_ms"
        case previewUrl = "preview_url"
    }
    
    /// 获取主要艺术家名称
    var primaryArtistName: String {
        return artists.first?.name ?? "Unknown Artist"
    }
    
    /// 获取专辑封面 URL
    var albumImageURL: String? {
        return album.imageURL
    }
    
    /// 获取时长字符串 (mm:ss)
    var durationString: String {
        guard let durationMs = durationMs else { return "--:--" }
        let totalSeconds = durationMs / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Spotify Playlist Track Model (用于播放列表中的歌曲包装)
struct SpotifyPlaylistTrack: Codable {
    let track: SpotifyTrack?
    let addedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case track
        case addedAt = "added_at"
    }
}

// MARK: - Spotify Owner Model
struct SpotifyOwner: Codable, Identifiable {
    let id: String
    let displayName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

// MARK: - Spotify Playlist Model
struct SpotifyPlaylist: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let images: [SpotifyImage]
    let owner: SpotifyOwner
    let tracks: SpotifyPlaylistTracksInfo
    let uri: String
    let isPublic: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, images, owner, tracks, uri
        case isPublic = "public"
    }
    
    /// 获取播放列表封面 URL
    var imageURL: String? {
        return SpotifyImage.bestImageURL(from: images, targetSize: 300)
    }
    
    /// 获取歌曲数量描述
    var trackCountDescription: String {
        let count = tracks.total
        return count == 1 ? "1 song" : "\(count) songs"
    }
}

// MARK: - Spotify Playlist Tracks Info
struct SpotifyPlaylistTracksInfo: Codable {
    let href: String
    let total: Int
}

// MARK: - Spotify API Response Models

// 播放列表列表响应
struct SpotifyPlaylistsResponse: Codable {
    let href: String
    let items: [SpotifyPlaylist]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}

// 播放列表歌曲响应
struct SpotifyPlaylistTracksResponse: Codable {
    let href: String
    let items: [SpotifyPlaylistTrack]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}

// MARK: - Player State Models (来自 iOS SDK)

/// 播放状态枚举
enum SpotifyPlaybackState {
    case playing
    case paused
    case stopped
    case unknown
}

/// 重复模式枚举
enum SpotifyRepeatMode {
    case off
    case track
    case context
}

/// 播放器状态模型 (映射自 SPTAppRemotePlayerState)
struct SpotifyPlayerState {
    let track: SpotifyTrack?
    let isPaused: Bool
    let playbackPosition: TimeInterval
    let playbackSpeed: Float
    let playbackRestrictions: [String: Bool]
    
    var isPlaying: Bool {
        return !isPaused
    }
    
    var playbackState: SpotifyPlaybackState {
        if isPaused {
            return .paused
        } else if playbackSpeed > 0 {
            return .playing
        } else {
            return .stopped
        }
    }
}

// MARK: - Playback Context Models (for Web API)

/// Spotify播放上下文模型，用于获取当前播放状态
struct SpotifyPlaybackContext: Codable {
    let device: SpotifyDevice?
    let shuffleState: Bool?
    let repeatState: String?
    let timestamp: Int?
    let context: SpotifyContext?
    let progressMs: Int?
    let item: SpotifyTrack?
    let isPlaying: Bool?
    
    enum CodingKeys: String, CodingKey {
        case device, context, item
        case shuffleState = "shuffle_state"
        case repeatState = "repeat_state"
        case timestamp
        case progressMs = "progress_ms"
        case isPlaying = "is_playing"
    }
}

/// Spotify设备信息
struct SpotifyDevice: Codable {
    let id: String?
    let isActive: Bool
    let isPrivateSession: Bool
    let isRestricted: Bool
    let name: String
    let type: String
    let volumePercent: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type
        case isActive = "is_active"
        case isPrivateSession = "is_private_session"
        case isRestricted = "is_restricted"
        case volumePercent = "volume_percent"
    }
}

/// Spotify播放上下文信息
struct SpotifyContext: Codable {
    let type: String  // "playlist", "album", "artist", etc.
    let href: String
    let uri: String
    
    /// 检查是否是指定的playlist URI
    func isPlaylist(withURI playlistURI: String) -> Bool {
        return type == "playlist" && uri == playlistURI
    }
}

// MARK: - Error Models

enum SpotifyError: Error, LocalizedError {
    case notAuthenticated
    case networkError(String)
    case apiError(String)
    case spotifyAppNotInstalled
    case invalidResponse
    case authorizationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please login to Spotify first"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "Spotify API error: \(message)"
        case .spotifyAppNotInstalled:
            return "Spotify app is not installed"
        case .invalidResponse:
            return "Invalid response from Spotify"
        case .authorizationFailed:
            return "Spotify authorization failed"
        }
    }
}

// MARK: - Mock Data for Development

extension SpotifyPlaylist {
    static let mockData: [SpotifyPlaylist] = [
        SpotifyPlaylist(
            id: "mock1",
            name: "My Favorites",
            description: "My favorite songs collection",
            images: [
                SpotifyImage(url: "https://via.placeholder.com/300x300?text=Favorites", height: 300, width: 300)
            ],
            owner: SpotifyOwner(id: "user1", displayName: "Me"),
            tracks: SpotifyPlaylistTracksInfo(href: "", total: 25),
            uri: "spotify:playlist:mock1",
            isPublic: false
        ),
        SpotifyPlaylist(
            id: "mock2", 
            name: "Rock Classics",
            description: "Best rock songs of all time",
            images: [
                SpotifyImage(url: "https://via.placeholder.com/300x300?text=Rock", height: 300, width: 300)
            ],
            owner: SpotifyOwner(id: "user1", displayName: "Me"),
            tracks: SpotifyPlaylistTracksInfo(href: "", total: 40),
            uri: "spotify:playlist:mock2",
            isPublic: true
        ),
        SpotifyPlaylist(
            id: "mock3",
            name: "Chill Vibes",
            description: "Relaxing music for work and study",
            images: [
                SpotifyImage(url: "https://via.placeholder.com/300x300?text=Chill", height: 300, width: 300)
            ],
            owner: SpotifyOwner(id: "user1", displayName: "Me"),
            tracks: SpotifyPlaylistTracksInfo(href: "", total: 60),
            uri: "spotify:playlist:mock3",
            isPublic: false
        )
    ]
}

extension SpotifyTrack {
    static let mockTrack = SpotifyTrack(
        id: "mock_track_1",
        name: "Sample Song",
        artists: [
            SpotifyArtist(id: "mock_artist_1", name: "Sample Artist", images: nil)
        ],
        album: SpotifyAlbum(
            id: "mock_album_1",
            name: "Sample Album",
            images: [
                SpotifyImage(url: "https://via.placeholder.com/300x300?text=Album", height: 300, width: 300)
            ],
            artists: [
                SpotifyArtist(id: "mock_artist_1", name: "Sample Artist", images: nil)
            ],
            releaseDate: "2023-01-01"
        ),
        durationMs: 180000, // 3 minutes
        explicit: false,
        previewUrl: nil,
        uri: "spotify:track:mock_track_1"
    )
}