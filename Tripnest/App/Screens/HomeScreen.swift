import SwiftUI
import UIKit

struct HomeScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onEditTrip: (String) -> Void = { _ in }
    var onDeleteTrip: (String) -> Void = { _ in }

    @AppStorage("tripnest.profile.name") private var profileName: String = ""
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"
    @AppStorage("tripnest.home.tileOrder") private var tileOrderRaw = "budget,spots,memories,plan"
    @AppStorage("tripnest.home.sectionOrder") private var sectionOrderRaw = "stats,ticket"
    @State private var pressedTile: HomeTile? = nil
    @State private var pendingTileNavigation: Task<Void, Never>? = nil
    @State private var showTicketScanner = false
    @State private var showTicketEditor = false
    @State private var showTripsPicker = false
    @State private var editingTicket = TravelTicketDraft()
    @State private var ticketEditorTripId: String? = nil
    @State private var reopenTicketEditorAfterScan = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationStatus: TripnestNotificationStatus = .notDetermined
    @State private var showNotificationSettingsAlert = false
    @State private var showHomeInfoSheet = false
    @State private var showFriendsSheet = false
    @EnvironmentObject private var avatarStore: ProfileImageStore

    private var profileFirstName: String {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.split(separator: " ").first, !first.isEmpty else { return "" }
        return String(String(first).prefix(10))
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Bonjour"
        case 12..<18: return L("Bon après-midi")
        default:      return "Bonsoir"
        }
    }

    private var initials: String {
        let parts = profileName.trimmingCharacters(in: .whitespaces).split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "T"
        let last  = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private var sortedTrips: [Trip] {
        store.trips.sorted { lhs, rhs in
            func rank(_ s: Trip.Status) -> Int {
                switch s { case .active: return 0; case .planned: return 1; case .done: return 2 }
            }
            let lr = rank(lhs.status), rr = rank(rhs.status)
            if lr != rr { return lr < rr }
            return (lhs.departureDate ?? .distantFuture) < (rhs.departureDate ?? .distantFuture)
        }
    }

    private var ongoingTrips: [Trip] { sortedTrips.filter { $0.status != .done } }

    private var selectedTripId: String? { store.selectedTripId ?? store.activeTrip?.id }

    private var displayedTrip: Trip? {
        if let id = selectedTripId, let m = ongoingTrips.first(where: { $0.id == id }) { return m }
        return ongoingTrips.first
    }

    private var ticketEditorTrip: Trip? {
        guard let ticketEditorTripId else { return displayedTrip }
        return store.trips.first(where: { $0.id == ticketEditorTripId })
    }

    private var currencySymbol: String { defaultCurrency.currencySymbol }

    // MARK: - Body

    var body: some View {
        ScreenShell(motif: false) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 10) {
                        header
                            .padding(.horizontal, 22)
                            .padding(.top, 8)

                        VStack(spacing: 10) {
                            if sortedTrips.isEmpty {
                                emptyHome
                            } else if ongoingTrips.isEmpty {
                                noOngoingTripsHint
                            } else {
                                if let t = displayedTrip {
                                    ZStack(alignment: .topTrailing) {
                                        HomeHeroCard(
                                            trip: t,
                                            tripStatus: tripStatusLabel(for: t),
                                            onTap: { onEditTrip(t.id) }
                                        )
                                        tripCardTransportBadge(t).padding(12)
                                    }

                                    ForEach(sectionOrder, id: \.self) { section in
                                        sectionView(section, trip: t)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 24)
                    }
                    .tripnestTabBarScrollPadding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .zIndex(1)
            }
            .overlay(alignment: .bottom) {
                TabBar(active: .home, onChange: onNav)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .task { await refreshNotificationStatus() }
        .onAppear {
            syncOngoingTripSelection()
        }
        .onDisappear {
            pendingTileNavigation?.cancel()
            pendingTileNavigation = nil
            pressedTile = nil
        }
        .onChange(of: store.trips.count) { _, _ in syncOngoingTripSelection() }
        .onChange(of: ongoingTrips.count) { _, _ in syncOngoingTripSelection() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                avatarStore.reload()
                Task { await refreshNotificationStatus() }
            }
        }
        .alert(L("Notifications désactivées"), isPresented: $showNotificationSettingsAlert) {
            Button(L("Ouvrir Réglages")) { Task { await TripnestNotifications.activate() } }
            Button(L("Annuler"), role: .cancel) {}
        } message: {
            Text(L("Active les notifications Tripnest dans Réglages pour recevoir tes rappels de voyage."))
        }
        .sheet(isPresented: $showHomeInfoSheet) { HomeTabsInfoSheet() }
        .sheet(isPresented: $showFriendsSheet) {
            FriendsListSheet()
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTripsPicker) {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(ongoingTrips) { trip in
                            Button {
                                store.selectTrip(id: trip.id)
                                showTripsPicker = false
                                Haptics.selection()
                            } label: {
                                tripPickerRow(trip)
                            }
                            .buttonStyle(TripnestPressStyle())
                        }
                    }
                    .padding(18)
                }
                .background(Color.tBg0.ignoresSafeArea())
                .navigationTitle(L("Voyages en cours"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L("Fermer")) { showTripsPicker = false }
                            .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTicketEditor) {
            if let trip = ticketEditorTrip {
                TravelTicketEditorSheet(
                    mode: trip.transportMode,
                    draft: $editingTicket,
                    tripOrigin: trip.origin,
                    tripDestination: trip.dest,
                    tripDepartureDate: trip.departureDate,
                    onScan: { openTicketScanner(for: trip, reopenEditor: true) },
                    onDone: saveHomeTicket
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
            }
        }
        .fullScreenCover(isPresented: $showTicketScanner) {
            if let t = ticketEditorTrip {
                TravelTicketCameraScanFlow(mode: t.transportMode) { draft in
                    editingTicket = draft
                    if reopenTicketEditorAfterScan {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            showTicketEditor = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                        .font(.tText(13))
                        .foregroundColor(.white)
                    // Salutation sur une ligne, prénom sur la ligne suivante
                    // → évite la troncature quand la salutation est longue (L("Bon après-midi")).
                    Text(timeGreeting)
                        .font(.tDisplay(24, weight: .bold))
                        .tracking(-0.5)
                        .lineLimit(1)
                    if !profileFirstName.isEmpty {
                        Text(profileFirstName)
                            .font(.tDisplay(24, weight: .bold))
                            .tracking(-0.5)
                            .foregroundColor(.tAccent2)
                            .lineLimit(1)
                    }
                }
                .offset(y: 12)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 8) {
                        Button {
                            showFriendsSheet = true
                            Haptics.selection()
                        } label: {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.tText)
                                .frame(width: 30, height: 30)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.tSurface))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
                                .overlay(alignment: .topTrailing) {
                                    if store.friendsCount > 0 {
                                        Text("\(store.friendsCount)")
                                            .font(.tText(10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .frame(minWidth: 16, minHeight: 16)
                                            .background(Circle().fill(Color.tAccent2))
                                            .overlay(Circle().stroke(Color.tBg0, lineWidth: 1.5))
                                            .offset(x: 6, y: -6)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L("Mes amis (%d)", store.friendsCount))

                        Button {
                            showHomeInfoSheet = true
                            Haptics.selection()
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.tText)
                                .frame(width: 30, height: 30)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.tSurface))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L("À quoi servent les onglets"))

                        Button(action: activateNotifications) {
                            IconBtn(
                                glyph: .bell,
                                dot: !notificationStatus.isEnabled,
                                stroke: .white,
                                strokeWidth: notificationStatus.isEnabled ? 2 : 1.75
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(notificationStatus.isEnabled ? L("Notifications activées") : L("Activer les notifications"))

                        Avatar(initials: initials, image: avatarStore.image)
                    }

                    Button {
                        showTripsPicker = true
                        Haptics.selection()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "suitcase.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text(L("Voyage total (%d)", ongoingTrips.count))
                                .font(.tText(10, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundColor(.tAccent2)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(Capsule().fill(Color.tSurface))
                        .overlay(Capsule().stroke(Color.tBubbleBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .opacity(ongoingTrips.isEmpty ? 0 : 1)
                    .disabled(ongoingTrips.isEmpty)
                }
            }
        }
    }

    // MARK: - Switcher

    private var ongoingTripsHeader: some View {
        HStack {
            Text(L("Voyages en cours"))
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

    private var tripSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ongoingTrips) { trip in tripChip(trip) }
            }
        }
    }

    private func tripChip(_ trip: Trip) -> some View {
        let isSelected = trip.id == selectedTripId
        let detailColor = isSelected ? Color.tAccent2.opacity(0.92) : Color.tTextMute
        return Button {
            store.selectTrip(id: trip.id)
            Haptics.selection()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.homeDestinationTitle)
                    .font(.tText(12, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                Text(trip.hasReturn ? trip.homeChipDateLine : trip.homeDateLine)
                    .font(.tText(10))
                    .foregroundColor(detailColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(isSelected ? .tAccent2 : .tText)
            .frame(minWidth: 120, maxWidth: 170, alignment: .leading)
            .frame(height: 42, alignment: .leading)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(isSelected ? Color.tAccent2.opacity(0.12) : Color.tSurface.opacity(0.78)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(isSelected ? Color.tAccent2.opacity(0.35) : Color.tBorder.opacity(0.75), lineWidth: 1))
        }
        .buttonStyle(TripnestPressStyle())
    }

    // MARK: - Hero status

    private func tripStatusLabel(for t: Trip) -> HomeHeroStatus {
        let total = max(1, t.planDayCount)
        guard let dep = t.departureDate else {
            return HomeHeroStatus(text: L("EN PRÉPARATION"), tone: .planned)
        }
        let now   = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.startOfDay(for: dep)
        let end: Date = {
            if let ret = t.returnDate { return Calendar.current.startOfDay(for: ret) }
            return Calendar.current.date(byAdding: .day, value: total - 1, to: start) ?? start
        }()
        if now < start {
            let days = Calendar.current.dateComponents([.day], from: now, to: start).day ?? 0
            if days <= 0 { return HomeHeroStatus(text: L("DÉPART AUJOURD'HUI"), tone: .active) }
            if days == 1 { return HomeHeroStatus(text: L("DÉPART DEMAIN"), tone: .planned) }
            return HomeHeroStatus(text: "DANS \(days) JOURS", tone: .planned)
        }
        if now > end { return HomeHeroStatus(text: "TERMINÉ", tone: .done) }
        let elapsed = (Calendar.current.dateComponents([.day], from: start, to: now).day ?? 0) + 1
        let dayN = min(max(1, elapsed), total)
        return HomeHeroStatus(text: L("EN COURS · JOUR %d/%d", dayN, total), tone: .active)
    }

    // MARK: - Stats grid 2×2

    private var tileOrder: [HomeTile] {
        let saved = tileOrderRaw.split(separator: ",").compactMap { HomeTile(rawValue: String($0)) }
        let missing = HomeTile.allCases.filter { !saved.contains($0) }
        return saved + missing
    }

    private func statsGrid(_ t: Trip) -> some View {
        let allSpots  = store.spots(for: t.id)
        let saved     = allSpots.filter { $0.saved }
        let planCount = store.planItems.filter { $0.tripId == t.id }.count
        let total     = max(allSpots.count, saved.count)
        let order     = tileOrder

        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(order, id: \.self) { tile in
                let isPressed = pressedTile == tile
                tileView(tile, trip: t, saved: saved, allSpots: allSpots, total: total, planCount: planCount)
                    .scaleEffect(isPressed ? 0.985 : 1)
                    .opacity(isPressed ? 0.92 : 1)
                    .animation(.easeOut(duration: 0.07), value: pressedTile)
                    .onTapGesture {
                        tileAction(for: tile, trip: t)
                    }
            }
        }
    }

    @ViewBuilder
    private func tileView(_ tile: HomeTile, trip t: Trip, saved: [Spot], allSpots: [Spot], total: Int, planCount: Int) -> some View {
        switch tile {
        case .budget:   budgetTile(trip: t)
        case .spots:    spotsTile(trip: t, allSpots: allSpots, total: total)
        case .memories: memoriesTile(trip: t)
        case .plan:     planTile(trip: t, count: planCount)
        }
    }

    private func tileAction(for tile: HomeTile, trip t: Trip) {
        pendingTileNavigation?.cancel()
        let tripId = t.id
        let target = route(for: tile)

        withAnimation(.easeOut(duration: 0.06)) {
            pressedTile = tile
        }

        pendingTileNavigation = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 55_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                store.selectTrip(id: tripId)
            }

            onNav(target)
            pressedTile = nil
            pendingTileNavigation = nil
        }
    }

    private func route(for tile: HomeTile) -> AppRoute {
        switch tile {
        case .budget:   return .tripBudget
        case .spots:    return .spots
        case .memories: return .tripSouvenirs
        case .plan:     return .tripPlanning
        }
    }

    private var sectionOrder: [HomeSection] {
        let saved = sectionOrderRaw.split(separator: ",").compactMap { HomeSection(rawValue: String($0)) }
        let missing = HomeSection.allCases.filter { !saved.contains($0) }
        return saved + missing
    }

    @ViewBuilder
    private func sectionView(_ section: HomeSection, trip t: Trip) -> some View {
        switch section {
        case .stats:
            statsGrid(t)
        case .ticket:
            if t.transportMode.supportsTravelTicket {
                ticketView(for: t)
            }
        }
    }

    @ViewBuilder
    private func ticketView(for t: Trip) -> some View {
        if let ticket = store.primaryTicket(for: t) {
            HomeTravelTicketCard(ticket: ticket, mode: t.transportMode) {
                openTicketEditor(for: t)
            }
        } else {
            HomeTicketPlaceholder(
                mode: t.transportMode,
                onTap: { openTicketEditor(for: t) }
            )
        }
    }

    private func tripPickerRow(_ trip: Trip) -> some View {
        let isSelected = trip.id == selectedTripId
        return HStack(spacing: 12) {
            TripPhoto(destination: trip.dest, country: trip.country, hue: trip.hue, radius: 22, showBorder: false, coverKind: trip.coverKind, tripId: trip.id, solidColor: trip.resolvedCoverColor)
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
                .background {
                    TripRowAmbilight(trip: trip)
                        .frame(width: 60, height: 60)
                        .allowsHitTesting(false)
                }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(trip.homeDestinationTitle)
                        .font(.tText(14, weight: .bold))
                        .foregroundColor(.tText)
                        .lineLimit(1)
                    let flag = trip.resolvedFlag
                    if !flag.isEmpty {
                        Text(flag).font(.system(size: 14))
                    }
                }
                Text(trip.hasReturn ? trip.homeChipDateLine : trip.homeDateLine)
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)
                    .lineLimit(1)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.tAccent2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.tSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? Color.tAccent.opacity(0.14) : .clear)
                )
        )
        .tripnestBubbleChrome(radius: 16, border: isSelected ? .tBubbleBorderStrong : nil)
    }

    private func openTicketEditor(for trip: Trip) {
        ticketEditorTripId = trip.id
        if let existing = store.primaryTicket(for: trip) {
            editingTicket = TravelTicketDraft(flight: existing)
        } else {
            var draft = TravelTicketDraft()
            draft.prefillFromTrip(
                origin: trip.origin,
                destination: trip.dest,
                departureDate: trip.departureDate
            )
            editingTicket = draft
        }
        showTicketEditor = true
        Haptics.selection()
    }

    private func openTicketScanner(for trip: Trip, reopenEditor: Bool) {
        ticketEditorTripId = trip.id
        reopenTicketEditorAfterScan = reopenEditor
        showTicketEditor = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showTicketScanner = true
        }
        Haptics.selection()
    }

    private func saveHomeTicket() {
        guard let trip = ticketEditorTrip, editingTicket.hasMinimumInfo else { return }
        store.replaceTicket(for: trip.id, mode: trip.transportMode, draft: editingTicket)
        Haptics.success()
    }

    private func budgetTile(trip t: Trip) -> some View {
        let remaining = max(0, t.budget - t.spent)
        let pct: Int = {
            guard t.budget > 0 else { return t.spent > 0 ? 101 : 0 }
            return Int(Double(t.spent) / Double(t.budget) * 100)
        }()
        let overBudget = pct > 100
        return StatTile(title: L("BUDGET\nRESTANT"), glyph: .wallet, accent: overBudget ? .tRose : .tBlue) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text("\(remaining)\(currencySymbol)")
                        .font(.tDisplay(20, weight: .heavy))
                        .tracking(-0.5)
                        .foregroundColor(.tText)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    budgetMiniPreview(overBudget: overBudget)
                        .padding(.leading, 8)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0x24173f)).frame(height: 3)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: overBudget ? [.tRose, .tAccent2] : [.tMint, .tBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(geo.size.width, geo.size.width * CGFloat(min(100, pct)) / 100), height: 3)
                    }
                }
                .frame(height: 3)
            }
        }
    }

    private func budgetMiniPreview(overBudget: Bool) -> some View {
        let main: Color = overBudget ? .tRose : .tMint
        let accent: Color = overBudget ? .tAccent2 : .tBlue
        return ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(
                    LinearGradient(
                                colors: [main, accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 27, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .overlay {
                    Capsule()
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 12, height: 3)
                }
                .rotationEffect(.degrees(-5))
                .shadow(color: main.opacity(0.30), radius: 3, x: 0, y: 1)

            Circle()
                .fill(Color.tGold)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1))
                .overlay {
                    Text(currencySymbol)
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(.white.opacity(0.90))
                        .minimumScaleFactor(0.5)
                }
                .offset(x: 1, y: 1)
                .shadow(color: Color.tGold.opacity(0.30), radius: 2.5, x: 0, y: 1)
        }
        .frame(width: 36, height: 22, alignment: .trailing)
    }

    private func spotsTile(trip t: Trip, allSpots: [Spot], total: Int) -> some View {
        let previewSpots = Array(allSpots.prefix(4))
        let extra = max(0, allSpots.count - previewSpots.count)
        let emptyPreviewColors: [Color] = [.tRose, .tBlue, .tMint, .tGold]
        return StatTile(title: L("SPOTS\nSAUVÉS"), glyph: .spot, accent: .tGold) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text("\(allSpots.count)")
                        .font(.tDisplay(20, weight: .heavy))
                        .tracking(-0.5)
                        .foregroundColor(.tText)
                        .monospacedDigit()
                    HStack(spacing: 5) {
                        ForEach(Array(previewSpots.enumerated()), id: \.element.id) { index, spot in
                            let color: Color = index == 2 ? .tMint : spotCategoryColor(spot.category)
                            HomeSpotPreviewPin(color: color, visited: spot.visited, toRedo: spot.toRedo)
                        }
                        if previewSpots.count < 4 {
                            ForEach(previewSpots.count..<4, id: \.self) { index in
                                let color = emptyPreviewColors[index]
                                HomeSpotPreviewPin(color: color, isPlaceholder: true)
                            }
                        }
                        if extra > 0 {
                            Text("+\(extra)")
                                .font(.tText(9, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(Color.tAccent2.opacity(0.85))
                                )
                        }
                    }
                    .padding(.leading, 6)
                }
            }
        }
    }

    private func memoriesTile(trip t: Trip) -> some View {
        StatTile(title: "SOUVENIRS\nPHOTOS", glyph: .gallery, accent: .tRose) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text("\(t.photoCount)")
                        .font(.tDisplay(20, weight: .heavy))
                        .tracking(-0.5)
                        .foregroundColor(.tText)
                        .monospacedDigit()
                    photoStackPreview(active: t.photoCount > 0)
                        .padding(.leading, 12)
                }
            }
        }
    }

    private func planTile(trip t: Trip, count: Int) -> some View {
        StatTile(title: L("PLANIFIER\nÉTAPES"), glyph: .cal, accent: .tMint) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text("\(count)")
                        .font(.tDisplay(20, weight: .heavy))
                        .tracking(-0.5)
                        .foregroundColor(.tText)
                        .monospacedDigit()
                    routeStepsPreview(activeCount: min(max(count, 0), 3))
                        .padding(.leading, 6)
                }
            }
        }
    }

    private func photoStackPreview(active: Bool) -> some View {
        let colors: [Color] = [.tRose, .tBlue, .tGold]
        return ZStack {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color)
                    .frame(width: 18, height: 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .offset(x: CGFloat(index) * 9, y: CGFloat(2 - index) * 2)
            }
        }
        .frame(width: 38, height: 22, alignment: .leading)
    }

    private func routeStepsPreview(activeCount: Int) -> some View {
        let colors: [Color] = [.tMint, .tBlue, .tGold]
        return ZStack {
            HStack(spacing: 0) {
                Capsule()
                    .fill(LinearGradient(colors: [colors[0].opacity(0.75), colors[1].opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 16, height: 3)
                Capsule()
                    .fill(LinearGradient(colors: [colors[1].opacity(0.5), colors[2].opacity(0.75)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 16, height: 3)
            }
            .opacity(activeCount == 0 ? 0.35 : 1)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < activeCount ? colors[index] : Color.tTextMute)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(index < activeCount ? 0.42 : 0.28))
                                .frame(width: 4, height: 4)
                        )
                        .overlay(Circle().stroke(Color.tSurface, lineWidth: 1.4))
                        .shadow(color: (index < activeCount ? colors[index] : Color.tTextMute).opacity(0.38), radius: 3, x: 0, y: 1)
                }
            }
        }
        .frame(width: 44, height: 20)
    }

    private struct HomeSpotPreviewPin: View {
        let color: Color
        var visited: Bool = false
        var toRedo: Bool = false
        var isPlaceholder: Bool = false

        var body: some View {
            ZStack {
                HomeSpotPreviewPinShape()
                    .fill(color)
                    .frame(width: 17, height: 22)
                    .blur(radius: 4)
                    .opacity(isPlaceholder ? 0.30 : 0.46)

                HomeSpotPreviewPinShape()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(isPlaceholder ? 0.72 : 0.84), color.opacity(isPlaceholder ? 0.48 : 0.60)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 15, height: 20)
                    .overlay(
                        HomeSpotPreviewPinShape()
                            .stroke(Color.white.opacity(isPlaceholder ? 0.44 : 0.68), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(isPlaceholder ? 0.14 : 0.26), radius: 2.5, x: 0, y: 1)

                Circle()
                    .fill(Color.white.opacity(isPlaceholder ? 0.54 : 0.72))
                    .frame(width: 4.5, height: 4.5)
                    .offset(y: -3.5)
            }
            .frame(width: 19, height: 24)
            .overlay(alignment: .topLeading) {
                if visited {
                    Circle()
                        .fill(Color(hex: 0x1F7A4F))
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(Color.white, lineWidth: 0.9))
                        .offset(x: -1.5, y: -1)
                }
            }
            .overlay(alignment: .topTrailing) {
                if toRedo {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(Color.white, lineWidth: 0.9))
                        .offset(x: 1.5, y: -1)
                }
            }
        }
    }

    private struct HomeSpotPreviewPinShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let w = rect.width
            let h = rect.height
            let r = w / 2
            let cx = rect.midX

            path.addArc(
                center: CGPoint(x: cx, y: r),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            path.addQuadCurve(
                to: CGPoint(x: cx, y: h),
                control: CGPoint(x: w, y: r + (h - r) * 0.38)
            )
            path.addQuadCurve(
                to: CGPoint(x: 0, y: r),
                control: CGPoint(x: 0, y: r + (h - r) * 0.38)
            )
            path.closeSubpath()
            return path
        }
    }

    private func spotCategoryColor(_ category: String) -> Color {
        SpotCategoryStyle.color(for: category)
    }

    // MARK: - Menu

    private func tripCardTransportBadge(_ t: Trip) -> some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.42))
                .frame(width: 34, height: 34)
            TransportModeGlyph(mode: t.transportMode, size: 18, stroke: .white)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Empty states

    private var emptyHome: some View {
        TCard(padding: 22, glow: true) {
            VStack(spacing: 14) {
                TripnestLogo(size: 72, glow: false)
                Text(L("Aucun voyage pour le moment"))
                    .font(.tDisplay(24)).tracking(-0.5).multilineTextAlignment(.center)
                Text(L("Planifie ton premier trajet en quelques étapes."))
                    .font(.tText(14)).foregroundColor(.tTextMute).multilineTextAlignment(.center)
                CTA(label: L("Créer un voyage"), action: { onNav(.newTrip) }).padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var noOngoingTripsHint: some View {
        TCard(padding: 20) {
            VStack(spacing: 12) {
                TIcon(glyph: .globe, size: 28, stroke: .tGold)
                Text(L("Tous tes voyages sont archivés")).font(.tText(16, weight: .bold))
                Text(L("Retrouve-les dans l'onglet Voyages → Voyages passés, ou crée un nouveau voyage."))
                    .font(.tText(13)).foregroundColor(.tTextMute).multilineTextAlignment(.center)
                CTA(label: L("Voir l'onglet Voyages"), secondary: true, action: { onNav(.trips) })
                CTA(label: L("Créer un voyage"), action: { onNav(.newTrip) })
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private func refreshNotificationStatus() async {
        notificationStatus = await TripnestNotifications.currentStatus()
    }

    private func activateNotifications() {
        Task {
            let before = notificationStatus
            let after = await TripnestNotifications.activate()
            notificationStatus = after
            if after.isEnabled { Haptics.success() }
            else if before == .denied || after == .denied { showNotificationSettingsAlert = true }
        }
    }

    private func syncOngoingTripSelection() {
        guard !ongoingTrips.isEmpty else { return }
        if let id = selectedTripId, ongoingTrips.contains(where: { $0.id == id }) { return }
        if let first = ongoingTrips.first { store.selectTrip(id: first.id) }
    }
}

// MARK: - Hero card

private enum HomeHeroTone {
    case active, planned, done
    var dotColor: Color {
        switch self { case .active: return Color(hex: 0x4CD964); case .planned: return .tGold; case .done: return .tTextMute }
    }
    var textColor: Color {
        switch self { case .active: return Color(hex: 0x4CD964); case .planned: return .tGold; case .done: return .white }
    }
}

private struct HomeHeroStatus { var text: String; var tone: HomeHeroTone }

private struct HomeHeroCard: View {
    let trip: Trip
    let tripStatus: HomeHeroStatus
    var onTap: () -> Void

    private let height: CGFloat = 184
    private let radius: CGFloat = 24

    var body: some View {
        heroCardContent
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .onTapGesture(perform: onTap)
        .accessibilityLabel("\(trip.homeDestinationTitle), \(tripStatus.text)")
    }

    private var heroCardContent: some View {
        ZStack(alignment: .topLeading) {
            // Photo background
            TripPhoto(
                destination: trip.dest,
                country: trip.country,
                hue: trip.hue,
                radius: 0,
                showBorder: false,
                coverKind: trip.coverKind,
                tripId: trip.id,
                solidColor: trip.resolvedCoverColor
            )
            .aspectRatio(TripCoverLayout.aspectRatio, contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            // Scrim
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.36), location: 0.0),
                    .init(color: .black.opacity(0.08), location: 0.42),
                    .init(color: .black.opacity(0.58), location: 1.0),
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Arc décoratif en pointillé
            GeometryReader { geo in
                DashedArc()
                    .stroke(Color.white.opacity(0.50),
                            style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [3, 7]))
                    .frame(width: geo.size.width - 60, height: 72)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.44)
                    .allowsHitTesting(false)
            }

            // Chrome
            VStack(alignment: .leading, spacing: 0) {
                // Top row : pill statut + drapeau (espace pour le menu ··· géré par le parent)
                HStack(alignment: .center) {
                    statusPill
                    Spacer(minLength: 8)
                    // réserve la place du bouton ···
                    Color.clear.frame(width: 40, height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Spacer(minLength: 0)

                // Bottom block
                VStack(alignment: .leading, spacing: 5) {
                    Text(L("PROCHAINE ESCALE"))
                        .font(.tText(10, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.78))

                    Text(trip.homeDestinationTitle)
                        .font(.tDisplay(34, weight: .heavy))
                        .tracking(-0.8)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    HStack(alignment: .center) {
                        Text(dateRangeLine)
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: 8)
                        HStack(spacing: 4) {
                            Text(L("Détails")).font(.tText(12, weight: .bold))
                            Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.tBorderStrong, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.24), radius: 14, x: 0, y: 10)
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle().fill(tripStatus.tone.dotColor).frame(width: 8, height: 8)
            Text(tripStatus.text)
                .font(.tText(11, weight: .heavy))
                .tracking(1.0)
                .foregroundColor(tripStatus.tone.textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.42)))
    }

    private static let _dateRangeFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "d MMM"
        return f
    }()

    private var dateRangeLine: String {
        let total = max(1, trip.planDayCount)
        let fmt = Self._dateRangeFmt
        if let dep = trip.departureDate {
            let start = fmt.string(from: dep)
            if let ret = trip.returnDate {
                return "\(start) — \(fmt.string(from: ret)) · " + (total > 1 ? L("%d jours", total) : L("%d jour", total))
            }
            return "\(start) · " + (total > 1 ? L("%d jours", total) : L("%d jour", total))
        }
        return trip.homeDateLine
    }

}

/// Couleurs « ambilight » par drapeau (utilisé par Accueil + Voyages).
enum TripAmbilightColor {
    static func color(for flag: String, fallbackHue: Double) -> Color {
        switch flag {
        case "🇫🇷": return Color(hex: 0x256DFF)
        case "🇺🇸": return Color(hex: 0xC81E3A)
        case "🇵🇹": return Color(hex: 0xD71920)
        case "🇲🇦": return Color(hex: 0xC1272D)
        case "🇯🇵": return Color(hex: 0xBC002D)
        case "🇮🇹": return Color(hex: 0x009246)
        case "🇪🇸": return Color(hex: 0xF1BF00)
        case "🇬🇧": return Color(hex: 0x3157A4)
        case "🇧🇷": return Color(hex: 0x009B3A)
        case "🇨🇦": return Color(hex: 0xD52B1E)
        default:
            return Color(hue: fallbackHue / 360, saturation: 0.68, brightness: 0.86)
        }
    }
}

enum TripRouteFlagResolver {
    private static let aliases: [String: String] = [
        "usa": "US",
        "us": "US",
        "united states": "US",
        "etats unis": "US",
        "etats-unis": "US",
        "royaume uni": "GB",
        "royaume-uni": "GB",
        "uk": "GB",
        "united kingdom": "GB",
        "angleterre": "GB",
        "emirats arabes unis": "AE",
        "emirats-arabes-unis": "AE",
        "united arab emirates": "AE",
        "coree du sud": "KR",
        "corée du sud": "KR",
        "south korea": "KR",
        "pays bas": "NL",
        "pays-bas": "NL",
        "netherlands": "NL"
    ]

    static func flag(
        for place: String,
        mode: TransportMode,
        fallbackCountry: String = "",
        fallbackFlag: String = ""
    ) -> String {
        // Ordre de fiabilité (valable pour tous les pays) :
        // 1. Catalogue de lieux curaté (aéroports/gares/ports) : pays connu de
        //    façon sûre, contrairement au géocodage qui peut confondre un nom
        //    ambigu (« ... Air Base ») avec un autre pays.
        // 2. Pays explicite du voyage.
        // 3. Texte libre de la destination.
        let trimmedFallback = fallbackCountry.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [
            countryFromCatalog(place: place, mode: mode),
            trimmedFallback.isEmpty || trimmedFallback == "À définir" ? nil : trimmedFallback,
            countryFromText(place)
        ]

        for candidate in candidates {
            if let candidate, let flag = flag(forCountryOrCode: candidate) {
                return flag
            }
        }
        return fallbackFlag
    }

    private static func countryFromCatalog(place: String, mode: TransportMode) -> String? {
        let trimmed = place.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }

        var modes: [TransportMode] = mode == .car ? [] : [mode]
        for fallbackMode in [TransportMode.plane, .train, .boat] where !modes.contains(fallbackMode) {
            modes.append(fallbackMode)
        }

        for mode in modes {
            if let match = TransportPlaceCatalog.bestMatch(mode: mode, query: trimmed),
               let country = countryFromSubtitle(match.subtitle) {
                return country
            }
        }
        return nil
    }

    private static func countryFromSubtitle(_ subtitle: String) -> String? {
        let parts = subtitle
            .split(separator: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard parts.count >= 2 else { return nil }

        if let last = parts.last {
            let upper = last.uppercased()
            if upper.count == 2, upper.allSatisfy(\.isLetter) {
                return upper
            }
            if upper.count == 3, upper.allSatisfy(\.isLetter), parts.count >= 3 {
                return parts[parts.count - 2]
            }
            return last
        }
        return nil
    }

    private static func countryFromText(_ text: String) -> String? {
        let separators = CharacterSet(charactersIn: ",;|/()[]{}")
        let pieces = text
            .components(separatedBy: separators)
            .flatMap { $0.components(separatedBy: "·") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for piece in pieces.reversed() {
            if flag(forCountryOrCode: piece) != nil {
                return piece
            }
        }
        return nil
    }

    private static func flag(forCountryOrCode value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let upper = trimmed.uppercased()
        if upper.count == 2, upper.allSatisfy(\.isLetter) {
            return emojiFlag(forRegionCode: upper)
        }

        let normalized = normalizeCountry(trimmed)
        if let aliasCode = aliases[normalized] {
            return emojiFlag(forRegionCode: aliasCode)
        }

        for region in Locale.Region.isoRegions {
            let code = region.identifier
            guard code.count == 2 else { continue }
            let fr = Locale(identifier: "fr_FR").localizedString(forRegionCode: code).map(normalizeCountry)
            let en = Locale(identifier: "en_US").localizedString(forRegionCode: code).map(normalizeCountry)
            let current = Locale.current.localizedString(forRegionCode: code).map(normalizeCountry)
            if [fr, en, current].contains(where: { $0 == normalized }) {
                return emojiFlag(forRegionCode: code)
            }
        }
        return nil
    }

    static func flag(forISOCode code: String) -> String? {
        emojiFlag(forRegionCode: code)
    }

    /// Pays (nom ou code ISO) déduit du catalogue de lieux curaté (aéroports,
    /// gares, ports). Source plus fiable que le géocodage pour les noms ambigus
    /// (ex. « ... Air Base » que le géocodeur confond avec une base US).
    static func country(forPlace place: String, mode: TransportMode) -> String? {
        countryFromCatalog(place: place, mode: mode) ?? countryFromText(place)
    }

    /// Drapeau emoji pour un nom de pays ou un code ISO (accès public).
    static func flag(forCountry value: String) -> String? {
        flag(forCountryOrCode: value)
    }

    private static func emojiFlag(forRegionCode code: String) -> String? {
        let upper = code.uppercased()
        guard upper.count == 2, upper.allSatisfy(\.isLetter) else { return nil }
        let scalars = upper.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }
        guard scalars.count == 2 else { return nil }
        return String(String.UnicodeScalarView(scalars))
    }

    private static func normalizeCountry(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: " ")
            .replacingOccurrences(of: "’", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private struct DashedArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height),
            control: CGPoint(x: rect.width / 2, y: -rect.height * 0.4)
        )
        return p
    }
}

// MARK: - Stat tile

private struct StatTile<Content: View>: View {
    let title: String
    let glyph: TIcon.Glyph
    let accent: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.tText(10, weight: .heavy))
                    .tracking(1.0)
                    .foregroundColor(.tTextMute)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(accent.opacity(0.14))
                        .frame(width: 26, height: 26)
                    TIcon(glyph: glyph, size: 13, stroke: accent, strokeWidth: 1.8)
                }
            }
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 102, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.tSurface))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.tBubbleBorder, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Misc

