import CasePaths
import CustomDump
import Dependencies
import XCTest

@testable import Standups

@MainActor
final class StandupDetailTests: XCTestCase {
  func testSpeechRestricted() throws {
    let model = withDependencies {
      $0.speechClient.authorizationStatus = { .restricted }
    } operation: {
      StandupDetailModel(standup: .mock)
    }

    model.startMeetingButtonTapped()

    let alert = try XCTUnwrap(model.destination, case: /StandupDetailModel.Destination.alert)

    XCTAssertNoDifference(alert, .speechRecognitionRestricted)
  }

  func testSpeechDenied() async throws {
    let model = withDependencies {
      $0.speechClient.authorizationStatus = { .denied }
    } operation: {
      StandupDetailModel(standup: .mock)
    }

    model.startMeetingButtonTapped()

    let alert = try XCTUnwrap(model.destination, case: /StandupDetailModel.Destination.alert)

    XCTAssertNoDifference(alert, .speechRecognitionDenied)
  }

  func testOpenSettings() async {
    let settingsOpened = LockIsolated(false)
    let model = withDependencies {
      $0.openSettings = { settingsOpened.setValue(true) }
    } operation: {
      StandupDetailModel(
        destination: .alert(.speechRecognitionDenied),
        standup: .mock
      )
    }

    await model.alertButtonTapped(.openSettings)

    XCTAssertEqual(settingsOpened.value, true)
  }

  func testContinueWithoutRecording() async throws {
    let model = StandupDetailModel(
      destination: .alert(.speechRecognitionDenied),
      standup: .mock
    )

    await model.alertButtonTapped(.continueWithoutRecording)

    let recordModel = try XCTUnwrap(model.destination, case: /StandupDetailModel.Destination.record)

    XCTAssertEqual(recordModel.standup, model.standup)
  }

  func testSpeechAuthorized() async throws {
    let model = withDependencies {
      $0.speechClient.authorizationStatus = { .authorized }
    } operation: {
      StandupDetailModel(standup: .mock)
    }

    model.startMeetingButtonTapped()

    let recordModel = try XCTUnwrap(model.destination, case: /StandupDetailModel.Destination.record)

    XCTAssertEqual(recordModel.standup, model.standup)
  }

  func testRecordWithTranscript() async throws {
    let model = withDependencies {
      $0.continuousClock = ImmediateClock()
      $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
      $0.soundEffectClient = .noop
      $0.speechClient.authorizationStatus = { .authorized }
      $0.speechClient.startTask = { _ in
        AsyncThrowingStream { continuation in
          continuation.yield(
            SpeechRecognitionResult(
              bestTranscription: Transcription(formattedString: "I completed the project"),
              isFinal: true
            )
          )
          continuation.finish()
        }
      }
      $0.uuid = .incrementing
    } operation: {
      StandupDetailModel(
        destination: .record(RecordMeetingModel(standup: .mock)),
        standup: Standup(
          id: Standup.ID(),
          attendees: [
            .init(id: Attendee.ID()),
            .init(id: Attendee.ID()),
          ],
          duration: .seconds(10),
          title: "Engineering"
        )
      )
    }

    let recordModel = try XCTUnwrap(model.destination, case: /StandupDetailModel.Destination.record)

    await recordModel.task()

    XCTAssertNil(model.destination)
    XCTAssertNoDifference(
      model.standup.meetings,
      [
        Meeting(
          id: Meeting.ID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          date: Date(timeIntervalSince1970: 1_234_567_890),
          transcript: "I completed the project"
        )
      ]
    )
  }

  func testEdit() throws {
    let model = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid

      return StandupDetailModel(
        standup: Standup(
          id: Standup.ID(uuid()),
          title: "Engineering"
        )
      )
    }

    model.editButtonTapped()

    let editModel = try XCTUnwrap(model.destination, case: /StandupDetailModel.Destination.edit)

    editModel.standup.title = "Engineering"
    editModel.standup.theme = .lavender
    model.doneEditingButtonTapped()

    XCTAssertNil(model.destination)
    XCTAssertEqual(
      model.standup,
      Standup(
        id: Standup.ID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        attendees: [
          Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        ],
        theme: .lavender,
        title: "Engineering"
      )
    )
  }
}
