import SwiftUI

struct TripPlanningScreen: View {
    @EnvironmentObject private var store: TripStore
    var tripId: String?
    var onNav: (AppRoute) -> Void = { _ in }
    var onBack: () -> Void = {}

    @State private var calendarDate = Date()
    @State private var displayedMonth = Date()
    @State private var selectedDayKey: String = ""
    @State private var showPlanSheet = false
    @State private var sheetEditingItemId: String?
    @State private var showPlanSettings = false
    @State private var notificationStatus: TripnestNotificationStatus = .notDetermined
    @State private var showNotificationPermissionAlert = false

    private static let frLocale = Locale(identifier: "fr_FR")
    fileprivate static var defaultDraftTime: Date {
        Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    }

    private var trip: Trip? {
        if let tripId, let match = store.trips.first(where: { $0.id == tripId }) { return match }
        return store.activeTrip
    }

    private var selectedDayLabel: String {
        TripPlanCalendar.date(from: selectedDayKey)?
            .formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Self.frLocale))
            .capitalized ?? ""
    }

    private var selectedDayItems: [TripPlanItem] {
        guard let trip, !selectedDayKey.isEmpty else { return [] }
        return store.planItems(for: trip.id, dayKey: selectedDayKey)
    }

    var body: some View {
        ScreenShell(motif: false) {
            Group {
                if let trip {
                    VStack(spacing: 0) {
                        TripSubpageTopBar(
                            title: "Planification",
                            subtitle: trip.homeDestinationTitle,
                            onSettings: { showPlanSettings = true },
                            onBack: onBack
                        )

                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 18) {
                                baseCalendarCard(trip: trip)
                                planProgramButton
                                selectedDayProgramSection
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 4)
                            .padding(.bottom, 28)
                        }
                        .tripnestScrollBounceWhenNeeded()
                    }
                } else {
                    missingTripState
                }
            }
        }
        .swipeBack(enabled: true, onBack: onBack)
        .onAppear {
            if let tripId { store.selectTrip(id: tripId) }
            displayedMonth = calendarDate
            if selectedDayKey.isEmpty, let trip {
                selectCalendarDay(calendarDate, trip: trip)
            }
        }
        .task {
            await refreshNotificationStatus()
            if let trip { await TripPlanNotifications.sync(trip: trip, store: store) }
        }
        .sheet(isPresented: $showPlanSettings) {
            if let trip {
                PlanificationNotificationSettingsSheet(
                    trip: trip,
                    notificationStatus: notificationStatus,
                    onActivateSystemNotifications: {
                        Task {
                            let after = await TripnestNotifications.activate()
                            notificationStatus = after
                            if after.isEnabled {
                                await TripPlanNotifications.sync(trip: trip, store: store)
                                Haptics.success()
                            } else if after == .denied {
                                showNotificationPermissionAlert = true
                            }
                        }
                    },
                    onPrefsChanged: {
                        Task { await TripPlanNotifications.sync(trip: trip, store: store) }
                    }
                )
            }
        }
        .alert(L("Notifications désactivées"), isPresented: $showNotificationPermissionAlert) {
            Button(L("Ouvrir Réglages")) {
                Task { await TripnestNotifications.activate() }
            }
            Button(L("Annuler"), role: .cancel) {}
        } message: {
            Text(L("Active les notifications dans Réglages iOS pour recevoir tes rappels de planification."))
        }
        .sheet(isPresented: $showPlanSheet) {
            if let trip, !selectedDayKey.isEmpty {
                PlanActivitySheet(
                    trip: trip,
                    dayKey: selectedDayKey,
                    dayLabel: selectedDayLabel,
                    editingItemId: sheetEditingItemId,
                    onDismiss: {
                        showPlanSheet = false
                        sheetEditingItemId = nil
                    }
                )
            }
        }
    }

    // MARK: - Calendrier de base

    private func baseCalendarCard(trip: Trip) -> some View {
        TCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L("Mon calendrier"))
                    .font(.tText(15, weight: .bold))

                PlanMonthCalendar(
                    month: $displayedMonth,
                    selection: calendarDate,
                    programDayKeys: programDayKeys(for: trip),
                    onSelect: { date in
                        calendarDate = date
                        selectCalendarDay(date, trip: trip)
                    }
                )
            }
        }
    }

    private func programDayKeys(for trip: Trip) -> Set<String> {
        Set(store.planItems
            .filter { $0.tripId == trip.id }
            .map { $0.dayKey })
    }

    private var planProgramButton: some View {
        Button {
            guard !selectedDayKey.isEmpty else { return }
            sheetEditingItemId = nil
            showPlanSheet = true
            Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                Text(L("Planifie ton programme"))
                    .font(.tText(16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.tAccent)
            )
        }
        .buttonStyle(TripnestPressStyle())
        .disabled(selectedDayKey.isEmpty)
        .opacity(selectedDayKey.isEmpty ? 0.5 : 1)
    }

    // MARK: - Programme du jour sélectionné

    @ViewBuilder
    private var selectedDayProgramSection: some View {
        if !selectedDayKey.isEmpty {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("Programme du %@", selectedDayLabel))
                .font(.tText(14, weight: .bold))

            if selectedDayItems.isEmpty {
                TCard(padding: 18) {
                    Text(L("Aucune activité ce jour-là.\nAppuie sur « Planifie ton programme » pour en ajouter une."))
                        .font(.tText(13))
                        .foregroundColor(.tTextMute)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            } else {
                TCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(selectedDayItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider().padding(.leading, 56)
                            }
                            programActivityRow(item)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Text(L("Modifier ou supprimer une activité avec les icônes à droite."))
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)
            }
        }
        }
    }

    private func programActivityRow(_ item: TripPlanItem) -> some View {
        HStack(spacing: 12) {
            Text(item.time.isEmpty ? "—" : item.time)
                .font(.tText(13, weight: .bold))
                .foregroundColor(.tMint)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.tText(15, weight: .semibold))
                if !item.location.isEmpty {
                    Text(item.location)
                        .font(.tText(12, weight: .semibold))
                        .foregroundColor(.tAccent2)
                        .lineLimit(1)
                }
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                        .lineLimit(3)
                }
            }

            Spacer(minLength: 0)

            Button {
                sheetEditingItemId = item.id
                showPlanSheet = true
                Haptics.selection()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tAccent2)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.tAccent2.opacity(0.12)))
            }
            .buttonStyle(.plain)

            Button {
                store.deletePlanItem(id: item.id)
                if let trip { syncPlanNotifications(for: trip) }
                Haptics.selection()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tRose)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.tRose.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func selectCalendarDay(_ date: Date, trip: Trip?) {
        guard let trip else { return }
        let key = TripPlanCalendar.dayKey(for: date)
        store.registerPlanDay(tripId: trip.id, date: date)
        selectedDayKey = key
        calendarDate = date
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await TripnestNotifications.currentStatus()
    }

    private func syncPlanNotifications(for trip: Trip) {
        Task { await TripPlanNotifications.sync(trip: trip, store: store) }
    }

    private var missingTripState: some View {
        VStack(spacing: 0) {
            TripSubpageTopBar(title: "Planification", subtitle: L("Voyage introuvable"), onBack: onBack)
            Spacer()
            TIcon(glyph: .cal, size: 36, stroke: .tAccent2)
            Text(L("Impossible de charger ce voyage."))
                .font(.tText(15, weight: .semibold))
                .padding(.top, 12)
            Spacer()
        }
    }
}

