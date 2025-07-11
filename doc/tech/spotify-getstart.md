Getting Started with iOS SDK
iOS SDK 入门
Welcome! In this Getting Started guide, we will go through how to use the Spotify iOS SDK in your existing Xcode application to integrate:
欢迎！在本入门指南中，我们将介绍如何在您现有的 Xcode 应用程序中使用 Spotify iOS SDK 来集成：

Authentication (via the Spotify Accounts API)
身份验证（通过 Spotify 帐户 API）
Shuffle playback for Spotify Free users
Spotify Free 用户的随机播放
On-demand playback for Spotify Premium users
Spotify Premium 用户的点播播放
Real-time player state updates
实时玩家状态更新
You can read more about the iOS SDK in the overview, or dig into the reference documentation.
您可以在概述中阅读有关 iOS SDK 的更多信息，或者深入了解参考文档 。

Important policy notes  重要政策说明
Streaming applications may not be commercial
流媒体应用程序不得商业化
Keep audio content in its original form
保持音频内容的原始形式
Do not synchronize Spotify content
不同步 Spotify 内容
Spotify content may not be broadcasted
Spotify 内容可能无法播放
Prepare Your Environment  准备您的环境
Register a Developer App  注册开发者应用
Go to the Developer Dashboard and create an app with the following configuration values:
转到开发者仪表板并创建具有以下配置值的应用程序：

Redirect URI: Set this to spotify-ios-quick-start://spotify-login-callback. We'll use this to send users back to your application
重定向 URI：将其设置为 spotify-ios-quick-start://spotify-login-callback 。我们将使用此 URL 将用户返回到您的应用程序
Bundle ID: This is your iOS app bundle identifier, in a format similar to com.spotify.iOS-SDK-Quick-Start.
捆绑包 ID：这是您的 iOS 应用程序捆绑包标识符，格式类似于 com.spotify.iOS-SDK-Quick-Start 。
Which API/SDKs are you planning to use: iOS
您计划使用哪些 API/SDK：iOS
Install the Spotify App  安装 Spotify 应用程序
Install the latest version of Spotify from the Apple App Store on the device you wish to use for this tutorial. Run the Spotify app and be sure to login or register to Spotify on your device.
在本教程中使用的设备上，从 Apple App Store 安装最新版本的 Spotify 。运行 Spotify 应用，并确保已在设备上登录或注册 Spotify。

You must use a physical iOS device to test the iOS SDK as the Spotify app cannot be installed on a simulator. More information on how to install apps here
由于 Spotify 应用无法在模拟器上安装，因此您必须使用实体 iOS 设备来测试 iOS SDK。 更多安装方法，请点击此处。
Download the iOS SDK  下载 iOS SDK
Download the latest version of Spotify's iOS SDK from our GitHub repository. You'll need to add the SpotifyiOS.framework file as a dependency in your iOS project for the next section.
从我们的 GitHub 仓库下载最新版本的 Spotify iOS SDK。您需要将 SpotifyiOS.framework 文件添加为 iOS 项目的依赖项，以便进行下一部分操作。

Set up the iOS SDK
设置 iOS SDK
At this point, we should have the following:
此时，我们应该得到以下内容：

A registered Client ID
注册的客户 ID
A downloaded copy of the Spotify iOS SDK
下载的 Spotify iOS SDK 副本
The latest version of the Spotify app installed on an iOS device
iOS 设备上安装的 Spotify 应用的最新版本
Next we'll focus on installing the SDK inside of an existing Xcode application.
接下来我们将重点介绍在现有 Xcode 应用程序中安装 SDK。

Import SpotifyiOS.framework
导入 SpotifyiOS.framework
You'll need to import the SpotifyiOS.framework. You can simply drag it into your Xcode project.
您需要导入 SpotifyiOS.framework 。您可以直接将其拖到您的 Xcode 项目中。

Configure Info.plist
配置 Info.plist
We'll need to configure our Info.plist to support the iOS SDK. There are two things we need to add:
我们需要配置 Info.plist 来支持 iOS SDK。我们需要添加两件事：

