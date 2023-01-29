import Combine
import Dependencies
import SwiftUI

class AppModel: ObservableObject {
  @Published var path: [Destination] {
    didSet { self.bind() }
  }
  @Published var standupsList: StandupsListModel

  @Dependency(\.continuousClock) var clock
  @Dependency(\.date.now) var now
  @Dependency(\.uuid) var uuid

  private var detailCancellable: AnyCancellable?

  init(
    path: [Destination] = [],
    standupsList: StandupsListModel
  ) {
    self.path = path
    self.standupsList = standupsList
    self.bind()
  }

  enum Destination: Hashable {
    case detail(StandupDetailModel)
    case meeting(Meeting, standup: Standup)
    case record(RecordMeetingModel)
  }

  private func bind() {
    for destination in self.path {
      switch destination {
      case let .detail(model):
        model.onConfirmDeletion = { [weak self, weak model] in
          guard let self, let model
          else { return }

          self.standupsList.standups.remove(id: model.standup.id)
          _ = self.path.popLast()
        }
        model.onStartMeeting = { [weak self, weak model] in
          guard let self, let model
          else { return }

          self.path.append(
            .record(
              withDependencies(from: model) {
                RecordMeetingModel(standup: model.standup)
              }
            )
          )
        }
        self.detailCancellable = model.$standup
          .sink { [weak self] standup in
            self?.standupsList.standups[id: standup.id] = standup
          }

      case .meeting:
        break

      case let .record(model):
        model.onDiscardMeeting = { [weak self] in
          _ = self?.path.popLast()
        }
        model.onMeetingFinished = { @MainActor [weak self] transcript in
          guard
            let self,
            case .some(.record) = self.path.popLast(),
            case let .some(.detail(detailModel)) = self.path.last
          else { return }

          let didCancel = nil == (try? await self.clock.sleep(for: .milliseconds(400)))
          withAnimation(didCancel ? nil : .default) {
            _ = detailModel.standup.meetings.insert(
              Meeting(
                id: Meeting.ID(self.uuid()),
                date: self.now,
                transcript: transcript
              ),
              at: 0
            )
          }
        }
      }
    }
  }
}

struct AppView: View {
  @ObservedObject var model: AppModel

  var body: some View {
    NavigationStack(path: self.$model.path) {
      StandupsList(model: self.model.standupsList)
        .navigationDestination(for: AppModel.Destination.self) { path in
          switch path {
          case let .detail(model):
            StandupDetailView(model: model)
          case let .meeting(meeting, standup: standup):
            MeetingView(meeting: meeting, standup: standup)
          case let .record(model):
            RecordMeetingView(model: model)
          }
        }
    }
  }
}

struct App_Previews: PreviewProvider {
  static var previews: some View {
    withDependencies {
      $0.dataManager = .mock(
        initialData: try! JSONEncoder().encode([
          Standup.mock,
          .engineeringMock,
          .designMock,
        ])
      )
    } operation: {
      AppView(model: AppModel(standupsList: StandupsListModel()))
    }

    Preview(
      message: """
        The preview demonstrates how you can start the application navigated to a very specific \
        screen just by constructing a piece of state. In particular we will start the app drilled \
        down to the detail screen of a standup, and then further drilled down to the record screen \
        for a new meeting.
        """
    ) {
      withDependencies {
        $0.dataManager = .mock(
          initialData: try! JSONEncoder().encode([
            Standup.mock,
            .engineeringMock,
            .designMock,
          ])
        )
      } operation: {
        AppView(
          model: AppModel(
            path: [
              .detail(StandupDetailModel(standup: .mock)),
              .record(RecordMeetingModel(standup: .mock)),
            ],
            standupsList: StandupsListModel()
          )
        )
      }
    }
    .previewDisplayName("Deep link record flow")

    Preview(
      message: """
        The preview demonstrates how you can start the application navigated to a very specific \
        screen just by constructing a piece of state. In particular we will start the app with the \
        "Add standup" screen opened and with the last attendee text field focused.
        """
    ) {
      var standup = Standup.mock
      let lastAttendee = Attendee(id: Attendee.ID())
      let _ = standup.attendees.append(lastAttendee)

      withDependencies {
        $0.dataManager = .mock()
      } operation: {
        AppView(
          model: AppModel(
            standupsList: StandupsListModel(
              destination: .add(
                StandupFormModel(
                  focus: .attendee(lastAttendee.id),
                  standup: standup
                )
              )
            )
          )
        )
      }
    }
    .previewDisplayName("Deep link add flow")

    Preview(
      message: """
        This preview demonstrates an "unhappy path" of the application where the speech \
        recognizer mysteriously fails after 2 seconds of recording. This gives us an opportunity \
        to see how the application deals with this rare occurence. To see the behavior, run the \
        preview, tap the "Start Meeting" button and wait 2 seconds.
        """
    ) {
      withDependencies {
        $0.dataManager = .mock(initialData: try! JSONEncoder().encode([Standup.mock]))
        $0.speechClient = .fail(after: .seconds(2))
      } operation: {
        AppView(
          model: AppModel(
            path: [
              .detail(StandupDetailModel(standup: .mock)),
              .record(RecordMeetingModel(standup: .mock)),
            ],
            standupsList: StandupsListModel()
          )
        )
      }
    }
    .previewDisplayName("Speech recognition failed")
  }
}
