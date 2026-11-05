# 0001 - AppKitNavigation 清理：警告、重复代理和多余依赖

- **状态**: Implemented
- **创建日期**: 2026-11-04
- **最后更新**: 2026-11-04
- **实现分支**: `appkit-navigation-cleanup`

## 摘要

不改用法，把 AppKitNavigation 收拾干净：清掉 fork 自己代码里的 14 条编译警告（其中 3 条在以后的 Swift 语言模式里会变成错误），把 `NSFontManager` 复制出来的那一整套动作代理并回通用实现，去掉只为两个私有数组引入的 `IdentifiedCollections` 依赖，给加在 AppKit 类上的 `@objc` 成员加库前缀，收回一个没必要公开的遵循，删掉文档目录里从 UIKit 抄来的页面。起因是上一批修 bug 时，同样的两个问题要在两份代理里各修一遍；fork 的依赖和 lockfile 也比上游多出两个包。实现中发现 `NSColorPanel.bind(color:)` 一调用就崩溃，用户决定在这一批一起修掉；用户看过后，又要求修掉与上游共用代码里的警告和 Examples 的编译错误（第 9 步）。

## 方案

先补测试，再动代码：

1. **补测试作安全网**（已完成）：每个类型化的 `bind`（开关、滑块、步进器、日期、颜色、路径、分段）各补一条双向测试，颜色面板除外（见决策日志）；字体管理器补一条重新绑定的测试。`NSSavePanel.bind(url:)` 与 `NSOpenPanel.bind(urls:)` 靠交换私有方法 `setFinalURL:` / `setFinalURLs:` 工作，系统去掉它们时现在只会静默失效；补一条测试，让那种情况立即变红。
2. **清警告**（已完成）：
   - `NSControl`、`NSToolbarItem`、`NSColorPanel` 的 `@retroactive Sendable` 改成 `@unchecked @retroactive Sendable`，与 `NSMenuItem`、`NSFontManager` 一致。
   - 两处没用在公开声明里的 `public import Combine` 改成内部导入。
   - 上一批加的 `ControlActionDeliveryTests` 有 7 条并发警告：`makeControl()` 改为 `@MainActor`。
3. **合并字体管理器的代理**（已完成）：删掉 `FontManagerProxy` 和 `NSFontManager` 扩展里复制的 `bind(_:to:set:)`，改走 `TargetActionProxy` 和同一份绑定实现。`NSFontManager.action` 是非可选的 `Selector`，遵循不了 `TargetActionProtocol`，所以只共享内部实现，公开签名不变。实际做法：`TargetActionProxy` 加一个接管字体管理器的构造器；绑定的主体提成内部函数 `establishBinding(_:to:of:through:set:)`，两边的 `bind(_:to:set:)` 都转给它。
4. **去掉 `IdentifiedCollections`**（已完成）：动作列表改用普通数组。四份 `Package*.swift` 删掉这个依赖，`Package.resolved` 随之少掉 `swift-identified-collections` 和 `swift-collections`，依赖条目与上游一致（只剩 `originHash` 不同）；两条 `public import IdentifiedCollections` 的警告一并消失。
5. **加库前缀**（已完成）：`NSSwitch.boolValue`、`NSFontManager._selectedFont` 改成带 `appKitNavigation` 前缀的名字（`appKitNavigationIsOn`、`appKitNavigationSelectedFont`）。macOS 27.2 的 AppKit 里还没有同名方法，可一旦重名，Swift 扩展会悄悄替换掉系统实现——上一批修的 `textViewDidChangeSelection:` 就是这样坏的。两者都不是公开成员。另加一条测试守住这一类：扫描本库加在系统类上的 Objective-C 方法，名字里都要带库名，shim 有意替换的五个方法除外。
6. **收回 `AnyCancellable` 的公开 `Sendable` 遵循**（已完成）：它只是为了在 `ObserveToken` 的闭包里捕获订阅，改用局部的 `nonisolated(unsafe) let`，库里已有同样的写法。
7. **文档**（已完成）：删掉 `AppKitNavigation.docc` 里从 UIKit 抄来的 12 个页面（上游的 AppKitNavigation 没有它们），首页加一段概述和「绑定」「导航」两组目录；生成一次文档，确认没有新的 DocC 警告。实际还顺带修了 fork 自己的文档注释：文本框焦点绑定的示例和说明是从 UIKit 抄的，改成 AppKit 的写法；删掉不存在的参数说明，补上分段控件缺的参数说明。AppKitNavigation 的 DocC 警告从 23 条降到 3 条，剩下的都来自与上游共用的内容。
8. **修颜色面板绑定的崩溃**（已完成，实现中加入）：`NSColorPanel` 遵循 `TargetActionProtocol` 时，`action` 的 getter 经 KVC 读面板的 action，而 KVC 返回不了 selector，抛出 `NSUnknownKeyException`；绑定在接管面板的 target/action 前要先读它，所以每次调用 `bind(color:)` 都崩溃。改为直接调用 AppKit 未公开但一直实现着的 `-action`，并用 `responds(to:)` 兜底。先补两条测试（面板能报出设置给它的 action；颜色面板的双向绑定），修之前崩溃，修之后通过。
9. **用户看过后追加的修复**（已完成）：
   - `AppKitAnimation.perform(_:completion:)` 的 `completion` 改为 `@Sendable`，消掉它被捕获进 `NSAnimationContext` 完成回调时的警告；唯一的调用方原本就只捕获 `Sendable` 的值。调用方原来的三目写法在 Swift 6.4 下会让类型检查器报「failed to produce diagnostic」，改成 `if` 赋值。
   - `observe(_:)` 的两个重载在 Swift 6.4 上加 `@diagnose(ConversionFromIsolatedAnyToSynchronous, as: ignored, …)`（SE-0522），屏蔽「`@isolated(any)` 函数转成同步函数」的警告。这次同步转换是有意的：观察追踪要求同步执行；签名保留 `@isolated(any)`，因为上游靠它支持 `observe { @MainActor in … }` 这类显式指定隔离的写法。旧编译器不认这个属性，用 `#if hasAttribute(diagnose)` 包起来。
   - Examples 里三处 `import XCTestDynamicOverlay` 改成 `import IssueReporting`，`XCTFail` 改成 `reportIssue`。上游把依赖升到 `swift-issue-reporting` 2.0 后，依赖图里不再有 `XCTestDynamicOverlay` 这个模块，CaseStudies 因此编不过。
   - 工作区锁定文件 `SwiftNavigation.xcworkspace/xcshareddata/swiftpm/Package.resolved` 重新解析。原来那份和上游一样过时：钉着 `swift-case-paths` 的一个分支，还拉进旧地址的 `xctest-dynamic-overlay`，和 `swift-issue-reporting` 产品名冲突，命令行从零解析时直接失败。新的 pin 与 Xcode 实际解析出的版本一致。

