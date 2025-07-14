// lovepodApp.swift
// 应用入口点，处理混合 Spotify 授权回调和应用生命周期
// 集成 iOS SDK 和 Web API 双重授权系统

import SwiftUI

@main
struct lovepodApp: App {
    // 使用 AppState 单例
    private let appState = AppState.shared
    
    // Spotify 服务管理器
    @StateObject private var spotifyService = SpotifyService()
    @StateObject private var webAPIManager = SpotifyWebAPIManager()
    @StateObject private var tokenManager = SpotifyTokenManager()
    @StateObject private var playlistService: SpotifyPlaylistService
    
    init() {
        print("🚀 LovePod App initializing...")
        print("🔵 Using AppState singleton: \(AppState.shared.instanceID)")
        
        // 创建播放列表服务时需要依赖注入
        let webAPI = SpotifyWebAPIManager()
        let tokens = SpotifyTokenManager()
        let playlist = SpotifyPlaylistService(tokenManager: tokens, webAPIManager: webAPI)
        
        _webAPIManager = StateObject(wrappedValue: webAPI)
        _tokenManager = StateObject(wrappedValue: tokens)
        _playlistService = StateObject(wrappedValue: playlist)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(spotifyService)
                .environmentObject(webAPIManager)
                .environmentObject(tokenManager)
                .environmentObject(playlistService)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onAppear {
                    setupManagers()
                    setupAppStateConnections()
                }
        }
    }
    
    // MARK: - Setup
    private func setupManagers() {
        // 注册管理器到 Token Manager
        tokenManager.registerManagers(iOSSDK: spotifyService, webAPI: webAPIManager)
        print("🔧 Spotify managers setup completed")
    }
    
    private func setupAppStateConnections() {
        // 关键：建立服务与 AppState 的连接
        appState.setSpotifyService(spotifyService)
        appState.setPlaylistService(playlistService)
        appState.setWebAPIManager(webAPIManager)
        
        print("✅ AppState connections established")
        print("🔗 SpotifyService connected to AppState: \(appState.instanceID)")
        print("🔗 PlaylistService connected to AppState: \(appState.instanceID)")
        print("🔗 WebAPIManager connected to AppState: \(appState.instanceID)")
    }
    
    // MARK: - URL Handling
    private func handleIncomingURL(_ url: URL) {
        print("📱 Received URL: \(url)")
        
        // 使用 Token Manager 统一处理回调
        if url.scheme == "lovepod" {
            let success = tokenManager.handleCallback(url: url)
            print(success ? "✅ Spotify authorization handled successfully" : "❌ Failed to handle Spotify authorization")
        }
    }
}

// MARK: - Scene Delegate for UIKit Integration (如果需要)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Scene 连接时的处理
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        // 通过通知中心传递 URL 到 SwiftUI 应用
        NotificationCenter.default.post(
            name: NSNotification.Name("SpotifyAuthorizationURL"),
            object: url
        )
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // 应用变为活跃状态时重连 Spotify
        NotificationCenter.default.post(name: NSNotification.Name("AppDidBecomeActive"), object: nil)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // 应用将要失去活跃状态时断开 Spotify 连接
        NotificationCenter.default.post(name: NSNotification.Name("AppWillResignActive"), object: nil)
    }
}
