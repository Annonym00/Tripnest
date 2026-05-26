import SwiftUI

struct AddExpenseScreen: View {
    @EnvironmentObject private var store: TripStore
    var expenseId: String? = nil
    var onClose: () -> Void = {}
    var onSave: () -> Void = {}

    @State private var cat: String = "food"
    @State private var amountText: String = ""
    @State private var label: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var paidWith: String = ""
    @State private var currency: String = "EUR"
    @State private var rating: Double = 4.5
    @State private var status: ExpenseStatus = .completed
    @State private var expenseDate: Date = Date()
    @State private var showDeleteAlert = false
    @State private var showCurrencyPicker = false
    @State private var loaded = false

    private let maxDescriptionLines = 150

    private struct Cat { let id, label: String; let glyph: TIcon.Glyph; let color: Color }
    private let cats: [Cat] = [
        .init(id: "food",   label: "Repas",     glyph: .food,   color: .tGold),
        .init(id: "hotel",  label: "Hôtel",     glyph: .hotel,  color: .tRose),
        .init(id: "bus",    label: "Transport", glyph: .bus,    color: .tBlue),
        .init(id: "ticket", label: "Activité",  glyph: .ticket, color: .tMint),
        .init(id: "gift",   label: "Souvenir",  glyph: .gift,   color: .tAccent2),
        .init(id: "more",   label: "Autre",     glyph: .more,   color: .tTextMute),
    ]

    private var isEditing: Bool { expenseId != nil }

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                headerBar

                if store.activeTrip == nil {
                    noTripState
                } else {
                    amountSection.padding(.horizontal, 22).padding(.bottom, 18)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            sectionLabel("CATÉGORIE").padding(.bottom, 10)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                                ForEach(cats, id: \.id) { c in
                                    catButton(c)
                                }
                            }

                            sectionLabel("STATUT").padding(.top, 22).padding(.bottom, 10)
                            statusCheckboxes

                            sectionLabel("DÉTAILS").padding(.top, 22).padding(.bottom, 10)
                            TCard(padding: 4) {
                                VStack(spacing: 0) {
                                    editableRow("Titre", text: $label, placeholder: "Ex. déjeuner, hôtel, taxi")
                                    divider
                                    FormField(label: "Lieu", text: $location, placeholder: "Ex. Le Marais, gare…")
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                    divider
                                    dateRow
                                    divider
                                    editableRow("Payé avec", text: $paidWith, placeholder: "Carte, espèces…")
                                }
                            }

                            descriptionSection.padding(.top, 22)

                            ratingSection.padding(.top, 22)

                            CTA(label: isEditing ? "Enregistrer les modifications" : "Enregistrer la dépense", action: save)
                                .opacity(amountValue > 0 ? 1 : 0.45)
                                .disabled(amountValue <= 0)
                                .padding(.top, 22)

