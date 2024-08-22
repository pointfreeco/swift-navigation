import SwiftUI
import UIKit
import UIKitNavigation

class AnimationsViewController: UIViewController, UIKitCaseStudy {
  let caseStudyTitle = "Animations"
  let readMe = """
    This case study demonstrates how to drive animations from state in a UIKit application. To \
    animate a model mutation you simply wrap the mutation in `withUIKitAnimation`. And to animate \
    changes to a binding, you use the `.animation()` method on `UIBinding`.
    """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    circleView.backgroundColor = .black
    circleView.isUserInteractionEnabled = false
    circleView.layer.cornerRadius = 50
    view.addSubview(circleView)

    let scaleLabel = UILabel()
    scaleLabel.text = "Is scaled?"
    let isScaledSwitch = UISwitch(
      isOn: $model.isScaled.animation(.animate(springDuration: 0.3, bounce: 0.7))
    )
    let scaleStack = UIStackView(arrangedSubviews: [scaleLabel, isScaledSwitch])
    scaleStack.spacing = 12
    scaleStack.axis = .horizontal
    let colorsButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        guard let self else { return }
        Task { await self.model.cycleColors() }
      })
    colorsButton.setTitle("Cycle colors", for: .normal)
    let stack = UIStackView(arrangedSubviews: [
      scaleStack,
      colorsButton,
    ])
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    ])

    observe { [weak self] in
      guard let self else { return }

      var transform = CGAffineTransform(translationX: model.position.x, y: model.position.y)
      if model.isScaled {
        transform = transform.scaledBy(x: 2, y: 2)
      }
      circleView.transform = transform
      circleView.backgroundColor = model.color
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    withUIKitAnimation(.animate(springDuration: 0.4, bounce: 0.75)) {
      model.position = touches.first!
        .location(in: view)
        .applying(CGAffineTransform(translationX: -50, y: -50))
    }
  }

  @MainActor
  @Observable
  class Model {
    var position = CGPoint(x: 100, y: 300)
    var isScaled = false
    var color = UIColor.black
    func cycleColors() async {
      let colors: [UIColor] = [.red, .blue, .cyan, .green, .magenta, .purple, .black]
      for color in colors {
        withUIKitAnimation { self.color = color }
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }
}

#Preview {
  AnimationsViewController()
}
