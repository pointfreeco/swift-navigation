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
          guard
            let self,
            let model
          else { return }

          self.standupsList.standups.remove(id: model.standup.id)
          _ = self.path.popLast()
        }
        model.onStartMeeting = { [weak self, weak model] in
          guard
            let self,
            let model
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
    AppView(
      model: AppModel(standupsList: StandupsListModel())
    )
  }
}
