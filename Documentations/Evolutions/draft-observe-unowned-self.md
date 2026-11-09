# Draft - 简化 `observe` 闭包里对 `self` 的捕获

- **状态**: In Progress
- **创建日期**: 2026-11-09
- **最后更新**: 2026-11-09
- **实现分支**: `appkit-more-control-bindings`

## 摘要

依赖这个 fork 的 4 个 App 里有 55 个 `NSObject.observe` 闭包写了 `[weak self]`：43 个下一行就是 `guard let self else { return }`，11 个写成 `self?.method()`。这些写法只为打破「对象 → 观察令牌 → 闭包 → 对象」的引用环。`NSObject.observe` 把令牌挂在对象自己身上，对象释放时令牌随之释放；之后每次重新运行闭包之前，库都会先检查令牌还在不在，所以闭包不会在对象释放后被调用。因此这里用 `[unowned self]` 是安全的，而且 Swift 允许在 `unowned` 捕获的闭包里省略 `self.`（SE-0269），闭包体不用改。这一批不加新 API：用测试把「对象释放后闭包不再运行」固定为库的保证，并把 `[unowned self]` 写成推荐写法。

## 方案

调用点：

```swift
// Before
observe { [weak self] in
    guard let self else { return }
    titleLabel.stringValue = model.title
}
observe { [weak self] in
    self?.applyComment()
}

// After
observe { [unowned self] in
    titleLabel.stringValue = model.title
}
observe { [unowned self] in
    applyComment()
}
```

1. **测试**（已完成）：在 AppKitNavigation 的测试里加两条回归测试。闭包用 `[weak self]` 并计数，这样保证一旦失效，测试会失败而不是崩溃。
   - 对象释放后再改模型、转几圈 run loop，闭包一次也没被调用。
   - 令牌被对象以外的东西留住时，对象释放后闭包仍会被调用。这正是推荐写法的前提，文档要写明。
2. **文档**（已完成）：AppKitNavigation 的 DocC 首页加一段，说明在 `NSObject.observe` 里推荐写 `[unowned self]` 及其前提；`swift-navigation-bindings` skill 的写法和常见错误同步改。
3. **示例**（已完成）：AppKit 案例里的 12 处 `observe { [weak self] in … }` 改成新写法。

没有询问就采用的假设：

- 前提：令牌只由对象自己持有，也就是 `observe` 的默认做法，或存进对象自己的属性。令牌交给别的对象保管时，仍写 `[weak self]`。
- 只适用于 `NSObject.observe`。全局函数 `observe(_:)` 返回的令牌由调用方保管，不在此列。
- 不改与上游共用的代码和文档注释（`NSObject+Observe.swift`），说明只写在 fork 自己的文档里。
- 下游 App 改写法不在这一批。

没有采用的写法：新增一个把对象传进闭包的重载。照 KVO 的 `observe(_:options:changeHandler:)` 写成 `observe { owner, transaction in … }`，可以完全不写捕获列表，但闭包里每次访问成员都要加 `owner.`，下游 43 个多行闭包反而更啰嗦。只带一个参数的 `observe { owner in … }` 和现有的 `observe { transaction in … }` 只差参数类型，`observe { _ in … }` 会产生歧义。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-09 | Created as Draft | 下游 4 个 App 的 55 个 `observe` 闭包都写了 `[weak self]`，其中 43 个还要再写一行 `guard let self`；用户选定简化这个写法 |
| 2026-11-09 | 用户选定推荐 `[unowned self]`，不加把对象传进闭包的新重载 | 新重载要在每次访问成员时写 `owner.`，下游多行闭包反而更啰嗦；`[unowned self]` 保留隐式 `self`，闭包体不用改 |
| 2026-11-09 | 用户批准，开始实现 | 与另两份提案在同一条分支 `appkit-more-control-bindings` 上实现，做完在本地合进 `main`、不推送 |
| 2026-11-09 | 实现完成，待用户看过后收尾 | 两条回归测试通过；DocC 首页加了一节「Observing from a view or view controller」，`swift-navigation-bindings` skill 的示例、说明和常见错误同步改成 `[unowned self]`；AppKit 案例 12 处改完，CaseStudies 的 macOS 版编译通过。文档判断：推荐写法和前提都写进了 DocC 和 skill，不需要另写使用指南或实现说明，没有新术语 |
