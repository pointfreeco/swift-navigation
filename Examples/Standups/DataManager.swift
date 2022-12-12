import Dependencies
import Foundation

struct DataManager: Sendable {
  var load: @Sendable (URL) throws -> Data
  var save: @Sendable (Data, URL) throws -> Void
}

extension DataManager: DependencyKey {
  static let liveValue = DataManager(
    load: { url in try Data(contentsOf: url) },
    save: { data, url in try data.write(to: url) }
  )
}

extension DependencyValues {
  var dataManager: DataManager {
    get { self[DataManager.self] }
    set { self[DataManager.self] = newValue }
  }
}

extension DataManager {
  static func mock(initialData: Data = Data()) -> DataManager {
    let data = LockIsolated(initialData)
    return DataManager(
      load: { _ in data.value },
      save: { newData, _ in data.setValue(newData) }
    )
  }

  static let failToWrite = DataManager(
    load: { url in Data() },
    save: { data, url in
      struct SaveError: Error {}
      throw SaveError()
    }
  )

  static let failToLoad = DataManager(
    load: { _ in
      struct LoadError: Error {}
      throw LoadError()
    },
    save: { newData, url in }
  )
}
