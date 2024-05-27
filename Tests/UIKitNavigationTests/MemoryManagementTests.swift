import UIKitNavigation
import XCTest

@available(iOS 16.0, *)
final class MemoryManagementTests: XCTestCase {
  @MainActor
  func testPresentIsPresented_ObservationDoesNotRetainModel() {
    weak var weakModel: Model?
    do {
      @UIBindable var model = Model()
      weakModel = model
      let vc = UIViewController()
      vc.present(isPresented: $model.isPresented) { UIViewController() }
    }
    XCTAssertNil(weakModel)
  }

  @MainActor
  func testPresentItem_ObservationDoesNotRetainModel() {
    weak var weakModel: Model?
    do {
      @UIBindable var model = Model()
      weakModel = model
      let vc = UIViewController()
      vc.present(item: $model.child) { _ in UIViewController() }
    }
    XCTAssertNil(weakModel)
  }

  @MainActor
  func testBinding_ObservationDoesNotRetainModel() {
    weak var weakModel: Model?
    do {
      @UIBindable var model = Model()
      weakModel = model
      let textField = UITextField(text: $model.text)
      observe {
        _ = textField
      }
    }
    XCTAssertNil(weakModel)
  }

  @MainActor
  func testPresentation() async throws {
    class VC: UIViewController {
      @UIBindable var model = Model()
      override func viewDidLoad() {
        super.viewDidLoad()
        present(isPresented: $model.isPresented) {
          UIViewController()
        }
      }
    }

    let window = UIWindow()
    let vc = VC()
    window.rootViewController = vc
    _ = vc.view
    XCTAssertEqual(vc.children.count, 0)
    vc.model.isPresented = true
    try await Task.sleep(for: .seconds(1))
    XCTAssertEqual(vc.children.count, 1)
    XCTAssertNotNil(vc.presentedViewController)
  }
}

@Perceptible
fileprivate final class Model: Identifiable {
  var isPresented = false
  var child: Model? = nil
  var text = ""
}
