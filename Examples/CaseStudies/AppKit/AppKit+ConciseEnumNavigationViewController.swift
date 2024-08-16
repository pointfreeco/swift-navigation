#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import SwiftUI
import AppKit
import AppKitNavigation

class ConciseEnumNavigationViewController: XiblessViewController<NSView>, AppKitCaseStudy {
    let caseStudyNavigationTitle = "Enum navigation"
    let caseStudyTitle = "Concise enum navigation"
    let readMe = """
    This case study demonstrates how to navigate to multiple destinations from a single optional \
    enum.

    This allows you to be very concise with your domain modeling by having a single enum \
    describe all the possible destinations you can navigate to. In the case of this demo, we have \
    four cases in the enum, which means there are exactly 5 possible states, including the case \
    where none are active.

    If you were to instead model this domain with 4 optionals (or booleans), then you would have \
    16 possible states, of which only 5 are valid. That can leak complexity into your domain \
    because you can never be sure of exactly what is presented at a given time.
    """
    @UIBindable var model = Model()

    override func viewDidLoad() {
        super.viewDidLoad()

        let showAlertButton = NSButton { [weak self] _ in
            self?.model.destination = .alert("Hello!")
        }
        let showSheetButton = NSButton { [weak self] _ in
            self?.model.destination = .sheet(.random(in: 1 ... 1_000))
        }
        let showSheetFromBooleanButton = NSButton { [weak self] _ in
            self?.model.destination = .sheetWithoutPayload
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

            showAlertButton.title = "Alert is presented: \(model.destination?.alert != nil ? "✅" : "❌")"
            showSheetButton.title = "Sheet is presented: \(model.destination?.sheet != nil ? "✅" : "❌")"
            showSheetFromBooleanButton.title = "Sheet is presented from boolean: \(model.destination?.sheetWithoutPayload != nil ? "✅" : "❌")"
        }

        modal(item: $model.destination.alert, id: \.self) { message in
            let alert = NSAlert()
            alert.messageText = "This is an alert"
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            return alert
        }
        present(item: $model.destination.sheet, id: \.self, style: .sheet) { [unowned self] count in
            
            NSHostingController(
                rootView: Form {
                    Text(count.description)
                    Button("Close") {
                        self.model.destination = nil
                    }
                }.frame(width: 200, height: 200, alignment: .center)
            )
        }
        present(isPresented: UIBinding($model.destination.sheetWithoutPayload), style: .sheet) { [unowned self] in
            NSHostingController(
                rootView: Form {
                    Text("Hello!")
                    Button("Close") {
                        self.model.destination = nil
                    }
                }.frame(width: 200, height: 200, alignment: .center)
            )
        }
    }

    @Observable
    class Model {
        var destination: Destination?
        @CasePathable
        @dynamicMemberLookup
        enum Destination {
            case alert(String)
            case drillDown(Int)
            case sheet(Int)
            case sheetWithoutPayload
        }
    }
}

#Preview {
    ConciseEnumNavigationViewController()
}
#endif