1. Add spotify to LSApplicationQueriesSchemes
1. 将 spotify 添加到 LSApplicationQueriesSchemes
We'll need this to check if the Spotify main application is installed. The LSApplicationQueriesSchemes key in Info.plist allows your application to perform this check. To set this up, add this to your Info.plist:
我们需要它来检查 Spotify 主应用程序是否已安装。 Info.plist 中的 LSApplicationQueriesSchemes 键允许你的应用执行此检查。要进行设置，请将以下内容添加到你的 Info.plist 中：

<key>LSApplicationQueriesSchemes</key>
<array>
  <string>spotify</string>
</array>

2. Add a URI Scheme in CFBundleURLTypes
2. 在 CFBundleURLTypes 中添加 URI Scheme
In order for Spotify to send users back to your application, we need to set up a URI scheme in our Info.plist. To do this, we'll need our Bundle ID and Redirect URI from earlier. From the Redirect URI, we just need the protocol (which for spotify-ios-quick-start://spotify-login-callback would be spotify-ios-quick-start).
为了让 Spotify 将用户带回您的应用程序，我们需要设置 在 Info.plist 中创建一个 URI 方案 。为此，我们需要之前获取的 Bundle ID 和重定向 URI。从重定向 URI 中，我们只需要协议（对于 spotify-ios-quick-start://spotify-login-callback 将是 spotify-ios-quick-start ）。

We'll then need to put our Bundle ID in CFBundleURLName and our Redirect URI protocol in CFBundleURLSchemes:
然后我们需要将 Bundle ID 放入 CFBundleURLName 中，将 Redirect URI 协议放入 CFBundleURLSchemes 中：

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.spotify.iOS-SDK-Quick-Start</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>spotify-ios-quick-start</string>
    </array>
  </dict>
</array>

Set -ObjC Linker Flag
设置 -ObjC 链接器标志
In order to support the iOS SDK, we will need to add the -ObjC linker flag. This allows us to compile the Objective-C code that is contained within the iOS SDK.
为了支持 iOS SDK，我们需要添加 -ObjC 链接器标志。这使我们能够编译 iOS SDK 中包含的 Objective-C 代码。

In XCode, to add the linker flag, we need to do the following:
在 XCode 中，要添加链接器标志，我们需要执行以下操作：

In the File Navigator, click on your project.
在文件导航器中，单击您的项目。
Click your project under Targets
单击 Targets 下的项目
Go to Build Settings
转到 Build Settings
In the search box, enter Other Linker Flags
在搜索框中输入 Other Linker Flags
Besides Other Linker Flags, double click and enter -ObjC
除了 Other Linker Flags 之外，双击并输入 -ObjC
Add Bridging Header  添加桥接头
In the last step, we added the linker flag to compile Objective-C code. Next, we need to add a bridging header, which will allow us to include Objective-C binaries inside of our Swift app.
在上一步中，我们添加了链接器标志来编译 Objective-C 代码。接下来，我们需要添加桥接头文件，以便将 Objective-C 二进制文件引入到我们的 Swift 应用中。

Typically, this is named with the [YourApp]-Bridging-Header.h convention. Xcode may generate this for you, otherwise you will need to create this in the root directory of your project.
通常，其命名约定为 [YourApp]-Bridging-Header.h 可能会为您生成此文件，否则您需要在项目的根目录中创建它。

In your newly created file, you'll need to replace it with the following contents:
在新创建的文件中，您需要将其替换为以下内容：

#import <SpotifyiOS/SpotifyiOS.h>

Then you'll need to set the location of this bridging header by:
然后您需要通过以下方式设置此桥接头的位置：

In the File Navigator, click on your project.
在文件导航器中，单击您的项目。
Click your project under Targets
单击 Targets 下的项目
Go to Build Settings
转到 Build Settings
In the search box, enter Objective-C Bridging Header
在搜索框中输入 Objective-C Bridging Header
Besides Objective-C Bridging Header, double click and enter [YourApp]-Bridging-Header.h
除了 Objective-C Bridging Header 之外，双击并输入 [YourApp]-Bridging-Header.h
Set Up User Authorization
设置用户授权
In order for the iOS SDK to control the Spotify app, they will need to authorize your app.
为了让 iOS SDK 控制 Spotify 应用程序，他们需要授权您的应用程序。

