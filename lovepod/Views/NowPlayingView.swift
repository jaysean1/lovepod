// lovepod/Views/NowPlayingView.swift
// 正在播放界面实现，显示专辑封面、歌曲信息和播放进度
// 支持转盘控制进度条滑动和播放控制

import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var spotifyService: SpotifyService
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 专辑封面区域 - 严格按照设计系统比例分配高度
                albumArtSection
                    .frame(height: geometry.size.height * DesignSystem.Layout.albumArtHeight)
                
                // 歌曲信息区域 - 按设计系统比例分配高度
                trackInfoSection
                    .frame(height: geometry.size.height * DesignSystem.Layout.trackInfoHeight)
                
                // 播放进度区域 - 按设计系统比例分配高度
                progressSection
                    .frame(height: geometry.size.height * DesignSystem.Layout.scrubberHeight)
                
                // 底部剩余空间 - 无剩余空间，去除Spacer
            }
        }
        .background(DesignSystem.Colors.background)
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            updatePlaybackProgress()
        }
    }
    
    // MARK: - Album Art Section
    private var albumArtSection: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let albumSize = min(availableHeight * 0.8, 180) // 动态计算，最大180pt
            
            VStack {
                Spacer()
                
                // 专辑封面 - 使用 Spotify 数据或模拟数据
                if let spotifyTrack = appState.currentSpotifyTrack {
                    // 显示 Spotify 专辑封面，仅在专辑图片URL变化时重新加载
                    AlbumArtworkView(
                        albumImageURL: spotifyTrack.albumImageURL,
                        trackId: spotifyTrack.id
                    )
                    .frame(
                        width: albumSize,
                        height: albumSize
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Components.AlbumArt.cornerRadius))
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .id(spotifyTrack.albumImageURL ?? "no-image") // 仅在图片URL变化时重新创建
                        
                } else {
                    // 默认占位符封面
                    AlbumArtworkView(albumImageURL: nil, trackId: nil)
                        .frame(
                            width: albumSize,
                            height: albumSize
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Components.AlbumArt.cornerRadius))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Track Info Section
    private var trackInfoSection: some View {
        VStack {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                // 优先显示 Spotify 歌曲信息，否则使用 AppState 信息
                if let spotifyTrack = appState.currentSpotifyTrack {
                    // Spotify 歌曲信息 - 紧凑布局
                    Text(spotifyTrack.name)
                        .font(DesignSystem.Typography.nowPlayingTrack)
                        .foregroundColor(DesignSystem.Colors.text)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                    
                    Text(spotifyTrack.primaryArtistName)
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.8))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                    
                    Text(spotifyTrack.album.name)
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                } else {
                    // 使用 AppState 的歌曲信息（模拟数据或向后兼容）
                    Text(appState.currentTrackTitle)
                        .font(DesignSystem.Typography.nowPlayingTrack)
                        .foregroundColor(DesignSystem.Colors.text)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                    
                    Text(appState.currentArtist)
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.8))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                    
                    Text(appState.currentAlbum)
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                
                // 连接状态指示 - 仅在开发模式显示，使用最小间距
                if appState.isSpotifyConnected {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Spotify")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.text.opacity(0.4))
                    }
                    .padding(.top, DesignSystem.Spacing.xxs)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.s)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.s) {
                // 进度条（带有预览功能）- 减少水平 padding
                ProgressBarView(
                    progress: appState.playbackProgress,
                    duration: appState.duration,
                    isUserSeeking: appState.isUserSeekingProgress
                )
                .padding(.horizontal, DesignSystem.Spacing.s)
                
                // 时间显示 - 紧凑布局
                HStack {
                    Text(formatTime(appState.currentTime))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.7))
                    
                    Spacer()
                    
                    // 如果用户正在拖动，显示预览时间
                    if appState.isUserSeekingProgress {
                        Text("→ \(formatTime(appState.currentTime))")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.highlightBackground)
                            .transition(.opacity)
                    }
                    
                    Text(formatTime(appState.duration))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.7))
                }
                .padding(.horizontal, DesignSystem.Spacing.s)
                .animation(.easeInOut(duration: 0.2), value: appState.isUserSeekingProgress)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    private func updatePlaybackProgress() {
        // 只在播放状态下更新进度
        guard appState.isPlaying else { return }
        
        // 如果有 Spotify 服务且已连接，主动获取实时进度
        if appState.isSpotifyConnected {
            // 主动查询当前播放位置，确保实时更新
            Task {
                await appState.spotifyService?.refreshCurrentPlaybackPosition()
            }
            return
        }
        
        // 模拟模式下的手动进度更新
        if appState.duration > 0 {
            let newCurrentTime = min(appState.currentTime + 1.0, appState.duration)
            appState.currentTime = newCurrentTime
            appState.playbackProgress = newCurrentTime / appState.duration
            
            // 如果播放完毕，停止播放
            if newCurrentTime >= appState.duration {
                appState.isPlaying = false
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Album Artwork View
struct AlbumArtworkView: View {
    let albumImageURL: String?
    let trackId: String?
    @State private var hasFailedToLoad: Bool = false
    @State private var retryCount: Int = 0
    @State private var lastLoadedURL: String? = nil
    private let maxRetries: Int = 2
    
    var body: some View {
        Group {
            if let albumImageURL = albumImageURL,
               let url = URL(string: albumImageURL) {
                // 显示专辑封面，带有重试机制
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.opacity)
                            .onAppear {
                                print("✅ Successfully loaded album artwork from: \(albumImageURL)")
                                hasFailedToLoad = false
                                retryCount = 0
                                lastLoadedURL = albumImageURL
                            }
                    case .failure(let error):
                        // 加载失败时的占位符，支持重试
                        albumArtPlaceholder
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: hasFailedToLoad ? "photo" : "exclamationmark.triangle")
                                        .font(.system(size: 30, weight: .light))
                                        .foregroundColor(DesignSystem.Colors.text.opacity(0.5))
                                    
                                    if retryCount < maxRetries {
                                        Text("Tap to retry")
                                            .font(.caption2)
                                            .foregroundColor(DesignSystem.Colors.text.opacity(0.5))
                                    }
                                }
                            )
                            .onTapGesture {
                                // 点击重试加载
                                if retryCount < maxRetries {
                                    retryCount += 1
                                    print("🔄 Retrying album artwork load (attempt \(retryCount))")
                                    // 强制刷新AsyncImage
                                }
                            }
                            .onAppear {
                                print("❌ Failed to load album artwork: \(error.localizedDescription)")
                                print("❌ URL: \(albumImageURL)")
                                hasFailedToLoad = true
                            }
                    case .empty:
                        // 加载中占位符
                        albumArtPlaceholder
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.highlightBackground))
                            )
                            .onAppear {
                                // 仅在URL真正变化时记录加载
                                if lastLoadedURL != albumImageURL {
                                    print("🔄 Loading new album artwork from: \(albumImageURL)")
                                    lastLoadedURL = albumImageURL
                                } else {
                                    print("⏭️ Same URL, skipping load log: \(albumImageURL)")
                                }
                            }
                    @unknown default:
                        albumArtPlaceholder
                    }
                }
                .id("\(albumImageURL)-\(retryCount)") // 使用retryCount强制重新加载
            } else {
                // 无图片URL时的默认占位符
                albumArtPlaceholder
                    .onAppear {
                        print("ℹ️ No album artwork URL provided")
                    }
            }
        }
    }
    
    private var albumArtPlaceholder: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Components.AlbumArt.cornerRadius)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.highlightBackground.opacity(0.8),
                        DesignSystem.Colors.highlightBackground.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: DesignSystem.Icons.music)
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(DesignSystem.Colors.background)
            )
    }
}

