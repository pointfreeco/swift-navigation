# Draft - AppKit 测试在 `swift test` 下不再中途以 0 退出

- **状态**: In Progress
- **创建日期**: 2026-11-05
- **最后更新**: 2026-11-05
- **实现分支**: `appkit-test-run-loop-exit`

## 摘要

本地用 `swift test` 跑 AppKit 的 Swift Testing 测试，偶尔跑到一半进程就结束了，退出码却是 0，没跑的测试结果直接丢失——一次没跑完的测试会被当成通过。原因在 [0001](0001-appkit-navigation-cleanup.md) 的后续项里已经查明：`swift test` 让 Swift Testing 跑在一个 `async` main 的进程里，主线程上的 `CFRunLoopRun()` 一返回，Swift 运行时就 `exit(0)`；分段控件的 `performClick`、保存和打开面板的创建会跑嵌套的事件循环，偶尔给最外层留下一个 `CFRunLoopStop`。这次让测试进程在主 run loop 被这样停下时接着跑，与真实 app 里 `NSApplication.run` 的表现一致。CI 的 `xcodebuild` 测试计划里没有 AppKit 的测试，它们只在本地跑：用 `swift test`，或在 Xcode 里直接打开包；后者不经过 `async` main，没有这个问题。

## 方案

1. **先写必定变红的回归测试**（已完成）：一个 exit test，在子进程里从主线程停掉最外层的 run loop（代替 AppKit 留下的那个 `CFRunLoopStop`），再要求主 actor 还能接着执行，最后以一个约定的退出码结束。没有修复时，子进程在 run loop 停下的那一刻以 0 退出，测试失败。它只在主 run loop 由 Swift 的 `async` main 驱动时运行（即 `swift test`）；Xcode 里没有这个问题，跳过。修复前实测：子进程以 0 退出，测试失败；修复后通过。
2. **加一个测试 trait `.keepsMainRunLoopRunning`**（已完成）：Swift Testing 在开始跑任何测试之前调用 trait 的 `prepare(for:)`，它在那时给主 run loop 装一个观察者，数 run loop 的进出层数；最外层那次运行一退出（只可能是被误停，因为 Swift Testing 自己用 `exit()` 结束进程），就在原地重新运行主 run loop。只在主 run loop 由 Swift 的 `async` main 驱动时安装，Xcode 与 `xcodebuild` 下什么都不做。实现在 `Tests/AppKitNavigationTests/MainRunLoopKeeper.swift`。
3. **给会跑嵌套事件循环的套件标上这个 trait**（已完成）：`ControlActionDeliveryTests`、`ControlBindingLifetimeTests`、`ControlBindingRoundTripTests`。装一次就保护整个进程；标在这几个套件上，是为了让人看出谁需要它。
4. **验证**（已完成）：
   - Xcode 27.2 上用 `swift test` 跑 AppKit 的 Swift Testing 测试，`--no-parallel` 连跑 30 次、默认并行 10 次，40 次都有完整的汇总行，退出码都是 0。同一台机器上临时去掉 trait 作对照，串行 30 次里截断 3 次，退出码同样是 0，正是要修的那种「没跑完却算通过」。
   - Xcode 的测试运行器下（`xcodebuild test`，包自己的 `swift-navigation-Package` scheme）没有卡住，回归测试按设计跳过，XCTest 16 条通过。唯一的失败是 `TextFieldSelectionTests` 的一条，与本次改动无关，见后续项。
   - Xcode 26.6 编过 AppKit 的测试 target；Xcode 27.2 全新构建整个包，本包代码零警告（只有依赖 `swift-issue-reporting` 的两条链接器警告）。

没有询问就采用的假设：

- trait 放在 `AppKitNavigationTests` 里，不新建 `TestingSupport` target：只有这一个 target 需要它，新建 target 又要改四份与上游共用的包清单。
- 不改 `swift test` 的调用方式，也不动 Swift Testing 的运行器。
- `NSPathControl` 构造器标签的修复（`date:` 直接改名为 `url:`）在同一分支上单独提交，不属于这份提案。

## 后续项

- 根目录的 `Package.resolved` 与上游保持一致，仍钉着 `swift-issue-reporting` 的旧名字 `xctest-dynamic-overlay`。`swift test` 不受影响；但用 Xcode 27 直接打开这个包（或对包跑 `xcodebuild`）时，计算依赖图失败：`PIFLoader: GUID 'PRODUCTREF-PACKAGE-PRODUCT:IssueReporting-…-dynamic' has already been registered`。加 `-IDEEnableNewPackagePIFBuilder=NO` 也一样。换成不含旧名字的 pin 就能编，但根目录这份就和上游不一致了。
- `TextFieldSelectionTests` 的「AppKit's own selection handling stays in place on every text field」在 Xcode 的测试运行器下失败：Xcode 测试时加载的主线程检查器替换了 `textViewDidChangeSelection:` 的实现，查到的实现所在镜像是 `libMainThreadChecker.dylib`，不是 AppKit。`swift test` 下通过。`main` 上同样如此（这个测试和它测的代码在本分支上没有改动）。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-05 | 让主 run loop 被误停后接着跑，不把相关测试移到 XCTest，也不改用 `xcodebuild` 判定 | 用户选定。移到 XCTest 只修了已知的几处，以后在 Swift Testing 里写同类测试还会复发；只换成 `xcodebuild` 则 `swift test` 照样不可靠 |
| 2026-11-05 | 用户批准，开始实现 | |
| 2026-11-05 | 判断「主 run loop 是否由 Swift 的 `async` main 驱动」，要在 run loop 的回调里读调用栈，安装观察者也放在那里做 | 第一版在 trait 的异步上下文里读 `Thread.callStackSymbols`，回归测试因此被误判为不需要而跳过：在 Swift 任务里取到的调用栈只有任务自己的异步帧，看不到底下的 run loop 和 `swift_task_asyncMainDrainQueue`。改为用 `CFRunLoopPerformBlock` 让最外层的 run loop 执行这段代码，同时保证观察者从最外层那次运行开始计数 |
| 2026-11-05 | 编译器低于 6.4 时公开导入 `Testing`（`#if compiler(<6.4)`），6.4 起保持内部导入 | Xcode 26.6 编测试 target 时，Swift 6.2 把 `KeepsMainRunLoopRunningTrait` 对 `SuiteTrait` 的遵循当成公开的，要求公开导入 `Testing`；6.4 没有这个要求。手头只能验证 6.2 和 6.4，没装 6.3，所以条件写成低于 6.4 |
| 2026-11-05 | 用 `xcodebuild` 验证时，临时用工作区那份锁定文件顶替根目录那份，跑完还原 | CI 的测试计划不含 AppKit 测试，只能用包自己的 scheme；根目录那份锁定文件让 Xcode 27 算不出依赖图（见后续项） |
| 2026-11-05 | 用 `xcodebuild` 验证时发现的两个旧问题记进后续项，不在这条分支上修 | 都与本次改动无关，`main` 上同样存在 |
| 2026-11-05 | 实现完成，待用户看过后收尾 | 四步全部完成；Xcode 27.2 上全量 `swift test` 只有已知的 `ButtonStateTests.testAsyncAnimationWarning` 失败，`main` 上同样如此。文档判断：不需要使用指南或实现说明，trait 的用法和原理写在它的文档注释里，取舍写在本提案里；README、DocC 和 `swift-navigation-bindings` skill 都不用改（DocC 只链接到 `NSPathControl` 扩展本身，skill 没提这个构造器的标签） |
