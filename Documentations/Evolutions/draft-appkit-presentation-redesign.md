# Draft - AppKit 弹出 API 重做：生命周期收进一层，重载合并

- **状态**: In Progress
- **作者**: JH
- **创建日期**: 2026-11-06
- **最后更新**: 2026-11-06
- **所属愿景**: 无
- **关联提案**: [0001 - AppKitNavigation 清理](0001-appkit-navigation-cleanup.md)（把这次重构留给了单独的完整档提案）
- **实现分支 / PR**: `appkit-presentation-redesign`
- **配套文档**: 待定 —— 落地时登记实现说明 / 使用指南的链接

## 摘要

把 AppKitNavigation 的弹出 API（`modal`、`modalSession`、`sheet`、`popover`、`present`）重做成「一层通用代码管生命周期，各弹出方式只写怎么弹、怎么关」。新的通用层在内容显示期间强持有它；换 id 时先等旧内容下屏再弹新的；`onDismiss` 每次恰好调用一次，在内容下屏之后；宿主释放时收起内容；锚点还没显示时等它显示再弹。modal 可以叠在 modal 上，不再误停别人的模态循环、误关别人的 sheet。公开 API 同时收敛：参数标签统一为 `isPresented:`，删掉与 `present(style: .sheet)` 重复的 `NSViewController.sheet`，modal 和 sheet 的内容合并到公开协议 `ModalContent`，公开重载从 58 个降到 33 个。起因是审查这块代码读出 8 个问题，其中 5 个行为缺陷都出在同一个结构上：每种弹出方式各写一遍替换和收尾。

## 动机

### 读出的问题

都在 `main` 上，不是最近的改动引入的。起草时是读代码确认的；落地第 1 步的测试在 macOS 27.2 上复现了 1–5 和 8，第 8 条里对 alert 的猜测被测试否定（见该行）。本机依赖这个 fork 的 7 个项目都还没踩到（见「下游影响」）。

| # | 问题 | 怎么触发 | 原因 | 以前修过吗 |
|---|---|---|---|---|
| 1 | popover 被用户关掉时不调用 `onDismiss` | 点外部或按 Esc 关掉 popover：binding 复位了，回调不来 | `Navigated` 弱引用内容（`Sources/AppKitNavigation/Navigation/NavigationObserver.swift:85`）；`_PopoverPresentation` 只被关闭通知的订阅持有，通知一到就释放（`Internal/PopoverPresentationsObserver.swift:16-19`）；`observe` 在下一拍才重跑（`Sources/SwiftNavigation/NSObject+Observe.swift:135`），找不到内容就跳过 `end`（`NavigationObserver.swift:69-74`），而 `onDismiss` 只在 `end` 里调用。App 没有留着内容对象时，alert、每次新建的窗口和视图控制器同样会漏 | 2026-06 修过同一处「不回写 binding」，当时只管了回写 |
| 2 | 在 modal 里再弹 modal，外层被停掉 | modal 窗口里弹确认 alert：窗口消失、alert 单独出现，还调用了 alert 那个 binding 的 `onDismiss` | 开始时只要有模态窗口就 `stopModal()`（`Navigation/Modal.swift:276-279`），新循环又只在默认模式里启动（`Modal.swift:287`），嵌套本来就起不来；关闭时也不看是谁的就 `stopModal()`（`Modal.swift:300-302`） | 移植时就这样；2026-11-03 修 modal 时保留了 |
| 3 | popover 换了 id，旧的不关 | `popover(item:)` 换成另一项：新旧同时在屏上；`.applicationDefined` 时旧的再也关不掉，也不调用 `onDismiss` | 只有 popover 的开始闭包不处理替换（`Navigation/Popover.swift:247-253`），本该兜底的 `clearup()` 是死代码 | 加 popover 时就这样 |
| 4 | modal 结束后，窗口一直被全局表持有 | alert、被 binding 关掉的窗口都不发关闭通知，`ModalWindowsObserver.shared` 里的条目连同窗口永远留着，每弹一次漏一个 | 条目只在 `willClose` 时移除（`Internal/ModalWindowsObserver.swift:29-41`），而 alert 和被停掉的模态只是 `orderOut` | 没修过 |
| 5 | 替换时不分来源 | 新 sheet 会关掉窗口上别的 binding 或 App 自己弹的 sheet；`modalSession` 会关掉本库开的任何会话窗口；`present` 会关掉第一个被弹出的视图控制器；三处都调用本 binding 的 `onDismiss` | `Sheet.swift:262-264`、`Modal.swift:360-365`、`Presentation.swift:74-77` 都只看「现在有没有」，不看是谁弹的 | `present` 那处 2026-11-03 记进[裁决清单](../Internal/ReviewDecisions.md)暂缓，复查条件就是这次重构 |
| 6 | 带 `id:` 的绑定版重载少了 `@_disfavoredOverload` | 闭包写成 `{ _ in … }` 时两个重载都能用，编译报歧义 | `Modal.swift:52、105、158、211`，`Sheet.swift:49、99、149、199`，`Popover.swift:116、384`；UIKit 版（`Sources/UIKitNavigation/Navigation/Presentation.swift:123`）和本库的 `present` 都标了 | 没修过 |
| 7 | 视图控制器的 sheet 有两套实现 | `sheet(isSheeted:)` 不等视图出现就弹，`present(style: .sheet)` 会等；同一件事两套代码 | `Sheet.swift:160-208` 与 `Presentation.swift` 各走一条路 | 2026-11-03 修「用户关闭不回写」时两边各修了一遍 |
| 8 | 存取面板作为 sheet 时没走它自己的 API | `window.sheet { NSSavePanel() }` 用 `NSWindow.beginSheet(_:)` 附上面板，没调用 `beginSheetModal(for:)`：点「取消」关不掉 sheet，binding 也不复位。alert 同样没走 `beginSheetModal(for:)`，但测试表明它的文字照常排版、按钮照常结束 sheet，不受影响 | 默认实现把父窗口当接收者（`Navigation/SheetContent.swift:18-21`），`NSAlert`、`NSSavePanel` 自己的实现（`SheetContent.swift:33-55`）永远走不到 | 没修过；起草本提案时发现 |

