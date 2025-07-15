// lovepod/Views/PlaylistView.swift  
// 播放列表界面实现，包含横向Cover Flow布局
// 使用混合授权系统显示用户的Spotify播放列表

import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var spotifyService: SpotifyService
    @EnvironmentObject var tokenManager: SpotifyTokenManager
    @EnvironmentObject var playlistService: SpotifyPlaylistService
    
    var body: some View {
        VStack(spacing: 0) {
            // 使用新的授权状态检查
            if !tokenManager.canReadData {
                spotifyAuthView
                    .frame(maxHeight: .infinity)
            } else if appState.spotifyPlaylists.isEmpty && !playlistService.isLoading {
                // 如果已授权但没有 Spotify 播放列表，显示加载按钮
                loadPlaylistsView
                    .frame(maxHeight: .infinity)
            } else {
                // Cover Flow 区域
                coverFlowView
                    .frame(maxHeight: .infinity)
                
                // 播放列表信息区域
                playlistInfoView
                    .frame(height: 80)
            }
        }
        .background(DesignSystem.Colors.background)
        .onAppear {
            print("🎨 PlaylistView using AppState: \(appState.instanceID)")
            // 如果已授权但没有 Spotify 播放列表，自动加载
            if tokenManager.canReadData && appState.spotifyPlaylists.isEmpty {
                print("📱 PlaylistView onAppear: triggering playlist refresh")
                print("📱 Current state - canReadData: \(tokenManager.canReadData), spotifyPlaylists.count: \(appState.spotifyPlaylists.count)")
                playlistService.refreshPlaylists()
            } else {
                print("📱 PlaylistView onAppear: no refresh needed")
                print("📱 Current state - canReadData: \(tokenManager.canReadData), spotifyPlaylists.count: \(appState.spotifyPlaylists.count)")
                // 应用智能默认选中逻辑
                if !appState.spotifyPlaylists.isEmpty {
                    appState.applySmartPlaylistSelection()
                }
            }
        }
    }
    
    // MARK: - Spotify Auth View
    private var spotifyAuthView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.highlightBackground)
            
            Text("Connect to Spotify")
                .font(DesignSystem.Typography.menuItem)
                .foregroundColor(DesignSystem.Colors.text)
            
            Text("Tap MENU + Center button\nto authorize")
                .font(DesignSystem.Typography.nowPlayingArtist)
                .foregroundColor(DesignSystem.Colors.text.opacity(0.7))
                .multilineTextAlignment(.center)
            
            // 显示当前授权状态
            Text(tokenManager.authenticationStatus.description)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.text.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Load Playlists View
    private var loadPlaylistsView: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            if playlistService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.highlightBackground))
                    .scaleEffect(1.5)
                
                Text("Loading playlists...")
                    .font(DesignSystem.Typography.nowPlayingArtist)
                    .foregroundColor(DesignSystem.Colors.text.opacity(0.7))
            } else {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.highlightBackground)
                
                Text("No playlists found")
                    .font(DesignSystem.Typography.menuItem)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Text("Tap Center button to reload")
                    .font(DesignSystem.Typography.nowPlayingArtist)
                    .foregroundColor(DesignSystem.Colors.text.opacity(0.7))
            }
        }
    }

    // MARK: - Cover Flow View
    private var coverFlowView: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 20) {
                        // 使用 Spotify 播放列表
                        ForEach(appState.spotifyPlaylists.indices, id: \.self) { index in
                            let playlist = appState.spotifyPlaylists[index]
                            let isSelected = index == appState.selectedPlaylistIndex
                            
                            spotifyPlaylistCover(playlist: playlist, isSelected: isSelected)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, geometry.size.width / 2 - 75) // Center the selected item
                }
                .onChange(of: appState.shouldScrollToPlaylist) { _, shouldScroll in
                    // 监听滚动触发标志 - 优先级最高
                    if shouldScroll {
                        let targetIndex = appState.selectedPlaylistIndex
                        let playlistCount = appState.spotifyPlaylists.count
                        
                        print("📜 ScrollViewReader: Attempting to scroll to index \(targetIndex) of \(playlistCount) playlists")
                        
                        if targetIndex < playlistCount && targetIndex >= 0 {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo(targetIndex, anchor: .center)
                            }
                            print("✅ ScrollViewReader: Scroll animation triggered for index \(targetIndex)")
                        } else {
                            print("❌ ScrollViewReader: Invalid index \(targetIndex) for \(playlistCount) playlists")
                        }
                    }
                }
                .onChange(of: appState.selectedPlaylistIndex) { _, newIndex in
                    // 简化的索引变化处理 - 只处理转盘导航时的滚动
                    let playlistCount = appState.spotifyPlaylists.count
                    guard playlistCount > 0 else { return }
                    
                    // 只在有效范围内且不是智能选中触发时滚动
                    if newIndex >= 0 && newIndex < playlistCount && !appState.shouldScrollToPlaylist {
                        print("🎡 Manual navigation: Scrolling to index \(newIndex)")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .onAppear {
            print("🎨 Cover Flow rendering with \(appState.spotifyPlaylists.count) Spotify playlists")
            for (index, playlist) in appState.spotifyPlaylists.enumerated() {
                print("  \(index): \(playlist.name) - Image: \(playlist.imageURL ?? "nil")")
            }
            
            // 确保在 Cover Flow 显示时应用智能选中逻辑
            if !appState.spotifyPlaylists.isEmpty {
                appState.applySmartPlaylistSelection()
            }
        }
    }
    
    // MARK: - Spotify Playlist Cover
    private func spotifyPlaylistCover(playlist: SpotifyPlaylist, isSelected: Bool) -> some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            let coverSize: CGFloat = isSelected ? 150 : 120
            let imageURL = playlist.imageURL
            
            // Spotify 播放列表封面
            AsyncImage(url: URL(string: imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .onAppear {
                            if isSelected {
                                print("✅ Successfully loaded image for playlist: \(playlist.name)")
                                print("✅ Image loaded from URL: \(imageURL ?? "unknown")")
                            }
                        }
                case .failure(let error):
                    // 失败时的占位符
                    RoundedRectangle(cornerRadius: DesignSystem.Components.AlbumArt.cornerRadius)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.3),
                                    Color.red.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: isSelected ? 40 : 32, weight: .light))
                                .foregroundColor(DesignSystem.Colors.background)
                        )
                        .onAppear {
                            if isSelected {
                                print("❌ Failed to load image for playlist: \(playlist.name)")
                                print("❌ URL attempted: \(imageURL ?? "nil")")
                                print("❌ Error: \(error.localizedDescription)")
                                print("❌ Error details: \(error)")
                            }
                        }
                case .empty:
                    // 加载中或无封面时的占位符
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
                                .font(.system(size: isSelected ? 40 : 32, weight: .light))
                                .foregroundColor(DesignSystem.Colors.background)
                        )
                        .onAppear {
                            if isSelected {
                                print("🔄 Loading image for playlist: \(playlist.name)")
                                print("🔄 Attempting to load URL: \(imageURL ?? "nil")")
                            }
                        }
                @unknown default:
                    // 默认占位符
                    RoundedRectangle(cornerRadius: DesignSystem.Components.AlbumArt.cornerRadius)
                        .fill(DesignSystem.Colors.highlightBackground.opacity(0.6))
                        .overlay(
                            Image(systemName: DesignSystem.Icons.music)
                                .font(.system(size: isSelected ? 40 : 32, weight: .light))
                                .foregroundColor(DesignSystem.Colors.background)
                        )
                }
            }
            .frame(width: coverSize, height: coverSize)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Components.AlbumArt.cornerRadius))
            .shadow(
                color: Color.black.opacity(isSelected ? 0.3 : 0.1),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(isSelected ? 1.0 : 0.8)
        }
        .animation(.easeInOut(duration: 0.3), value: isSelected)
        .onAppear {
            if isSelected {
                print("🖼️ Rendering cover for selected playlist: \(playlist.name)")
                print("🖼️ Image URL: \(playlist.imageURL ?? "nil")")
                print("🖼️ Images array count: \(playlist.images.count)")
                if !playlist.images.isEmpty {
                    print("🖼️ First image details: \(playlist.images[0])")
                }
                
                // 验证URL格式
                if let imageURL = playlist.imageURL {
                    if let url = URL(string: imageURL) {
                        print("✅ Valid URL created: \(url)")
                    } else {
                        print("❌ Failed to create URL from string: \(imageURL)")
                    }
                } else {
                    print("❌ No image URL available for playlist: \(playlist.name)")
                }
            }
        }
    }
    
    // MARK: - Legacy Playlist Cover
    private func playlistCover(playlist: PlaylistModel, isSelected: Bool) -> some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            // 专辑封面占位符 (用于向后兼容)
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
                    width: isSelected ? 150 : 120,
                    height: isSelected ? 150 : 120
                )
                .overlay(
                    Image(systemName: DesignSystem.Icons.music)
                        .font(.system(size: isSelected ? 40 : 32, weight: .light))
                        .foregroundColor(DesignSystem.Colors.background)
                )
                .shadow(
                    color: Color.black.opacity(isSelected ? 0.3 : 0.1),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
                .scaleEffect(isSelected ? 1.0 : 0.8)
        }
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
    
    // MARK: - Playlist Info View
    private var playlistInfoView: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // 只显示 Spotify 播放列表信息
            if !appState.spotifyPlaylists.isEmpty && appState.selectedPlaylistIndex < appState.spotifyPlaylists.count {
                let selectedPlaylist = appState.spotifyPlaylists[appState.selectedPlaylistIndex]
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    // Spotify 播放列表名称
                    Text(selectedPlaylist.name)
                        .font(DesignSystem.Typography.nowPlayingTrack)
                        .foregroundColor(DesignSystem.Colors.text)
                        .lineLimit(1)
                    
                    // 歌曲数量信息
                    Text(selectedPlaylist.trackCountDescription)
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.7))
                    
                    // 所有者信息 (如果有)
                    if let ownerName = selectedPlaylist.owner.displayName {
                        Text("by \(ownerName)")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.text.opacity(0.5))
                    }
                    
                    // 显示当前播放状态指示器
                    if let currentTrack = appState.currentSpotifyTrack,
                       let currentPlaylistUri = extractPlaylistUri(from: currentTrack.uri),
                       currentPlaylistUri == selectedPlaylist.uri {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.highlightBackground)
                            Text("Now Playing")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.highlightBackground)
                        }
                    }
                }
                .onAppear {
                    print("🎵 PlaylistInfoView: Displaying \(selectedPlaylist.name)")
                }
            } else {
                // 只在真正无数据或加载中时显示占位符
                if playlistService.isLoading {
                    Text("Loading playlist...")
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.5))
                        .onAppear {
                            print("🎵 PlaylistInfoView: Loading playlists...")
                        }
                } else if appState.spotifyPlaylists.isEmpty {
                    Text("No playlists available")
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.5))
                        .onAppear {
                            print("🎵 PlaylistInfoView: No Spotify playlists available")
                        }
                } else {
                    // 避免显示 loading 文本
                    Text("")
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.5))
                        .onAppear {
                            print("🎵 PlaylistInfoView: Index out of bounds (count: \(appState.spotifyPlaylists.count), selectedIndex: \(appState.selectedPlaylistIndex))")
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignSystem.Spacing.m)
    }
    
    // 辅助方法：从track URI中提取playlist URI
    private func extractPlaylistUri(from trackUri: String) -> String? {
        // 由于SDK限制，我们使用简单的字符串匹配
        // 实际应用中可能需要更复杂的逻辑
        return nil
    }
}

// MARK: - Preview
#Preview {
    iPodLayout {
        PlaylistView()
    }
    .environmentObject(AppState.shared)
}