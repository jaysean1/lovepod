# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LovePod 是一个基于 SwiftUI 的 iOS 应用，重现经典 iPod 用户体验和视觉设计，集成 Spotify 服务。项目采用模块化架构，使用现代 SwiftUI 技术栈实现复古交互体验。

## Development Commands

### Build and Run
```bash
# 在 iPhone16 模拟器中构建和运行项目
xcodebuild -scheme lovepod -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build

# 使用 Xcode 打开项目
open lovepod.xcodeproj

# 清理构建缓存
xcodebuild clean -scheme lovepod

# 构建并运行到指定模拟器
xcodebuild -scheme lovepod -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build test
```

### Testing
```bash
# 运行单元测试
xcodebuild test -scheme lovepod -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16'

# 运行 UI 测试
xcodebuild test -scheme lovepod -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:lovepodUITests
```

### Development Device Requirements
- **推荐开发设备**: iPhone16 模拟器
- **Spotify 功能测试**: 需要真实 iOS 设备（Spotify SDK 要求）
- **iOS 版本要求**: iOS 15.0+
- **Xcode 版本**: Xcode 14.0+

## Architecture Overview

### Core Components Structure
```
lovepod/
├── lovepodApp.swift              # 应用入口，处理 Spotify 授权回调和生命周期
├── AppState.swift                # 全局状态管理（ObservableObject + Combine）
├── iPodLayout.swift              # 主要布局容器（屏幕区域 + 转盘控制区域）
├── ContentView.swift             # 应用入口视图
├── DesignSystem.swift            # 设计系统（颜色、字体、间距等）
├── HapticManager.swift           # 触觉反馈管理器
├── Views/                        # 页面视图组件
├── Spotify Services/             # Spotify 集成服务层
└── Assets.xcassets/             # 应用资源
```

### State Management Architecture
- **AppState**: 单例模式管理全局状态，使用 `@Published` 属性和 Combine 实现响应式 UI
- **Navigation**: 基于枚举的页面状态管理 (`NavigationPage`)
- **Spotify Integration**: 多服务协作模式（iOS SDK + Web API 双重授权）

### Key Design Patterns
- **MVVM**: View + ViewModel (AppState) + Model (Spotify Models)
- **Dependency Injection**: 服务通过 `@EnvironmentObject` 注入
- **Observer Pattern**: 使用 Combine 框架进行状态订阅

## File Header Requirements

根据项目规范，EVERY 文件都必须以 3 个注释开头：
1. 第一个注释：文件路径位置，格式：`// location/file-name.swift`
2. 第二、三个注释：文件用途的清晰描述，说明该文件的作用和责任边界

示例：
```swift
// lovepod/AppState.swift
// 应用状态管理类，使用ObservableObject来管理应用的全局状态
// 包含页面导航、选中状态、播放状态等核心应用状态
```

注意：某些文件类型不需要 header comments，如 .md、.txt、.json 文件等。

## Spotify Integration

### Prerequisites
- Spotify iOS SDK 3.0.0 已集成在 `Frameworks/` 目录
- Client ID 需要在 `SpotifyService.swift` 中配置
- Bundle URL Scheme: `lovepod://`

### Authorization Flow
1. **iOS SDK Authorization**: 用于播放控制和实时状态
2. **Web API Authorization**: 用于获取播放列表和用户数据
3. **混合模式**: 应用同时使用两种授权方式

### Development Notes
- Spotify SDK 只能在真实设备上工作
- 需要安装 Spotify 官方应用
- Web API 调用需要有效的 access token

## Key Service Classes

### AppState (Singleton)
全局状态管理中心，负责：
- 页面导航状态
- 音乐播放状态
- Spotify 数据同步
- UI 状态协调

### SpotifyService
iOS SDK 集成服务，处理：
- 用户授权
- 音乐播放控制
- 实时播放状态

### SpotifyWebAPIManager
Web API 集成服务，负责：
- 获取用户播放列表
- 播放上下文检查
- 扩展音乐数据

### SpotifyPlaylistService
播放列表管理服务：
- 数据获取和缓存
- AppState 集成
- 错误处理

## UI Component Guidelines

### Layout Structure
应用采用经典 iPod 布局：
- **上半部分 (50%)**: 内容显示区域
- **下半部分 (50%)**: 转盘控制区域
- **状态栏**: 页面标题 + 电池图标

### Interaction Patterns
- **转盘旋转**: 菜单选择、进度控制
- **中央按钮**: 确认、播放/暂停
- **方向按钮**: 上下首、快进快退
- **MENU 按钮**: 返回上级页面

### Theme System
基于 `DesignSystem.swift` 的主题系统：
- Classic (经典白色)
- Black (黑色版本)
- Retro (复古配色)
- Neon (霓虹色彩)

## Development Workflow

### Phase-Based Development
项目按阶段开发：
1. **Phase 1**: 核心 UI 框架 ✅
2. **Phase 2**: 交互和导航 ✅  
3. **Phase 3**: 服务集成 🔄
4. **Phase 4**: 高级功能和优化

### Testing Strategy
- **单元测试**: `lovepodTests/`
- **UI测试**: `lovepodUITests/`
- **真实设备测试**: Spotify 功能验证

## Debugging and Troubleshooting

### Common Issues
- **Spotify SDK 连接失败**: 确保在真实设备上测试
- **权限错误**: 检查 Web API token 有效性
- **UI 状态不同步**: 验证 AppState 连接

### Debug Tools
- Xcode Console 日志
- AppState instanceID 追踪
- Spotify 服务状态监控

### Performance Considerations
- 避免频繁的 API 调用
- 使用本地状态缓存
- 优化图片加载和缓存

## Documentation References

Key documentation files:
- `doc/requirement/prd.md` - 产品需求文档
- `doc/plan/development_plan.md` - 开发计划
- `doc/tech/SPOTIFY_INTEGRATION_GUIDE.md` - Spotify 集成指南
- `README.md` - 项目概览和使用说明

## Important Notes

- 开发时使用 iPhone16 模拟器
- Spotify 功能必须在真实设备上测试
- 遵循 Header Comments 规范
- 优先使用现有组件，避免重复造轮
- 保持 AppState 单例模式的完整性