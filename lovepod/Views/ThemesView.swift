// lovepod/Views/ThemesView.swift
// 主题选择界面实现，包含左右分屏的主题选项布局
// 左侧显示主题列表，右侧显示对应的预览效果

import SwiftUI

struct ThemesView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedThemeIndex: Int = 0
    
    private let themes = [
        ThemeModel(name: "Classic", description: "Original iPod", color: .white),
        ThemeModel(name: "Black", description: "Dark variant", color: .black),
        ThemeModel(name: "Retro", description: "Vintage style", color: .brown),
        ThemeModel(name: "Neon", description: "Bright colors", color: .cyan)
    ]
    
    var body: some View {
        HStack(spacing: 1) {
            // 左侧主题列表
            themeListView
                .frame(maxWidth: .infinity)
            
            // 分割线
            Rectangle()
                .fill(DesignSystem.Colors.divider)
                .frame(width: 1)
            
            // 右侧预览效果
            themePreviewView
                .frame(maxWidth: .infinity)
        }
        .background(DesignSystem.Colors.background)
    }
    
    // MARK: - Theme List View
    private var themeListView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Components.MenuList.itemSpacing) {
            ForEach(themes.indices, id: \.self) { index in
                let theme = themes[index]
                let isSelected = index == selectedThemeIndex
                
                HStack {
                    // 选中箭头
                    if isSelected {
                        Image(systemName: "arrowtriangle.right.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text)
                    } else {
                        // 占位空间保持对齐
                        Color.clear
                            .frame(width: 12, height: 12)
                    }
                    
                    // 主题名称
                    Text(theme.name)
                        .font(DesignSystem.Typography.menuItem)
                        .foregroundColor(isSelected ? DesignSystem.Colors.text : DesignSystem.Colors.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 当前使用标识
                    if theme.name == appState.selectedTheme {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.highlightBackground)
                    }
                }
                .frame(minHeight: DesignSystem.Components.MenuList.itemMinHeight)
                .padding(.horizontal, DesignSystem.Components.MenuList.paddingHorizontal)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .fill(isSelected ? DesignSystem.Colors.highlightBackground : Color.clear)
                )
                .foregroundColor(isSelected ? DesignSystem.Colors.highlightText : DesignSystem.Colors.text)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Components.MenuList.paddingVertical)
    }
    
    // MARK: - Theme Preview View
    private var themePreviewView: some View {
        VStack {
            Spacer()
            
            // 主题预览
            if selectedThemeIndex < themes.count {
                let selectedTheme = themes[selectedThemeIndex]
                
                VStack(spacing: DesignSystem.Spacing.m) {
                    // 迷你iPod预览
                    miniPodPreview(theme: selectedTheme)
                    
                    // 主题信息
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text(selectedTheme.name)
                            .font(DesignSystem.Typography.nowPlayingTrack)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Text(selectedTheme.description)
                            .font(DesignSystem.Typography.nowPlayingArtist)
                            .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Mini Pod Preview
    private func miniPodPreview(theme: ThemeModel) -> some View {
        VStack(spacing: 4) {
            // 迷你屏幕
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.color == .black ? Color.gray.opacity(0.2) : Color.white)
                .frame(width: 60, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Text("iPod")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(theme.color == .black ? Color.white : Color.black)
                )
            
            // 迷你转盘
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            theme.color.opacity(0.8),
                            theme.color.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                )
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Theme Model
struct ThemeModel {
    let name: String
    let description: String
    let color: Color
}

// MARK: - Preview
#Preview {
    iPodLayout {
        ThemesView()
    }
    .environmentObject(AppState.shared)
}