import CasePaths
import CustomDump
import Dependencies
import IdentifiedCollections
import XCTest

@testable import Standups

@MainActor
final class AppTests: XCTestCase {
  let mainQueue = DispatchQueue.test

  func testDelete() async throws {
    let model = try withDependencies { dependencies in
      dependencies.dataManager = .mock(
        initialData: try JSONEncoder().encode([Standup.mock])
      )
      dependencies.mainQueue = mainQueue.eraseToAnyScheduler()
    } operation: {
      AppModel(standupsList: StandupsListModel())
    }

    model.path.append(.detail(StandupDetailModel(standup: .mock)))

    let detailModel = try XCTUnwrap(model.path[0], case: /AppModel.Destination.detail)

    detailModel.deleteButtonTapped()

    let alert = try XCTUnwrap(detailModel.destination, case: /StandupDetailModel.Destination.alert)

    XCTAssertNoDifference(alert, .deleteStandup)

    await detailModel.alertButtonTapped(.confirmDeletion)

    XCTAssertEqual(model.path, [])
    XCTAssertEqual(model.standupsList.standups, [])
  }

  func testDetailEdit() async throws {
    let standup = Standup(
      id: Standup.ID(uuidString: "00000000-0000-0000-0000-000000000000")!,
      attendees: [
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!)
      ]
    )

    let model = try withDependencies { dependencies in
      dependencies.dataManager = .mock(
        initialData: try JSONEncoder().encode([standup])
      )
      dependencies.mainQueue = mainQueue.eraseToAnyScheduler()
    } operation: {
      AppModel(
        path: [.detail(StandupDetailModel(standup: standup))],
        standupsList: StandupsListModel()
      )
    }

    let detailModel = try XCTUnwrap(model.path[0], case: /AppModel.Destination.detail)

    detailModel.editButtonTapped()

    let editModel = try XCTUnwrap(
      detailModel.destination,
      case: /StandupDetailModel.Destination.edit
    )

    editModel.standup.title = "Design"
    detailModel.doneEditingButtonTapped()

    XCTAssertNil(detailModel.destination)
    XCTAssertNoDifference(
      model.standupsList.standups,
      [
        Standup(
          id: Standup.ID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          attendees: [
            Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!)
          ],
          title: "Design"
        )
      ]
    )
  }
}



/*

 */




/*

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

  let onMeetingFinishedExpectation = self.expectation(description: "onMeetingFinished")
  model.on
  onMeetingFinishedExpectation.fulfill()

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
*/