### 结构上的问题

- **重复**：四个文件共 1,485 行。公开重载 58 个：`modal` 15 个、`modalSession` 5 个、`NSWindow.sheet` 15 个、`NSViewController.sheet` 5 个、`popover` 10 个、`present` 5 个、`destination` 3 个。每个公开重载先转给同形的 `fileprivate` 重载，再转给私有核心，一共三层。
- **生命周期分散**：替换、收尾、`onDismiss` 由各弹出方式的开始和结束闭包各写一遍，通用的 `NavigationObserver` 只负责比对 binding。缺陷 1–5 都出在这里。
- **死代码**：`Navigated` 的四个 `clearup()`（裁决清单里的暂缓项：泛型类的 `deinit` 只会调用类里那份空实现）、`onBeginNavigation`、`PresentationContent` 协议及其两个方法。
- **机制杂**：每次弹出的状态挂在内容对象的关联对象上，按类型分 key（`AssociatedKeys`）；有两个全局单例（`ModalWindowsObserver`、`PopoverPresentationsObserver`）；调度方式有五种（run loop 块、`DispatchQueue.main.async`、`Task`、continuation、Combine 订阅），先后顺序全靠隐含约定，2026-11-03 那次「binding 停不掉 modal」就是其中两种的顺序问题。
- **API 不一致**：标签 `isModaled`、`isSheeted` 与 `popover`、`present` 的 `isPresented` 不一致；公开 API 都没有文档注释。

### 为什么现在做

- 0001 清理时把「弹出三个文件的重载收敛连同 `clearup()` 死代码」留给了单独的完整档提案；裁决清单里两条暂缓项的复查条件也是这次重构。
- 下游只有 5 处调用，而且都不受这次的破坏性改动影响，这是改公开 API 代价最低的时候。

## 前期调研

- **现状代码怎么走的**：
  - 公开重载 → `fileprivate` 同形重载 → 私有核心 → `xxxObserver()` 取出挂在宿主上的 `NavigationObserver<Owner, Content>`（每种内容类型一个）→ `NavigationObserver.observe(item:id:content:begin:end:)`（`NavigationObserver.swift:17-76`）。
  - 用户自己关掉内容时，靠挂在内容对象上的 `onEndNavigation` 闭包写回 binding；各方式报告「结束」的途径各不相同：modal 是 `runModal` 返回，modalSession 是窗口的 `willClose`，sheet 是 `beginSheet` 的 async 返回，popover 是 `didCloseNotification`，`present` 是 shim 在 `viewDidDisappear` 里报告的 dismiss。
  - `observe` 的重跑走 `DispatchQueue.main.async`（`NSObject+Observe.swift:134-136`），所以用户关闭后，binding 的写回要到下一拍才被看到。
- **上游是否已有**：没有。`upstream/main`（2026-08-31）的 `Sources/AppKitNavigation` 下没有 `Navigation` 目录，这些弹出 API 都是 fork 独有的，改名不影响合并上游。
- **前人怎么做的**：
  - UIKit 版（`Sources/UIKitNavigation/Navigation/Presentation.swift`）：用一个 presenter 标记区分「是不是自己弹的」再决定是否替换，`onDismiss` 在 `dismiss(animated:)` 的完成回调里调用（下屏之后）；用户关闭时用 `inFlightController` 临时强引用被关的控制器，保证下一拍还能收尾；宿主释放时 `Presented.deinit` 收起内容；`UIBinding` 版重载都标了 `@_disfavoredOverload`。
  - SwiftUI 的 `sheet(isPresented:onDismiss:content:)`、`popover(isPresented:)` 用名词作基名、`isPresented:` 作标签，内容是泛型 `Content: View`。
- **AppKit 的事实**（macOS 27.2 SDK）：
  - 窗口已有 sheet 时，`beginSheet` 会排队，等前一个结束才显示；critical sheet 跳过排队（`NSWindow.h:581-582`）。
  - `NSView.window` 声明为 `unsafe_unretained`，没有标注支持 KVO；进出窗口只能靠覆写点 `viewWillMoveToWindow:` / `viewDidMoveToWindow`（`NSView.h:86、107-108`）。
  - 窗口显示与否可以从 `occlusionState` 和 `NSWindowDidChangeOcclusionStateNotification` 得知（`NSWindow.h:638、985`）。
  - `NSAlert`、`NSSavePanel` 有自己的 `beginSheetModal(for:completionHandler:)` 和 `runModal()`；`NSApplication.runModal(for:)` 可以嵌套。
