# Draft - 给 AppKit 案例补上弹出与新控件绑定的演示

- **状态**: In Progress
- **创建日期**: 2026-11-08
- **最后更新**: 2026-11-08
- **实现分支**: `appkit-window-backed-content`

## 摘要

Examples 里的 AppKit 案例只演示了用 `present` 弹 sheet 和一个打开面板的 modal：[0005](0005-appkit-presentation-redesign.md) 重做后的弹出行为、[0003](0003-appkit-common-control-bindings.md) 和 [0004](0004-appkit-table-selection-bindings.md) 加的控件绑定都没有案例。这一批在 AppKit 案例列表里补上五个案例，让这些 API 有可以照着写、可以运行起来看的样子。

## 方案

新增一组「Presentation」，三个案例：

- **弹出方式总览**：一个页面挨个演示窗口、alert、存取面板作为 sheet 和 modal，modal session，视图和工具栏项的 popover，以及视图控制器的三种 `present`。每种都在页面底部记下 `onDismiss` 的调用。
- **嵌套 modal**：模态运行的设置窗口里，「重置」按钮先弹一个确认 alert，叠在设置窗口上面；绑定在 alert 还开着时要求关掉设置窗口，会等 alert 先结束。
- **关闭与 `onDismiss`**：同一个 sheet 分别由用户关、由 binding 关、换成另一项，日志列出每次 `onDismiss` 的调用和当时 binding 的值。

「Bindings」一组加两个案例：

- **选项绑定**：弹出按钮、分段控件、标签页控制器绑到同一个枚举，三者互相跟随；分段控件的每一段绑一个 `Bool`；下拉菜单里一个菜单项的勾号绑一个 `Bool`。
- **表格与大纲的选中**：表格用 diffable data source 绑定选中项；大纲用一棵静态的树，绑定选中项和展开的项。

顺带的小改动：`Basics` 案例的说明把 AppKit 写成了 UIKit，改正；案例列表里已经由这一批覆盖的两条 TODO（alert 状态、关闭）删掉。

没有询问就采用的假设：

- 新文件手工登记进 `Examples.xcodeproj`：官方 Xcode MCP 操作的是用户当前打开的 Xcode，而这个 worktree 里的工程没有打开，另一个工程文件工具这次会话里也没有。
- 验证只编译 `CaseStudies` 的 macOS 版，不打开界面去点。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-08 | Created as Draft | 0005 的弹出行为和 0003、0004 的控件绑定都还没有可以运行的示例 |
| 2026-11-08 | Accepted | 用户选定了全部四块内容并批准；控件绑定那一块拆成两个案例，免得一个页面太挤。做完在本地合进 `main`，不推送 |
| 2026-11-08 | 实现完成，待用户看过后收尾 | 五个案例和一个共享辅助文件已登记进 `Examples.xcodeproj`；用 xcodebuild 编译 `CaseStudies` 的 macOS 版一次通过，新文件没有警告。没有打开界面去点。文档判断：案例本身就是示例文档，各自带说明；仓库 README 里关于案例的那一句来自上游，AppKit 案例此前就有，不用改；不需要使用指南或实现说明，没有新术语 |
