import SwiftUI
import SwiftUINavigation

private let readMe = """
  This case study demonstrates how to enhance an existing SwiftUI component so that it can be \
  driven off of optional and enum state.

  The BottomMenuModifier component in this is file is primarily powered by a simple boolean \
  binding, which means its content cannot be dynamic based off of the source of truth that drives \
  its presentation, and it cannot make mutations to the source of truth.

  However, by leveraging the binding transformations that come with this library we can extend the \
  bottom menu component with additional APIs that allow presentation and dismissal to be powered \
  by optionals and enums.
  """

struct CustomComponents: View {
  @State var count: Int?

  var body: some View {
    Form {
      Section {
        Text(readMe)
      }

      Button("Show bottom menu") {
        withAnimation {
          self.count = 0
        }
      }

      if let count = self.count, count > 0 {
        Text("Current count: \(count)")
          .transition(.opacity)
      }
    }
    .bottomMenu(unwrapping: self.$count) { $count in
      Stepper("Number: \(count)", value: $count.animation())
    }
    .navigationTitle("Custom components")
  }
}

private struct BottomMenuModifier<BottomMenuContent>: ViewModifier
where BottomMenuContent: View {
  @Binding var isActive: Bool
  let content: () -> BottomMenuContent

  func body(content: Content) -> some View {
    content.overlay(
      ZStack(alignment: .bottom) {
        if self.isActive {
          Rectangle()
            .fill(Color.black.opacity(0.4))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
              withAnimation {
                self.isActive = false
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
    self.modifier(
      BottomMenuModifier(
        isActive: isActive,
        content: content
      )
    )
  }

  fileprivate func bottomMenu<Value, Content>(
    unwrapping value: Binding<Value?>,
    @ViewBuilder content: @escaping (Binding<Value>) -> Content
  ) -> some View
  where Content: View {
    self.modifier(
      BottomMenuModifier(
        isActive: value.isPresent(),
        content: { Binding(unwrapping: value).map(content) }
      )
    )
  }

  fileprivate func bottomMenu<Enum, Case, Content>(
    unwrapping value: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    @ViewBuilder content: @escaping (Binding<Case>) -> Content
  ) -> some View
  where Content: View {
    self.bottomMenu(
      unwrapping: value.case(casePath),
      content: content
    )
  }
}

#Preview {
  CustomComponents()
}