- **下游用法**（在本机依赖这个 fork 的 7 个项目里搜过）：XCOrganizer 的 `MainWindowController.swift:94、103` 用 `NSWindow.sheet(item:)`，内容是窗口；SymbolViewer 的 `MainSplitViewController.swift:50、62` 和 ApplicationScaffold 模板的 `MainViewController.swift:46` 用 `present(isPresented:style: .sheet)`。`modal`、`modalSession`、`popover`、`NSViewController.sheet`、`isModaled`、`isSheeted`、`onDismiss` 都没有人用。
- **现有测试**：`ModalPresentationTests` 3 条、`ViewControllerPresentationTests` 5 条；popover、alert 和存取面板、`onDismiss`、换 id 都没有测试。
- **验证过什么**：目前只读了代码和 git 历史，还没在运行时复现。曾怀疑 popover 的锚点视图不在窗口里时 AppKit 会抛异常，但在 macOS 27.2 的 AppKit 里没搜到对应的断言文字，没有坐实，不作为动机。

## 提议方案

**一层通用代码管生命周期**，每次调用 `modal`、`sheet`、`popover`、`present` 各建一个，由宿主持有：

- 内容在显示期间被强持有，直到它下屏，不再依赖「App 有没有留着它」。
- binding 有值时，先等锚点能显示内容，再建内容、弹出；还没显示就被复位的，直接取消，不调用 `onDismiss`。
- 换 id 时，先请旧内容下屏，等它真正下屏、调用过 `onDismiss`，再弹新的。
- `onDismiss` 每次弹出恰好调用一次，在内容下屏之后，不论是用户关的、binding 关的、换 id 替换的，还是宿主释放收起的。用户关的，先把 binding 写回 `nil`，再调用 `onDismiss`。
- 宿主释放时，收起正在显示的内容。取消返回的 token 只是不再跟随 binding：内容留到用户关闭，那时仍写回 binding、调用 `onDismiss`。
- 只动自己弹出的内容：窗口上已经有别人的 sheet 时，交给 AppKit 排队；要关的 modal 上面还叠着别的模态时，等上面那些先结束。

**各弹出方式只写「怎么弹、怎么关」**：

- `modal` 的模态循环可以在外层模态循环里启动，叠在上面；结束时只停自己的循环。
- `sheet` 让内容用它自己的 API 弹出：窗口用 `beginSheet`，alert 和存取面板用 `beginSheetModal(for:)`。
- popover 用每次弹出各自的通知观察代替全局单例；`animates` 同时参考参数和 transaction 的 `appKit.disablesAnimations`。窗口 sheet、模态窗口和视图控制器的弹出，AppKit 没有关动画的公开办法，照常带动画。
- `present` 保持现有的「等 `viewDidAppear`」；窗口等它显示出来；视图等它进窗口、窗口显示出来；工具栏项等它所在的窗口显示出来。

**公开 API 收敛**：

- 参数标签统一为 `isPresented:`：`modal(isPresented:)`、`modalSession(isPresented:)`、`NSWindow.sheet(isPresented:)`。
- 删掉 `NSViewController.sheet`，视图控制器的 sheet 一律用 `present(…, style: .sheet)`。
- modal 和 `NSWindow.sheet` 的内容改为泛型 `Content: ModalContent`。`ModalContent` 是公开协议，`NSWindow`（以及所有面板）和 `NSAlert` 遵循；协议要求带下划线、不出现在文档里，不作为给 App 扩展用的入口。取这个名字，是因为 AppKit 把 sheet 也算作一种模态（document-modal）。
- `UIBinding` 版重载都标 `@_disfavoredOverload`；泛型参数写完整的 `Identifier`（调用方看不到，不影响源码兼容）。
- 公开 API 全部补上文档注释。
- 不保留旧名：保留旧名会让重载翻倍，而下游没有调用点会受影响。

### 非目标

- 不新增弹出方式，例如 `NSPrintPanel` 或 `NSPageLayout`。
- 不把 `ModalContent` 或内部的弹出方式开放成扩展点；视图控制器的自定义转场继续用 `destination`。
- 不改 `NSViewController.TransitionStyle` 的成员，不改 `destination` 的签名。
- 不碰与上游共用的 `SwiftNavigation`、UIKit、SwiftUI 部分。
- 不发版；发版另外决定。
- `present(style: .popover)` 在 transient popover 被点外部关闭时的回写，单元测试里仍然没法模拟，裁决清单里那条「未在运行时验证」照旧保留。

## 详细设计

### 公开 API

```swift
/// Content that AppKit shows in a window of its own — a window, an alert, or a save or open
/// panel — either attached to another window as a sheet, or run as an application-modal window.
///
/// `NSWindow`, and through it every panel, conforms, as does `NSAlert`. The requirements are
/// implementation details of AppKitNavigation; conforming other types is not supported.
@MainActor
public protocol ModalContent: AnyObject {
  @_documentation(visibility: private)
  var _appKitNavigationWindow: NSWindow { get }

  @_documentation(visibility: private)
  func _appKitNavigationBeginSheet(
    attachedTo parentWindow: NSWindow,
    completionHandler: @escaping @MainActor () -> Void
  )

  @_documentation(visibility: private)
  func _appKitNavigationRunModal()
}

// Save and open panels take their own `beginSheetModal(for:)` and `runModal()`, chosen inside the
// window's implementation.
extension NSWindow: ModalContent { /* … */ }
extension NSAlert: ModalContent { /* … */ }

@MainActor
extension NSObject {
  @discardableResult
  public func modal<Content: ModalContent>(
    isPresented: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> Content
  ) -> ObserveToken

  @discardableResult
  public func modal<Item: Identifiable, Content: ModalContent>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> Content
  ) -> ObserveToken

  @_disfavoredOverload
  @discardableResult
  public func modal<Item: Identifiable, Content: ModalContent>(
    item: UIBinding<Item?>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> Content
  ) -> ObserveToken

  @discardableResult
  public func modal<Item, Identifier: Hashable, Content: ModalContent>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, Identifier>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (Item) -> Content
  ) -> ObserveToken

  @_disfavoredOverload
  @discardableResult
  public func modal<Item, Identifier: Hashable, Content: ModalContent>(
    item: UIBinding<Item?>,
    id: KeyPath<Item, Identifier>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping (UIBinding<Item>) -> Content
  ) -> ObserveToken

  // `modalSession` has the same five shapes. Its content stays a plain `NSWindow`: a modal session
  // needs a window that the app runs itself, which an alert or a panel is not.
  @discardableResult
  public func modalSession(
    isPresented: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> NSWindow
  ) -> ObserveToken
}

extension NSWindow {
  // The same five shapes as `modal`, generic over `Content: ModalContent`.
  @discardableResult
  public func sheet<Content: ModalContent>(
    isPresented: UIBinding<Bool>,
    onDismiss: (() -> Void)? = nil,
    content: @escaping () -> Content
  ) -> ObserveToken
}
```

