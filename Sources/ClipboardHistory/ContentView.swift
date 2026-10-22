import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ClipboardStore
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var filteredItems: [ClipItem] {
        guard !query.isEmpty else { return store.items }
        return store.items.filter { item in
            switch item.kind {
            case .text:
                return (item.text ?? "").localizedCaseInsensitiveContains(query)
            case .image:
                return "image".localizedCaseInsensitiveContains(query)
            }
        }
    }

    private var pinnedItems: [ClipItem] { filteredItems.filter { $0.pinned } }
    private var recentItems: [ClipItem] { filteredItems.filter { !$0.pinned } }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard History")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    store.clearHistory()
                }
                .font(.caption)
            }
            .padding(10)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Search clipboard history", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.12))
            .cornerRadius(6)
            .padding(.horizontal, 10)
            .padding(.bottom, 8)

            Divider()

            if filteredItems.isEmpty {
                VStack {
                    Spacer()
                    Text(query.isEmpty ? "No clipboard history yet" : "No matches")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Spacer()
                }
                .frame(height: 120)
            } else {
                let rowHeight: CGFloat = 52
                let visibleRows = min(filteredItems.count, 10)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if !pinnedItems.isEmpty {
                            SectionLabel(text: "PINNED")
                            ForEach(pinnedItems) { item in
                                ClipRow(item: item, store: store)
                                Divider()
                            }
                        }
                        if !recentItems.isEmpty {
                            if !pinnedItems.isEmpty {
                                SectionLabel(text: "RECENT")
                            }
                            ForEach(recentItems) { item in
                                ClipRow(item: item, store: store)
                                Divider()
                            }
                        }
                    }
                }
                .frame(height: rowHeight * CGFloat(visibleRows))
            }

            Divider()

            HStack {
                Text("\(store.items.count) items")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.caption)
            }
            .padding(8)
        }
        .frame(width: 340)
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

struct ClipRow: View {
    let item: ClipItem
    @ObservedObject var store: ClipboardStore
    @State private var isHovering = false

    var body: some View {
        Button {
            store.copyToClipboard(item)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                if item.kind == .image, let nsImage = item.nsImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "doc.plaintext")
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.preview)
                        .font(.system(size: 12))
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    Text(item.date, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isHovering || item.pinned {
                    Button {
                        store.togglePin(item)
                    } label: {
                        Image(systemName: item.pinned ? "pin.fill" : "pin")
                            .foregroundStyle(item.pinned ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                if isHovering {
                    Button {
                        store.remove(item)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovering ? Color.gray.opacity(0.15) : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
