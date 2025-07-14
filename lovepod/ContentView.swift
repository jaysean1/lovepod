// lovepod/ContentView.swift
// 主应用入口视图，使用iPod布局包装器
// 根据应用状态显示不同的页面内容

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var spotifyService: SpotifyService
    @EnvironmentObject var playlistService: SpotifyPlaylistService
    
    var body: some View {
        iPodLayout {
            NavigationContentView()
        }
        .onAppear {
            // 将 Spotify 服务连接到 AppState
            appState.setSpotifyService(spotifyService)
            appState.setPlaylistService(playlistService)
        }
    }
}

// MARK: - Navigation Content View
struct NavigationContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            switch appState.currentPage {
            case .home:
                HomeView()
            case .playlist:
                PlaylistView()
            case .nowPlaying:
                NowPlayingView()
            case .settings:
                SettingsView()
            case .themes:
                ThemesView()
            case .upgrade:
                UpgradeView()
            case .user:
                UserView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentPage)
    }
}

// MARK: - Placeholder Views (to be implemented)
// Note: HomeView is now implemented in Views/HomeView.swift
// Note: PlaylistView is now implemented in Views/PlaylistView.swift
// Note: NowPlayingView is now implemented in Views/NowPlayingView.swift
// Note: SettingsView is now implemented in Views/SettingsView.swift
// Note: ThemesView is now implemented in Views/ThemesView.swift

struct UpgradeView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Colors.highlightBackground)
            
            Text("Upgrade to Pro")
                .font(DesignSystem.Typography.menuItem)
                .foregroundColor(DesignSystem.Colors.text)
            
            Text("Premium features coming soon")
                .font(DesignSystem.Typography.nowPlayingArtist)
                .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
        }
    }
}

struct UserView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
            
            Text("User Profile")
                .font(DesignSystem.Typography.menuItem)
                .foregroundColor(DesignSystem.Colors.text)
            
            Text("Profile features coming soon")
                .font(DesignSystem.Typography.nowPlayingArtist)
                .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
        }
    }
}

#Preview {
    ContentView()
}
