# Draft - 表格与大纲的选中绑定、大纲的展开状态绑定

- **状态**: In Progress
- **创建日期**: 2026-11-05
- **最后更新**: 2026-11-05
- **实现分支**: `appkit-table-selection-bindings`

## 摘要

本机依赖这个 fork 的项目里，表格和大纲的选中同步约 20 处，是手写逻辑最多的一块：在选中变化的代理方法里按行查出条目写进模型，在 `observe {}` 里再按模型把行选回去，还有 3 处要靠 `isSyncingSelection` 一类的标志位，挡住「把行选回去」触发的选中通知再写回模型。XCOrganizer 另外手写了大纲展开、折叠状态与模型的同步。库里没有任何对应的绑定。这次给 `NSTableView`（因而也包括 `NSOutlineView`）加单选的双向绑定，给 `NSOutlineView` 加展开状态的双向绑定，标志位交给库内部处理。

## 方案

调用点：

```swift
// diffable 数据源（AppKit 自带的或 AppKitPlus 的）：传它的两个查找方法
outlineView.bind(
  selection: $model.selectedItem,
  row: dataSource.row(forItemIdentifier:),
  itemIdentifier: dataSource.itemIdentifier(forRow:)
)
// AppKit 自带的 diffable 数据源，简写
tableView.bind(selection: $model.selectedApplicationID, dataSource: dataSource)
// 普通数组
tableView.bind(
  selection: $model.selectedCategoryKey,
  row: { key in model.categories.firstIndex { $0.key == key } },
  itemIdentifier: { row in model.categories[row].key }
)
// 大纲的展开状态
outlineView.bind(expandedItems: $model.expandedItems, itemIdentifier: dataSource.itemIdentifier(forRow:))
```

1. **单选绑定**（已完成）：`NSTableView.bind(selection:row:itemIdentifier:)`，绑定一个可选的标识。模型变了就按 `row` 找到行选中；用户改了选中（表格发出选中变化的通知），就按 `itemIdentifier` 查出标识写回。绑定自己选行时发出的通知不写回。表格变成没有选中行时写回 `nil`——用户点空白处、选中的行被删掉或被折叠隐藏都算。模型里的标识对应不到可见的行时，表格取消选中，模型保留原值。配 `unbindSelection()`。
2. **AppKit 自带 diffable 数据源的简写**（已完成）：`bind(selection:dataSource:)`，用 `NSTableViewDiffableDataSource` 的两个查找方法。
3. **大纲的展开状态**：`NSOutlineView.bind(expandedItems:itemIdentifier:)`，绑定一个标识的 `Set`。模型变了就从上到下逐行展开或折叠，展开父项后露出的子项接着处理；用户展开或折叠（大纲发出展开、折叠的通知）时把标识加进或移出集合。配 `unbindExpandedItems()`。
4. **文档与验证**：DocC 首页「绑定」一组登记 `NSTableView`、`NSOutlineView`；`swift-navigation-bindings` skill 补上新绑定。每种绑定先写双向测试再实现；Xcode 27.2 跑 AppKit 的全部测试，Xcode 26.6 编译 AppKit 的库和测试。

没有询问就采用的假设：

- 只做单选；多选以后另做。
- 标识要求 `Hashable`，与 diffable 数据源和展开状态用的 `Set` 一致。
- 通过表格、大纲发出的通知得知用户的改动，不占用、也不替换 app 自己的 delegate。
- 绑定不负责滚动到选中的行。
- 数据重新加载后，绑定在两种情况下重新对一次选中和展开：绑定的值变了，或者 `row`、`itemIdentifier` 闭包里读到的可观察状态变了。diffable 数据源应用快照时，表格自己会让选中跟着条目走；新条目的展开状态应该放进快照里。
- 只改 fork 独有的 AppKitNavigation；各项目改用新绑定不在这一批。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-11-05 | 行和标识用两个查找函数对应，另给 AppKit 自带的 diffable 数据源一个简写 | 用户选定。diffable 数据源直接传它自己的两个方法，普通数组和对象树写两个闭包，任何数据源都能用 |
| 2026-11-05 | 表格变成没有选中行时，模型写回 `nil` | 用户选定。模型如实反映表格；XCOrganizer「折叠后把选中移到父项」这类逻辑改由模型自己处理 |
| 2026-11-05 | 一起做大纲的展开状态绑定；多选、`NSCollectionView` 的选中以后再说 | 用户选定 |
| 2026-11-05 | 用户批准，开始实现 | |
