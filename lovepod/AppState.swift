// lovepod/AppState.swift
// 应用状态管理类，使用ObservableObject来管理应用的全局状态
// 包含页面导航、选中状态、播放状态等核心应用状态

import SwiftUI
import Combine
import SpotifyiOS

// MARK: - Navigation States
enum NavigationPage: CaseIterable {
    case home
    case playlist
    case nowPlaying
    case settings
    case themes
    case upgrade
    case user
}

enum HomeMenuItem: Int, CaseIterable {
    case playlist = 0
    case settings = 1
    case user = 2
    
    var title: String {
        switch self {
        case .playlist: return "Playlist"
        case .settings: return "Settings"
        case .user: return "User"
        }
    }
    
    var icon: String {
        switch self {
        case .playlist: return DesignSystem.Icons.playlist
        case .settings: return DesignSystem.Icons.settings
        case .user: return DesignSystem.Icons.user
        }
    }
    
    var navigationPage: NavigationPage {
        switch self {
        case .playlist: return .playlist
        case .settings: return .settings
        case .user: return .user
        }
    }
}

enum SettingsMenuItem: Int, CaseIterable {
    case themes = 0
    case upgrade = 1
    case about = 2
    case privacy = 3
    
    var title: String {
        switch self {
        case .themes: return "Themes"
        case .upgrade: return "Upgrade"
        case .about: return "About"
        case .privacy: return "Privacy"
        }
    }
    
    var icon: String {
        switch self {
        case .themes: return "paintbrush.fill"
        case .upgrade: return "star.fill"
        case .about: return "info.circle.fill"
        case .privacy: return "lock.fill"
        }
    }
    
    var navigationPage: NavigationPage? {
        switch self {
        case .themes: return .themes
        case .upgrade: return .upgrade
        case .about: return nil
        case .privacy: return nil
        }
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AppState()
    
    // 实例唯一标识符，用于调试
    lazy var instanceID: ObjectIdentifier = ObjectIdentifier(self)
    
    // MARK: - Navigation State
    @Published var currentPage: NavigationPage = .home
    @Published var navigationStack: [NavigationPage] = [.home]
    
    // MARK: - Menu Selection State
    @Published var selectedHomeMenuItem: Int = 0
    @Published var selectedSettingsMenuItem: Int = 0
    @Published var selectedPlaylistIndex: Int = 0
    
    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Music State (integrated with Spotify)
    @Published var isPlaying: Bool = false
    @Published var currentTrackTitle: String = "Track Title"
    @Published var currentArtist: String = "Artist Name"
    @Published var currentAlbum: String = "Album Name"
    @Published var playbackProgress: Double = 0.0
    @Published var duration: TimeInterval = 180.0
    @Published var currentTime: TimeInterval = 0.0
    @Published var isUserSeekingProgress: Bool = false
    
    // MARK: - Spotify Integration
    @Published var spotifyPlaylists: [SpotifyPlaylist] = []
    @Published var currentSpotifyTrack: SpotifyTrack? = nil
    @Published var isSpotifyAuthenticated: Bool = false
    @Published var isSpotifyConnected: Bool = false
    @Published var currentPlaylistURI: String? = nil  // 跟踪当前播放的playlist URI
    @Published var showReconnectPrompt: Bool = false  // 显示重连提示
    
    // MARK: - Playlist State (backward compatibility)
    @Published var playlists: [PlaylistModel] = PlaylistModel.mockData
    
    // MARK: - Spotify Services
    private(set) var spotifyService: SpotifyService? = nil
    private var playlistService: SpotifyPlaylistService? = nil
    private var webAPIManager: SpotifyWebAPIManager? = nil
    
    // MARK: - Theme State
    @Published var selectedTheme: String = "Classic"
    
    private init() {
        print("🔵 AppState singleton created")
    }
    
    // MARK: - Spotify Service Integration
    func setSpotifyService(_ service: SpotifyService) {
        self.spotifyService = service
        
        // 监听 Spotify 状态变化
        service.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSpotifyAuthenticated)
        
        service.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isSpotifyConnected = isConnected
                // 当连接断开时，如果之前是已连接状态，显示重连提示
                if !isConnected && self?.isSpotifyAuthenticated == true {
                    self?.showReconnectPrompt = true
                    print("🔌 Spotify disconnected - showing reconnect prompt")
                } else if isConnected {
                    // 连接成功时隐藏重连提示
                    self?.showReconnectPrompt = false
                    print("✅ Spotify connected - hiding reconnect prompt")
                }
            }
            .store(in: &cancellables)
        
