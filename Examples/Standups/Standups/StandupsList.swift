import Combine
import Dependencies
import IdentifiedCollections
import SwiftUI
import SwiftUINavigation

@MainActor
final class StandupsListModel: ObservableObject {
  @Published var destination: Destination? {
    didSet { self.bind() }
  }
  @Published var standups: IdentifiedArrayOf<Standup>

  private var destinationCancellable: AnyCancellable?
  private var cancellables: Set<AnyCancellable> = []

  @Dependency(\.dataManager) var dataManager
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.uuid) var uuid

  enum Destination {
    case add(StandupFormModel)
    case alert(AlertState<AlertAction>)
    case detail(StandupDetailModel)
  }
  enum AlertAction {
    case confirmLoadMockData
  }

  init(
    destination: Destination? = nil
  ) {
    defer { self.bind() }
    self.destination = destination
    self.standups = []

    do {
      self.standups = try JSONDecoder().decode(
        IdentifiedArray.self,
        from: self.dataManager.load(.standups)
      )
    } catch is DecodingError {
      self.destination = .alert(.dataFailedToLoad)
    } catch {
    }

    self.$standups
      .dropFirst()
      .debounce(for: .seconds(1), scheduler: self.mainQueue)
      .sink { [weak self] standups in
        try? self?.dataManager.save(JSONEncoder().encode(standups), .standups)
      }
      .store(in: &self.cancellables)
  }

  func addStandupButtonTapped() {
    self.destination = .add(
      withDependencies(from: self) {
        StandupFormModel(standup: Standup(id: Standup.ID(self.uuid())))
      }
    )
  }

  func dismissAddStandupButtonTapped() {
    self.destination = nil
  }

  func confirmAddStandupButtonTapped() {
    defer { self.destination = nil }

    guard case let .add(standupFormModel) = self.destination
    else { return }
    var standup = standupFormModel.standup

    standup.attendees.removeAll { attendee in
      attendee.name.allSatisfy(\.isWhitespace)
    }
    if standup.attendees.isEmpty {
      standup.attendees.append(Attendee(id: Attendee.ID(self.uuid())))
    }
    self.standups.append(standup)
  }

  func standupTapped(standup: Standup) {
    self.destination = .detail(
      withDependencies(from: self) {
        StandupDetailModel(standup: standup)
      }
    )
  }

  private func bind() {
    switch self.destination {
    case let .detail(standupDetailModel):
      standupDetailModel.onConfirmDeletion = { [weak self, id = standupDetailModel.standup.id] in
        withAnimation {
          self?.standups.remove(id: id)
          self?.destination = nil
        }
      }

      self.destinationCancellable = standupDetailModel.$standup
        .sink { [weak self] standup in
          self?.standups[id: standup.id] = standup
        }

    case .add, .alert, .none:
      break
    }
  }

  func alertButtonTapped(_ action: AlertAction?) {
    switch action {
    case .confirmLoadMockData?:
      withAnimation {
        self.standups = [
          .mock,
          .designMock,
          .engineeringMock,
        ]
      }
    case nil:
      break
    }
  }
}

extension AlertState where Action == StandupsListModel.AlertAction {
  static let dataFailedToLoad = Self {
    TextState("Data failed to load")
  } actions: {
    ButtonState(action: .confirmLoadMockData) {
      TextState("Yes")
    }
    ButtonState(role: .cancel) {
      TextState("No")
    }
  } message: {
    TextState(
      """
      Unfortunately your past data failed to load. Would you like to load some mock data to play \
      around with?
      """)
  }
}

struct StandupsList: View {
  @ObservedObject var model: StandupsListModel

