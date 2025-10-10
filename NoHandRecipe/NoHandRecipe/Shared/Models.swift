import Foundation
enum Role { case user, assistant, system }
struct Message: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    var text: String
}
