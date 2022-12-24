import CustomDump
import Dependencies
import XCTest
import CustomDump
@testable import Standups

@MainActor
final class StandupDetailTests: XCTestCase {
  func testRestricted() {
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

  func testDenied() {
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

    model.alertButtonTapped(.openSettings)

    // TODO: do better
    while !settingsOpened.value {
      await Task.yield()
    }
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

    model.alertButtonTapped(.continueWithoutRecording)

    while model.destination == nil {
      await Task.yield()
    }

    // TODO: alertButtonTapped should really be async
    guard case let .some(.record(recordModel)) = model.destination
    else {
      XCTFail()
      return
    }

    XCTAssertEqual(recordModel.standup, model.standup)
  }
}
