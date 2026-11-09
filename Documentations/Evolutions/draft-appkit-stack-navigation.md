# Draft - 可选集成 AppKitPlus：把 UIKit 的栈式导航搬到 AppKit

- **状态**: In Progress
- **作者**: JH
- **创建日期**: 2026-11-09
- **最后更新**: 2026-11-09
- **所属愿景**: 无
- **关联提案**: [0005](0005-appkit-presentation-redesign.md)（弹出的共用生命周期）、[0004](0004-appkit-table-selection-bindings.md)（表格与大纲的选中绑定）
- **实现分支 / PR**: `appkit-stack-navigation`
- **配套文档**: 待定 —— 落地时判断要不要写打开 trait 的使用指南

## 摘要

给 AppKitNavigation 加一个默认关闭的 package trait `AppKitPlus`。打开后，AppKitNavigation 依赖 AppKitPlus-Release（0.21.0 起，只在 macOS 上），借它的 `NSNavigationController` 和 trait 机制，提供 UIKitNavigation 已有的四块能力：

1. 路径驱动的栈 `NavigationStackController`，以及 `navigationDestination(for:destination:)`、`push(value:)`；
2. 按状态推入的 `navigationDestination(isPresented:)`、`navigationDestination(item:)`；
3. 让内容自己关掉的 `dismiss()`，对推入的内容和经 `present`、`sheet`、`modal`、`modalSession`、`popover` 弹出的内容都生效；
4. 直接接受 AppKitPlus 数据源的表格、大纲选中绑定。

trait 关闭时，包的依赖、最低系统（6.2 那份清单除外，见「影响」）和公开 API 都与现在一样。

## 动机

- **AppKit 没有导航控制器**，所以 AppKitNavigation 缺了 UIKitNavigation 的整块栈式导航：`NavigationStackController`、`push(value:)`、`navigationDestination(for:)`、`navigationDestination(isPresented:/item:)`，以及经 trait 传下去的 `push`、`dismiss` 两个动作。AppKit 案例列表里「Stack navigation」一组至今是注释掉的（`Examples/CaseStudies/AppKit/AppKitCaseStudies.swift`）。
- **AppKitPlus 正好补上 UIKit 版依赖的两样东西**：一个导航控制器 `NSNavigationController`（移植自 OpenUXKit），和一套与 UIKit 同形的 trait 机制（`NSTraitDefinition`、`traitCollection`、`traitOverrides`）。
- **内容没法统一地关掉自己。** 被弹出的内容现在只能由宿主改状态，或者按自己是怎么被弹出的去调用不同的 AppKit 方法（`dismiss(_:)`、`endSheet(_:)`、`stopModal()`……）。UIKit 版用一个 `traitCollection.dismiss()` 统一了这件事。
- **用户自己的 App 在用 AppKitPlus。** 调查过依赖这个 fork 的 6 个 App：4 个依赖 AppKitPlus-Release；XCOrganizer 的内容列表用 AppKitPlus 的 `NSOutlineViewDiffableDataSource`，选中靠代理方法手写同步。没有 App 在用它的导航控制器——栈式导航是给以后用的新能力，不是替换现有的手写代码。

## 前期调研

- **AppKitPlus 的分发**：Objective-C 框架，经 `AppKitPlus-Release`（`https://github.com/AppKitSupportProgram/AppKitPlus-Release`）以二进制 xcframework 分发：`swift-tools-version: 5.9`、`.macOS(.v12)`、没有依赖、MIT 许可；README 写明不承诺 API 与 ABI 稳定，框架是动态库，要嵌进 App。
  - 要用的 API（`NSNavigationController`、`NSTraitDefinition` 与 `traitOverrides`、`NSOutlineViewDiffableDataSource`）从 0.1.1 起每个版本都有。
  - 0.20.0 删过 `NSNavigationItem` 的几个属性、不再公开 `NSTransitionController`；0.21.0 没有动这几块。
  - 下游 App 现在解析到 0.18 至 0.21。
