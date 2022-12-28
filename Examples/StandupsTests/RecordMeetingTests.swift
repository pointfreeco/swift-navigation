import CasePaths
import Dependencies
import XCTest
import CustomDump
@testable import Standups

@MainActor
final class RecordMeetingTests: DependencyTestCase {
  func testTimer() async throws {
    let clock = TestClock()
    
    let model = DependencyValues.withTestValues {
      $0.continuousClock = clock
      $0.speechClient.authorizationStatus = { .denied }
    } operation: {
      RecordMeetingModel(
        standup: Standup(
          id: Standup.ID(),
          attendees: [
            Attendee(id: Attendee.ID()),
            Attendee(id: Attendee.ID()),
            Attendee(id: Attendee.ID()),
          ],
          duration: .seconds(3)
        )
      )
    }

    let onMeetingFinishedExpectation = self.expectation(description: "onMeetingFinished")
    model.onMeetingFinished = {
      XCTAssertEqual($0, "")
      onMeetingFinishedExpectation.fulfill()
    }

    let task = Task {
      await model.task()
    }

    // NB: This should not be necessary, but it doesn't seem like there is a better way to
    //     guarantee that the timer has started up. See this forum discussion for more information
    //     on the difficulties of testing async code in Swift:
    //     https://forums.swift.org/t/reliably-testing-code-that-adopts-swift-concurrency/57304
    try await Task.sleep(for: .milliseconds(300))

    XCTAssertEqual(model.speakerIndex, 0)
    XCTAssertEqual(model.durationRemaining, .seconds(3))

    await clock.advance(by: .seconds(1))
    XCTAssertEqual(model.speakerIndex, 1)
    XCTAssertEqual(model.durationRemaining, .seconds(2))

    await clock.advance(by: .seconds(1))
    XCTAssertEqual(model.speakerIndex, 2)
    XCTAssertEqual(model.durationRemaining, .seconds(1))

    await clock.advance(by: .seconds(1))
    XCTAssertEqual(model.speakerIndex, 2)
    XCTAssertEqual(model.durationRemaining, .seconds(0))

    await task.value

    self.wait(for: [onMeetingFinishedExpectation], timeout: 0)
    XCTAssertEqual(model.dismiss, true)
  }

  func testRecordTranscript() async throws {
    let model = DependencyValues.withTestValues {
      $0.continuousClock = ImmediateClock()
      $0.speechClient.authorizationStatus = { .authorized }
      $0.speechClient.startTask = { _ in
        AsyncThrowingStream([
          .init(bestTranscription: .init(formattedString: "I completed the project"), isFinal: true)
        ])
      }
    } operation: {
      RecordMeetingModel(
        standup: Standup(
          id: Standup.ID(),
          attendees: [Attendee(id: Attendee.ID())],
          duration: .seconds(3)
        )
      )
    }

    let onMeetingFinishedExpectation = self.expectation(description: "onMeetingFinished")
    model.onMeetingFinished = {
      XCTAssertEqual($0, "I completed the project")
      onMeetingFinishedExpectation.fulfill()
    }

    await model.task()

    self.wait(for: [onMeetingFinishedExpectation], timeout: 0)
    XCTAssertEqual(model.dismiss, true)
  }

  func testEndMeetingSave() async throws {
    let clock = TestClock()

    let model = DependencyValues.withTestValues {
      $0.continuousClock = clock
      $0.speechClient.authorizationStatus = { .denied }
    } operation: {
      RecordMeetingModel(standup: .mock)
    }

    let onMeetingFinishedExpectation = self.expectation(description: "onMeetingFinished")
    model.onMeetingFinished = {
      XCTAssertEqual($0, "")
      onMeetingFinishedExpectation.fulfill()
    }

    let task = Task {
      await model.task()
    }

    model.endMeetingButtonTapped()

    let alert = try XCTUnwrap(model.destination, case: /RecordMeetingModel.Destination.alert)

    XCTAssertNoDifference(alert, .endMeeting(isDiscardable: true))

    await clock.advance(by: .seconds(5))

    XCTAssertEqual(model.speakerIndex, 0)
    XCTAssertEqual(model.durationRemaining, .seconds(60))

    await model.alertButtonTapped(.confirmSave)

    self.wait(for: [onMeetingFinishedExpectation], timeout: 0)
    XCTAssertEqual(model.dismiss, true)

    task.cancel()
    await task.value
  }

  func testEndMeetingDiscard() async throws {
    let clock = TestClock()

    let model = DependencyValues.withTestValues {
      $0.continuousClock = clock
      $0.speechClient.authorizationStatus = { .denied }
    } operation: {
      RecordMeetingModel(standup: .mock)
    }

    model.onMeetingFinished = { _ in XCTFail() }

    let task = Task {
      await model.task()
    }

    model.endMeetingButtonTapped()

    let alert = try XCTUnwrap(model.destination, case: /RecordMeetingModel.Destination.alert)

    XCTAssertNoDifference(alert, .endMeeting(isDiscardable: true))

    await model.alertButtonTapped(.confirmDiscard)

    XCTAssertEqual(model.dismiss, true)

    task.cancel()
    await task.value
  }

  func testNextSpeaker() async throws {
    let clock = TestClock()
    let model = DependencyValues.withTestValues {
      $0.continuousClock = clock
      $0.speechClient.authorizationStatus = { .denied }

    } operation: {
      RecordMeetingModel(
        standup: Standup(
          id: Standup.ID(),
          attendees: [
            Attendee(id: Attendee.ID()),
            Attendee(id: Attendee.ID()),
            Attendee(id: Attendee.ID()),
          ],
          duration: .seconds(3)
        )
      )
    }

    let onMeetingFinishedExpectation = self.expectation(description: "onMeetingFinished")
    model.onMeetingFinished = {
      XCTAssertEqual($0, "")
      onMeetingFinishedExpectation.fulfill()
    }

    let task = Task {
      await model.task()
    }

    model.nextButtonTapped()

    XCTAssertEqual(model.speakerIndex, 1)
    XCTAssertEqual(model.durationRemaining, .seconds(2))

    model.nextButtonTapped()

    XCTAssertEqual(model.speakerIndex, 2)
    XCTAssertEqual(model.durationRemaining, .seconds(1))

    model.nextButtonTapped()

    let alert = try XCTUnwrap(model.destination, case: /RecordMeetingModel.Destination.alert)

    XCTAssertNoDifference(alert, .endMeeting(isDiscardable: false))

    await clock.advance(by: .seconds(5))

    XCTAssertEqual(model.speakerIndex, 2)
    XCTAssertEqual(model.durationRemaining, .seconds(1))

    await model.alertButtonTapped(.confirmSave)

    self.wait(for: [onMeetingFinishedExpectation], timeout: 0)
    XCTAssertEqual(model.dismiss, true)

    task.cancel()
    await task.value
  }
}

