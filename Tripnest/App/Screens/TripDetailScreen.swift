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
                        VStack(alignment: .leading, spacing: 14) {
                            heroCard(t)
                            detailActions(t)
                            budgetSummary(t)
                            TripPhotosSection(trip: t)
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
        HStack(spacing: 12) {
            Button(action: onBack) {
                IconBtn(glyph: .back)
            }
            .buttonStyle(TripnestPressStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Voyage")
                    .font(.tText(12, weight: .bold))
                    .foregroundColor(.tTextMute)
                Text(store.activeTrip?.homeDestinationTitle ?? "Détails")
                    .font(.tText(17, weight: .bold))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func detailActions(_ trip: Trip) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                detailAction(glyph: .cal, title: "Planning", color: .tMint) { onNav(.tripPlanning) }
                detailAction(glyph: .wallet, title: "Budget", color: .tBlue) { onNav(.tripBudget) }
                detailAction(glyph: .spot, title: "Spots", color: .tRose) { onNav(.spots) }
            }

            HStack(spacing: 10) {
                if trip.transportMode.supportsTravelTicket {
                    detailAction(glyph: .ticket, title: "Billet", color: .tGold) { onNav(.flights) }
                }
                detailAction(glyph: .gallery, title: "Souvenirs", color: .tAccent2) { onNav(.tripSouvenirs) }
            }
        }
    }

    private func detailAction(glyph: TIcon.Glyph, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                TIcon(glyph: glyph, size: 17, stroke: color, strokeWidth: 2)
                Text(title)
                    .font(.tText(13, weight: .bold))
                    .foregroundColor(.tText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.tSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(TripnestPressStyle())
    }

    private func budgetSummary(_ t: Trip) -> some View {
        let sym = defaultCurrency.currencySymbol
        let spotCount = store.spots.filter { $0.tripId == t.id }.count
        let ticketCount = store.flights.filter { $0.tripId == t.id }.count
        let remaining = max(0, t.budget - t.spent)
        let pct = t.budget > 0 ? min(100, Int(Double(t.spent) / Double(t.budget) * 100)) : 0

        return TCard(padding: 16, radius: 18, bg: AnyShapeStyle(Color.tSurface)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Résumé")
                            .font(.tText(16, weight: .bold))
                        Text(t.budget > 0 ? "\(remaining)\(sym) restant" : "Aucun budget défini")
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(.tTextMute)
                    }
                    Spacer()
                    Text(t.budget > 0 ? "\(pct)%" : "--")
                        .font(.tDisplay(22))
                        .foregroundColor(pct > 90 ? .tRose : .tAccent2)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.tAccent2.opacity(0.12)).frame(height: 5)
                        Capsule()
                            .fill(pct > 90 ? Color.tRose : Color.tAccent2)
                            .frame(width: geo.size.width * CGFloat(pct) / 100, height: 5)
                    }
                }
                .frame(height: 5)

                HStack(spacing: 10) {
                    miniStat("\(t.spent)\(sym)", "dépensé", .tBlue)
                    miniStat("\(spotCount)", "spots", .tRose)
                    miniStat("\(ticketCount)", "billets", .tGold)
                    miniStat("\(t.days)", "jours", .tMint)
                }
            }
        }
    }

    private func miniStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.tText(14, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
            Text(label)
                .font(.tText(10, weight: .semibold))
                .foregroundColor(.tTextMute)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Hero

    private func heroStatusColor(_ status: Trip.Status) -> Color {
        switch status {
        case .active:  return .tMint
        case .planned: return .tBlue
        case .done:    return .tGold
        }
    }

    private func heroStatusLabel(_ status: Trip.Status) -> String {
        switch status {
        case .active:  return "VOYAGE EN COURS"
        case .planned: return "VOYAGE PLANIFIÉ"
        case .done:    return "VOYAGE TERMINÉ"
        }
    }

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
            .frame(height: 220)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: Color.tBg0.opacity(0.32), location: 0),
                    .init(color: .clear, location: 0.35),
                    .init(color: Color.tBg0.opacity(0.72), location: 0.8),
                    .init(color: Color.tBg0.opacity(0.98), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(heroStatusColor(t.status))
                        .frame(width: 6, height: 6)
                    Text(heroStatusLabel(t.status))
                        .font(.tText(10, weight: .heavy))
                        .tracking(1.4)
                        .foregroundColor(heroStatusColor(t.status))
                    Spacer(minLength: 8)
                    TripDoneStatusControl(isDone: t.status == .done, style: .detail) { completed in
                        if completed {
                            showCompleteTripAlert = true
                        } else {
                            store.setTripCompleted(id: t.id, completed: false)
                        }
                    }
                }
                Text(t.displayTitle)
                    .font(.tDisplay(36))
                    .tracking(-1.4)
                    .foregroundColor(.white)
                    .lineLimit(2)
                if !t.origin.isEmpty {
                    Text(t.routeLine)
                        .font(.tText(13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.82))
                }
                Text(t.tripSubtitle)
                    .font(.tText(13))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(18)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.tBorderStrong, lineWidth: 1)
        )
        .shadow(color: Color.tBg0.opacity(0.5), radius: 22, x: 0, y: 18)
    }

    /// Bandeau de 4 mini-cartes : dépensé, spots, vols, jours.
    private func statStrip(_ t: Trip) -> some View {
        let sym = defaultCurrency.currencySymbol
        let spotCount = store.spots.filter { $0.tripId == t.id }.count
        let stats: [(label: String, value: String, sub: String, color: Color)] = [
            ("Dépensé", "\(t.spent)\(sym)", "/ \(t.budget)\(sym)", .tAccent2),
            ("Spots", "\(spotCount)", spotCount > 1 ? "sauvés" : "sauvé", .tRose),
            ("Photos", "\(t.photoCount)", t.photoCount > 1 ? "clichés" : "cliché", .tBlue),
            ("Jours", "\(t.days)", t.days > 1 ? "jours" : "jour", .tMint),
        ]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(stats, id: \.label) { stat in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stat.label)
                            .font(.tText(10, weight: .heavy))
                            .tracking(0.4)
                            .foregroundColor(.tTextMute)
                        Text(stat.value)
                            .font(.tDisplay(20))
                            .tracking(-0.5)
                            .foregroundColor(stat.color)
                        Text(stat.sub)
                            .font(.tText(10))
                            .foregroundColor(.tTextMute)
                    }
                    .frame(minWidth: 78, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.tSurface))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
                }
            }
        }
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
