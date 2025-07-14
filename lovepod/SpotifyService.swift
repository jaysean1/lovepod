// lovepod/SpotifyService.swift
// Spotify 服务层，支持条件编译 - 可以在有或没有 SDK 的情况下工作
// 提供授权、播放控制、数据获取等完整功能

import Foundation
import SwiftUI
import Combine

// MARK: - Conditional Spotify SDK Import
#if canImport(SpotifyiOS)
import SpotifyiOS
#endif

// MARK: - Spotify Service Protocol
protocol SpotifyServiceProtocol: ObservableObject {
    var isConnected: Bool { get }
    var isAuthenticated: Bool { get }
    var currentTrack: SpotifyTrack? { get }
    var currentPlayerState: SpotifyPlayerState? { get }
    var playlists: [SpotifyPlaylist] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func authorize()
    func connect()
    func disconnect()
    func fetchPlaylists() async throws
    func play(uri: String?) async throws
    func pause() async throws
    func resume() async throws
    func skipToNext() async throws
    func skipToPrevious() async throws
    func seek(to position: TimeInterval) async throws
}

// MARK: - Spotify Service Implementation
class SpotifyService: NSObject, SpotifyServiceProtocol {
    
    // MARK: - Configuration
    private let clientID = "88e54f88f52c4f66a20eab13bdc10f07" // Spotify Client ID
    private let redirectURI = "lovepod://spotify-login-callback"
    
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var currentTrack: SpotifyTrack? = nil
    @Published var currentPlayerState: SpotifyPlayerState? = nil
    @Published var playlists: [SpotifyPlaylist] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    #if canImport(SpotifyiOS)
    private var appRemote: SPTAppRemote?
    private var configuration: SPTConfiguration?
    #endif
    
    private var accessToken: String? {
        didSet {
            isAuthenticated = accessToken != nil
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupService()
    }
    
    // MARK: - Setup
    private func setupService() {
        #if canImport(SpotifyiOS)
        setupSpotifySDK()
        #else
        print("⚠️ Spotify iOS SDK not available - running in mock mode")
        setupMockMode()
        #endif
    }
    
    #if canImport(SpotifyiOS)
    private func setupSpotifySDK() {
        guard let redirectURL = URL(string: redirectURI) else {
            setError("Invalid redirect URI")
            return
        }
        
        configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
        configuration?.playURI = ""
        
        // 注意：iOS SDK 的权限可能通过不同方式配置
        // 如果 scopes 属性不存在，权限可能在 Developer Dashboard 中设置
        
        appRemote = SPTAppRemote(configuration: configuration!, logLevel: .debug)
        appRemote?.delegate = self
        appRemote?.playerAPI?.delegate = self
        
        print("✅ Spotify iOS SDK configured")
    }
    #endif
    
    private func setupMockMode() {
        // 模拟模式：延迟加载模拟数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.playlists = SpotifyPlaylist.mockData
            print("🧪 Mock mode: loaded sample playlists")
        }
    }
    
    // MARK: - Public Methods
    
    func authorize() {
        #if canImport(SpotifyiOS)
        guard let appRemote = appRemote else {
            setError("Spotify service not configured")
            return
        }
        print("🎵 Starting Spotify authorization...")
        appRemote.authorizeAndPlayURI("")
        #else
        print("🧪 Mock: Authorizing...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.accessToken = "mock_token"
            self.isConnected = true
            print("✅ Mock authorization successful")
        }
        #endif
    }
    
    func connect() {
        #if canImport(SpotifyiOS)
        guard let appRemote = appRemote, accessToken != nil else {
            setError("Cannot connect: no access token")
            return
        }
        print("🔗 Connecting to Spotify...")
        appRemote.connect()
        #else
        print("🧪 Mock: Connecting...")
        isConnected = true
        #endif
    }
    
    func disconnect() {
        #if canImport(SpotifyiOS)
        if let appRemote = appRemote, appRemote.isConnected {
            appRemote.disconnect()
        }
        #endif
        isConnected = false
        print("🔌 Disconnected")
    }
    
