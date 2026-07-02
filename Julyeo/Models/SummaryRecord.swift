import Foundation
import SwiftData

enum InputType: String, Codable {
    case audio = "audio"
    case image = "image"
}

@Model
final class SummaryRecord {
    var id: UUID
    var createdAt: Date
    var inputType: InputType
    var title: String
    var originalText: String
    var summary: String
    var keyPoints: [String]
    var imageData: Data?

    init(
        inputType: InputType,
        title: String,
        originalText: String,
        summary: String,
        keyPoints: [String],
        imageData: Data? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.inputType = inputType
        self.title = title
        self.originalText = originalText
        self.summary = summary
        self.keyPoints = keyPoints
        self.imageData = imageData
    }
}
