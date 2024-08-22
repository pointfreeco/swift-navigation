#if canImport(ObjectiveC)
  import Dispatch
  import ObjectiveC

  @MainActor
  extension NSObject {
    /// Observe access to properties of an observable (or perceptible) object.
    ///
    /// This tool allows you to set up an observation loop so that you can access fields from an
    /// observable model in order to populate your view, and also automatically track changes to
    /// any accessed fields so that the view is always up-to-date.
    ///
    /// It is most useful when dealing with non-SwiftUI views, such as UIKit views and controller.
    /// You can invoke the ``observe(_:)`` method a single time in the `viewDidLoad` and update all
    /// the view elements:
    ///
    /// ```swift
    /// override func viewDidLoad() {
    ///   super.viewDidLoad()
    ///
    ///   let countLabel = UILabel()
    ///   let incrementButton = UIButton(primaryAction: UIAction { [weak self] _ in
    ///     self?.model.incrementButtonTapped()
    ///   })
    ///
    ///   observe { [weak self] in
    ///     guard let self
    ///     else { return }
    ///
    ///     countLabel.text = "\(model.count)"
    ///   }
    /// }
    /// ```
    ///
    /// This closure is immediately called, allowing you to set the initial state of your UI
    /// components from the feature's state. And if the `count` property in the feature's state is
    /// ever mutated, this trailing closure will be called again, allowing us to update the view
    /// again.
    ///
    /// Generally speaking you can usually have a single ``observe(_:)`` in the entry point of your
    /// view, such as `viewDidLoad` for `UIViewController`. This works even if you have many UI
    /// components to update:
    ///
    /// ```swift
    /// override func viewDidLoad() {
    ///   super.viewDidLoad()
    ///
    ///   observe { [weak self] in
    ///     guard let self
    ///     else { return }
    ///
    ///     countLabel.isHidden = model.isObservingCount
    ///     if !countLabel.isHidden {
    ///       countLabel.text = "\(model.count)"
    ///     }
    ///     factLabel.text = model.fact
    ///   }
    /// }
    /// ```
    ///
    /// This does mean that you may execute the line `factLabel.text = model.fact` even when
    /// something unrelated changes, such as `store.model`, but that is typically OK for simple
    /// properties of UI components. It is not a performance problem to repeatedly set the `text` of
    /// a label or the `isHidden` of a button.
    ///
    /// However, if there is heavy work you need to perform when state changes, then it is best to
    /// put that in its own ``observe(_:)``. For example, if you needed to reload a table view or
    /// collection view when a collection changes:
    ///
    /// ```swift
    /// override func viewDidLoad() {
    ///   super.viewDidLoad()
    ///
    ///   observe { [weak self] in
    ///     guard let self
    ///     else { return }
    ///
    ///     dataSource = model.items
    ///     tableView.reloadData()
    ///   }
    /// }
    /// ```
    ///
    /// ## Cancellation
    ///
    /// The method returns an ``ObserveToken`` that can be used to cancel observation. For
    /// example, if you only want to observe while a view controller is visible, you can start
    /// observation in the `viewWillAppear` and then cancel observation in the `viewWillDisappear`:
    ///
    /// ```swift
    /// var observation: ObserveToken?
    ///
    /// func viewWillAppear() {
    ///   super.viewWillAppear()
    ///   observation = observe { [weak self] in
    ///     // ...
    ///   }
    /// }
    /// func viewWillDisappear() {
    ///   super.viewWillDisappear()
    ///   observation?.cancel()
    /// }
    /// ```
    ///
    /// - Parameter apply: A closure that contains properties to track and is invoked when the value
    ///   of a property changes.
    /// - Returns: A cancellation token.
    @discardableResult
    public func observe(_ apply: @escaping @MainActor @Sendable () -> Void) -> ObserveToken {
      observe { _ in apply() }
    }

    /// Observe access to properties of an observable (or perceptible) object.
    ///
    /// A version of ``observe(_:)`` that is passed the current transaction.
    ///
    /// - Parameter apply: A closure that contains properties to track and is invoked when the value
    ///   of a property changes.
    /// - Returns: A cancellation token.
    @discardableResult
    public func observe(
      _ apply: @escaping @MainActor @Sendable (_ transaction: UITransaction) -> Void
    ) -> ObserveToken {
      let token = SwiftNavigation.observe { transaction in
        MainActor._assumeIsolated {
          apply(transaction)
        }
      } task: { transaction, work in
        DispatchQueue.main.async {
          withUITransaction(transaction, work)
        }
      }
      tokens.append(token)
      return token
    }

    fileprivate var tokens: [Any] {
      get {
        objc_getAssociatedObject(self, Self.tokensKey) as? [Any] ?? []
      }
      set {
        objc_setAssociatedObject(self, Self.tokensKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }

    private static let tokensKey = malloc(1)!
  }
#endif
