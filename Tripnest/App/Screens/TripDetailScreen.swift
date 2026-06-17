import SwiftUI
import UIKit
import CoreLocation

struct TripDetailScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.colorScheme) private var colorScheme
    var onNav: (AppRoute) -> Void = { _ in }
    var onBack: () -> Void = {}
    var onDelete: (String) -> Void = { _ in }
    @State private var tab: DetailTab = .info
    @State private var showCompleteTripAlert = false
    @State private var showShareOptions = false
    @State private var showSystemShare = false
    @State private var shareCanEdit = false
    @State private var showTripFriends = false
    @State private var estimatedTravelTime = ""
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"

    private enum DetailTab: String, CaseIterable {
        case info, itinerary, budget, spots, photos, notes

        var label: String {
            switch self {
            case .itinerary: return L("Itinéraire")
            case .info: return "Infos"
            case .budget: return "Budget"
            case .spots: return "Spots"
            case .photos: return "Photos"
            case .notes: return "Notes"
            }
        }

        var route: AppRoute? {
            switch self {
            case .itinerary: return nil
            case .info: return nil
            case .budget: return .tripBudget
            case .spots: return .spots
            case .photos: return .tripSouvenirs
            case .notes: return .tripNotes
            }
        }
    }

    var body: some View {
        ScreenShell(motif: false) {
            if let t = store.activeTrip {
                ZStack(alignment: .top) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            heroCard(t)
                            statsSection(t)
                                .padding(.leading, 18)
                            tabSelector
                                .padding(.horizontal, 18)
                            tabContent(t)
                                .padding(.horizontal, 18)
                        }
                        .tripnestTabBarScrollPadding()
                    }
                    .tripnestScrollBounceWhenNeeded()
                    .ignoresSafeArea(.container, edges: .top)

                    topBar
                }
                .safeAreaInset(edge: .bottom) {
                    TabBar(active: .trips, onChange: onNav)
                }
            } else {
                emptyState
            }
        }
        .alert(L("Archiver ce voyage ?"), isPresented: $showCompleteTripAlert) {
            Button(L("Annuler"), role: .cancel) {}
            Button(L("Oui, archiver")) { confirmTripCompletion() }
        } message: {
            if let t = store.activeTrip {
                Text(L("« %@ » sera enregistré dans Voyages passés.", t.homeDestinationTitle))
            }
        }
        .sheet(isPresented: $showShareOptions) {
            tripShareOptionsSheet
                .presentationDetents([.height(330)])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showTripFriends) {
            tripFriendsSheet
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSystemShare) {
            TripShareActivityView(items: [tripShareMessage])
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                IconBtn(glyph: .back)
            }
            .buttonStyle(TripnestPressStyle())
            Spacer()
            HStack(spacing: 8) {
                if let t = store.activeTrip {
                    Button(action: {
                        showTripFriends = true
                        Haptics.impact(.light)
                    }) {
                        ZStack(alignment: .topTrailing) {
                            SystemIconBtn(systemImage: "person.2.fill", stroke: .white)
                            Text("\(tripFriendCount)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 15, height: 15)
                                .background(Circle().fill(Color.tAccent))
                                .overlay(Circle().stroke(Color.tSurface, lineWidth: 1))
                                .offset(x: 2, y: -2)
                        }
                    }
                    .buttonStyle(TripnestPressStyle())
                    .accessibilityLabel(L("%d ami sur ce voyage", tripFriendCount))

                    Button(action: {
                        shareCanEdit = false
                        showShareOptions = true
                        Haptics.impact(.light)
                    }) {
                        SystemIconBtn(systemImage: "square.and.arrow.up", stroke: .white)
                    }
                    .buttonStyle(TripnestPressStyle())
                    .accessibilityLabel(L("Partager ce voyage"))

                    Button(action: { toggleFavorite(t) }) {
                        IconBtn(glyph: .heart, stroke: t.favorite ? .tRose : .tText)
                    }
                    .buttonStyle(TripnestPressStyle())
                    .accessibilityLabel(t.favorite ? L("Retirer des coups de cœur") : L("Ajouter aux coups de cœur"))

                    Button(action: { onDelete(t.id) }) {
                        IconBtn(glyph: .close, stroke: .tRose)
                    }
                    .buttonStyle(TripnestPressStyle())
                    .accessibilityLabel(L("Supprimer ce voyage"))
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    private var tripFriends: [Friend] {
        guard let tripId = store.activeTrip?.id else { return [] }
        return store.friends.filter { $0.sharedTripIds.contains(tripId) }
    }

    private var tripFriendCount: Int { tripFriends.count }

    private var tripFriendsSheet: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L("Amis du voyage"))
                            .font(.tDisplay(24))
                            .tracking(-0.5)
                            .foregroundColor(.tText)
                        Text(tripFriendCount > 1 ? L("%d personnes peuvent accéder à ce voyage.", tripFriendCount) : L("%d personne peut accéder à ce voyage.", tripFriendCount))
                            .font(.tText(13))
                            .foregroundColor(.tTextMute)
                    }
                    .padding(.top, 10)

                    if tripFriends.isEmpty {
                        TCard(padding: 18) {
                            VStack(spacing: 10) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.tAccent2)
                                Text(L("Aucun ami invité"))
                                    .font(.tText(15, weight: .bold))
                                    .foregroundColor(.tText)
                                Text(L("Invite un ami depuis la création ou le partage du voyage."))
                                    .font(.tText(12))
                                    .foregroundColor(.tTextMute)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        TCard(padding: 4) {
                            VStack(spacing: 0) {
                                ForEach(tripFriends) { friend in
                                    tripFriendAccessRow(friend)
                                    if friend.id != tripFriends.last?.id {
                                        Rectangle().fill(Color.tBorder).frame(height: 1)
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(22)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { showTripFriends = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.tTextMute)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.tSurface))
                            .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L("Fermer"))
                }
            }
        }
        .tripnestPreferredColorScheme()
    }

    private func tripFriendAccessRow(_ friend: Friend) -> some View {
        let permission = friend.sharedTripPermissions[store.activeTrip?.id ?? ""] ?? .viewOnly
        return HStack(spacing: 12) {
            Avatar(initials: initials(for: friend.name), size: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(friend.name)
                    .font(.tText(15, weight: .bold))
                    .foregroundColor(.tText)
                Text(friend.status == .accepted ? L("Ami Tripnest") : "Invitation en attente")
                    .font(.tText(12))
                    .foregroundColor(.tTextMute)
            }
            Spacer(minLength: 0)
            Text(L(permission.title))
                .font(.tText(11, weight: .bold))
                .foregroundColor(permission == .canEdit ? .tMint : .tBlue)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Capsule().fill((permission == .canEdit ? Color.tMint : Color.tBlue).opacity(0.12)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func initials(for name: String) -> String {
        let parts = name.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "?"
        let last = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private var tripShareOptionsSheet: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L("Partager le voyage"))
                            .font(.tDisplay(24))
                            .tracking(-0.5)
                            .foregroundColor(.tText)
                        Text(L("Choisis ce que ton ami pourra faire avant d'envoyer l'invitation."))
                            .font(.tText(13))
                            .foregroundColor(.tTextMute)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 10)

                    TCard(padding: 4) {
                        VStack(spacing: 0) {
                            sharePermissionRow(
                                title: L("Peut modifier"),
                                subtitle: L("Ton ami pourra ajouter ou changer le voyage."),
                                isSelected: shareCanEdit,
                                action: { shareCanEdit = true }
                            )
                            Rectangle().fill(Color.tBorder).frame(height: 1)
                            sharePermissionRow(
                                title: "Regarder seulement",
                                subtitle: L("Ton ami verra le voyage en direct sans modifier."),
                                isSelected: !shareCanEdit,
                                action: { shareCanEdit = false }
                            )
                        }
                    }

                    CTA(label: "Partager", action: startTripShare)
                }
                .padding(22)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { showShareOptions = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.tTextMute)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.tSurface))
                            .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L("Fermer"))
                }
            }
        }
        .tripnestPreferredColorScheme()
    }

    private func sharePermissionRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            action()
            Haptics.selection()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .tMint : .tTextMute)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.tText(15, weight: .bold))
                        .foregroundColor(.tText)
                    Text(subtitle)
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var tripShareMessage: String {
        guard let t = store.activeTrip else { return L("Rejoins mon voyage sur Tripnest.") }
        let permission = shareCanEdit
            ? L("Tu pourras modifier le voyage avec moi.")
            : L("Tu pourras regarder le voyage en direct, sans le modifier.")
        return L("Je te partage mon voyage « %@ » sur Tripnest. %@", t.homeDestinationTitle, permission)
    }

    private func startTripShare() {
        showShareOptions = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showSystemShare = true
        }
    }

    private func toggleFavorite(_ t: Trip) {
        store.setTripFavorite(id: t.id, favorite: !t.favorite)
        Haptics.selection()
    }

    // MARK: - Hero

    private func heroCard(_ t: Trip) -> some View {
        ZStack(alignment: .bottomLeading) {
            TripPhoto(
                destination: t.dest,
                country: t.country,
                hue: t.hue,
                radius: 0,
                showBorder: false,
                coverKind: t.coverKind,
                tripId: t.id,
                solidColor: t.resolvedCoverColor
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            LinearGradient(
                stops: colorScheme == .light
                    ? [
                        // Clair : on garde la teinte du voyage bien plus longtemps,
                        // fondu vers le blanc seulement en bas (sous le titre).
                        .init(color: .clear, location: 0.45),
                        .init(color: Color.tBg0.opacity(0.30), location: 0.72),
                        .init(color: Color.tBg0.opacity(0.85), location: 0.93),
                        .init(color: Color.tBg0, location: 1),
                      ]
                    : [
                        .init(color: .clear, location: 0.20),
                        .init(color: Color.tBg0.opacity(0.55), location: 0.55),
                        .init(color: Color.tBg0.opacity(0.92), location: 0.92),
                        .init(color: Color.tBg0, location: 1),
                      ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                heroStatusBadge(t)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(t.displayTitle)
                        .font(.tDisplay(44))
                        .tracking(-1.6)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                    let flag = t.resolvedFlag
                    if !flag.isEmpty {
                        Text(flag)
                            .font(.system(size: 32))
                    }
                }
                Text(heroSubtitle(t))
                    .font(.tText(14))
                    .foregroundColor(.tTextMute)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 420)
        .frame(maxWidth: .infinity)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: 0,
                    bottomLeading: 28,
                    bottomTrailing: 28,
                    topTrailing: 0
                ),
                style: .continuous
            )
        )
    }

    @ViewBuilder
    private func heroStatusBadge(_ t: Trip) -> some View {
        let (label, color): (String, Color) = {
            switch t.status {
            case .done: return (L("VOYAGE TERMINÉ"), .tTextMute)
            case .planned: return (L("VOYAGE PLANIFIÉ"), .tGold)
            case .active: return (L("VOYAGE EN COURS"), Color(hex: 0x4CD964))
            }
        }()
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.6), radius: 4)
            Text(label)
                .font(.tText(12, weight: .bold))
                .tracking(1.4)
                .foregroundColor(.tText)
        }
    }

    private func heroSubtitle(_ t: Trip) -> String {
        var parts: [String] = []
        if let datesPart = formattedDateRange(for: t) {
            parts.append(datesPart)
        }
        parts.append((t.days > 1 ? L("%d jours", t.days) : L("%d jour", t.days)))
        let country = t.country.trimmingCharacters(in: .whitespacesAndNewlines)
        if !country.isEmpty, country != "À définir" {
            parts.append(country)
        }
        return parts.joined(separator: " · ")
    }

    private func formattedDateRange(for t: Trip) -> String? {
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

    // MARK: - Stats

    private func statsSection(_ t: Trip) -> some View {
        let sym = defaultCurrency.currencySymbol
        let tripSpots = store.spots.filter { $0.tripId == t.id }
        let spotCount = tripSpots.count
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                statCard(
                    label: L("Dépensé"),
                    value: "\(t.spent)\(sym)",
                    sub: "/ \(t.budget)\(sym)",
                    color: .tAccent,
                    action: { onNav(.tripBudget) }
                )
                spotsStatCard(
                    count: spotCount,
                    spots: tripSpots,
                    action: { onNav(.spots) }
                )
                statCard(
                    label: "Photos",
                    value: "\(t.photoCount)",
                    sub: t.photoCount > 1 ? L("clichés") : L("cliché"),
                    color: .tBlue,
                    action: { onNav(.tripSouvenirs) }
                )
                Spacer(minLength: 18)
            }
            .padding(.vertical, 2)
        }
    }

    private func statCard(
        label: String,
        value: String,
        sub: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.tTextMute)
                Text(value)
                    .font(.tText(28, weight: .bold))
                    .tracking(-0.8)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(sub)
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: 140, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.tSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.tBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TripnestPressStyle())
    }

    private func spotsStatCard(
        count: Int,
        spots: [Spot],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Spots"))
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.tTextMute)
                Text("\(count)")
                    .font(.tText(28, weight: .bold))
                    .tracking(-0.8)
                    .foregroundColor(.tRose)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(L("sauvés"))
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: 150, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.tSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.tBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TripnestPressStyle())
    }

    // MARK: - Tabs

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DetailTab.allCases, id: \.self) { item in
                    Button {
                        withAnimation(TripnestAnimation.page) {
                            tab = item
                        }
                        if let route = item.route {
                            onNav(route)
                        }
                    } label: {
                        Text(item.label)
                            .font(.tText(13, weight: .semibold))
                            .foregroundColor(tab == item ? .white : .tTextMute)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(tab == item ? Color.tAccent : Color.tSurface)
                            )
                            .overlay(
                                Capsule().stroke(tab == item ? Color.clear : Color.tAccent2.opacity(0.55), lineWidth: 1.2)
                            )
                    }
                    .buttonStyle(TripnestPressStyle())
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func tabContent(_ t: Trip) -> some View {
        switch tab {
        case .itinerary:
            itinerarySection(t)
        case .budget:
            shortcutCard(
                glyph: .wallet,
                title: L("Suivi budget"),
                subtitle: L("Consulte tes dépenses et ajoute-en de nouvelles."),
                cta: L("Ouvrir le budget"),
                action: { onNav(.tripBudget) }
            )
        case .spots:
            shortcutCard(
                glyph: .spot,
                title: L("Tes spots"),
                subtitle: L("Restaurants, hôtels et lieux à visiter."),
                cta: L("Voir les spots"),
                action: { onNav(.spots) }
            )
        case .info:
            infoSection(t)
        case .photos:
            shortcutCard(
                glyph: .gallery,
                title: L("Photos du voyage"),
                subtitle: L("Tes clichés et souvenirs de ce voyage."),
                cta: L("Voir les photos"),
                action: { onNav(.tripSouvenirs) }
            )
        case .notes:
            shortcutCard(
                glyph: .edit,
                title: L("Notes du voyage"),
                subtitle: L("Adresses, idées et rappels, jusqu'à 500 lignes."),
                cta: L("Ouvrir les notes"),
                action: { onNav(.tripNotes) }
            )
        }
    }

    private func itinerarySection(_ trip: Trip) -> some View {
        let dayKeys = store.allPlanDayKeys(for: trip.id)
            .filter { !store.planItems(for: trip.id, dayKey: $0).isEmpty }
        return VStack(spacing: 14) {
            if dayKeys.isEmpty {
                emptyItineraryCard(trip)
            } else {
                ForEach(dayKeys, id: \.self) { key in
                    if let date = TripPlanCalendar.date(from: key) {
                        dayCard(trip: trip, date: date, dayKey: key)
                    }
                }
            }

            Button(action: { onNav(.tripPlanning) }) {
                HStack(spacing: 8) {
                    TIcon(glyph: .plus, size: 14, stroke: .tAccent2, strokeWidth: 2.5)
                    Text(L("Planifier une étape"))
                        .font(.tText(13, weight: .semibold))
                        .foregroundColor(.tAccent2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.tAccent2.opacity(0.10))
                )
            }
            .buttonStyle(TripnestPressStyle())
        }
    }

    private func emptyItineraryCard(_ trip: Trip) -> some View {
        TCard(padding: 20) {
            VStack(spacing: 10) {
                IconBubble(glyph: .cal, color: .tAccent2, size: 44)
                Text(L("Aucune étape planifiée"))
                    .font(.tText(15, weight: .bold))
                Text(L("Ajoute tes activités pour %@ jour par jour.", trip.dest))
                    .font(.tText(13))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func dayCard(trip: Trip, date: Date, dayKey: String) -> some View {
        let items = store.planItems(for: trip.id, dayKey: dayKey)
        return Button(action: {
            store.selectTrip(id: trip.id)
            onNav(.tripPlanning)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    dayBadge(for: date)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayTitle(for: date))
                            .font(.tText(17, weight: .bold))
                            .foregroundColor(.tText)
                        Text(items.count > 1 ? L("%d étapes", items.count) : L("%d étape", items.count))
                            .font(.tText(12))
                            .foregroundColor(.tTextMute)
                    }
                    Spacer()
                }

                if !items.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(items.prefix(3)) { item in
                            planStepRow(item)
                        }
                        if items.count > 3 {
                            Text("+ \(items.count - 3) autre\(items.count - 3 > 1 ? "s" : "")")
                                .font(.tText(11, weight: .semibold))
                                .foregroundColor(.tAccent2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.tSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.tBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TripnestPressStyle())
    }

    private func dayBadge(for date: Date) -> some View {
        let cal = Calendar.current
        let day = cal.component(.day, from: date)
        let month = date.formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "fr_FR")))
            .uppercased()
            .replacingOccurrences(of: ".", with: "")
        return VStack(spacing: 2) {
            Text("\(day)")
                .font(.tText(20, weight: .bold))
                .tracking(-0.4)
                .foregroundColor(.tText)
            Text(month)
                .font(.tText(10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(.tTextMute)
        }
        .frame(width: 54, height: 54)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.tAccent.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.tAccent.opacity(0.35), lineWidth: 1)
        )
    }

    private func dayTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Aujourd'hui" }
        if cal.isDateInTomorrow(date) { return "Demain" }
        if cal.isDateInYesterday(date) { return "Hier" }
        let formatted = date.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "fr_FR")))
        return formatted.prefix(1).uppercased() + formatted.dropFirst()
    }

    private func planStepRow(_ item: TripPlanItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconBubble(glyph: glyphForStep(item), color: colorForStep(item), size: 32)
            VStack(alignment: .leading, spacing: 2) {
                if !item.time.isEmpty {
                    Text(item.time)
                        .font(.tText(12, weight: .semibold))
                        .foregroundColor(.tTextMute)
                }
                Text(stepDisplayTitle(item))
                    .font(.tText(14, weight: .semibold))
                    .foregroundColor(.tText)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }

    private func stepDisplayTitle(_ item: TripPlanItem) -> String {
        let loc = item.location.trimmingCharacters(in: .whitespacesAndNewlines)
        if loc.isEmpty { return item.title }
        return "\(item.title) · \(loc)"
    }

    private func glyphForStep(_ item: TripPlanItem) -> TIcon.Glyph {
        let s = (item.title + " " + item.location).lowercased()
        if s.contains("vol") || s.contains("avion") || s.contains("aéroport") || s.contains("aeroport") || s.contains("arrivée") || s.contains("départ") || s.contains("depart") {
            return .plane
        }
        if s.contains("check-in") || s.contains("hôtel") || s.contains("hotel") || s.contains("auberge") || s.contains("airbnb") || s.contains("logement") {
            return .hotel
        }
        if s.contains("train") || s.contains("tram") || s.contains("métro") || s.contains("metro") || s.contains("bus") {
            return .train
        }
        if s.contains("restaurant") || s.contains("dîner") || s.contains("diner") || s.contains("déjeuner") || s.contains("petit-déjeuner") || s.contains("café") {
            return .food
        }
        if s.contains("musée") || s.contains("musee") || s.contains("visite") || s.contains("tour") || s.contains("château") || s.contains("chateau") {
            return .spot
        }
        return .cal
    }

    private func colorForStep(_ item: TripPlanItem) -> Color {
        switch glyphForStep(item) {
        case .plane: return .tBlue
        case .hotel: return .tRose
        case .train: return .tAccent2
        case .food: return .tGold
        case .spot: return .tMint
        default: return .tAccent2
        }
    }

    // MARK: - Infos

    @ViewBuilder
    private func infoSection(_ t: Trip) -> some View {
        let tickets = store.flights(for: t.id)
        let sym = defaultCurrency.currencySymbol
        let departurePlace = Trip.displayPlaceName(t.origin)
        let ticketTime = travelDuration(for: store.primaryTicket(for: t))
        let travelTime = ticketTime.isEmpty ? estimatedTravelTime : ticketTime
        VStack(spacing: 14) {
            TCard(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L("DÉTAILS DU VOYAGE"))
                        .font(.tText(11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.tTextMute)

                    infoRow(glyph: .spot, label: L("Départ"), value: departurePlace.isEmpty ? "—" : departurePlace)
                    infoRow(glyph: .spot, label: "Destination", value: t.dest.isEmpty ? "—" : t.dest)
                    if !t.country.trimmingCharacters(in: .whitespaces).isEmpty, t.country != "À définir" {
                        infoRow(glyph: .globe, label: "Pays", value: "\(t.resolvedFlag) \(t.country)".trimmingCharacters(in: .whitespaces))
                    }
                    infoRow(glyph: .arrow, label: "Trajet", value: t.tripsListRouteLine)
                    infoRow(glyph: .cal, label: "Dates", value: formattedDateRange(for: t) ?? t.dates)
                    infoRow(glyph: .ticket, label: "Temps de trajet", value: travelTime.isEmpty ? "—" : travelTime)
                    infoRow(glyph: .sun, label: L("Durée"), value: (t.days > 1 ? L("%d jours", t.days) : L("%d jour", t.days)))
                    infoRow(glyph: transportGlyph(t.transportMode), label: "Transport", value: t.transportMode.label)
                    infoRow(glyph: .wallet, label: "Budget", value: "\(t.spent)\(sym) / \(t.budget)\(sym)")
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    TIcon(glyph: .plane, size: 16, stroke: .tAccent2, strokeWidth: 2)
                    Text(L("Vols & billets"))
                        .font(.tText(14, weight: .bold))
                }

                if tickets.isEmpty {
                    shortcutCard(
                        glyph: .plane,
                        title: L("Aucun vol enregistré"),
                        subtitle: L("Ajoute ton billet pour retrouver horaires et détails ici."),
                        cta: L("Ajouter un vol"),
                        action: { onNav(.flights) }
                    )
                } else {
                    ForEach(tickets) { flight in
                        flightDetailCard(flight)
                    }

                    Button(action: { onNav(.flights) }) {
                        HStack(spacing: 8) {
                            TIcon(glyph: .edit, size: 14, stroke: .tAccent2, strokeWidth: 2.5)
                            Text(L("Gérer les vols"))
                                .font(.tText(13, weight: .semibold))
                                .foregroundColor(.tAccent2)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.tAccent2.opacity(0.10))
                        )
                    }
                    .buttonStyle(TripnestPressStyle())
                }
            }
        }
        .task(id: t.routeMapLoadKey) {
            if travelDuration(for: store.primaryTicket(for: t)).isEmpty {
                estimatedTravelTime = await estimateTravelTime(for: t)
            } else {
                estimatedTravelTime = ""
            }
        }
    }

    private func infoRow(glyph: TIcon.Glyph, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            TIcon(glyph: glyph, size: 16, stroke: .tAccent2, strokeWidth: 2)
                .frame(width: 22)
            Text(label)
                .font(.tText(13))
                .foregroundColor(.tTextMute)
            Spacer(minLength: 12)
            Text(value)
                .font(.tText(13, weight: .semibold))
                .foregroundColor(.tText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func travelDuration(for flight: Flight?) -> String {
        guard let flight else { return "" }
        let dur = flight.duration.trimmingCharacters(in: .whitespaces)
        if !dur.isEmpty { return dur }
        return computedDuration(from: flight.departure, to: flight.arrival)
    }

    private func computedDuration(from departure: String, to arrival: String) -> String {
        guard let start = minutes(from: departure), let end = minutes(from: arrival) else { return "" }
        var diff = end - start
        if diff < 0 { diff += 24 * 60 }
        guard diff > 0 else { return "" }
        return formatDuration(minutes: diff)
    }

    private func formatDuration(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        switch (h, m) {
        case (0, _): return "\(m) min"
        case (_, 0): return "\(h)h"
        default: return "\(h)h\(String(format: "%02d", m))"
        }
    }

    private func estimateTravelTime(for trip: Trip) async -> String {
        let origin = trip.origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let dest = trip.dest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !origin.isEmpty, !dest.isEmpty else { return "" }
        let mode = trip.transportMode
        guard let a = await TripPlaceResolver.coordinate(for: origin, mode: mode),
              let b = await TripPlaceResolver.coordinate(for: dest, mode: mode) else { return "" }
        let km = CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude)) / 1000
        guard km > 1 else { return "" }
        let hours: Double
        switch mode {
        case .plane: hours = km / 750 + 1.5
        case .train: hours = km / 120 + 0.3
        case .car:   hours = km / 85
        case .boat:  hours = km / 35
        }
        let raw = Int((hours * 60).rounded())
        let rounded = max(5, Int((Double(raw) / 5).rounded()) * 5)
        return "≈ " + formatDuration(minutes: rounded)
    }

    private func minutes(from time: String) -> Int? {
        let parts = time.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "h", with: ":")
            .split(separator: ":")
        guard let h = parts.first.flatMap({ Int($0) }) else { return nil }
        let m = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        return h * 60 + m
    }

    private func transportGlyph(_ mode: TransportMode) -> TIcon.Glyph {
        switch mode {
        case .plane: return .plane
        case .train: return .train
        case .boat: return .boat
        case .car: return .car
        }
    }

    private func flightDetailCard(_ flight: Flight) -> some View {
        TCard(padding: 18) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flight.company.isEmpty ? "Compagnie" : flight.company)
                            .font(.tText(13, weight: .bold))
                        Text(flight.code.isEmpty ? "—" : flight.code)
                            .font(.tText(11)).foregroundColor(.tTextMute)
                    }
                    Spacer()
                    TransportModeGlyph(mode: flight.transportMode, size: 22, stroke: .tAccent2)
                }

                HStack(alignment: .center, spacing: 8) {
                    flightAirport(city: flight.fromCity, code: flight.from, time: flight.departure)
                    Spacer()
                    VStack(spacing: 8) {
                        Text(flight.duration.isEmpty ? "--" : flight.duration)
                            .font(.tText(10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(.tTextDim)
                        TIcon(glyph: .arrow, size: 18, stroke: .tAccent2)
                    }
                    Spacer()
                    flightAirport(city: flight.toCity, code: flight.to, time: flight.arrival, trailing: true)
                }

                HStack {
                    flightDetail("DATE", flight.date)
                    flightDetail("SIÈGE", flight.seat)
                    flightDetail("PORTE", flight.gate)
                    flightDetail("TERM.", flight.terminal)
                }
            }
        }
    }

    private func flightAirport(city: String, code: String, time: String, trailing: Bool = false) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
            Text(city.isEmpty ? "Ville" : city).font(.tText(12)).foregroundColor(.tTextMute)
            Text(code.isEmpty ? "---" : code).font(.tDisplay(34)).tracking(-1.2)
            Text(time.isEmpty ? "--:--" : time).font(.tText(13, weight: .bold))
        }
    }

    private func flightDetail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.tText(10, weight: .bold)).tracking(1).foregroundColor(.tTextMute)
            Text(value.isEmpty ? "--" : value).font(.tText(14, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shortcutCard(
        glyph: TIcon.Glyph,
        title: String,
        subtitle: String,
        cta: String,
        action: @escaping () -> Void
    ) -> some View {
        TCard(padding: 20) {
            VStack(spacing: 14) {
                IconBubble(glyph: glyph, color: .tAccent2, size: 48)
                Text(title).font(.tDisplay(22))
                Text(subtitle)
                    .font(.tText(14))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                CTA(label: cta, action: action)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func confirmTripCompletion() {
        guard let t = store.activeTrip else { return }
        store.setTripCompleted(id: t.id, completed: true)
        Haptics.success()
        onNav(.completedTrips)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            TCard(padding: 22) {
                VStack(spacing: 12) {
                    TIcon(glyph: .globe, size: 36, stroke: .tAccent2)
                    Text(L("Aucun voyage à afficher")).font(.tDisplay(24))
                    CTA(label: L("Retour aux voyages"), action: { onNav(.trips) })
                }
            }
            .padding(22)
            Spacer()
        }
    }
}

private struct SystemIconBtn: View {
    let systemImage: String
    var stroke: Color = .tText

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.tSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.tBorder, lineWidth: 1)
                )
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(stroke)
        }
        .frame(width: 40, height: 40)
    }
}

private struct TripShareActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