`NSView.popover`、`NSToolbarItem.popover`、`NSViewController.present` 和 `destination` 的签名不变，只给 `UIBinding` 版补 `@_disfavoredOverload`、把泛型参数 `ID` 写成 `Identifier`。

改完后的调用点：

```swift
window.sheet(isPresented: $model.isConfirmingDelete) { makeDeleteAlert() }
window.sheet(item: $model.tagEditor) { editor in TagEditor.makeWindow(viewModel: editor) }
modal(item: $model.failure) { failure in NSAlert(error: failure) }
present(isPresented: $model.isSettingsPresented, style: .sheet) { SettingsViewController() }
view.popover(isPresented: $model.isInfoShown, preferredEdge: .maxY) { InfoViewController() }
```

### 生命周期（内部）

```swift
/// One way of showing content: as a sheet, a modal loop or session, a popover, or a presented
/// view controller.
@MainActor
protocol PresentationStyle {
  associatedtype Content: AnyObject

  /// Calls `body` once the anchor can show content: right away when it already can, otherwise
  /// once it gets on screen. Returns a closure that cancels a wait that is no longer wanted.
  func whenReady(_ body: @escaping @MainActor () -> Void) -> @MainActor () -> Void

  /// Shows `content` and calls `didEnd` exactly once, after the content has left the screen,
  /// whatever ended it.
  func begin(
    _ content: Content,
    transaction: UITransaction,
    didEnd: @escaping @MainActor () -> Void
  )

  /// Asks `content` to leave the screen, which leads to the `didEnd` passed to `begin`. Works
  /// from the content's side, so that it still works while the owner is being deallocated.
  func end(_ content: Content, transaction: UITransaction)
}

/// Shows content while a binding holds a value: one per call of `modal`, `sheet`, `popover` or
/// `present`, kept alive by the object it was called on.
@MainActor
final class BindingPresenter<Style: PresentationStyle> {
  init(style: Style, onDismiss: (() -> Void)?)

  func observe<Item>(
    item: UIBinding<Item?>,
    id: @escaping (Item) -> AnyHashable?,
    content: @escaping (UIBinding<Item>) -> Style.Content
  ) -> ObserveToken
}
```

`BindingPresenter` 的状态转换：

| 状态 | binding 有值 | binding 变成 `nil` | `didEnd` 到来 | 宿主释放 |
|---|---|---|---|---|
| 空闲 | 等锚点就绪，就绪后建内容、`begin`，进入「显示中」 | — | — | — |
| 等就绪 | 记下最新的值，就绪时用它 | 取消等待，回到空闲；没显示过，不调用 `onDismiss` | — | 取消等待 |
| 显示中 | id 相同不动；id 不同就 `end` 旧内容，记下新值，进入「结束中」 | `end`，进入「结束中」 | 用户关的：id 仍相符就写回 `nil`，调用 `onDismiss`，回到空闲 | `end`，进入「结束中」 |
| 结束中 | 更新记下的新值 | 清掉记下的新值 | 调用 `onDismiss`；有记下的新值就去「等就绪」，否则回到空闲 | 不再接受新值 |

`didEnd` 同步地把状态改回空闲，所以「用户关闭写回 `nil` 后，同一拍里 binding 又被设回有值」不再需要现在的 `hasEnded` 标记：下一次重跑看到的就是空闲加有值，照常弹出。

### 各弹出方式

| 方式 | 锚点就绪 | 开始 | `didEnd` 的来源 | `end` |
|---|---|---|---|---|
| `modal` | 立即 | 在默认和模态面板两种 run loop 模式里排一个块，块里调用 `_appKitNavigationRunModal()`；窗口被关闭且它是最上层模态时 `stopModal()` | 模态循环返回、窗口已下屏 | 是最上层模态就 `stopModal()`；否则挂一个 run loop 观察者，在每次等待前检查，轮到自己时再停 |
| `modalSession` | 立即 | `beginModalSession(for:)` | 窗口关闭、会话结束 | 是最上层就关窗口；否则同上，等轮到自己 |
| `NSWindow.sheet` | 父窗口显示出来 | `_appKitNavigationBeginSheet(attachedTo:completionHandler:)`；父窗口已有别的 sheet 时由 AppKit 排队 | AppKit 的 completion handler | `sheetParent?.endSheet(_:)`；还在排队的 sheet 怎么撤，实现时先测 |
| `NSView.popover` | 视图进了窗口，且窗口显示出来 | 新建 `NSPopover` 并显示 | `NSPopover.didCloseNotification` | `close()` |
| `NSToolbarItem.popover` | 工具栏所在的窗口显示出来 | 同上，用 `show(relativeTo:)` | 同上 | 同上 |
| `present` / `destination` | `viewDidAppear`（shim 现有的机制） | `present(_:for:)`，或调用方传入的 `present` 闭包 | shim 在 `viewDidDisappear` 里报告的 dismiss | 仍在 `presentedViewControllers` 里才 `dismiss(_:)` |