        service.$currentTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] track in
                self?.updateCurrentTrack(from: track)
            }
            .store(in: &cancellables)
        
        service.$currentPlayerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playerState in
                self?.updatePlayerState(from: playerState)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Playlist Service Integration
    func setPlaylistService(_ service: SpotifyPlaylistService) {
        self.playlistService = service
        
        // 配置服务使用当前 AppState 实例
        service.configure(with: self)
        
        print("✅ AppState (\(instanceID)): Configured playlist service")
    }
    
    // MARK: - Web API Manager Integration
    func setWebAPIManager(_ manager: SpotifyWebAPIManager) {
        self.webAPIManager = manager
        print("✅ AppState: Configured Web API manager")
    }
    
    // MARK: - Data Update Methods
    func updateSpotifyPlaylists(_ playlists: [SpotifyPlaylist]) {
        print("📊 AppState (\(instanceID)): Updating playlists from \(spotifyPlaylists.count) to \(playlists.count)")
        
        self.spotifyPlaylists = playlists
        
        // 验证更新结果
        print("✅ AppState (\(instanceID)): Successfully updated to \(spotifyPlaylists.count) playlists")
        if let firstPlaylist = spotifyPlaylists.first {
            print("📋 First playlist: \(firstPlaylist.name) (\(firstPlaylist.tracks.total) tracks)")
            print("🖼️ First playlist image URL: \(firstPlaylist.imageURL ?? "nil")")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateCurrentTrack(from spotifyTrack: SpotifyTrack?) {
        guard let track = spotifyTrack else { return }
        
        currentSpotifyTrack = track
        currentTrackTitle = track.name
        currentArtist = track.primaryArtistName
        currentAlbum = track.album.name
        duration = TimeInterval(track.durationMs ?? 180000) / 1000.0
    }
    
    private func updatePlayerState(from playerState: SpotifyPlayerState?) {
        guard let state = playerState else { return }
        
        isPlaying = state.isPlaying
        
        // 只有在用户不手动控制进度时才更新进度
        if !isUserSeekingProgress {
            currentTime = state.playbackPosition
            playbackProgress = duration > 0 ? state.playbackPosition / duration : 0.0
        }
    }
    
    // MARK: - Navigation Methods
    func navigateTo(_ page: NavigationPage) {
        currentPage = page
        navigationStack.append(page)
    }
    
    func navigateBack() {
        if navigationStack.count > 1 {
            navigationStack.removeLast()
            currentPage = navigationStack.last ?? .home
        }
    }
    
    func navigateToHome() {
        currentPage = .home
        navigationStack = [.home]
    }
    
    // MARK: - Menu Selection Methods
    func selectHomeMenuItem(_ index: Int) {
        selectedHomeMenuItem = index
        
        if let item = HomeMenuItem(rawValue: index) {
            navigateTo(item.navigationPage)
        }
    }
    
    func selectSettingsMenuItem(_ index: Int) {
        selectedSettingsMenuItem = index
        
        if let item = SettingsMenuItem(rawValue: index),
           let page = item.navigationPage {
            navigateTo(page)
        }
    }
    
    // MARK: - Playlist Methods
    func selectPlaylist(_ index: Int) {
        // 实现无边界循环选择逻辑
        let playlistCount = !spotifyPlaylists.isEmpty ? spotifyPlaylists.count : playlists.count
        guard playlistCount > 0 else { return }
        
        // 计算有效的索引（保持在边界内）
        let validIndex: Int
        if index >= playlistCount {
            validIndex = playlistCount - 1  // 保持在最后一个
        } else if index < 0 {
            validIndex = 0  // 保持在第一个
        } else {
            validIndex = index
        }
        
        selectedPlaylistIndex = validIndex
        
        // 根据是否有 Spotify 播放列表来决定播放逻辑
        if !spotifyPlaylists.isEmpty && validIndex < spotifyPlaylists.count {
            startPlayingSpotifyPlaylist(at: validIndex)
        } else if validIndex < playlists.count {
            startPlayingPlaylist(at: validIndex)
        }
    }
    
    func startPlayingPlaylist(at index: Int) {
        guard index < playlists.count else { return }
        
        let playlist = playlists[index]
        // 使用模拟数据进行播放
        currentTrackTitle = playlist.tracks.first?.title ?? "Unknown Track"
        currentArtist = playlist.tracks.first?.artist ?? "Unknown Artist"
        currentAlbum = playlist.name
        isPlaying = true
        
        navigateTo(.nowPlaying)
    }
    
    func startPlayingSpotifyPlaylist(at index: Int) {
        guard index < spotifyPlaylists.count else { return }
        
        let playlist = spotifyPlaylists[index]
        
        // 检查连接状态
        if !isSpotifyConnected {
            print("🔌 Spotify not connected, showing reconnect prompt")
            showReconnectPrompt = true
            return
        }
        
        // 异步检查是否是当前正在播放的playlist
        Task {
            let isCurrentlyPlaying = await isCurrentlyPlayingPlaylist(playlist: playlist)
            
            await MainActor.run {
                if isCurrentlyPlaying {
                    print("📱 Same playlist already playing, navigating to Now Playing")
                    // 如果选中的是当前正在播放的playlist，直接进入Now Playing界面
                    self.navigateTo(.nowPlaying)
                    return
                }
                
                print("🎵 Different playlist or not playing, starting new playback")
                // 如果有其他播放内容正在播放，先停止
                if self.isPlaying {
                    print("⏹️ Stopping current playback before switching playlist")
                }
            }
            
            // 触发 Spotify 播放新的playlist
            do {
                print("▶️ Starting playback for playlist: \(playlist.name)")
                try await spotifyService?.play(uri: playlist.uri)
                await MainActor.run {
                    print("✅ Successfully started playlist, navigating to Now Playing")
                    // 更新当前播放的playlist URI
                    self.currentPlaylistURI = playlist.uri
                    self.navigateTo(.nowPlaying)
                }
            } catch {
                await MainActor.run {
                    // 检查是否是连接相关错误
                    if error.localizedDescription.contains("not connected") || error.localizedDescription.contains("connection") {
                        self.showReconnectPrompt = true
                    } else {
                        self.showError("Failed to play playlist: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // 检查当前是否正在播放指定的playlist
    private func isCurrentlyPlayingPlaylist(playlist: SpotifyPlaylist) async -> Bool {
        print("🔍 Checking if playlist \(playlist.name) is currently playing...")
        
        // 优先使用本地状态检查 - 避免不必要的API调用
        if let currentPlaylistURI = currentPlaylistURI {
            let isCurrentPlaylist = currentPlaylistURI == playlist.uri
            print("📱 Local state check: current=\(currentPlaylistURI), target=\(playlist.uri)")
            print("📊 Is same playlist (local): \(isCurrentPlaylist)")
            
            if isCurrentPlaylist {
                print("✅ Matched current playlist via local state - avoiding API call")
                return true
            }
        }
        
        // 如果本地状态不匹配或为空，尝试通过Web API验证
        guard let webAPIManager = webAPIManager else {
            print("⚠️ No Web API manager available, using fallback logic")
            return isPlaying && currentSpotifyTrack != nil && currentPlaylistURI == playlist.uri
        }
        
        if let playbackContext = await webAPIManager.getCurrentPlaybackContext() {
            if let context = playbackContext.context {
                let isCurrentPlaylist = context.isPlaylist(withURI: playlist.uri)
                print("✅ Found active playback context via API")
                print("🎵 Current context: \(context.uri)")
                print("🎯 Target playlist: \(playlist.uri)")
                print("📊 Is same playlist (API): \(isCurrentPlaylist)")
                
                // 更新本地状态缓存
                if isCurrentPlaylist {
                    await MainActor.run {
                        self.currentPlaylistURI = playlist.uri
                    }
                }
                
                return isCurrentPlaylist
            } else {
                print("ℹ️ No context in playback (might be a single track)")
                return false
            }
        } else {
            print("ℹ️ No active playback session")
            return false
        }
    }
    
    // MARK: - Spotify Integration Methods
    func authenticateSpotify() {
        guard let service = spotifyService else { return }
        
        if !service.isSpotifyAppInstalled {
            showError("Please install Spotify app first")
            return
        }
        
        service.authorize()
    }
    
    func reconnectSpotify() {
        print("🔄 Reconnecting to Spotify using same flow as first connection...")
        
        // 隐藏重连提示
        showReconnectPrompt = false
        
        // 直接使用首次连接的逻辑
        authenticateSpotify()
    }
    
    func loadSpotifyPlaylists() {
        guard let service = playlistService else { return }
        
        Task {
            do {
                try await service.fetchPlaylists()
            } catch {
                showError("Failed to load playlists: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Music Control Methods
    func togglePlayPause() {
        print("🎮 Toggle play/pause requested (current state: \(isPlaying ? "playing" : "paused"))")
        
        guard let service = spotifyService else {
            print("🎮 No Spotify service, using mock mode")
            isPlaying.toggle()
            print("🎮 Mock: Toggled to \(isPlaying ? "playing" : "paused")")
            return
        }
        
        // 检查连接状态
        if !isSpotifyConnected {
            print("🔌 Spotify not connected, showing reconnect prompt")
            showReconnectPrompt = true
            return
        }
        
        print("🎮 Using Spotify service for playback control")
        
        Task {
            do {
                if isPlaying {
                    print("🎮 Attempting to pause...")
                    try await service.pause()
                    print("🎮 Pause command sent successfully")
                } else {
                    print("🎮 Attempting to resume...")
                    try await service.resume()
                    print("🎮 Resume command sent successfully")
                }
            } catch {
                print("❌ Playback control failed: \(error)")
                // 检查是否是连接相关错误
                if error.localizedDescription.contains("not connected") || error.localizedDescription.contains("connection") {
                    showReconnectPrompt = true
                } else {
                    showError("Playback control failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func nextTrack() {
        print("🎮 Next track requested")
        
        guard let service = spotifyService else {
            print("🎮 No Spotify service, using mock mode")
            playbackProgress = 0.0
            currentTime = 0.0
            print("🎮 Mock: Skipped to next track")
            return
        }
        
        // 检查连接状态
        if !isSpotifyConnected {
            print("🔌 Spotify not connected, showing reconnect prompt")
            showReconnectPrompt = true
            return
        }
        
        print("🎮 Using Spotify service to skip to next")
        
        Task {
            do {
                try await service.skipToNext()
                print("🎮 Skip to next command sent successfully")
            } catch {
                print("❌ Skip to next failed: \(error)")
                // 检查是否是连接相关错误
                if error.localizedDescription.contains("not connected") || error.localizedDescription.contains("connection") {
                    showReconnectPrompt = true
                } else {
                    showError("Skip to next failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func previousTrack() {
        print("🎮 Previous track requested")
        
        guard let service = spotifyService else {
            print("🎮 No Spotify service, using mock mode")
            playbackProgress = 0.0
            currentTime = 0.0
            print("🎮 Mock: Skipped to previous track")
            return
        }
        
        // 检查连接状态
        if !isSpotifyConnected {
            print("🔌 Spotify not connected, showing reconnect prompt")
            showReconnectPrompt = true
            return
        }
        
        print("🎮 Using Spotify service to skip to previous")
        
        Task {
            do {
                try await service.skipToPrevious()
                print("🎮 Skip to previous command sent successfully")
            } catch {
                print("❌ Skip to previous failed: \(error)")
                // 检查是否是连接相关错误
                if error.localizedDescription.contains("not connected") || error.localizedDescription.contains("connection") {
                    showReconnectPrompt = true
                } else {
                    showError("Skip to previous failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func seek(to progress: Double) {
        let newProgress = max(0.0, min(1.0, progress))
        playbackProgress = newProgress
        currentTime = duration * newProgress
        
        guard let service = spotifyService else { return }
        
        Task {
            do {
                print("🎵 Seeking to position: \(currentTime)s (progress: \(newProgress))")
                try await service.seek(to: currentTime)
                print("✅ Seek completed successfully")
                
                // Seek成功后，恢复自动进度更新
                await MainActor.run {
                    self.isUserSeekingProgress = false
                }
            } catch {
                print("❌ Seek failed: \(error)")
                showError("Seek failed: \(error.localizedDescription)")
                
                // 如果seek失败，也恢复自动进度更新
                await MainActor.run {
                    self.isUserSeekingProgress = false
                }
            }
        }
    }
    
    // MARK: - Progress Control Methods
    func setUserSeekingProgress(_ isSeeking: Bool) {
        isUserSeekingProgress = isSeeking
        print("🎵 User seeking progress: \(isSeeking)")
    }
    
    // MARK: - Error Handling
    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func clearError() {
        showError = false
        errorMessage = ""
    }
}

// MARK: - Playlist Model (Mock Data)
struct PlaylistModel: Identifiable {
    let id = UUID()
    let name: String
    let imageURL: String?
    let tracks: [TrackModel]
    
    static let mockData: [PlaylistModel] = [
        PlaylistModel(
            name: "My Favorites",
            imageURL: nil,
            tracks: [
                TrackModel(title: "Song 1", artist: "Artist 1"),
                TrackModel(title: "Song 2", artist: "Artist 2")
            ]
        ),
        PlaylistModel(
            name: "Rock Classics",
            imageURL: nil,
            tracks: [
                TrackModel(title: "Rock Song 1", artist: "Rock Artist 1"),
                TrackModel(title: "Rock Song 2", artist: "Rock Artist 2")
            ]
        ),
        PlaylistModel(
            name: "Chill Vibes",
            imageURL: nil,
            tracks: [
                TrackModel(title: "Chill Song 1", artist: "Chill Artist 1"),
                TrackModel(title: "Chill Song 2", artist: "Chill Artist 2")
            ]
        )
    ]
}

struct TrackModel: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
}