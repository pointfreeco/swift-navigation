import Foundation

struct Fact: Identifiable {
  var description: String
  let number: Int

  var id: AnyHashable {
    [self.description as AnyHashable, self.number]
  }
}

func getNumberFact(_ count: Int) async -> Fact {
  let fact: String
  do {
    let (data, _) = try await URLSession.shared.data(
      from: URL(string: "http://numbersapi.com/\(count)/trivia")!
    )
    fact = String(decoding: data, as: UTF8.self)
  } catch {
    // Sometimes numbersapi.com can be flakey, so if it ever fails we will just
    // default to a mock response.
    fact = "\(count) is a good number Brent"
  }
  try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
  return Fact(description: fact, number: count)
}
