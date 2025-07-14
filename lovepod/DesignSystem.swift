// lovepod/DesignSystem.swift
// 设计系统文件，基于design.json定义了应用的视觉设计规范
// 包含颜色、间距、字体、布局等所有设计相关的常量和组件

import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        static let background = Color.white
        static let text = Color.black
        static let highlightBackground = Color(red: 0.204, green: 0.471, blue: 0.965)
        static let highlightText = Color.white
        static let statusBarBackground = Color(red: 0.941, green: 0.941, blue: 0.941)
        static let statusBarText = Color.black
        static let divider = Color(red: 0.784, green: 0.780, blue: 0.800)
    }
    
    // MARK: - Spacing
    struct Spacing {
        private static let baseUnit: CGFloat = 8
        
        static let xxs: CGFloat = baseUnit * 0.25  // 2pt
        static let xs: CGFloat = baseUnit * 0.5    // 4pt
        static let s: CGFloat = baseUnit * 1       // 8pt
        static let m: CGFloat = baseUnit * 1.5     // 12pt
        static let l: CGFloat = baseUnit * 2       // 16pt
        static let xl: CGFloat = baseUnit * 3      // 24pt
    }
    
    // MARK: - Typography
    struct Typography {
        static let fontFamily = "Helvetica Neue"
        
        struct Scale {
            static let body: CGFloat = 16
            static let caption: CGFloat = 14
            static let subtitle: CGFloat = 14
            static let title: CGFloat = 18
        }
        
        struct Weights {
            static let normal: Font.Weight = .regular
            static let bold: Font.Weight = .bold
        }
        
        // Predefined text styles
        static let statusBar = Font.custom(fontFamily, size: Scale.caption).weight(Weights.bold)
        static let menuItem = Font.custom(fontFamily, size: Scale.body).weight(Weights.bold)
        static let nowPlayingTrack = Font.custom(fontFamily, size: Scale.body).weight(Weights.normal)
        static let nowPlayingArtist = Font.custom(fontFamily, size: Scale.subtitle).weight(Weights.normal)
    }
    
    // MARK: - Layout
    struct Layout {
        static let cornerRadius: CGFloat = Spacing.s
        
        // Screen proportions
        static let headerHeight: CGFloat = 0.1     // 10%
        static let contentHeight: CGFloat = 0.9    // 90%
        static let screenHeight: CGFloat = 0.5     // 50% for screen area
        static let controlHeight: CGFloat = 0.5    // 50% for control area
        
        // Menu split view
        static let menuWidth: CGFloat = 0.5        // 50%
        static let contentWidth: CGFloat = 0.5     // 50%
        
        // Now playing layout
        static let albumArtHeight: CGFloat = 0.45  // 45%
        static let trackInfoHeight: CGFloat = 0.25 // 25%
        static let scrubberHeight: CGFloat = 0.20  // 20%
        
        // Click wheel dimensions
        static let wheelDiameterRatio: CGFloat = 0.7    // 70% of screen width
        static let centerButtonRatio: CGFloat = 0.35    // 35% of wheel diameter
    }
    
    // MARK: - Components
    struct Components {
        
        // Status bar styling
        struct StatusBar {
            static let paddingHorizontal = Spacing.m
            static let height: CGFloat = 30
        }
        
        // Menu list styling
        struct MenuList {
            static let paddingVertical = Spacing.s
            static let paddingHorizontal = Spacing.m
            static let itemSpacing = Spacing.xs
            static let itemMinHeight: CGFloat = 44
        }
        
        // Album art styling
        struct AlbumArt {
            static let aspectRatio: CGFloat = 1.0
            static let marginVertical = Spacing.m
            static let cornerRadius = Spacing.xs
            static let size: CGFloat = 200  // 200x200pt as specified in PRD
        }
        
        // Progress bar/scrubber styling
        struct Scrubber {
            static let padding = Spacing.m
            static let trackHeight = Spacing.xs
            static let thumbSize = Spacing.m
        }
    }
    
    // MARK: - Iconography
    struct Icons {
        static let size: CGFloat = Typography.Scale.body * 1.2
        
        // System icons used in the app
        static let play = "play.fill"
        static let pause = "pause.fill"
        static let forward = "forward.fill"
        static let backward = "backward.fill"
        static let battery = "battery.100"
        static let music = "music.note"
        static let photo = "photo"
        static let video = "video"
        static let settings = "gearshape.fill"
        static let user = "person.fill"
        static let playlist = "music.note.list"
    }
}

// MARK: - Custom Modifiers
extension View {
    func iPodStatusBarStyle() -> some View {
        self
            .font(DesignSystem.Typography.statusBar)
            .foregroundColor(DesignSystem.Colors.statusBarText)
            .padding(.horizontal, DesignSystem.Components.StatusBar.paddingHorizontal)
    }
    
    func iPodMenuItemStyle(isSelected: Bool = false) -> some View {
        self
            .font(DesignSystem.Typography.menuItem)
            .foregroundColor(isSelected ? DesignSystem.Colors.highlightText : DesignSystem.Colors.text)
            .padding(.vertical, DesignSystem.Components.MenuList.paddingVertical)
            .padding(.horizontal, DesignSystem.Components.MenuList.paddingHorizontal)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(isSelected ? DesignSystem.Colors.highlightBackground : Color.clear)
            )
    }
    
    func iPodScreenContainer() -> some View {
        self
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}