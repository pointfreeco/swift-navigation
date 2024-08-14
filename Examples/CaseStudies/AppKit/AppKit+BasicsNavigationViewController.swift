#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import SwiftUI
import AppKit
import AppKitNavigation

class BasicsNavigationViewController: XiblessViewController<NSView>, AppKitCaseStudy {
    let caseStudyTitle = "Basics"
    let readMe = """
    This case study demonstrates how to perform every major form of navigation in UIKit (alerts, \
    sheets, drill-downs) by driving navigation off of optional and boolean state.
    """
    @UIBindable var model = Model()

    override func viewDidLoad() {
        super.viewDidLoad()

        let showAlertButton = NSButton { [weak self] _ in
            self?.model.alert = "Hello!"
        }
        
        let showSheetButton = NSButton { [weak self] _ in
            self?.model.sheet = .random(in: 1 ... 1_000)
        }

        let showSheetFromBooleanButton = NSButton { [weak self] _ in
            self?.model.isSheetPresented = true
        }

        let stack = NSStackView(views: [
            showAlertButton,
            showSheetButton,
            showSheetFromBooleanButton,
        ])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        observe { [weak self] in
            guard let self else { return }

            showAlertButton.title = "Alert is presented: \(model.alert != nil ? "✅" : "❌")"
            showSheetButton.title = "Sheet is presented: \(model.sheet != nil ? "✅" : "❌")"
            showSheetFromBooleanButton.title = "Sheet is presented from boolean: \(model.isSheetPresented ? "✅" : "❌")"
            
        }

//        present(item: $model.alert, id: \.self) { message in
//            let alert = UIAlertController(
//                title: "This is an alert",
//                message: message,
//                preferredStyle: .alert
//            )
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//            return alert
//        }
        sheet(item: $model.sheet, id: \.self) { count in
            NSAlert(error: CocoaError.error(.coderInvalidValue))
        }
//        present(item: $model.sheet, id: \.self, style: .sheet) { count in
////            let vc = NSHostingController(
////                rootView: Form { Text(count.description) }
////            )
//            let vc = XiblessViewController<NSBox>()
//            vc.preferredContentSize = .init(width: 300, height: 200)
//            return vc
//        }
        present(isPresented: $model.isSheetPresented, style: .sheet) {
            let vc = NSHostingController(
                rootView: Form { Text("Hello!") }
            )
            return vc
        }
    }

    @Observable
    class Model {
        var alert: String?
        var isSheetPresented = false
        var sheet: Int?
    }
}

#Preview {
    BasicsNavigationViewController()
}
#endif