    func fetchPlaylists() async throws {
        await MainActor.run { isLoading = true }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        #if canImport(SpotifyiOS)
        // 真实的 API 调用
        let urlString = "https://api.spotify.com/v1/me/playlists?limit=50"
        guard let url = URL(string: urlString) else {
            throw SpotifyError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("🔍 API Request:")
        print("  URL: \(urlString)")
        print("  Token (first 20 chars): \(String(token.prefix(20)))...")
        print("  Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 详细的响应日志
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 API Response:")
            print("  Status Code: \(httpResponse.statusCode)")
            print("  Headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("  Response Body: \(responseString)")
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ API Error: HTTP \(statusCode)")
            print("❌ Response: \(responseBody)")
            throw SpotifyError.apiError("HTTP \(statusCode): \(responseBody)")
        }
        
        let decoder = JSONDecoder()
        let playlistsResponse = try decoder.decode(SpotifyPlaylistsResponse.self, from: data)
        
        await MainActor.run {
            self.playlists = playlistsResponse.items
            print("✅ Fetched \(playlistsResponse.items.count) playlists")
            if playlistsResponse.items.isEmpty {
                print("⚠️ No playlists found - user may have no playlists or insufficient permissions")
            } else {
                print("📋 Playlists:")
                for (index, playlist) in playlistsResponse.items.enumerated() {
                    print("  \(index + 1). \(playlist.name) (tracks: \(playlist.tracks.total))")
                }
            }
        }
        #else
        // 模拟 API 调用
        try await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            self.playlists = SpotifyPlaylist.mockData
            print("🧪 Mock: Fetched \(SpotifyPlaylist.mockData.count) mock playlists")
        }
        #endif
    }
    
    func play(uri: String?) async throws {
        #if canImport(SpotifyiOS)
        guard let appRemote = appRemote, appRemote.isConnected else {
            print("❌ Cannot play: Not connected to Spotify app")
            throw SpotifyError.notAuthenticated
        }
        
        if let uri = uri {
            print("▶️ Attempting to play URI: \(uri)")
        } else {
            print("▶️ Attempting to resume playback...")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            if let uri = uri {
                appRemote.playerAPI?.play(uri) { _, error in
                    if let error = error {
                        print("❌ Failed to play URI: \(error.localizedDescription)")
                        continuation.resume(throwing: SpotifyError.apiError(error.localizedDescription))
                    } else {
                        print("✅ Successfully started playing: \(uri)")
                        continuation.resume()
                    }
                }
            } else {
                appRemote.playerAPI?.resume { _, error in
                    if let error = error {
                        print("❌ Failed to resume: \(error.localizedDescription)")
                        continuation.resume(throwing: SpotifyError.apiError(error.localizedDescription))
                    } else {
                        print("✅ Successfully resumed playback")
                        continuation.resume()
                    }
                }
            }
        }
        #else
        print("🧪 Mock: Playing \(uri ?? "current track")")
        await MainActor.run {
            self.currentTrack = SpotifyTrack.mockTrack
        }
        #endif
    }
    
    func pause() async throws {
        #if canImport(SpotifyiOS)
        guard let appRemote = appRemote, appRemote.isConnected else {
            print("❌ Cannot pause: Not connected to Spotify app")
            throw SpotifyError.notAuthenticated
        }
        
        print("⏸️ Attempting to pause playback...")
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.pause { _, error in
                if let error = error {
                    print("❌ Failed to pause: \(error.localizedDescription)")
                    continuation.resume(throwing: SpotifyError.apiError(error.localizedDescription))
                } else {
                    print("✅ Successfully paused playback")
                    continuation.resume()
                }
            }
        }
        #else
        print("🧪 Mock: Paused")
        #endif
    }
    
    func resume() async throws {
        try await play(uri: nil)
    }
    
    func skipToNext() async throws {
        #if canImport(SpotifyiOS)
        guard let appRemote = appRemote, appRemote.isConnected else {
            print("❌ Cannot skip to next: Not connected to Spotify app")
            throw SpotifyError.notAuthenticated
        }
        
        print("⏭️ Attempting to skip to next track...")
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.skip(toNext: { _, error in
                if let error = error {
                    print("❌ Failed to skip to next: \(error.localizedDescription)")
                    continuation.resume(throwing: SpotifyError.apiError(error.localizedDescription))
                } else {
                    print("✅ Successfully skipped to next track")
                    continuation.resume()
                }
            })
        }
        #else
        print("🧪 Mock: Next track")
        #endif
    }
    
    func skipToPrevious() async throws {
        #if canImport(SpotifyiOS)
        guard let appRemote = appRemote, appRemote.isConnected else {
            print("❌ Cannot skip to previous: Not connected to Spotify app")
            throw SpotifyError.notAuthenticated
        }
        
        print("⏮️ Attempting to skip to previous track...")
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.skip(toPrevious: { _, error in
                if let error = error {
                    print("❌ Failed to skip to previous: \(error.localizedDescription)")
                    continuation.resume(throwing: SpotifyError.apiError(error.localizedDescription))
                } else {
                    print("✅ Successfully skipped to previous track")
                    continuation.resume()
                }
            })
        }
        #else
        print("🧪 Mock: Previous track")
        #endif
    }
    
    func seek(to position: TimeInterval) async throws {
#if canImport(SpotifyiOS)
        guard let appRemote = appRemote, appRemote.isConnected else {
            throw SpotifyError.notAuthenticated
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.seek(toPosition: Int(position * 1000)) { _, error in
                if let error = error {
                    continuation.resume(throwing: SpotifyError.apiError(error.localizedDescription))
                } else {
                    print("🔍 Seeked to \(position)s")
                    continuation.resume()
                }
            }
        }
#else
        print("🧪 Mock: Seeked to \(position)s")
#endif
    }
    
    func refreshCurrentPlaybackPosition() async {
#if canImport(SpotifyiOS)
        guard let appRemote = appRemote, appRemote.isConnected else {
            return
        }
        
        appRemote.playerAPI?.getPlayerState { [weak self] playerState, error in
            guard let self = self,
                  let playerState = playerState as? SPTAppRemotePlayerState,
                  error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                self.currentTrack = self.convertTrack(from: playerState.track)
                self.currentPlayerState = SpotifyPlayerState(
                    track: self.currentTrack,
                    isPaused: playerState.isPaused,
                    playbackPosition: TimeInterval(playerState.playbackPosition) / 1000.0,
                    playbackSpeed: playerState.playbackSpeed,
                    playbackRestrictions: [:]
                )
            }
        }
