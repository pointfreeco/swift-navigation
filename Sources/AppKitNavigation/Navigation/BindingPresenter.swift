#if canImport(AppKit) && !targetEnvironment(macCatalyst)

  import AppKit
  import SwiftNavigation

  /// One way of showing content: as a sheet, in a modal loop or session, in a popover, or as a
  /// presented view controller.
  ///
  /// A style only knows how to show and hide content. When to do either is up to the
  /// ``BindingPresenter`` that uses it.
  @MainActor
  protocol PresentationStyle {
    associatedtype Content: AnyObject

    /// Calls `body` once the anchor can show content — right away when it already can — and
    /// returns a closure that cancels a wait that is no longer wanted.
    func whenReady(_ body: @escaping @MainActor () -> Void) -> @MainActor () -> Void

    /// Shows `content`, and calls `didEnd` exactly once, after the content has left the screen,
    /// whatever ended it: the user, ``end(_:transaction:)``, or AppKit.
    ///
    /// Returns without waiting for the content to end.
    func begin(
      _ content: Content,
      transaction: UITransaction,
      didEnd: @escaping @MainActor () -> Void
    )

    /// Asks `content` to leave the screen, which leads to the `didEnd` given to
    /// ``begin(_:transaction:didEnd:)``.
    ///
    /// Works from the content's side rather than the anchor's, so that it still works while the
    /// object that owns the presentation is being deallocated.
    func end(_ content: Content, transaction: UITransaction)
  }

  extension PresentationStyle {
    func whenReady(_ body: @escaping @MainActor () -> Void) -> @MainActor () -> Void {
      body()
      return {}
    }
  }

  /// Shows content while a binding holds a value: one for every call of `modal`, `sheet`,
  /// `popover` or `present`, kept alive by the object it was called on.
  ///
  /// - Content is held here while it is on screen, rather than by whoever made it.
  /// - A new item, told apart by its identifier, replaces the content only once the previous
  ///   content has left the screen.
  /// - `onDismiss` runs exactly once for every content that was shown, after it left the screen,
  ///   whatever ended it. Content that was never shown does not call it.
  /// - Content that ends on its own — the user closed it — writes `nil` back to the binding before
  ///   `onDismiss` runs.
  /// - When the object that owns this presenter goes away, the content on screen is ended.
  /// - Once the returned token is cancelled, the binding no longer shows or ends anything, but
  ///   content the user ends still writes back and calls `onDismiss`.
  @MainActor
  final class BindingPresenter<Style: PresentationStyle>: NSObject {
    private let style: Style
    private let onDismiss: (() -> Void)?
    private var source: Source?
    private var phase = Phase.idle
    private var waitCount = 0
    private var observation: ObserveToken?

    init(style: Style, onDismiss: (() -> Void)?) {
      self.style = style
      self.onDismiss = onDismiss
      super.init()
    }

    deinit {
      // NB: The owner, a window, view, view controller or other AppKit object, is released on the
      //     main thread.
      MainActor._assumeIsolated {
        endBecauseTheOwnerWentAway()
      }
    }

    /// Starts following `item`, showing what `content` makes while it holds a value.
    func observe<Item>(
      item: UIBinding<Item?>,
      id: @escaping (Item) -> AnyHashable?,
      content: @escaping (UIBinding<Item>) -> Style.Content
    ) -> ObserveToken {
      source = Source(
        currentItem: {
          guard let unwrappedItem = UIBinding(item) else { return nil }
          return Source.Item(identity: id(unwrappedItem.wrappedValue)) {
            content(unwrappedItem)
          }
        },
        clearItem: { identity in
          if let wrappedValue = item.wrappedValue, id(wrappedValue) == identity {
            item.wrappedValue = nil
          }
        }
      )
      let observation = observe { [weak self] transaction in
        self?.update(transaction: transaction)
      }
      self.observation = observation
      return observation
    }

    private func update(transaction: UITransaction) {
      guard let source else { return }
      let currentItem = source.currentItem()
      switch phase {
      case .idle:
        if currentItem != nil {
          waitUntilReady(transaction: transaction)
        }

      case let .waiting(cancelWait):
        if currentItem == nil {
          cancelWait()
          phase = .idle
        }

      case let .presented(presentation):
        guard let currentItem else {
          end(presentation, transaction: transaction)
          return
        }
        if let identity = presentation.identity, identity != currentItem.identity {
          end(presentation, transaction: transaction)
        }

      case .ending:
        // NB: Whatever the binding holds once the content has left the screen decides what comes
        //     next.
        break
      }
    }

    private func waitUntilReady(transaction: UITransaction) {
      waitCount += 1
      let wait = waitCount
      phase = .waiting(cancel: {})
      let cancelWait = style.whenReady { [weak self] in
        guard let self, case .waiting = self.phase, self.waitCount == wait else { return }
        self.show(transaction: transaction)
      }
      if case .waiting = phase, waitCount == wait {
        phase = .waiting(cancel: cancelWait)
      }
    }

    private func show(transaction: UITransaction) {
      guard let source, let currentItem = source.currentItem() else {
        phase = .idle
        return
      }
      let presentation = Presentation(
        content: currentItem.makeContent(),
        identity: currentItem.identity,
        clearItem: { [identity = currentItem.identity] in
          source.clearItem(identity)
        }
      )
      phase = .presented(presentation)
      #if AppKitPlus
        installDismissAction(for: presentation)
      #endif
      let onDismiss = onDismiss
      style.begin(presentation.content, transaction: transaction) { [weak self] in
        guard !presentation.hasEnded else { return }
        presentation.hasEnded = true
        if let self {
          self.didEnd(presentation)
        } else {
          // NB: The owner went away while the content was on screen, which is what ended it.
          presentation.clearItem()
          onDismiss?()
        }
      }
    }

    #if AppKitPlus
      /// Lets the content close itself with `traitCollection.dismiss()`, as if the user had.
      private func installDismissAction(for presentation: Presentation) {
        guard let host = presentation.content as? any DismissActionHost else { return }
        host.installDismissAction(
          AppKitDismissAction { [weak self, weak presentation] transaction in
            guard
              let self,
              let presentation,
              case let .presented(current) = phase,
              current === presentation
            else { return }
            // NB: The phase stays as it is, so that the end counts as the user's: the binding is
            //     cleared, and 'onDismiss' runs once the content has left the screen.
            style.end(presentation.content, transaction: transaction)
          }
        )
      }
    #endif

    private func end(_ presentation: Presentation, transaction: UITransaction) {
      phase = .ending(presentation)
      style.end(presentation.content, transaction: transaction)
    }

    private func didEnd(_ presentation: Presentation) {
      switch phase {
      case let .presented(current) where current === presentation:
        // NB: Nothing asked the content to end, so the user did.
        phase = .idle
        presentation.clearItem()
      case let .ending(current) where current === presentation:
        phase = .idle
      default:
        break
      }
      onDismiss?()
      if observation?.isCancelled != true {
        update(transaction: UITransaction())
      }
    }

    private func endBecauseTheOwnerWentAway() {
      switch phase {
      case let .waiting(cancelWait):
        cancelWait()
      case let .presented(presentation):
        style.end(presentation.content, transaction: UITransaction())
      case .idle, .ending:
        break
      }
    }

    private enum Phase {
      case idle
      case waiting(cancel: @MainActor () -> Void)
      case presented(Presentation)
      case ending(Presentation)
    }

    @MainActor
    private final class Presentation {
      let content: Style.Content
      let identity: AnyHashable?
      let clearItem: () -> Void
      var hasEnded = false

      init(content: Style.Content, identity: AnyHashable?, clearItem: @escaping () -> Void) {
        self.content = content
        self.identity = identity
        self.clearItem = clearItem
      }
    }

    private struct Source {
      struct Item {
        let identity: AnyHashable?
        let makeContent: () -> Style.Content
      }

      /// The item the binding holds now, if any.
      let currentItem: () -> Item?
      /// Writes `nil` to the binding if it still holds the item with the given identity.
      let clearItem: (AnyHashable?) -> Void
    }
  }

  @MainActor
  private let presentersKey = malloc(1)!

  extension NSObject {
    /// Shows content in the given style while `item` holds a value, for as long as this object
    /// lives.
    @MainActor
    func bindPresentation<Style: PresentationStyle, Item>(
      _ style: Style,
      item: UIBinding<Item?>,
      id: @escaping (Item) -> AnyHashable?,
      onDismiss: (() -> Void)?,
      content: @escaping (UIBinding<Item>) -> Style.Content
    ) -> ObserveToken {
      let presenter = BindingPresenter(style: style, onDismiss: onDismiss)
      let presenters = objc_getAssociatedObject(self, presentersKey) as? [NSObject] ?? []
      objc_setAssociatedObject(
        self, presentersKey, presenters + [presenter], .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
      return presenter.observe(item: item, id: id, content: content)
    }
  }

#endif
