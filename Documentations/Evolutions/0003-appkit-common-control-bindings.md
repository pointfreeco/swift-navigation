# 0003 - AppKit 常用控件的类型化绑定

- **状态**: Implemented
- **创建日期**: 2026-11-05
- **最后更新**: 2026-11-05
- **实现分支**: `appkit-common-control-bindings`

## 摘要

调查了本机依赖这个 fork 的 7 个 macOS 项目，约 50 处代码在手写同一类连接：弹出按钮和分段控件按 `allCases` 的下标对应枚举，勾选框的 `state` 与 `Bool` 或集合成员互相同步，分栏的折叠状态和标签页的选中项只从模型往界面单向同步。库现有的类型化绑定覆盖不到这些控件：`bind(selectedSegment:)` 只接受以 `Int` 为原始值的枚举，勾选框、弹出按钮、分栏、标签页和菜单项勾号都没有对应的绑定。这次补上八种双向绑定，写法与现有的 `bind(isOn:)`、`bind(selectedSegment:)` 一致。

## 方案

调用点：

```swift
NSButton(checkboxWithTitle: "Dump Objective-C", isOn: $model.dumpsObjectiveC)
NSButton(checkboxWithTitle: kind.title, isOn: $model.declarationKinds, contains: kind)
NSPopUpButton(selection: $model.weight, options: SymbolWeight.allCases, title: \.displayName)
segmentedControl.bind(selection: $model.segment, options: EntitySegment.allCases)
paneToggleControl.bind(isSelected: $model.isSidebarVisible, forSegment: 0)
inspectorItem.bind(isCollapsed: $model.isInspectorCollapsed)
tabViewController.bind(selection: $model.mode, options: MainSidebarMode.allCases)
NSMenuItem(title: "Show Hidden Files", isOn: $model.showsHiddenFiles)
```

1. **整理内部的绑定机制**（已完成）：现有的 `establishBinding` 同时要求 target/action 和 KVO。改成三部分都可选——target/action、KVO、用户操作后读回的值——让分栏、标签页这类没有 target/action 的对象，以及每段各绑一个值的分段控件也能用。现有绑定的行为不变，现有测试全部通过。
2. **勾选框**（已完成）：`NSButton.bind(isOn:)` 把 `state` 与 `Bool` 双向同步；`bind(isOn:contains:)` 把勾选状态与一个 `SetAlgebra`（`Set`、`OptionSet`）里是否含有某个成员同步，勾上插入、取消移除。各配一个 `NSButton(checkboxWithTitle:isOn:)` 形式的便捷构造器。
3. **从一组选项里选一个**（已完成）：`NSPopUpButton` 与 `NSSegmentedControl` 加 `bind(selection:options:)`，第 i 项对应 `options[i]`，值只要求 `Equatable`。便捷构造器多一个 `title:`，按选项生成菜单项或分段标签，保证顺序一致。
4. **多选分段控件的单段**（已完成）：`NSSegmentedControl.bind(isSelected:forSegment:)`，每段各绑一个 `Bool`，名字照 AppKit 的 `isSelected(forSegment:)`。
5. **分栏折叠**（已完成）：`NSSplitViewItem.bind(isCollapsed:)`，用户拖动分隔条或点侧栏按钮折叠时经 KVO 写回；在 `withAppKitAnimation` 里改模型时经 `animator()` 带动画。配 `unbindIsCollapsed()`。
6. **标签页**（已完成）：`NSTabViewController.bind(selection:options:)`，对应 `selectedTabViewItemIndex`，用户切换标签时经 KVO 写回。配 `unbindSelection()`。
7. **菜单项勾号**（已完成）：`NSMenuItem.bind(isOn:)`，勾号跟随 `Bool`，用户选中菜单项时取反写回。配 `NSMenuItem(title:isOn:keyEquivalent:)`。
8. **文档与验证**（已完成）：
   - DocC 首页「绑定」一组登记了 `NSButton`、`NSPopUpButton`、`NSSplitViewItem`、`NSTabViewController`；生成文档没有新的 DocC 警告，仍是与上游共用内容的那 3 条。
   - `swift-navigation-bindings` skill 的绑定清单补上新绑定，常见错误表加了两条。
   - 每种绑定先写双向测试再实现，新测试在 `Tests/AppKitNavigationTests/CommonControlBindingTests.swift`。Xcode 27.2 上全量 `swift test` 只有已知的 `ButtonStateTests.testAsyncAnimationWarning` 失败；AppKit 的 Swift Testing 49 条（含 2 条故意触发的已知问题）、XCTest 16 条全部通过。Xcode 26.6 编过 AppKit 的测试 target；Xcode 27.2 全新构建，本包代码零警告。

