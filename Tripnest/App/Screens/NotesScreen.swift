import SwiftUI

struct NotesScreen: View {
    @EnvironmentObject private var store: TripStore
    var tripId: String?
    var onNav: (AppRoute) -> Void = { _ in }
    var onBack: () -> Void = {}

    static let maxLines = 500

    @State private var text: String = ""
    @State private var loaded = false
    @FocusState private var focused: Bool

    private var trip: Trip? {
        if let tripId, let match = store.trips.first(where: { $0.id == tripId }) { return match }
        return store.activeTrip
    }

    private var lineCount: Int {
        text.components(separatedBy: .newlines).count
    }

    var body: some View {
        ScreenShell(motif: false) {
            Group {
                if let trip {
                    VStack(spacing: 0) {
                        TripSubpageTopBar(
                            title: "Notes",
                            subtitle: trip.homeDestinationTitle,
                            onBack: onBack
                        )

                        ScrollView(showsIndicators: false) {
                            editorCard
                                .padding(.horizontal, 18)
                                .padding(.top, 4)
                                .padding(.bottom, 24)
                        }
                        .tripnestScrollBounceWhenNeeded()
                    }
                } else {
                    missingTripState
                }
            }
        }
        .swipeBack(enabled: !focused, onBack: onBack)
        .onAppear {
            if let tripId { store.selectTrip(id: tripId) }
            loadIfNeeded()
        }
        .onChange(of: text) { _, newValue in
            let clamped = clampLines(newValue)
            if clamped != newValue { text = clamped }
            if let id = trip?.id { store.setTripNotes(id: id, notes: clamped) }
        }
    }

    private var editorCard: some View {
        TCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("MES NOTES")
                        .font(.tText(11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.tTextMute)
                    Spacer()
                    Text("\(lineCount)/\(Self.maxLines) lignes")
                        .font(.tText(11, weight: .semibold))
                        .foregroundColor(lineCount >= Self.maxLines ? .tRose : .tTextMute)
                        .monospacedDigit()
                }

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Écris tes notes pour ce voyage : adresses, idées, rappels…")
                            .font(.tText(14))
                            .foregroundColor(.tTextMute)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $text)
                        .font(.tText(14))
                        .foregroundColor(.tText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 320)
                        .focused($focused)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Terminé") { focused = false }
                    .font(.tText(15, weight: .bold))
                    .foregroundColor(.tAccent2)
            }
        }
    }

    private var missingTripState: some View {
        VStack(spacing: 0) {
            TripSubpageTopBar(title: "Notes", subtitle: "Voyage introuvable", onBack: onBack)
            Spacer()
            TIcon(glyph: .edit, size: 36, stroke: .tAccent2)
            Text("Impossible de charger ce voyage.")
                .font(.tText(15, weight: .semibold))
                .padding(.top, 12)
            Spacer()
        }
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        text = trip?.notes ?? ""
    }

    private func clampLines(_ value: String) -> String {
        var lines = value.components(separatedBy: .newlines)
        if lines.count > Self.maxLines {
            lines = Array(lines.prefix(Self.maxLines))
            return lines.joined(separator: "\n")
        }
        return value
    }
}
