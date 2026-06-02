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
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Voyages")
                    .font(.tDisplay(30))
                    .tracking(-0.6)

                Text(headerSubtitle)
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.tTextMute)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 12)

            Button(action: { onNav(.newTrip) }) {
                TIcon(glyph: .plus, size: 18, stroke: .white, strokeWidth: 2.2)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: [.tAccent2, .tAccentDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                    .shadow(color: Color.tAccent.opacity(0.32), radius: 14, y: 8)
            }
            .buttonStyle(TripnestPressStyle())
            .accessibilityLabel("Créer un voyage")
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var headerSubtitle: String {
        if ongoingTrips.isEmpty {
            return completedCount == 0 ? "Prépare ton prochain départ." : "\(completedCount) voyage\(completedCount > 1 ? "s" : "") archivé\(completedCount > 1 ? "s" : "")"
        }
        return "\(ongoingTrips.count) voyage\(ongoingTrips.count > 1 ? "s" : "") en cours"
    }

    // MARK: - Voyages en cours (contenu principal)

    private var ongoingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if ongoingTrips.isEmpty {
                emptyOngoingState
            } else {
                HStack(alignment: .firstTextBaseline) {
                    sectionLabel("EN COURS", color: .tMint)
                    Spacer()
                    Text("\(ongoingTrips.count)")
                        .font(.tText(12, weight: .bold))
                        .foregroundColor(.tMint)
                        .monospacedDigit()
                }

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

    private var emptyOngoingState: some View {
        TCard(
            padding: 20,
            radius: 22,
            bg: AnyShapeStyle(
                LinearGradient(colors: [
                    Color.tAccent2.opacity(0.16),
                    Color.tBlue.opacity(0.08),
                    Color.tSurface
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            ),
            border: Color.tBorderStrong
        ) {
            VStack(alignment: .leading, spacing: 16) {
                IconBubble(glyph: .plane, color: .tBlue, size: 48)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Aucun voyage actif")
                        .font(.tDisplay(22))
                        .tracking(-0.4)
                    Text("Crée ton prochain départ et retrouve ici le planning, le budget, les spots et les souvenirs.")
                        .font(.tText(13))
                        .foregroundColor(.tTextMute)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: { onNav(.newTrip) }) {
                    HStack(spacing: 8) {
                        TIcon(glyph: .plus, size: 15, stroke: .white, strokeWidth: 2.1)
                        Text("Créer un voyage")
                            .font(.tText(14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(colors: [.tAccent2, .tAccentDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                }
                .buttonStyle(TripnestPressStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Voyages passés (page séparée)

    private var pastTripsEntry: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TERMINÉS")

            Button(action: { onNav(.completedTrips) }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(colors: [
                                Color.tGold.opacity(0.24),
                                Color.tRose.opacity(0.12)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing))
                        TIcon(glyph: .globe, size: 23, stroke: .tGold, strokeWidth: 2)
                    }
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Voyages passés")
                            .font(.tText(17, weight: .bold))
                            .foregroundColor(.tText)
                        Text(completedCount == 0
                             ? "Souvenirs, spots, budget et planning"
                             : "\(completedCount) voyage\(completedCount > 1 ? "s" : "") terminé\(completedCount > 1 ? "s" : "")")
                            .font(.tText(12))
                            .foregroundColor(.tTextMute)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)

                    TIcon(glyph: .arrow, size: 15, stroke: .tGold)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.tGold.opacity(0.10)))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient(colors: [
                            Color.tGold.opacity(0.10),
                            Color.tSurface
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.tGold.opacity(0.28), lineWidth: 1)
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

    private var showsTripActions: Bool {
        isSelected && (onPlan != nil || onBudget != nil || onSouvenirs != nil || onSpots != nil)
    }

    private var pct: Int {
        guard t.budget > 0 else { return t.spent > 0 ? 101 : 0 }
        return Int(Double(t.spent) / Double(t.budget) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                compactHeader
            }
            .buttonStyle(TripnestPressStyle())

            tripActionChips

            HStack(spacing: 10) {
                if let onSetCompleted {
                    TripDoneStatusControl(isDone: t.status == .done, style: .card, onChange: onSetCompleted)
                }

                Spacer()

                if let onModify {
                    Button(action: onModify) {
                        Text("Modifier")
                            .font(.tText(12, weight: .bold))
                            .foregroundColor(.tAccent2)
                    }
                    .buttonStyle(.plain)
                }

                if let onDelete {
                    Button(action: onDelete) {
                        Text("Supprimer")
                            .font(.tText(12, weight: .bold))
                            .foregroundColor(.tRose)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.tSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? Color.tAccent2.opacity(0.48) : Color.tBorder, lineWidth: 1)
        )
        .shadow(color: Color.tBg0.opacity(0.18), radius: 10, x: 0, y: 6)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityLabel(isSelected ? "\(t.homeDestinationTitle), sélectionné" : t.homeDestinationTitle)
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .task(id: t.routeMapLoadKey) {
            outboundTravelDuration = await TripTravelDuration.outboundLeg(trip: t, ticket: primaryTicket)
            returnTravelDuration = await TripTravelDuration.returnLeg(trip: t)
        }
    }

    private var compactHeader: some View {
        HStack(spacing: 12) {
            TripPhoto(
                destination: t.dest,
                country: t.country,
                hue: t.hue,
                radius: 14,
                showBorder: false,
                coverKind: t.coverKind,
                tripId: t.id
            )
            .frame(width: 78, height: 78)
            .clipped()
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tBorderStrong, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(statusLabel.capitalized)
                        .font(.tText(11, weight: .bold))
                        .foregroundColor(statusColor)
                }

                Text(t.homeDestinationTitle)
                    .font(.tText(18, weight: .bold))
                    .foregroundColor(.tText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(t.homeDateLine)
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.tTextMute)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 4) {
                TransportModeGlyph(mode: t.transportMode, size: 18, stroke: .tAccent2)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.tAccent2.opacity(0.12)))

                Text("\(t.spent)\(defaultCurrency.currencySymbol)")
                    .font(.tText(11, weight: .bold))
                    .foregroundColor(.tTextMute)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var editDeleteActions: some View {
        HStack(spacing: 10) {
            if let onModify {
                Button(action: onModify) {
                    actionButtonLabel("Modifier", glyph: .edit, color: .tAccent2)
                }
                .buttonStyle(.plain)
            }

            if let onDelete {
                Button(action: onDelete) {
                    HStack(spacing: 7) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Supprimer")
                            .font(.tText(13, weight: .bold))
                    }
                    .foregroundColor(.tRose)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.tRose.opacity(0.10))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func actionButtonLabel(_ title: String, glyph: TIcon.Glyph, color: Color) -> some View {
        HStack(spacing: 7) {
            TIcon(glyph: glyph, size: 14, stroke: color)
            Text(title)
                .font(.tText(13, weight: .bold))
        }
        .foregroundColor(color)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.12))
        )
    }

    private var tripActionChips: some View {
        HStack(spacing: 8) {
            if let onPlan {
                TripRowActionChip(title: "Planning", glyph: .cal, accent: .tMint, action: onPlan)
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
    }

    private var rowHeader: some View {
        ZStack(alignment: .bottomLeading) {
            TripPhoto(
                destination: t.dest,
                country: t.country,
                hue: t.hue,
                radius: 0,
                showBorder: false,
                coverKind: t.coverKind,
                tripId: t.id
            )
            .frame(maxWidth: .infinity)
            .frame(height: 156)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.14), location: 0),
                    .init(color: .black.opacity(0.24), location: 0.42),
                    .init(color: .black.opacity(0.84), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    statusPill

                    Spacer(minLength: 8)

                    HStack(spacing: 8) {
                        if t.photoCount > 0 {
                            Label("\(t.photoCount)", systemImage: "photo")
                                .font(.tText(10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.black.opacity(0.34)))
                        }

                        if let onGoToDestination {
                            Button(action: onGoToDestination) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color.black.opacity(0.34)))
                                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Voir sur la planète")
                        }

                        if isSelected, let onClose {
                            Button(action: onClose) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color.black.opacity(0.34)))
                                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Fermer")
                        }
                    }
                }

                Spacer(minLength: 0)

                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(t.homeDestinationTitle)
                            .font(.tDisplay(26))
                            .tracking(-0.5)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)

                        Text(t.tripsListRouteLine)
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.76))
                            .lineLimit(2)
                            .minimumScaleFactor(0.84)
                    }

                    Spacer(minLength: 6)

                    TransportModeGlyph(mode: t.transportMode, size: 20, stroke: .white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.white.opacity(0.14)))
                        .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                }
            }
            .padding(16)
        }
        .frame(height: 156)
    }

    private var statusPill: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .shadow(color: statusColor.opacity(0.75), radius: 5)
            Text(statusLabel)
                .font(.tText(10, weight: .heavy))
                .tracking(1.1)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.38)))
        .overlay(Capsule().stroke(statusColor.opacity(0.30), lineWidth: 1))
    }

    private var statusColor: Color {
        switch t.status {
        case .active: return .tMint
        case .planned: return .tBlue
        case .done: return .tGold
        }
    }

    private var statusLabel: String {
        switch t.status {
        case .active: return "EN COURS"
        case .planned: return "PLANIFIÉ"
        case .done: return "TERMINÉ"
        }
    }

    private var scheduleSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            scheduleLine(glyph: .plane, text: departureScheduleLine, color: .tBlue)
            if let returnLine = returnScheduleLine {
                scheduleLine(glyph: .back, text: returnLine, color: .tGold)
            }
        }
    }

    private func scheduleLine(glyph: TIcon.Glyph, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            TIcon(glyph: glyph, size: 14, stroke: color, strokeWidth: 2)
                .frame(width: 22, height: 22)
                .background(Circle().fill(color.opacity(0.12)))
            Text(text)
                .font(.tText(11, weight: .semibold))
                .foregroundColor(.tTextMute)
                .fixedSize(horizontal: false, vertical: true)
        }
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
        VStack(spacing: 12) {
            scheduleSummary

            HStack(alignment: .center, spacing: 10) {
                if let onSetCompleted {
                    TripDoneStatusControl(isDone: t.status == .done, style: .card, onChange: onSetCompleted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(pct)%")
                        .font(.tText(15, weight: .heavy))
                        .foregroundColor(pct > 100 ? .tRose : .tAccent2)
                        .monospacedDigit()
                    Text("\(t.spent)\(defaultCurrency.currencySymbol) / \(t.budget)\(defaultCurrency.currencySymbol)")
                        .font(.tText(10, weight: .semibold))
                        .foregroundColor(.tTextMute)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0xa78bfa, opacity: 0.12)).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(
                            colors: pct > 100 ? [.tRose, .tRose.opacity(0.75)] : [.tAccent2, .tBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: min(geo.size.width, geo.size.width * CGFloat(min(100, pct)) / 100), height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(14)
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