没有询问就采用的假设：

- 公开 API 除第 6 条外不变。第 6 条严格说去掉了一个公开遵循；本机依赖这个 fork 的 7 个项目，都没有在 import AppKitNavigation 的文件里用 `AnyCancellable`，所以按轻量档处理。
- 这 7 个项目也都没有自己 import `IdentifiedCollections`，去掉依赖不影响它们。
- 保留 `TargetActionProtocol` 的 `Sendable` 要求和各控件的 `Sendable` 遵循：去掉它们才是真正的破坏性改动。
- 只动 fork 独有的文件，不碰与上游共用的 `SwiftNavigation` 和 UIKit 部分；四份清单的改动是向上游靠拢。
- 验证：Xcode 27.2 跑 AppKit 的全部测试，Xcode 26.6 编译 AppKit 的库和测试。
- 不在这一批：弹出相关三个文件（约 1,300 行）的重载收敛，连同 `Navigated.clearup()` 死代码（见 [ReviewDecisions.md](../Internal/ReviewDecisions.md)），属于大型重构，另起完整档提案；新功能各自另起提案。

## 后续项

- AppKit 的 Swift Testing 测试偶尔会中途结束，退出码却是 0，没跑完的测试结果就此丢失；`main` 上同样存在。用 lldb 查到：分段控件的 `performClick`、保存和打开面板的创建（`-[NSSavePanel _initBridgeAndStuff]` 等待远程面板的信号量）都会跑嵌套 run loop，偶尔把一个 `CFRunLoopStop` 漏给外层；而测试进程的主执行器在主 run loop 一返回就 `exit(0)`。去掉分段控件的点击用例不能根治，来源不止一处。修法要改测试基础设施，例如把这类测试移到 XCTest，或在主 run loop 退出时接着运行，留给另一批。（已修：在主 run loop 被误停时接着运行，见 [draft-appkit-test-run-loop-exit.md](draft-appkit-test-run-loop-exit.md)。）
- `NSPathControl` 的便捷构造器把 URL 绑定的参数标签写成了 `date:`，应为 `url:`；改它要动公开 API，不在这一批。（已修：直接改名为 `url:`，与上一项在同一分支上提交。）

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-04 | Created as Draft | 修 bug 的那一批已落地，按审查清单的顺序接着处理优化项；这一批只收不改用法的清理 |
| 2026-11-04 | Accepted | 用户批准，开始实现 |
| 2026-11-04 | 第 1 步不含颜色面板的双向测试 | 写测试时发现 `NSColorPanel.bind(color:)` 一调用就崩溃（见后续项），崩溃的测试会中断整个测试进程；修它属于修 bug，不在这一批的范围里 |
| 2026-11-04 | 字体管理器补一条重新绑定的测试 | 第 3 步改动的正是解绑时移除回写动作的那段代码，现有测试没覆盖它 |
| 2026-11-04 | 现有的两条面板测试在调用私有方法前先确认它存在 | 方法不在时直接调用会让整个测试进程崩溃，金丝雀测试的结果也就看不到了 |
| 2026-11-04 | `AppKitAnimation.swift` 里的一条 `Sendable` 警告不改，记进 [ReviewDecisions.md](../Internal/ReviewDecisions.md) | 起草时的 14 条是增量构建统计的，漏了这个没重新编译的文件；用全新的构建目录重编一遍才看到它。它是与上游共用的代码，按上面的假设不碰 |
| 2026-11-04 | 第 5 步加一条命名测试，扫描本库加在系统类上的方法 | 只改两个名字，管不住以后再加的成员；测试先红（正好报出这两个成员的四个方法），改名后变绿 |
| 2026-11-04 | 命名测试放在主线程上跑 | 第一版没标 `@MainActor`：在后台线程写出 `NSView.self` 会在那条线程上执行 `+initialize`，让 AppKit 认错了线程。并行跑的其他测试随后在主线程处理事件时陷入断言陷阱，或者在打开面板时抛出 `already on an AppKit thread`，10 次里崩了 4 次；放到主线程后连跑 20 次没有再崩 |
| 2026-11-04 | 文档一步顺带修了 fork 自己的文档注释 | 生成文档时这些注释贡献了大部分 DocC 警告，而且文本框焦点绑定的示例是 UIKit 代码，照着写编不过 |
| 2026-11-04 | 实现完成，待用户看过后收尾 | 七步都已提交。Xcode 27.2 上 AppKit 测试全过（XCTest 16 条、Swift Testing 31 条），整个包只剩基线上本来就失败的 `ButtonStateTests.testAsyncAnimationWarning`；Xcode 26.6 编得过 AppKit 的库和测试；全新构建目录下 AppKit 只剩上游那一条警告。文档判断：README 不用改（用法没变）；不需要使用指南或实现说明（没有新的调用契约）；没有新术语；`swift-navigation-bindings` skill 不用改（公开用法没变） |
| 2026-11-04 | 颜色面板绑定的崩溃在这条分支上一起修（第 8 步） | 用户看过汇报后决定收尾前一起修，不另开一批 |
| 2026-11-04 | 修法：直接调用 AppKit 未公开的 `-action`，用 `responds(to:)` 兜底 | 让 getter 直接返回 `nil` 也不会崩，但绑定接管面板的 target/action 之后，就转发不了用户原先设的 action；改成监听颜色变化的通知、不再接管，又得改公开的 `TargetActionProtocol` 遵循。本机导出的 AppKit 头文件里，macOS 12.0.1、26.4–26.6、27.0、27.2 都有这个 getter。出问题的写法是 2024-10-11 加入颜色面板绑定时写下的，之后没改过，也没人修过；本机依赖这个 fork 的项目都没用到这个绑定 |
| 2026-11-04 | 测试进程中途以 0 退出的问题查明原因，不在这批修（见后续项） | 加入颜色面板测试后截断变得频繁，于是追查：问题出在 AppKit 嵌套 run loop 与测试进程主执行器的交互上，`main` 上本来就有；试着去掉分段控件的点击用例，并不能根治，已恢复原样。根治要改测试基础设施，超出这一批的范围 |
| 2026-11-04 | 第 8 步完成，重新验证 | Xcode 27.2 上 AppKit 测试完整跑通（Swift Testing 33 条、XCTest 16 条，有汇总行为证）；Xcode 26.6 编得过 AppKit 的库和测试，只剩上游那一条警告 |
| 2026-11-04 | 按用户要求修与上游共用代码里的警告和 Examples 的编译错误（第 9 步） | 用户在 Xcode 里看到了这几条警告和 CaseStudies 的报错，要求一并修掉。这推翻了「只动 fork 独有的文件」那条假设，代价是以后合并上游时 `Observe.swift`、`AppKitAnimation.swift`、`UITransaction.swift` 和 Examples 可能冲突；原先记进裁决清单的「`AppKitAnimation.swift` 警告不修」随之删除 |
| 2026-11-04 | `observe(_:)` 用 `@diagnose` 屏蔽警告，不改签名 | 编译器对这类转换没有豁免写法，官方建议只有改成 async 或去掉 `@isolated(any)`：前者做不到（观察追踪必须同步），后者会让显式指定隔离的写法退化。代价是 Xcode 26.6（Swift 6.2）不认识这个属性，那两条警告在旧编译器上仍在，记进裁决清单 |
| 2026-11-04 | 工作区锁定文件一并更新 | 不更新的话，命令行和全新 clone 解析 Examples 的依赖时会因产品名冲突失败；新 pin 与 Xcode 里实际用的版本逐个核对过 |
| 2026-11-04 | 第 9 步完成，重新验证 | 全新构建目录下，Xcode 27.2 编 SwiftNavigation、AppKitNavigation 和 AppKit 测试零警告；整个包的测试只剩基线上的 `ButtonStateTests.testAsyncAnimationWarning`；CaseStudies 与 Inventory 用 xcodebuild 编 macOS 版成功（Inventory 关掉签名）；Xcode 26.6 编得过 |
| 2026-11-04 | Implemented，编号 0001，落地到 `main` | 用户看过效果后要求收尾。九步全部完成；没做的两项留在后续项（测试进程中途以 0 退出、`NSPathControl` 构造器标签）。文档判断：不需要使用指南或实现说明，没有新的调用契约，难懂的决定都写在代码注释和本提案里；没有新术语；README 和 `swift-navigation-bindings` skill 不用改，公开用法没变 |
