// lovepod/SpotifyTokenManager.swift
// 双 Token 管理系统，统一管理 iOS SDK 和 Web API 的 Token
// 实现智能 Token 选择策略和自动刷新机制

import Foundation
import SwiftUI
import Combine

// MARK: - Token Type Enum
enum SpotifyTokenType {
    case iOSSDK      // 播放控制 Token
    case webAPI      // 数据读取 Token
}

// MARK: - Spotify Token Manager
class SpotifyTokenManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isFullyAuthenticated: Bool = false
    @Published var authenticationStatus: AuthenticationStatus = .notAuthenticated
    
    // MARK: - Private Properties
    private var iOSSDKToken: String?
    private var webAPIToken: String?
    private var webAPITokenExpiry: Date?
    
    // 管理器引用
    private weak var iOSSDKManager: SpotifyService?
    private weak var webAPIManager: SpotifyWebAPIManager?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authentication Status
    enum AuthenticationStatus {
        case notAuthenticated
        case iOSSDKOnly        // 只有播放控制权限
        case webAPIOnly        // 只有数据读取权限
        case fullyAuthenticated // 两种权限都有
    }
    
    // MARK: - Initialization
    init() {
        setupStatusMonitoring()
    }
    
    // MARK: - Manager Registration
    func registerManagers(iOSSDK: SpotifyService, webAPI: SpotifyWebAPIManager) {
        self.iOSSDKManager = iOSSDK
        self.webAPIManager = webAPI
        
        // 监听 token 变化
        setupTokenMonitoring()
        setupNotificationListeners()
        updateAuthenticationStatus()
    }
    
    // MARK: - Token Monitoring
    private func setupTokenMonitoring() {
        // 监听 iOS SDK token 变化
        iOSSDKManager?.$isAuthenticated
            .sink { [weak self] _ in
                self?.updateTokens()
            }
            .store(in: &cancellables)
        
        // 监听 Web API token 变化
        webAPIManager?.$isAuthenticated
            .sink { [weak self] _ in
                self?.updateTokens()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notification Listeners
    private func setupNotificationListeners() {
        // 监听 Web API token 更新通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SpotifyWebAPITokenUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("📢 Received Web API token update notification")
            self?.handleWebAPITokenUpdate(notification)
        }
    }
    
    private func handleWebAPITokenUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let isAuthenticated = userInfo["isAuthenticated"] as? Bool else {
            print("❌ Invalid Web API token notification data")
            return
        }
        
        print("🔄 Web API token update: isAuthenticated = \(isAuthenticated)")
        
        // 强制更新状态
        DispatchQueue.main.async {
            self.updateTokens()
            print("🔄 Forced token status update after Web API notification")
        }
    }
    
    private func setupStatusMonitoring() {
        // 监听认证状态变化
        $authenticationStatus
            .map { status in
                status == .fullyAuthenticated
            }
            .assign(to: &$isFullyAuthenticated)
    }
    
    private func updateTokens() {
        print("🔄 Updating token states...")
        
        // 更新 iOS SDK token 状态
        if let iOSSDK = iOSSDKManager {
            let wasAuthenticated = iOSSDKToken != nil
            iOSSDKToken = iOSSDK.isAuthenticated ? "ios_sdk_token_available" : nil
            print("📱 iOS SDK: isAuthenticated = \(iOSSDK.isAuthenticated), token = \(iOSSDKToken != nil ? "available" : "nil")")
            
            if wasAuthenticated != (iOSSDKToken != nil) {
                print("🔄 iOS SDK authentication state changed")
            }
        }
        
        // 更新 Web API token 状态
        if let webAPI = webAPIManager {
            let wasAuthenticated = webAPIToken != nil
            webAPIToken = webAPI.webAPIToken
            print("🌐 Web API: isAuthenticated = \(webAPI.isAuthenticated), token = \(webAPIToken != nil ? "available" : "nil")")
            
            if wasAuthenticated != (webAPIToken != nil) {
                print("🔄 Web API authentication state changed")
            }
        }
        
        updateAuthenticationStatus()
    }
    
    private func updateAuthenticationStatus() {
        let hasIOSSDK = iOSSDKManager?.isAuthenticated == true
        let hasWebAPI = webAPIManager?.isAuthenticated == true
        let previousStatus = authenticationStatus
        
        print("🔍 Authentication status check:")
        print("  iOS SDK authenticated: \(hasIOSSDK)")
        print("  Web API authenticated: \(hasWebAPI)")
        print("  Previous status: \(previousStatus)")
        
        DispatchQueue.main.async {
            switch (hasIOSSDK, hasWebAPI) {
            case (false, false):
                self.authenticationStatus = .notAuthenticated
            case (true, false):
                self.authenticationStatus = .iOSSDKOnly
            case (false, true):
                self.authenticationStatus = .webAPIOnly
            case (true, true):
                self.authenticationStatus = .fullyAuthenticated
            }
            
            print("🔐 Authentication status updated: \(previousStatus) → \(self.authenticationStatus)")
            
            // 如果获得了数据读取权限，发送通知触发播放列表加载
            let canReadDataBefore = self.canReadDataForStatus(previousStatus)
            let canReadDataNow = self.canReadData
            
            print("📊 Data access status: before=\(canReadDataBefore), now=\(canReadDataNow)")
            
            if !canReadDataBefore && canReadDataNow {
                print("🎵 Data access now available, triggering playlist load...")
                NotificationCenter.default.post(
                    name: NSNotification.Name("SpotifyDataAccessAvailable"),
                    object: nil
                )
            }
        }
    }
    
    // 辅助方法：检查指定状态是否可以读取数据
    private func canReadDataForStatus(_ status: AuthenticationStatus) -> Bool {
        return status == .webAPIOnly || status == .fullyAuthenticated
    }
    
    // MARK: - Token Selection Strategy
    func getAppropriateToken(for purpose: TokenPurpose) -> String? {
        switch purpose {
        case .dataAccess:
            // 数据访问优先使用 Web API token
            if let webToken = webAPIToken {
                print("🌐 Using Web API token for data access")
                return webToken
            }
            // Fallback 到 iOS SDK token（虽然可能权限不足）
            if iOSSDKToken != nil {
                print("⚠️ Using iOS SDK token for data access (may have insufficient permissions)")
                return "fallback_to_ios_sdk"
            }
            return nil
            
        case .playbackControl:
            // 播放控制优先使用 iOS SDK
            if iOSSDKManager?.isAuthenticated == true {
                print("📱 Using iOS SDK for playback control")
                return "use_ios_sdk"
            }
            // Fallback 到 Web API token
            if let webToken = webAPIToken {
                print("🌐 Using Web API token for playback control")
                return webToken
            }
            return nil
            
        case .any:
            // 任意 token
            return webAPIToken ?? (iOSSDKManager?.isAuthenticated == true ? "ios_sdk_available" : nil)
        }
    }
    
    // MARK: - Token Purpose
    enum TokenPurpose {
        case dataAccess       // 数据读取（播放列表、用户信息等）
        case playbackControl  // 播放控制（播放、暂停、切歌等）
        case any             // 任意用途
    }
    
    // MARK: - Authorization Management
    func startFullAuthorization() {
        print("🚀 Starting full Spotify authorization...")
        
        // 首先尝试 Web API 授权（数据读取权限）
        webAPIManager?.startWebAPIAuthorization()
    }
    
    func handleCallback(url: URL) -> Bool {
        print("📱 Token Manager handling callback: \(url)")
        
        // 尝试让各个管理器处理回调
        var handled = false
        
        // 首先尝试 Web API 处理
        if webAPIManager?.handleWebAPICallback(url: url) == true {
            print("✅ Web API callback handled")
            handled = true
        }
        
        // 然后尝试 iOS SDK 处理
        if iOSSDKManager?.handleAuthorizationCallback(url: url) == true {
            print("✅ iOS SDK callback handled")
            handled = true
        }
        
        return handled
    }
    
    // MARK: - Token Validation
    func validateAllTokens() async -> Bool {
        var webAPIValid = false
        var iOSSDKValid = false
        
        // 验证 Web API token
        if let webAPI = webAPIManager {
            webAPIValid = await webAPI.validateToken()
        }
        
        // 验证 iOS SDK token（通过连接状态）
        iOSSDKValid = iOSSDKManager?.isConnected == true
        
        print("🔍 Token validation results: Web API: \(webAPIValid), iOS SDK: \(iOSSDKValid)")
        
        return webAPIValid || iOSSDKValid
    }
    
    // MARK: - Authorization Status Helpers
    var needsWebAPIAuth: Bool {
        return authenticationStatus == .notAuthenticated || authenticationStatus == .iOSSDKOnly
    }
    
    var needsIOSSDKAuth: Bool {
        return authenticationStatus == .notAuthenticated || authenticationStatus == .webAPIOnly
    }
    
    var canReadData: Bool {
        return authenticationStatus == .webAPIOnly || authenticationStatus == .fullyAuthenticated
    }
    
    var canControlPlayback: Bool {
        return authenticationStatus == .iOSSDKOnly || authenticationStatus == .fullyAuthenticated
    }
    
    // MARK: - Debug Information
    var debugInfo: String {
        return """
        🔐 Token Manager Status:
        - Authentication: \(authenticationStatus)
        - Fully Authenticated: \(isFullyAuthenticated)
        - iOS SDK Token: \(iOSSDKToken != nil ? "✅" : "❌")
        - Web API Token: \(webAPIToken != nil ? "✅" : "❌")
        - Can Read Data: \(canReadData ? "✅" : "❌")
        - Can Control Playback: \(canControlPlayback ? "✅" : "❌")
        """
    }
}

// MARK: - Token Manager Extensions
extension SpotifyTokenManager {
    
    // 便捷方法：获取数据访问 token
    var dataAccessToken: String? {
        return getAppropriateToken(for: .dataAccess)
    }
    
    // 便捷方法：检查是否可以进行 API 调用
    func canMakeAPICall(type: TokenPurpose) -> Bool {
        return getAppropriateToken(for: type) != nil
    }
}

// MARK: - Authentication Status Extension
extension SpotifyTokenManager.AuthenticationStatus: CustomStringConvertible {
    var description: String {
        switch self {
        case .notAuthenticated:
            return "Not Authenticated"
        case .iOSSDKOnly:
            return "iOS SDK Only (Playback Control)"
        case .webAPIOnly:
            return "Web API Only (Data Access)"
        case .fullyAuthenticated:
            return "Fully Authenticated (All Permissions)"
        }
    }
}