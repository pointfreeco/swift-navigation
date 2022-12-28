import Clocks
import CustomDump
import Dependencies
import SwiftUI
import SwiftUINavigation
import XCTestDynamicOverlay

@MainActor
class StandupDetailModel: ObservableObject {
  @Published var destination: Destination? {
    didSet {
      self.bind()
    }
  }
  @Published var dismiss = false
  @Published var standup: Standup

  @Dependency(\.continuousClock) var clock
  @Dependency(\.date.now) var now
  @Dependency(\.openSettings) var openSettings
  @Dependency(\.speechClient.authorizationStatus) var authorizationStatus
  @Dependency(\.uuid) var uuid

  var onConfirmDeletion: () -> Bool = unimplemented("StandupDetailModel.onConfirmDeletion")

  enum Destination {
    case alert(AlertState<AlertAction>)
    case edit(EditStandupModel)
    case meeting(Meeting)
    case record(RecordMeetingModel)
  }
  enum AlertAction {
    case confirmDeletion
    case continueWithoutRecording
    case openSettings
  }

  init(
    destination: Destination? = nil,
    standup: Standup
  ) {
    self.destination = destination
    self.standup = standup
    self.bind()
  }

  func deleteMeetings(atOffsets indices: IndexSet) {
    self.standup.meetings.remove(atOffsets: indices)
  }

  func meetingTapping(_ meeting: Meeting) {
    self.destination = .meeting(meeting)
  }

  func deleteButtonTapped() {
    self.destination = .alert(.deleteStandup)
  }

  func alertButtonTapped(_ action: AlertAction) async {
    switch action {
    case .confirmDeletion:
      self.dismiss = self.onConfirmDeletion()

    case .continueWithoutRecording:
      // TODO: NB: SwiftUI does not support performing navigation immediately after clearing out
      //     alert state, so we have to wait a small amount of time for the alert to dismiss.
      try? await self.clock.sleep(for: .milliseconds(100))
      self.destination = .record(
        DependencyValues.withValues(from: self) {
          RecordMeetingModel(standup: self.standup)
        }
      )

    case .openSettings:
      await self.openSettings()
    }
  }

  func editButtonTapped() {
    self.destination = .edit(
      DependencyValues.withValues(from: self) {
        EditStandupModel(standup: self.standup)
      }
    )
  }

  func cancelEditButtonTapped() {
    self.destination = nil
  }

  func doneEditingButtonTapped() {
    guard case let .edit(model) = self.destination
    else { return }

    self.standup = model.standup
    self.destination = nil
  }

  private let speechAlertSeenKey = "speechAlertSeenKey"

  func startMeetingButtonTapped() {
    switch self.authorizationStatus() {
    case .notDetermined, .authorized:
      self.destination = .record(
        DependencyValues.withValues(from: self) {
          RecordMeetingModel(standup: self.standup)
        }
      )

    case .denied:
      self.destination = .alert(.speechRecognitionDenied)

    case .restricted:
      self.destination = .alert(.speechRecognitionRestricted)

    @unknown default:
      break
    }
  }

  private func bind() {
    switch destination {
    case let .record(recordMeetingModel):
      recordMeetingModel.onMeetingFinished = { [weak self] transcript async in
        guard let self else { return }

        let didCancel = nil == (try? await self.clock.sleep(for: .milliseconds(400)))
        withAnimation(didCancel ? nil : .default) {
          _ = self.standup.meetings.insert(
            Meeting(
              id: Meeting.ID(self.uuid()),
              date: self.now,
              transcript: transcript
            ),
            at: 0
          )
        }
        self.destination = nil
      }

    case .edit, .meeting, .alert, .none:
      break
    }
  }
}

struct StandupDetailView: View {
  @Environment(\.dismiss) var dismiss
  @ObservedObject var model: StandupDetailModel