- **trait 守着的依赖**（UIFoundation 的提案 0017 在 Swift 6.2 上实测）：
  - trait 关闭时，只有 trait 用到的依赖不解析、不下载、不进 `Package.resolved`。这是 SwiftPM 6.2 起的行为（swift-package-manager 的 PR 8852，挑进 6.2 的 PR 8948）；6.1 上没有验证。
  - trait 打开时，依赖方的清单必须声明 macOS 12 起，否则直接报错：`the library 'Probe' requires macos 10.15, but depends on the product 'AppKitPlus' which requires macos 12.0`。`@available` 和 `#if` 都绕不开。
- **fork 的清单**：`Package.swift`（tools 6.4，macOS 12，有 trait）；`Package@swift-6.2.swift`、`Package@swift-6.1.swift`（macOS 10.15，有 trait）；`Package@swift-6.0.swift`（没有 trait）。只被部分 target 用的依赖，已经用 `.product(…, condition: .when(traits: […]))` 声明（CasePaths、CustomDump 等）。Xcode 27 读 `Package.swift`，Xcode 26.x（Swift 6.2、6.3）读 6.2 那份。
- **在 Xcode 里开 trait**：Xcode 26.4 起可以在工程的 Package Dependencies 里给依赖打开 trait，`project.pbxproj` 记为 `traits = (…);`，本地和远程的包引用都支持（UIFoundation 的示例工程就这样开）。下游 App 打开 UIFoundation 的 `AppKitPlus` trait，都写在自己的 `Package.swift` 里。
- **AppKitPlus 的 `NSNavigationController`**（`AppKitPlus/Navigation Controller/NSNavigationController.h`）：
  - `pushViewController(_:animated:)`、`popViewController(animated:)`、`popToViewController(_:animated:)`、`setViewControllers(_:animated:)`；动画只有一个 `BOOL`，没有完成回调，过渡进行中的请求会排队。
  - 用户返回有三条路：控制器自己导航栏里的返回按钮、⌘↑、触控板双指轻扫，都走 `popViewControllerAnimated:` 或 `popToViewController:animated:`。没有专门的「用户返回」回调；代理有 `willShow`、`didShow`（不带 `animated`）和否决用的 `shouldPop`。
  - 弹出控制器时调用 `willMove(toParent: nil)` 和 `removeFromParent()`，**从不调用 `didMove(toParent: nil)`**。UIKit 版正是靠后者得知用户返回的，这里要换一种办法。
  - 它已经在 `NSViewController` 上定义了 `navigationController` 和 `navigationItem`，这两个名字归它。
- **UIKit 版怎么做的**（`Sources/UIKitNavigation/Navigation/`）：
  - `NavigationStackController` 继承 `UINavigationController`，`path` 是绑到 `Hashable` 元素集合或 `UINavigationPath` 的 `UIBinding`；在 `observe` 里比对路径与栈，推入、弹出或 `setViewControllers`；包一层代理，在 `didShow` 之后把路径截到栈上还在的那部分。
  - `push(value:)` 和 `dismiss` 经 trait（`traitOverrides`）传给子控制器。
  - `navigationDestination(item:)` 建在私有的 `destination(item:id:content:present:dismiss:)` 上，靠 shim 交换 `didMoveToParentViewController:` 得知用户返回。
- **`UINavigationPath`** 定义在共用模块 `SwiftNavigation` 里（`Sources/SwiftNavigation/UINavigationPath.swift`），只依赖 Foundation，AppKit 可以直接用。
- **0005 的弹出生命周期**（`Sources/AppKitNavigation/Navigation/BindingPresenter.swift`）：`BindingPresenter` 加 `PresentationStyle`（`whenReady`、`begin(_:transaction:didEnd:)`、`end(_:transaction:)`），已经处理了 id 变化时先收起旧的、`onDismiss` 每次只调一次、用户关闭时写回 `nil`。推入可以作为一种新的 style 接进来。

## 提议方案

**trait 与依赖**

- 新 trait `AppKitPlus`，默认关闭，只声明在 `Package.swift` 和 `Package@swift-6.2.swift` 里。6.2 那份的最低系统从 macOS 10.15 抬到 12；`Package@swift-6.1.swift`、`Package@swift-6.0.swift` 不动，这两个工具链用不了这批 API。
- `AppKitNavigation` 加一个依赖：AppKitPlus-Release 0.21.0 起，条件是 macOS 且 trait 打开。
- 新代码都放在 `AppKitNavigation` 里，用 `#if AppKitPlus` 包住。trait 关闭时，模块的公开 API 与现在完全一样。

