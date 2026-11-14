#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Call shapes the presentation overloads must accept.
  ///
  /// These guard the overload sets more than any behavior: each call only has to type-check. The
  /// bindings never hold a value, so nothing is ever presented.
  final class PresentationOverloadTests: XCTestCase {
    private struct Item: Identifiable {
      let id: Int
    }

    // NB: Every presentation has an overload whose content takes the item and one whose content
    //     takes a binding to it. A closure that ignores its parameter fits both, so these calls only
    //     compile while the binding overloads are disfavored.
    @MainActor
    func testAClosureThatIgnoresItsItemPicksTheOverloadTakingTheItem() {
      let host = makeHost()
      @UIBinding var item: Item?

      host.window.modal(item: $item) { _ in NSAlert() }
      host.window.modal(item: $item, id: \.id) { _ in NSAlert() }
      host.window.modalSession(item: $item) { _ in NSWindow() }
      host.window.modalSession(item: $item, id: \.id) { _ in NSWindow() }
      host.window.sheet(item: $item) { _ in NSAlert() }
      host.window.sheet(item: $item, id: \.id) { _ in NSAlert() }
      host.view.popover(item: $item) { _ in NSViewController() }
      host.view.popover(item: $item, id: \.id) { _ in NSViewController() }
      host.viewController.present(item: $item, style: .sheet) { _ in NSViewController() }
      host.viewController.present(item: $item, id: \.id, style: .sheet) { _ in NSViewController() }
      if #available(macOS 14.0, *) {
        let toolbarItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("Item"))
        toolbarItem.popover(item: $item) { _ in NSViewController() }
        toolbarItem.popover(item: $item, id: \.id) { _ in NSViewController() }
      }

      spinRunLoop(for: 0.1)
      XCTAssertNil(host.window.attachedSheet)
    }

    @MainActor
    func testAClosureTakingABindingToTheItemPicksTheOverloadTakingABinding() {
      let host = makeHost()
      @UIBinding var item: Item?

      host.window.modal(item: $item) { $item in Self.makeAlert(for: $item) }
      host.window.sheet(item: $item, id: \.id) { $item in Self.makeAlert(for: $item) }
      host.view.popover(item: $item) { $item in Self.makeViewController(for: $item) }
      host.viewController.present(item: $item, style: .sheet) { $item in
        Self.makeViewController(for: $item)
      }

      spinRunLoop(for: 0.1)
      XCTAssertNil(host.window.attachedSheet)
    }

    // NB: The shape XCOrganizer uses: several statements, a weak capture, and two returns.
    @MainActor
    func testAClosureWithSeveralStatementsAndReturns() {
      let host = makeHost()
      @UIBinding var item: Item?

      host.window.sheet(item: $item) { [weak host = host.viewController] currentItem in
        guard let host else { return Self.makeSheetWindow(for: currentItem) }
        return Self.makeSheetWindow(for: currentItem, title: host.title)
      }

      spinRunLoop(for: 0.1)
      XCTAssertNil(host.window.attachedSheet)
    }

    @MainActor
    private static func makeAlert(for item: UIBinding<Item>) -> NSAlert {
      let alert = NSAlert()
      alert.messageText = "Item \(item.wrappedValue.id)"
      return alert
    }

    @MainActor
    private static func makeViewController(for item: UIBinding<Item>) -> NSViewController {
      let viewController = NSViewController()
      viewController.title = "Item \(item.wrappedValue.id)"
      return viewController
    }

    @MainActor
    private static func makeSheetWindow(for item: Item, title: String? = nil) -> NSWindow {
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 240, height: 160),
        styleMask: [.titled],
        backing: .buffered,
        defer: true
      )
      window.title = title ?? "Item \(item.id)"
      return window
    }
  }
#endif
