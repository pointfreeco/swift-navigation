import SwiftUI
import SwiftUINavigation

struct RootView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("SwiftUI") {
                    SwiftUICaseStudiesView()
                }
                #if canImport(UIKit) && !os(watchOS)
                NavigationLink("UIKit") {
                    UIKitCaseStudiesView()
                }
                #endif
                #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                NavigationLink("AppKit") {
                    AppKitCaseStudiesView()
                }
                #endif
            }
            .navigationTitle("Case studies")
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
