import Foundation
import AppKit

enum ClipKind: String, Codable {
    case text
    case image
}

final class ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: ClipKind
    let date: Date
    var text: String?
    var imageData: Data? // PNG data for images
    var pinned: Bool = false

    init(text: String) {
        self.id = UUID()
        self.kind = .text
        self.date = Date()
        self.text = text
        self.imageData = nil
    }

    init(imageData: Data) {
        self.id = UUID()
        self.kind = .image
        self.date = Date()
        self.text = nil
        self.imageData = imageData
    }

    var preview: String {
        switch kind {
        case .text:
            let t = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let collapsed = t.replacingOccurrences(of: "\n", with: " ")
            return collapsed.isEmpty ? "(empty)" : String(collapsed.prefix(80))
        case .image:
            return "Image"
        }
    }

    var nsImage: NSImage? {
        guard kind == .image, let data = imageData else { return nil }
        return NSImage(data: data)
    }

    static func == (lhs: ClipItem, rhs: ClipItem) -> Bool {
        lhs.id == rhs.id
    }
}