struct DashedDivider: View {
    var body: some View {
        Canvas { ctx, rect in
            var p = Path()
            p.move(to: CGPoint(x: 0, y: rect.height / 2))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            ctx.stroke(p, with: .color(.tBorder), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
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
                    Text(L("Petit rappel sur les onglets de Tripnest."))
                        .font(.tText(14)).foregroundColor(.tTextMute)
                    infoCard(title: "Accueil",  icon: .home,   description: L("Vue d'ensemble de ton voyage en cours : statut, budget, spots, souvenirs et planning."))
                    infoCard(title: "Voyages",  icon: .globe,  description: L("Tous tes voyages planifiés ou réalisés. Crée, modifie, archive et invite des amis pour qu’ils puissent voir et gérer le voyage avec toi."))
                    infoCard(title: "Spots",    icon: .spot,   description: L("Tes lieux importants : restaurants, hôtels, activités… reliés à un voyage."))
                    infoCard(title: "Budget",   icon: .wallet, description: L("Suivi des dépenses du voyage sélectionné : catégories, total dépensé et budget restant."))
                }
                .padding(18)
            }
            .background(Color.tBg0.ignoresSafeArea())
            .navigationTitle(L("Comment fonctionne Tripnest ?"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Fermer")) { dismiss() }.fontWeight(.semibold)
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
                    Text(title).font(.tText(15, weight: .bold))
                    Text(description).font(.tText(13)).foregroundColor(.tTextMute)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Tile ordering

private enum HomeTile: String, CaseIterable, Hashable {
    case budget, spots, memories, plan
}

// MARK: - Section ordering

private enum HomeSection: String, CaseIterable, Hashable {
    case stats, ticket
}
