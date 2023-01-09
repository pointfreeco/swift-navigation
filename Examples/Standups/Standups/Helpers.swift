import SwiftUI

// NB: This is only used for previews.
struct Preview<Content: View>: View {
  let content: Content
  let message: String
  init(
    message: String,
    @ViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.message = message
  }

  var body: some View {
    VStack {
      DisclosureGroup {
        Text(self.message)
          .frame(maxWidth: .infinity)
      } label: {
        HStack {
          Image(systemName: "info.circle.fill")
            .font(.title3)
          Text("About this preview")
        }
      }
      .padding()

      self.content
    }
  }
}

struct Preview_Previews: PreviewProvider {
  static var previews: some View {
    Preview(
      message:
        """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt \
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation \
        ullamco laboris nisi ut aliquip ex ea commodo consequat.
        """
    ) {
      StandupDetailView(model: StandupDetailModel(standup: .mock))
    }
  }
}
