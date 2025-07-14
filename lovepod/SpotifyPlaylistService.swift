// lovepod/SpotifyPlaylistService.swift
// Spotify 播放列表服务，使用 Web API Token 获取播放列表数据
// 专门负责数据读取功能，与播放控制分离

import Foundation
import SwiftUI
import Combine

// MARK: - Spotify Playlist Service
class SpotifyPlaylistService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var playlists: [SpotifyPlaylist] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Dependencies
    private weak var tokenManager: SpotifyTokenManager?
    private weak var webAPIManager: SpotifyWebAPIManager?
    private weak var appState: AppState?
    
    // MARK: - Initialization
    init(tokenManager: SpotifyTokenManager, webAPIManager: SpotifyWebAPIManager) {
        self.tokenManager = tokenManager
        self.webAPIManager = webAPIManager
    }
    
    // MARK: - Configuration
    @MainActor
    func configure(with appState: AppState) {
        self.appState = appState
        print("🔧 SpotifyPlaylistService: Configured with AppState \(appState.instanceID)")
    }
    
    // MARK: - Playlist Fetching
    func fetchPlaylists() async throws {
        print("🎵 Starting playlist fetch...")
        
        await MainActor.run { 
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
                print("🎵 Playlist fetch completed, isLoading = false")
            }
        }
        
        // 检查是否有数据读取权限
        guard let tokenManager = tokenManager,
              tokenManager.canReadData else {
            print("❌ No data read permissions")
            throw SpotifyPlaylistError.insufficientPermissions
        }
        
        // 获取适当的 token
        guard let token = tokenManager.getAppropriateToken(for: .dataAccess) else {
            print("❌ No valid token available")
            throw SpotifyPlaylistError.noValidToken
        }
        
        print("✅ Token available, proceeding with API call")
        try await performPlaylistsAPICall(token: token)
    }
    
    private func performPlaylistsAPICall(token: String) async throws {
        let urlString = "https://api.spotify.com/v1/me/playlists?limit=50"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid API URL: \(urlString)")
            throw SpotifyPlaylistError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        print("🔍 Playlist API Request:")
        print("  URL: \(urlString)")
        print("  Token (first 20 chars): \(String(token.prefix(20)))...")
        print("  Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("  Timeout: \(request.timeoutInterval)s")
        
        print("📡 Sending API request...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("✅ API request completed successfully")
            print("  Response data size: \(data.count) bytes")
            
            // 处理响应
            try await handleAPIResponse(data: data, response: response)
        } catch {
            print("❌ API request failed with error: \(error)")
            throw SpotifyPlaylistError.apiError("Network request failed: \(error.localizedDescription)")
        }
    }
    
    private func handleAPIResponse(data: Data, response: URLResponse) async throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw SpotifyPlaylistError.invalidResponse
        }
        
        print("📡 Playlist API Response:")
        print("  Status Code: \(httpResponse.statusCode)")
        print("  Headers: \(httpResponse.allHeaderFields)")
        
        // 打印响应体（截取前1000字符以避免过长）
        if let responseString = String(data: data, encoding: .utf8) {
            let truncated = responseString.count > 1000 ? String(responseString.prefix(1000)) + "..." : responseString
            print("  Response Body: \(truncated)")
        }
        
        // 处理不同的状态码
        switch httpResponse.statusCode {
        case 200:
            print("✅ API call successful, parsing response...")
            try await parsePlaylistsResponse(data: data)
            
        case 401:
            print("❌ 401 Unauthorized - Token may be expired or invalid")
            throw SpotifyPlaylistError.unauthorized
            
        case 403:
            print("❌ 403 Forbidden - Insufficient permissions")
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ Response: \(responseBody)")
            throw SpotifyPlaylistError.insufficientPermissions
            
        case 429:
            print("❌ 429 Rate Limited")
            throw SpotifyPlaylistError.rateLimited
            
        default:
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ API Error: HTTP \(httpResponse.statusCode)")
            print("❌ Response: \(responseBody)")
            throw SpotifyPlaylistError.apiError("HTTP \(httpResponse.statusCode): \(responseBody)")
        }
    }
    
    private func parsePlaylistsResponse(data: Data) async throws {
        print("🔄 Parsing playlists response...")
        let decoder = JSONDecoder()
        
        do {
            let playlistsResponse = try decoder.decode(SpotifyPlaylistsResponse.self, from: data)
            print("✅ Successfully decoded response: \(playlistsResponse.items.count) playlists found")
            
            await MainActor.run {
                self.playlists = playlistsResponse.items
                self.errorMessage = nil
                
                print("✅ Successfully updated playlists in main thread")
                print("📊 Playlist summary:")
                print("  Total: \(playlistsResponse.items.count)")
                print("  Limit: \(playlistsResponse.limit)")
                print("  Offset: \(playlistsResponse.offset)")
                
                if playlistsResponse.items.isEmpty {
                    print("⚠️ No playlists found - user may have no playlists or insufficient permissions")
                } else {
                    print("📋 Playlists details:")
                    for (index, playlist) in playlistsResponse.items.enumerated() {
                        let imageStatus = playlist.imageURL != nil ? "has image" : "no image"
                        let imageURL = playlist.imageURL ?? "nil"
                        print("  \(index + 1). \(playlist.name) (\(playlist.tracks.total) tracks, \(imageStatus))")
                        print("      Image URL: \(imageURL)")
                    }
                }
                
                // 直接更新 AppState 数据，替换 NotificationCenter
                self.appState?.updateSpotifyPlaylists(self.playlists)
                print("🔄 Directly updated AppState with \(self.playlists.count) playlists")
            }
        } catch {
            print("❌ Failed to decode playlists response: \(error)")
            print("❌ JSON decoding error details: \(error.localizedDescription)")
            if let data = String(data: data, encoding: .utf8) {
                print("❌ Raw response data: \(data.prefix(500))...")
            }
            throw SpotifyPlaylistError.decodingError(error)
        }
    }
    
    // MARK: - User Library
    func fetchUserSavedTracks() async throws {
        // 类似的实现，获取用户保存的音乐
        print("🎵 Fetching user saved tracks...")
        // TODO: 实现用户保存音乐的获取
    }
    
    func fetchUserAlbums() async throws {
        // 获取用户保存的专辑
        print("💿 Fetching user albums...")
        // TODO: 实现用户专辑的获取
    }
    
    // MARK: - Error Handling
    private func setError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            print("❌ Playlist Service Error: \(message)")
        }
    }
    
    // MARK: - Convenience Methods
    func refreshPlaylists() {
        Task {
            do {
                try await fetchPlaylists()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Spotify Playlist Error
enum SpotifyPlaylistError: LocalizedError {
    case insufficientPermissions
    case noValidToken
    case tokenExpired
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case apiError(String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .insufficientPermissions:
            return "Insufficient permissions to read playlists. Please authorize with Web API."
        case .noValidToken:
            return "No valid token available for API access."
        case .tokenExpired:
            return "Access token has expired. Please re-authenticate."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid response from Spotify API."
        case .unauthorized:
            return "Unauthorized access. Please re-authenticate."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .apiError(let message):
            return "API Error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}