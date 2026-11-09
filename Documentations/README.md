# 文档索引

这个 fork 自己的文档。库的公开 API 文档在各 target 的 `Documentation.docc` 里，与上游共用。

## Evolutions

- [Evolutions/README.md](Evolutions/README.md)：提案索引与状态。
- [0001-appkit-navigation-cleanup.md](Evolutions/0001-appkit-navigation-cleanup.md)：AppKitNavigation 清理——警告、重复代理和多余依赖。
- [0002-appkit-test-run-loop-exit.md](Evolutions/0002-appkit-test-run-loop-exit.md)：AppKit 测试在 `swift test` 下不再中途以 0 退出。
- [0003-appkit-common-control-bindings.md](Evolutions/0003-appkit-common-control-bindings.md)：AppKit 常用控件的类型化绑定。
- [0004-appkit-table-selection-bindings.md](Evolutions/0004-appkit-table-selection-bindings.md)：表格与大纲的选中绑定、大纲的展开状态绑定。
- [0005-appkit-presentation-redesign.md](Evolutions/0005-appkit-presentation-redesign.md)：AppKit 弹出 API 重做——生命周期收进一层，重载合并。
- [0006-appkit-window-backed-content.md](Evolutions/0006-appkit-window-backed-content.md)：把公开协议 `ModalContent` 改名为 `WindowBackedContent`。
- [0007-appkit-case-studies.md](Evolutions/0007-appkit-case-studies.md)：给 AppKit 案例补上弹出与新控件绑定的演示。
- [draft-observe-unowned-self.md](Evolutions/draft-observe-unowned-self.md)：简化 `observe` 闭包里对 `self` 的捕获（In Progress）。
- [draft-appkit-more-control-bindings.md](Evolutions/draft-appkit-more-control-bindings.md)：AppKit 控件绑定第二批——随模型变化的选项、文本视图、集合视图的选中（In Progress）。
- [draft-appkit-animations-case-study.md](Evolutions/draft-appkit-animations-case-study.md)：AppKit 动画案例（In Progress）。
- [draft-appkit-stack-navigation.md](Evolutions/draft-appkit-stack-navigation.md)：可选集成 AppKitPlus，把 UIKit 的栈式导航搬到 AppKit（In Progress）。

## Internal

- [ReviewDecisions.md](Internal/ReviewDecisions.md)：审查中判为误报、不修或暂缓的发现及理由，以及没能在运行时验证的部分；每次审查前先对照。
