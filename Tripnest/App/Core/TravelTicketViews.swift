import SwiftUI
import VisionKit

// MARK: - Formulaire billet (nouveau voyage)

struct TravelTicketFormSection: View {
    let mode: TransportMode
    @Binding var draft: TravelTicketDraft?
    var onEdit: () -> Void
    var onScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(mode.ticketSectionHeading)
                .font(.tText(12, weight: .bold))
                .foregroundColor(.tTextMute)

            if let draft, draft.hasMinimumInfo {
                TCard(padding: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TransportModeGlyph(mode: mode, size: 20, stroke: .tAccent2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(draft.summaryLine)
                                    .font(.tText(14, weight: .bold))
                                if !draft.code.isEmpty {
                                    Text(draft.code)
                                        .font(.tText(11))
                                        .foregroundColor(.tTextMute)
                                }
                            }
                            Spacer()
                            Button("Modifier", action: onEdit)
                                .font(.tText(12, weight: .semibold))
                                .foregroundColor(.tAccent2)
                        }
                        if !draft.date.isEmpty || !draft.departure.isEmpty {
                            Text([draft.date, draft.departure].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.tText(11))
                                .foregroundColor(.tTextMute)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: onEdit) {
                    ticketActionLabel(title: "Saisir le billet", icon: "square.and.pencil")
                }
                .buttonStyle(TripnestPressStyle())

                Button(action: onScan) {
                    ticketActionLabel(title: "Scanner", icon: "doc.text.viewfinder", accent: true)
                }
                .buttonStyle(TripnestPressStyle())
            }
        }
    }

    private func ticketActionLabel(title: String, icon: String, accent: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.tText(13, weight: .bold))
        }
        .foregroundColor(accent ? .white : .tAccent2)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accent
                    ? AnyShapeStyle(LinearGradient(colors: [.tAccent2, .tAccentDeep], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color.tAccent2.opacity(0.10)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent ? Color.clear : Color.tAccent2.opacity(0.28), lineWidth: 1)
        )
    }
}

// MARK: - Éditeur billet

struct TravelTicketEditorSheet: View {
    let mode: TransportMode
    @Binding var draft: TravelTicketDraft
    var tripOrigin: String = ""
    var tripDestination: String = ""
    var tripDepartureDate: Date? = nil
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scheduleDay = Date()
    @State private var departureTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var arrivalTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var durationHours = 1
    @State private var durationMinutes = 0
    @State private var fromPlaceValidation: LocationFieldValidation = .unknown
    @State private var toPlaceValidation: LocationFieldValidation = .unknown

