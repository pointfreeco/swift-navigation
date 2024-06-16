import SwiftUI
import SwiftUINavigation

struct CustomComponents: SwiftUICaseStudy {
  let caseStudyTitle = "Custom components"
  let readMe = """
    This case study demonstrates how to enhance an existing SwiftUI component so that it can be \
    driven off of enum state.

    By marking your enum with @CasePathable you can deriving bindings of each case of the enum \
    in order to hand off to SwiftUI components that take bindings of optionals.
    """
  let usesOwnLayout = true
  @State var bottom: Bottom?

  @CasePathable
  @dynamicMemberLookup
  enum Bottom {
    case count(Int)
    case text(String)
  }

  var body: some View {
    Form {
      Section {
        DisclosureGroup("About this case study") {
          Text(readMe)
        }
      }

      Button("Show bottom menu: count") {
        withAnimation { bottom = .count(0) }
      }
      Button("Show bottom menu: text") {
        withAnimation { bottom = .text("") }
      }

      if let count = bottom?.count, count > 0 {
        Text("Current count: \(count)")
          .transition(.opacity)
      }
      if let text = bottom?.text, !text.isEmpty {
        Text("Current text: \(text)")
          .transition(.opacity)
      }
    }
    .bottomMenu(item: $bottom.count) { $count in
      Stepper("Number: \(count)", value: $count)
    }
    .bottomMenu(item: $bottom.text) { $text in
      TextField("Type into this field", text: $text)
    }
  }
}

private struct BottomMenuModifier<BottomMenuContent>: ViewModifier
where BottomMenuContent: View {
  @Binding var isActive: Bool
  let content: () -> BottomMenuContent

  func body(content: Content) -> some View {
    content.overlay(
      ZStack(alignment: .bottom) {
        if isActive {
          Rectangle()
            .fill(Color.black.opacity(0.4))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
              withAnimation {
                isActive = false
              }
            }
            .zIndex(1)
            .transition(.opacity)

          self.content()
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
            .padding(24)
            .padding(.bottom)
            .zIndex(2)
            .transition(.move(edge: .bottom))
        }
      }
      .ignoresSafeArea()
    )
  }
}

extension View {
  fileprivate func bottomMenu<Content>(
    isActive: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View
  where Content: View {
    modifier(
      BottomMenuModifier(
        isActive: isActive,
        content: content
      )
    )
  }

  fileprivate func bottomMenu<Item, Content>(
    item: Binding<Item?>,
    @ViewBuilder content: @escaping (Binding<Item>) -> Content
  ) -> some View
  where Content: View {
    modifier(
      BottomMenuModifier(
        isActive: Binding(item),
        content: { Binding(unwrapping: item).map(content) }
      )
    )
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      CustomComponents()
    }
  }
}
