#if Perception
  public import PerceptionCore
#else
  public import Observation
#endif

#if Perception
  public typealias _Observable = Perceptible
#else
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  public typealias _Observable = Observable
#endif

@discardableResult
@_transparent
package func skippingPerceptionChecking<R>(
  operation: () throws -> R,
  file: String = #fileID,
  line: UInt = #line
) rethrows -> R {
  #if Perception
    try _PerceptionLocals.$skipPerceptionChecking.withValue(
      true,
      operation: operation,
      file: file,
      line: line
    )
  #else
    try operation()
  #endif
}
