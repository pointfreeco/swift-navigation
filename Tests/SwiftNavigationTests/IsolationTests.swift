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
  @GA
  func isolationOnGlobalActor() async {
    let model = GlobalActorModel()
    let token = observe { _ in
      _ = model.count
      GA.assertIsolated()
    }
    model.count += 1
    _ = token
  }

//  @Test
//  func nonIsolated() async {
//    let model = NonIsolatedModel()
//    let token = observe { _ in
//      _ = model.count
//      GA.assertIsolated()
//    }
//    model.count += 1
//    _ = token
//  }
}

@globalActor actor GA: GlobalActor {
  static let shared = GA()
}

@Perceptible
@MainActor
class MainActorModel {
  var count = 0
}

@Perceptible
@GA
class GlobalActorModel {
  var count = 0
}

@Perceptible
class NonIsolatedModel {
  var count = 0
}
