import SwiftUI

struct TripDetailScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onBack: () -> Void = {}
    @State private var tab: DetailTab = .itinerary
    @State private var showCompleteTripAlert = false
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"

    private enum DetailTab: String, CaseIterable {
        case itinerary, budget, spots, flights, notes

        var label: String {
            switch self {
            case .itinerary: return "Itinéraire"
            case .budget: return "Budget"
            case .spots: return "Spots"
            case .flights: return "Vols"
            case .notes: return "Notes"
            }
        }

        var route: AppRoute? {
            switch self {
            case .itinerary: return nil
            case .budget: return .budget
            case .spots: return .spots
            case .flights: return .flights
            case .notes: return .memories
            }
        }
    }

    var body: some View {
        ScreenShell(motif: false) {
            if let t = store.activeTrip {
                VStack(spacing: 0) {
                    topBar
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            heroCard(t)
                            TripPhotosSection(trip: t)
                            statsSection(t)
                            tabSelector
                            tabContent(t)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        .tripnestTabBarScrollPadding()
                    }
                    .tripnestScrollBounceWhenNeeded()
                }
                .safeAreaInset(edge: .bottom) {
                    TabBar(active: .trips, onChange: onNav)
                }
            } else {
                emptyState
            }
        }
        .alert("Archiver ce voyage ?", isPresented: $showCompleteTripAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Oui, archiver") { confirmTripCompletion() }
        } message: {
            if let t = store.activeTrip {
                Text("« \(t.homeDestinationTitle) » sera enregistré dans Voyages passés.")
            }
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
                IconBtn(glyph: .heart)
                IconBtn(glyph: .more)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 4)
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
                tripId: t.id
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 200)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.35),
                    .init(color: Color.tBg0.opacity(0.75), location: 0.75),
                    .init(color: Color.tBg0.opacity(0.95), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                TripDoneStatusControl(isDone: t.status == .done, style: .detail) { completed in
                    if completed {
                        showCompleteTripAlert = true
                    } else {
                        store.setTripCompleted(id: t.id, completed: false)
                    }
                }
                Text(t.displayTitle)
                    .font(.tDisplay(34))
                    .tracking(-1.2)
                    .lineLimit(2)
                if !t.origin.isEmpty {
                    Text(t.routeLine)
                        .font(.tText(14, weight: .semibold))
                        .foregroundColor(.tTextMute)
                }
                Text(t.tripSubtitle)
                    .font(.tText(13))
                    .foregroundColor(.tTextMute)
            }
            .padding(18)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.tBorderStrong, lineWidth: 1)
        )
    }

    // MARK: - Stats

    private func statsSection(_ t: Trip) -> some View {
        let sym = defaultCurrency.currencySymbol
        let spotCount = store.spots.filter { $0.tripId == t.id }.count
        let flightCount = store.flights.filter { $0.tripId == t.id }.count
        let pct = t.budget > 0 ? min(100, Int(Double(t.spent) / Double(t.budget) * 100)) : 0

        return TCard(padding: 16) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    budgetRing(t, pct: pct, sym: sym)
                    VStack(alignment: .leading, spacing: 8) {
                        statLine("Spots enregistrés", "\(spotCount)", .tRose, action: { onNav(.spots) })
                        statLine("Vols suivis", "\(flightCount)", .tBlue, action: { onNav(.flights) })
                        statLine("Durée", "\(t.days) j", .tMint, action: nil)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0xa78bfa, opacity: 0.12)).frame(height: 5)
                        Capsule()
                            .fill(pct > 90 ? Color.tRose : Color.tAccent2)
                            .frame(width: geo.size.width * CGFloat(pct) / 100, height: 5)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text("\(pct)% du budget utilisé")
                        .font(.tText(11))
                        .foregroundColor(.tTextMute)
                    Spacer()
                    Button(action: { onNav(.budget) }) {
                        Text("Voir le budget")
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func budgetRing(_ t: Trip, pct: Int, sym: String) -> some View {
        ProgressRing(value: Double(t.spent), max: Double(max(t.budget, 1)),
                     size: 88, stroke: 8, color: pct > 100 ? .tRose : .tAccent2) {
            VStack(spacing: 0) {
                Text("Dépensé").font(.tText(9, weight: .semibold)).foregroundColor(.tTextMute)
                Text("\(t.spent)\(sym)")
                    .font(.tText(15, weight: .bold))
                    .tracking(-0.3)
                Text("/ \(t.budget)\(sym)")
                    .font(.tText(9))
                    .foregroundColor(.tTextMute)
            }
        }
    }

    private func statLine(_ label: String, _ value: String, _ color: Color, action: (() -> Void)?) -> some View {
        Button(action: { action?() }) {
            HStack {
                Text(label).font(.tText(12)).foregroundColor(.tTextMute)
                Spacer()
                Text(value)
                    .font(.tText(15, weight: .bold))
                    .foregroundColor(color)
                if action != nil {
                    TIcon(glyph: .arrow, size: 12, stroke: .tTextDim)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
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
                                Capsule().stroke(tab == item ? Color.clear : Color.tBorder, lineWidth: 1)
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
                title: "Suivi budget",
                subtitle: "Consulte tes dépenses et ajoute-en de nouvelles.",
                cta: "Ouvrir le budget",
                action: { onNav(.budget) }
            )
        case .spots:
            shortcutCard(
                glyph: .spot,
                title: "Tes spots",
                subtitle: "Restaurants, hôtels et lieux à visiter.",
                cta: "Voir les spots",
                action: { onNav(.spots) }
            )
        case .flights:
            shortcutCard(
                glyph: .plane,
                title: "Tes vols",
                subtitle: "Horaires, portes et numéros de vol.",
                cta: "Voir les vols",
                action: { onNav(.flights) }
            )
        case .notes:
            shortcutCard(
                glyph: .gallery,
                title: "Souvenirs",
                subtitle: "Voyages passés et moments mémorables.",
                cta: "Voir les souvenirs",
                action: { onNav(.memories) }
            )
        }
    }

    private func itinerarySection(_ trip: Trip) -> some View {
        VStack(spacing: 12) {
            TCard(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AUJOURD'HUI")
                                .font(.tText(10, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(.tTextMute)
                            Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                                .font(.tText(16, weight: .bold))
                        }
                        Spacer()
                        IconBubble(glyph: .cal, color: .tAccent2, size: 40)
                    }

                    Divider().background(Color.tBorder)

                    HStack(spacing: 12) {
                        IconBubble(glyph: .spot, color: .tAccent2, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Planifie ta journée")
                                .font(.tText(15, weight: .semibold))
                            Text("Ajoute des spots et des activités pour \(trip.dest).")
                                .font(.tText(13))
                                .foregroundColor(.tTextMute)
                        }
                    }

                    CTA(label: "Ajouter un spot", secondary: true, action: { onNav(.spots) })
                }
            }

            HStack(spacing: 10) {
                quickAction(glyph: .wallet, label: "Dépense", color: .tGold) { onNav(.add) }
                quickAction(glyph: .plane, label: "Vol", color: .tBlue) { onNav(.flights) }
                quickAction(glyph: .spot, label: "Spot", color: .tRose) { onNav(.spots) }
            }
        }
    }

    private func quickAction(glyph: TIcon.Glyph, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                IconBubble(glyph: glyph, color: color, size: 44)
                Text(label)
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.tText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.tSurface))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
        }
        .buttonStyle(TripnestPressStyle())
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
                    Text("Aucun voyage à afficher").font(.tDisplay(24))
                    CTA(label: "Retour aux voyages", action: { onNav(.trips) })
                }
            }
            .padding(22)
            Spacer()
        }
    }
}