**四块能力**（trait 打开后）

1. **路径驱动的栈**：`NavigationStackController` 继承 AppKitPlus 的 `NSNavigationController`，`path` 绑到 `Hashable` 元素的集合或 `UINavigationPath`。`navigationDestination(for:destination:)` 登记每种元素对应的控制器；`push(value:)` 和 `traitCollection.push(value:)` 往路径上加元素。用户经返回按钮、⌘↑ 或轻扫返回后，路径截到栈上还在的部分。
2. **按状态推入**：`NSViewController.navigationDestination(isPresented:)`、`navigationDestination(item:)` 等，形状与现有的 `present` 一样。状态有值时推入，变成 `nil` 时弹出，用户返回时写回 `nil`，id 变化时先弹出旧的再推入新的。作为一种新的 `PresentationStyle` 接进 `BindingPresenter`，`onDismiss` 的语义与其他弹出一致。
3. **`dismiss()`**：`traitCollection.dismiss` 与 `traitCollection.isPresented`。推入的内容，以及经 `present`、`sheet`、`modal`、`modalSession`、`popover` 弹出的内容，在里面调用 `dismiss()` 就经它自己的 binding 关掉，与用户关闭一样写回、调用 `onDismiss`。
4. **AppKitPlus 数据源的选中绑定**：`NSTableView` 接受 `NSTableViewDiffableReorderableDataSource`、`NSOutlineView` 接受 `NSOutlineViewDiffableDataSource` 的 `bind(selection:dataSource:)`，写法与 0004 的系统数据源版本一致。

**示例**：Examples 工程给本地的 fork 引用打开 `AppKitPlus` trait，恢复 AppKit 案例列表里的「Stack navigation」一组，照 UIKit 版补两个栈案例。

### 非目标

- 不支持 Swift 6.0、6.1 工具链。
- 不做状态恢复和 deep link（UIKit 版也只写了 TODO）。
- 不改 AppKitPlus 本身，它的已知限制照单接受。
- trait 关闭时，不为栈式导航、`dismiss()` 和这些选中绑定提供任何替代实现。
- 表格和大纲的多选不在这一批。
- 不发版；下游 App 的迁移不在这一批。

## 详细设计

清单（`Package.swift` 与 `Package@swift-6.2.swift`）：

```swift
traits: [
  // ...the existing traits...
  .trait(
    name: "AppKitPlus",
    description: "Stack navigation, dismiss actions and AppKitPlus data source bindings in AppKitNavigation."
  ),
],
dependencies: [
  .package(url: "https://github.com/AppKitSupportProgram/AppKitPlus-Release", from: "0.21.0"),
],
// In the AppKitNavigation target's dependencies:
.product(
  name: "AppKitPlus",
  package: "AppKitPlus-Release",
  condition: .when(platforms: [.macOS], traits: ["AppKitPlus"])
),
```

调用点：

```swift
// A stack driven by a path
let stackController = NavigationStackController(path: $model.path) {
  ListViewController(model: model)
}
listViewController.navigationDestination(for: Planet.self) { planet in
  PlanetViewController(planet: planet)
}
traitCollection.push(value: Planet.mars)

// Pushing from optional state
navigationDestination(item: $model.detail) { detail in
  DetailViewController(model: detail)
}

// Content closing itself, whether it was pushed or presented
traitCollection.dismiss()

// AppKitPlus data sources
outlineView.bind(selection: $model.selectedItemID, dataSource: outlineDataSource)
```

签名（都只在 `#if AppKitPlus` 时存在）：