#else
        // 模拟模式下不需要刷新
        print("🧪 Mock: Refreshing playback position")
#endif
    }    
    // MARK: - Token Validation
    private func validateTokenScopes() async {
        guard let token = accessToken else {
            print("❌ No access token to validate")
            return
        }
        
        do {
            let urlString = "https://api.spotify.com/v1/me"
            guard let url = URL(string: urlString) else { return }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Token Validation:")
                print("  Status Code: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("  User Info: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    print("✅ Access token is valid")
                } else {
                    print("❌ Access token validation failed")
                }
            }
        } catch {
            print("❌ Token validation error: \(error)")
        }
    }
    
    // MARK: - Authorization Handling
    func handleAuthorizationCallback(url: URL) -> Bool {
        #if canImport(SpotifyiOS)
        guard let appRemote = appRemote else { return false }
        
        let parameters = appRemote.authorizationParameters(from: url)
        
        if let accessToken = parameters?[SPTAppRemoteAccessTokenKey] {
            self.accessToken = accessToken
            appRemote.connectionParameters.accessToken = accessToken
            print("✅ Authorization successful")
            
            // 验证 token 权限
            Task {
                await validateTokenScopes()
            }
            
            connect()
            return true
        } else if let error = parameters?[SPTAppRemoteErrorDescriptionKey] {
            setError("Authorization failed: \(error)")
            return false
        }
        #endif
        return false
    }
    
    // MARK: - Helper Methods
    private func setError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            print("❌ \(message)")
        }
    }
    
    var isSpotifyAppInstalled: Bool {
        guard let url = URL(string: "spotify:") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

// MARK: - Spotify SDK Delegates (only when SDK is available)
#if canImport(SpotifyiOS)
extension SpotifyService: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("✅ Spotify connected")
        DispatchQueue.main.async {
            self.isConnected = true
            self.errorMessage = nil
        }
        
        // 订阅播放状态
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { _, error in
            if let error = error {
                print("❌ Failed to subscribe: \(error)")
            }
        })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("🔌 Spotify disconnected")
        DispatchQueue.main.async {
            self.isConnected = false
            if let error = error {
                self.setError("Disconnected: \(error.localizedDescription)")
            }
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("❌ Connection failed")
        DispatchQueue.main.async {
            self.isConnected = false
            if let error = error {
                self.setError("Connection failed: \(error.localizedDescription)")
            }
        }
    }
}

extension SpotifyService: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("🎵 Player state changed: \(playerState.track.name)")
        
        DispatchQueue.main.async {
            // 将 SPTAppRemoteTrack 转换为 SpotifyTrack
            self.currentTrack = self.convertTrack(from: playerState.track)
            
            self.currentPlayerState = SpotifyPlayerState(
                track: self.currentTrack,
                isPaused: playerState.isPaused,
                playbackPosition: TimeInterval(playerState.playbackPosition) / 1000.0,
                playbackSpeed: playerState.playbackSpeed,
                playbackRestrictions: [:]
            )
        }
    }
    
    private func convertTrack(from remoteTrack: SPTAppRemoteTrack) -> SpotifyTrack {
        return SpotifyTrack(
            id: remoteTrack.uri.replacingOccurrences(of: "spotify:track:", with: ""),
            name: remoteTrack.name,
            artists: [SpotifyArtist(id: "", name: remoteTrack.artist.name, images: nil)],
            album: SpotifyAlbum(
                id: "",
                name: remoteTrack.album.name,
                images: [], // SDK 不直接提供图片 URL，需要通过 Web API 获取
                artists: [SpotifyArtist(id: "", name: remoteTrack.artist.name, images: nil)],
                releaseDate: nil
            ),
            durationMs: Int(remoteTrack.duration),
            explicit: false,
            previewUrl: nil,
            uri: remoteTrack.uri
        )
    }
}
#endif