// MARK: - Calendrier mensuel personnalisé

private struct PlanMonthCalendar: View {
    @Binding var month: Date
    let selection: Date
    let programDayKeys: Set<String>
    let onSelect: (Date) -> Void

    private static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "fr_FR")
        c.firstWeekday = 2
        return c
    }()

    private let weekdaySymbols = ["LUN", "MAR", "MER", "JEU", "VEN", "SAM", "DIM"]

    var body: some View {
        VStack(spacing: 10) {
            header
            weekdayRow
            grid
        }
    }

    private var header: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.tAccent2)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
            Text(monthTitle)
                .font(.tText(15, weight: .bold))
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.tAccent2)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.tText(10, weight: .bold))
                    .foregroundColor(.tTextMute)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let cal = Self.cal
        let isSelected = cal.isDate(date, inSameDayAs: selection)
        let isToday = cal.isDateInToday(date)
        let hasProgram = programDayKeys.contains(TripPlanCalendar.dayKey(for: date))
        return Button { onSelect(date) } label: {
            VStack(spacing: 3) {
                Text("\(cal.component(.day, from: date))")
                    .font(.tText(14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .tText)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(isSelected ? Color.tAccent2 : Color.clear))
                    .overlay(
                        Circle().stroke(
                            isToday && !isSelected ? Color.tAccent2.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                    )
                Circle()
                    .fill(hasProgram ? Color.tAccent2 : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private static let _monthTitleFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private var monthTitle: String {
        Self._monthTitleFmt.string(from: month).capitalized
    }

    private var monthDays: [Date?] {
        let cal = Self.cal
        guard let interval = cal.dateInterval(of: .month, for: month),
              let firstWeekday = cal.dateComponents([.weekday], from: interval.start).weekday,
              let daysInMonth = cal.range(of: .day, in: .month, for: month)?.count
        else { return [] }

        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<daysInMonth {
            cells.append(cal.date(byAdding: .day, value: offset, to: interval.start))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private func shiftMonth(_ delta: Int) {
        if let next = Self.cal.date(byAdding: .month, value: delta, to: month) {
            month = next
        }
    }
}

// MARK: - Ajouter / modifier une activité

private struct PlanActivitySheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let dayKey: String
    let dayLabel: String
    var editingItemId: String?
    var onDismiss: () -> Void

    @State private var draftTimeDate = TripPlanningScreen.defaultDraftTime
    @State private var draftTitle = ""
    @State private var draftLocation = ""
    @State private var draftNotes = ""

    private static let frLocale = Locale(identifier: "fr_FR")
    private var isEditing: Bool { editingItemId != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L("Pour le %@", dayLabel))
                        .font(.tText(13))
                        .foregroundColor(.tTextMute)

                    timeSection
                    titleSection
                    locationSection
                    notesSection

                    Button(action: save) {
                        Text(isEditing ? "Enregistrer" : "Ajouter")
                            .font(.tText(15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(canSave ? Color.tAccent : Color.tAccent.opacity(0.4))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
                .padding(18)
            }
            .background(Color.tBg0.ignoresSafeArea())
            .navigationTitle(isEditing ? L("Modifier l’activité") : L("Nouvelle activité"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Annuler")) { close() }
                }
            }
            .onAppear { loadEditingIfNeeded() }
        }
        .presentationDetents([.large])
    }

    private var canSave: Bool {
        !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L("Heure"))
                .font(.tText(11, weight: .semibold))
                .foregroundColor(.tTextMute)
            HStack {
                DatePicker("", selection: $draftTimeDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Self.frLocale)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(fieldBackground)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L("Nom de l’activité"))
                .font(.tText(11, weight: .semibold))
                .foregroundColor(.tTextMute)
            TextField(L("Ex : Musée, Déjeuner…"), text: $draftTitle)
                .font(.tText(15))
                .padding(12)
                .background(fieldBackground)
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L("Lieu (facultatif)"))
                .font(.tText(11, weight: .semibold))
                .foregroundColor(.tTextMute)
            TextField(L("Ex : Centre-ville, Hôtel…"), text: $draftLocation)
                .font(.tText(14))
                .padding(12)
                .background(fieldBackground)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L("Note (facultatif)"))
                    .font(.tText(11, weight: .semibold))
                    .foregroundColor(.tTextMute)
                Spacer()
                Text(L("%d/%d lignes", TripPhotoMemory.lineCount(for: draftNotes), TripPhotoMemory.maxCaptionLines))
                    .font(.tText(11, weight: .semibold))
                    .foregroundColor(.tTextMute)
            }
            TextField(L("Détails, adresse, rappels…"), text: $draftNotes, axis: .vertical)
                .font(.tText(14))
                .lineLimit(6...TripPhotoMemory.maxCaptionLines)
                .padding(12)
                .background(fieldBackground)
                .keyboardDoneBar()
                .onChange(of: draftNotes) { _, newValue in
                    if TripPhotoMemory.lineCount(for: newValue) > TripPhotoMemory.maxCaptionLines {
                        draftNotes = TripPhotoMemory.clampedCaption(newValue)
                    }
                }
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.tSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.tBorder, lineWidth: 1)
            )
    }

    private func loadEditingIfNeeded() {
        guard let id = editingItemId,
              let item = store.planItems.first(where: { $0.id == id }) else { return }
        applyTimeString(item.time)
        draftTitle = item.title
        draftLocation = item.location
        draftNotes = item.notes
    }

    private func save() {
        let time = formattedDraftTime
        let notes = TripPhotoMemory.clampedCaption(draftNotes)
        if let editId = editingItemId {
            store.updatePlanItem(id: editId, time: time, title: draftTitle, location: draftLocation, notes: notes)
        } else {
            store.addPlanItem(
                tripId: trip.id,
                dayKey: dayKey,
                time: time,
                title: draftTitle,
                location: draftLocation,
                notes: notes
            )
        }
        Haptics.success()
        syncAfterSave()
        close()
    }

    private func syncAfterSave() {
        Task { await TripPlanNotifications.sync(trip: trip, store: store) }
    }

    private func close() {
        onDismiss()
        dismiss()
    }

    private static let _timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()

    private var formattedDraftTime: String {
        Self._timeFmt.string(from: draftTimeDate)
    }

    private func applyTimeString(_ time: String) {
        let parts = time.split(separator: ":")
        let hour = Int(parts.first ?? "9") ?? 9
        let minute = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        draftTimeDate = Calendar.current.date(from: DateComponents(hour: hour, minute: minute))
            ?? TripPlanningScreen.defaultDraftTime
    }
}