```swift
open class NavigationStackController: NSNavigationController {
  public required init<Data: RandomAccessCollection & RangeReplaceableCollection>(
    navigationBarClass: AnyClass? = nil,
    toolbarClass: AnyClass? = nil,
    path: UIBinding<Data>,
    root: () -> NSViewController
  ) where Data.Element: Hashable

  public required init(
    navigationBarClass: AnyClass? = nil,
    toolbarClass: AnyClass? = nil,
    path: UIBinding<UINavigationPath>,
    root: () -> NSViewController
  )
}

extension NSViewController {
  public func navigationDestination<Element: Hashable>(
    for data: Element.Type,
    destination: @escaping (Element) -> NSViewController
  )

  public func push<Element: Hashable>(value: Element)

  @discardableResult
  public func navigationDestination(
    isPresented: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> NSViewController
  ) -> ObserveToken

  @discardableResult
  public func navigationDestination<Item: Identifiable>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> NSViewController
  ) -> ObserveToken

  // Plus the item:id: shape and the two shapes whose content takes a UIBinding<Item>,
  // the same five shapes present(...) has, the UIBinding ones @_disfavoredOverload.
}

@MainActor
public struct AppKitPushAction: Sendable {
  public func callAsFunction<Element: Hashable>(
    value: Element,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  )
}

@MainActor
public struct AppKitDismissAction: Sendable {
  public func callAsFunction()
}

extension NSTraitCollection {
  public var push: AppKitPushAction { get }
  public var dismiss: AppKitDismissAction { get }
  public var isPresented: Bool { get }
}

extension NSTableView {
  @discardableResult
  public func bind<SectionIdentifier, ItemIdentifier>(
    selection: UIBinding<ItemIdentifier?>,
    dataSource: NSTableViewDiffableReorderableDataSource<SectionIdentifier, ItemIdentifier>
  ) -> ObserveToken
}

extension NSOutlineView {
  @discardableResult
  public func bind<ItemIdentifier>(
    selection: UIBinding<ItemIdentifier?>,
    dataSource: NSOutlineViewDiffableDataSource<ItemIdentifier>
  ) -> ObserveToken
}
```

几处设计要点：

- **命名**：两个动作类型照库里 AppKit 专属类型的叫法（`AppKitAnimation`、`AppKitTextSelection`），叫 `AppKitPushAction`、`AppKitDismissAction`，对应 UIKit 的 `UIPushAction`、`UIDismissAction`。控制器照 UIKit 版叫 `NavigationStackController`。
- **动画**：推入和弹出默认带动画；当前事务的 `appKit.disablesAnimations` 为真时不带，与 popover 的做法一致。
- **得知用户返回**：AppKitPlus 不发 `didMove(toParent: nil)`。路径驱动的栈像 UIKit 版一样包一层代理，在 `didShow` 之后比对栈与路径。按状态推入的内容可能在任意 `NSNavigationController` 里，不能占用它的代理：实现时先用测试确认 AppKitPlus 弹出控制器时 `willMove(toParent:)`、`removeFromParent()`、视图离开窗口的先后，再决定从哪一处得知，结论记进决策日志。
- **`dismiss` 怎么传下去**：内容显示之前，在它的 `traitOverrides` 里放一个 `dismiss` 动作，调用时走 `BindingPresenter` 里「用户关闭」那条路——写回 `nil`（身份仍匹配时），收起内容，离屏后调用 `onDismiss`。视图控制器放在它自己身上；窗口与存取面板放在窗口的内容视图控制器上，没有的话放在内容视图上；alert 没有可供调用的地方，不放。
- **选中绑定**：转调 0004 的 `bind(selection:row:itemIdentifier:)`。AppKitPlus 大纲数据源的 `row(forItemIdentifier:)` 在项不可见时返回 `-1` 而不是 `nil`，转调时换成 `nil`。

## 替代方案考量

- **另开一个包**（同时依赖 fork 和 AppKitPlus-Release）：fork 的清单一行不改；但按状态推入和 `dismiss` 要用 `BindingPresenter` 等内部机制，得把它们作为 SPI 公开，两个包的版本也要一直对齐。用户选了 trait。
- **trait 只放进 `Package.swift`**：其余清单与上游一致，但 Xcode 26.x 用不了。用户选了 6.4 和 6.2 两份。
- **连 `Package@swift-6.1.swift` 也加**：6.1 在 trait 关闭时是否仍会解析、钉住 AppKitPlus 没有验证，可能让所有用 6.1 的使用方都去拉一个用不到的二进制包。不做。
- **自己写一个 AppKit 导航控制器**：返回按钮、轻扫手势、过渡动画都要从头写，AppKitPlus 已有成熟实现。不做。
- **`dismiss()` 只管推入**：与 UIKit 版不一致，弹出的内容仍要按弹出方式各写各的关闭。用户选了推入和弹出都管。
- **AppKitPlus 从 0.18.0 或 0.20.0 起**：能少让下游升级，但要另外编译验证旧版本，实现还得避开 0.20 改过的 API。用户选了 0.21.0。
- **照 UIKit 版交换 `didMoveToParentViewController:`**：AppKitPlus 从不在弹出时发这个回调，换了也收不到。

