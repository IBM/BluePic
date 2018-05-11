# BluePic

*阅读本资料的其他语言版本：[English](README.md).*

[![构建状态 - 主页](https://travis-ci.org/IBM/BluePic.svg?branch=master)](https://travis-ci.org/IBM/BluePic)

BluePic 是一个照片和图像分享样本应用程序，使您能够拍摄照片并将其分享给其他 BluePic 用户。此样本应用程序演示了如何在移动 iOS 10 应用程序中，使用以 Swift 编写的基于 Kitura 的服务器应用程序。

BluePic 在典型的 iOS 客户端设置中，以及在使用全新 Swift Web 框架和 Kitura (HTTP Server) 的服务器端均可使用 Swift。Bluepic 比较有趣的一个方面是它在服务器上处理照片的方式。发布照片时，其数据记录在 Cloudant 中，而图像二进制文件则存储在 Object Storage 中。在那里，将调用一个 [Cloud Functions](https://www.ibm.com/cloud/functions) 序列，根据图像上传位置来计算诸如温度和当前天气情况（例如，晴、多云等）等气象数据。Cloud Functions 序列中还会使用 Watson Visual Recognition 来分析图像并基于图像内容提取文本标签。最终会向用户发送一条推送通知，告知其图像已处理完毕并且现已包含气象数据和标签数据。

## Swift 版本
BluePic 应用程序的后端组件（例如，基于 Kitura 的服务器和 Cloud Functions 操作）和 iOS 组件可以使用特定版本的 Swift 二进制文件，请参阅下表：

| 组件 | Swift 版本 |
| --- | --- |
| 基于 Kitura 的服务器 | `4.0.2` |
| Cloud Functions 操作 | `3.1.1` |
| iOS 应用程序 | Xcode 9.1 默认版本 (`Swift 4.0.2`)

您可以通过访问此[链接](https://swift.org/download/)来下载 Swift 二进制文件的开发快照。不保证与其他 Swift 版本的兼容性。

（可选）如果想要使用 Xcode 来运行基于 Kitura 的 BluePic 服务器，那么应使用 Xcode 9.1 并将其配置为使用默认工具链。有关如何设置 Xcode 的详细信息，请参阅[在 Xcode 内构建](http://www.kitura.io/en/starter/xcode.html)。请注意，不保证任何其他版本的 Xcode 适用于该后端代码。


## 入门

### 1.安装系统依赖项
在 macOS 上使用 [Homebrew](http://brew.sh/) 安装以下系统级别的依赖项：

```bash
brew install curl
```

如果要使用 Linux 作为 Kitura 服务器组件的开发平台，请参阅[在 macOS 和 Linux 上编译和测试代码](http://www.kitura.io/en/starter/leveragedocker.html)以获取有关如何在 macOS 系统上使用 Docker 的详细信息。

### 2.克隆 BluePic Git 存储库
执行以下命令以克隆 Git 存储库：

```bash
git clone https://github.com/IBM/BluePic.git
```

如果您愿意，可以花几分钟时间来熟悉该存储库的文件夹结构，如[关于](Docs/About.md)页面中所述。

### 3.在 IBM Cloud 上创建 BluePic 应用程序

#### Cloud Foundry 部署
单击以下按钮，将 BluePic 应用程序部署至 IBM Cloud。解析[包含在存储库中的] [`manifest.yml`](manifest.yml) 文件，以获取应用程序的名称并确定应实例化的 Cloud Foundry 服务。有关 `manifest.yml` 文件结构的更多详细信息，请参阅 [Cloud Foundry 文档](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html#minimal-manifest)。单击以下按钮后，可以为应用程序命名。请记住，您的 IBM Cloud 应用程序名称必须与 `manifest.yml` 中的名称值相匹配。因此，如果在 IBM Cloud 帐户中存在命名冲突，那么您可能需要更改 `manifest.yml` 中的名称值。

[![部署到 Bluemix](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/IBM/BluePic.git&cm_mmc=github-code-_-native-_-bluepic-_-deploy2bluemix)

部署到 IBM Cloud 后，应使用所选 Web 浏览器访问为您的应用程序指定的路由。您应该会看到 Kitura 欢迎页面！

请注意，将使用[针对 Swift 的 IBM Cloud 构建包](https://github.com/IBM-Swift/swift-buildpack)来将 BluePic 部署到 IBM Cloud。以下 IBM Cloud 地区当前已安装此构建包：美国南部地区、英国和悉尼。

#### 手动命令行部署
##### 作为 Cloud Foundry 应用程序进行部署
您将需要安装以下组件：
- [IBM Cloud Dev Plugin](https://console.bluemix.net/docs/cloudnative/dev_cli.html#developercli)

```
sh ./Cloud-Scripts/Deployment/cloud_foundry.sh
```

##### 作为 Kubernetes 容器集群随 Docker 一起部署
- 有关部署至 Kubernetes 的信息，请阅读[文档](./Docs/Kubernetes.md)

### 4.填充 Cloudant 数据库
要使用样本数据填充 Cloudant 数据库实例，需要获取以下凭证值：

- `username` - Cloudant 实例的用户名。
- `password` - Cloudant 实例的密码。
- `projectId` - Object Storage 实例的项目 ID。

您可以通过访问 IBM Cloud 上的应用程序页面并单击 Cloudant 服务和 Object Storage 服务实例上的 `Show Credentials` 下拉菜单来获取以上凭证。获得这些凭证后，请浏览至 BluePic 存储库中的 `Cloud-Scripts/cloudantNoSQLDB/` 目录，并执行 `populator.sh` 脚本，如下所示：

```bash
./populator.sh --username=<cloudant username> --password=<cloudant password> --projectId=<object storage projectId>

```

### 5.填充 Object Storage
要使用样本数据填充 Object Storage 实例，需要获取以下凭证值（region 为可选项）：

- `userId` - Object Storage 实例的用户标识。
- `password` - Object Storage 实例的密码。
- `projectId` - Object Storage 实例的项目 ID。
- `region` -（可选）您可以为 Object Storage 设置要用于保存数据的区域（例如，`london` 表示伦敦，`dallas` 表示达拉斯）。如果未设置 region，其默认设置为 `dallas`。

您可以通过访问 IBM Cloud 上的应用程序页面并单击 Object Storage 实例上的 `Show Credentials` 下拉菜单来获取以上凭证。获得这些凭证后，请浏览至 BluePic 存储库中的 `./Cloud-Scripts/Object-Storage/` 目录，并执行 `populator.sh` 脚本，如下所示：

```bash
./populator.sh --userId=<object storage userId> --password=<object storage password> --projectId=<object storage projectId> --region=<object storage region>
```

### 6.更新 `BluePic-Server/config/configuration.json` 文件
现在，应更新 `BluePic-Server/config/configuration.json` 文件中列出的每一个服务的凭证。这样，您就可以在本地运行基于 Kitura 的服务器以用于开发和测试目的。在 `configuration.json` 文件中找到每个应提供的凭证值对应的占位符（例如，`<username>`、`<projectId>`）。

请记住，您可以通过访问 IBM Cloud 上的应用程序页面，并单击与 BluePic 应用程序绑定的每一个服务实例上的 `Show Credentials` 下拉菜单，来获取 `configuration.json` 文件中列出的每一个服务的凭证。

您可以通过单击[此处](BluePic-Server/configuration.json)来查看 `configuration.json` 文件的内容。

### 7.更新 iOS 应用程序的配置
转至 `BluePic-iOS` 目录，并在 Xcode 中使用 `open BluePic.xcworkspace` 打开 BluePic 工作空间。现在，更新 Xcode 项目中的 `cloud.plist`（可在 Xcode 项目的 `Configuration` 文件夹中找到此文件）。

1.如果要使用本地运行的服务器，应将 `isLocal` 值设置为 `YES`；如果将该值设置为 `NO`，那么将访问 IBM Cloud 上运行的服务器实例。

2.要获取 `appRouteRemote` 的值，请转至 IBM Cloud 上的应用程序页面。在该页面右上角附近找到 `View App` 按钮。单击此按钮将在新选项卡中打开应用程序，此页面的 URL 即是映射到 plist 中的 `appRouteRemote` 键的 `route`。请确保在 `appRouteRemote` 中包含 `http://` 协议，并删除 URL 末尾的正斜杠。

3.最后，需要获取 `cloudAppRegion` 的值，该值当前可为以下三个选项之一：

REGION US SOUTH | REGION UK | REGION SYDNEY
--- | --- | ---
`.ng.bluemix.net` | `.eu-gb.bluemix.net` | `.au-syd.bluemix.net`

您可以通过多种方式找到自己的地区。例如，只需查看用于访问应用程序页面（或 IBM Cloud 仪表板）的 URL 即可。另一种方式是查看您之前修改的 `configuration.json` 文件。如果您查看 `AppID` 服务下的凭证，其中有一个值是 `oauthServerUrl`，该值应包含上述区域之一。在将 `cloudAppRegion` 值插入到 `cloud.plist` 后，您的应用程序应该已配置完成。

## 配置的可选功能
本部分描述了通过 App ID、Push Notifications 和 Cloud Functions 来进行 Facebook 认证要采取的步骤。

*BluePic-Server 中的 API 端点当前因为依赖关系限制而不受保护，可一旦能通过 Kitura 和 App ID SDK 使用该功能，这些端点会立即受到保护*

### 1.在 Facebook 上创建应用程序实例
要通过 Facebook 进行应用程序认证，必须在 Facebook 网站上创建应用程序实例。

1.转至 `BluePic-iOS` 目录，并在 Xcode 中使用 `open BluePic.xcworkspace` 打开 BluePic 工作空间。

2.为应用程序选择包标识符，并对 Xcode 项目进行相应的更新：选择 Xcode 左上角的项目导航器文件夹图标；然后选择位于文件结构顶部的 BluePic 项目，再选择 BluePic 目标。在 Identity 部分下，您应该可以看到包标识符对应的文本字段。使用您选择的包标识符更新该字段。（例如，com.bluepic）

3.转至[针对 iOS 的 Facebook 快速启动](https://developers.facebook.com/quickstarts/?platform=ios)页面以创建应用程序实例。输入 `BluePic` 作为新的 Facebook 应用程序的名称，然后单击 `Create New Facebook App ID` 按钮。为该应用程序选择任意类别，然后单击 `Create App ID` 按钮。

4.在随后显示的屏幕上，请注意，您**无需**下载 Facebook SDK。iOS 项目中已包含的 App ID SDK 具有支持 Facebook 认证所需的所有代码。在 `Configure your info.plist` 部分中，复制 `FacebookAppID` 值，并将其插入到 `info.plist` 中的 `URL Schemes` 和 `FacebookAppID` 字段，使您的 plist 如下图所示。`info.plist` 文件位于 Xcode 项目的 `Configuration` 文件夹下。
<p align="center"><img src="Imgs/infoplist.png"  alt="Drawing" height=150 border=0 /></p>

1.接下来，滚动至 Facebook 快速启动页面底部显示 `Supply us with your Bundle Identifier` 的位置，并输入您先前在步骤 2 中所选的应用程序包标识符。

2.在 Facebook Developer 网站上设置 BluePic 应用程序实例到此已完成。在以下部分中，我们将把该 Facebook 应用程序实例链接至 IBM Cloud App ID 服务。

### 2.配置 IBM Cloud App ID
1.转至 IBM Cloud 上的应用程序页面，并打开 `App ID` 服务实例：
<p align="center"><img src="Imgs/app-id-service.png"  alt="Drawing" height=125 border=0 /></p>

1.在下一个页面上，单击侧边的 `Identity Providers` 按钮，此时会显示如下内容：
<p align="center"><img src="Imgs/configure-facebook.png"  alt="Drawing" height=125 border=0 /></p>

1.将 Facebook 对应的开关切换至 On，然后单击 Edit 按钮。在此处输入来自 Facebook 应用程序页面的 Facebook 应用程序 ID 和密钥（请参阅[在 Facebook 上创建应用程序实例](#1-create-an-application-instance-on-facebook)部分以获取更多详细信息）。
<p align="center"><img src="Imgs/facebook-appid-setup.png"  alt="Drawing" height=250 border=0 /></p>

1.在此页面上，您还会看到“面向开发人员的 Facebook 重定向 URL”，请复制它，因为稍后需要使用。在 Facebook Developer 应用程序页面上，导航至 Facebook 登录产品。此 URL 为 `https://developers.facebook.com/apps/<facebookAppId>/fb-login/`。在此处，将该链接粘贴到“Valid OAuth redirect URIs”字段中，并单击 Save changes。返回到 IBM Cloud，您还可以单击 Save 按钮。

2.要使 App ID 正常运行，还需要执行一项操作，即需要将 App ID 的 `tenantId` 添加到 BluePic-iOS 的 `cloud.plist` 中。通过查看 IBM Cloud 中 App ID 服务的凭证即可获取 `tenantId `，您的所有服务都应位于 IBM Cloud 上您应用程序的“Connections”选项卡下。在其中单击 App ID 服务的“View Credentials”或“Show Credentials”按钮，此时您应该可以看到 `tenantId ` 与其他值一起弹出。现在，只需将该值置于 `cloud.plist`（与 `appIdTenantId` 键对应）即可。

3.使用 IBM Cloud App ID 进行 Facebook 认证现已设置完成！

### 3.配置 IBM Cloud 推送服务
要在 IBM Cloud 上使用推送通知功能，需要配置通知提供商。对于 BluePic，应配置 Apple 推送通知服务 (APNS) 的凭证。在执行此配置步骤期间，将需要使用[在 Facebook 上创建应用程序实例](#1-create-an-application-instance-on-facebook)部分中所选的**包标识符**。

幸运的是，IBM Cloud 提供了[指示信息](https://console.bluemix.net/docs/services/mobilepush/index.html#gettingstartedtemplate)来指导您完成通过 IBM Cloud 推送服务配置 APNS 的整个过程。请注意，您将需要向 IBM Cloud 上传一份 `.p12` 证书，并为其输入密码，如 IBM Cloud 指示信息中所述。

此外，推送服务的 `appGuid ` 独立于 BluePic 应用程序运行，因此需要将该值添加到 `cloud.plist`。而且，我们需要推送服务的 `clientSecret` 值。通过查看 IBM Cloud 中推送服务的凭证即可获取 `appGuid` 和 `clientSecret`，您的所有服务都应位于您应用程序的“Connections”选项卡下。在其中单击推送通知服务的“View Credentials”或“Show Credentials”按钮，此时您应该可以看到 `appGuid` 与其他值一起弹出。现在，只需将该值置于 `cloud.plist`（与 `pushAppGUID` 键对应）即可。接下来，您应该可以看到 `clientSecret` 值，可以使用此值来填充 `cloud.plist` 中的 `pushClientSecret` 字段。这样可确保向推送服务正确注册您的设备。

最后，请记住，推送通知将仅显示在物理 iOS 设备上。为确保您的应用程序可在设备上运行并收到推送通知，请确保遵循了 IBM Cloud [指示信息](https://console.bluemix.net/docs/services/mobilepush/index.html#gettingstartedtemplate)。现在，请在 Xcode 中打开 `BluePic.xcworkspace`，并浏览至 BluePic 应用程序目标的 `Capabilities` 选项卡。在此处，调整推送通知对应的开关，如下所示：

<p align="center"><img src="Imgs/enablePush.png"  alt="Drawing" height=145 border=0 /></p>

现在，请确保您的应用程序正在使用您先前按照 IBM Cloud 指示信息创建的、已启用推送的配置文件。此时，您便可以在自己的设备上运行应用程序，并且能够接收推送通知。

### 4.配置 Cloud Functions
BluePic 使用以 Swift 编写的 Cloud Functions 操作来访问 Watson Visual Recognition 和 Weather API。有关如何配置 Cloud Functions 的指示信息，请参阅以下[页面](Docs/CloudFunctions.md)。您将在其中找到有关如何配置和调用 Cloud Functions 命令的详细信息。

### 5.重新将 BluePic 应用程序部署至 IBM Cloud

#### 使用 IBM Cloud 命令行界面
配置可选功能后，应重新将 BluePic 应用程序部署至 IBM Cloud。

###### Cloud Foundry
您可以使用 IBM Cloud CLI 来执行此操作，请在[此处](http://clis.ng.bluemix.net/ui/home.html)下载。使用命令行登录到 IBM Cloud 后，可从本地文件系统上该存储库的根文件夹中执行 `bx app push`。这样会将应用程序代码和配置推送至 IBM Cloud。

###### Kubernetes 集群
如果您正在使用 Kubernetes 集群，并且已完成[此处](#deploy-as-kubernetes-container-cluster-with-docker)的初始部署过程
```
  # 使用来自先前设置指示信息的默认参数：
  bx dev deploy --target=container --deploy-image-target=bluepic --ibm-cluster=BluePic-Cluster
```

## 运行 iOS 应用程序
如果您尚未打开 iOS 项目，请转至 `BluePic-iOS` 目录，并使用 `open BluePic.xcworkspace` 打开 BluePic 工作空间。

现在，您可以在模拟器中使用自己熟悉的 Xcode 功能来构建和运行 iOS 应用程序！

### 在物理设备上运行 iOS 应用程序

对于 IBM 开发人员，请参阅我们的 [Wiki](https://github.com/IBM/BluePic/wiki/Code-Signing-Configuration-for-Internal-Developers) 以获取有关需要采取的步骤的详细信息。

在物理设备上运行 iOS 应用程序的最简单方法是将 BluePic 的包 ID 更改为唯一值（如果尚未执行此更改）。然后，在 Xcode 中转至 BluePic 应用程序目标的 `General` 选项卡，选中 `Automatically manage signing` 框。选中此框后，需要确保已从下拉列表中选中了您个人 Apple Developer 帐户所属的团队。假定您担任的 Apple Developer Program 团队角色是 `Agent` 或 `Admin`，需要为 BluePic 应用程序创建一个配置文件或者使用通配符配置文件（如果存在），以便能够在设备上运行此应用程序。

或者，您可以通过使用通配符 App ID 手动配置应用程序的代码签名以便在设备上运行此应用程序。如果已创建该配置文件，只需在 `Signing (Debug)` 部分中的配置文件下拉列表中将其选中即可。如果尚未创建该配置文件，可以通过 Apple Developer Portal 进行创建。此[链接](https://developer.apple.com/library/content/qa/qa1713/_index.html)可帮助提供有关通配符 App ID 的更多信息。

## 在本地运行基于 Kitura 的服务器
您可以通过转至克隆存储库的 `BluePic-Server` 目录并运行 `swift build` 来构建 BluePic-Server。要在本地系统上为 BluePic 应用程序启动基于 Kitura 的服务器，请转至克隆存储库的 `BluePic-Server` 目录，并运行 `.build/debug/BluePicServer`。另外还应更新 Xcode 项目中的 `cloud.plist` 文件以使 iOS 应用程序连接到此本地服务器。请参阅[更新 iOS 应用程序的配置](#7-update-configuration-for-ios-app)部分以获取详细信息。

## 使用 BluePic
BluePic 设计了大量实用功能。要查看有关如何使用 iOS 应用程序的更多详细信息，请查看[使用 BluePic](Docs/Usage.md) 页面上的演示。

## 关于 BluePic
要了解有关 BluePic 的文件夹结构、架构及其依赖的 Swift 程序包的更多信息，请参阅[关于](Docs/About.md)页面。

## 了解更多信息
- [使用 BluePic 转换至服务器端的 Swift](https://developer.ibm.com/swift/2016/11/15/transition-to-server-side-swift-with-bluepic/)
- [Kitura 2.0 简介](https://developer.ibm.com/swift/2017/10/30/kitura-20/)
- [使用 Kitura 命令行界面构建服务器端的 Swift 应用程序](https://developer.ibm.com/swift/2017/10/30/kitura-cli/)

## 许可
此应用程序是在 Apache 2.0 下授予许可的。在[许可](LICENSE)中提供了完整许可文本。

要获取所使用的演示图像的列表，请查看[图像来源](Docs/ImageSources.md)文件。
