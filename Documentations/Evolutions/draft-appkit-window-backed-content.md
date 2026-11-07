# Draft - 把 `ModalContent` 改名为 `WindowBackedContent`

- **状态**: In Progress
- **创建日期**: 2026-11-08
- **最后更新**: 2026-11-08
- **实现分支**: `appkit-window-backed-content`

## 摘要

[0005](0005-appkit-presentation-redesign.md) 新增的公开协议 `ModalContent`（`NSWindow`、`NSAlert` 与存取面板遵循）改名为 `WindowBackedContent`。这个协议同时是 `modal(...)` 和 `NSWindow.sheet(...)` 的内容约束，叫 `ModalContent` 读起来像只给 `modal` 用；遵循它的几种类型真正的共同点是各自带一个窗口，新名字直接说出这一点。

## 方案

- 协议、它所在的文件（`ModalContent.swift` → `WindowBackedContent.swift`）、`modal` 与 `NSWindow.sheet` 的泛型约束、两个内部 style 的约束一并改名。协议要求（`_appKitNavigation…`）不变。
- 不保留旧名：这个协议还没随任何版本发布，下游也没有代码直接写它的名字，与 0005 不保留旧名的理由相同。
- 同步文档注释、DocC 首页和 `swift-navigation-bindings` skill。0005 的正文保持原样，只在它的决策日志里记一行指向本提案。

没有询问就采用的假设：

- 验证：Xcode 27.2 跑 AppKit 的全部测试，再生成一次 AppKitNavigation 的文档，确认符号链接都能解析。改动只是改名，不另用 Xcode 26.6 编译。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-08 | Created as Draft | `ModalContent` 读起来像只给 `modal` 用，而 `NSWindow.sheet` 也用它 |
| 2026-11-08 | 采用 `WindowBackedContent`，不采用 `NavigationContent` | 后者比实际范围宽：popover 与 `present` 收的 `NSViewController` 不遵循这个协议，叫它会让人以为所有导航 API 都收它；遵循者的共同点是各自带一个窗口，`NSWindow` 本身就是，`NSAlert` 与存取面板也都有自己的窗口 |
| 2026-11-08 | Accepted | 用户批准；做完在本地合进 `main`，不推送 |
| 2026-11-08 | 实现完成，待用户看过后收尾 | Xcode 27.2 上 AppKit 测试 64 条 XCTest、58 条 Swift Testing 全部通过；生成文档只有上游共用内容里原有的 3 条链接警告，新名字的符号页正常生成。文档判断：文档注释、DocC 首页、`swift-navigation-bindings` skill 已同步，0005 只加了一行指向本提案；不需要使用指南或实现说明，没有新术语 |
