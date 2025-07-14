# Spotify iOS SDK 集成指南

## 步骤 1: 下载 Spotify iOS SDK

1. 访问 [Spotify iOS SDK GitHub](https://github.com/spotify/ios-sdk)
2. 下载最新版本的 `SpotifyiOS.framework`
3. 将下载的 framework 保存到项目根目录的 `Frameworks` 文件夹中

## 步骤 2: 在 Xcode 中添加 Framework

1. 在 Xcode 中打开 `lovepod.xcodeproj`
2. 选择项目导航器中的项目文件 (lovepod)
3. 选择 "lovepod" target
4. 转到 "General" 标签页
5. 在 "Frameworks, Libraries, and Embedded Content" 部分点击 "+"
6. 点击 "Add Other..." → "Add Files..."
7. 导航到并选择 `SpotifyiOS.framework`
8. 确保 "Embed & Sign" 选项被选中

## 步骤 3: 配置 Build Settings

### 3.1 添加 Linker Flag
1. 选择 "lovepod" target
2. 转到 "Build Settings" 标签页
3. 搜索 "Other Linker Flags"
4. 双击并添加 `-ObjC`

### 3.2 设置 Bridging Header
1. 在 "Build Settings" 中搜索 "Objective-C Bridging Header"
2. 设置路径为: `lovepod/lovepod-Bridging-Header.h`

## 步骤 4: 配置 Info.plist

### 4.1 通过 Xcode 界面配置
1. 选择 "lovepod" target
2. 转到 "Info" 标签页
3. 在 "Custom iOS Target Properties" 中添加以下键值：

#### LSApplicationQueriesSchemes
- 右键点击列表，选择 "Add Row"
- 键名: `LSApplicationQueriesSchemes`
- 类型: `Array`
- 添加子项 (String): `spotify`

#### CFBundleURLTypes
- 右键点击列表，选择 "Add Row"
- 键名: `CFBundleURLTypes`
- 类型: `Array`
- 添加子项 (Dictionary)
  - `CFBundleURLName` (String): `com.lovepod.spotify`
  - `CFBundleURLSchemes` (Array)
    - 子项 (String): `lovepod`

### 4.2 Raw XML 格式 (备选方法)
如果需要直接编辑 Info.plist 源码，添加以下内容：

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>spotify</string>
</array>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.lovepod.spotify</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>lovepod</string>
        </array>
    </dict>
</array>
```

## 步骤 5: 创建 Spotify 开发者应用

1. 访问 [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. 登录并创建新应用
3. 记录 `Client ID`
4. 设置 Redirect URI 为: `lovepod://spotify-login-callback`
5. 在应用设置中选择 "iOS" 作为平台

## 步骤 6: 更新 Client ID

在 `SpotifyService.swift` 中更新您的 Client ID：

```swift
private let clientID = "YOUR_ACTUAL_SPOTIFY_CLIENT_ID_HERE"
```

## 步骤 7: 网络权限配置 (可选)

如果需要加载 Spotify 图片，在 Info.plist 中添加网络安全配置：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>scdn.co</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.0</string>
        </dict>
        <key>spotify.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.0</string>
        </dict>
    </dict>
</dict>
```

## 验证集成

完成上述步骤后：

1. 清理并重新构建项目 (⌘+Shift+K, 然后 ⌘+B)
2. 在物理 iOS 设备上运行应用 (Spotify SDK 需要真实设备)
3. 确保设备上已安装 Spotify 应用
4. 测试授权流程

## 故障排除

### 常见问题:
- **"SpotifyiOS.h file not found"**: 检查 framework 是否正确添加到项目中
- **链接错误**: 确保添加了 `-ObjC` linker flag
- **授权失败**: 检查 Bundle ID 和 Redirect URI 是否匹配
- **无法连接**: 确保在真实设备上测试，且已安装 Spotify 应用

### 调试提示:
- 查看 Xcode 控制台的详细错误信息
- 确认 Client ID 和 Redirect URI 配置正确
- 检查设备上的网络连接

---

⚠️ **重要提醒**: 
- Spotify iOS SDK 只能在真实的 iOS 设备上工作
- 确保设备上安装了最新版本的 Spotify 应用
- 应用必须在 Spotify Developer Dashboard 中注册