  var body: some View {
    List {
      Section {
        Button {
          self.model.startMeetingButtonTapped()
        } label: {
          Label("Start Meeting", systemImage: "timer")
            .font(.headline)
            .foregroundColor(.accentColor)
        }
        HStack {
          Label("Length", systemImage: "clock")
          Spacer()
          Text(self.model.standup.duration.formatted(.units()))
        }

        HStack {
          Label("Theme", systemImage: "paintpalette")
          Spacer()
          Text(self.model.standup.theme.name)
            .padding(4)
            .foregroundColor(self.model.standup.theme.accentColor)
            .background(self.model.standup.theme.mainColor)
            .cornerRadius(4)
        }
      } header: {
        Text("Standup Info")
      }

      if !self.model.standup.meetings.isEmpty {
        Section {
          ForEach(self.model.standup.meetings) { meeting in
            Button {
              self.model.meetingTapping(meeting)
            } label: {
              HStack {
                Image(systemName: "calendar")
                Text(meeting.date, style: .date)
                Text(meeting.date, style: .time)
              }
            }
          }
          .onDelete { indices in
            self.model.deleteMeetings(atOffsets: indices)
          }
        } header: {
          Text("Past meetings")
        }
      }

      Section {
        ForEach(self.model.standup.attendees) { attendee in
          Label(attendee.name, systemImage: "person")
        }
      } header: {
        Text("Attendees")
      }

      Section {
        Button("Delete") {
          self.model.deleteButtonTapped()
        }
        .foregroundColor(.red)
        .frame(maxWidth: .infinity)
      }
    }
    .navigationTitle(self.model.standup.title)
    .toolbar {
      Button("Edit") {
        self.model.editButtonTapped()
      }
    }
    .navigationDestination(
      unwrapping: self.$model.destination,
      case: /StandupDetailModel.Destination.meeting
    ) { $meeting in
      MeetingView(meeting: meeting, standup: self.model.standup)
    }
    .navigationDestination(
      unwrapping: self.$model.destination,
      case: /StandupDetailModel.Destination.record
    ) { $model in
      RecordMeetingView(model: model)
    }
    .alert(
      unwrapping: self.$model.destination,
      case: /StandupDetailModel.Destination.alert
    ) { action in
      await self.model.alertButtonTapped(action)
    }
    .sheet(
      unwrapping: self.$model.destination,
      case: /StandupDetailModel.Destination.edit
    ) { $editModel in
      NavigationStack {
        EditStandupView(model: editModel)
          .navigationTitle(self.model.standup.title)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                self.model.cancelEditButtonTapped()
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") {
                self.model.doneEditingButtonTapped()
              }
            }
          }
      }
    }
    .onChange(of: self.model.dismiss) { _ in
      self.dismiss()
    }
  }
}

extension AlertState where Action == StandupDetailModel.AlertAction {
  static let deleteStandup = Self {
    TextState("Delete?")
  } actions: {
    ButtonState(role: .destructive, action: .confirmDeletion) {
      TextState("Yes")
    }
    ButtonState(role: .cancel) {
      TextState("Nevermind")
    }
  } message: {
    TextState("Are you sure you want to delete this meeting?")
  }

  static let speechRecognitionDenied = Self {
    TextState("Speech recognition denied")
  } actions: {
    ButtonState(action: .openSettings) {
      TextState("Open settings")
    }
    ButtonState(action: .continueWithoutRecording) {
      TextState("Continue without recording")
    }
  } message: {
    TextState("""
      You previously denied speech recognition and so your meeting meeting will not be
      recorded. You can enable speech recognition in settings, or you can continue without
      recording.
      """)
  }

  static let speechRecognitionRestricted = Self {
    TextState("Speech recognition restricted")
  } actions: {
    ButtonState(action: .continueWithoutRecording) {
      TextState("Continue without recording")
    }
  } message: {
    TextState("""
      Your device does not support speech recognition and so your meeting will not be recorded.
      """)
  }
}

struct MeetingView: View {
  let meeting: Meeting
  let standup: Standup

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Divider()
          .padding(.bottom)
        Text("Attendees")
          .font(.headline)
        ForEach(self.standup.attendees) { attendee in
          Text(attendee.name)
        }
        Text("Transcript")
          .font(.headline)
          .padding(.top)
        Text(self.meeting.transcript)
      }
    }
    .navigationTitle(Text(self.meeting.date, style: .date))
    .padding()
  }
}

struct StandupDetail_Previews: PreviewProvider {
  static var previews: some View {
    var standup = Standup.mock
    let _ = standup.duration = .seconds(60)
    let _ = standup.attendees = [
      Attendee(id: Attendee.ID(UUID()), name: "Blob")
    ]
    NavigationStack {
      StandupDetailView(
        model: DependencyValues.withValues {
          $0.speechClient.authorizationStatus = { .restricted }
        } operation: {
          StandupDetailModel(
            standup: standup
          )
        }
      )
    }
  }
}