Instantiate SPTConfiguration
实例化 SPTConfiguration
At a class-level, we can define our Client ID, Redirect URI and instantiate the SDK:
在类级别，我们可以定义客户端 ID、重定向 URI 并实例化 SDK：

let SpotifyClientID = "[your spotify client id here]"
let SpotifyRedirectURL = URL(string: "spotify-ios-quick-start://spotify-login-callback")!

lazy var configuration = SPTConfiguration(
  clientID: SpotifyClientID,
  redirectURL: SpotifyRedirectURL
)

Configure Auth Callback  配置身份验证回调
Once a user successfully returns to your application, we'll need to the assign the access token to the appRemote connection parameters
一旦用户成功返回您的应用程序，我们需要将访问令牌分配给 appRemote 连接参数

func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
  let parameters = appRemote.authorizationParameters(from: url);

        if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = access_token
            self.accessToken = access_token
        } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
            // Show the error
        }
  return true
}

If you are using UIScene then you need to use appropriate method in your scene delegate.
如果您正在使用 UIScene，那么您需要在场景委托中使用适当的方法。

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else {
        return
    }

    let parameters = appRemote.authorizationParameters(from: url);

    if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
        appRemote.connectionParameters.accessToken = access_token
        self.accessToken = access_token
    } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
        // Show the error
    }
}

User authorization provides offline support. This means that a user can be authorized even if the device is currently offline. Offline support works out of the box, so it doesn't require any additional implementation.
用户授权提供离线支持。这意味着即使设备当前处于离线状态，用户也可以获得授权。离线支持开箱即用，无需任何额外实现。

To successfully authorize a user while offline, the following conditions have to be met:
要在离线状态下成功授权用户，必须满足以下条件：

Your application has successfully connected to Spotify within the last 24 hours
您的应用程序已在过去 24 小时内成功连接到 Spotify
Your application uses the same redirect URI, client ID and scopes when connecting to Spotify
您的应用程序在连接到 Spotify 时使用相同的重定向 URI、客户端 ID 和范围
Set up App Remote  设置 App Remote
With authentication implemented, we can now control the Spotify main application to play music and notify us on playback state:
实施身份验证后，我们现在可以控制 Spotify 主应用程序播放音乐并在播放状态下通知我们：

Implement Remote Delegates
实现远程委托
We'll need to implement two delegates: SPTAppRemoteDelegate and SPTAppRemotePlayerStateDelegate. These will respectively provide connection and playback state methods to implement inside of our AppDelegate.swift:
我们需要实现两个委托： SPTAppRemoteDelegate 和 SPTAppRemotePlayerStateDelegate . 这些将分别提供连接和播放状态方法，以便在我们的 AppDelegate.swift 内部实现：

class AppDelegate: UIResponder, UIApplicationDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
  ...

or if you are using UIScene:
或者如果你正在使用 UIScene：

class SceneDelegate: UIResponder, UIWindowSceneDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate
  ...

These will require us to implement the following methods:
这些将要求我们实施以下方法：

func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
  print("connected")
}
func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
  print("disconnected")
}
func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
  print("failed")
}
func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
  print("player state changed")
}

Initialize App Remote  初始化应用程序远程
We'll need to initialize App Remote on a class-level closure, which can take the self.configuration we defined earlier:
我们需要在类级闭包上初始化 App Remote，它可以采用我们之前定义的 self.configuration ：

lazy var appRemote: SPTAppRemote = {
  let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
  appRemote.connectionParameters.accessToken = self.accessToken
  appRemote.delegate = self
  return appRemote
}()

Configure Initial Music  配置初始音乐
iOS requires us to define a playURI (as shown in the last step) in order to play music to wake up the Spotify main application. This is an iOS-specific requirement. This can be:
iOS 系统要求我们定义一个 playURI （如上一步所示），以便播放音乐并唤醒 Spotify 主应用程序。这是 iOS 系统特有的要求。具体可以是：