    private var todayStart: Date { Calendar.current.startOfDay(for: Date()) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        FormField(
                            label: mode.ticketCodeLabel,
                            text: $draft.code,
                            placeholder: mode == .plane ? "AF1234" : "—",
                            showsClearButton: true
                        )
                        FormField(label: mode.ticketCompanyLabel, text: $draft.company, placeholder: "Compagnie", showsClearButton: true)
                        FormField(label: "Départ (code)", text: $draft.from, placeholder: mode == .plane ? "LYS" : "—", showsClearButton: true)

                        FormLocationField(
                            label: "Lieu de départ",
                            placeholder: mode.originPlaceholder,
                            text: $draft.fromCity,
                            validation: $fromPlaceValidation,
                            transportMode: mode,
                            showsClearButton: false
                        )

                        FormField(label: "Arrivée (code)", text: $draft.to, placeholder: mode == .plane ? "MRS" : "—", showsClearButton: true)

                        FormLocationField(
                            label: "Lieu d'arrivée",
                            placeholder: mode.destinationPlaceholder,
                            text: $draft.toCity,
                            validation: $toPlaceValidation,
                            transportMode: mode,
                            showsClearButton: false
                        )

                        TravelTicketScheduleFields(
                            scheduleDay: $scheduleDay,
                            departureTime: $departureTime,
                            arrivalTime: $arrivalTime,
                            durationHours: $durationHours,
                            durationMinutes: $durationMinutes,
                            minimumDay: todayStart
                        )

                        if mode == .plane {
                            FormField(label: "Siège", text: $draft.seat, placeholder: "14A", showsClearButton: true)
                            FormField(label: "Porte", text: $draft.gate, placeholder: "G22", showsClearButton: true)
                            FormField(label: "Terminal", text: $draft.terminal, placeholder: "2E", showsClearButton: true)
                        } else if mode == .train {
                            FormField(label: "Siège / place", text: $draft.seat, placeholder: "Voiture 4", showsClearButton: true)
                            FormField(label: "Voie / quai", text: $draft.gate, placeholder: "Voie B", showsClearButton: true)
                        } else {
                            FormField(label: "Cabine / place", text: $draft.seat, placeholder: "Pont 5", showsClearButton: true)
                            FormField(label: "Embarquement", text: $draft.gate, placeholder: "Porte 3", showsClearButton: true)
                        }
                        CTA(label: "Valider le billet", action: validateAndClose)
                            .opacity(draft.hasMinimumInfo ? 1 : 0.45)
                            .disabled(!draft.hasMinimumInfo)
                            .padding(.top, 8)
                    }
                    .padding(22)
                }
                .scrollDismissesKeyboard(.never)
            }
            .navigationTitle(mode.ticketSectionHeading)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
            .onAppear {
                draft.prefillFromTrip(
                    origin: tripOrigin,
                    destination: tripDestination,
                    departureDate: tripDepartureDate
                )
                loadScheduleFromDraft()
            }
            .onChange(of: scheduleDay) { _, _ in syncDraftSchedule() }
            .onChange(of: departureTime) { _, _ in syncDraftSchedule() }
            .onChange(of: arrivalTime) { _, _ in syncDraftSchedule() }
            .onChange(of: durationHours) { _, _ in syncDraftSchedule() }
            .onChange(of: durationMinutes) { _, _ in syncDraftSchedule() }
        }
        .interactiveDismissDisabled(true)
        .preferredColorScheme(.dark)
    }

    private func validateAndClose() {
        syncDraftSchedule()
        onDone()
        dismiss()
    }

    private func loadScheduleFromDraft() {
        if let parsed = TravelTicketDraft.parseDepartureDate(from: draft.date) {
            scheduleDay = max(parsed, todayStart)
        } else if let tripDepartureDate {
            scheduleDay = max(tripDepartureDate, todayStart)
        } else {
            scheduleDay = todayStart
        }
        if let dep = TravelTicketDraft.parseTime(draft.departure) {
            departureTime = dep
        }
        if let arr = TravelTicketDraft.parseTime(draft.arrival) {
            arrivalTime = arr
        }
        if let dur = TravelTicketDraft.parseDuration(draft.duration) {
            durationHours = dur.hours
            durationMinutes = dur.minutes
        } else {
            updateDurationFromTimes()
        }
        syncDraftSchedule()
    }

    private func updateDurationFromTimes() {
        let cal = Calendar.current
        let depM = cal.component(.hour, from: departureTime) * 60 + cal.component(.minute, from: departureTime)
        var arrM = cal.component(.hour, from: arrivalTime) * 60 + cal.component(.minute, from: arrivalTime)
        if arrM < depM { arrM += 24 * 60 }
        let total = max(0, arrM - depM)
        durationHours = total / 60
        durationMinutes = total % 60
    }

    private func syncDraftSchedule() {
        draft.date = TravelTicketDraft.formatDepartureDate(scheduleDay)
        draft.departure = TravelTicketDraft.formatTime(departureTime)
        draft.arrival = TravelTicketDraft.formatTime(arrivalTime)
        draft.duration = TravelTicketDraft.formatDuration(hours: durationHours, minutes: durationMinutes)
    }
}

// MARK: - Date / heure / durée (roues au tap, comme nouveau voyage)

private struct TravelTicketScheduleFields: View {
    @Binding var scheduleDay: Date
    @Binding var departureTime: Date
    @Binding var arrivalTime: Date
    @Binding var durationHours: Int
    @Binding var durationMinutes: Int
    let minimumDay: Date

    @State private var pickingDate = false
    @State private var pickingDeparture = false
    @State private var pickingArrival = false
    @State private var pickingDuration = false
    @State private var draftDay = Date()
    @State private var draftDeparture = Date()
    @State private var draftArrival = Date()
    @State private var draftDurationHours = 1
    @State private var draftDurationMinutes = 0

