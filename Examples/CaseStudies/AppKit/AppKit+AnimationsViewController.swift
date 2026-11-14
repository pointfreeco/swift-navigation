#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation
import SwiftUI

class AnimationsViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Animations"
  let readMe = """
  This case study demonstrates how to drive animations from state in an AppKit application. To \
  animate a model mutation, wrap the mutation in 'withAppKitAnimation'. To animate changes to a \
  binding, use the '.animation()' method on 'UIBinding'.

  Click or drag in the gray area to move the circle with a spring, flip the switch to scale it, \
  and cycle through its colors with the button.
  """
  @UIBindable var model = Model()
  private let canvasView = NSView()

  override func viewDidLoad() {
    super.viewDidLoad()

    canvasView.wantsLayer = true
    canvasView.layer?.backgroundColor = NSColor.quaternaryLabelColor.cgColor
    canvasView.layer?.cornerRadius = 8
    canvasView.translatesAutoresizingMaskIntoConstraints = false
    let circleView = NSView()
    circleView.wantsLayer = true
    canvasView.addSubview(circleView)

    let isScaledLabel = NSTextField(labelWithString: "Is scaled?")
    let isScaledSwitch = NSSwitch(isOn: $model.isScaled.animation(Self.springAnimation))
    let scaleRow = NSStackView(views: [isScaledLabel, isScaledSwitch])
    scaleRow.orientation = .horizontal
    scaleRow.spacing = 12
    let cycleColorsButton = makeButton("Cycle colors") { [weak self] in
      guard let self else { return }
      Task { await self.model.cycleColors() }
    }
    let controls = NSStackView(views: [scaleRow, cycleColorsButton])
    controls.orientation = .vertical
    controls.alignment = .centerX
    controls.spacing = 12
    controls.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(controls)
    view.addSubview(canvasView)
    NSLayoutConstraint.activate([
      controls.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
      controls.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      canvasView.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 20),
      canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
      canvasView.heightAnchor.constraint(greaterThanOrEqualToConstant: 360),
    ])

    observe { [unowned self] in
      // NB: 'NSView' has no 'transform' to scale with, so the circle grows by its frame instead.
      let diameter: CGFloat = model.isScaled ? 200 : 100
      circleView.frame = NSRect(
        x: model.position.x - diameter / 2,
        y: model.position.y - diameter / 2,
        width: diameter,
        height: diameter
      )
      circleView.layer?.cornerRadius = diameter / 2
      circleView.layer?.backgroundColor = model.color.cgColor
    }
  }

  override func mouseDown(with event: NSEvent) {
    moveCircle(to: event)
  }

  override func mouseDragged(with event: NSEvent) {
    moveCircle(to: event)
  }

  private func moveCircle(to event: NSEvent) {
    let location = canvasView.convert(event.locationInWindow, from: nil)
    guard canvasView.bounds.contains(location) else { return }
    withAppKitAnimation(Self.springAnimation) {
      model.position = location
    }
  }

  /// A spring where the system has one, which is macOS 15 and later.
  private static var springAnimation: AppKitAnimation {
    if #available(macOS 15, *) {
      AppKitAnimation(.spring(duration: 0.4, bounce: 0.6))
    } else {
      .easeInOut(duration: 0.4)
    }
  }

  @MainActor
  @Observable
  class Model {
    var position = CGPoint(x: 150, y: 180)
    var isScaled = false
    var color = NSColor.black

    func cycleColors() async {
      let colors: [NSColor] = [.systemRed, .systemBlue, .systemTeal, .systemGreen, .systemPink, .systemPurple, .black]
      for color in colors {
        withAppKitAnimation { self.color = color }
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }
}

#Preview {
  AnimationsViewController()
}
#endif
