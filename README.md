# 预约挂号（FirstIOS）

一个用 SwiftUI 写的门诊预约挂号示例。可以在模拟器里走完「选医院 → 选科室 → 选医生 → 选时间 → 填写就诊人 → 查看预约」的流程。没有真实后端，医院、医生和号源都是本地模拟数据。

Bundle ID：`com.binant.firstios`  
主屏幕名称：预约挂号

## 环境

- Mac
- Xcode 15 或更高版本（建议 Xcode 16 及以上）
- iOS 17 或更高版本的模拟器

工程是经典 `project.pbxproj`（objectVersion 56），用 Xcode 直接打开即可，不需要 CocoaPods，也没有第三方依赖。

## 打开并运行

1. 在 Mac 上克隆本仓库。
2. 双击打开根目录的 `FirstIOS.xcodeproj`。  
   工程内部已带 `project.xcworkspace`，不要再执行 `pod install`。
3. 顶部 Scheme 选择 **FirstIOS**，运行目标选一台 iPhone 模拟器（例如 iPhone 16）。共享 Scheme 会把应用语言设为简体中文。
4. 点击 Run（⌘R）。
5. 如果签名报错：打开 Target **FirstIOS** → **Signing & Capabilities**，勾选 **Automatically manage signing**，Team 选你的 Personal Team（免费 Apple ID 即可）。只在模拟器上运行时，也可以把 Signing Certificate 改成 **Sign to Run Locally**。
6. 第一次打开如果提示 **Update to recommended settings**，点 Update 即可，不影响源码。

## 可以体验的流程

1. **首页**：按综合、中医、妇幼、专科筛选，或搜索医院、科室、地区。
2. **科室**：查看医院简介，进入某个科室。
3. **医生**：查看职称、擅长方向和挂号费。
4. **时间**：选择未来 7 天中的日期，以及上午/下午时段。已过时或已约满的号不能选。
5. **确认预约**：填写就诊人姓名和 11 位手机号，备注可选。可点「填入示例」快速体验。
6. **预约成功**：得到本机预约号，可回到首页或打开「我的预约」。
7. **我的预约**：查看待就诊和已取消记录，可以取消单条或清空全部。

取消预约后，对应号源会回到可选列表。记录写在本机 `UserDefaults` 里，卸载 App 后消失。

## 目录

```text
FirstIOS.xcodeproj/          Xcode 工程与共享 Scheme
FirstIOS/
  FirstIOSApp.swift          App 入口
  Models/                    医院、医生、号源、预约和导航路由
  Data/                      模拟数据与本地预约存储
  Support/                   日期格式与表单校验
  Theme/                     颜色
  Views/                     各页面
  Assets.xcassets            图标与强调色
LICENSE                      MIT 许可证
```

## 说明

界面文案是中文。这是演示项目，不会连接医院系统，也不会产生真实挂号。
