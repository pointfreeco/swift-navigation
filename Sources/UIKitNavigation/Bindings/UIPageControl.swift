#if canImport(UIKit) && !os(watchOS)
  import UIKit

  @available(iOS 14, tvOS 14, *)
  extension UIPageControl {
    /// Creates a new page control with the specified frame and registers the binding against the
    /// current page.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - currentPage: The binding to read from for the current page, and write to when the
    ///     current page changes.
    public convenience init(frame: CGRect = .zero, currentPage: UIBinding<Int>) {
      self.init(frame: frame)
      bind(currentPage: currentPage)
    }

    /// Establishes a two-way connection between a binding and the page control's current page.
    ///
    /// - Parameter currentPage: The binding to read from for the current page, and write to when
    ///   the current page changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(currentPage: UIBinding<Int>) -> ObserveToken {
      bind(currentPage, to: \.currentPage, for: .valueChanged)
    }
  }
#endif
