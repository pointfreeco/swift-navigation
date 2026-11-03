# 审查裁决清单

记录审查中判为误报、不值得修或暂缓处理的发现，以及没能在运行时验证的部分。每次审查之前先对照这份清单：已裁决、且理由仍然成立的条目直接跳过；新证据推翻了当初理由的，更新条目并重新裁决。

已修复的问题不在这里，它们的原因与验证写在各自的 commit message 和回归测试里。

## 误报或未复现

### `modalSession` 由 binding 关闭时结束了两次模态会话

- **裁决**：未复现出后果，不按 bug 处理。（2026-11-03）
- **理由**：binding 置空时，旧代码先调用 `endModalSession`、再关窗，关窗通知里又调用一次。可在 macOS 27.2 上测试，模态会话正常结束，`NSApp.modalWindow` 也归零，看不到任何异常。
- **现状**：修复「用户关窗不回写」时，结束会话的位置已经统一到窗口关闭通知这一处，顺带消除了重复调用。

### 焦点绑定直接调用 `becomeFirstResponder()`

- **裁决**：未复现症状，不按 bug 处理。（2026-11-03）
- **理由**：Apple 文档写明不要直接调用它，应改用 `NSWindow.makeFirstResponder(_:)`。但实测通过 binding 设置焦点一直能正常生效，`NSTextField` 自己的实现会把字段编辑器设为第一响应者。
- **现状**：已按文档改用 `makeFirstResponder(_:)`，行为不变。

### `NSFontManager(font:)` 会建出一个和字体面板无关的新实例

- **裁决**：误报。（2026-11-03）
- **理由**：在 macOS 27.2 上实测，`NSFontManager()` 返回的就是 `NSFontManager.shared`。
- **复查条件**：将来某个系统版本上它不再返回共享实例时。

## 暂缓处理

### `Navigated` 各约束扩展里的 `clearup()` 从不执行

- **裁决**：确认是死代码，暂不修。（2026-11-03）
- **理由**：`Navigated` 是泛型类，`deinit` 里调用的 `clearup()` 在编译期就静态绑定到类里那份空实现，`where Content: …` 扩展里的同名方法永远不会被调用。导航观察者被释放时，原本打算关掉仍在显示的内容，但目前没有构造出现实中看得见的后果。直接把它激活反而有风险：模态那份会无条件调用 `stopModal()`，可能停掉一个并非本库发起的模态循环。
- **复查条件**：收敛导航相关重载的重构时，连同下一条一起处理。

### `present(...)` 替换已弹出的视图控制器时，不分来源都调用本 binding 的 `onDismiss`

- **裁决**：读代码确认，影响面小，暂不修。（2026-11-03）
- **理由**：同一个 presenter 已经有一个弹出的视图控制器时，新的 `present` 会先把它关掉，并调用*本 binding* 的 `onDismiss`，不管它是不是本 binding 弹出来的。UIKit 那边用一个 presenter 标记来区分。只有在同一个 presenter 上挂了两个 binding 时才会触发。另外，被关掉的那个 binding 现在能正确收到回写。
- **复查条件**：同上。

### 上游 `UIKitNavigation` 的 `UITextField` 选区绑定同样把 UTF-16 偏移当成字符数

- **裁决**：确认是同类问题，fork 内不修，暂不向上游报告。（2026-11-03，暂不报告由用户决定）
- **理由**：AppKit 那份已按 UTF-16 换算修好。UIKit 那份是上游拥有的代码，fork 保持与上游一致，在 fork 里改会让以后的合并持续冲突。
- **复查条件**：上游自己修了，或者 fork 的 UIKit 用户撞上这个问题时。

## 系统限制

### 字体绑定只在响应链上有对象实现 `changeFont(_:)` 时生效

- **裁决**：AppKit 自身的行为，库里无法绕开。（2026-11-03）
- **理由**：实测发现，响应链上没有实现 `changeFont(_:)` 的对象时，`NSFontManager.sendAction()` 返回 `false`，`addFontTrait(_:)` 也什么都不做，字体面板的改动根本不会发出来。
- **现状**：已写进 `NSFontManager.bind(font:)` 的文档注释。

## 未在运行时验证

### transient popover 被点外部关闭时的回写

- `present(style: .popover(...))` 在用户关闭时把 binding 写回 `nil`，依靠的是 AppKit 调用 `dismissViewController:`。用 `dismiss(nil)` 关闭的情形有测试覆盖；点击 popover 外部触发的 transient 关闭，在单元测试里没法模拟，所以 AppKit 在这条路径上是否也调用 `dismissViewController:`，还没有验证。
