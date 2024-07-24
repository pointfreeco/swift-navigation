#if canImport(Testing)
import SwiftNavigation
import Testing

@Suite
struct IsolationTests {
  @Test
  @MainActor
  func isolationOnMinActor() async {
    let model = MainActorModel()
    let token = observe { _ in
      _ = model.count
      MainActor.assertIsolated()
    }
    model.count += 1
    _ = token
  }

  @Test
  @GlobalActorIsolated
  func isolationOnGlobalActor() async {
    let model = GlobalActorModel()
    let token = observe { _ in
      _ = model.count
      GlobalActorIsolated.assertIsolated()
    }
    model.count += 1
    _ = token
  }
}

@globalActor private actor GlobalActorIsolated: GlobalActor {
  static let shared = GlobalActorIsolated()
}

@Perceptible
@MainActor
class MainActorModel {
  var count = 0
}

@Perceptible
@GlobalActorIsolated
private class GlobalActorModel {
  var count = 0
}
#endif