## 影响

### 源码兼容性（source compatibility）

- **纯新增**。trait 关闭时公开 API 不变；打开时只新增上面列出的类型和方法。
- 打开 trait 后，AppKitPlus 加在系统类上的成员（例如 `NSViewController.navigationController`、`navigationItem`）在 import 了 AppKitNavigation 的文件里也可见，可能与 App 自己的同名扩展冲突。只影响打开了 trait 的使用方。

### ABI 兼容性（条件项）

不适用 —— 本库以 SPM 源码分发，使用方每次重新编译。

### 下游影响

- 本仓库：`AppKitNavigation` 多一个条件依赖；`AppKitNavigationTests` 多一组只在 trait 打开时编译的测试；Examples 工程打开 trait、多依赖 AppKitPlus-Release。
- **`Package@swift-6.2.swift` 的最低系统抬到 macOS 12，不论 trait 开没开都生效**：用 Xcode 26.x 的使用方，部署目标低于 macOS 12 时会编不过。依赖这个 fork 的 App 部署目标都在 macOS 14 以上，不受影响。
- 下游 App 要用这批 API，要在自己的 `Package.swift` 里打开 trait；XCOrganizer（AppKitPlus 0.18）和 PrivateSymbols（0.19）打开时，AppKitPlus 要一起升到 0.21。不打开就没有任何变化。

### 文档与示例

- DocC 首页加一组「栈式导航」（注明需要打开 `AppKitPlus` trait），登记新类型与新方法；生成文档时打开 trait。
- `swift-navigation-bindings` skill 补上栈式导航、`dismiss()` 和新的选中绑定。
- Examples：恢复 AppKit 案例列表里的「Stack navigation」一组，补两个栈案例。

## API 演进与废弃策略

- 没有被替代的旧 API，不需要废弃期。
- 纯新增，fork 下次发版按 minor 处理；这一批不发版。

## 落地步骤

1. **trait 与依赖**（已完成）：两份清单加 trait 和依赖，6.2 那份抬到 macOS 12。trait 关闭、打开各编译一次 AppKitNavigation，确认关闭时不解析 AppKitPlus。
2. **路径驱动的栈**（已完成）：`NavigationStackController`、`navigationDestination(for:destination:)`、`push(value:)`、`traitCollection.push`。先写测试：改路径时推入、弹出；用户返回后路径被截短。
3. **按状态推入**（已完成）：推入用的 `PresentationStyle` 和五种 `navigationDestination` 重载。先用测试确认 AppKitPlus 弹出控制器时的回调顺序，再写实现。
4. **`dismiss()`**（已完成）：`traitCollection.dismiss` 与 `isPresented`，接进推入和现有五种弹出，各配测试。
5. **AppKitPlus 数据源的选中绑定**（已完成）：两个 `bind(selection:dataSource:)`，各配双向测试。
6. **示例**：Examples 工程打开 trait，恢复「Stack navigation」一组，补两个案例；CaseStudies 的 macOS 版只编译，不点界面。
7. **文档与验证**：DocC 首页与 skill；判断要不要写打开 trait 的使用指南。Xcode 27.2 跑 AppKit 的全部测试，trait 关闭、打开各一次；Xcode 26.6 在 trait 打开时编译库和 AppKit 测试。

**收尾时必须判断两件事**（判断结果写进决策日志，不允许沉默跳过）：

- **要不要配套专题文章** —— 有「从 API 签名看不出来的调用方契约」就写使用指南；有「下次维护会踩、代码本身看不出来的决策」就写实现说明。写了就登记到头部的「配套文档」。
- **有没有引入新术语** —— 有就同批次登记进术语表。