                            if isEditing {
                                Button(role: .destructive, action: { showDeleteAlert = true }) {
                                    Text("Supprimer cette dépense")
                                        .font(.tText(14, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, TripnestLayout.formScrollBreathing)
                    }
                    .tripnestScrollBounceWhenNeeded()
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .onAppear { loadIfNeeded() }
        .alert("Supprimer cette dépense ?", isPresented: $showDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                if let id = expenseId {
                    store.deleteExpense(id: id)
                    Haptics.success()
                    onSave()
                }
            }
        } message: {
            Text("Cette action est définitive.")
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selected: $currency, allCurrencies: CurrencyConverterSheet.allCurrencies)
        }
    }

    private var headerBar: some View {
        HStack {
            Button(action: onClose) { IconBtn(glyph: .close) }
                .buttonStyle(.plain)
                .accessibilityLabel("Fermer")
            Spacer()
            Text(isEditing ? "Modifier la dépense" : "Nouvelle dépense")
                .font(.tText(16, weight: .bold))
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 22).padding(.top, 6).padding(.bottom, 14)
    }

    private var noTripState: some View {
        Group {
            Spacer()
            TCard(padding: 22) {
                VStack(spacing: 12) {
                    TIcon(glyph: .wallet, size: 36, stroke: .tAccent2)
                    Text("Crée d'abord un voyage")
                        .font(.tDisplay(24))
                        .multilineTextAlignment(.center)
                    Text("Une dépense doit être rattachée à un voyage réel.")
                        .font(.tText(14))
                        .foregroundColor(.tTextMute)
                        .multilineTextAlignment(.center)
                    CTA(label: "Retour", action: onClose)
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 22)
            Spacer()
        }
    }

    private var statusCheckboxes: some View {
        TCard(padding: 4) {
            VStack(spacing: 0) {
                ExpenseStatusCheckboxRow(
                    title: "Dépense à venir",
                    subtitle: "Prévue, pas encore payée",
                    isChecked: status == .upcoming,
                    tint: .tGold
                ) {
                    withAnimation(TripnestAnimation.budgetMoney) { status = .upcoming }
                    Haptics.impact(.light)
                }
                Divider().background(Color.tBorder).padding(.horizontal, 14)
                ExpenseStatusCheckboxRow(
                    title: "Dépense effectuée",
                    subtitle: "Déjà payée, compte dans le budget",
                    isChecked: status == .completed,
                    tint: .tMint
                ) {
                    withAnimation(TripnestAnimation.budgetMoney) { status = .completed }
                    Haptics.impact(.medium)
                }
            }
        }
    }

    private var dateRow: some View {
        HStack {
            Text("Date").font(.tText(13)).foregroundColor(.tTextMute)
            Spacer()
            DatePicker("", selection: $expenseDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .tint(.tAccent2)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DESCRIPTION")
                    .font(.tText(12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.tTextMute)
                Spacer()
                Text("\(descriptionLineCount)/\(maxDescriptionLines) lignes")
                    .font(.tText(11))
                    .foregroundColor(descriptionLineCount >= maxDescriptionLines ? Color(hex: 0xff3b30) : .tTextMute)
            }

            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Détails, reçu, anecdote…")
                        .font(.tText(15))
                        .foregroundColor(.tTextMute.opacity(0.5))
                        .padding(.top, 14)
                        .padding(.leading, 18)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $notes)
                    .font(.tText(15))
                    .foregroundColor(.tText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90, maxHeight: 140)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .onChange(of: notes) { _, newValue in
                        notes = clampDescriptionLines(newValue)
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: 0x8b5cf6, opacity: 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tBorderStrong, lineWidth: 1)
            )
        }
    }

    private var ratingSection: some View {
        TCard(padding: 4) {
            Stepper(value: $rating, in: 1...5, step: 0.5) {
                HStack {
                    Text("Note").font(.tText(14, weight: .semibold))
                    Spacer()
                    HStack(spacing: 4) {
                        let sc = starColor(rating)
                        TIcon(glyph: .star, size: 12, stroke: sc, fill: sc)
                        Text("\(rating, specifier: "%.1f")")
                            .font(.tText(14, weight: .bold))
                            .foregroundColor(sc)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
        }
    }

    private var amountSection: some View {
        VStack(spacing: 8) {
            Text("MONTANT").font(.tText(11, weight: .bold)).tracking(1.5).foregroundColor(.tTextMute)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.tDisplay(64, weight: .heavy))
                    .tracking(-3)
                    .foregroundColor(.tText)
                    .frame(maxWidth: 210)
                    .onChange(of: amountText) { _, newValue in
                        amountText = digitsOnly(newValue)
                    }
                Text(currencySymbol).font(.tText(28, weight: .bold)).tracking(-0.5).foregroundColor(.tTextMute)
            }
            HStack(spacing: 6) {
                Button(action: {
                    showCurrencyPicker = true
                    Haptics.impact(.light)
                }) {
                    HStack(spacing: 8) {
                        Text(currencyFlagEmoji(currency))
                            .font(.system(size: 18))
                        Text(currency)
                            .font(.tText(13, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.tText)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(Capsule().fill(Color.tSurface))
                    .overlay(Capsule().stroke(Color.tBorder, lineWidth: 1))
                }
                .buttonStyle(TripnestPressStyle())
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(Color.tBorder).frame(height: 1).padding(.horizontal, 14)
    }

    private func catButton(_ c: Cat) -> some View {
        let active = cat == c.id
        return Button(action: { withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) { cat = c.id } }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(active ? c.color : c.color.opacity(0.13))
                    TIcon(glyph: c.glyph, size: 18, stroke: active ? .white : c.color)
                }
                .frame(width: 40, height: 40)
                Text(c.label)
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(active ? c.color : .tText)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14).padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(active ? c.color.opacity(0.12) : Color.tSurface))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(active ? c.color.opacity(0.33) : Color.tBorder, lineWidth: 1))
        }
        .buttonStyle(TripnestPressStyle())
    }

    private func sectionLabel(_ s: String) -> some View {
        HStack {
            Text(s).font(.tText(12, weight: .bold)).tracking(1.5).foregroundColor(.tTextMute)
            Spacer()
        }
    }

    private var selectedCategoryLabel: String {
        cats.first { $0.id == cat }?.label ?? "Autre"
    }

    private var amountValue: Int {
        max(0, Int(amountText) ?? 0)
    }

    private var currencySymbol: String { currency.currencySymbol }

    private func digitsOnly(_ text: String) -> String {
        text.filter(\.isNumber)
    }

    private var expenseTitle: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? selectedCategoryLabel : trimmed
    }

    private var descriptionLineCount: Int {
        max(1, notes.components(separatedBy: .newlines).count)
    }

    private func clampDescriptionLines(_ text: String) -> String {
        var lines = text.components(separatedBy: .newlines)
        if lines.count > maxDescriptionLines {
            lines = Array(lines.prefix(maxDescriptionLines))
            return lines.joined(separator: "\n")
        }
        return text
    }

    private func starColor(_ rating: Double) -> Color {
        if rating < 2.5 { return Color(hex: 0xff3b30) }
        if rating < 4 { return .tGold }
        return .tMint
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let id = expenseId, let expense = store.expenses.first(where: { $0.id == id }) else { return }
        label = expense.label
        location = expense.location
        notes = expense.notes
        paidWith = expense.paidWith
        currency = expense.currency ?? "EUR"
        amountText = "\(expense.amount)"
        rating = expense.rating > 0 ? expense.rating : 4.5
        status = expense.status
        expenseDate = expense.date
        if let match = cats.first(where: { $0.label == expense.category }) {
            cat = match.id
        } else {
            cat = "more"
        }
    }

    private func save() {
        guard amountValue > 0 else { return }
        let payload = (
            label: expenseTitle,
            category: selectedCategoryLabel,
            amount: amountValue,
            currency: currency,
            date: expenseDate,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            rating: rating,
            status: status,
            paidWith: paidWith.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        if let id = expenseId {
            store.updateExpense(id: id, label: payload.label, category: payload.category, amount: payload.amount,
                                currency: payload.currency, date: payload.date, location: payload.location,
                                notes: payload.notes, rating: payload.rating, status: payload.status,
                                paidWith: payload.paidWith)
        } else {
            store.addExpense(label: payload.label, category: payload.category, amount: payload.amount,
                             currency: payload.currency, date: payload.date, location: payload.location,
                             notes: payload.notes, rating: payload.rating, status: payload.status,
                             paidWith: payload.paidWith)
        }
        Haptics.success()
        onSave()
    }

    private func editableRow(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label).font(.tText(13)).foregroundColor(.tTextMute)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .font(.tText(14, weight: .semibold))
                .foregroundColor(.tText)
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
    }
}
