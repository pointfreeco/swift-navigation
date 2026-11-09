#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit

extension NSTextView {
    /// Establishes a two-way connection between a binding and the text view's text.
    ///
    /// ```swift
    /// commentTextView.bind(text: $model.comment)
    /// ```
    ///
    /// The text view shows the bound text, and writes each of the user's edits back, as
    /// ``AppKit/NSTextField/bind(text:)`` does for a text field. While an input method is still
    /// composing text, nothing is written back until the composition ends.
    ///
    /// A change to the binding replaces the text only when it differs from what the text view
    /// shows, and keeps the selection where it can. Changes that arrive while an input method is
    /// composing are skipped, so that the composition survives; the user's next edit writes the
    /// text view's text back.
    ///
    /// The binding learns of edits from notifications, and leaves the text view's delegate alone.
    ///
    /// - Parameter text: The binding to read from for the text, and write to when the user edits
    ///   it.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(text: UIBinding<String>) -> ObserveToken {
        let bindingToken = establishBinding(
            text,
            to: \NSTextView.string,
            of: self,
            through: nil,
            observesKeyPath: false
        ) { textView, newText, _ in
            guard textView.string != newText, !textView.hasMarkedText() else { return }
            let selectedRanges = textView.selectedRanges
            textView.string = newText
            let length = (newText as NSString).length
            textView.selectedRanges = selectedRanges.map { selectedRange in
                let range = selectedRange.rangeValue
                let location = min(range.location, length)
                return NSValue(range: NSRange(location: location, length: min(range.length, length - location)))
            }
        }
        let editObserver = NotificationObserver(
            name: NSText.didChangeNotification, object: self
        ) { [weak self] _ in
            guard let self, !hasMarkedText(), text.wrappedValue != string else { return }
            text.wrappedValue = string
        }
        let token = ObserveToken {
            bindingToken.cancel()
            MainActor._assumeIsolated {
                editObserver.invalidate()
            }
        }
        observationTokens[\NSTextView.string] = token
        return token
    }

    /// Removes the binding established with ``AppKit/NSTextView/bind(text:)``.
    public func unbindText() {
        removeBinding(to: \NSTextView.string)
    }
}
#endif
