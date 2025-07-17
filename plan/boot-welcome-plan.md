# LovePod 开机欢迎界面实施计划

## 1. 需求 (Requirements)

- **目标**: 在应用启动时，显示一个复古风格的欢迎界面（Splash Screen），以改善用户体验并处理初始加载时间。
- **核心功能**:
    - 界面应在应用启动后立即显示。
    - 界面中央需要有应用的Logo或一个代表性的图标。
    - Logo下方应有文本，显示当前的加载状态（例如，“正在连接Spotify...”、“正在加载播放列表...”）。
    - 加载状态文本需要能动态更新。
    - 所有核心服务（如`AppState`初始化、Spotify连接）加载完毕后，欢迎界面应平滑过渡到应用主界面。
    - 界面设计需与应用整体的复古iPod风格和主题系统保持一致。

## 2. 设计 (Design)

- **组件化设计**:
    - 创建一个新的SwiftUI视图 `WelcomeView.swift`，专门用于渲染欢迎界面。这个视图将是“哑”的，只负责根据外部传入的状态显示UI。
- **状态管理驱动**:
    - UI的显示逻辑将完全由全局状态管理器 `AppState.swift` 控制。
    - 在 `AppState` 中引入两个新的 `@Published` 属性：
        1. `isLoading: Bool`：一个布尔值，用于决定是显示 `WelcomeView` (`true`) 还是主应用界面 `iPodLayout` (`false`)。
        2. `loadingStatus: String`：一个字符串，用于在 `WelcomeView` 上显示当前的加载状态。
- **视图切换逻辑**:
    - 在应用的根视图 `ContentView.swift` 中，通过判断 `appState.isLoading` 的值，来动态地渲染 `WelcomeView` 或 `iPodLayout`。
    - 使用SwiftUI的 `.transition()` 和 `.animation()` 修饰符来实现两个视图之间的平滑淡入淡出效果。
- **初始化流程**:
    - 在 `AppState` 的 `init()` 方法或一个专门的 `startInitializationProcess()` 方法中，编排整个应用的启动任务序列。
    - 在这个流程中，按顺序执行任务（如连接Spotify、获取数据等），并同步更新 `loadingStatus` 文本。
    - 当所有任务完成后，将 `isLoading` 设置为 `false`，从而触发UI切换。

## 3. 任务 (Tasks)

1.  **修改 `AppState`**:
    - 在 `lovepod/AppState.swift` 中添加 `isLoading` 和 `loadingStatus` 两个 `@Published` 属性。
    - 实现 `startInitializationProcess` 方法来管理启动流程和状态更新。

2.  **创建 `WelcomeView`**:
    - 在 `lovepod/Views/` 目录下创建新文件 `WelcomeView.swift`。
    - 设计UI布局，包含一个图标和状态文本。
    - 从 `@EnvironmentObject` 引入 `AppState` 和 `DesignSystem`，确保UI元素（颜色、字体）与当前主题同步。
    - 将UI组件绑定到 `AppState` 的相应属性。

3.  **修改 `ContentView`**:
    - 在 `lovepod/ContentView.swift` 中，实现基于 `appState.isLoading` 的条件渲染逻辑。
    - 添加动画效果以实现平滑过渡。

4.  **集成真实加载逻辑**:
    - 将 `AppState` 中用于演示的模拟加载（`DispatchQueue.main.asyncAfter`）替换为对 `SpotifyService` 等真实服务的调用。
    - 在 `SpotifyService` 的关键初始化步骤中，回调更新 `AppState` 的 `loadingStatus` 和最终的 `isLoading` 状态。

5.  **测试**:
    - 编写UI测试（`lovepodUITests`）来验证欢迎界面是否按预期显示、更新和消失。
    - 在模拟器和真实设备上进行手动测试，确保视觉效果和功能符合要求。

## 4. 总结 (Summary)

此计划旨在通过引入一个由 `AppState` 驱动的 `WelcomeView`，系统性地解决应用启动时的加载体验问题。通过将状态管理与UI分离，我们可以创建一个可维护、可测试且与现有架构高度兼容的解决方案。最终目标是提供一个无缝、美观且信息明确的应用启动过程。
