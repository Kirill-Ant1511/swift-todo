import Foundation

struct Comment: Identifiable, Codable {
    let id: UUID
    let ownerId: UUID
    let ownerName: String?
    let content: String
}

struct TaskItem: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let title: String
    let description: String?
    let ownerId: UUID
    let ownerName: String?
    let performBy: UUID?
    let isDone: Bool
    let comments: [Comment]
}


struct CreateTaskRequest: Codable {
    let title: String
    let description: String?
    let ownerId: UUID
}

struct CreateCommentRequest: Codable {
    let content: String
    let ownerId: UUID
}
