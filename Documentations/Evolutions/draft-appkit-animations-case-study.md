# Draft - AppKit 动画案例

- **状态**: Accepted
- **创建日期**: 2026-11-09
- **最后更新**: 2026-11-09
- **实现分支**: `appkit-more-control-bindings`

## 摘要

AppKit 案例列表里的「Animations」一项一直是注释掉的：UIKit 有这个案例，AppKit 的 `withAppKitAnimation` 和 `UIBinding` 的 `animation(_:)` 却没有能运行的示例。这一批补上 AppKit 版，演示修改模型时界面跟着动画。

## 方案

新增 `AppKit+AnimationsViewController.swift` 并登记进 `Examples.xcodeproj`，在案例列表的「Observation」一组里取消注释，与 UIKit 版放在同一组。页面内容照 UIKit 版：

- 一个圆形视图。在页面上点击或拖动时，用 `withAppKitAnimation` 带弹簧动画移到鼠标的位置。
- 一个 `NSSwitch` 绑到 `$model.isScaled.animation(…)`，切换时圆放大或缩小。
- 「Cycle colors」按钮依次换几种颜色，每次换色都包在 `withAppKitAnimation` 里。

没有询问就采用的假设：

- 弹簧动画用 SwiftUI 的 `Animation`，要求 macOS 15；更早的系统退回 `.easeInOut`。
- `NSView` 没有 UIKit 那样的 `transform`，放大缩小改用视图的尺寸实现；具体做法以实现时实测能动起来为准。
- 只编译 CaseStudies 的 macOS 版，不打开界面去点。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-09 | Created as Draft | AppKit 案例列表里只有动画一项还注释着，用户选定补上 |
| 2026-11-09 | 用户批准，开始实现 | 与另两份提案在同一条分支上实现，做完在本地合进 `main`、不推送 |