    private static var frLocale: Locale { Locale(identifier: "fr_FR") }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            dateSection
            departureTimeSection
            arrivalTimeSection
            durationSection
        }
        .animation(TripnestAnimation.page, value: pickingDate)
        .animation(TripnestAnimation.page, value: pickingDeparture)
        .animation(TripnestAnimation.page, value: pickingArrival)
        .animation(TripnestAnimation.page, value: pickingDuration)
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Date de départ")
            if pickingDate {
                VStack(spacing: 14) {
                    DatePicker("", selection: $draftDay, in: minimumDay..., displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, Self.frLocale)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .onChange(of: draftDay) { _, newValue in
                            if newValue < minimumDay { draftDay = minimumDay }
                        }
                    pickerActions(
                        onCancel: { pickingDate = false },
                        onConfirm: {
                            scheduleDay = max(draftDay, minimumDay)
                            pickingDate = false
                            Haptics.success()
                        }
                    )
                }
                .padding(14)
                .background(TicketFormChrome.fieldBackground)
            } else {
                Button {
                    closeAllPickers(except: .date)
                    draftDay = max(scheduleDay, minimumDay)
                    pickingDate = true
                    Haptics.selection()
                } label: {
                    HStack(spacing: 10) {
                        TIcon(glyph: .cal, size: 18, stroke: .tAccent2)
                        Text(scheduleDay.formatted(.dateTime.day().month(.wide).year().locale(Self.frLocale)))
                            .font(.tText(15, weight: .semibold))
                            .foregroundColor(.tText)
                        Spacer()
                        Text("Modifier")
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(TicketFormChrome.fieldBackground)
                }
                .buttonStyle(TripnestPressStyle())
            }
        }
    }

    private var departureTimeSection: some View {
        collapsibleTimeSection(
            title: "Heure de départ",
            value: departureTime,
            isPicking: pickingDeparture,
            onOpen: {
                closeAllPickers(except: .departure)
                draftDeparture = departureTime
                pickingDeparture = true
            },
            onCancel: { pickingDeparture = false },
            onConfirm: {
                departureTime = draftDeparture
                pickingDeparture = false
                Haptics.success()
            },
            draftTime: $draftDeparture
        )
    }

    private var arrivalTimeSection: some View {
        collapsibleTimeSection(
            title: "Heure d'arrivée",
            value: arrivalTime,
            isPicking: pickingArrival,
            onOpen: {
                closeAllPickers(except: .arrival)
                draftArrival = arrivalTime
                pickingArrival = true
            },
            onCancel: { pickingArrival = false },
            onConfirm: {
                arrivalTime = draftArrival
                pickingArrival = false
                Haptics.success()
            },
            draftTime: $draftArrival
        )
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Durée du trajet")
            if pickingDuration {
                VStack(spacing: 14) {
                    HStack(spacing: 0) {
                        Picker("Heures", selection: $draftDurationHours) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h) h").tag(h)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Minutes", selection: $draftDurationMinutes) {
                            ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 150)

                    pickerActions(
                        onCancel: { pickingDuration = false },
                        onConfirm: {
                            durationHours = draftDurationHours
                            durationMinutes = draftDurationMinutes
                            pickingDuration = false
                            Haptics.success()
                        }
                    )
                }
                .padding(14)
                .background(TicketFormChrome.fieldBackground)
            } else {
                Button {
                    closeAllPickers(except: .duration)
                    draftDurationHours = durationHours
                    draftDurationMinutes = durationMinutes
                    pickingDuration = true
                    Haptics.selection()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.tAccent2)
                        Text(TravelTicketDraft.formatDuration(hours: durationHours, minutes: durationMinutes))
                            .font(.tText(15, weight: .semibold))
                            .foregroundColor(.tText)
                        Spacer()
                        Text("Modifier")
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(TicketFormChrome.fieldBackground)
                }
                .buttonStyle(TripnestPressStyle())
            }
        }
    }

    private func collapsibleTimeSection(
        title: String,
        value: Date,
        isPicking: Bool,
        onOpen: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void,
        draftTime: Binding<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel(title)
            if isPicking {
                VStack(spacing: 14) {
                    DatePicker("", selection: draftTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, Self.frLocale)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .clipped()
                    pickerActions(onCancel: onCancel, onConfirm: onConfirm)
                }
                .padding(14)
                .background(TicketFormChrome.fieldBackground)
            } else {
                Button(action: onOpen) {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.tAccent2)
                        Text(TravelTicketDraft.formatTime(value))
                            .font(.tText(15, weight: .semibold))
                            .foregroundColor(.tText)
                        Spacer()
                        Text("Modifier")
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(TicketFormChrome.fieldBackground)
                }
                .buttonStyle(TripnestPressStyle())
            }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.tText(12, weight: .bold))
            .tracking(1.5)
            .foregroundColor(.tTextMute)
    }

    private func pickerActions(onCancel: @escaping () -> Void, onConfirm: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Button(action: onCancel) {
                Text("Annuler")
                    .font(.tText(14, weight: .semibold))
                    .foregroundColor(.tTextMute)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: 0x8b5cf6, opacity: 0.06))
                    )
            }
            .buttonStyle(TripnestPressStyle())

            Button(action: onConfirm) {
                Text("Confirmer")
                    .font(.tText(14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.tAccent)
                    )
            }
            .buttonStyle(TripnestPressStyle())
        }
    }

    private enum PickerKind { case date, departure, arrival, duration }

    private func closeAllPickers(except kind: PickerKind) {
        pickingDate = kind == .date
        pickingDeparture = kind == .departure
        pickingArrival = kind == .arrival
        pickingDuration = kind == .duration
    }
}

