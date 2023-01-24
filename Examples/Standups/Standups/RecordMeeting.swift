import Clocks
import Dependencies
import Speech
import SwiftUI
import SwiftUINavigation
import XCTestDynamicOverlay

@MainActor
class RecordMeetingModel: ObservableObject {
  @Published var destination: Destination?
  @Published var isDismissed = false
  @Published var secondsElapsed = 0
  @Published var speakerIndex = 0
  let standup: Standup
  private var transcript = ""

  @Dependency(\.continuousClock) var clock
  @Dependency(\.soundEffectClient) var soundEffectClient
  @Dependency(\.speechClient) var speechClient

  var onMeetingFinished: (String) async -> Void = unimplemented(
    "RecordMeetingModel.onMeetingFinished")

  enum Destination {
    case alert(AlertState<AlertAction>)
  }

  enum AlertAction {
    case confirmSave
    case confirmDiscard
  }

  init(
    destination: Destination? = nil,
    standup: Standup
  ) {
    self.destination = destination
    self.standup = standup
  }

  var durationRemaining: Duration {
    self.standup.duration - .seconds(self.secondsElapsed)
  }

  var isAlertOpen: Bool {
    switch destination {
    case .alert:
      return true
    case .none:
      return false
    }
  }

  func nextButtonTapped() {
    guard self.speakerIndex < self.standup.attendees.count - 1
    else {
      self.destination = .alert(.endMeeting(isDiscardable: false))
      return
    }

    self.speakerIndex += 1
    self.soundEffectClient.play()
    self.secondsElapsed =
      self.speakerIndex * Int(self.standup.durationPerAttendee.components.seconds)
  }

  func endMeetingButtonTapped() {
    self.destination = .alert(.endMeeting(isDiscardable: true))
  }

  func alertButtonTapped(_ action: AlertAction?) async {
    switch action {
    case .confirmSave?:
      await self.finishMeeting()
    case .confirmDiscard?:
      self.isDismissed = true
    case nil:
      break
    }
  }

  func task() async {
    self.soundEffectClient.load("ding.wav")

    let authorization =
      await self.speechClient.authorizationStatus() == .notDetermined
      ? self.speechClient.requestAuthorization()
      : self.speechClient.authorizationStatus()

    await withTaskGroup(of: Void.self) { group in
      if authorization == .authorized {
        group.addTask {
          await self.startSpeechRecognition()
        }
      }
      group.addTask {
        await self.startTimer()
      }
    }
  }

  private func finishMeeting() async {
    self.isDismissed = true
    await self.onMeetingFinished(self.transcript)
  }

  private func startSpeechRecognition() async {
    do {
      let speechTask = await self.speechClient.startTask(SFSpeechAudioBufferRecognitionRequest())
      for try await result in speechTask {
        self.transcript = result.bestTranscription.formattedString
      }
    } catch {
      if !self.transcript.isEmpty {
        self.transcript += " ❌"
      }
      self.destination = .alert(.speechRecognizerFailed)
    }
  }

  private func startTimer() async {
    for await _ in self.clock.timer(interval: .seconds(1)) where !self.isAlertOpen {
      guard !self.isDismissed
      else { break }

      self.secondsElapsed += 1

      let secondsPerAttendee = Int(self.standup.durationPerAttendee.components.seconds)
      if self.secondsElapsed.isMultiple(of: secondsPerAttendee) {
        if self.speakerIndex == self.standup.attendees.count - 1 {
          await self.finishMeeting()
          break
        }
        self.speakerIndex += 1
        self.soundEffectClient.play()
      }
    }
  }
}

extension AlertState where Action == RecordMeetingModel.AlertAction {
  static func endMeeting(isDiscardable: Bool) -> Self {
    Self {
      TextState("End meeting?")
    } actions: {
      ButtonState(action: .confirmSave) {
        TextState("Save and end")
      }
      if isDiscardable {
        ButtonState(role: .destructive, action: .confirmDiscard) {
          TextState("Discard")
        }
      }
      ButtonState(role: .cancel) {
        TextState("Resume")
      }
    } message: {
      TextState("You are ending the meeting early. What would you like to do?")
    }
  }

  static let speechRecognizerFailed = Self {
    TextState("Speech recognition failure")
  } actions: {
    ButtonState(role: .cancel) {
      TextState("Continue meeting")
    }
    ButtonState(role: .destructive, action: .confirmDiscard) {
      TextState("Discard meeting")
    }
  } message: {
    TextState(
      """
      The speech recognizer has failed for some reason and so your meeting will no longer be \
      recorded. What do you want to do?
      """)
  }
}

struct RecordMeetingView: View {
  @Environment(\.dismiss) var dismiss
  @ObservedObject var model: RecordMeetingModel

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 16)
        .fill(self.model.standup.theme.mainColor)

      VStack {
        MeetingHeaderView(
          secondsElapsed: self.model.secondsElapsed,
          durationRemaining: self.model.durationRemaining,
          theme: self.model.standup.theme
        )
        MeetingTimerView(
          standup: self.model.standup,
          speakerIndex: self.model.speakerIndex
        )
        MeetingFooterView(
          standup: self.model.standup,
          nextButtonTapped: { self.model.nextButtonTapped() },
          speakerIndex: self.model.speakerIndex
        )
      }
    }
    .padding()
    .foregroundColor(self.model.standup.theme.accentColor)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("End meeting") {
          self.model.endMeetingButtonTapped()
        }
      }
    }
    .navigationBarBackButtonHidden(true)
    .alert(
      unwrapping: self.$model.destination,
      case: /RecordMeetingModel.Destination.alert
    ) { action in
      await self.model.alertButtonTapped(action)
    }
    .task { await self.model.task() }
    .onChange(of: self.model.isDismissed) { _ in self.dismiss() }
  }
}

