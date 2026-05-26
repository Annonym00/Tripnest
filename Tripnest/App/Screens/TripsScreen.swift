import SwiftUI

struct TripsScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onEditTrip: (String) -> Void = { _ in }
    var onDeleteTrip: (String) -> Void = { _ in }

    @State private var selectedTripId: String?
    @State private var tripPendingCompletion: Trip?
    @State private var showCompleteTripAlert = false

    private var ongoingTrips: [Trip] {
        store.trips
            .filter { $0.status != .done }
            .sorted { lhs, rhs in
                let l = lhs.departureDate ?? .distantFuture
                let r = rhs.departureDate ?? .distantFuture
                return l < r
            }
    }

    private var completedCount: Int {
        store.trips.filter { $0.status == .done }.count
    }

    var body: some View {
        ScreenShell(motif: false) {
            VStack(spacing: 0) {
                tripsHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        ongoingSection
                        pastTripsEntry
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
        }
        .onAppear { syncSelectedTrip() }
        .onChange(of: store.trips.count) { _, _ in syncSelectedTrip() }
        .onChange(of: store.trips.lazy.filter { $0.status != .done }.count) { _, _ in syncSelectedTrip() }
        .animation(.easeOut(duration: 0.2), value: selectedTripId)
        .alert("Archiver ce voyage ?", isPresented: $showCompleteTripAlert) {
            Button("Annuler", role: .cancel) { tripPendingCompletion = nil }
            Button("Oui, archiver") { confirmTripCompletion() }
        } message: {
            if let trip = tripPendingCompletion {
                Text("« \(trip.homeDestinationTitle) » sera déplacé dans Voyages passés.")
            }
        }
    }

    private var tripsHeader: some View {
        HStack(alignment: .top) {
            Text("Voyages")
                .font(.tDisplay(26))
                .tracking(-0.6)
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - Voyages en cours (contenu principal)

    private var ongoingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if ongoingTrips.isEmpty {
                TCard(padding: 20) {
                    VStack(spacing: 10) {
                        TIcon(glyph: .plane, size: 28, stroke: .tAccent2)
                        Text("Aucun voyage actif")
                            .font(.tText(16, weight: .bold))
                        Text("Pour créer un voyage, utilise l’onglet Accueil.")
                            .font(.tText(13))
                            .foregroundColor(.tTextMute)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text("Appuie sur un voyage pour le sélectionner et voir les actions.")
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)

                ForEach(ongoingTrips) { trip in
                    TripRow(
                        t: trip,
                        isSelected: trip.id == selectedTripId,
                        onTap: { toggleTripSelection(trip) },
                        onClose: { selectedTripId = nil },
                        onModify: { onEditTrip(trip.id) },
                        onPlan: { openPlanning(for: trip) },
                        onBudget: { openBudget(for: trip) },
                        onSouvenirs: { openSouvenirs(for: trip) },
                        onSpots: { openSpots(for: trip) },
                        onDelete: { onDeleteTrip(trip.id) },
                        onSetCompleted: { requestTripCompletionChange(for: trip, completed: $0) },
                        primaryTicket: store.primaryTicket(for: trip)
                    )
                }
            }
        }
    }

    // MARK: - Voyages passés (page séparée)

    private var pastTripsEntry: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TERMINÉS")

            Button(action: { onNav(.completedTrips) }) {
                HStack(spacing: 14) {
                    TIcon(glyph: .globe, size: 22, stroke: .tGold)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.tGold.opacity(0.14))
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Voyages passés")
                            .font(.tText(16, weight: .bold))
                            .foregroundColor(.tText)
                        Text(completedCount == 0
                             ? "Souvenirs, spots, budget et planning"
                             : "\(completedCount) voyage\(completedCount > 1 ? "s" : "") terminé\(completedCount > 1 ? "s" : "")")
                            .font(.tText(12))
                            .foregroundColor(.tTextMute)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)

                    TIcon(glyph: .arrow, size: 14, stroke: .tTextMute)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.tSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.tGold.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(TripnestPressStyle())
        }
    }

    private func toggleTripSelection(_ trip: Trip) {
        if selectedTripId == trip.id {
            selectedTripId = nil
        } else {
            selectedTripId = trip.id
            store.selectTrip(id: trip.id)
        }
        Haptics.selection()
    }

    private func openPlanning(for trip: Trip) {
        store.selectTrip(id: trip.id)
        onNav(.tripPlanning)
    }

    private func openBudget(for trip: Trip) {
        store.selectTrip(id: trip.id)
        onNav(.tripBudget)
    }

    private func openSouvenirs(for trip: Trip) {
        store.selectTrip(id: trip.id)
        onNav(.tripSouvenirs)
    }

    private func openSpots(for trip: Trip) {
        store.selectTrip(id: trip.id)
        onNav(.spots)
    }

    private func syncSelectedTrip() {
        guard let id = selectedTripId else { return }
        if !ongoingTrips.contains(where: { $0.id == id }) {
            selectedTripId = nil
        }
    }

    private func requestTripCompletionChange(for trip: Trip, completed: Bool) {
        if completed {
            tripPendingCompletion = trip
            showCompleteTripAlert = true
        } else {
            store.setTripCompleted(id: trip.id, completed: false)
        }
    }

    private func confirmTripCompletion() {
        guard let trip = tripPendingCompletion else { return }
        store.setTripCompleted(id: trip.id, completed: true)
        if selectedTripId == trip.id { selectedTripId = nil }
        tripPendingCompletion = nil
        Haptics.success()
    }

    private func sectionLabel(_ text: String, color: Color = .tTextMute) -> some View {
        Text(text)
            .font(.tText(11, weight: .bold))
            .tracking(1.2)
            .foregroundColor(color)
    }
}

