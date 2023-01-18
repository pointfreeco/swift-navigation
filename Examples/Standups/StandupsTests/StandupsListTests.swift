import CasePaths
import CustomDump
import Dependencies
import IdentifiedCollections
import XCTest

@testable import Standups

@MainActor
final class StandupsListTests: XCTestCase {
  let mainQueue = DispatchQueue.test

  func testAdd() async throws {
    let savedData = LockIsolated(Data?.none)

    let model = withDependencies {
      $0.dataManager = .mock()
      $0.dataManager.save = { data, _ in savedData.setValue(data) }
      $0.mainQueue = mainQueue.eraseToAnyScheduler()
      $0.uuid = .incrementing
    } operation: {
      StandupsListModel()
    }

    model.addStandupButtonTapped()

    let addModel = try XCTUnwrap(model.destination, case: /StandupsListModel.Destination.add)

    addModel.standup.title = "Engineering"
    addModel.standup.attendees[0].name = "Blob"
    addModel.addAttendeeButtonTapped()
    addModel.standup.attendees[1].name = "Blob Jr."
    model.confirmAddStandupButtonTapped()

    XCTAssertNil(model.destination)

    XCTAssertNoDifference(
      model.standups,
      [
        Standup(
          id: Standup.ID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          attendees: [
            Attendee(
              id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!,
              name: "Blob"
            ),
            Attendee(
              id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000002")!,
              name: "Blob Jr."
            ),
          ],
          title: "Engineering"
        )
      ]
    )

    await self.mainQueue.run()
    XCTAssertEqual(
      try JSONDecoder().decode(IdentifiedArrayOf<Standup>.self, from: XCTUnwrap(savedData.value)),
      model.standups
    )
  }

  func testAdd_ValidatedAttendees() async throws {
    let model = withDependencies {
      $0.dataManager = .mock()
      $0.mainQueue = mainQueue.eraseToAnyScheduler()
      $0.uuid = .incrementing
    } operation: {
      StandupsListModel(
        destination: .add(
          StandupFormModel(
            standup: Standup(
              id: Standup.ID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!,
              attendees: [
                Attendee(id: Attendee.ID(), name: ""),
                Attendee(id: Attendee.ID(), name: "    "),
              ],
              title: "Design"
            )
          )
        )
      )
    }

    model.confirmAddStandupButtonTapped()

    XCTAssertNil(model.destination)
    XCTAssertNoDifference(
      model.standups,
      [
        Standup(
          id: Standup.ID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!,
          attendees: [
            Attendee(
              id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000000")!,
              name: ""
            )
          ],
          title: "Design"
        )
      ]
    )
  }

  func testDelete() async throws {
    let model = try withDependencies { dependencies in
      dependencies.dataManager = .mock(
        initialData: try JSONEncoder().encode([Standup.mock])
      )
      dependencies.mainQueue = mainQueue.eraseToAnyScheduler()
    } operation: {
      StandupsListModel()
    }

    model.standupTapped(standup: model.standups[0])

    let detailModel = try XCTUnwrap(model.destination, case: /StandupsListModel.Destination.detail)

    detailModel.deleteButtonTapped()

    let alert = try XCTUnwrap(detailModel.destination, case: /StandupDetailModel.Destination.alert)

    XCTAssertNoDifference(alert, .deleteStandup)

    await detailModel.alertButtonTapped(.confirmDeletion)

    XCTAssertNil(model.destination)
    XCTAssertEqual(model.standups, [])
    XCTAssertEqual(detailModel.isDismissed, true)
  }

  func testDetailEdit() async throws {
    let model = try withDependencies { dependencies in
      dependencies.dataManager = .mock(
        initialData: try JSONEncoder().encode([
          Standup(
            id: Standup.ID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            attendees: [
              Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!)
            ]
          )
        ])
      )
      dependencies.mainQueue = mainQueue.eraseToAnyScheduler()
    } operation: {
      StandupsListModel()
    }

    model.standupTapped(standup: model.standups[0])

    let detailModel = try XCTUnwrap(model.destination, case: /StandupsListModel.Destination.detail)

    detailModel.editButtonTapped()

    let editModel = try XCTUnwrap(
      detailModel.destination, case: /StandupDetailModel.Destination.edit)

    editModel.standup.title = "Design"
    detailModel.doneEditingButtonTapped()

    XCTAssertNil(detailModel.destination)
    XCTAssertEqual(
      model.standups,
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

  func testLoadingDataDecodingFailed() async throws {
    let model = withDependencies {
      $0.mainQueue = .immediate
      $0.dataManager = .mock(
        initialData: Data("!@#$ BAD DATA %^&*()".utf8)
      )
    } operation: {
      StandupsListModel()
    }

    let alert = try XCTUnwrap(model.destination, case: /StandupsListModel.Destination.alert)

    XCTAssertNoDifference(alert, .dataFailedToLoad)

    model.alertButtonTapped(.confirmLoadMockData)

    XCTAssertNoDifference(model.standups, [.mock, .designMock, .engineeringMock])
  }

  func testLoadingDataFileNotFound() async throws {
    let model = withDependencies {
      $0.dataManager.load = { _ in
        struct FileNotFound: Error {}
        throw FileNotFound()
      }
    } operation: {
      StandupsListModel()
    }

    XCTAssertNil(model.destination)
  }
}