  var body: some View {
    NavigationStack {
      List {
        ForEach(self.model.standups) { standup in
          Button {
            self.model.standupTapped(standup: standup)
          } label: {
            CardView(standup: standup)
          }
          .listRowBackground(standup.theme.mainColor)
        }
      }
      .toolbar {
        Button {
          self.model.addStandupButtonTapped()
        } label: {
          Image(systemName: "plus")
        }
      }
      .navigationTitle("Daily Standups")
      .sheet(
        unwrapping: self.$model.destination,
        case: /StandupsListModel.Destination.add
      ) { $model in
        NavigationStack {
          StandupFormView(model: model)
            .navigationTitle("New standup")
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Dismiss") {
                  self.model.dismissAddStandupButtonTapped()
                }
              }
              ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                  self.model.confirmAddStandupButtonTapped()
                }
              }
            }
        }
      }
      .navigationDestination(
        unwrapping: self.$model.destination,
        case: /StandupsListModel.Destination.detail
      ) { $detailModel in
        StandupDetailView(model: detailModel)
      }
      .alert(
        unwrapping: self.$model.destination,
        case: /StandupsListModel.Destination.alert
      ) {
        self.model.alertButtonTapped($0)
      }
    }
  }
}

struct CardView: View {
  let standup: Standup

  var body: some View {
    VStack(alignment: .leading) {
      Text(self.standup.title)
        .font(.headline)
      Spacer()
      HStack {
        Label("\(self.standup.attendees.count)", systemImage: "person.3")
        Spacer()
        Label(self.standup.duration.formatted(.units()), systemImage: "clock")
          .labelStyle(.trailingIcon)
      }
      .font(.caption)
    }
    .padding()
    .foregroundColor(self.standup.theme.accentColor)
  }
}

struct TrailingIconLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.title
      configuration.icon
    }
  }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
  static var trailingIcon: Self { Self() }
}

extension URL {
  fileprivate static let standups = Self.documentsDirectory.appending(component: "standups.json")
}

struct StandupsList_Previews: PreviewProvider {
  static var previews: some View {
    Preview(
      message: """
        This preview demonstrates how to start the app in a state with a few standups \
        pre-populated. Since the initial standups are loaded from disk we cannot simply pass some \
        data to the StandupsList model. But, we can override the DataManager dependency so that \
        when its load endpoint is called it will load whatever data we want.
        """
    ) {
      StandupsList(
        model: withDependencies {
          $0.dataManager = .mock(
            initialData: try! JSONEncoder().encode([
              Standup.mock,
              .engineeringMock,
              .designMock,
            ])
          )
        } operation: {
          StandupsListModel()
        }
      )
    }
    .previewDisplayName("Mocking initial standups")

    Preview(
      message: """
        This preview demonstrates how to test the flow of loading bad data from disk, in which \
        case an alert should be shown. This can be done by overridding the DataManager dependency \
        so that its initial data does not properly decode into a collection of standups.
        """
    ) {
      StandupsList(
        model: withDependencies {
          $0.dataManager = .mock(
            initialData: Data("!@#$% bad data ^&*()".utf8)
          )
        } operation: {
          StandupsListModel()
        }
      )
    }
    .previewDisplayName("Load data failure")

    Preview(
      message: """
        The preview demonstrates how you can start the application navigated to a very specific \
        screen just by constructing a piece of state. In particular we will start the app drilled \
        down to the detail screen of a standup, and then further drilled down to the record screen \
        for a new meeting.
        """
    ) {
      StandupsList(
        model: withDependencies {
          $0.dataManager = .mock(
            initialData: try! JSONEncoder().encode([
              Standup.mock,
              .engineeringMock,
              .designMock,
            ])
          )
        } operation: {
          StandupsListModel(
            destination: .detail(
              StandupDetailModel(
                destination: .record(
                  RecordMeetingModel(standup: .mock)
                ),
                standup: .mock
              )
            )
          )
        }
      )
    }
    .previewDisplayName("Deep link record flow")

    Preview(
      message: """
        The preview demonstrates how you can start the application navigated to a very specific \
        screen just by constructing a piece of state. In particular we will start the app with the \
        "Add standup" screen opened and with the last attendee text field focused.
        """
    ) {
      StandupsList(
        model: withDependencies {
          $0.dataManager = .mock()
        } operation: {
          var standup = Standup.mock
          let lastAttendee = Attendee(id: Attendee.ID())
          let _ = standup.attendees.append(lastAttendee)
          return StandupsListModel(
            destination: .add(
              StandupFormModel(
                focus: .attendee(lastAttendee.id),
                standup: standup
              )
            )
          )
        }
      )
    }
    .previewDisplayName("Deep link add flow")
  }
}