// MARK: - Réglages notifications (planification)

struct PlanificationNotificationSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let notificationStatus: TripnestNotificationStatus
    var onActivateSystemNotifications: () -> Void
    var onPrefsChanged: () -> Void

    @State private var remindActivities: Bool
    @State private var remindDeparture: Bool

    init(
        trip: Trip,
        notificationStatus: TripnestNotificationStatus,
        onActivateSystemNotifications: @escaping () -> Void,
        onPrefsChanged: @escaping () -> Void
    ) {
        self.trip = trip
        self.notificationStatus = notificationStatus
        self.onActivateSystemNotifications = onActivateSystemNotifications
        self.onPrefsChanged = onPrefsChanged
        _remindActivities = State(
            initialValue: TripPlanNotificationPrefs.activitiesEnabled(tripId: trip.id)
        )
        _remindDeparture = State(
            initialValue: TripPlanNotificationPrefs.departureEnabled(tripId: trip.id)
        )
    }

    private var hasDepartureDate: Bool { trip.departureDate != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L("Rappels liés à ce voyage uniquement. Tu seras prévenu 1 h à l’avance."))
                        .font(.tText(13))
                        .foregroundColor(.tTextMute)

                    if !notificationStatus.isEnabled {
                        TCard(padding: 14) {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(L("Notifications iOS désactivées"), systemImage: "bell.slash")
                                    .font(.tText(14, weight: .semibold))
                                    .foregroundColor(.tRose)
                                Text(L("Autorise les notifications pour activer les rappels ci-dessous."))
                                    .font(.tText(12))
                                    .foregroundColor(.tTextMute)
                                Button(action: onActivateSystemNotifications) {
                                    Text(L("Activer les notifications"))
                                        .font(.tText(13, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Capsule().fill(Color.tAccent))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    TCard(padding: 0) {
                        VStack(spacing: 0) {
                            toggleRow(
                                title: L("1 h avant chaque activité"),
                                subtitle: L("Pour chaque heure planifiée dans ton calendrier"),
                                isOn: $remindActivities
                            ) {
                                TripPlanNotificationPrefs.setActivitiesEnabled(remindActivities, tripId: trip.id)
                                onPrefsChanged()
                            }

                            Divider().padding(.leading, 16)

                            toggleRow(
                                title: L("1 h avant le départ"),
                                subtitle: departureSubtitle,
                                isOn: $remindDeparture,
                                disabled: !hasDepartureDate
                            ) {
                                TripPlanNotificationPrefs.setDepartureEnabled(remindDeparture, tripId: trip.id)
                                onPrefsChanged()
                            }
                        }
                    }

                    if remindActivities || remindDeparture {
                        Label(
                            L("Les rappels sont mis à jour quand tu ajoutes ou modifies une activité."),
                            systemImage: "info.circle"
                        )
                        .font(.tText(11))
                        .foregroundColor(.tTextMute)
                    }
                }
                .padding(18)
            }
            .background(Color.tBg0.ignoresSafeArea())
            .navigationTitle(L("Rappels"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Fermer")) { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var departureSubtitle: String {
        if let dep = trip.departureDate {
            let label = dep.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "fr_FR")))
            return L("Départ le %@", label.capitalized)
        }
        return L("Ajoute une date de départ au voyage pour activer ce rappel")
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        disabled: Bool = false,
        onChange: @escaping () -> Void
    ) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.tText(14, weight: .semibold))
                    .foregroundColor(disabled ? .tTextMute : .tText)
                Text(subtitle)
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)
            }
            .padding(.vertical, 14)
        }
        .tint(.tAccent2)
        .disabled(disabled || !notificationStatus.isEnabled)
        .padding(.horizontal, 16)
        .onChange(of: isOn.wrappedValue) { _, _ in onChange() }
    }
}