An empty value: If empty, it will resume playback of user's last track or play a random track. If offline, one of the downloaded for offline tracks will play. Example:
空值： 如果为空，系统将恢复播放用户的上一首曲目或随机播放一首曲目。如果离线，系统将播放其中一首已下载的离线曲目。示例：

self.playURI = ""

A valid Spotify URI: Otherwise, provide a Spotify URI. Example:
有效的 Spotify URI： 否则，请提供 Spotify URI。例如：

self.playURI = "spotify:track:20I6sIOMTCkB6w7ryavxtO"

Authorizing and Connecting to Spotify
授权并连接到 Spotify
We need to initiate authorization and connect to Spotify:
我们需要启动授权并连接到 Spotify：

func connect()) {
  self.appRemote.authorizeAndPlayURI(self.playURI)
}

Upon a successful connection, this will invoke the appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) method we defined earlier.
连接成功后，这将调用我们之前定义的 appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) 方法。

Subscribing to state changes
订阅状态变化
We'll need to invoke a request to subscribe to player state updates, which we can do in the appRemoteDidEstablishConnection method:
我们需要调用订阅玩家状态更新的请求，我们可以在 appRemoteDidEstablishConnection 方法中执行此操作：

func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
  // Connection was successful, you can begin issuing commands
  self.appRemote.playerAPI?.delegate = self
  self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
    if let error = error {
      debugPrint(error.localizedDescription)
    }
  })
}

Inside playerStateDidChange, we can begin logging the output:
在 playerStateDidChange 内部，我们可以开始记录输出：

func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
  debugPrint("Track name: %@", playerState.track.name)
}

Cleaning up  清理
When the user switches from our application we should disconnect from App Remote. We can do this by inserting the following code into our applicationWillResignActive method:
当用户从我们的应用程序切换时，我们应该断开与 App Remote 的连接。我们可以通过在 applicationWillResignActive 方法中插入以下代码来实现：

func applicationWillResignActive(_ application: UIApplication) {
  if self.appRemote.isConnected {
    self.appRemote.disconnect()
  }
}

And similarly when a user re-opens our application, we should re-connect to App Remote. We can do by inserting the following code into our applicationDidBecomeActive method:
同样，当用户重新打开我们的应用时，我们也应该重新连接到 App Remote。我们可以在 applicationDidBecomeActive 方法中插入以下代码来实现：

func applicationDidBecomeActive(_ application: UIApplication) {
  if let _ = self.appRemote.connectionParameters.accessToken {
    self.appRemote.connect()
  }
}

Or if you are using UIScene:
或者如果你使用 UIScene：

func sceneDidBecomeActive(_ scene: UIScene) {
  if let _ = self.appRemote.connectionParameters.accessToken {
    self.appRemote.connect()
  }
    }

func sceneWillResignActive(_ scene: UIScene) {
  if self.appRemote.isConnected {
    self.appRemote.disconnect()
  }
}

Having issues? Take a look at a full example of AppDelegate.swift. Or check out the SceneDelegate example.
有问题吗？请查看 AppDelegate.swift 的完整示例 。或者查看 SceneDelegate 示例 。

Next Steps  后续步骤
Congratulations! You've interacted with the Spotify iOS SDK for the first time. Time to celebrate, you did great! 👏
恭喜！ 您首次与 Spotify iOS SDK 进行了交互。是时候庆祝一下了，您做得太棒了！👏

Want more? Here's what you can do next:
想要更多？接下来您可以执行以下操作：

Learn about how our iOS SDK interacts with iOS in our application lifecycle guide.
在我们的应用程序生命周期指南中了解我们的 iOS SDK 如何与 iOS 交互。
Dive into other things you can do with the SDK in the reference documentation.
深入了解可以使用参考文档中的 SDK 执行的其他操作。
Be sure to check out the sample code in the Demo Projects folder included with the SDK.
请务必查看 SDK 中包含的 Demo Projects 文件夹中的示例代码。