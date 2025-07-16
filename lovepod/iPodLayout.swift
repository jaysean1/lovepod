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
        .overlay(
            // 底部重连提示
            reconnectPromptOverlay,
            alignment: .bottom
        )
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
    
    // MARK: - Reconnect Prompt Overlay
    private var reconnectPromptOverlay: some View {
        Group {
            if appState.showReconnectPrompt {
                VStack {
                    Spacer()
                    
                    // 重连提示条
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        appState.reconnectSpotify()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Spotify disconnected - Tap to reconnect")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.9))
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.bottom, DesignSystem.Spacing.m)
                }
                .animation(.easeInOut(duration: 0.3), value: appState.showReconnectPrompt)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
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
    @State private var isWheelBeingRotated: Bool = false
    
    // 手势状态管理
    @State private var gestureState: GestureState = .idle
    @State private var gestureStartLocation: CGPoint = .zero
    @State private var gestureStartTime: Date = Date()
    @State private var totalMovementDistance: CGFloat = 0
    @State private var highlightedButton: ButtonPosition? = nil
    
    // 手势意图识别参数
    private let minimumMovementThreshold: CGFloat = 10 // 最小移动距离判断旋转意图
    private let intentRecognitionDelay: TimeInterval = 0.15 // 意图识别延迟时间
    private let quickMovementThreshold: CGFloat = 20 // 快速移动阈值
    
    enum GestureState {
        case idle           // 无手势
        case observing      // 观察期，判断意图
        case rotating       // 确认为旋转手势
        case clicking       // 确认为点击手势
    }
    
    enum ButtonPosition {
        case menu, left, right, playPause
    }
    
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
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleGestureChanged(value: value, wheelSize: wheelSize)
                            }
                            .onEnded { value in
                                handleGestureEnded(value: value, wheelSize: wheelSize)
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
    
    // MARK: - Direction Buttons (Visual Only)
    private func directionButtons(wheelSize: CGFloat) -> some View {
        ZStack {
            // MENU 按钮 (顶部) - 距离转盘边缘内侧20pt
            Text("MENU")
                .font(.caption.bold())
                .foregroundColor(highlightedButton == .menu ? DesignSystem.Colors.highlightBackground : DesignSystem.Colors.text)
                .scaleEffect(highlightedButton == .menu ? 1.1 : 1.0)
                .offset(y: -(wheelSize / 2 - 20))
                .animation(.easeInOut(duration: 0.1), value: highlightedButton == .menu)
            
            // 左按钮 - 距离转盘边缘内侧20pt
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(highlightedButton == .left ? DesignSystem.Colors.highlightBackground : DesignSystem.Colors.text)
                .scaleEffect(highlightedButton == .left ? 1.1 : 1.0)
                .offset(x: -(wheelSize / 2 - 20))
                .animation(.easeInOut(duration: 0.1), value: highlightedButton == .left)
            
            // 右按钮 - 距离转盘边缘内侧20pt
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(highlightedButton == .right ? DesignSystem.Colors.highlightBackground : DesignSystem.Colors.text)
                .scaleEffect(highlightedButton == .right ? 1.1 : 1.0)
                .offset(x: (wheelSize / 2 - 20))
                .animation(.easeInOut(duration: 0.1), value: highlightedButton == .right)
            
            // PLAY/PAUSE 按钮 (底部) - 距离转盘边缘内侧20pt
            Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(highlightedButton == .playPause ? DesignSystem.Colors.highlightBackground : DesignSystem.Colors.text)
                .scaleEffect(highlightedButton == .playPause ? 1.1 : 1.0)
                .offset(y: (wheelSize / 2 - 20))
                .animation(.easeInOut(duration: 0.1), value: highlightedButton == .playPause)
        }
        .allowsHitTesting(false) // 禁用原有的点击检测，由统一手势系统处理
    }
    
    // MARK: - Button Handlers
    private func handleCenterButtonTap() {
        HapticManager.shared.buttonTap()
        
        switch appState.currentPage {
        case .home:
            appState.selectHomeMenuItem(appState.selectedHomeMenuItem)
        case .playlist:
            // 特殊处理：如果未授权，触发授权；如果没有播放列表，加载播放列表；否则选择播放列表
            if !appState.isSpotifyAuthenticated {
                appState.authenticateSpotify()
            } else if appState.spotifyPlaylists.isEmpty {
                appState.loadSpotifyPlaylists()
            } else if appState.selectedPlaylistIndex < appState.spotifyPlaylists.count {
                // 确保索引有效后选择播放列表
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
        // 转盘停止时，同步播放进度到设定位置
        if appState.currentPage == .nowPlaying {
            // 转盘停止，同步进度
            syncPlaybackProgress()
        }
        rotationAccumulator = 0
    }
    
    private func syncPlaybackProgress() {
        // 转盘停止后，确保播放进度同步到设定位置
        print("🎵 Wheel rotation ended, syncing playback progress to: \(appState.playbackProgress)")
        
        // 调用AppState的seek方法，将当前UI进度同步到实际播放位置
        appState.seek(to: appState.playbackProgress)
        
        print("✅ Seek command sent to AppState for progress: \(appState.playbackProgress)")
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
            let maxIndex = !appState.spotifyPlaylists.isEmpty ? appState.spotifyPlaylists.count - 1 : appState.playlists.count - 1
            let newIndex = max(0, min(maxIndex, currentIndex + direction))
            appState.selectedPlaylistIndex = newIndex
            
        case .nowPlaying:
            // In now playing, rotation controls scrubbing
            let progressDelta = Double(direction) * 0.02 // 2% per step for finer control
            let newProgress = max(0.0, min(1.0, appState.playbackProgress + progressDelta))
            
            // 在滚动时实时更新UI进度，但不立即同步到Spotify
            appState.playbackProgress = newProgress
            appState.currentTime = appState.duration * newProgress
            
            print("🎵 Wheel rotation: progress updated to \(newProgress) (time: \(appState.currentTime)s)")
            
        default:
            break
        }
        
        // Trigger haptic feedback
        HapticManager.shared.menuItemChanged()
    }
    
    // MARK: - Smart Gesture Recognition
    private func handleGestureChanged(value: DragGesture.Value, wheelSize: CGFloat) {
        let currentLocation = value.location
        let timeSinceStart = Date().timeIntervalSince(gestureStartTime)
        
        switch gestureState {
        case .idle:
            // 手势开始，进入观察期
            gestureState = .observing
            gestureStartLocation = currentLocation
            gestureStartTime = Date()
            totalMovementDistance = 0
            print("🎯 Gesture started - entering observation mode")
            
        case .observing:
            // 计算移动距离
            let deltaX = currentLocation.x - gestureStartLocation.x
            let deltaY = currentLocation.y - gestureStartLocation.y
            let movementDistance = sqrt(deltaX * deltaX + deltaY * deltaY)
            totalMovementDistance = movementDistance
            
            // 在观察期内，显示可能的按钮高亮
            updateButtonPreview(currentLocation, wheelSize: wheelSize)
            
            // 快速移动检测：立即判定为旋转
            if movementDistance >= quickMovementThreshold {
                gestureState = .rotating
                clearButtonPreview()
                startRotationGesture()
                handleWheelRotation(value: value, wheelSize: wheelSize)
                print("🎯 Quick movement detected - immediate rotation mode")
                return
            }
            
            // 达到移动阈值：判定为旋转意图
            if movementDistance >= minimumMovementThreshold {
                gestureState = .rotating
                clearButtonPreview()
                startRotationGesture()
                handleWheelRotation(value: value, wheelSize: wheelSize)
                print("🎯 Movement threshold reached - rotation mode")
                return
            }
            
            // 时间超过延迟且无明显移动：判定为点击意图
            if timeSinceStart >= intentRecognitionDelay && movementDistance < minimumMovementThreshold {
                gestureState = .clicking
                print("🎯 No significant movement after delay - click mode")
                return
            }
            
        case .rotating:
            // 已确认为旋转手势，继续处理旋转
            handleWheelRotation(value: value, wheelSize: wheelSize)
            
        case .clicking:
            // 已确认为点击意图，不处理移动
            break
        }
    }
    
    private func handleGestureEnded(value: DragGesture.Value, wheelSize: CGFloat) {
        let finalLocation = value.location
        
        switch gestureState {
        case .observing:
            // 观察期结束，根据最终位置判断是否为点击
            if totalMovementDistance < minimumMovementThreshold {
                // 判定为点击，处理按钮点击事件
                handleButtonClickAtLocation(finalLocation, wheelSize: wheelSize)
                print("🎯 Gesture ended in observation - triggered click")
            }
            
        case .rotating:
            // 旋转手势结束
            endRotationGesture()
            print("🎯 Rotation gesture ended")
            
        case .clicking:
            // 点击手势结束，处理按钮点击
            handleButtonClickAtLocation(finalLocation, wheelSize: wheelSize)
            print("🎯 Click gesture ended")
            
        case .idle:
            break
        }
        
        // 重置状态
        gestureState = .idle
        gestureStartLocation = .zero
        totalMovementDistance = 0
        clearButtonPreview()
    }
    
    private func startRotationGesture() {
        if !isWheelBeingRotated {
            isWheelBeingRotated = true
            // 如果在Now Playing界面，设置用户正在控制进度
            if appState.currentPage == .nowPlaying {
                appState.setUserSeekingProgress(true)
            }
            print("🎵 Started wheel rotation gesture")
        }
    }
    
    private func endRotationGesture() {
        if isWheelBeingRotated {
            isWheelBeingRotated = false
            resetRotation()
            print("🎵 Ended wheel rotation gesture")
        }
    }
    
    private func handleButtonClickAtLocation(_ location: CGPoint, wheelSize: CGFloat) {
        let center = CGPoint(x: wheelSize / 2, y: wheelSize / 2)
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        let angle = atan2(deltaY, deltaX)
        
        // 检查是否在按钮区域（距离转盘边缘内侧20pt的区域）
        let buttonRegionInnerRadius = wheelSize / 2 - 50 // 按钮区域内边界
        let buttonRegionOuterRadius = wheelSize / 2 - 10 // 按钮区域外边界
        
        if distance >= buttonRegionInnerRadius && distance <= buttonRegionOuterRadius {
            // 根据角度判断点击的是哪个按钮
            let degrees = angle * 180 / .pi
            let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees
            
            // 定义按钮角度范围（每个按钮占90度）
            if normalizedDegrees >= 315 || normalizedDegrees < 45 {
                // 右按钮 (0度附近)
                handleRightButton()
                print("🎯 Detected right button click")
            } else if normalizedDegrees >= 45 && normalizedDegrees < 135 {
                // 下按钮 (90度) - PLAY/PAUSE
                handlePlayPauseButton()
                print("🎯 Detected play/pause button click")
            } else if normalizedDegrees >= 135 && normalizedDegrees < 225 {
                // 左按钮 (180度)
                handleLeftButton()
                print("🎯 Detected left button click")
            } else if normalizedDegrees >= 225 && normalizedDegrees < 315 {
                // 上按钮 (270度) - MENU
                handleMenuButton()
                print("🎯 Detected menu button click")
            }
        }
    }
    
    // MARK: - Button Preview and Highlight Management
    private func updateButtonPreview(_ location: CGPoint, wheelSize: CGFloat) {
        let buttonPosition = getButtonPosition(location, wheelSize: wheelSize)
        
        // 只有当按钮位置改变时才更新，避免不必要的动画
        if highlightedButton != buttonPosition {
            highlightedButton = buttonPosition
            
            // 轻微的触觉反馈来指示按钮预览
            if buttonPosition != nil {
                HapticManager.shared.selectionChanged()
            }
        }
    }
    
    private func clearButtonPreview() {
        highlightedButton = nil
    }
    
    private func getButtonPosition(_ location: CGPoint, wheelSize: CGFloat) -> ButtonPosition? {
        let center = CGPoint(x: wheelSize / 2, y: wheelSize / 2)
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        let angle = atan2(deltaY, deltaX)
        
        // 检查是否在按钮区域（距离转盘边缘内侧20pt的区域）
        let buttonRegionInnerRadius = wheelSize / 2 - 50 // 按钮区域内边界
        let buttonRegionOuterRadius = wheelSize / 2 - 10 // 按钮区域外边界
        
        guard distance >= buttonRegionInnerRadius && distance <= buttonRegionOuterRadius else {
            return nil
        }
        
        // 根据角度判断位置
        let degrees = angle * 180 / .pi
        let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees
        
        // 定义按钮角度范围（每个按钮占90度）
        if normalizedDegrees >= 315 || normalizedDegrees < 45 {
            return .right // 右按钮 (0度附近)
        } else if normalizedDegrees >= 45 && normalizedDegrees < 135 {
            return .playPause // 下按钮 (90度) - PLAY/PAUSE
        } else if normalizedDegrees >= 135 && normalizedDegrees < 225 {
            return .left // 左按钮 (180度)
        } else if normalizedDegrees >= 225 && normalizedDegrees < 315 {
            return .menu // 上按钮 (270度) - MENU
        }
        
        return nil
    }
}