// MARK: - Ligne voyage (liste)

struct TripRow: View {
    let t: Trip
    var isSelected: Bool = false
    var onTap: () -> Void = {}
    var onClose: (() -> Void)? = nil
    var onModify: (() -> Void)? = nil
    var onPlan: (() -> Void)? = nil
    var onBudget: (() -> Void)? = nil
    var onSouvenirs: (() -> Void)? = nil
    var onSpots: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onSetCompleted: ((Bool) -> Void)? = nil
    var onGoToDestination: (() -> Void)? = nil
    /// Pass the trip's primary ticket so TripRow doesn't need a store subscription.
    var primaryTicket: Flight? = nil
    @State private var outboundTravelDuration: String?
    @State private var returnTravelDuration: String?
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"

    private var hasMenu: Bool { onEdit != nil || onDelete != nil }
    private var showsTripActions: Bool {
        isSelected && (onPlan != nil || onBudget != nil || onSouvenirs != nil || onSpots != nil)
    }

    private var pct: Int {
        guard t.budget > 0 else { return t.spent > 0 ? 101 : 0 }
        return Int(Double(t.spent) / Double(t.budget) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isSelected, let onClose {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.tTextMute)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.tSurface))
                            .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Fermer")
                }
                .padding(.bottom, 4)
            }

            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 0) {
                    Button(action: onTap) {
                        rowHeader
                    }
                    .buttonStyle(TripnestPressStyle())

                    if isSelected, onModify != nil || onDelete != nil {
                        HStack(spacing: 10) {
                            if let onModify {
                                Button(action: onModify) {
                                    HStack(spacing: 6) {
                                        TIcon(glyph: .edit, size: 14, stroke: .tAccent2)
                                        Text("Modifier")
                                            .font(.tText(13, weight: .semibold))
                                    }
                                    .foregroundColor(.tAccent2)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.tAccent2.opacity(0.10))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            if let onDelete {
                                Button(action: onDelete) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Supprimer")
                                            .font(.tText(13, weight: .semibold))
                                    }
                                    .foregroundColor(.tRose)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.tRose.opacity(0.08))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                    }

                    rowFooter

                    if showsTripActions {
                        tripActionChips
                    }
                }
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.tSurface))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.tBorder, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if isSelected {
                        TripSelectedBadge()
                            .padding(10)
                    }
                }
                .accessibilityLabel(isSelected ? "\(t.homeDestinationTitle), sélectionné" : t.homeDestinationTitle)

                if let onGoToDestination {
                    Button(action: onGoToDestination) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.tAccent2)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.tAccent2.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Voir sur la planète")
                }
            }
        }
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .task(id: t.routeMapLoadKey) {
            outboundTravelDuration = await TripTravelDuration.outboundLeg(trip: t, ticket: primaryTicket)
            returnTravelDuration = await TripTravelDuration.returnLeg(trip: t)
        }
    }

    private var tripActionChips: some View {
        HStack(spacing: 8) {
            if let onPlan {
                TripRowActionChip(title: "Planifier", glyph: .cal, accent: .tMint, action: onPlan)
            }
            if let onBudget {
                TripRowActionChip(title: "Budget", glyph: .wallet, accent: .tBlue, action: onBudget)
            }
            if let onSouvenirs {
                TripRowActionChip(title: "Souvenirs", glyph: .gallery, accent: .tRose, action: onSouvenirs)
            }
            if let onSpots {
                TripRowActionChip(title: "Spots", glyph: .spot, accent: .tAccent2, action: onSpots)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .padding(.top, 4)
    }

    private var tripMenu: some View {
        Menu {
            if let onEdit {
                Button(action: onEdit) {
                    Label("Modifier", systemImage: "pencil")
                }
            }
            if onEdit != nil {
                Divider()
            }
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Supprimer", systemImage: "trash")
                }
            }
        } label: {
            TIcon(glyph: .more, size: 18, stroke: .tTextMute)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0x8b5cf6, opacity: 0.06))
                )
        }
        .buttonStyle(.plain)
    }

    private var rowHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            TripPhoto(
                destination: t.dest,
                country: t.country,
                hue: t.hue,
                radius: 14,
                coverKind: t.coverKind,
                tripId: t.id
            )
            .aspectRatio(TripCoverLayout.aspectRatio, contentMode: .fill)
            .frame(width: 72, height: 72)
            .clipped()

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(t.homeDestinationTitle)
                        .font(.tText(17, weight: .bold))
                        .tracking(-0.3)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if t.photoCount > 0 {
                        Label("\(t.photoCount)", systemImage: "photo")
                            .font(.tText(10, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                }

                Text(t.tripsListRouteLine)
                    .font(.tText(12))
                    .foregroundColor(.tTextMute)
                    .fixedSize(horizontal: false, vertical: true)

                Text(departureScheduleLine)
                    .font(.tText(11, weight: .semibold))
                    .foregroundColor(.tTextMute)
                    .fixedSize(horizontal: false, vertical: true)

                if let returnLine = returnScheduleLine {
                    Text(returnLine)
                        .font(.tText(11, weight: .semibold))
                        .foregroundColor(.tTextMute)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
    }

    private var departureScheduleLine: String {
        var line = t.tripsListDepartureLabel
        if let duration = outboundTravelDuration {
            line += " · \(duration) d'aller"
        }
        return line
    }

    private var returnScheduleLine: String? {
        guard var line = t.tripsListReturnLabel else { return nil }
        if let duration = returnTravelDuration {
            line += " · \(duration) de retour"
        }
        return line
    }

    private var rowFooter: some View {
        VStack(spacing: 0) {
            Divider().background(Color.tBorder).padding(.horizontal, 14)

            HStack(spacing: 10) {
                if let onSetCompleted {
                    TripDoneStatusControl(isDone: t.status == .done, style: .card, onChange: onSetCompleted)
                }

                Spacer()

                Text("\(t.spent)\(defaultCurrency.currencySymbol) / \(t.budget)\(defaultCurrency.currencySymbol)")
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)

                Text("\(pct)%")
                    .font(.tText(11, weight: .bold))
                    .foregroundColor(pct > 100 ? .tRose : .tAccent2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0xa78bfa, opacity: 0.10)).frame(height: 3)
                    Capsule()
                        .fill(pct > 100 ? Color.tRose : (t.status == .done ? .tTextMute : .tAccent2))
                        .frame(width: min(geo.size.width, geo.size.width * CGFloat(min(100, pct)) / 100), height: 3)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
    }
}

/// Pastille verte + coche blanche (voyage sélectionné).
private struct TripSelectedBadge: View {
    private let fill = Color(hex: 0x4CD964)

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: 22, height: 22)
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(.white)
        }
        .shadow(color: fill.opacity(0.35), radius: 4, y: 2)
        .accessibilityHidden(true)
    }
}

private struct TripRowActionChip: View {
    let title: String
    let glyph: TIcon.Glyph
    let accent: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                TIcon(glyph: glyph, size: 16, stroke: accent)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(accent.opacity(0.12))
                    )
                Text(title)
                    .font(.tText(10, weight: .semibold))
                    .foregroundColor(.tText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(TripnestPressStyle())
    }
}