- **怎么等**：所有「等」——等窗口显示、等视图进窗口、等工具栏显示、等 sheet 离开屏幕——都用一个挂在主 run loop 上的观察者，在每次等待之前检查条件（`Internal/RunLoopWait.swift`），只在有东西在等时挂着。测试表明通知靠不住：测试进程不是活跃的 App，窗口显示出来时遮挡状态、key、main 三种通知一个都没发；视图进窗口本来就没有通知；sheet 的 completion handler 在 sheet 开始收起、还在屏幕上时就调用了。
- **等窗口显示**：等 `isVisible` 为真。
- **等视图进窗口**：等视图有窗口、且窗口显示出来。不用交换 `viewDidMoveToWindow`。
- **工具栏项**：从 `NSApp.windows` 里找 `toolbar === item.toolbar` 的窗口，等它显示。实现时先测 AppKit 在工具栏还没显示时 `show(relativeTo:)` 怎么表现，AppKit 自己能处理就不加这层等待。
- **「下屏之后」**：sheet 在 completion handler 之后再等 sheet 窗口不可见；modal session 在窗口 `willClose` 之后同样再等；模态循环返回后由本库把窗口 `orderOut`，随即算作下屏。
- **嵌套 modal 的顺序**：测试表明，模态循环被请求停止后、真正返回之前，若有新的模态循环在它上面启动，AppKit 会丢掉那次停止请求，旧循环再也不返回。所以本库请某个循环停下后，新的模态循环先排队，等它返回再启动；窗口关闭按钮触发的停止也走同一条路。

### 存放与清理

- 每个 `BindingPresenter` 存进宿主上的一个数组（一个关联对象）。宿主释放时数组随之释放，`BindingPresenter` 在 `deinit` 里收起正在显示的内容。
- 每次弹出用到的通知观察（窗口关闭、popover 关闭）用现有的 `NotificationObserver`，挂在那次弹出上，`didEnd` 时注销。不再有全局表，也就没有缺陷 4 那种泄漏。
- 删除：`NavigationObserver.swift`、`NavigationContent.swift`、`SheetContent.swift`、`PopoverContent.swift`、`PresentationContent.swift`、`Internal/ModalWindowsObserver.swift`、`Internal/PopoverPresentationsObserver.swift`、`Internal/AssociatedKeys.swift`（这三个都只被弹出代码使用），以及 `NSWindow` 上的 `@objc` 方法 `__appKitNavigationRunModal`。
- 存取面板走自己的 API，由 `NSWindow` 实现里的 `self as? NSSavePanel` 判断。这是实现内部对一个子类的特判，不是对外的能力判断，也免得在 `NSWindow` 上多加 Objective-C 方法。

### 测试

- 现有行为先补测试，改动前就要通过：每种方式 binding 打开、binding 关闭、用户关闭写回。
- 8 条问题各一条测试。行为缺陷先用严格模式的 `XCTExpectFailure` 标成预期失败，确认它现在确实失败；修好的那一步去掉标记。第 6 条是编译期问题：只需编译的测试文件在修复那一步加入，加入前先在本地确认它编不过。
- 新行为各一条测试：嵌套 modal、等锚点显示、`onDismiss` 恰好一次且在下屏后、换 id 的先后顺序、宿主释放收起、取消 token 后用户关闭仍写回。
- 把下游的调用写法搬进一个只需编译的测试：XCOrganizer 那种多语句、两处 `return` 的闭包，`{ _ in … }`，以及 `{ $item in … }`。
- 照现有测试的写法，用同步的 XCTest 方法、靠转动主 run loop 等待。机器闲置时动画可能不跑，测试卡住时先用 `caffeinate -u` 排除。

## 替代方案考量

- **在现有结构上逐条修**：改动小，但 5 个行为缺陷都出在同一个结构上，逐条修完重构时又得重写一遍。用户选择直接重构。
- **改名但保留旧名过渡**：API 设计规范的默认做法是改名时保留旧名并标 `renamed:`。没有采用：这些 API 是 fork 独有的，下游没有调用点受影响，保留旧名会让重载数量不降反升。
- **公开 API 一点不动**：标签不一致、重复的 sheet、每种内容各一套重载都会留下来，被否。
- **嵌套 modal 排队，或拒绝并报警告**：都偏离 AppKit 原生 `runModal` 的嵌套行为，被否。
- **锚点没显示时不等、只报警告，或保持现状**：「一启动就弹」的场景得由调用方自己推迟，而 `present` 已经在等，被否。
- **`onDismiss` 在开始关闭时调用，或换 id 替换时不调用**：前者在回调里马上再弹东西，可能和还在退场的内容撞上；后者与 UIKit 版不一致。都被否。
- **每种内容保留一套重载**：公开重载数量不变，被否。**把 `ModalContent` 开放成扩展点**：App 可以让自己的类型也能弹出，但多一个要长期维护的契约，眼下没有需求，被否。
- **取消 token 时也收起内容，或宿主释放时也不收起**：前者让取消变成破坏性操作，后者留着 `clearup()` 原本要解决的问题。都被否。
- **继续弱引用内容，像 UIKit 版那样在用户关闭时临时强引用**：AppKit 这边的 popover 包装和 alert 没有别人持有，弱引用正是缺陷 1 的根源，直接在显示期间强持有更简单。
- **用 KVO 观察 `NSView.window`**：头文件没有标注它支持 KVO，将来可能悄悄失效。
- **交换 `viewDidMoveToWindow`、监听窗口的遮挡与 key、main 通知**：起草时的方案。前者要替换每个视图的一个系统方法；后者在测试进程里一个都不发（见「怎么等」）。实现时改用 run loop 观察者检查条件，两者都不需要了。
- **保留全局单例、只修泄漏**：每次弹出各自观察以后，全局状态就没有存在的理由了。
- **存取面板沿用 `@objc` 方法加子类覆写**：现在的 `__appKitNavigationRunModal` 就是这么做的，但这要在 `NSWindow` 上加 Objective-C 方法；改成实现内部的类型判断更简单。

