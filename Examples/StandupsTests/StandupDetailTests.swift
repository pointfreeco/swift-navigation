import CustomDump
import Dependencies
import XCTest

@testable import Standups

@MainActor
final class StandupDetailTests: XCTestCase {
  func testSpeechRestricted() {
    let model = DependencyValues.withTestValues {
      $0.speechClient.authorizationStatus = { .restricted }
    } operation: {
      StandupDetailModel(standup: .mock)
    }

    model.startMeetingButtonTapped()

    guard case let .some(.alert(alert)) = model.destination
    else {
      XCTFail()
      return
    }

    XCTAssertNoDifference(alert, .speechRecognitionRestricted)
  }

  func testSpeechDenied() async {
    let model = DependencyValues.withTestValues {
      $0.speechClient.authorizationStatus = { .denied }
    } operation: {
      StandupDetailModel(standup: .mock)
    }

    model.startMeetingButtonTapped()

    guard case let .some(.alert(alert)) = model.destination
    else {
      XCTFail()
      return
    }

    XCTAssertNoDifference(alert, .speechRecognitionDenied)
  }

  func testOpenSettings() async {
    let settingsOpened = LockIsolated(false)
    let model = DependencyValues.withTestValues {
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

  func testContinueWithoutRecording() async {
    let model = DependencyValues.withTestValues {
      $0.continuousClock = ImmediateClock()
    } operation: {
      StandupDetailModel(
        destination: .alert(.speechRecognitionDenied),
        standup: .mock
      )
    }

    await model.alertButtonTapped(.continueWithoutRecording)

    guard case let .some(.record(recordModel)) = model.destination
    else {
      XCTFail()
      return
    }

    XCTAssertEqual(recordModel.standup, model.standup)
  }

  func testSpeechAuthorized() async {
    let model = DependencyValues.withTestValues {
      $0.speechClient.authorizationStatus = { .authorized }
    } operation: {
      StandupDetailModel(standup: .mock)
    }

    model.startMeetingButtonTapped()

    guard case let .some(.record(recordModel)) = model.destination
    else {
      XCTFail()
      return
    }

    XCTAssertEqual(recordModel.standup, model.standup)
  }

  func testRecordWithTranscript() async {
    let model = DependencyValues.withTestValues {
      $0.continuousClock = ImmediateClock()
      $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
      $0.speechClient.authorizationStatus = { .authorized }
      $0.speechClient.startTask = { _ in
        AsyncThrowingStream([
          .init(bestTranscription: .init(formattedString: "I completed the project"), isFinal: true)
        ])
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

    guard case let .some(.record(recordModel)) = model.destination
    else {
      XCTFail()
      return
    }

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
}
