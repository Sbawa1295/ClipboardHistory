import SwiftUI

@main
struct ClipboardHistoryApp: App {
    @StateObject private var store = ClipboardStore()

    var body: some Scene {
        MenuBarExtra("Clipboard History", systemImage: "doc.on.clipboard") {
            ContentView(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}
