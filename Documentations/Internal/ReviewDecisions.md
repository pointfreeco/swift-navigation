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

### alert 作为 sheet 时没走 `beginSheetModal(for:)`，会不排版、按钮关不掉

- **裁决**：误报。（2026-11-06）
- **理由**：`NSWindow.sheet` 把 alert 的窗口直接交给 `NSWindow.beginSheet(_:)`，确实没调用 `NSAlert.beginSheetModal(for:)`。但在 macOS 27.2 上测试，alert 的标题和说明文字照常排版显示，点按钮也照常结束 sheet、把 binding 写回 `false`。同一处代码对存取面板是真问题：点「取消」关不掉 sheet，见提案 [draft-appkit-presentation-redesign](../Evolutions/draft-appkit-presentation-redesign.md) 第 8 条。
- **现状**：那份提案让 alert 改走自己的 `beginSheetModal(for:)`，`SheetPresentationTests` 里两条 alert 测试守着上面两点。

### `NSFontManager(font:)` 会建出一个和字体面板无关的新实例

- **裁决**：误报。（2026-11-03）
- **理由**：在 macOS 27.2 上实测，`NSFontManager()` 返回的就是 `NSFontManager.shared`。
- **复查条件**：将来某个系统版本上它不再返回共享实例时。

## 暂缓处理

### 上游 `UIKitNavigation` 的 `UITextField` 选区绑定同样把 UTF-16 偏移当成字符数

- **裁决**：确认是同类问题，fork 内不修，暂不向上游报告。（2026-11-03，暂不报告由用户决定）
- **理由**：AppKit 那份已按 UTF-16 换算修好。UIKit 那份是上游拥有的代码，fork 保持与上游一致，在 fork 里改会让以后的合并持续冲突。
- **复查条件**：上游自己修了，或者 fork 的 UIKit 用户撞上这个问题时。

## 系统限制

### Xcode 26.6 上 `observe(_:)` 的两条 `@isolated(any)` 转换警告

- **裁决**：旧编译器的限制，不修。（2026-11-04）
- **理由**：`observe(_:)` 必须同步执行传入的 `@isolated(any)` 闭包，编译器为此报「converting @isolated(any) function … to synchronous function type」。Swift 6.4 上用 `@diagnose(ConversionFromIsolatedAnyToSynchronous, as: ignored)` 屏蔽了；Swift 6.2（Xcode 26.6）不认识这个属性，只能去掉签名里的 `@isolated(any)`，而那会让 `observe { @MainActor in … }` 这类显式指定隔离的写法退化。
- **复查条件**：不再支持 Xcode 26.6 时，这一条直接删掉。

### 字体绑定只在响应链上有对象实现 `changeFont(_:)` 时生效

- **裁决**：AppKit 自身的行为，库里无法绕开。（2026-11-03）
- **理由**：实测发现，响应链上没有实现 `changeFont(_:)` 的对象时，`NSFontManager.sendAction()` 返回 `false`，`addFontTrait(_:)` 也什么都不做，字体面板的改动根本不会发出来。
- **现状**：已写进 `NSFontManager.bind(font:)` 的文档注释。

## 未在运行时验证

### transient popover 被点外部关闭时的回写

- `present(style: .popover(...))` 在用户关闭时把 binding 写回 `nil`，依靠的是 AppKit 调用 `dismissViewController:`。用 `dismiss(nil)` 关闭的情形有测试覆盖；点击 popover 外部触发的 transient 关闭，在单元测试里没法模拟，所以 AppKit 在这条路径上是否也调用 `dismissViewController:`，还没有验证。
