# Draft - AppKit 控件绑定第二批：随模型变化的选项、文本视图、集合视图的选中

- **状态**: In Progress
- **创建日期**: 2026-11-09
- **最后更新**: 2026-11-09
- **实现分支**: `appkit-more-control-bindings`

## 摘要

[0003](0003-appkit-common-control-bindings.md) 和 [0004](0004-appkit-table-selection-bindings.md) 之后，下游 App 里还剩三类手写的同步：

- 弹出按钮和分段控件绑定之前，菜单项或分段要先手工生成（PrivateSymbols 3 处）；选项随模型变化时，整份菜单要重建（XCOrganizer 的标签菜单）。
- `NSTextView` 的文本与模型手工同步（XCOrganizer 的检查器）。
- `NSCollectionView` 的多选与模型手工同步，还要自己防止回写时重复触发（PrivateSymbols 的符号浏览器，约 30 行）。

这一批补上对应的绑定，写法沿用现有的 `bind(selection:options:)` 和表格的 `bind(selection:dataSource:)`。

## 方案

调用点：

```swift
// Items generated for an existing control, from fixed options
weightPopUpButton.bind(selection: $model.weight, options: SymbolWeight.allCases, title: \.displayName)

// With an image for each option
visibilityPopUpButton.bind(
    selection: $model.visibilityFilter,
    options: SymbolVisibilityFilter.allCases,
    title: \.displayName,
    image: { NSImage(systemSymbolName: $0.iconName, accessibilityDescription: $0.displayName) }
)

// Options that follow the model: read again whenever what they read changes
tagPopUpButton.bind(
    selection: $model.selectedTagID,
    options: { [nil] + model.tags.map(\.id) },
    title: { tagID in tagID.flatMap { model.tags[id: $0]?.name } ?? "No Tag" }
)

textView.bind(text: $model.comment)

collectionView.bind(selection: $model.selectedSymbolIDs, dataSource: dataSource)  // Set<Symbol.ID>
collectionView.bind(selection: $model.focusedSymbolID, dataSource: dataSource)    // Symbol.ID?
```

1. **按选项生成项**（已完成）：`NSPopUpButton` 和 `NSSegmentedControl` 加 `bind(selection:options:title:image:)`，`image:` 可以不传。
   - 绑定时按选项生成菜单项或分段，再建立与现有 `bind(selection:options:)` 相同的双向绑定。
   - `options` 传数组时，项只生成一次。传闭包时，闭包与 `title:`、`image:` 在同一次 `observe` 里读取；读到的模型属性一变，就重新生成项并恢复选中。
   - 绑定只管理它生成的项。弹出按钮里 App 另加的项（比如「新建标签…」）留在后面；用户选中这些项时不写回，选中回到绑定的值。
   - 分段控件只管段数、标题和图标；宽度等仍由调用方设置。
   - 现有的便捷构造器 `init(selection:options:title:)` 改为调用新绑定，行为不变。
2. **文本视图**（已完成）：`NSTextView.bind(text:)`。
   - 用户每次编辑都写回，与 `NSTextField.bind(text:)` 一致。输入法还在组字（有 marked text）时不写回，组完再写。
   - 模型变化时，只在内容不同时替换文本，选区尽量保留。
   - 不占用 delegate，靠 `NSText.didChangeNotification` 得知编辑。
3. **集合视图的选中**（已完成）：`NSCollectionView.bind(selection:dataSource:)`，多选绑 `Set<ItemIdentifier>`，单选绑 `ItemIdentifier?`。
   - 另配一个传两个查找函数的版本 `bind(selection:indexPath:itemIdentifier:)`，给不用 diffable data source 的集合视图，写法与表格的 `bind(selection:row:itemIdentifier:)` 对应。
   - 用户的点选、⌘ 或 ⇧ 点选、拖选、方向键、全选，以及 App 直接设置 `selectionIndexPaths`，都写回；模型改变选中时，库自己防止回写。
   - 集合视图只把用户的选中变化告诉 delegate，所以绑定在 App 的 delegate 前面放一个转发代理：所有消息原样转给 App 的 delegate，只顺带听选中变化；App 之后另设 delegate 时重新放到前面，解除绑定时把 App 的 delegate 放回去。读 `delegate` 拿到的是代理。
   - 数据源更新删掉选中项、重新加载清掉被重载项的选中时，集合视图什么都不报，这些标识留在绑定里；项出现在屏幕上时，绑定里还有它的标识就重新选上，并补上选中外观（PrivateSymbols 现在手工修的就是这个）。
4. **示例**：在现有的「选项绑定」和「表格选中」案例里各加上新绑定的演示。
5. **文档与验证**：每种绑定先写双向测试再实现。DocC 首页「绑定」一组登记 `NSTextView` 和 `NSCollectionView`；`swift-navigation-bindings` skill 的绑定清单补上。Xcode 27.2 跑 AppKit 的全部测试，Xcode 26.6 编译库和测试，CaseStudies 的 macOS 版只编译、不点界面。

没有询问就采用的假设：

- 选中值为空的那一项用可选值表达，例如 `options` 里放一个 `nil`，标题写成「No Tag」，不另加参数。
- 表格和大纲的多选这次不做：下游没有用例；以后照集合视图的 `Set` 版本补上。
- 文本视图只绑纯文本；富文本、选区和焦点这次不做。
- 下游 App 改用新绑定不在这一批。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-09 | Created as Draft | 调查依赖这个 fork 的 App 后，用户选定补上随模型变化的选项、文本视图和集合视图多选三种绑定 |
| 2026-11-09 | 用户批准，开始实现 | 照提案做，表格和大纲的多选不在这一批；与另两份提案在同一条分支上实现，做完在本地合进 `main`、不推送 |
| 2026-11-09 | 便捷构造器也改由新绑定生成项；用户选中 App 自己加的项时，不再报问题，而是不写回、选中回到绑定的值 | 两条路径生成的项由同一套代码管理，行为应当一致。自己搭好菜单再调用 `bind(selection:options:)` 的写法仍按位置对应，选中选项之外的项照旧报问题，测试改为覆盖这种写法 |
| 2026-11-09 | 两个便捷构造器各加一个可省的 `image:` 参数 | 与新绑定的参数一致；不传时与原来相同 |
| 2026-11-09 | 带自身动作的菜单项（如「新建标签…」）靠菜单的 `didSendActionNotification` 得知被选中 | 这类项发送自己的动作，不发弹出按钮的动作，绑定的 target/action 收不到 |
| 2026-11-09 | `NSTextView` 另加 `unbindText()` | 与 `unbindIsCollapsed()`、`unbindSelection()` 一致；文本视图不是控件，用不了 `unbind(_:)` |
| 2026-11-09 | 集合视图改用转发代理得知用户的选中变化，不再「不占用 delegate」 | 探针实测：全选、取消全选只回调 delegate，不发 KVO；方向键会发 KVO；删掉选中项、重新加载被重载项都既不发 KVO 也不回调 delegate。用户在三种做法（转发代理、只从模型到界面、先不做）里选了转发代理 |
| 2026-11-09 | 数据源更新拿走或重载掉的选中项，标识留在绑定里；项上屏时按绑定重新选上 | 集合视图对这两种变化什么都不报，绑定无从写回；绑定是选中的来源，项回到屏幕上时以它为准 |
