import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onEditTrip: (String) -> Void = { _ in }
    var onDeleteTrip: (String) -> Void = { _ in }

    @AppStorage("tripnest.profile.name") private var profileName: String = ""
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationStatus: TripnestNotificationStatus = .notDetermined
    @State private var showNotificationSettingsAlert = false
    @State private var showHomeInfoSheet = false

    private var profileFirstName: String {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.split(separator: " ").first, !first.isEmpty else { return "" }
        return String(first)
    }

    /// Salutation selon l'heure locale du téléphone.
    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Bonjour"
        case 12..<18:
            return "Bon après-midi"
        default:
            return "Bonsoir"
        }
    }

    private var initials: String {
        let parts = profileName.trimmingCharacters(in: .whitespaces).split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "T"
        let last = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private var sortedTrips: [Trip] {
        store.trips.sorted { lhs, rhs in
            func sortRank(_ status: Trip.Status) -> Int {
                switch status {
                case .active: return 0
                case .planned: return 1
                case .done: return 2
                }
            }
            let lRank = sortRank(lhs.status)
            let rRank = sortRank(rhs.status)
            if lRank != rRank { return lRank < rRank }
            let l = lhs.departureDate ?? .distantFuture
            let r = rhs.departureDate ?? .distantFuture
            return l < r
        }
    }

    private var ongoingTrips: [Trip] {
        sortedTrips.filter { $0.status != .done }
    }

    private var selectedTripId: String? {
        store.selectedTripId ?? store.activeTrip?.id
    }

    private var displayedTrip: Trip? {
        if let id = selectedTripId,
           let match = ongoingTrips.first(where: { $0.id == id }) {
            return match
        }
        return ongoingTrips.first
    }

    var body: some View {
        ScreenShell(motif: false) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if sortedTrips.isEmpty {
                            emptyHome
                        } else if ongoingTrips.isEmpty {
                            noOngoingTripsHint
                        } else {
                            if ongoingTrips.count > 1 {
                                ongoingTripsHeader
                                tripSwitcher
                            }
                            if let t = displayedTrip {
                                TripHomeHeroCard(
                                    trip: t,
                                    onTap: { onEditTrip(t.id) }
                                )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                tripActions(t)
                                newTripButton
                                TripRouteMapCard(trip: t)
                                    .id(t.routeMapLoadKey)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            if let trip = displayedTrip,
                               trip.transportMode.supportsTravelTicket,
                               let ticket = store.primaryTicket(for: trip) {
                                HomeTravelTicketCard(ticket: ticket, mode: trip.transportMode) {
                                    onNav(.flights)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .tripnestTabBarScrollPadding()
                }
                .tripnestScrollBounceWhenNeeded()
            }
            .safeAreaInset(edge: .bottom) {
                TabBar(active: .home, onChange: onNav)
            }
        }
        .task { await refreshNotificationStatus() }
        .onAppear { syncOngoingTripSelection() }
        .onChange(of: store.trips.count) { _, _ in syncOngoingTripSelection() }
        .onChange(of: store.trips.lazy.filter { $0.status != .done }.count) { _, _ in syncOngoingTripSelection() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshNotificationStatus() } }
        }
        .alert("Notifications désactivées", isPresented: $showNotificationSettingsAlert) {
            Button("Ouvrir Réglages") {
                Task { await TripnestNotifications.activate() }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Active les notifications Tripnest dans Réglages pour recevoir tes rappels de voyage.")
        }
        .sheet(isPresented: $showHomeInfoSheet) {
            HomeTabsInfoSheet()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                        .font(.tText(13))
                        .foregroundColor(.tTextMute)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(profileFirstName.isEmpty ? timeGreeting : "\(timeGreeting),")
                            .font(.tDisplay(24, weight: .bold))
                            .tracking(-0.5)
                        if !profileFirstName.isEmpty {
                            Text(profileFirstName)
                                .font(.tDisplay(24, weight: .bold))
                                .tracking(-0.5)
                                .foregroundColor(.tAccent2)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 8)
                HStack(spacing: 8) {
                    Button {
                        showHomeInfoSheet = true
                        Haptics.selection()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.tText)
                            .frame(width: 30, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.tSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.tBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("À quoi servent les onglets")

                    Button(action: activateNotifications) {
                        IconBtn(
                            glyph: .bell,
                            dot: !notificationStatus.isEnabled,
                            stroke: notificationStatus.isEnabled ? .white : .tText,
                            strokeWidth: notificationStatus.isEnabled ? 2 : 1.75
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        notificationStatus.isEnabled
                            ? "Notifications activées"
                            : "Activer les notifications"
                    )
                    Avatar(initials: initials)
                }
            }

        }
    }

    private var ongoingTripsHeader: some View {
        HStack {
            Text("Voyages en cours")
                .font(.tText(12, weight: .bold))
                .tracking(0.6)
                .foregroundColor(.tTextMute)
            Spacer()
            Text("\(ongoingTrips.count)")
                .font(.tText(12, weight: .bold))
                .foregroundColor(.tAccent2)
                .monospacedDigit()
        }
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await TripnestNotifications.currentStatus()
    }

    private func activateNotifications() {
        Task {
            let before = notificationStatus
            let after = await TripnestNotifications.activate()
            notificationStatus = after
            if after.isEnabled {
                Haptics.success()
            } else if before == .denied || after == .denied {
                showNotificationSettingsAlert = true
            }
        }
    }

    private var emptyHome: some View {
        TCard(padding: 22, glow: true) {
            VStack(spacing: 14) {
                TripnestLogo(size: 72, glow: false)
                Text("Aucun voyage pour le moment")
                    .font(.tDisplay(24))
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                Text("Planifie ton premier trajet en quelques étapes.")
                    .font(.tText(14))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                CTA(label: "Créer un voyage", action: { onNav(.newTrip) })
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func syncOngoingTripSelection() {
        guard !ongoingTrips.isEmpty else { return }
        if let id = selectedTripId, ongoingTrips.contains(where: { $0.id == id }) {
            return
        }
        if let first = ongoingTrips.first {
            store.selectTrip(id: first.id)
        }
    }

    private var noOngoingTripsHint: some View {
        TCard(padding: 20) {
            VStack(spacing: 12) {
                TIcon(glyph: .globe, size: 28, stroke: .tGold)
                Text("Tous tes voyages sont archivés")
                    .font(.tText(16, weight: .bold))
                Text("Retrouve-les dans l’onglet Voyages → Voyages passés, ou crée un nouveau voyage.")
                    .font(.tText(13))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                CTA(label: "Voir l’onglet Voyages", secondary: true, action: { onNav(.trips) })
                CTA(label: "Créer un voyage", action: { onNav(.newTrip) })
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var tripSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ongoingTrips) { trip in
                    tripChip(trip)
                }
            }
        }
    }

    private enum TripChipLayout {
        static let height: CGFloat = 56
        static let minWidth: CGFloat = 148
        static let maxWidth: CGFloat = 220
    }

    private func tripChip(_ trip: Trip) -> some View {
        let isSelected = trip.id == selectedTripId
        let detailColor = isSelected ? Color.white.opacity(0.85) : Color.tTextMute
        return Button {
            store.selectTrip(id: trip.id)
            Haptics.selection()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.homeDestinationTitle)
                    .font(.tText(13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text(trip.hasReturn ? trip.homeChipDateLine : trip.homeDateLine)
                    .font(.tText(11))
                    .foregroundColor(detailColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(isSelected ? .white : .tText)
            .frame(minWidth: TripChipLayout.minWidth, maxWidth: TripChipLayout.maxWidth, alignment: .leading)
            .frame(height: TripChipLayout.height, alignment: .leading)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.tAccent : Color.tSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.tBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TripnestPressStyle())
    }

    private var newTripButton: some View {
        Button(action: { onNav(.newTrip) }) {
            HStack(spacing: 8) {
                TIcon(glyph: .plus, size: 16, stroke: .tAccent2, strokeWidth: 2.2)
                Text("Nouveau voyage")
                    .font(.tText(14, weight: .semibold))
            }
            .foregroundColor(.tAccent2)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tAccent2.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(TripnestPressStyle())
    }

    private func tripActions(_ t: Trip) -> some View {
        HStack(spacing: 10) {
            Button(action: { onEditTrip(t.id) }) {
                HStack(spacing: 6) {
                    TIcon(glyph: .edit, size: 16, stroke: .tAccent2)
                    Text("Modifier")
                        .font(.tText(13, weight: .semibold))
                }
                .foregroundColor(.tAccent2)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.tAccent2.opacity(0.10))
                )
            }
            .buttonStyle(TripnestPressStyle())

            Button(action: { onDeleteTrip(t.id) }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Supprimer")
                        .font(.tText(13, weight: .semibold))
                }
                .foregroundColor(.tRose)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.tRose.opacity(0.08))
                )
            }
            .buttonStyle(TripnestPressStyle())
        }
    }

}

struct DashedDivider: View {
    var body: some View {
        Canvas { ctx, rect in
            var p = Path()
            p.move(to: CGPoint(x: 0, y: rect.height / 2))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            ctx.stroke(p, with: .color(.tBorder),
                       style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 1)
    }
}

struct HomeTabsInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Petit rappel sur les onglets de Tripnest.")
                        .font(.tText(14))
                        .foregroundColor(.tTextMute)

                    infoCard(
                        title: "Accueil",
                        icon: .home,
                        description: "Vue d'ensemble de ton voyage en cours : carte, résumé du trajet et accès rapide aux billets."
                    )

                    infoCard(
                        title: "Voyages",
                        icon: .globe,
                        description: "Tous tes voyages planifiés ou réalisés. C'est ici que tu peux en créer un nouveau, le modifier, l'archiver et accéder au budget, aux souvenirs ou aux spots."
                    )

                    infoCard(
                        title: "Spots",
                        icon: .spot,
                        description: "Tes lieux importants pour le voyage sélectionné : restaurants, hôtels, activités… Chaque spot est relié à un voyage."
                    )

                    infoCard(
                        title: "Budget",
                        icon: .wallet,
                        description: "Suivi des dépenses du voyage sélectionné : catégories, total dépensé et budget restant."
                    )
                }
                .padding(18)
            }
            .background(Color.tBg0.ignoresSafeArea())
            .navigationTitle("Comment fonctionne Tripnest ?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func infoCard(title: String, icon: TIcon.Glyph, description: String) -> some View {
        TCard(padding: 16) {
            HStack(alignment: .top, spacing: 12) {
                TIcon(glyph: icon, size: 22, stroke: .tAccent2)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.tText(15, weight: .bold))
                    Text(description)
                        .font(.tText(13))
                        .foregroundColor(.tTextMute)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
