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
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self?.model.sheet = nil
            }
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

            if let url = model.url {
                showAlertButton.title = "URL is: \(url)"
            } else {
                showAlertButton.title = "Alert is presented: \(model.alert != nil ? "✅" : "❌")"
            }
            showSheetButton.title = "Sheet is presented: \(model.sheet != nil ? "✅" : "❌")"
            showSheetFromBooleanButton.title = "Sheet is presented from boolean: \(model.isSheetPresented ? "✅" : "❌")"
        }

        modal(item: $model.alert, id: \.self) { [unowned self] message in
//            let alert = NSAlert()
//            alert.messageText = "This is an alert"
//            alert.informativeText = message
//            alert.addButton(withTitle: "OK")
//            return alert
            let openPanel = NSOpenPanel(url: $model.url)
            openPanel.message = message
            return openPanel
        }

        present(item: $model.sheet, id: \.self, style: .sheet) { count in
            NSHostingController(
                rootView: Form { Text(count.description) }.frame(width: 100, height: 100, alignment: .center)
            )
        }
        
        present(isPresented: $model.isSheetPresented, style: .sheet) {
            NSHostingController(
                rootView: Form { Text("Hello!") }.frame(width: 100, height: 100, alignment: .center)
            )
        }
    }

    @Observable
    class Model {
        var alert: String?
        var isSheetPresented = false
        var sheet: Int?
        var url: URL?
    }
}

#Preview {
    BasicsNavigationViewController()
}
#endif
