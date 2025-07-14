// lovepod/Views/SettingsView.swift
// 设置界面实现，包含左右分屏的设置选项布局
// 左侧显示设置项列表，右侧显示对应的图标预览

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 1) {
            // 左侧设置列表
            settingsListView
                .frame(maxWidth: .infinity)
            
            // 分割线
            Rectangle()
                .fill(DesignSystem.Colors.divider)
                .frame(width: 1)
            
            // 右侧图标预览
            iconPreviewView
                .frame(maxWidth: .infinity)
        }
        .background(DesignSystem.Colors.background)
    }
    
    // MARK: - Settings List View
    private var settingsListView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Components.MenuList.itemSpacing) {
            ForEach(SettingsMenuItem.allCases.indices, id: \.self) { index in
                let menuItem = SettingsMenuItem.allCases[index]
                let isSelected = index == appState.selectedSettingsMenuItem
                
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
                    
                    // 设置项文本
                    Text(menuItem.title)
                        .font(DesignSystem.Typography.menuItem)
                        .foregroundColor(isSelected ? DesignSystem.Colors.text : DesignSystem.Colors.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    // MARK: - Icon Preview View
    private var iconPreviewView: some View {
        VStack {
            Spacer()
            
            // 显示当前选中项的图标和描述
            if let selectedItem = SettingsMenuItem(rawValue: appState.selectedSettingsMenuItem) {
                VStack(spacing: DesignSystem.Spacing.s) {
                    Image(systemName: selectedItem.icon)
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
                    
                    Text(selectedItem.title)
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
                    
                    // 设置项描述
                    Text(settingsDescription(for: selectedItem))
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.s)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    private func settingsDescription(for item: SettingsMenuItem) -> String {
        switch item {
        case .themes:
            return "Change iPod style"
        case .upgrade:
            return "Get premium features"
        case .about:
            return "App information"
        case .privacy:
            return "Privacy settings"
        }
    }
}

// MARK: - Preview
#Preview {
    iPodLayout {
        SettingsView()
    }
    .environmentObject(AppState.shared)
}