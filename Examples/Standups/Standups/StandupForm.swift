import Dependencies
import SwiftUI
import SwiftUINavigation

class StandupFormModel: ObservableObject {
  @Published var focus: Field?
  @Published var standup: Standup

  @Dependency(\.uuid) var uuid

  enum Field: Hashable {
    case attendee(Attendee.ID)
    case title
  }

  init(
    focus: Field? = .title,
    standup: Standup
  ) {
    self.focus = focus
    self.standup = standup
    if self.standup.attendees.isEmpty {
      self.standup.attendees.append(Attendee(id: Attendee.ID(self.uuid())))
    }
  }

  func deleteAttendees(atOffsets indices: IndexSet) {
    self.standup.attendees.remove(atOffsets: indices)
    if self.standup.attendees.isEmpty {
      self.standup.attendees.append(Attendee(id: Attendee.ID(self.uuid())))
    }
    guard let firstIndex = indices.first
    else { return }
    let index = min(firstIndex, self.standup.attendees.count - 1)
    self.focus = .attendee(self.standup.attendees[index].id)
  }

  func addAttendeeButtonTapped() {
    let attendee = Attendee(id: Attendee.ID(self.uuid()))
    self.standup.attendees.append(attendee)
    self.focus = .attendee(attendee.id)
  }
}

struct StandupFormView: View {
  @FocusState var focus: StandupFormModel.Field?
  @ObservedObject var model: StandupFormModel

  var body: some View {
    Form {
      Section {
        TextField("Title", text: self.$model.standup.title)
          .focused(self.$focus, equals: .title)
        HStack {
          Slider(value: self.$model.standup.duration.seconds, in: 5...30, step: 1) {
            Text("Length")
          }
          Spacer()
          Text(self.model.standup.duration.formatted(.units()))
        }
        ThemePicker(selection: self.$model.standup.theme)
      } header: {
        Text("Standup Info")
      }
      Section {
        ForEach(self.$model.standup.attendees) { $attendee in
          TextField("Name", text: $attendee.name)
            .focused(self.$focus, equals: .attendee(attendee.id))
        }
        .onDelete { indices in
          self.model.deleteAttendees(atOffsets: indices)
        }

        Button("New attendee") {
          self.model.addAttendeeButtonTapped()
        }
      } header: {
        Text("Attendees")
      }
    }
    .bind(self.$model.focus, to: self.$focus)
  }
}

struct ThemePicker: View {
  @Binding var selection: Theme

  var body: some View {
    Picker("Theme", selection: $selection) {
      ForEach(Theme.allCases) { theme in
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .fill(theme.mainColor)
          Label(theme.name, systemImage: "paintpalette")
            .padding(4)
        }
        .foregroundColor(theme.accentColor)
        .fixedSize(horizontal: false, vertical: true)
        .tag(theme)
      }
    }
  }
}

extension Duration {
  fileprivate var seconds: Double {
    get { Double(self.components.seconds / 60) }
    set { self = .seconds(newValue * 60) }
  }
}

struct StandupForm_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      StandupFormView(model: StandupFormModel(standup: .mock))
    }
    .previewDisplayName("Edit")

    Preview(
      message: """
        This preview shows how we can start the screen if a very specific state, where the 4th \
        attendee is already focused.
        """
    ) {
      NavigationStack {
        StandupFormView(
          model: StandupFormModel(
            focus: .attendee(Standup.mock.attendees[3].id),
            standup: .mock
          )
        )
      }
    }
    .previewDisplayName("4th attendee focused")
  }
}
