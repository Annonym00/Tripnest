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
            .overlay(alignment: .bottom) {
                TabBar(active: .trips, onChange: onNav)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .onAppear { syncSelectedTrip() }
        .onChange(of: store.trips.count) { _, _ in syncSelectedTrip() }
        .onChange(of: ongoingTrips.count) { _, _ in syncSelectedTrip() }
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
                        Text("Pour créer un voyage, utilise l'onglet Accueil.")
                            .font(.tText(13))
                            .foregroundColor(.tTextMute)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text("Appuie sur un voyage pour voir tous ses détails.")
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)

                ForEach(ongoingTrips) { trip in
                    TripRow(
                        t: trip,
                        isSelected: false,
                        onTap: { openTripDetail(trip) },
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
                .tripnestBubbleChrome(radius: 18)
            }
            .buttonStyle(TripnestPressStyle())
        }
    }

    private func openTripDetail(_ trip: Trip) {
        store.selectTrip(id: trip.id)
        selectedTripId = trip.id
        Haptics.selection()
        onNav(.trip)
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
    var onRestore: (() -> Void)? = nil
    var onGoToDestination: (() -> Void)? = nil
    /// Pass the trip's primary ticket so TripRow doesn't need a store subscription.
    var primaryTicket: Flight? = nil
    @EnvironmentObject private var store: TripStore
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

                    if showsTripActions {
                        tripActionChips
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.tSurface, Color.tSurfaceStrong],
                            startPoint: .top, endPoint: .bottom))
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .tripnestBubbleChrome(radius: 20)
                .overlay(alignment: .topLeading) {
                    if isSelected {
                        TripSelectedBadge()
                            .padding(10)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if let onSetCompleted, t.status != .done {
                        HStack(alignment: .top, spacing: 6) {
                            tripViewerCounter
                            completionCheckbox(onSetCompleted)
                        }
                        .padding(8)
                    } else if let onRestore, t.status == .done {
                        restoreButton(onRestore)
                            .padding(8)
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
        .task(id: "\(t.id)|\(t.dest)") {
            // Toujours appelé : le catalogue peut corriger un pays/drapeau déjà
            // stocké mais erroné (ex. géocodage US à tort), sans re-géocoder.
            await store.resolveCountryIfNeeded(for: t.id)
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
                        .fill(Color(hex: 0x1c0f36))
                )
        }
        .buttonStyle(.plain)
    }

    private var rowHeader: some View {
        HStack(alignment: .top, spacing: 11) {
            TripPhoto(
                destination: t.dest,
                country: t.country,
                hue: t.hue,
                radius: 14,
                coverKind: t.coverKind,
                tripId: t.id,
                solidColor: t.resolvedCoverColor
            )
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 62, height: 62)
            .clipped()
            .background {
                TripRowAmbilight(trip: t)
                    .frame(width: 80, height: 80)
                    .allowsHitTesting(false)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(t.displayTitle)
                        .font(.tText(17, weight: .bold))
                        .tracking(-0.3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    let flag = t.resolvedFlag
                    if !flag.isEmpty {
                        Text(flag)
                            .font(.system(size: 15))
                    }
                    Spacer(minLength: 4)
                }
                .padding(.trailing, t.status == .done ? 88 : 112)

                HStack(spacing: 8) {
                    statusPill
                    if t.favorite {
                        favoriteTag
                    }
                    if let range = compactDateRange {
                        Text("\(range) · \(t.days)j")
                            .font(.tText(12))
                            .foregroundColor(.tTextMute)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else {
                        Text("\(t.days)j")
                            .font(.tText(12))
                            .foregroundColor(.tTextMute)
                    }
                }

                progressBar

                HStack(spacing: 10) {
                    Text("\(t.spent)\(defaultCurrency.currencySymbol) / \(t.budget)\(defaultCurrency.currencySymbol)")
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                    Spacer()
                    Text("\(pct)%")
                        .font(.tText(14, weight: .bold))
                        .foregroundColor(pct > 100 ? .tRose : .tAccent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0x24173f)).frame(height: 6)
                Capsule()
                    .fill(pct > 100 ? Color.tRose : (t.status == .done ? Color.tTextMute : Color.tAccent))
                    .frame(width: min(geo.size.width, geo.size.width * CGFloat(min(100, pct)) / 100), height: 6)
            }
        }
        .frame(height: 6)
    }

    /// Compteur de vues du voyage partagé.
    private var tripViewerCounter: some View {
        VStack(spacing: 1) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 9, weight: .semibold))
            Text("0")
                .font(.tText(8, weight: .bold))
        }
        .foregroundColor(.tTextMute)
        .frame(width: 24, height: 24)
        .background(Circle().fill(Color.tSurface.opacity(0.95)))
        .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
        .accessibilityLabel("0 personne regarde ce voyage")
    }


    /// Bouton « Archiver » : envoie le voyage dans « Voyages passés ».
    private func completionCheckbox(_ action: @escaping (Bool) -> Void) -> some View {
        Button {
            action(true)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "archivebox")
                    .font(.system(size: 9, weight: .bold))
                Text("Archiver")
                    .font(.tText(10, weight: .bold))
            }
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.tAccent.opacity(0.7)))
            .overlay(Capsule().stroke(Color.tAccent2.opacity(0.5), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Archiver dans les voyages passés")
    }

    /// Bouton « Revenir » : renvoie le voyage dans les voyages en cours.
    private func restoreButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .bold))
                Text("Revenir")
                    .font(.tText(12, weight: .bold))
            }
            .foregroundColor(.tAccent2)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.tAccent2.opacity(0.14)))
            .overlay(Capsule().stroke(Color.tAccent2.opacity(0.4), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remettre dans les voyages en cours")
    }

    private var favoriteTag: some View {
        HStack(spacing: 4) {
            Text("❤️").font(.system(size: 9))
            Text("Coup de cœur")
                .font(.tText(11, weight: .bold))
                .foregroundColor(.tRose)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.tRose.opacity(0.12)))
        .overlay(Capsule().stroke(Color.tRose.opacity(0.3), lineWidth: 1))
    }

    private var statusPill: some View {
        let status = rowStatus
        return HStack(spacing: 5) {
            Circle().fill(status.color).frame(width: 6, height: 6)
            Text(status.text)
                .font(.tText(11, weight: .bold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(status.color.opacity(0.12)))
        .overlay(Capsule().stroke(status.color.opacity(0.3), lineWidth: 1))
    }

    /// Petit mot de statut : « En cours », « Terminé » ou « Dans X jours ».
    private var rowStatus: (text: String, color: Color) {
        let active = Color(hex: 0x4CD964)
        if t.status == .done { return ("Terminé", .tTextMute) }

        let total = max(1, t.planDayCount)
        guard let dep = t.departureDate else { return ("En préparation", .tGold) }

        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let start = cal.startOfDay(for: dep)
        let end: Date = {
            if let ret = t.returnDate { return cal.startOfDay(for: ret) }
            return cal.date(byAdding: .day, value: total - 1, to: start) ?? start
        }()

        if now < start {
            let days = cal.dateComponents([.day], from: now, to: start).day ?? 0
            if days <= 0 { return ("Départ aujourd'hui", active) }
            if days == 1 { return ("Dans 1 jour", .tGold) }
            return ("Dans \(days) jours", .tGold)
        }
        if now > end { return ("Terminé", .tTextMute) }
        let elapsed = (cal.dateComponents([.day], from: start, to: now).day ?? 0) + 1
        let dayN = min(max(1, elapsed), total)
        return ("En cours · Jour \(dayN)/\(total)", active)
    }

    private var compactDateRange: String? {
        let locale = Locale(identifier: "fr_FR")
        guard let start = t.departureDate else { return nil }
        let cal = Calendar.current
        let monthFmt = Date.FormatStyle.dateTime.month(.abbreviated).locale(locale)
        if let end = t.returnDate {
            let startDay = cal.component(.day, from: start)
            let endDay = cal.component(.day, from: end)
            let sameMonth = cal.isDate(start, equalTo: end, toGranularity: .month)
                && cal.isDate(start, equalTo: end, toGranularity: .year)
            if sameMonth {
                let month = start.formatted(monthFmt)
                return "\(startDay) — \(endDay) \(month)"
            }
            let s = start.formatted(.dateTime.day().month(.abbreviated).locale(locale))
            let e = end.formatted(.dateTime.day().month(.abbreviated).locale(locale))
            return "\(s) — \(e)"
        }
        return start.formatted(.dateTime.day().month(.abbreviated).locale(locale))
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

/// Halo coloré derrière la photo d'un voyage dans la liste — variante compacte
/// de l'effet ambilight de l'Accueil. Teinte issue de la couleur de fond du voyage.
struct TripRowAmbilight: View {
    let trip: Trip

    @State private var sampledImageColor: Color?
    @Environment(\.colorScheme) private var colorScheme

    private var haloColor: Color {
        if trip.coverKind == .custom, let sampledImageColor { return sampledImageColor }
        return trip.resolvedCoverColor
    }

    // `plusLighter` n'a aucun effet sur un fond blanc : en clair on repasse en
    // fusion normale avec des opacités plus fortes pour que la teinte ressorte.
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(haloColor.opacity(isLight ? 0.42 : 0.18))
                .blur(radius: 22)
                .offset(x: -4, y: -1)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(haloColor.opacity(isLight ? 0.28 : 0.12))
                .blur(radius: 26)
                .offset(x: 4, y: 1)
        }
        .blendMode(isLight ? .normal : .plusLighter)
        .task(id: imageSampleKey) {
            await refreshImageColor()
        }
    }

    private var imageSampleKey: String {
        let coverToken = trip.coverKind == .custom ? TripCoverImageStore.modificationToken(tripId: trip.id) : "none"
        return "\(trip.id)|\(trip.coverKind.rawValue)|\(coverToken)"
    }

    @MainActor
    private func refreshImageColor() async {
        guard trip.coverKind == .custom, !trip.id.isEmpty else {
            sampledImageColor = nil
            return
        }
        let tripId = trip.id
        let color = await TripCoverImagePalette.dominantColor(forTripId: tripId)
        if tripId == trip.id { sampledImageColor = color }
    }
}