## 决策日志

| 日期 | 变更 | 说明 |
|------|------|------|
| 2026-11-09 | Created as Draft | 调查下游 App 时，用户提出可选地集成 AppKitPlus，并把 UIKit 的栈式导航搬到 AppKit；属于完整档，先经三轮澄清提问 |
| 2026-11-09 | 用 package trait 集成，不另开一个包 | 用户选定。同一个包里能直接复用 `BindingPresenter` 等内部机制，不必公开 SPI；做法与 UIFoundation 的 `AppKitPlus` trait 一致 |
| 2026-11-09 | 搬四块：路径驱动的栈、按状态推入、`dismiss()`、AppKitPlus 数据源的选中绑定 | 用户选定 |
| 2026-11-09 | trait 只放进 `Package.swift` 和 `Package@swift-6.2.swift`，后者抬到 macOS 12 | 用户选定。覆盖 Xcode 27 与 Xcode 26.x；6.1 在 trait 关闭时的行为没有验证，不加 |
| 2026-11-09 | `dismiss()` 对推入的内容和现有五种弹出的内容都生效 | 用户选定，与 UIKit 版一致 |
| 2026-11-09 | Examples 打开 trait，补两个栈案例 | 用户选定 |
| 2026-11-09 | AppKitPlus-Release 从 0.21.0 起 | 用户选定，只承诺测过的版本 |
| 2026-11-09 | 代码放在 AppKitNavigation 里用 `#if AppKitPlus` 包住；类型照 UIKit 版命名；路径支持集合和 `UINavigationPath`；推入动画跟随事务；选中绑定覆盖大纲与可重排表格两种数据源 | 提问时补上的默认做法，用户确认 |
| 2026-11-09 | Accepted | 用户批准。排在绑定和动画两份提案之后实现，做完在本地合进 `main`、不推送 |
| 2026-11-09 | trait 关闭时实测不解析 AppKitPlus；打开时要连默认 trait 一起写 | `swift build` 不带 trait 时，`Package.resolved` 里没有 AppKitPlus。`--traits AppKitPlus` 会关掉默认 trait，`Perception` 一关，`observe` 就要求 macOS 14，AppKitNavigation 编不过；使用方在 `Package.swift` 里要写 `traits: [.defaults, "AppKitPlus"]`，写进文档 |
| 2026-11-09 | `push`、`dismiss` 两个动作装进 `NSObject` 盒子再放进 trait | AppKitPlus 的 trait 存储只认对象：结构体值经 `as? any NSObjectProtocol` 变成 `nil`，写进去等于没写（探针实测） |
| 2026-11-09 | 栈控制器的 `delegate` 读到的是转发代理，不像 UIKit 版那样返回 App 的委托 | AppKitPlus 内部经 `delegate` 属性取委托，getter 若返回 App 的委托，路径代理就被绕过，用户返回时路径不会截短（探针实测）。App 设的委托排在代理后面，所有消息照转 |
| 2026-11-09 | 栈控制器重写 `init(nibName:bundle:)` 并标为不可用 | AppKitPlus 的 `init(navigationBarClass:toolbarClass:)` 内部经它初始化，Swift 子类不实现就会在运行时崩溃 |
| 2026-11-09 | 视图加载时第一次按路径摆放控制器不带动画 | 那时没有可以过渡的画面；测试里这次动画也收不了尾，后面的推入弹出都排在它后面 |
| 2026-11-09 | 按状态推入的内容，以「到过栈上、又离开了导航控制器、视图也离开了窗口」判定已经下屏 | 推入可能落在任意 `NSNavigationController` 里，不能占用它的委托；AppKitPlus 弹出时不发 `didMove(toParent: nil)`。在 run loop 每次等待前检查这三个条件；推入若因过渡进行中而排队，先等它落到栈上，结束时也先等它落到栈上再弹出 |
| 2026-11-09 | `dismiss` 装在内容的 trait 覆盖里：视图控制器装在自己身上，窗口和存取面板装在窗口上，alert 装在它的窗口上，popover 装在内容视图控制器上 | AppKitPlus 里窗口也是 trait 环境，装在窗口上，窗口里的所有视图都能读到 |
