import Foundation
import AppKit
import Combine

final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipItem] = []

    private let maxItems = 100
    private var pasteboardChangeCount: Int
    private var timer: Timer?
    private var isRestoringPaste = false

    private let storeURL: URL

    init() {
        let pasteboard = NSPasteboard.general
        pasteboardChangeCount = pasteboard.changeCount

        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipboardHistory", isDirectory: true)
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        storeURL = supportDir.appendingPathComponent("history.json")

        load()
        startPolling()
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != pasteboardChangeCount else { return }
        pasteboardChangeCount = pasteboard.changeCount

        // Ignore the change we ourselves trigger when re-pasting an item.
        if isRestoringPaste {
            isRestoringPaste = false
            return
        }

        if let str = pasteboard.string(forType: .string), !str.isEmpty {
            addItem(.text(str))
        } else if let data = pasteboard.data(forType: .tiff), let image = NSImage(data: data),
                  let png = pngData(from: image) {
            addItem(.image(png))
        }
    }

    private enum NewClip {
        case text(String)
        case image(Data)
    }

    private func addItem(_ clip: NewClip) {
        let newItem: ClipItem
        switch clip {
        case .text(let s):
            // Skip duplicate of the most recent item.
            if let first = items.first, first.kind == .text, first.text == s { return }
            newItem = ClipItem(text: s)
        case .image(let d):
            if let first = items.first, first.kind == .image, first.imageData == d { return }
            newItem = ClipItem(imageData: d)
        }

        items.insert(newItem, at: 0)
        trimIfNeeded()
        save()
    }

    /// Keeps the most recent `maxItems` unpinned entries; pinned entries never age out.
    private func trimIfNeeded() {
        let unpinnedCount = items.filter { !$0.pinned }.count
        guard unpinnedCount > maxItems else { return }

        var overflow = unpinnedCount - maxItems
        // Walk from the oldest end, dropping unpinned items until we've removed `overflow`.
        var i = items.count - 1
        while i >= 0 && overflow > 0 {
            if !items[i].pinned {
                items.remove(at: i)
                overflow -= 1
            }
            i -= 1
        }
    }

    func togglePin(_ item: ClipItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].pinned.toggle()
        save()
    }

    func copyToClipboard(_ item: ClipItem) {
        let pasteboard = NSPasteboard.general
        isRestoringPaste = true
        pasteboard.clearContents()
        switch item.kind {
        case .text:
            pasteboard.setString(item.text ?? "", forType: .string)
        case .image:
            if let data = item.imageData, let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        }
        pasteboardChangeCount = pasteboard.changeCount
    }

    func clearHistory() {
        items.removeAll()
        save()
    }

    func remove(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    private func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            NSLog("ClipboardHistory: failed to save history: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        if let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) {
            items = decoded
        }
    }
}