## 影响

### 源码兼容性（source compatibility）

**有破坏。** 需要修改的调用写法：

| 改前 | 改后 |
|---|---|
| `modal(isModaled: $flag) { window }` | `modal(isPresented: $flag) { window }` |
| `modalSession(isModaled: $flag) { window }` | `modalSession(isPresented: $flag) { window }` |
| `window.sheet(isSheeted: $flag) { alert }` | `window.sheet(isPresented: $flag) { alert }` |
| `viewController.sheet(isSheeted: $flag) { child }` | `viewController.present(isPresented: $flag, style: .sheet) { child }` |
| `viewController.sheet(item: $item) { item in child(item) }` | `viewController.present(item: $item, style: .sheet) { item in child(item) }` |

- `modal(item:)`、`NSWindow.sheet(item:)` 的写法不变；内容闭包的返回类型从三种具体类型变成泛型，返回 `NSWindow`、`NSAlert`、`NSSavePanel` 及其子类的调用点照常编译。不同分支返回不同类型的闭包，改前也编不过。
- 新增公开协议 `ModalContent`，以及 `NSWindow`、`NSAlert` 对它的遵循。
- 行为变化（不影响编译）：
  - `onDismiss` 总会调用一次，在下屏之后；之前有时漏调，binding 关闭时则在开始关闭时就调用。
  - 嵌套 modal 不再停掉外层。
  - 新的 sheet 不再关掉别人的 sheet，改由 AppKit 排队。
  - sheet 和 popover 等锚点显示后才弹出。
  - 宿主释放时收起内容。
  - alert 和存取面板作为 sheet 时走它们自己的 API。
  - popover 遵守 transaction 的关动画设置。
- 不提供 `@available(*, deprecated, renamed:)` 的过渡版本，理由见「API 演进与废弃策略」。

### ABI 兼容性（条件项）

不适用 —— 本库以 SPM 源码分发，使用方每次重新编译。

### 下游影响

- 本仓库：`AppKitNavigation`、`AppKitNavigationTests`。Examples 里 Wi-Fi 案例的两处 `modal(isModaled:)` 随这次改成 `modal(isPresented:)`；它的 `modalSession(item:)` 和其余案例的 `present(...)` 写法不变。（起草时只搜了带点号的调用，漏掉了这两处省略 `self` 的写法，第 3 步发现后更正。）
- 下游仓库：XCOrganizer 的 2 处 `NSWindow.sheet(item:)`、SymbolViewer 的 2 处和 ApplicationScaffold 模板的 1 处 `present(isPresented:style: .sheet)`，写法都不用改。其余 4 个依赖这个 fork 的项目没有用到弹出 API。这些项目在下次重新解析依赖、拿到新版本时，只会碰到上面那些行为变化：XCOrganizer 的 sheet 的 item 初始为 `nil`，等锚点那一条对它没有影响；它们都没有用 `onDismiss`。

### 文档与示例

- 公开 API 全部补上文档注释，包括 `ModalContent`。
- DocC 首页（`Sources/AppKitNavigation/Documentation.docc/AppKitNavigation.md`）的「Presenting content from state」一组：加上 `ModalContent`，去掉只剩下划线成员的 `AppKit/NSAlert`。
- `swift-navigation-bindings` skill 里 AppKit 那张表：标签、泛型内容、删掉的 `NSViewController.sheet`；顺带更正 `modalSession` 的内容只能是 `NSWindow`（现在那张表写成了和 `modal` 一样）。
- [裁决清单](../Internal/ReviewDecisions.md)：两条暂缓项（`clearup()` 死代码、`present` 替换时不分来源）随这次修掉，从清单里删除；「transient popover 被点外部关闭时的回写」保留。
- README 没有提到 AppKit 的弹出 API，不用改。

## API 演进与废弃策略

- 被替代的旧 API 直接删除，不标 `deprecated`、不设废弃期。理由：这些 API 是 fork 独有的，上游没有；本机依赖这个 fork 的项目没有调用点受影响；保留旧名会让重载数量翻倍，和这次收敛重载的目标相反。这偏离了 API 设计规范「改名时保留旧名并标 `renamed:`」的默认做法，偏离的理由就是上面这几条。
- 不跃迁 semver major：fork 的版本号跟随上游的 2.11，自己的改动用 100 以上的补丁号（最近一次是 2.11.101）。下一个版本号在发版时再定。

## 落地步骤