private enum TicketFormChrome {
    static var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(hex: 0x8b5cf6, opacity: 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tBorderStrong, lineWidth: 1)
            )
    }
}

// MARK: - Scanner (caméra document native)

struct TravelTicketCameraScanFlow: View {
    let mode: TransportMode
    var onScanned: (TravelTicketDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if VNDocumentCameraViewController.isSupported {
                TravelTicketDocumentScanner(
                    onImage: process,
                    onCancel: { dismiss() }
                )
                .ignoresSafeArea()
            } else {
                fallbackCamera
            }

            if isProcessing {
                Color.black.opacity(0.72).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.tAccent2)
                        .scaleEffect(1.2)
                    Text("Lecture du billet…")
                        .font(.tText(15, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .alert("Billet non reconnu", isPresented: showErrorBinding) {
            Button("Réessayer", role: .cancel) {}
            Button("Fermer") { dismiss() }
        } message: {
            Text(errorMessage ?? "Prends une photo plus nette ou saisis le billet à la main.")
        }
    }

    private var showErrorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil && !isProcessing },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private var fallbackCamera: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TicketScanCameraPicker(
                onImage: process,
                onCancel: { dismiss() }
            )
            .ignoresSafeArea()
        }
    }

    private func process(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil
        Task {
            if let draft = await TicketScanService.scan(image: image, mode: mode),
               draft.hasMinimumInfo || !draft.code.isEmpty || !draft.fromCity.isEmpty {
                await MainActor.run {
                    isProcessing = false
                    onScanned(draft)
                    dismiss()
                }
            } else {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Impossible de lire ce billet."
                }
            }
        }
    }
}

private struct TravelTicketDocumentScanner: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, onCancel: onCancel)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0 else {
                onCancel()
                return
            }
            onImage(scan.imageOfPage(at: 0))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onCancel()
        }
    }
}

/// Caméra simple si le scan document n’est pas disponible (simulateur).
private struct TicketScanCameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            picker.cameraDevice = .rear
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

// MARK: - Carte accueil

struct HomeTravelTicketCard: View {
    let ticket: Flight
    let mode: TransportMode
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            TCard(padding: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text(mode.ticketHomeHeading)
                            .font(.tText(11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.tTextMute)
                        Spacer()
                        if !ticket.code.isEmpty {
                            Text(ticket.code)
                                .font(.tText(11, weight: .bold))
                                .foregroundColor(.tGold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.tGold.opacity(0.12)))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                    DashedDivider()
                    HStack(alignment: .top, spacing: 8) {
                        ticketEndpoint(city: ticket.fromCity, code: ticket.from, detail: "\(ticket.date) · \(ticket.departure)", leading: true)
                        Spacer()
                        TransportModeGlyph(mode: mode, size: 16, stroke: .tAccent2)
                        Spacer()
                        ticketEndpoint(city: ticket.toCity, code: ticket.to, detail: "\(ticket.date) · \(ticket.arrival)", leading: false)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
            }
        }
        .buttonStyle(TripnestPressStyle())
    }

    private func ticketEndpoint(city: String, code: String, detail: String, leading: Bool) -> some View {
        VStack(alignment: leading ? .leading : .trailing, spacing: 2) {
            Text(city.isEmpty ? "Départ" : city).font(.tText(12)).foregroundColor(.tTextMute)
            Text(code.isEmpty ? "---" : code).font(.tDisplay(28)).tracking(-0.5).lineLimit(1)
            Text(detail.trimmingCharacters(in: .whitespaces).isEmpty ? "--" : detail)
                .font(.tText(12))
                .foregroundColor(.tTextMute)
                .lineLimit(1)
        }
    }
}
