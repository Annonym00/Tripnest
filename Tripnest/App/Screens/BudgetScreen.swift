import SwiftUI

// MARK: - Onglet Budget (choix du voyage)

struct BudgetHubScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"
    @State private var showConverter = false

    private var sym: String { defaultCurrency.currencySymbol }

    private var ongoingTrips: [Trip] {
        store.trips
            .filter { $0.status != .done }
            .sorted { ($0.departureDate ?? .distantFuture) < ($1.departureDate ?? .distantFuture) }
    }

    private var pastTrips: [Trip] {
        store.trips
            .filter { $0.status == .done }
            .sorted { ($0.departureDate ?? .distantPast) > ($1.departureDate ?? .distantPast) }
    }

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                hubHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {

                        // ── Voyages en cours ──────────────────────
                        sectionLabel(L("VOYAGES EN COURS"), color: .tBlue)
                        if ongoingTrips.isEmpty {
                            emptyOngoingTrips
                        } else {
                            ForEach(ongoingTrips) { trip in
                                Button(action: { openTrip(trip) }) {
                                    hubOngoingRow(trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // ── Voyages passés ────────────────────────
                        if !pastTrips.isEmpty {
                            sectionLabel(L("VOYAGES PASSÉS"), color: .tGold)
                                .padding(.top, 6)
                            ForEach(pastTrips) { trip in
                                Button(action: { openTrip(trip) }) {
                                    hubPastRow(trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                    .tripnestTabBarScrollPadding()
                }
                .tripnestScrollBounceWhenNeeded()
            }
            .overlay(alignment: .bottom) {
                TabBar(active: .budget, onChange: onNav)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .sheet(isPresented: $showConverter) {
            CurrencyConverterSheet(defaultCurrency: defaultCurrency)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: Header & section label

    private var hubHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(L("Budget"))
                .font(.tDisplay(24))
                .tracking(-0.5)
            Spacer(minLength: 8)
            Button(action: { showConverter = true; Haptics.impact(.light) }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                    Text(L("Convertisseur"))
                        .font(.tText(13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .frame(height: 36)
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
            .accessibilityLabel(L("Convertir les devises"))
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private func sectionLabel(_ text: String, color: Color = .tTextMute) -> some View {
        Text(text)
            .font(.tText(11, weight: .bold))
            .tracking(1.2)
            .foregroundColor(color)
    }

    // MARK: Empty state

    private var emptyOngoingTrips: some View {
        TCard(padding: 22) {
            VStack(spacing: 10) {
                TIcon(glyph: .plane, size: 28, stroke: .tAccent2)
                Text(L("Aucun voyage actif"))
                    .font(.tText(16, weight: .bold))
                Text(L("Crée ou ouvre un voyage depuis l'onglet Voyages pour gérer son budget ici."))
                    .font(.tText(13))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Row – voyage en cours

    private func hubOngoingRow(_ trip: Trip) -> some View {
        let hasBudget = trip.budget > 0

        return TCard(padding: 16, bg: Self.tripCardBackground) {
            HStack(spacing: 14) {
                tripThumbnail(trip)

                VStack(alignment: .leading, spacing: 4) {
                    titleRow(trip)
                    Text(trip.homeDateLine)
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    Text(hasBudget ? L("En cours") : L("À définir"))
                        .font(.tText(11, weight: .bold))
                        .foregroundColor(hasBudget ? .tMint : .tBlue)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill((hasBudget ? Color.tMint : Color.tBlue).opacity(0.12)))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.tTextMute)
                }
            }
        }
    }

    /// Vignette de couverture du voyage (avec halo ambilight), comme dans Voyages.
    private func tripThumbnail(_ trip: Trip) -> some View {
        TripPhoto(
            destination: trip.dest,
            country: trip.country,
            hue: trip.hue,
            radius: 12,
            coverKind: trip.coverKind,
            tripId: trip.id,
            solidColor: trip.resolvedCoverColor
        )
        .aspectRatio(1, contentMode: .fill)
        .frame(width: 46, height: 46)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background {
            TripRowAmbilight(trip: trip)
                .frame(width: 62, height: 62)
                .allowsHitTesting(false)
        }
    }

    /// Titre du voyage + drapeau à droite, comme dans Voyages.
    private func titleRow(_ trip: Trip) -> some View {
        HStack(spacing: 6) {
            Text(trip.homeDestinationTitle)
                .font(.tText(16, weight: .semibold))
                .foregroundColor(.tText)
                .lineLimit(1)
            let flag = trip.resolvedFlag
            if !flag.isEmpty {
                Text(flag)
                    .font(.system(size: 14))
            }
        }
    }

    // MARK: Row – voyage passé (récap budget stocké)

    private func hubPastRow(_ trip: Trip) -> some View {
        let hasBudget = trip.budget > 0
        let isOver    = hasBudget && trip.spent > trip.budget
        let remaining = trip.budget - trip.spent

        return TCard(padding: 16, bg: Self.tripCardBackground) {
            HStack(spacing: 14) {
                tripThumbnail(trip)

                VStack(alignment: .leading, spacing: 4) {
                    titleRow(trip)
                    Text(trip.homeDateLine)
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if hasBudget {
                    VStack(alignment: .trailing, spacing: 5) {
                        Text(L("Terminé"))
                            .font(.tText(11, weight: .bold))
                            .foregroundColor(.tGold)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.tGold.opacity(0.12)))
                        Text(L("%@ dépensé", "\(trip.spent)\(sym)"))
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(.tText)
                        Text(isOver ? L("Dépassé") : "−\(remaining)\(sym) restant")
                            .font(.tText(11, weight: .bold))
                            .foregroundColor(isOver ? .tRose : .tMint)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.tTextMute)
                    }
                } else {
                    HStack(spacing: 8) {
                        Text(L("Terminé"))
                            .font(.tText(11, weight: .bold))
                            .foregroundColor(.tGold)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.tGold.opacity(0.12)))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.tTextMute)
                    }
                }
            }
        }
    }

    /// Même fond que les cartes de la page Voyages (dégradé surface → surface forte).
    private static let tripCardBackground = AnyShapeStyle(
        LinearGradient(
            colors: [Color.tSurface, Color.tSurfaceStrong],
            startPoint: .top, endPoint: .bottom
        )
    )

    private func openTrip(_ trip: Trip) {
        Haptics.impact(.light)
        store.selectTrip(id: trip.id)
        onNav(.tripBudget)
    }
}

// MARK: - Gestion budget & dépenses (voyage sélectionné)

struct BudgetScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onEditExpense: (String) -> Void = { _ in }
    var onBack: () -> Void = {}

    @State private var showBudgetEditor      = false
    @State private var showBudgetVisibility  = false
    @State private var showEmergencyFundSheet = false
    @State private var budgetInput           = ""
    @State private var budgetMode            = BudgetMode.define
    @State private var emergencyInput      = ""
    @State private var emergencyCause      = ""
    @State private var emergencyNotes      = ""
    @State private var emergencyEditingEntryId: String?
    @State private var emergencyPendingDelete: String?
    @State private var expensePendingDelete: String?
    @State private var lastAnimatedSpent: Int?
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"

    private let maxEmergencyDescriptionLines = 150

    private struct CategoryRecapItem: Identifiable {
        let id: String
        let title: String
        let expenseCategory: String
        let budgetWeight: Double
        let glyph: TIcon.Glyph
        let color: Color
    }

    private let categoryRecapItems: [CategoryRecapItem] = [
        .init(id: "hotel", title: "Hébergement", expenseCategory: "Hôtel", budgetWeight: 700.0 / 1850.0, glyph: .hotel, color: .tRose),
        .init(id: "food", title: "Restaurants", expenseCategory: "Repas", budgetWeight: 450.0 / 1850.0, glyph: .food, color: .tGold),
        .init(id: "transport", title: "Transport", expenseCategory: "Transport", budgetWeight: 250.0 / 1850.0, glyph: .bus, color: .tBlue),
        .init(id: "activity", title: "Activités", expenseCategory: "Activité", budgetWeight: 300.0 / 1850.0, glyph: .ticket, color: .tMint),
        .init(id: "gift", title: "Souvenirs", expenseCategory: "Souvenir", budgetWeight: 150.0 / 1850.0, glyph: .gift, color: .tAccent2),
    ]

    private enum BudgetMode: String, CaseIterable {
        case define = "Définir"
        case add    = "Ajouter"
    }

    private var sym: String { defaultCurrency.currencySymbol }

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if let t = store.activeTrip {
                            if t.budget == 0 {
                                noBudgetState(t).padding(.bottom, 14)
                            } else {
                                ring(t)
                                    .padding(.top, 6)
                                    .padding(.bottom, 14)
                                budgetActions(t).padding(.bottom, 14)
                                emergencyFundCard(t).padding(.bottom, 14)
                                txHeader.padding(.bottom, 10)
                                expensesSections(tripId: t.id)
                                CTA(label: L("Ajouter une dépense"), action: { onNav(.add) })
                                    .padding(.top, 14)
                            }
                        } else {
                            missingTripState
                        }
                    }
                    .padding(.horizontal, 18)
                    .tripnestTabBarScrollPadding()
                }
            }
        }
        .swipeBack(enabled: true, onBack: onBack)
        .sheet(isPresented: $showBudgetVisibility) {
            budgetVisibilitySheet
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showBudgetEditor) {
            budgetEditorSheet
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showEmergencyFundSheet) {
            emergencyFundSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
        }
        .alert(L("Supprimer cette dépense ?"), isPresented: expenseDeleteAlertBinding) {
            Button(L("Annuler"), role: .cancel) { expensePendingDelete = nil }
            Button(L("Supprimer"), role: .destructive) {
                if let id = expensePendingDelete {
                    store.deleteExpense(id: id)
                    Haptics.success()
                }
                expensePendingDelete = nil
            }
        } message: {
            Text(L("Cette action est définitive."))
        }
        .onChange(of: store.activeTrip?.spent) { _, newValue in
            guard let newValue else { return }
            animateSpentChange(newValue)
        }
        .onChange(of: store.activeTrip?.id) { _, _ in
            lastAnimatedSpent = store.activeTrip?.spent
        }
    }

    private var expenseDeleteAlertBinding: Binding<Bool> {
        Binding(
            get: { expensePendingDelete != nil },
            set: { if !$0 { expensePendingDelete = nil } }
        )
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.tAccent2)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.tAccent2.opacity(0.10))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("Revenir"))

            VStack(alignment: .leading, spacing: 2) {
                Text(L("Budget"))
                    .font(.tDisplay(22))
                    .tracking(-0.5)
                    .foregroundColor(.tText)
                Text(store.activeTrip?.homeDestinationTitle ?? "Voyage")
                    .font(.tText(12))
                    .foregroundColor(.tTextMute)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: - Budget action buttons (Modifier / Ajouter)

    private func budgetActions(_ t: Trip) -> some View {
        HStack(spacing: 10) {
            // Récap – budget breakdown (base, spent, remaining)
            Button(action: {
                showBudgetVisibility = true
                Haptics.impact(.light)
            }) {
                HStack(spacing: 7) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 13, weight: .semibold))
                    Text(L("Récap"))
                        .font(.tText(14, weight: .semibold))
                }
                .foregroundColor(.tText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.tSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.tBorder, lineWidth: 1)
                )
            }
            .buttonStyle(TripnestPressStyle())

            Button(action: {
                budgetInput = ""
                budgetMode  = .add
                showBudgetEditor = true
                Haptics.impact(.light)
            }) {
                HStack(spacing: 7) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text(L("Modifier le budget"))
                        .font(.tText(14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.tAccent2)
                )
            }
            .buttonStyle(TripnestPressStyle())
        }
    }

    // MARK: - No budget state

    private func noBudgetState(_ t: Trip) -> some View {
        TCard(padding: 22, glow: true) {
            VStack(spacing: 14) {
                TIcon(glyph: .wallet, size: 36, stroke: .tAccent2)
                Text(L("Définis ton budget"))
                    .font(.tDisplay(22))
                Text(L("Ajoute un montant pour suivre tes dépenses pendant le voyage."))
                    .font(.tText(14))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                CTA(label: L("Définir un budget"), action: {
                    budgetInput = ""
                    budgetMode  = .define
                    showBudgetEditor = true
                })
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Budget visibility sheet (Récap)

    private var budgetVisibilitySheet: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                if let t = store.activeTrip {
                    let remaining = t.budget - t.spent
                    let pct = min(1.0, Double(t.spent) / Double(max(1, t.budget)))
                    VStack(alignment: .leading, spacing: 18) {
                        TCard(padding: 18, glow: true) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L("Budget total"))
                                            .font(.tText(12, weight: .semibold))
                                            .foregroundColor(.tTextMute)
                                        Text("\(t.budget)\(sym)")
                                            .font(.tDisplay(34))
                                            .tracking(-0.8)
                                            .foregroundColor(.tText)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(remaining < 0 ? L("Dépassement") : "Reste")
                                            .font(.tText(12, weight: .semibold))
                                            .foregroundColor(.tTextMute)
                                        Text("\(remaining)\(sym)")
                                            .font(.tText(22, weight: .bold))
                                            .foregroundColor(remaining < 0 ? .tRose : .tMint)
                                    }
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color.tBorder.opacity(0.82))
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(pct >= 1 ? Color.tRose : Color.tAccent2)
                                            .frame(width: geo.size.width * pct)
                                            .animation(TripnestAnimation.budgetMoney, value: pct)
                                    }
                                }
                                .frame(height: 10)

                                HStack {
                                    Text(L("%@ dépensés", "\(t.spent)\(sym)"))
                                    Spacer()
                                    Text(L("%d%% utilisé", Int(pct * 100)))
                                }
                                .font(.tText(12, weight: .semibold))
                                .foregroundColor(.tTextMute)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text(L("PAR CATÉGORIE"))
                                .font(.tText(13, weight: .bold))
                                .tracking(0.9)
                                .foregroundColor(.tTextMute)

                            TCard(padding: 0) {
                                VStack(spacing: 0) {
                                    ForEach(Array(categoryRecapItems.enumerated()), id: \.element.id) { index, item in
                                        categoryRecapRow(item, trip: t)
                                        if index < categoryRecapItems.count - 1 {
                                            Rectangle()
                                                .fill(Color.tBorder)
                                                .frame(height: 1)
                                                .padding(.horizontal, 8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(L("Récapitulatif"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { showBudgetVisibility = false }.foregroundColor(.tAccent2)
                }
            }
        }
        .tripnestPreferredColorScheme()
    }

    private func categoryRecapRow(_ item: CategoryRecapItem, trip: Trip) -> some View {
        let spent = completedSpent(for: item.expenseCategory, tripId: trip.id)
        let allocated = max(1, Int((Double(trip.budget) * item.budgetWeight).rounded()))
        let pct = min(1.0, Double(spent) / Double(max(1, allocated)))

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(item.color.opacity(0.14))
                TIcon(glyph: item.glyph, size: 18, stroke: item.color, strokeWidth: 2)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(L(item.title))
                        .font(.tText(15, weight: .bold))
                        .foregroundColor(.tText)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    (
                        Text("\(spent)\(sym)")
                            .font(.tText(15, weight: .bold))
                            .foregroundColor(.tText)
                        + Text(" / \(allocated)\(sym)")
                            .font(.tText(13, weight: .semibold))
                            .foregroundColor(.tTextMute)
                    )
                    .lineLimit(1)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.tBorder.opacity(0.82))
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(item.color)
                            .frame(width: max(8, geo.size.width * pct))
                            .animation(TripnestAnimation.budgetMoney, value: pct)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func completedSpent(for category: String, tripId: String) -> Int {
        store.expenses
            .filter { $0.tripId == tripId && $0.status == .completed && $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }

    private func visibilityRow(
        systemImage: String,
        label: String,
        valueText: String,
        color: Color,
        isHighlight: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.tText(14, weight: isHighlight ? .bold : .semibold))
                .foregroundColor(.tText)
            Spacer(minLength: 8)
            Text(valueText)
                .font(.tText(isHighlight ? 17 : 15, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, isHighlight ? 18 : 14)
        .background(isHighlight ? color.opacity(0.07) : Color.clear)
    }

    // MARK: - Budget editor sheet

    private var budgetEditorSheet: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                VStack(spacing: 20) {
                    if let trip = store.activeTrip, trip.budget > 0 {
                        Picker("", selection: $budgetMode) {
                            ForEach(BudgetMode.allCases, id: \.self) { mode in
                                Text(L(mode.rawValue)).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: budgetMode) { _, newMode in
                            budgetInput = newMode == .define ? "\(trip.budget)" : ""
                        }
                    }

                    VStack(spacing: 6) {
                        Text(budgetMode == .define ? L("NOUVEAU BUDGET TOTAL") : L("MONTANT À AJOUTER"))
                            .font(.tText(12, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.tTextMute)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            TextField("0", text: $budgetInput)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.tDisplay(48, weight: .bold))
                                .tracking(-2)
                                .foregroundColor(.tText)
                                .frame(maxWidth: 220)
                                .onChange(of: budgetInput) { _, newValue in
                                    budgetInput = digitsOnly(newValue)
                                }
                            Text(sym).font(.tText(24, weight: .bold)).foregroundColor(.tTextMute)
                        }
                        // Preview total in "Ajouter" mode
                        if budgetMode == .add,
                           let trip = store.activeTrip,
                           let added = Int(budgetInput), added > 0 {
                            Text(L("→ Budget total : %@", "\(trip.budget + added)\(sym)"))
                                .font(.tText(13))
                                .foregroundColor(.tTextMute)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    CTA(label: "Enregistrer", action: saveBudget)
                        .opacity((Int(budgetInput) ?? 0) > 0 ? 1 : 0.45)
                        .disabled((Int(budgetInput) ?? 0) <= 0)
                }
                .padding(28)
            }
            .navigationTitle(budgetMode == .define ? L("Modifier le budget") : L("Ajouter au budget"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { showBudgetEditor = false }.foregroundColor(.tAccent2)
                }
            }
        }
        .tripnestPreferredColorScheme()
    }

    private func saveBudget() {
        guard let amount = Int(budgetInput), amount > 0, let trip = store.activeTrip else { return }
        switch budgetMode {
        case .define:
            store.updateBudget(tripId: trip.id, budget: amount)
        case .add:
            store.updateBudget(tripId: trip.id, budget: trip.budget + amount)
        }
        Haptics.success()
        showBudgetEditor = false
    }

    // MARK: - Fond d'urgence

    private func emergencyFundCard(_ t: Trip) -> some View {
        TCard(padding: 4) {
            Button(action: {
                emergencyInput = ""
                emergencyCause = ""
                emergencyNotes = ""
                emergencyEditingEntryId = nil
                store.setEmergencyFundEnabled(tripId: t.id, enabled: true)
                showEmergencyFundSheet = true
                Haptics.impact(.light)
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.tGold.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.tGold)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L("Fond d'urgence"))
                            .font(.tText(15, weight: .semibold))
                            .foregroundColor(.tText)
                        Text(L("%d fond(s) stocké(s) · %@", store.emergencyEntries(for: t.id).count, "\(t.emergencyFund)\(sym)"))
                            .font(.tText(12))
                            .foregroundColor(.tTextMute)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.tTextMute)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var emergencyFundSheet: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(spacing: 8) {
                            Text(L("MONTANT"))
                                .font(.tText(11, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.tTextMute)
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                TextField("0", text: $emergencyInput)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .font(.tDisplay(52, weight: .bold))
                                    .tracking(-2)
                                    .foregroundColor(.tGold)
                                    .frame(maxWidth: 220)
                                    .onChange(of: emergencyInput) { _, newValue in
                                        emergencyInput = digitsOnly(newValue)
                                    }
                                Text(sym)
                                    .font(.tText(24, weight: .bold))
                                    .foregroundColor(.tTextMute)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text(L("TITRE"))
                                .font(.tText(11, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.tTextMute)
                            TextField(L("Ex. réparation, médicament, taxi…"), text: $emergencyCause)
                                .font(.tText(15))
                                .foregroundColor(.tText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.tGold.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.tBorderStrong, lineWidth: 1)
                                )
                        }

                        emergencyDescriptionSection

                        if emergencyEditingEntryId != nil {
                            HStack(spacing: 10) {
                                CTA(label: "Enregistrer", action: saveEmergencyEntry)
                                    .opacity(canSaveEmergencyEntry ? 1 : 0.45)
                                    .disabled(!canSaveEmergencyEntry)
                                Button(action: cancelEmergencyEdit) {
                                    Text(L("Annuler"))
                                        .font(.tText(14, weight: .bold))
                                        .foregroundColor(.tText)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color.tSurface)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.tBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            CTA(label: L("Ajouter au fond"), action: saveEmergencyEntry)
                                .opacity(canSaveEmergencyEntry ? 1 : 0.45)
                                .disabled(!canSaveEmergencyEntry)
                        }

                        if let trip = store.activeTrip {
                            let entries = store.emergencyEntries(for: trip.id)
                            if !entries.isEmpty {
                                Text(L("DANS LE FOND"))
                                    .font(.tText(11, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundColor(.tTextMute)
                                    .padding(.top, 4)

                                TCard(padding: 4) {
                                    VStack(spacing: 0) {
                                        ForEach(Array(entries.enumerated()), id: \.element.id) { i, entry in
                                            emergencyEntryRow(entry)
                                            if i < entries.count - 1 {
                                                Rectangle().fill(Color.tBorder).frame(height: 1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(22)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(L("Fond d'urgence"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { showEmergencyFundSheet = false }.foregroundColor(.tAccent2)
                }
            }
        }
        .tripnestPreferredColorScheme()
        .alert(L("Supprimer ce fond ?"), isPresented: emergencyDeleteAlertBinding) {
            Button(L("Annuler"), role: .cancel) { emergencyPendingDelete = nil }
            Button(L("Supprimer"), role: .destructive) {
                if let id = emergencyPendingDelete {
                    store.deleteEmergencyFundEntry(id: id)
                    Haptics.success()
                }
                emergencyPendingDelete = nil
            }
        } message: {
            Text(L("Ce fond sera retiré du portefeuille urgence."))
        }
    }

    private var emergencyDeleteAlertBinding: Binding<Bool> {
        Binding(
            get: { emergencyPendingDelete != nil },
            set: { if !$0 { emergencyPendingDelete = nil } }
        )
    }

    private var canSaveEmergencyEntry: Bool {
        (Int(emergencyInput) ?? 0) > 0
    }

    private var emergencyDescriptionLineCount: Int {
        max(1, emergencyNotes.components(separatedBy: .newlines).count)
    }

    private var emergencyDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L("DESCRIPTION"))
                    .font(.tText(11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.tTextMute)
                Spacer()
                Text(L("%d/%d lignes", emergencyDescriptionLineCount, maxEmergencyDescriptionLines))
                    .font(.tText(11))
                    .foregroundColor(emergencyDescriptionLineCount >= maxEmergencyDescriptionLines ? .tRose : .tTextMute)
            }

            ZStack(alignment: .topLeading) {
                if emergencyNotes.isEmpty {
                    Text(L("Détails de l'urgence…"))
                        .font(.tText(15))
                        .foregroundColor(.tTextMute.opacity(0.5))
                        .padding(.top, 14)
                        .padding(.leading, 18)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $emergencyNotes)
                    .font(.tText(15))
                    .foregroundColor(.tText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90, maxHeight: 140)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .keyboardDoneBar()
                    .onChange(of: emergencyNotes) { _, newValue in
                        emergencyNotes = clampEmergencyDescriptionLines(newValue)
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.tGold.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tBorderStrong, lineWidth: 1)
            )
        }
    }

    private func emergencyEntryRow(_ entry: EmergencyFundEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.cause)
                    .font(.tText(14, weight: .semibold))
                    .foregroundColor(.tText)
                    .lineLimit(2)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)
                if !entry.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(entry.notes)
                        .font(.tText(11))
                        .foregroundColor(.tTextMute)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            Text("\(entry.amount)\(sym)")
                .font(.tText(15, weight: .bold))
                .foregroundColor(.tGold)
            Button(action: { withdrawEmergencyEntry(entry.id) }) {
                Text(L("Retirer"))
                    .font(.tText(12, weight: .bold))
                    .foregroundColor(.tMint)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(Capsule().fill(Color.tMint.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("Retirer ce fond"))
            Button(action: { startEmergencyEdit(entry) }) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.tAccent2)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.tAccent2.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("Modifier ce fond"))
            Button(action: { emergencyPendingDelete = entry.id }) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.tRose)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.tRose.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("Supprimer ce fond"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func saveEmergencyEntry() {
        guard let trip = store.activeTrip else { return }
        let amount = max(0, Int(emergencyInput) ?? 0)
        guard amount > 0 else { return }
        if let id = emergencyEditingEntryId {
            store.updateEmergencyFundEntry(id: id, amount: amount, cause: emergencyCause, notes: emergencyNotes)
        } else {
            store.addEmergencyFundEntry(tripId: trip.id, amount: amount, cause: emergencyCause, notes: emergencyNotes)
        }
        cancelEmergencyEdit()
        Haptics.success()
    }

    private func startEmergencyEdit(_ entry: EmergencyFundEntry) {
        emergencyEditingEntryId = entry.id
        emergencyInput = "\(entry.amount)"
        emergencyCause = entry.cause
        emergencyNotes = entry.notes
        Haptics.impact(.light)
    }

    private func cancelEmergencyEdit() {
        emergencyEditingEntryId = nil
        emergencyInput = ""
        emergencyCause = ""
        emergencyNotes = ""
    }

    private func withdrawEmergencyEntry(_ id: String) {
        store.withdrawEmergencyFundEntry(id: id, currency: defaultCurrency)
        Haptics.success()
    }

    private func clampEmergencyDescriptionLines(_ text: String) -> String {
        var lines = text.components(separatedBy: .newlines)
        if lines.count > maxEmergencyDescriptionLines {
            lines = Array(lines.prefix(maxEmergencyDescriptionLines))
            return lines.joined(separator: "\n")
        }
        return text
    }

    private func digitsOnly(_ text: String) -> String {
        text.filter(\.isNumber)
    }

    private func animateSpentChange(_ newSpent: Int) {
        guard let oldSpent = lastAnimatedSpent else {
            lastAnimatedSpent = newSpent
            return
        }
        guard oldSpent != newSpent else { return }
        withAnimation(TripnestAnimation.budgetMoney) {
            lastAnimatedSpent = newSpent
        }
    }

    // MARK: - Ring card

    private func ring(_ t: Trip) -> some View {
        let isOver     = t.spent > t.budget && t.budget > 0
        let remaining  = t.budget - t.spent
        let available  = t.budget - t.emergencyFund - t.spent
        let statusColor: Color = isOver ? .tRose : .tMint
        let ringColor:   Color = isOver ? .tRose : .tAccent2

        return TCard(padding: 22, glow: true) {
            VStack(spacing: 0) {
                // ── Main row ──────────────────────────────────────
                HStack(spacing: 18) {
                    ProgressRing(
                        value: Double(t.spent),
                        max: Double(max(1, t.budget)),
                        size: 130, stroke: 11, color: ringColor
                    ) {
                        VStack(spacing: 0) {
                            Text(L("Dépensé")).font(.tText(11)).foregroundColor(.tTextMute)
                            AnimatedCurrencyAmount(value: t.spent, symbol: sym)
                            AnimatedCurrencyAmount(
                                value: t.budget,
                                symbol: sym,
                                font: .tText(11),
                                tracking: 0,
                                color: .tTextMute,
                                prefix: "/ "
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(isOver ? L("Dépassement") : "Reste")
                            .font(.tText(12)).foregroundColor(.tTextMute)
                        AnimatedCurrencyAmount(
                            value: remaining,
                            symbol: sym,
                            font: .tDisplay(32),
                            tracking: -0.8,
                            color: statusColor
                        )
                        if !isOver && t.days > 0 {
                            Text(L("≈ %@/jour", "\(remaining / t.days)\(sym)"))
                                .font(.tText(12)).foregroundColor(.tTextMute)
                        }
                        HStack(spacing: 6) {
                            TIcon(glyph: isOver ? .close : .check, size: 14, stroke: statusColor)
                            Text(isOver ? L("Budget dépassé") : L("Dans le budget"))
                                .font(.tText(12, weight: .semibold)).foregroundColor(statusColor)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(statusColor.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(statusColor.opacity(0.20), lineWidth: 1)
                        )
                        .padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                }

                // ── Emergency fund rows (only when set) ───────────
                if t.emergencyFundEnabled {
                    Divider()
                        .background(Color.tBorder)
                        .padding(.vertical, 12)

                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.tGold)
                            Text(L("Fond d'urgence"))
                                .font(.tText(13, weight: .semibold))
                                .foregroundColor(.tTextMute)
                            Spacer()
                            Text("\(t.emergencyFund)\(sym)")
                                .font(.tText(15, weight: .bold))
                                .foregroundColor(.tGold)
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(available < 0 ? .tRose : .tMint)
                            Text(L("Disponible réel"))
                                .font(.tText(13, weight: .semibold))
                                .foregroundColor(.tTextMute)
                            Spacer()
                            Text("\(available)\(sym)")
                                .font(.tText(15, weight: .bold))
                                .foregroundColor(available < 0 ? .tRose : .tMint)
                        }
                    }
                }
            }
        }
    }

    // MARK: - DÉPENSES header

    private var txHeader: some View {
        Text(L("MES DÉPENSES"))
            .font(.tText(14, weight: .bold))
            .foregroundColor(.tText)
            .tracking(0.4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Expense sections

    @ViewBuilder
    private func expensesSections(tripId: String) -> some View {
        let upcoming  = store.upcomingExpenses(for: tripId)
        let completed = store.completedExpenses(for: tripId)

        VStack(alignment: .leading, spacing: 16) {
            expenseSection(
                title: L("DÉPENSES À VENIR"),
                expenses: upcoming,
                upcoming: true,
                emptyHint: upcoming.isEmpty ? L("Aucune dépense planifiée.") : nil
            )

            expenseSection(
                title: L("DÉPENSES EFFECTUÉES"),
                expenses: completed,
                upcoming: false,
                emptyHint: completed.isEmpty ? L("Tes dépenses payées apparaîtront ici.") : nil
            )
        }
        .padding(.bottom, 10)
    }

    private func expenseSection(
        title: String,
        expenses: [Expense],
        upcoming: Bool,
        emptyHint: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.tText(11, weight: .bold))
                .tracking(1.2)
                .foregroundColor(.tTextMute)

            TCard(padding: 4) {
                if expenses.isEmpty, let emptyHint {
                    Text(emptyHint)
                        .font(.tText(13))
                        .foregroundColor(.tTextMute)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(expenses.enumerated()), id: \.element.id) { i, expense in
                            expenseRow(expense, upcoming: upcoming)
                            if i < expenses.count - 1 {
                                Rectangle().fill(Color.tBorder).frame(height: 1)
                            }
                        }
                    }
                }
            }
        }
    }

    private func expenseRow(_ expense: Expense, upcoming: Bool) -> some View {
        let rowColor = color(for: expense.category)
        let rowGlyph = glyph(for: expense.category)
        let cur      = expense.currency ?? "EUR"
        let isEmergency = expense.category == "Urgence"

        return HStack(spacing: 12) {
            expenseStatusToggle(expense: expense, upcoming: upcoming)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(rowColor.opacity(upcoming ? 0.08 : 0.13))
                    if isEmergency {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(rowColor)
                    } else {
                        TIcon(glyph: rowGlyph, size: 16, stroke: rowColor)
                    }
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(expense.label)
                        .font(.tText(14, weight: .semibold))
                        .foregroundColor(.tText)
                        .lineLimit(1)
                    expenseMetaView(expense)
                    if expense.rating > 0 {
                        HStack(spacing: 4) {
                            let sc = starColor(expense.rating)
                            TIcon(glyph: .star, size: 10, stroke: sc, fill: sc)
                            Text("\(expense.rating, specifier: "%.1f")")
                                .font(.tText(11, weight: .semibold))
                                .foregroundColor(sc)
                        }
                    }
                }

                Spacer(minLength: 8)

                Text("\(upcoming ? "" : "−")\(expense.amount)\(cur.currencySymbol)")
                    .font(.tText(15, weight: .bold))
                    .foregroundColor(upcoming ? .tBlue : (isEmergency ? .tGold : .tText))

                Button(action: { expensePendingDelete = expense.id }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.tRose)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.tRose.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("Supprimer cette dépense"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { onEditExpense(expense.id) }
        .accessibilityLabel(L("Modifier %@", expense.label))
    }

    private func expenseActionChip(
        title: String,
        glyph: TIcon.Glyph,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                TIcon(glyph: glyph, size: 13, stroke: accent)
                Text(title)
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.tText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accent.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(accent.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(TripnestPressStyle())
    }

    private func expenseStatusToggle(expense: Expense, upcoming: Bool) -> some View {
        let tint: Color = upcoming ? .tGold : .tMint
        return Button {
            let next: ExpenseStatus = upcoming ? .completed : .upcoming
            withAnimation(TripnestAnimation.budgetMoney) {
                store.setExpenseStatus(id: expense.id, status: next)
            }
            if upcoming { Haptics.impact(.medium) } else { Haptics.impact(.light) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(upcoming ? Color.clear : tint)
                    .frame(width: 26, height: 26)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(upcoming ? Color.tBorderStrong : tint, lineWidth: upcoming ? 1.5 : 0)
                    .frame(width: 26, height: 26)
                if !upcoming {
                    TIcon(glyph: .check, size: 14, stroke: .white, strokeWidth: 2.5)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(upcoming ? L("Marquer comme effectuée") : L("Marquer comme à venir"))
    }

    // MARK: - Formatters & helpers

    private static let _expenseDateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private func expenseMetaLine(_ expense: Expense) -> String {
        var parts = [Self._expenseDateFmt.string(from: expense.date), expense.category]
        let place = expense.location.trimmingCharacters(in: .whitespacesAndNewlines)
        if !place.isEmpty { parts.append(place) }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func expenseMetaView(_ expense: Expense) -> some View {
        let date = Self._expenseDateFmt.string(from: expense.date)
        let place = expense.location.trimmingCharacters(in: .whitespacesAndNewlines)
        if expense.category == "Urgence" {
            (
                Text("\(date) · ")
                    .foregroundColor(.tTextMute)
                + Text(L("Urgence"))
                    .foregroundColor(.tRose)
                + Text(place.isEmpty ? "" : " · \(place)")
                    .foregroundColor(.tTextMute)
            )
            .font(.tText(11))
            .lineLimit(2)
        } else {
            Text(expenseMetaLine(expense))
                .font(.tText(11))
                .foregroundColor(.tTextMute)
                .lineLimit(2)
        }
    }

    private func starColor(_ rating: Double) -> Color {
        if rating < 2.5 { return Color(hex: 0xff3b30) }
        if rating < 4   { return .tGold }
        return .tMint
    }

    private var emptyBudget: some View {
        TCard(padding: 22) {
            VStack(spacing: 10) {
                TIcon(glyph: .wallet, size: 34, stroke: .tAccent2)
                Text(L("Aucune dépense enregistrée")).font(.tDisplay(22))
                Text(L("Ajoute tes dépenses réelles pour suivre ton budget."))
                    .font(.tText(14)).foregroundColor(.tTextMute).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var missingTripState: some View {
        TCard(padding: 22) {
            VStack(spacing: 10) {
                TIcon(glyph: .wallet, size: 34, stroke: .tAccent2)
                Text(L("Aucun voyage sélectionné")).font(.tDisplay(22))
                Text(L("Choisis un voyage pour gérer son budget."))
                    .font(.tText(14)).foregroundColor(.tTextMute).multilineTextAlignment(.center)
                CTA(label: L("Revenir"), action: onBack).padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func glyph(for category: String) -> TIcon.Glyph {
        switch category {
        case "Hôtel": return .hotel
        case "Transport": return .bus
        case "Activité": return .ticket
        case "Souvenir": return .gift
        default: return .food
        }
    }

    private func color(for category: String) -> Color {
        switch category {
        case "Urgence": return .tGold
        case "Hôtel": return .tRose
        case "Transport": return .tBlue
        case "Activité": return .tMint
        case "Souvenir": return .tAccent2
        default: return .tGold
        }
    }
}

// MARK: - Currency Service

@MainActor
final class CurrencyService: ObservableObject {
    @Published var rates: [String: Double] = [:]
    @Published var rateDate: String = ""
    @Published var isLoading = false
    @Published var isOffline = false

    private static let cacheRatesKey = "tripnest.currencyRates.v2"
    private static let cacheDateKey  = "tripnest.currencyRatesDate.v2"

    // Approximate fallback rates relative to EUR (2025)
    static let fallback: [String: Double] = [
        "EUR": 1.00,  "USD": 1.08,  "GBP": 0.86,  "JPY": 162.0, "CHF": 0.96,
        "CAD": 1.47,  "AUD": 1.65,  "CNY": 7.82,  "INR": 90.1,  "BRL": 5.45,
        "MXN": 18.6,  "KRW": 1450.0,"SGD": 1.45,  "HKD": 8.42,  "NOK": 11.4,
        "SEK": 11.2,  "DKK": 7.46,  "NZD": 1.77,  "ZAR": 20.2,  "TRY": 34.8,
        "AED": 3.97,  "SAR": 4.05,  "THB": 38.5,  "MAD": 10.8,  "TND": 3.35,
        "EGP": 52.3,  "IDR": 17200.0,"PLN": 4.28, "CZK": 25.1,  "HUF": 390.0,
        "RON": 4.97,  "BGN": 1.96,  "MYR": 5.06,  "PHP": 63.2,  "VND": 27300.0,
        "TWD": 34.9,  "PKR": 299.0, "BDT": 128.0, "CLP": 995.0, "COP": 4650.0,
        "ARS": 985.0, "PEN": 4.08,  "UAH": 44.2,  "ILS": 4.02,  "QAR": 3.94,
        "KWD": 0.332, "BHD": 0.408, "OMR": 0.416, "JOD": 0.766, "NGN": 1710.0,
        "GHS": 16.4,  "KES": 138.0, "TZS": 2790.0,"DZD": 145.0, "LYD": 5.21,
        "MUR": 50.2,  "ISK": 149.0, "HRK": 7.53,  "RSD": 117.0, "ALL": 103.0,
        "BAM": 1.96,  "MDL": 19.4,  "GEL": 2.96,  "AMD": 431.0, "AZN": 1.84,
        "KZT": 497.0, "UZS": 13800.0,"MNT": 3720.0,"KHR": 4380.0,"NPR": 143.0,
        "LKR": 335.0, "MVR": 16.6,  "BND": 1.45,  "PGK": 4.25,  "NIO": 39.6,
        "GTQ": 8.42,  "DOP": 64.0,  "JMD": 169.0, "TTD": 7.33,  "GYD": 226.0,
        "PYG": 8350.0,"BOB": 7.49,  "UYU": 43.8,  "CRC": 566.0, "RUB": 98.5,
        "BYN": 3.54,  "XOF": 655.0, "XAF": 655.0,
    ]

    func fetchRates() async {
        isLoading = true
        isOffline = false
        defer { isLoading = false }
        do {
            let url = URL(string: "https://api.frankfurter.app/latest?base=EUR")!
            let (data, _) = try await URLSession.shared.data(from: url)
            struct Resp: Decodable { let rates: [String: Double]; let date: String }
            let response = try JSONDecoder().decode(Resp.self, from: data)
            var rateMap = response.rates
            rateMap["EUR"] = 1.0
            // frankfurter.app couvre ~33 devises ; on complète avec le fallback
            // pour toutes les devises absentes (VND, INR, etc.)
            for (code, rate) in Self.fallback where rateMap[code] == nil {
                rateMap[code] = rate
            }
            rates = rateMap
            rateDate = response.date
            if let enc = try? JSONEncoder().encode(rateMap) {
                UserDefaults.standard.set(enc, forKey: Self.cacheRatesKey)
                UserDefaults.standard.set(response.date, forKey: Self.cacheDateKey)
            }
        } catch {
            isOffline = true
            if let cached = UserDefaults.standard.data(forKey: Self.cacheRatesKey),
               let decoded = try? JSONDecoder().decode([String: Double].self, from: cached) {
                rates    = decoded
                rateDate = UserDefaults.standard.string(forKey: Self.cacheDateKey) ?? ""
            } else {
                rates    = Self.fallback
                rateDate = ""
            }
        }
    }

    func convert(_ amount: Double, from: String, to: String) -> Double? {
        // Fallback covers exotic currencies; live rates override where available
        var r = Self.fallback
        for (k, v) in rates { r[k] = v }
        guard let fRate = r[from], let tRate = r[to], fRate > 0 else { return nil }
        return amount * (tRate / fRate)
    }
}

// MARK: - Currency Converter Sheet

struct CurrencyConverterSheet: View {
    var defaultCurrency: String = "EUR"
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = CurrencyService()

    @State private var amountText = ""
    @State private var fromCode: String = "EUR"
    @State private var toCode:   String = "USD"
    @State private var pickingFrom = false
    @State private var pickingTo   = false
    @State private var savedConversions: [SavedConversion] = []

    private struct SavedConversion: Identifiable {
        let id   = UUID()
        let fromAmount: Double
        let fromCode:   String
        let toAmount:   Double
        let toCode:     String
        let date:       Date
    }

    // All world currencies, sorted by name — built once at module load
    static let allCurrencies: [(code: String, name: String)] = {
        Locale.commonISOCurrencyCodes
            .compactMap { code -> (String, String)? in
                guard let name = Locale.current.localizedString(forCurrencyCode: code),
                      !name.isEmpty else { return nil }
                return (code, name)
            }
            .sorted { $0.1 < $1.1 }
    }()

    private var inputAmount: Double {
        Double(amountText) ?? 0
    }
    private var result: Double? { service.convert(inputAmount, from: fromCode, to: toCode) }

    private var fromName: String { Self.allCurrencies.first { $0.code == fromCode }?.name ?? fromCode }
    private var toName:   String { Self.allCurrencies.first { $0.code == toCode   }?.name ?? toCode   }

    private static let _numFmt: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()
    private static let _rateFmt: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 5
        f.minimumFractionDigits = 2
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Source field
                        currencyField(
                            label: "MONTANT",
                            code: fromCode, name: fromName,
                            displayText: amountText,
                            isInput: true,
                            onPickCurrency: { pickingFrom = true }
                        )

                        // Swap button
                        Button {
                            swap(&fromCode, &toCode)
                            Haptics.impact(.light)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.tSurface)
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.tAccent2)
                            }
                        }
                        .buttonStyle(TripnestPressStyle())

                        // Result field
                        let resultText = result
                            .flatMap { Self._numFmt.string(from: NSNumber(value: $0)) } ?? "—"
                        currencyField(
                            label: "RÉSULTAT",
                            code: toCode, name: toName,
                            displayText: resultText,
                            isInput: false,
                            onPickCurrency: { pickingTo = true }
                        )

                        // Rate info bar
                        rateBar

                        // Saved conversions
                        if !savedConversions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L("ENREGISTREMENTS"))
                                    .font(.tText(11, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundColor(.tTextMute)

                                TCard(padding: 4) {
                                    VStack(spacing: 0) {
                                        ForEach(Array(savedConversions.enumerated()), id: \.element.id) { i, saved in
                                            savedRow(saved)
                                            if i < savedConversions.count - 1 {
                                                Rectangle().fill(Color.tBorder).frame(height: 1)
                                            }
                                        }
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                    .animation(.easeInOut(duration: 0.22), value: savedConversions.count)
                }
            }
            .navigationTitle(L("Convertisseur de devises"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { dismiss() }.foregroundColor(.tAccent2)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: saveConversion) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                    .disabled(result == nil || inputAmount <= 0)
                    .opacity((result == nil || inputAmount <= 0) ? 0.35 : 1)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        amountText = ""
                        Haptics.impact(.light)
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                    .disabled(amountText.isEmpty)
                    .opacity(amountText.isEmpty ? 0.35 : 1)
                }
            }
        }
        .tripnestPreferredColorScheme()
        .task { await service.fetchRates() }
        .onAppear {
            fromCode = defaultCurrency
            toCode   = defaultCurrency == "EUR" ? "USD" : "EUR"
        }
        .onChange(of: amountText) { _, newValue in
            amountText = digitsOnly(newValue)
        }
        .sheet(isPresented: $pickingFrom) {
            CurrencyPickerSheet(selected: $fromCode, allCurrencies: Self.allCurrencies)
        }
        .sheet(isPresented: $pickingTo) {
            CurrencyPickerSheet(selected: $toCode, allCurrencies: Self.allCurrencies)
        }
    }

    // MARK: - Save helpers

    private func saveConversion() {
        guard let res = result, inputAmount > 0 else { return }
        let entry = SavedConversion(
            fromAmount: inputAmount,
            fromCode:   fromCode,
            toAmount:   res,
            toCode:     toCode,
            date:       Date()
        )
        withAnimation { savedConversions.insert(entry, at: 0) }
        Haptics.success()
    }

    private func savedRow(_ saved: SavedConversion) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(currencyFlagEmoji(saved.fromCode)).font(.system(size: 14))
                    Text(Self._numFmt.string(from: NSNumber(value: saved.fromAmount)) ?? "—")
                        .font(.tText(14, weight: .bold)).foregroundColor(.tText)
                    Text(saved.fromCode)
                        .font(.tText(12)).foregroundColor(.tTextMute)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10)).foregroundColor(.tTextMute)
                    Text(currencyFlagEmoji(saved.toCode)).font(.system(size: 14))
                    Text(Self._numFmt.string(from: NSNumber(value: saved.toAmount)) ?? "—")
                        .font(.tText(14, weight: .bold)).foregroundColor(.tAccent2)
                    Text(saved.toCode)
                        .font(.tText(12)).foregroundColor(.tTextMute)
                }
                Text(saved.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.tText(10)).foregroundColor(.tTextMute)
            }
            Spacer(minLength: 8)
            Button {
                withAnimation { savedConversions.removeAll { $0.id == saved.id } }
                Haptics.impact(.light)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.tTextMute)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.tBorder.opacity(0.6)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Currency field

    private func currencyField(
        label: String,
        code: String,
        name: String,
        displayText: String,
        isInput: Bool,
        onPickCurrency: @escaping () -> Void
    ) -> some View {
        TCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(label)
                    .font(.tText(11, weight: .bold))
                    .tracking(1.4)
                    .foregroundColor(.tTextMute)

                HStack(spacing: 12) {
                    if isInput {
                        TextField("0", text: $amountText)
                            .keyboardType(.numberPad)
                            .font(.tDisplay(36, weight: .bold))
                            .tracking(-1)
                            .foregroundColor(.tText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(displayText)
                            .font(.tDisplay(36, weight: .bold))
                            .tracking(-1)
                            .foregroundColor(.tText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                    }

                    // Currency picker button
                    Button(action: onPickCurrency) {
                        HStack(spacing: 6) {
                            Text(currencyFlagEmoji(code))
                                .font(.system(size: 20))
                            Text(code)
                                .font(.tText(15, weight: .bold))
                                .foregroundColor(.tText)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.tTextMute)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.tSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.tBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(TripnestPressStyle())
                }
            }
        }
    }

    // MARK: - Rate bar

    private var rateBar: some View {
        HStack(spacing: 8) {
            Image(systemName: service.isOffline ? "wifi.slash" : "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(service.isOffline ? .tGold : .tMint)

            if let r = service.convert(1, from: fromCode, to: toCode),
               let formatted = Self._rateFmt.string(from: NSNumber(value: r)) {
                Text("1 \(fromCode) = \(formatted) \(toCode)")
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.tText)
            } else {
                Text(L("Taux indisponible")).font(.tText(12)).foregroundColor(.tTextMute)
            }

            Spacer()

            if service.isOffline {
                Text(service.rateDate.isEmpty ? "Taux indicatifs" : L("Hors-ligne · %@", service.rateDate))
                    .font(.tText(10))
                    .foregroundColor(.tGold)
            } else if !service.rateDate.isEmpty {
                Text(service.rateDate).font(.tText(10)).foregroundColor(.tTextMute)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.tSurface))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
    }

    private func digitsOnly(_ text: String) -> String {
        text.filter(\.isNumber)
    }

}

// MARK: - Currency Picker Sheet

struct CurrencyPickerSheet: View {
    @Binding var selected: String
    var allCurrencies: [(code: String, name: String)] = []
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [(code: String, name: String)] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return allCurrencies }
        return allCurrencies.filter {
            $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                List {
                    ForEach(filtered, id: \.code) { item in
                        Button {
                            selected = item.code
                            Haptics.selection()
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text(currencyFlagEmoji(item.code))
                                    .font(.system(size: 22))
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.tText(15, weight: .semibold))
                                        .foregroundColor(.tText)
                                    Text(item.code)
                                        .font(.tText(12))
                                        .foregroundColor(.tTextMute)
                                }
                                Spacer()
                                if selected == item.code {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.tAccent2)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.tBg0)
                        .listRowSeparatorTint(Color.tBorder)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(L("Choisir une devise"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: L("Rechercher une devise…"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { dismiss() }.foregroundColor(.tAccent2)
                }
            }
        }
        .tripnestPreferredColorScheme()
    }
}

// MARK: - Country flag emoji helper (currency code → flag emoji)

func currencyFlagEmoji(_ code: String) -> String {
    let map: [String: String] = [
        "EUR":"EU","USD":"US","GBP":"GB","JPY":"JP","CHF":"CH","CAD":"CA","AUD":"AU",
        "CNY":"CN","INR":"IN","BRL":"BR","MXN":"MX","KRW":"KR","SGD":"SG","HKD":"HK",
        "NOK":"NO","SEK":"SE","DKK":"DK","NZD":"NZ","ZAR":"ZA","TRY":"TR","AED":"AE",
        "SAR":"SA","THB":"TH","MAD":"MA","TND":"TN","EGP":"EG","IDR":"ID","PLN":"PL",
        "CZK":"CZ","HUF":"HU","RON":"RO","BGN":"BG","MYR":"MY","PHP":"PH","VND":"VN",
        "TWD":"TW","PKR":"PK","BDT":"BD","CLP":"CL","COP":"CO","ARS":"AR","PEN":"PE",
        "UAH":"UA","ILS":"IL","QAR":"QA","KWD":"KW","BHD":"BH","OMR":"OM","JOD":"JO",
        "NGN":"NG","GHS":"GH","KES":"KE","ETB":"ET","TZS":"TZ","DZD":"DZ","LYD":"LY",
        "MUR":"MU","ISK":"IS","HRK":"HR","RSD":"RS","ALL":"AL","BAM":"BA","MDL":"MD",
        "GEL":"GE","AMD":"AM","AZN":"AZ","KZT":"KZ","UZS":"UZ","MNT":"MN","KHR":"KH",
        "NPR":"NP","LKR":"LK","MVR":"MV","BND":"BN","PGK":"PG","NIO":"NI","GTQ":"GT",
        "DOP":"DO","JMD":"JM","TTD":"TT","GYD":"GY","PYG":"PY","BOB":"BO","UYU":"UY",
        "CRC":"CR","RUB":"RU","BYN":"BY","XOF":"SN","XAF":"CM","MMK":"MM","LAK":"LA",
        "KGS":"KG","TJS":"TJ","TMT":"TM","AFN":"AF","IRR":"IR","IQD":"IQ","SYP":"SY",
    ]
    guard let cc = map[code], cc.count == 2 else { return "🌐" }
    let base: UInt32 = 127397
    return String(cc.unicodeScalars.compactMap { Unicode.Scalar(base + $0.value) }.map { Character($0) })
}