1. **补测试作安全网**（已完成）：按「测试」一节补现有行为的测试（改动前就通过）和问题的测试（先标预期失败）。共享的等待、建窗口、记录 popover 的辅助放进 `PresentationTestSupport.swift`，两份原有测试改用它。新增 `SheetPresentationTests`、`PopoverPresentationTests`，`ModalPresentationTests`、`ViewControllerPresentationTests` 各有补充；AppKit 测试共 39 条 XCTest、58 条 Swift Testing，全部通过。
2. **通用层与 modal**（已完成）：加入 `PresentationStyle`、`BindingPresenter`、`ModalContent`，把 `modal` 和 `modalSession` 迁过去、改标签、补文档注释；删除 `ModalWindowsObserver`。通用层的契约（恰好一次的 `onDismiss`、换 id 的顺序、宿主释放、取消 token）先拿 modal 测。修掉缺陷 2、4，以及 1、5 里属于 modal 的部分。`ModalPresentationTests` 共 17 条，连跑 5 次全部通过。
3. **sheet**（已完成）：`NSWindow.sheet` 改成泛型并迁过去、补文档注释，加上等父窗口显示；删除 `NSViewController.sheet` 和 `SheetContent.swift`；Examples 跟着改标签。修掉缺陷 7、8，以及 5 里属于 sheet 的部分。`SheetPresentationTests` 共 12 条，AppKit 测试共 50 条 XCTest、58 条 Swift Testing，全部通过。
4. **popover**（已完成）：`NSView` 和 `NSToolbarItem` 的 popover 迁过去、补文档注释，加上等锚点显示（用 `RunLoopWait`）和 transaction 的关动画；删除 `PopoverContent.swift` 与 `PopoverPresentationsObserver`。修掉缺陷 1、3。`PopoverPresentationTests` 共 12 条（含工具栏项的两条），AppKit 测试共 56 条 XCTest、58 条 Swift Testing，全部通过。
5. **present 与 destination**（已完成）：迁过去、补文档注释，替换时只动自己弹的；`TransitionStyle` 移进 `Presentation.swift`，删除 `PresentationContent.swift`。修掉缺陷 5 剩下的部分（裁决清单里的那条暂缓项）。`ViewControllerPresentationTests` 共 11 条，新增的覆盖了 `.modalWindow` 风格和 `destination` 的自定义闭包；AppKit 测试共 61 条 XCTest、58 条 Swift Testing，全部通过。
6. **清理**（已完成）：删除旧的 `NavigationObserver`、`NavigationContent`、各 `*Content.swift` 和 `AssociatedKeys`；`UIBinding` 版重载在第 2–5 步重写时都已标 `@_disfavoredOverload`（`destination` 的两个没有同形的 item 版，不需要）。加入 `PresentationOverloadTests`：第 6 条的歧义写法、`{ $item in … }` 写法和 XCOrganizer 那种多语句闭包。先去掉一处标记确认它编不过（报 `ambiguous use of 'modal(item:id:onDismiss:content:)'`），恢复后通过。AppKit 测试共 64 条 XCTest、58 条 Swift Testing，全部通过。
7. **文档**：按「文档与示例」一节更新文档注释、DocC 首页、`swift-navigation-bindings` skill 和裁决清单。
8. **完整验证**：Xcode 27.2 跑 AppKit 的全部测试，成败只认原始退出码，弹出相关的测试连跑 10 次；Xcode 26.6 编译库和测试；用 xcodebuild 编译 Examples 里 macOS 版的 CaseStudies。

每一步都能单独构建通过、测试全绿：第 2–5 步迁移期间，还没迁的方式继续走旧的 `NavigationObserver`，第 6 步才删除。

**收尾时必须判断两件事**（判断结果写进决策日志，不允许沉默跳过）：

- **要不要配套专题文章** —— 有「从 API 签名看不出来的调用方契约」就写使用指南；有「下次维护会踩、代码本身看不出来的决策」就写实现说明。写了就登记到头部的「配套文档」。候选的实现说明内容：模态循环为什么要在两种 run loop 模式里启动、为什么要等上层模态先结束、内容为什么要强持有。
- **有没有引入新术语** —— 有就同批次登记进术语表（项目级 `Documentations/Glossary.md`，跨项目通用的登记到全局术语表）。

## 后续项

- AppKit 测试的共享辅助（`PresentationTestSupport.swift` 里的等待、建窗口、记录 popover）将来可以移进一个独立的 `TestingSupport` 测试库；这要改四份 `Package*.swift`，不在这一批。

## 决策日志

