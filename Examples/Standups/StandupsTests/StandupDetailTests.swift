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

    let onStartMeetingExpectation = self.expectation(description: "onStartMeeting")
    model.onStartMeeting = {
      onStartMeetingExpectation.fulfill()
    }

    await model.alertButtonTapped(.continueWithoutRecording)
    self.wait(for: [onStartMeetingExpectation], timeout: 0)
  }

  func testSpeechAuthorized() async throws {
    let model = withDependencies {
      $0.speechClient.authorizationStatus = { .authorized }
    } operation: {
      StandupDetailModel(standup: .mock)
    }

    let onStartMeetingExpectation = self.expectation(description: "onStartMeeting")
    model.onStartMeeting = {
      onStartMeetingExpectation.fulfill()
    }

    model.startMeetingButtonTapped()

    self.wait(for: [onStartMeetingExpectation], timeout: 0)
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
