import CasePaths
import CustomDump
import Dependencies
import XCTest

@testable import Standups

@MainActor
final class RecordMeetingTests: XCTestCase {
  func testTimer() async throws {
    let clock = TestClock()
    let soundEffectPlayCount = LockIsolated(0)

    let model = withDependencies {
      $0.continuousClock = clock
      $0.soundEffectClient = .noop
      $0.soundEffectClient.play = { soundEffectPlayCount.withValue { $0 += 1 } }
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
    XCTAssertEqual(soundEffectPlayCount.value, 1)

    await clock.advance(by: .seconds(1))
    XCTAssertEqual(model.speakerIndex, 2)
    XCTAssertEqual(model.durationRemaining, .seconds(1))
    XCTAssertEqual(soundEffectPlayCount.value, 2)

    await clock.advance(by: .seconds(1))
    XCTAssertEqual(model.speakerIndex, 2)
    XCTAssertEqual(model.durationRemaining, .seconds(0))
    XCTAssertEqual(soundEffectPlayCount.value, 2)

    await task.value

    self.wait(for: [onMeetingFinishedExpectation], timeout: 0)
    XCTAssertEqual(model.isDismissed, true)
    XCTAssertEqual(soundEffectPlayCount.value, 2)
  }

  func testRecordTranscript() async throws {
    let model = withDependencies {
      $0.continuousClock = ImmediateClock()
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
    XCTAssertEqual(model.isDismissed, true)
  }

  func testEndMeetingSave() async throws {
    let clock = TestClock()

    let model = withDependencies {
      $0.continuousClock = clock
      $0.soundEffectClient = .noop
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
    XCTAssertEqual(model.isDismissed, true)

    task.cancel()
    await task.value
  }

  func testEndMeetingDiscard() async throws {
    let clock = TestClock()

    let model = withDependencies {
      $0.continuousClock = clock
      $0.soundEffectClient = .noop
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

    XCTAssertEqual(model.isDismissed, true)

    task.cancel()
    await task.value
  }

  func testNextSpeaker() async throws {
    let clock = TestClock()
    let soundEffectPlayCount = LockIsolated(0)

    let model = withDependencies {
      $0.continuousClock = clock
      $0.soundEffectClient = .noop
      $0.soundEffectClient.play = { soundEffectPlayCount.withValue { $0 += 1 } }
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
    XCTAssertEqual(soundEffectPlayCount.value, 1)

    model.nextButtonTapped()

    XCTAssertEqual(model.speakerIndex, 2)
    XCTAssertEqual(model.durationRemaining, .seconds(1))
    XCTAssertEqual(soundEffectPlayCount.value, 2)

    model.nextButtonTapped()

    let alert = try XCTUnwrap(model.destination, case: /RecordMeetingModel.Destination.alert)

    XCTAssertNoDifference(alert, .endMeeting(isDiscardable: false))

    await clock.advance(by: .seconds(5))

    XCTAssertEqual(model.speakerIndex, 2)
    XCTAssertEqual(model.durationRemaining, .seconds(1))
    XCTAssertEqual(soundEffectPlayCount.value, 2)

    await model.alertButtonTapped(.confirmSave)

    self.wait(for: [onMeetingFinishedExpectation], timeout: 0)
    XCTAssertEqual(model.isDismissed, true)
    XCTAssertEqual(soundEffectPlayCount.value, 2)

    task.cancel()
    await task.value
  }

  func testSpeechRecognitionFailure_Continue() async throws {
    let model = withDependencies {
      $0.continuousClock = ImmediateClock()
      $0.soundEffectClient = .noop
      $0.speechClient.authorizationStatus = { .authorized }
      $0.speechClient.startTask = { _ in
        AsyncThrowingStream {
          $0.yield(
            SpeechRecognitionResult(
              bestTranscription: Transcription(formattedString: "I completed the project"),
              isFinal: true
            )
          )
          struct SpeechRecognitionFailure: Error {}
          $0.finish(throwing: SpeechRecognitionFailure())
        }
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
    model.onMeetingFinished = { transcript in
      XCTAssertEqual(transcript, "I completed the project ❌")
      onMeetingFinishedExpectation.fulfill()
    }

    let task = Task {
      await model.task()
    }

    // NB: This should not be necessary, but it doesn't seem like there is a better way to
    //     guarantee that the timer has started up. See this forum discussion for more information
    //     on the difficulties of testing async code in Swift:
    //     https://forums.swift.org/t/reliably-testing-code-that-adopts-swift-concurrency/57304
    try await Task.sleep(for: .milliseconds(100))

    let alert = try XCTUnwrap(model.destination, case: /RecordMeetingModel.Destination.alert)
    XCTAssertEqual(alert, .speechRecognizerFailed)

    model.destination = nil  // NB: Simulate SwiftUI closing alert.
    XCTAssertEqual(model.isDismissed, false)

    await task.value

    XCTAssertEqual(model.secondsElapsed, 3)
    self.wait(for: [onMeetingFinishedExpectation], timeout: 0)
  }

  func testSpeechRecognitionFailure_Discard() async throws {
    let model = withDependencies {
      $0.continuousClock = ImmediateClock()
      $0.soundEffectClient = .noop
      $0.speechClient.authorizationStatus = { .authorized }
      $0.speechClient.startTask = { _ in
        struct SpeechRecognitionFailure: Error {}
        return AsyncThrowingStream.finished(throwing: SpeechRecognitionFailure())
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

    let task = Task {
      await model.task()
    }

    // NB: This should not be necessary, but it doesn't seem like there is a better way to
    //     guarantee that the timer has started up. See this forum discussion for more information
    //     on the difficulties of testing async code in Swift:
    //     https://forums.swift.org/t/reliably-testing-code-that-adopts-swift-concurrency/57304
    try await Task.sleep(for: .milliseconds(100))

    let alert = try XCTUnwrap(model.destination, case: /RecordMeetingModel.Destination.alert)
    XCTAssertEqual(alert, .speechRecognizerFailed)

    await model.alertButtonTapped(.confirmDiscard)
    model.destination = nil  // NB: Simulate SwiftUI closing alert.
    XCTAssertEqual(model.isDismissed, true)

    await task.value
  }
}