| 日期 | 变更 | 说明 |
|------|------|------|
| 2026-11-06 | Created as Draft | 审查弹出代码读出 8 个问题和大量重复重载；0001 把这块重构留给了单独的完整档提案 |
| 2026-11-06 | 重构而不是逐条修 | 5 个行为缺陷出在同一个结构上，逐条修完重构时又得重写 |
| 2026-11-06 | 公开 API 直接改，不保留旧名 | fork 独有，下游没有调用点受影响；保留旧名会让重载翻倍。偏离 API 设计规范的默认做法，理由记在「API 演进与废弃策略」 |
| 2026-11-06 | modal 可以叠在 modal 上 | 与 AppKit 原生 `runModal` 的嵌套一致；排队、拒绝两种做法被否 |
| 2026-11-06 | 锚点没显示时等它显示再弹 | 与 `present` 的现有行为和 UIKit 版一致；「不等、报警告」「保持现状」被否 |
| 2026-11-06 | `onDismiss` 在下屏后恰好调用一次，换 id 替换也算 | 与 UIKit 版一致；「开始关闭时调用」「替换时不调用」被否 |
| 2026-11-06 | modal 与 sheet 的内容合并到公开协议 `ModalContent`，要求带下划线 | 每个动词从 15 个重载降到 5 个；开放成扩展点、保留每种一套被否 |
| 2026-11-06 | 宿主释放时收起内容，取消 token 不收起 | 补上 `clearup()` 原本要做的事，与 UIKit 版一致；「两种都收起」「都不收起」被否 |
| 2026-11-06 | 其余默认做法经用户确认 | 强持有内容、换 id 的顺序、不碰别人的内容、等上层模态结束、取消后仍写回、popover 遵守关动画、补 `@_disfavoredOverload`、测试先行、文档同步、发版另定 |
| 2026-11-06 | 起草时查出第 8 条问题 | alert 和存取面板作为 sheet 时没走自己的 `beginSheetModal(for:)`；方案里 `ModalContent` 的 sheet 要求本来就按类型各走各的 API，不改变方向 |
| 2026-11-06 | Accepted | 用户批准，开始实现 |
| 2026-11-06 | 第 1 步：缺陷 1–5 与 8 在 macOS 27.2 上复现 | 每条都由一条先失败的测试证实，现在用严格模式的 `XCTExpectFailure` 标着。第 8 条原以为 alert 也受影响，测试表明 alert 的文字和按钮都正常，只有存取面板点「取消」关不掉 sheet；alert 那半记进裁决清单的误报一节 |
| 2026-11-06 | 第 7 条不写先变红的测试 | 它的修法是删掉重复的 `NSViewController.sheet`；留下的 `present(style: .sheet)` 本来就等视图出现，那条测试从一开始就是绿的。没有对要删的 API 写红测试，也免得冒险：视图不在窗口里时调用 `presentAsSheet` 会怎样，还不清楚 |
| 2026-11-06 | 共享的测试辅助放在测试 target 里的一个文件，不另建 `TestingSupport` 库 | 另建库要改四份 `Package*.swift`，超出本提案范围；记为后续项 |
| 2026-11-06 | 第 2 步：新的模态循环等本库刚停下的循环返回后再启动 | 测试「同一拍里结束一个 modal、弹出另一个」时发现：新循环在旧循环返回前启动，AppKit 会丢掉旧循环的停止请求，旧窗口一直挂着。提案原以为停止标记只属于外层，被测试否定 |
| 2026-11-06 | 模态循环由 style 自己从 run loop 块里启动，`begin` 不等它结束就返回 | 循环若在 `BindingPresenter` 的方法里阻塞，presenter 会一直留在调用栈上、不会释放，宿主释放时就收不起内容 |
| 2026-11-06 | 通用层不再把 `begin` 包在 `withUITransaction` 里 | 模态循环会在 `begin` 里一直跑，事务会漏给循环里处理的所有事件；需要事务的 style 自己取用 |
| 2026-11-06 | 宿主释放、内容被收起后，binding 若还指着那一项就写回 `nil` | 让 binding 与屏幕一致；方案原来只写了「收起并调用 `onDismiss`」 |
| 2026-11-06 | `BindingPresenter` 继承 `NSObject` | 沿用 `NSObject.observe` 在主队列上重跑、把 token 存在对象上的做法，与原来的 `NavigationObserver` 一致 |
| 2026-11-06 | 第 3 步：「等」一律改用 run loop 观察者检查条件，不交换 `viewDidMoveToWindow`、不靠窗口通知 | 测试里父窗口显示出来后，遮挡、key、main 三种通知一个都没来，sheet 一直等不到；检查条件只在有东西等时才挂着，成本可以忽略，还省掉了对每个视图生效的方法交换 |
| 2026-11-06 | sheet 与 modal session 在 AppKit 的结束回调之后，再等窗口离开屏幕才算结束 | 测试表明 sheet 的 completion handler 在 sheet 还在屏幕上时就调用了，`onDismiss` 会比「下屏之后」早；session 的 `willClose` 同理 |
| 2026-11-06 | 撤掉还在排队的 sheet 时，对父窗口调用 `endSheet(_:)` | 排队中的 sheet 还没有 `sheetParent`；测试表明这样能把它从队列里撤掉，它之后不会再出现 |
| 2026-11-06 | 更正下游影响：Examples 的 Wi-Fi 案例用了两处 `modal(isModaled:)` | 起草时只搜了带点号的调用；本分支一并改成 `modal(isPresented:)`。本机下游项目用更宽的写法重搜过，仍然没有用到改名的 API |
| 2026-11-06 | 第 4 步：工具栏项照样等它所在的窗口显示，没有先去试 AppKit 自己怎么处理 | 与其他锚点的等待一致，代价只是一次检查；测试覆盖了「窗口还没显示就设成 `true`」 |
| 2026-11-06 | popover 被要求关闭时若已不在屏幕上，直接算作结束 | 从没显示出来、或正在被用户关掉的 popover 不会再发关闭通知，不这样做 presenter 会一直停在「结束中」 |
| 2026-11-06 | 第 5 步：视图控制器在 shim 报告 dismiss 后，再等它的窗口不可见才算结束 | 测试表明报告到来时 sheet 窗口已经不可见，但父窗口的 `attachedSheet` 还指着它；判断「下屏」看窗口本身，多等这一下是为了有动画时也成立 |
| 2026-11-06 | `destination` 的内容若不是经 AppKit 的弹出机制显示的，调用方的 `dismiss` 闭包返回就算结束 | 比如 `addChild(_:)` 加进来的子控制器，没有任何 dismiss 报告可等；写进了文档注释 |
| 2026-11-06 | 视图控制器的宿主释放时，只经 style 自己的弱引用去 dismiss；引用已空就只报告结束 | `presentingViewController` 是 `assign` 引用，宿主释放过程中读它不安全 |
| 2026-11-06 | `.modalWindow` 风格补了测试 | 以前没有任何测试；测试表明 `presentAsModalWindow` 不阻塞，binding 能正常关掉它 |
