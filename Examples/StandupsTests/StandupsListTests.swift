import Dependencies
import XCTest
import CustomDump
@testable import Standups

@MainActor
final class StandupsListTests: XCTestCase {
  let mainQueue = DispatchQueue.test

  func testAdd() async throws {
    let savedData = LockIsolated(Data?.none)

    let model = DependencyValues.withTestValues {
      $0.dataManager = .mock()
      $0.dataManager.save = { data, _ in savedData.setValue(data) }
      $0.mainQueue = mainQueue.eraseToAnyScheduler()
      $0.uuid = .incrementing
    } operation: {
      StandupsListModel()
    }

    model.addStandupButtonTapped()

    guard case let .some(.add(addModel)) = model.destination
    else {
      XCTFail()
      return
    }

    addModel.standup.title = "Product"
    addModel.standup.attendees[0].name = "Blob"
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
            )
          ],
          title: "Product"
        )
      ]
    )

    await self.mainQueue.run()
    XCTAssertEqual(
      try JSONDecoder().decode([Standup].self, from: XCTUnwrap(savedData.value)),
      [
        Standup(
          id: Standup.ID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          attendees: [
            Attendee(
              id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!,
              name: "Blob"
            )
          ],
          title: "Product"
        )
      ]
    )
  }

  func testDelete() async throws {
    let model = try DependencyValues.withTestValues { dependencies in
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

    guard case let .some(.detail(detailModel)) = model.destination
    else {
      XCTFail()
      return
    }

    detailModel.deleteButtonTapped()

    guard case let .some(.alert(alert)) = detailModel.destination
    else {
      XCTFail()
      return
    }

    XCTAssertNoDifference(alert, .deleteStandup)

    detailModel.alertButtonTapped(.confirmDeletion)

    XCTAssertNil(model.destination)
    XCTAssertEqual(model.standups, [])
  }

  func testDetailEdit() async throws {
    let model = try DependencyValues.withTestValues { dependencies in
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

    guard case let .some(.detail(detailModel)) = model.destination
    else {
      XCTFail()
      return
    }

    detailModel.editButtonTapped()

    guard case let .some(.edit(editModel)) = detailModel.destination
    else {
      XCTFail()
      return
    }

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
}
