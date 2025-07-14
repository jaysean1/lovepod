// lovepod/iPodLayout.swift
// 主要的iPod布局容器，定义了经典iPod的视觉结构
// 包含上半部分的屏幕区域和下半部分的控制区域

import SwiftUI

struct iPodLayout<Content: View>: View {
    private let appState = AppState.shared
    @EnvironmentObject var spotifyService: SpotifyService
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 上半部分：屏幕区域 (50%)
                screenArea
                    .frame(height: geometry.size.height * DesignSystem.Layout.screenHeight)
                
                // 下半部分：控制区域 (50%)
                controlArea
                    .frame(height: geometry.size.height * DesignSystem.Layout.controlHeight)
            }
        }
        .environmentObject(appState)
        .background(DesignSystem.Colors.background)
        .onAppear {
            // 连接 Spotify 服务到 AppState
            appState.setSpotifyService(spotifyService)
        }
    }
    
    // MARK: - Screen Area
    private var screenArea: some View {
        VStack(spacing: 0) {
            // 状态栏
            StatusBarView()
                .frame(height: DesignSystem.Components.StatusBar.height)
            
            // 主要内容区域
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .iPodScreenContainer()
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.top, DesignSystem.Spacing.m)
    }
    
    // MARK: - Control Area
    private var controlArea: some View {
        ClickWheelView()
            .padding(.all, DesignSystem.Spacing.l)
    }
}

// MARK: - Status Bar View
struct StatusBarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            // 左侧：页面标题
            Text(pageTitle)
                .iPodStatusBarStyle()
            
            Spacer()
            
            // 右侧：电池图标
            Image(systemName: DesignSystem.Icons.battery)
                .font(.system(size: DesignSystem.Icons.size))
                .foregroundColor(DesignSystem.Colors.statusBarText)
        }
        .frame(height: DesignSystem.Components.StatusBar.height)
        .background(DesignSystem.Colors.statusBarBackground)
    }
    
    private var pageTitle: String {
        switch appState.currentPage {
        case .home:
            return "lovepod"
        case .playlist:
            return "Cover Flow"
        case .nowPlaying:
            return "Now Playing"
        case .settings:
            return "Settings"
        case .themes:
            return "Themes"
        case .upgrade:
            return "Upgrade to Pro"
        case .user:
            return "User"
        }
    }
}

// MARK: - Click Wheel View with Gesture Recognition
struct ClickWheelView: View {
    @EnvironmentObject var appState: AppState
    @State private var lastAngle: Double = 0
    @State private var rotationAccumulator: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let wheelSize = min(geometry.size.width, geometry.size.height) * DesignSystem.Layout.wheelDiameterRatio
            let centerButtonSize = wheelSize * DesignSystem.Layout.centerButtonRatio
            
