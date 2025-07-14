// lovepod/Views/NowPlayingView.swift
// 正在播放界面实现，显示专辑封面、歌曲信息和播放进度
// 支持转盘控制进度条滑动和播放控制

import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var spotifyService: SpotifyService
    
    var body: some View {
        VStack(spacing: 0) {
            // 专辑封面区域
            albumArtSection
                .frame(maxHeight: .infinity)
            
            // 歌曲信息区域
            trackInfoSection
                .frame(height: 120)
            
            // 播放进度区域
            progressSection
                .frame(height: 60)
        }
        .background(DesignSystem.Colors.background)
    }
    
    // MARK: - Album Art Section
    private var albumArtSection: some View {
        VStack {
            Spacer()
            
            // 专辑封面 - 使用 Spotify 数据或模拟数据
            if let spotifyTrack = appState.currentSpotifyTrack,
               let albumImageURL = spotifyTrack.albumImageURL {
                // 显示 Spotify 专辑封面
                AsyncImage(url: URL(string: albumImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    // 加载中占位符
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.highlightBackground))
                        .frame(
                            width: DesignSystem.Components.AlbumArt.size,
                            height: DesignSystem.Components.AlbumArt.size
                        )
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Components.AlbumArt.cornerRadius)
                                .fill(DesignSystem.Colors.background)
                        )
                }
                .frame(
                    width: DesignSystem.Components.AlbumArt.size,
                    height: DesignSystem.Components.AlbumArt.size
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Components.AlbumArt.cornerRadius))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
            } else {
                // 默认占位符封面
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
                    .frame(
                        width: DesignSystem.Components.AlbumArt.size,
                        height: DesignSystem.Components.AlbumArt.size
                    )
                    .overlay(
                        Image(systemName: DesignSystem.Icons.music)
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(DesignSystem.Colors.background)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Track Info Section
    private var trackInfoSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // 优先显示 Spotify 歌曲信息，否则使用 AppState 信息
            if let spotifyTrack = appState.currentSpotifyTrack {
                // Spotify 歌曲信息
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
            
            // 连接状态指示 (仅在开发模式显示)
            if appState.isSpotifyConnected {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Spotify")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // 进度条
            ProgressBarView(
                progress: appState.playbackProgress,
                duration: appState.duration
            )
            .padding(.horizontal, DesignSystem.Components.Scrubber.padding)
            
            // 时间显示
            HStack {
                Text(formatTime(appState.currentTime))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.text.opacity(0.7))
                
                Spacer()
                
                Text(formatTime(appState.duration))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.text.opacity(0.7))
            }
            .padding(.horizontal, DesignSystem.Components.Scrubber.padding)
        }
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Progress Bar Component
struct ProgressBarView: View {
    let progress: Double
    let duration: TimeInterval
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                RoundedRectangle(cornerRadius: DesignSystem.Components.Scrubber.trackHeight / 2)
                    .fill(DesignSystem.Colors.divider.opacity(0.3))
                    .frame(height: DesignSystem.Components.Scrubber.trackHeight)
                
                // 进度填充
                RoundedRectangle(cornerRadius: DesignSystem.Components.Scrubber.trackHeight / 2)
                    .fill(DesignSystem.Colors.highlightBackground)
                    .frame(
                        width: geometry.size.width * CGFloat(progress),
                        height: DesignSystem.Components.Scrubber.trackHeight
                    )
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .frame(height: DesignSystem.Components.Scrubber.trackHeight)
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