import SwiftUI

@main
struct StandupsApp: App {
  var body: some Scene {
    WindowGroup {
      var standup = Standup.mock
      let _ = standup.duration = .seconds(1)
      let _ = standup.attendees = [
        Attendee(id: Attendee.ID(UUID()), name: "Blob")
      ]
      StandupsList(
        model: StandupsListModel(
//          destination: .detail(
//            StandupDetailModel(
//              destination: .record(
//                RecordMeetingModel(standup: standup)
//              ),
//              standup: standup
//            )
//          )
        )
      )
    }
  }
}