            ZStack {
                // 外圆环 (转盘) - 可以检测旋转手势
                Circle()
                    .stroke(DesignSystem.Colors.divider, lineWidth: 2)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white,
                                        Color.gray.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .frame(width: wheelSize, height: wheelSize)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleWheelRotation(value: value, wheelSize: wheelSize)
                            }
                            .onEnded { _ in
                                resetRotation()
                            }
                    )
                
                // 方向按钮
                directionButtons(wheelSize: wheelSize)
                
                // 中央按钮
                Button(action: {
                    handleCenterButtonTap()
                }) {
                    Circle()
                        .fill(DesignSystem.Colors.background)
                        .frame(width: centerButtonSize, height: centerButtonSize)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
    
    // MARK: - Direction Buttons
    private func directionButtons(wheelSize: CGFloat) -> some View {
        ZStack {
            // MENU 按钮 (顶部) - 距离转盘边缘内侧20pt
            Button("MENU") {
                handleMenuButton()
            }
            .font(.caption.bold())
            .foregroundColor(DesignSystem.Colors.text)
            .offset(y: -(wheelSize / 2 - 20))
            
            // 左按钮 - 距离转盘边缘内侧20pt
            Button(action: handleLeftButton) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.text)
            }
            .offset(x: -(wheelSize / 2 - 20))
            
            // 右按钮 - 距离转盘边缘内侧20pt
            Button(action: handleRightButton) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.text)
            }
            .offset(x: (wheelSize / 2 - 20))
            
            // PLAY/PAUSE 按钮 (底部) - 距离转盘边缘内侧20pt
            Button(action: handlePlayPauseButton) {
                Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.text)
            }
            .offset(y: (wheelSize / 2 - 20))
        }
    }
    
    // MARK: - Button Handlers
    private func handleCenterButtonTap() {
        HapticManager.shared.buttonTap()
        
        switch appState.currentPage {
        case .home:
            appState.selectHomeMenuItem(appState.selectedHomeMenuItem)
        case .playlist:
            // 特殊处理：如果未授权，触发授权；否则选择播放列表
            if !appState.isSpotifyAuthenticated {
                appState.authenticateSpotify()
            } else if appState.spotifyPlaylists.isEmpty {
                appState.loadSpotifyPlaylists()
            } else {
                appState.selectPlaylist(appState.selectedPlaylistIndex)
            }
        case .settings:
            appState.selectSettingsMenuItem(appState.selectedSettingsMenuItem)
        case .nowPlaying:
            appState.togglePlayPause()
        default:
            break
        }
    }
    
    private func handleMenuButton() {
        HapticManager.shared.buttonTap()
        appState.navigateBack()
    }
    
    private func handleLeftButton() {
        HapticManager.shared.buttonTap()
        switch appState.currentPage {
        case .nowPlaying:
            appState.previousTrack()
        default:
            break
        }
    }
    
    private func handleRightButton() {
        HapticManager.shared.buttonTap()
        switch appState.currentPage {
        case .nowPlaying:
            appState.nextTrack()
        default:
            break
        }
    }
    
    private func handlePlayPauseButton() {
        HapticManager.shared.playbackToggle()
        if appState.currentPage == .nowPlaying {
            appState.togglePlayPause()
        } else {
            // 如果不在播放页面，开始播放当前选中的内容
            if appState.currentPage == .playlist {
                appState.selectPlaylist(appState.selectedPlaylistIndex)
            }
        }
    }
    
    // MARK: - Wheel Rotation Gesture Handling
    private func handleWheelRotation(value: DragGesture.Value, wheelSize: CGFloat) {
        let center = CGPoint(x: wheelSize / 2, y: wheelSize / 2)
        let vector = CGPoint(x: value.location.x - center.x, y: value.location.y - center.y)
        let angle = atan2(vector.y, vector.x)
        
        // Convert to degrees and normalize
        let degrees = angle * 180 / .pi
        let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees
        
        // Calculate rotation delta
        let angleDelta = normalizedDegrees - lastAngle
        var rotationDelta = angleDelta
        
        // Handle angle wrap around
        if abs(angleDelta) > 180 {
            rotationDelta = angleDelta > 0 ? angleDelta - 360 : angleDelta + 360
        }
        
        // Accumulate rotation
        rotationAccumulator += rotationDelta
        
        // Check if we've rotated enough to trigger a menu change (30 degrees)
        let threshold: Double = 30
        if abs(rotationAccumulator) >= threshold {
            let direction = rotationAccumulator > 0 ? 1 : -1
            handleMenuNavigation(direction: direction)
            
            // Reset accumulator
            rotationAccumulator = 0
        }
        
        lastAngle = normalizedDegrees
    }
    
    private func resetRotation() {
        rotationAccumulator = 0
    }
    
    private func handleMenuNavigation(direction: Int) {
        switch appState.currentPage {
        case .home:
            let currentIndex = appState.selectedHomeMenuItem
            let maxIndex = HomeMenuItem.allCases.count - 1
            let newIndex = max(0, min(maxIndex, currentIndex + direction))
            appState.selectedHomeMenuItem = newIndex
            
        case .settings:
            let currentIndex = appState.selectedSettingsMenuItem
            let maxIndex = SettingsMenuItem.allCases.count - 1
            let newIndex = max(0, min(maxIndex, currentIndex + direction))
            appState.selectedSettingsMenuItem = newIndex
            
        case .playlist:
            let currentIndex = appState.selectedPlaylistIndex
            let maxIndex = appState.playlists.count - 1
            let newIndex = max(0, min(maxIndex, currentIndex + direction))
            appState.selectedPlaylistIndex = newIndex
            
        case .nowPlaying:
            // In now playing, rotation controls scrubbing
            let progressDelta = Double(direction) * 0.05 // 5% per step
            let newProgress = max(0.0, min(1.0, appState.playbackProgress + progressDelta))
            appState.seek(to: newProgress)
            
        default:
            break
        }
        
        // Trigger haptic feedback
        HapticManager.shared.menuItemChanged()
    }
}