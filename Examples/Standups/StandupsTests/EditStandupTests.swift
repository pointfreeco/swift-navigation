import Dependencies
import XCTest
import CustomDump
@testable import Standups

@MainActor
final class EditStandupTests: DependencyTestCase {
  func testAddAttendee() {
    let model = DependencyValues.withTestValues {
      $0.uuid = .incrementing
    } operation: {
      EditStandupModel(
        standup: Standup(
          id: Standup.ID(),
          attendees: [],
          title: "Engineering"
        )
      )
    }

    XCTAssertNoDifference(
      model.standup.attendees,
      [
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000000")!),
      ]
    )

    model.addAttendeeButtonTapped()

    XCTAssertNoDifference(
      model.standup.attendees,
      [
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000000")!),
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!),
      ]
    )
  }

  func testFocus_AddAttendee() {
    let model = DependencyValues.withTestValues {
      $0.uuid = .incrementing
    } operation: {
      EditStandupModel(
        standup: Standup(
          id: Standup.ID(),
          attendees: [],
          title: "Engineering"
        )
      )
    }

    XCTAssertEqual(model.focus, .title)

    model.addAttendeeButtonTapped()

    XCTAssertEqual(
      model.focus,
      .attendee(Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    )
  }

  func testFocus_RemoveAttendee() {
    let model = DependencyValues.withTestValues {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid

      return EditStandupModel(
        standup: Standup(
          id: Standup.ID(),
          attendees: [
            Attendee(id: Attendee.ID(uuid())),
            Attendee(id: Attendee.ID(uuid())),
            Attendee(id: Attendee.ID(uuid())),
            Attendee(id: Attendee.ID(uuid())),
          ],
          title: "Engineering"
        )
      )
    }

    model.deleteAttendees(atOffsets: [0])

    XCTAssertNoDifference(
      model.focus,
      .attendee(Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    )
    XCTAssertNoDifference(
      model.standup.attendees,
      [
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!),
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000002")!),
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000003")!),
      ]
    )

    model.deleteAttendees(atOffsets: [1])

    XCTAssertNoDifference(
      model.focus,
      .attendee(Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000003")!)
    )
    XCTAssertNoDifference(
      model.standup.attendees,
      [
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!),
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000003")!),
      ]
    )

    model.deleteAttendees(atOffsets: [1])

    XCTAssertNoDifference(
      model.focus,
      .attendee(Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    )
    XCTAssertNoDifference(
      model.standup.attendees,
      [
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000001")!),
      ]
    )

    model.deleteAttendees(atOffsets: [0])

    XCTAssertNoDifference(
      model.focus,
      .attendee(Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000004")!)
    )
    XCTAssertNoDifference(
      model.standup.attendees,
      [
        Attendee(id: Attendee.ID(uuidString: "00000000-0000-0000-0000-000000000004")!),
      ]
    )
  }
}
