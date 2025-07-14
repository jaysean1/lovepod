// lovepod/Views/HomeView.swift
// 主页界面实现，包含左右分屏的菜单布局
// 左侧显示菜单项列表，右侧显示对应的图标预览

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 1) {
            // 左侧菜单列表
            menuListView
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
    
    // MARK: - Menu List View
    private var menuListView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Components.MenuList.itemSpacing) {
            ForEach(HomeMenuItem.allCases.indices, id: \.self) { index in
                let menuItem = HomeMenuItem.allCases[index]
                let isSelected = index == appState.selectedHomeMenuItem
                
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
                    
                    // 菜单项文本
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
            
            // 显示当前选中项的图标
            if let selectedItem = HomeMenuItem(rawValue: appState.selectedHomeMenuItem) {
                VStack(spacing: DesignSystem.Spacing.s) {
                    Image(systemName: selectedItem.icon)
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
                    
                    Text(selectedItem.title)
                        .font(DesignSystem.Typography.nowPlayingArtist)
                        .foregroundColor(DesignSystem.Colors.text.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    iPodLayout {
        HomeView()
    }
    .environmentObject(AppState.shared)
}