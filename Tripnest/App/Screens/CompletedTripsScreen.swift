import SwiftUI

struct CompletedTripsScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onEditTrip: (String) -> Void = { _ in }
    var onDeleteTrip: (String) -> Void = { _ in }

    @State private var selectedTripId: String?

    private var completedTrips: [Trip] {
        store.trips
            .filter { $0.status == .done }
            .sorted { lhs, rhs in
                let l = lhs.departureDate ?? .distantPast
                let r = rhs.departureDate ?? .distantPast
                return l > r
            }
    }

    var body: some View {
        ScreenShell(motif: false) {
            VStack(spacing: 0) {
                tripsHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        completedSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                    .tripnestTabBarScrollPadding()
                }
                .tripnestScrollBounceWhenNeeded()
            }
            .safeAreaInset(edge: .bottom) {
                TabBar(active: .trips, onChange: onNav)
            }
            .swipeBack(enabled: true, onBack: { onNav(.trips) })
        }
        .onAppear { syncSelectedTrip() }
        .onChange(of: store.trips.count) { _, _ in syncSelectedTrip() }
        .onChange(of: store.trips.map(\.status)) { _, _ in syncSelectedTrip() }
        .animation(.easeOut(duration: 0.2), value: selectedTripId)
    }

    // MARK: - Header

    private var tripsHeader: some View {
        HStack(alignment: .top) {
            Button(action: { onNav(.trips) }) {
                IconBtn(glyph: .back)
            }
            .buttonStyle(TripnestPressStyle())
            Text(L("Voyages faits"))
                .font(.tDisplay(24))
                .tracking(-0.6)
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - Content

    @ViewBuilder
    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                sectionLabel(L("VOYAGES FAITS"), dotColor: .tGold, color: .tGold)
                Spacer()
                Text("\(completedTrips.count)")
                    .font(.tText(12, weight: .bold))
                    .foregroundColor(.tGold)
                    .monospacedDigit()
            }

            if completedTrips.isEmpty {
                emptyState
            } else {
                ForEach(completedTrips) { trip in
                    TripRow(
                        t: trip,
                        isSelected: false,
                        onTap: { openTripDetail(trip) },
                        onRestore: { restoreTrip(trip) },
                        primaryTicket: store.primaryTicket(for: trip)
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        TCard(padding: 20) {
            VStack(spacing: 10) {
                TIcon(glyph: .globe, size: 28, stroke: .tGold)
                Text(L("Aucun voyage terminé"))
                    .font(.tText(16, weight: .bold))
                Text(L("Coche « Voyage fait » sur un voyage en cours pour le retrouver ici."))
                    .font(.tText(13))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func openTripDetail(_ trip: Trip) {
        store.selectTrip(id: trip.id)
        selectedTripId = trip.id
        Haptics.selection()
        onNav(.trip)
    }

    private func restoreTrip(_ trip: Trip) {
        store.setTripCompleted(id: trip.id, completed: false)
        if selectedTripId == trip.id { selectedTripId = nil }
        Haptics.success()
    }

    private func syncSelectedTrip() {
        guard let id = selectedTripId else { return }
        if !completedTrips.contains(where: { $0.id == id }) {
            selectedTripId = nil
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, dotColor: Color? = nil, color: Color = .tTextMute) -> some View {
        HStack(spacing: 6) {
            if let dotColor {
                Circle().fill(dotColor).frame(width: 6, height: 6)
            }
            Text(text)
                .font(.tText(11, weight: .bold))
                .tracking(1.2)
                .foregroundColor(color)
        }
    }
}