没有询问就采用的假设：

- 参数标签用 `selection:`、`options:`，照 SwiftUI 的 `Picker(selection:)` 和 Cocoa 绑定的 `content` / `selectedObject`；现有的 `bind(selectedSegment:)` 保留不动。
- 模型里的值不在 `options` 里时，用 `reportIssue` 报出来：弹出按钮和分段控件取消选中，标签页保持原样。用户选中了 `options` 之外的项（例如菜单里另加的项）时，同样报出来，不写回。
- 勾选框不支持混合状态：`.on` 对应 `true`，其余都是 `false`。
- 选项列表在绑定时一次给定；菜单内容随模型变化的情况这次不做。
- 分栏折叠只在改模型时带了动画（`withAppKitAnimation`，或绑定自带的事务）才带动画，与库里其他绑定的做法一致。
- 分栏和标签页不加便捷构造器：它们随视图控制器创建，构造器没有可省的步骤。
- 只改 fork 独有的 AppKitNavigation，不碰与上游共用的 SwiftNavigation 核心。各项目改用新绑定不在这一批。

## 后续项

- 各项目要用新绑定，得先给 fork 打一个包含它们的新版本（目前最新是 2.11.100），再把约 50 处手写代码换掉。
- 菜单内容随模型变化（比如 XCOrganizer 在 `observe {}` 里重建标签菜单）还得手写：`options` 只在绑定时给一次。
- 勾选框的混合状态没有对应的绑定。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-05 | 先做常用控件的类型化绑定，表格选中绑定、状态驱动的独立窗口、简化 `observe` 写法留到以后 | 用户选定。调查中这一块手写代码的处数最多，写法与现有绑定一致，没有设计上的未知数 |
| 2026-11-05 | 选中值按选项数组的顺序对应界面上的项，不按菜单项里存的值 | 用户选定。与各项目现有按 `allCases` 下标的写法一致，任意 `Equatable` 值都能用；代价是菜单里不能夹别的项，便捷构造器按选项生成菜单项来保证顺序 |
| 2026-11-05 | 集合成员勾选框、多选分段控件的单段、菜单项勾号三种附加绑定一起做 | 用户选定 |
| 2026-11-05 | 用户批准，开始实现 | |
| 2026-11-05 | 内部的 `establishBinding` 不再要求被绑定的对象是 `Sendable`；分栏的扩展标 `@MainActor` | SDK 明确声明 `NSSplitViewItem` 不能是 `Sendable`，也没有把它隔离到主 actor，所以既不能像 `NSControl` 那样补一个 `@unchecked Sendable`，它的扩展也默认不在主 actor 上。KVO 回调里改用 `nonisolated(unsafe)` 把对象交给主 actor：这些对象只在主线程上变化、发通知 |
| 2026-11-05 | 菜单项的新扩展同样标 `@MainActor` | `NSMenuItem` 也没有隔离到主 actor，新加的构造器和绑定要调用主 actor 上的绑定机制 |
| 2026-11-05 | 分栏折叠带动画时，在绑定里自己用事务的动画包一层 | `observe` 已经会把更新放进环境事务的动画组里，但绑定自带的事务（`$model.x.animation(…)`）不走那一层；自己包一层，两种情况都经 `animator()` 带上同一个动画 |
| 2026-11-05 | 实现完成，待用户看过后收尾 | 八步全部完成。文档判断：不需要使用指南或实现说明，用法写在各绑定的文档注释和 `swift-navigation-bindings` skill 里，取舍写在本提案里；README 不用改（上游的 README 不列 AppKit 的绑定）；没有新术语 |
| 2026-11-05 | Implemented，编号 0003，落地到 `main` | 用户看过后要求收尾。八步全部完成；没做的三项留在后续项（打 fork 新版本供各项目使用、随模型变化的菜单内容、勾选框的混合状态）。文档判断同上一行，没有新术语 |