// MARK: - Progress Bar Component
struct ProgressBarView: View {
    let progress: Double
    let duration: TimeInterval
    let isUserSeeking: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                RoundedRectangle(cornerRadius: DesignSystem.Components.Scrubber.trackHeight / 2)
                    .fill(DesignSystem.Colors.divider.opacity(0.3))
                    .frame(height: DesignSystem.Components.Scrubber.trackHeight)
                
                // 进度填充
                RoundedRectangle(cornerRadius: DesignSystem.Components.Scrubber.trackHeight / 2)
                    .fill(isUserSeeking ? 
                          DesignSystem.Colors.highlightBackground.opacity(0.8) : 
                          DesignSystem.Colors.highlightBackground)
                    .frame(
                        width: geometry.size.width * CGFloat(progress),
                        height: DesignSystem.Components.Scrubber.trackHeight
                    )
                    .animation(.linear(duration: isUserSeeking ? 0.05 : 0.1), value: progress)
                
                // 拖动时的预览指示器
                if isUserSeeking {
                    Circle()
                        .fill(DesignSystem.Colors.highlightBackground)
                        .frame(width: 12, height: 12)
                        .offset(x: geometry.size.width * CGFloat(progress) - 6)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(height: DesignSystem.Components.Scrubber.trackHeight)
        .animation(.easeInOut(duration: 0.2), value: isUserSeeking)
    }
}

// MARK: - Preview
#Preview {
    iPodLayout {
        NowPlayingView()
    }
    .environmentObject({
        let state = AppState.shared
        state.currentTrackTitle = "Love Story"
        state.currentArtist = "Taylor Swift"
        state.currentAlbum = "Fearless"
        state.isPlaying = true
        state.playbackProgress = 0.4
        state.currentTime = 72
        state.duration = 180
        return state
    }())
}