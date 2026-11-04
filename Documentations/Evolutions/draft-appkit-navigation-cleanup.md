# Draft - AppKitNavigation 清理：警告、重复代理和多余依赖

- **状态**: In Progress
- **创建日期**: 2026-11-04
- **最后更新**: 2026-11-04
- **实现分支**: `appkit-navigation-cleanup`

## 摘要

不改用法，把 AppKitNavigation 收拾干净：清掉现有的 14 条编译警告（其中 3 条在以后的 Swift 语言模式里会变成错误），把 `NSFontManager` 复制出来的那一整套动作代理并回通用实现，去掉只为两个私有数组引入的 `IdentifiedCollections` 依赖，给加在 AppKit 类上的 `@objc` 成员加库前缀，收回一个没必要公开的遵循，删掉文档目录里从 UIKit 抄来的页面。起因是上一批修 bug 时，同样的两个问题要在两份代理里各修一遍；fork 的依赖和 lockfile 也比上游多出两个包。

## 方案

先补测试，再动代码：

1. **补测试作安全网**（已完成）：每个类型化的 `bind`（开关、滑块、步进器、日期、颜色、路径、分段）各补一条双向测试，颜色面板除外（见决策日志）；字体管理器补一条重新绑定的测试。`NSSavePanel.bind(url:)` 与 `NSOpenPanel.bind(urls:)` 靠交换私有方法 `setFinalURL:` / `setFinalURLs:` 工作，系统去掉它们时现在只会静默失效；补一条测试，让那种情况立即变红。
2. **清警告**（已完成）：
   - `NSControl`、`NSToolbarItem`、`NSColorPanel` 的 `@retroactive Sendable` 改成 `@unchecked @retroactive Sendable`，与 `NSMenuItem`、`NSFontManager` 一致。
   - 两处没用在公开声明里的 `public import Combine` 改成内部导入。
   - 上一批加的 `ControlActionDeliveryTests` 有 7 条并发警告：`makeControl()` 改为 `@MainActor`。
3. **合并字体管理器的代理**（已完成）：删掉 `FontManagerProxy` 和 `NSFontManager` 扩展里复制的 `bind(_:to:set:)`，改走 `TargetActionProxy` 和同一份绑定实现。`NSFontManager.action` 是非可选的 `Selector`，遵循不了 `TargetActionProtocol`，所以只共享内部实现，公开签名不变。实际做法：`TargetActionProxy` 加一个接管字体管理器的构造器；绑定的主体提成内部函数 `establishBinding(_:to:of:through:set:)`，两边的 `bind(_:to:set:)` 都转给它。
4. **去掉 `IdentifiedCollections`**：动作列表改用普通数组。四份 `Package*.swift` 删掉这个依赖，`Package.resolved` 随之少掉 `swift-identified-collections` 和 `swift-collections`，与上游一致；两条 `public import IdentifiedCollections` 的警告一并消失。
5. **加库前缀**：`NSSwitch.boolValue`、`NSFontManager._selectedFont` 改成带 `appKitNavigation` 前缀的名字。macOS 27.2 的 AppKit 里还没有同名方法，可一旦重名，Swift 扩展会悄悄替换掉系统实现——上一批修的 `textViewDidChangeSelection:` 就是这样坏的。两者都不是公开成员。
6. **收回 `AnyCancellable` 的公开 `Sendable` 遵循**：它只是为了在 `ObserveToken` 的闭包里捕获订阅，改用局部的 `nonisolated(unsafe) let`，库里已有同样的写法。
7. **文档**：删掉 `AppKitNavigation.docc` 里从 UIKit 抄来的 12 个页面（上游的 AppKitNavigation 没有它们），首页加「绑定」「导航」两组目录；生成一次文档，确认没有新的 DocC 警告。

没有询问就采用的假设：

- 公开 API 除第 6 条外不变。第 6 条严格说去掉了一个公开遵循；本机依赖这个 fork 的 7 个项目，都没有在 import AppKitNavigation 的文件里用 `AnyCancellable`，所以按轻量档处理。
- 这 7 个项目也都没有自己 import `IdentifiedCollections`，去掉依赖不影响它们。
- 保留 `TargetActionProtocol` 的 `Sendable` 要求和各控件的 `Sendable` 遵循：去掉它们才是真正的破坏性改动。
- 只动 fork 独有的文件，不碰与上游共用的 `SwiftNavigation` 和 UIKit 部分；四份清单的改动是向上游靠拢。
- 验证：Xcode 27.2 跑 AppKit 的全部测试，Xcode 26.6 编译 AppKit 的库和测试。
- 不在这一批：弹出相关三个文件（约 1,300 行）的重载收敛，连同 `Navigated.clearup()` 死代码（见 [ReviewDecisions.md](../Internal/ReviewDecisions.md)），属于大型重构，另起完整档提案；新功能各自另起提案。

## 后续项

- `NSColorPanel.bind(color:)` 一调用就崩溃：它经 KVC 读面板的 `action`，而 KVC 返回不了 `SEL`，抛出 `NSUnknownKeyException`。原本就有，由第 1 步的测试发现，不在这一批修。
- `NSPathControl` 的便捷构造器把 URL 绑定的参数标签写成了 `date:`，应为 `url:`；改它要动公开 API，不在这一批。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-04 | Created as Draft | 修 bug 的那一批已落地，按审查清单的顺序接着处理优化项；这一批只收不改用法的清理 |
| 2026-11-04 | Accepted | 用户批准，开始实现 |
| 2026-11-04 | 第 1 步不含颜色面板的双向测试 | 写测试时发现 `NSColorPanel.bind(color:)` 一调用就崩溃（见后续项），崩溃的测试会中断整个测试进程；修它属于修 bug，不在这一批的范围里 |
| 2026-11-04 | 字体管理器补一条重新绑定的测试 | 第 3 步改动的正是解绑时移除回写动作的那段代码，现有测试没覆盖它 |
| 2026-11-04 | 现有的两条面板测试在调用私有方法前先确认它存在 | 方法不在时直接调用会让整个测试进程崩溃，金丝雀测试的结果也就看不到了 |