struct MeetingHeaderView: View {
  let secondsElapsed: Int
  let durationRemaining: Duration
  let theme: Theme

  var body: some View {
    VStack {
      ProgressView(value: self.progress)
        .progressViewStyle(MeetingProgressViewStyle(theme: self.theme))
      HStack {
        VStack(alignment: .leading) {
          Text("Time Elapsed")
            .font(.caption)
          Label(
            Duration.seconds(self.secondsElapsed).formatted(.units()),
            systemImage: "hourglass.bottomhalf.fill"
          )
        }
        Spacer()
        VStack(alignment: .trailing) {
          Text("Time Remaining")
            .font(.caption)
          Label(self.durationRemaining.formatted(.units()), systemImage: "hourglass.tophalf.fill")
            .font(.body.monospacedDigit())
            .labelStyle(.trailingIcon)
        }
      }
    }
    .padding([.top, .horizontal])
  }

  private var totalDuration: Duration {
    .seconds(self.secondsElapsed) + self.durationRemaining
  }

  private var progress: Double {
    guard totalDuration > .seconds(0) else { return 0 }
    return Double(self.secondsElapsed) / Double(self.totalDuration.components.seconds)
  }
}

struct MeetingProgressViewStyle: ProgressViewStyle {
  var theme: Theme

  func makeBody(configuration: Configuration) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10.0)
        .fill(theme.accentColor)
        .frame(height: 20.0)

      ProgressView(configuration)
        .tint(theme.mainColor)
        .frame(height: 12.0)
        .padding(.horizontal)
    }
  }
}

struct MeetingTimerView: View {
  let standup: Standup
  let speakerIndex: Int

  var body: some View {
    Circle()
      .strokeBorder(lineWidth: 24)
      .overlay {
        VStack {
          Group {
            if self.speakerIndex < self.standup.attendees.count {
              Text(self.standup.attendees[self.speakerIndex].name)
            } else {
              Text("Someone")
            }
          }
          .font(.title)
          Text("is speaking")
          Image(systemName: "mic.fill")
            .font(.largeTitle)
            .padding(.top)
        }
        .foregroundStyle(self.standup.theme.accentColor)
      }
      .overlay {
        ForEach(Array(self.standup.attendees.enumerated()), id: \.element.id) { index, attendee in
          if index < self.speakerIndex + 1 {
            SpeakerArc(totalSpeakers: self.standup.attendees.count, speakerIndex: index)
              .rotation(Angle(degrees: -90))
              .stroke(self.standup.theme.mainColor, lineWidth: 12)
          }
        }
      }
      .padding(.horizontal)
  }
}

struct SpeakerArc: Shape {
  let totalSpeakers: Int
  let speakerIndex: Int

  func path(in rect: CGRect) -> Path {
    let diameter = min(rect.size.width, rect.size.height) - 24.0
    let radius = diameter / 2.0
    let center = CGPoint(x: rect.midX, y: rect.midY)
    return Path { path in
      path.addArc(
        center: center,
        radius: radius,
        startAngle: self.startAngle,
        endAngle: self.endAngle,
        clockwise: false
      )
    }
  }

  private var degreesPerSpeaker: Double {
    360.0 / Double(self.totalSpeakers)
  }
  private var startAngle: Angle {
    Angle(degrees: self.degreesPerSpeaker * Double(self.speakerIndex) + 1.0)
  }
  private var endAngle: Angle {
    Angle(degrees: self.startAngle.degrees + self.degreesPerSpeaker - 1.0)
  }
}

struct MeetingFooterView: View {
  let standup: Standup
  var nextButtonTapped: () -> Void
  let speakerIndex: Int

  var body: some View {
    VStack {
      HStack {
        if self.speakerIndex < self.standup.attendees.count - 1 {
          Text("Speaker \(self.speakerIndex + 1) of \(self.standup.attendees.count)")
        } else {
          Text("No more speakers.")
        }
        Spacer()
        Button(action: self.nextButtonTapped) {
          Image(systemName: "forward.fill")
        }
      }
    }
    .padding([.bottom, .horizontal])
  }
}

struct RecordMeeting_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      RecordMeetingView(
        model: RecordMeetingModel(standup: .mock)
      )
    }
    .previewDisplayName("Happy path")

    Preview(
      message: """
        This preview demonstrates how the feature behaves when the speech recognizer emits a \
        failure after 2 seconds of transcribing.
        """
    ) {
      NavigationStack {
        RecordMeetingView(
          model: withDependencies {
            $0.speechClient = .fail(after: .seconds(2))
          } operation: {
            RecordMeetingModel(standup: .mock)
          }
        )
      }
    }
    .previewDisplayName("Speech failure after 2 secs")
  }
}
