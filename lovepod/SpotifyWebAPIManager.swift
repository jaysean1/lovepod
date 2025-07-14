// lovepod/SpotifyWebAPIManager.swift
// Spotify Web API OAuth 2.0 管理器，用于获取数据读取权限
// 实现 PKCE 授权流程，获取播放列表等数据访问权限

import Foundation
import SwiftUI
import CryptoKit
import AuthenticationServices

// MARK: - Spotify Web API Manager
class SpotifyWebAPIManager: NSObject, ObservableObject {
    
    // MARK: - Configuration
    private let clientID = "88e54f88f52c4f66a20eab13bdc10f07"
    private let redirectURI = "lovepod://spotify-web-callback"
    private let authURL = "https://accounts.spotify.com/authorize"
    private let tokenURL = "https://accounts.spotify.com/api/token"
    
    // 需要的权限范围
    private let requiredScopes = [
        "playlist-read-private",
        "playlist-read-collaborative",
        "user-read-private",
        "user-read-email",
        "user-library-read",
        "app-remote-control"  // 保持与 iOS SDK 兼容
    ]
    
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var webAPIToken: String? = nil
    
    // MARK: - Private Properties
    private var codeVerifier: String?
    private var refreshToken: String?
    private var tokenExpiryDate: Date?
    
    // MARK: - PKCE Helper Methods
    private func generateCodeVerifier() -> String {
        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        let data = verifier.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    // MARK: - Authorization Methods
    func startWebAPIAuthorization() {
        print("🌐 Starting Spotify Web API authorization...")
        
        // 生成 PKCE 参数
        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)
        self.codeVerifier = verifier
        
        // 构建授权URL
        var components = URLComponents(string: authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: requiredScopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: "web_api_auth") // 用于区分不同的授权流程
        ]
        
        guard let authURL = components.url else {
            setError("Failed to construct authorization URL")
            return
        }
        
        print("🔗 Opening authorization URL: \(authURL)")
        
        // 打开授权页面
        DispatchQueue.main.async {
            UIApplication.shared.open(authURL)
        }
    }
    
    // MARK: - Authorization Callback Handling
    func handleWebAPICallback(url: URL) -> Bool {
        print("📱 Received Web API callback: \(url)")
        
        // 首先尝试处理 iOS SDK 的 implicit grant token (fragment 中的 access_token)
        if let token = extractTokenFromFragment(url: url) {
            print("✅ Extracted iOS SDK access token")
            handleImplicitGrantToken(token)
            return true
        }
        
        // 然后尝试处理标准的授权码模式 (query 中的 code)
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("⚠️ Invalid callback URL format")
            return false
        }
        
        // 检查是否是 Web API 授权码回调
        let state = queryItems.first(where: { $0.name == "state" })?.value
        guard state == "web_api_auth" else {
            print("⚠️ Not a Web API authorization code callback")
            return false
        }
        
        // 处理授权码
        if let code = queryItems.first(where: { $0.name == "code" })?.value {
            print("✅ Received authorization code: \(String(code.prefix(10)))...")
            Task {
                await exchangeCodeForToken(code: code)
            }
            return true
        }
        
        // 处理错误
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            setError("Authorization failed: \(error)")
            return false
        }
        
        return false
    }
    
    // MARK: - iOS SDK Token Extraction
    private func extractTokenFromFragment(url: URL) -> String? {
        guard let fragment = url.fragment else { return nil }
        
        // 解析 fragment 中的参数 (access_token=...&token_type=Bearer&expires_in=3600)
        let fragmentComponents = fragment.components(separatedBy: "&")
        var fragmentParams: [String: String] = [:]
        
        for component in fragmentComponents {
            let keyValue = component.components(separatedBy: "=")
            if keyValue.count == 2 {
                fragmentParams[keyValue[0]] = keyValue[1]
            }
        }
        
        return fragmentParams["access_token"]
    }
    
    private func handleImplicitGrantToken(_ token: String) {
        print("🔑 Processing iOS SDK access token (first 20 chars): \(String(token.prefix(20)))...")
        
        DispatchQueue.main.async {
            self.webAPIToken = token
            self.isAuthenticated = true
            self.errorMessage = nil
            
            // 设置默认过期时间为1小时（iOS SDK 通常是1小时）
            self.tokenExpiryDate = Date().addingTimeInterval(3600)
            
            print("✅ iOS SDK token stored for Web API use")
            print("🔄 Web API isAuthenticated = \(self.isAuthenticated)")
            
            // 立即发送状态更新通知
            NotificationCenter.default.post(
                name: NSNotification.Name("SpotifyWebAPITokenUpdated"),
                object: nil,
                userInfo: ["isAuthenticated": true, "token": token]
            )
        }
    }
    
    // MARK: - Token Exchange
    private func exchangeCodeForToken(code: String) async {
        await MainActor.run { isLoading = true }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        guard let codeVerifier = codeVerifier else {
            setError("Code verifier not found")
            return
        }
        
        guard let url = URL(string: tokenURL) else {
            setError("Invalid token URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 构建请求体
        let parameters = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ]
        
        let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        print("🔄 Exchanging authorization code for token...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Token exchange response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                    
                    await MainActor.run {
                        self.webAPIToken = tokenResponse.accessToken
                        self.refreshToken = tokenResponse.refreshToken
                        self.isAuthenticated = true
                        self.errorMessage = nil
                        
                        // 计算过期时间
                        if let expiresIn = tokenResponse.expiresIn {
                            self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                        }
                        
                        print("✅ Web API token obtained successfully")
                        print("🔑 Token (first 20 chars): \(String(tokenResponse.accessToken.prefix(20)))...")
                    }
                } else {
                    let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                    setError("Token exchange failed: \(httpResponse.statusCode) - \(errorString)")
                }
            }
        } catch {
            setError("Token exchange error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Token Refresh
    func refreshTokenIfNeeded() async -> Bool {
        // 对于 iOS SDK 获得的 implicit grant token，我们没有 refresh token
        // 直接返回 true，让 API 调用继续进行
        if refreshToken == nil {
            print("ℹ️ Using iOS SDK token (no refresh token available)")
            return true
        }
        
        // 检查是否需要刷新（提前5分钟刷新）
        if let expiryDate = tokenExpiryDate,
           Date().addingTimeInterval(300) < expiryDate {
            print("✅ Token still valid, no refresh needed")
            return true
        }
        
        print("🔄 Refreshing Web API token...")
        
        guard let url = URL(string: tokenURL) else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken!,
            "client_id": clientID
        ]
        
        let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                
                await MainActor.run {
                    self.webAPIToken = tokenResponse.accessToken
                    if let newRefreshToken = tokenResponse.refreshToken {
                        self.refreshToken = newRefreshToken
                    }
                    
                    if let expiresIn = tokenResponse.expiresIn {
                        self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                    }
                    
                    print("✅ Token refreshed successfully")
                }
                return true
            }
        } catch {
            print("❌ Token refresh failed: \(error)")
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    private func setError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            print("❌ Web API Error: \(message)")
        }
    }
    
    // MARK: - Token Validation
    func validateToken() async -> Bool {
        guard let token = webAPIToken else { return false }
        
        // 刷新 token 如果需要
        if !(await refreshTokenIfNeeded()) {
            return false
        }
        
        // 验证 token 有效性
        guard let url = URL(string: "https://api.spotify.com/v1/me") else { return false }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("❌ Token validation failed: \(error)")
        }
        
        return false
    }
}

// MARK: - Token Response Model
private struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let expiresIn: Int?
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}