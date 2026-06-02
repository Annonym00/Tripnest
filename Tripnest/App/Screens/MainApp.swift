import SwiftUI

struct MainApp: View {
    @EnvironmentObject private var store: TripStore
    var onLogout: () -> Void = {}
    @State private var baseRoute: AppRoute = .home
    @State private var modalRoute: AppRoute?
    @State private var formTripId: String?
    @State private var formExpenseId: String?
    @State private var motion: NavMotion = .tab(forward: true)
    @State private var routeHistory: [AppRoute] = []
    @State private var pendingDeleteId: String?
    @AppStorage("tripnest.profile.name") private var profileName: String = ""

    /// Première arrivée dans l'app : tant qu'aucun nom de profil n'est défini,
    /// on bloque tout derrière l'écran de saisie du nom.
    private var needsProfileName: Bool {
        profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isPushedRoute: Bool {
        !baseRoute.isTabRoot && !baseRoute.isModal
    }

    private var activeTab: AppRoute {
        if baseRoute.isTabRoot { return baseRoute }
        return routeHistory.last ?? fallbackBack(for: baseRoute)
    }

    var body: some View {
        ZStack {
            persistentTabLayer
                .zIndex(0)

            if isPushedRoute {
                pushedScreen
                    .transition(motion.transition)
                    .swipeBack(enabled: modalRoute == nil && baseRoute.supportsSwipeBack, onBack: goBack)
                    .zIndex(1)
            }

            if let modalRoute {
                modalScreen(modalRoute)
                    .transition(TripnestPageTransition.modal)
                    .zIndex(2)
            }

            if needsProfileName {
                ProfileNameGate()
                    .zIndex(10)
                    .transition(.opacity)
            }
        }
        .environment(\.tripnestSkipShellMotion, true)
        .alert("Supprimer ce voyage ?", isPresented: deleteAlertBinding) {
            Button("Annuler", role: .cancel) { pendingDeleteId = nil }
            Button("Supprimer", role: .destructive) {
                if let id = pendingDeleteId {
                    store.deleteTrip(id: id)
                    Haptics.success()
                    if modalRoute == .editTrip {
                        dismissModal()
                    } else if baseRoute == .trip {
                        goBack()
                    }
                }
                pendingDeleteId = nil
            }
        } message: {
            if let id = pendingDeleteId, let trip = store.trips.first(where: { $0.id == id }) {
                Text("« \(trip.dest) » et toutes ses dépenses, vols et spots seront effacés.")
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteId != nil },
            set: { if !$0 { pendingDeleteId = nil } }
        )
    }

    private func openEditTrip(_ id: String) {
        formTripId = id
        withAnimation(TripnestAnimation.modal) {
            modalRoute = .editTrip
        }
        DispatchQueue.main.async {
            store.selectTrip(id: id)
        }
    }

    private func openEditExpense(_ id: String) {
        formExpenseId = id
        presentModal(.add)
    }

    private var persistentTabLayer: some View {
        ZStack {
            tabLayer(.home) {
                HomeScreen(onNav: navigate, onEditTrip: openEditTrip, onDeleteTrip: { pendingDeleteId = $0 })
            }
            tabLayer(.trips) {
                TripsScreen(onNav: navigate, onEditTrip: openEditTrip, onDeleteTrip: { pendingDeleteId = $0 })
            }
            tabLayer(.budget) {
                BudgetHubScreen(onNav: navigate)
            }
            tabLayer(.profile) {
                ProfileScreen(onNav: navigate, onLogout: onLogout)
            }
        }
    }

    private func tabLayer<Content: View>(_ tab: AppRoute, @ViewBuilder content: () -> Content) -> some View {
        let isVisible = activeTab == tab && !isPushedRoute && modalRoute == nil
        return content()
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
            .accessibilityHidden(!isVisible)
            // Pause FlyingPlanesLayer sur les onglets non visibles → 1 seul Canvas actif à la fois.
            .environment(\.tripnestScreenActive, isVisible)
    }

    @ViewBuilder
    private var pushedScreen: some View {
        switch baseRoute {
        case .trip:
            TripDetailScreen(onNav: navigate, onBack: goBack)
        case .completedTrips:
            CompletedTripsScreen(onNav: navigate, onEditTrip: openEditTrip, onDeleteTrip: { pendingDeleteId = $0 })
        case .flights:
            FlightsScreen(onNav: navigate, onBack: goBack)
        case .tripPlanning:
            TripPlanningScreen(tripId: store.selectedTripId, onNav: navigate, onBack: goBack)
        case .tripSouvenirs:
            TripSouvenirsScreen(tripId: store.selectedTripId, onNav: navigate, onBack: goBack)
        case .tripNotes:
            NotesScreen(tripId: store.selectedTripId, onNav: navigate, onBack: goBack)
        case .tripBudget:
            BudgetScreen(onNav: navigate, onEditExpense: openEditExpense, onBack: goBack)
        case .spots:
            SpotsScreen(
                onNav: navigate,
                onBack: goBack,
                showsSubpageBack: routeHistory.last == .trip
            )
        case .newSpot:
            AddSpotScreen(onBack: goBack)
        case .memories:
            MemoriesScreen(onNav: navigate)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func modalScreen(_ route: AppRoute) -> some View {
        switch route {
        case .add:
            AddExpenseScreen(
                expenseId: formExpenseId,
                onClose: { dismissModal() },
                onSave: {
                    dismissModal()
                    if store.selectedTripId != nil {
                        navigate(.tripBudget)
                    } else {
                        navigate(.budget)
                    }
                }
            )
        case .newTrip:
            TripFormScreen(onClose: { dismissModal() }, onSave: { dismissModal(); navigate(.home) })
        case .editTrip:
            TripFormScreen(
                tripId: formTripId,
                onClose: { dismissModal() },
                onSave: { dismissModal() },
                onDelete: { pendingDeleteId = $0 }
            )
        default:
            EmptyView()
        }
    }

    private func navigate(_ target: AppRoute) {
        if target.isModal {
            if target == .editTrip, formTripId == nil {
                formTripId = store.activeTrip?.id
            }
            if target == .newTrip {
                formTripId = nil
            }
            if target == .add {
                formExpenseId = nil
            }
            presentModal(target)
            return
        }

        if modalRoute != nil {
            dismissModal(animated: false)
        }

        if target.isTabRoot {
            routeHistory.removeAll()
        } else {
            routeHistory.append(baseRoute)
        }

        let nextMotion = AppNavigator.motion(from: baseRoute, to: target)
        if target.isTabRoot {
            motion = nextMotion
            baseRoute = target
        } else {
            withAnimation(animation(for: nextMotion)) {
                motion = nextMotion
                baseRoute = target
            }
        }
    }

    private func presentModal(_ target: AppRoute) {
        withAnimation(TripnestAnimation.modal) {
            modalRoute = target
        }
    }

    private func dismissModal(animated: Bool = true) {
        let clear = {
            modalRoute = nil
            formTripId = nil
            formExpenseId = nil
        }
        if animated {
            withAnimation(TripnestAnimation.modal, clear)
        } else {
            clear()
        }
    }

    private func goBack() {
        if modalRoute != nil {
            dismissModal()
            return
        }

        let destination = routeHistory.popLast() ?? fallbackBack(for: baseRoute)
        withAnimation(TripnestAnimation.page) {
            motion = .pop
            baseRoute = destination
        }
    }

    private func animation(for motion: NavMotion) -> Animation {
        switch motion {
        case .tab: return TripnestAnimation.tab
        case .modal: return TripnestAnimation.modal
        case .push, .pop: return TripnestAnimation.page
        }
    }

    private func fallbackBack(for route: AppRoute) -> AppRoute {
        switch route {
        case .tripBudget: return .budget
        case .trip, .tripPlanning, .tripSouvenirs, .tripNotes, .flights, .spots, .newSpot, .memories, .completedTrips: return .trips
        default: return .home
        }
    }
}

struct TripFormScreen: View {
    @EnvironmentObject private var store: TripStore
    var tripId: String? = nil
    var onClose: () -> Void = {}
    var onSave: () -> Void = {}
    var onDelete: ((String) -> Void)? = nil

    @State private var origin = ""
    @State private var destination = ""
    @State private var departureDate: Date? = nil
    @State private var oneWay = true
    @State private var addReturn = false
    @State private var returnLocation = ""
    @State private var returnDate: Date? = nil
    @State private var transportMode: TransportMode?
    @State private var tripTitle = ""
    @State private var coverKind: TripCoverKind = .none
    @State private var coverColor: String = TripCoverPalette.defaultHex()
    @State private var draftCoverImage: UIImage?
    @State private var showGalleryPicker = false
    @State private var showCameraPicker = false
    @State private var showColorPicker = false
    @State private var pendingCoverCrop: PendingCoverCrop?
    @State private var isChoosingTransport = false
    @State private var originValidation: LocationFieldValidation = .unknown
    @State private var destinationValidation: LocationFieldValidation = .unknown
    @State private var returnLocationValidation: LocationFieldValidation = .unknown
    @State private var transportLocationSnapshots: [TransportMode: TransportLocationSnapshot] = [:]
    @State private var ticketDraft: TravelTicketDraft?
    @State private var showTicketEditor = false
    @State private var showTicketScanner = false
    @State private var editingTicket = TravelTicketDraft()
    @State private var loaded = false
    @State private var selectedTravelFriendIds: Set<String> = []
    @State private var pendingTravelFriendNames: [String] = []
    @State private var travelFriendInviteName = ""
    @State private var travelFriendInviteFeedback = ""
    @State private var travelFriendsCanEdit = false
    @State private var showTravelInviteControls = false

    private struct TransportLocationSnapshot {
        var origin: String
        var destination: String
        var returnLocation: String
        var originValidation: LocationFieldValidation
        var destinationValidation: LocationFieldValidation
        var returnLocationValidation: LocationFieldValidation
    }

    private var isEditing: Bool { tripId != nil }
    private var activeMode: TransportMode { transportMode ?? .car }
    private var showsTransportPicker: Bool {
        isChoosingTransport || (!isEditing && transportMode == nil)
    }

    private var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var returnMinimumDate: Date {
        guard let departureDate else { return todayStart }
        return max(todayStart, Calendar.current.startOfDay(for: departureDate))
    }

    private var locationsAreValid: Bool {
        originValidation == .valid
            && destinationValidation == .valid
            && (!addReturn || returnLocationValidation == .valid)
    }

    private var canSave: Bool {
        let hasOrigin = !origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDestination = !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDepartureDate = departureDate != nil
        let returnFieldsValid = !addReturn || (
            !returnLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && returnDate != nil
        )
        return formIsReady
            && hasOrigin
            && hasDestination
            && hasDepartureDate
            && returnFieldsValid
            && locationsAreValid
    }

    /// En édition, attendre le chargement du voyage avant d’autoriser l’enregistrement.
    private var formIsReady: Bool { !isEditing || loaded }

    var body: some View {
        ScreenShell {
            if showsTransportPicker {
                TransportModePickerView(
                    onSelect: { mode in
                        withAnimation(TripnestAnimation.page) {
                            transportMode = mode
                            isChoosingTransport = false
                        }
                    },
                    onClose: {
                        if isChoosingTransport {
                            isChoosingTransport = false
                        } else {
                            onClose()
                        }
                    }
                )
            } else if isEditing && !loaded {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.tAccent2)
                    Text("Chargement du voyage…")
                        .font(.tText(14))
                        .foregroundColor(.tTextMute)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                tripFormContent
            }
        }
        .onAppear { loadIfNeeded() }
        .task(id: tripId) {
            loadIfNeeded()
        }
        .onChange(of: tripId) { _, _ in
            loaded = false
            transportLocationSnapshots = [:]
            selectedTravelFriendIds = []
            pendingTravelFriendNames = []
            travelFriendInviteName = ""
            travelFriendInviteFeedback = ""
            travelFriendsCanEdit = false
            showTravelInviteControls = false
            loadIfNeeded()
        }
        .onChange(of: oneWay) { _, isOn in
            if isOn {
                addReturn = false
                returnDate = nil
            }
        }
        .onChange(of: addReturn) { _, isOn in
            if isOn {
                oneWay = false
                if returnLocation.isEmpty {
                    returnLocation = origin
                }
            } else {
                returnLocation = ""
                returnDate = nil
                returnLocationValidation = .unknown
            }
        }
        .onChange(of: transportMode) { oldMode, newMode in
            guard let newMode else { return }
            if newMode == .car || oldMode != newMode {
                ticketDraft = nil
            }
            applyTransportModeChange(from: oldMode, to: newMode)
        }
        .sheet(isPresented: $showTicketEditor) {
            TravelTicketEditorSheet(
                mode: activeMode,
                draft: $editingTicket,
                tripOrigin: origin,
                tripDestination: destination,
                tripDepartureDate: departureDate,
                onDone: {
                    ticketDraft = editingTicket
                    editingTicket.applyToTripForm(
                        origin: &origin,
                        destination: &destination,
                        departureDate: &departureDate
                    )
                }
            )
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        }
        .fullScreenCover(isPresented: $showTicketScanner) {
            TravelTicketCameraScanFlow(mode: activeMode) { scanned in
                ticketDraft = scanned
                editingTicket = scanned
                scanned.applyToTripForm(
                    origin: &origin,
                    destination: &destination,
                    departureDate: &departureDate
                )
            }
        }
        .onChange(of: departureDate) { _, newDep in
            guard let ret = returnDate, let dep = newDep else { return }
            if Calendar.current.startOfDay(for: ret) < Calendar.current.startOfDay(for: dep) {
                returnDate = nil
            }
        }
        .sheet(isPresented: $showGalleryPicker) {
            GalleryPhotoPicker(
                onImage: { image in
                    showGalleryPicker = false
                    presentCoverCrop(with: image)
                },
                onCancel: { showGalleryPicker = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraImagePicker(
                onImage: { image in
                    showCameraPicker = false
                    presentCoverCrop(with: image)
                },
                onCancel: { showCameraPicker = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $pendingCoverCrop) { payload in
            TripCoverCropSheet(
                sourceImage: payload.image,
                onConfirm: { cropped in
                    draftCoverImage = cropped
                    coverKind = .custom
                    pendingCoverCrop = nil
                },
                onCancel: { pendingCoverCrop = nil }
            )
        }
    }

    private var tripFormContent: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) { IconBtn(glyph: .close) }
                    .buttonStyle(TripnestPressStyle())
                Spacer()
                Text(isEditing ? "Modifier le voyage" : "Nouveau voyage")
                    .font(.tText(16, weight: .bold))
                Spacer()
                Button(action: save) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.tAccent)
                        TIcon(glyph: .check, size: 20, stroke: .white, strokeWidth: 2)
                    }
                    .frame(width: 40, height: 40)
                }
                .buttonStyle(TripnestPressStyle())
                .opacity(canSave ? 1 : 0.45)
                .disabled(!canSave)
            }
            .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 14)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Color.clear
                            .frame(height: 1)
                            .id("tripFormTop")

                        transportModeBadge

                        if activeMode.supportsTravelTicket {
                            TravelTicketFormSection(
                                mode: activeMode,
                                draft: $ticketDraft,
                                onEdit: openTicketEditor,
                                onScan: { showTicketScanner = true }
                            )
                        }

                        travelCompanionsSection

                        FormField(
                            label: "Titre du voyage",
                            text: $tripTitle,
                            placeholder: "Titre du voyage",
                            showsClearButton: true
                        )

                        tripCoverSection

                        FormLocationField(
                            label: "Lieu de départ",
                            placeholder: activeMode.originPlaceholder,
                            text: $origin,
                            validation: $originValidation,
                            transportMode: activeMode
                        )
                        FormLocationField(
                            label: "Lieu de destination",
                            placeholder: activeMode.destinationPlaceholder,
                            text: $destination,
                            validation: $destinationValidation,
                            transportMode: activeMode
                        )

                        FormOptionalDateField(
                            label: "Date et heure de départ",
                            placeholder: "Ajouter le départ",
                            date: $departureDate,
                            minimumDate: todayStart,
                            includesTime: true
                        )

                        TCard(padding: 4) {
                            VStack(spacing: 0) {
                                TripCheckboxRow(
                                    label: "Aller sans retour",
                                    subtitle: "Voyage aller simple",
                                    isOn: $oneWay
                                )
                                Divider().background(Color.tBorder).padding(.horizontal, 14)
                                TripCheckboxRow(
                                    label: "Rajouter le retour",
                                    subtitle: "Indique où tu repars au retour",
                                    isOn: $addReturn
                                )
                            }
                        }

                        if addReturn {
                            FormLocationField(
                                label: "Lieu de retour",
                                placeholder: activeMode.originPlaceholder,
                                text: $returnLocation,
                                validation: $returnLocationValidation,
                                transportMode: activeMode
                            )
                            FormOptionalDateField(
                                label: "Date et heure de retour",
                                placeholder: "Ajouter le retour",
                                date: $returnDate,
                                minimumDate: returnMinimumDate,
                                includesTime: true,
                                fieldID: "returnDateField",
                                onPickingChanged: { picking in
                                    guard picking else { return }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withAnimation(TripnestAnimation.page) {
                                            proxy.scrollTo("returnDateField", anchor: .center)
                                        }
                                    }
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if isEditing, let tripId, let onDelete {
                            Button(role: .destructive) {
                                Haptics.impact(.medium)
                                onDelete(tripId)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Supprimer ce voyage")
                                        .font(.tText(14, weight: .bold))
                                    Spacer()
                                }
                                .foregroundColor(.tRose)
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.tSurface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.tRose.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(TripnestPressStyle())
                            .padding(.top, 8)
                        }

                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, TripnestLayout.formScrollBreathing)
                    .animation(TripnestAnimation.page, value: addReturn)
                }
                .tripnestScrollBounceWhenNeeded()
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: draftCoverImage) { _, _ in
                    DispatchQueue.main.async {
                        proxy.scrollTo("tripFormTop", anchor: .top)
                    }
                }
            }
        }
    }

    private var previewHue: Double {
        let seed = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = seed.isEmpty ? tripTitle : seed
        return Double(abs(value.hashValue % 300) + 20)
    }

    private var tripCoverSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("IMAGE DE FOND")
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)

            TripCoverAspectContainer(maxHeight: 148, cornerRadius: 16) {
                TripPhoto(
                    destination: destination.isEmpty ? "Voyage" : destination,
                    country: "",
                    hue: previewHue,
                    radius: 0,
                    showBorder: false,
                    coverKind: coverKind,
                    tripId: tripId,
                    previewImage: draftCoverImage,
                    solidColor: TripCoverPalette.color(fromHex: coverColor)
                )
            }

            HStack(spacing: 8) {
                Button {
                    showGalleryPicker = true
                    Haptics.selection()
                } label: {
                    coverActionLabel(
                        title: "Galerie",
                        icon: "photo.on.rectangle.angled",
                        isSelected: coverKind == .custom && draftCoverImage != nil
                    )
                }
                .buttonStyle(TripnestPressStyle())

                Button {
                    showCameraPicker = true
                    Haptics.selection()
                } label: {
                    coverActionLabel(title: "Appareil", icon: "camera.fill")
                }
                .buttonStyle(TripnestPressStyle())

                Button {
                    showColorPicker = true
                    Haptics.selection()
                } label: {
                    coverActionLabel(
                        title: "Couleur",
                        icon: "paintpalette.fill",
                        isSelected: coverKind != .custom
                    )
                }
                .buttonStyle(TripnestPressStyle())
            }

            if showColorPicker {
                tripColorPicker
                    .transition(
                        .scale(scale: 0.94, anchor: .top)
                            .combined(with: .opacity)
                    )
            }
        }
        .animation(TripnestAnimation.soft, value: showColorPicker)
    }

    private var tripColorPicker: some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: 10), count: 6)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Choisis une couleur")
                    .font(.tText(12, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.tTextMute)
                Spacer()
                Button {
                    var tx = Transaction()
                    tx.disablesAnimations = true
                    withTransaction(tx) { showColorPicker = false }
                    Haptics.selection()
                } label: {
                    TIcon(glyph: .close, size: 14, stroke: .tTextMute)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.tSurface))
                        .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(TripCoverPalette.hexCodes, id: \.self) { hex in
                    Button {
                        coverColor = hex
                        coverKind = .none
                        draftCoverImage = nil
                        Haptics.selection()
                    } label: {
                        let contrast: Color = TripCoverPalette.isLight(hex: hex) ? .black : .white
                        ZStack {
                            Circle()
                                .fill(TripCoverPalette.color(fromHex: hex) ?? Color.tAccent)
                            Circle()
                                .stroke(contrast.opacity(0.22), lineWidth: 1)
                            if coverColor.caseInsensitiveCompare(hex) == .orderedSame, coverKind != .custom {
                                Circle()
                                    .stroke(contrast, lineWidth: 2.5)
                                    .padding(2)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(contrast)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .shadow(
                            color: (TripCoverPalette.color(fromHex: hex) ?? .tAccent).opacity(0.45),
                            radius: 6, x: 0, y: 2
                        )
                    }
                    .buttonStyle(TripnestPressStyle())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.tSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.tBorder, lineWidth: 1)
        )
    }

    private func presentCoverCrop(with image: UIImage) {
        // On attend la fin de la fermeture du picker avant de présenter le recadrage.
        // Sans ce délai, SwiftUI tente de présenter le 2ᵉ écran pendant que le 1ᵉ se
        // ferme → présentation qui « rame » / saute (le bug du choix d'image de fond).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            pendingCoverCrop = PendingCoverCrop(image: image)
        }
    }

    private func coverActionLabel(title: String, icon: String, isSelected: Bool = false) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.tText(11, weight: .semibold))
        }
        .foregroundColor(isSelected ? .white : .tTextMute)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.tAccent : Color(hex: 0x1c0f36))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.clear : Color.tBorder, lineWidth: 1)
        )
    }

    private var transportModeBadge: some View {
        HStack(spacing: 10) {
            TCard(padding: 12) {
                HStack(spacing: 10) {
                    transportModeIcon(activeMode)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Transport")
                            .font(.tText(11, weight: .semibold))
                            .foregroundColor(.tTextMute)
                        Text(activeMode.label)
                            .font(.tText(14, weight: .bold))
                    }
                    Spacer()
                }
            }
            Button {
                Haptics.selection()
                withAnimation(TripnestAnimation.page) {
                    isChoosingTransport = true
                }
            } label: {
                Text("Changer")
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.tAccent2)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.tAccent2.opacity(0.10))
                    )
            }
            .buttonStyle(TripnestPressStyle())
        }
    }

    private func transportModeIcon(_ mode: TransportMode) -> some View {
        TransportModeGlyph(mode: mode, size: 18, stroke: .tAccent2)
    }

    private var travelCompanionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AVEC QUI TU VAS VOYAGER ?")
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)

            TCard(padding: 4) {
                VStack(spacing: 0) {
                    if !store.friends.isEmpty || !pendingTravelFriendNames.isEmpty {
                        ForEach(store.friends) { friend in
                            travelFriendRow(
                                name: friend.name,
                                subtitle: friend.status == .accepted ? "Ami Tripnest" : "Invitation en attente",
                                isSelected: selectedTravelFriendIds.contains(friend.id),
                                action: { toggleTravelFriend(friend.id) }
                            )
                            if (store.friends.last?.id != friend.id) || !pendingTravelFriendNames.isEmpty {
                                Divider().background(Color.tBorder).padding(.horizontal, 14)
                            }
                        }

                        ForEach(pendingTravelFriendNames, id: \.self) { name in
                            travelFriendRow(
                                name: name,
                                subtitle: "Sera invité après l'enregistrement",
                                isSelected: true,
                                action: { removePendingTravelFriend(name) }
                            )
                            if pendingTravelFriendNames.last != name {
                                Divider().background(Color.tBorder).padding(.horizontal, 14)
                            }
                        }
                    }

                    if !store.friends.isEmpty || !pendingTravelFriendNames.isEmpty {
                        Divider().background(Color.tBorder).padding(.horizontal, 14)
                    }

                    travelInviteBubble

                    if showTravelInviteControls {
                        Divider().background(Color.tBorder).padding(.horizontal, 14)

                        VStack(spacing: 0) {
                            travelPermissionRow(
                                title: "Peut modifier",
                                subtitle: "Ton ami pourra ajouter ou changer le voyage.",
                                isSelected: travelFriendsCanEdit,
                                action: { travelFriendsCanEdit = true }
                            )
                            Divider().background(Color.tBorder).padding(.horizontal, 14)
                            travelPermissionRow(
                                title: "Regarder seulement",
                                subtitle: "Ton ami verra le voyage en direct sans modifier.",
                                isSelected: !travelFriendsCanEdit,
                                action: { travelFriendsCanEdit = false }
                            )
                        }

                        Divider().background(Color.tBorder).padding(.horizontal, 14)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                TextField("Nom de l'ami Tripnest", text: $travelFriendInviteName)
                                    .font(.tText(14))
                                    .foregroundColor(.tText)
                                    .textInputAutocapitalization(.words)
                                    .padding(.horizontal, 14)
                                    .frame(height: 46)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(hex: 0x1b0e34))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.tBorder, lineWidth: 1)
                                    )

                                Button(action: inviteTravelFriend) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 13, weight: .bold))
                                        Text("Inviter")
                                            .font(.tText(12, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .frame(height: 46)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.tAccent)
                                    )
                                }
                                .buttonStyle(TripnestPressStyle())
                                .opacity(travelFriendInviteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                                .disabled(travelFriendInviteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            if !travelFriendInviteFeedback.isEmpty {
                                Text(travelFriendInviteFeedback)
                                    .font(.tText(12))
                                    .foregroundColor(.tTextMute)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(14)
                    }
                }
            }
        }
    }

    private var travelInviteBubble: some View {
        Button {
            withAnimation(TripnestAnimation.soft) {
                showTravelInviteControls.toggle()
            }
            travelFriendInviteFeedback = ""
            Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                TIcon(glyph: .user, size: 17, stroke: .tAccent2)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.tAccent2.opacity(0.12)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Invite un ami qui a Tripnest")
                        .font(.tText(14, weight: .bold))
                        .foregroundColor(.tText)
                    Text("Appuie ici seulement si tu veux inviter quelqu'un.")
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: showTravelInviteControls ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.tTextMute)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func travelFriendRow(
        name: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Avatar(initials: initials(for: name), size: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.tText(14, weight: .bold))
                        .foregroundColor(.tText)
                    Text(subtitle)
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .tMint : .tTextMute)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func travelPermissionRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            action()
            travelFriendInviteFeedback = ""
            Haptics.selection()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .tMint : .tTextMute)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.tText(14, weight: .bold))
                        .foregroundColor(.tText)
                    Text(subtitle)
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func initials(for name: String) -> String {
        let parts = name.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "?"
        let last = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private func toggleTravelFriend(_ id: String) {
        if selectedTravelFriendIds.contains(id) {
            selectedTravelFriendIds.remove(id)
        } else {
            selectedTravelFriendIds.insert(id)
        }
        travelFriendInviteFeedback = ""
        Haptics.selection()
    }

    private func removePendingTravelFriend(_ name: String) {
        pendingTravelFriendNames.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
        travelFriendInviteFeedback = ""
        Haptics.selection()
    }

    private func inviteTravelFriend() {
        let trimmed = travelFriendInviteName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let canonical = TripStore.userDirectory.first(where: {
            $0.caseInsensitiveCompare(trimmed) == .orderedSame
        }) else {
            travelFriendInviteFeedback = "Cet utilisateur n'a pas encore Tripnest."
            Haptics.warning()
            return
        }
        if let existing = store.friends.first(where: { $0.name.caseInsensitiveCompare(canonical) == .orderedSame }) {
            selectedTravelFriendIds.insert(existing.id)
            travelFriendInviteFeedback = "\(existing.name) sera ajouté au voyage en mode \(travelPermissionLabel)."
        } else if pendingTravelFriendNames.contains(where: { $0.caseInsensitiveCompare(canonical) == .orderedSame }) {
            travelFriendInviteFeedback = "\(canonical) est déjà prêt à être invité."
        } else {
            pendingTravelFriendNames.append(canonical)
            travelFriendInviteFeedback = "\(canonical) recevra l'invitation après l'enregistrement en mode \(travelPermissionLabel)."
        }
        travelFriendInviteName = ""
        Haptics.success()
    }

    private var travelPermissionLabel: String {
        travelFriendsCanEdit ? "modification" : "lecture seule"
    }

    private func openTicketEditor() {
        var draft = ticketDraft ?? TravelTicketDraft()
        draft.prefillFromTrip(
            origin: origin,
            destination: destination,
            departureDate: departureDate
        )
        editingTicket = draft
        showTicketEditor = true
    }

    private func persistTicket(for tripId: String) {
        guard activeMode.supportsTravelTicket, let draft = ticketDraft, draft.hasMinimumInfo else { return }
        store.replaceTicket(for: tripId, mode: activeMode, draft: draft)
    }

    private func loadIfNeeded() {
        guard isEditing, !loaded, let id = tripId,
              let trip = store.trips.first(where: { $0.id == id }) else { return }
        origin = trip.origin
        destination = trip.dest
        tripTitle = trip.resolvedCustomTitle ?? ""
        coverKind = trip.coverKind == .automatic ? .none : trip.coverKind
        coverColor = trip.coverColor.isEmpty
            ? TripCoverPalette.deterministicHex(forKey: trip.id)
            : trip.coverColor
        draftCoverImage = trip.coverKind == .custom ? TripCoverImageStore.load(tripId: id) : nil
        departureDate = trip.departureDate
        transportMode = trip.transportMode
        if trip.isOneWay {
            oneWay = true
            addReturn = false
            returnLocation = ""
            returnDate = nil
        } else {
            oneWay = false
            addReturn = true
            returnLocation = trip.returnLocation ?? ""
            returnDate = trip.returnDate
        }
        storeLocationSnapshot(for: trip.transportMode)
        if trip.transportMode.supportsTravelTicket, let existing = store.primaryTicket(for: trip) {
            ticketDraft = TravelTicketDraft(flight: existing)
        }
        selectedTravelFriendIds = Set(store.friends.filter { $0.sharedTripIds.contains(id) }.map(\.id))
        loaded = true
        Task { await revalidateAllLocations(mode: trip.transportMode) }
    }

    private func storeLocationSnapshot(for mode: TransportMode) {
        transportLocationSnapshots[mode] = TransportLocationSnapshot(
            origin: origin,
            destination: destination,
            returnLocation: returnLocation,
            originValidation: originValidation,
            destinationValidation: destinationValidation,
            returnLocationValidation: returnLocationValidation
        )
    }

    private func applyTransportModeChange(from oldMode: TransportMode?, to newMode: TransportMode) {
        if let oldMode {
            storeLocationSnapshot(for: oldMode)
        }

        if let snapshot = transportLocationSnapshots[newMode] {
            origin = snapshot.origin
            destination = snapshot.destination
            returnLocation = snapshot.returnLocation
            originValidation = snapshot.originValidation
            destinationValidation = snapshot.destinationValidation
            returnLocationValidation = snapshot.returnLocationValidation
            if originValidation == .unknown || destinationValidation == .unknown {
                Task { await revalidateAllLocations(mode: newMode) }
            }
        } else {
            clearLocationFields()
        }
    }

    private func clearLocationFields() {
        origin = ""
        destination = ""
        returnLocation = ""
        originValidation = .unknown
        destinationValidation = .unknown
        returnLocationValidation = .unknown
    }

    @MainActor
    private func revalidateAllLocations(mode: TransportMode) async {
        await validateLocationField(
            text: origin,
            mode: mode,
            assign: { originValidation = $0 }
        )
        await validateLocationField(
            text: destination,
            mode: mode,
            assign: { destinationValidation = $0 }
        )
        if addReturn {
            await validateLocationField(
                text: returnLocation,
                mode: mode,
                assign: { returnLocationValidation = $0 }
            )
        } else {
            returnLocationValidation = .unknown
        }
        storeLocationSnapshot(for: mode)
    }

    @MainActor
    private func validateLocationField(
        text: String,
        mode: TransportMode,
        assign: (LocationFieldValidation) -> Void
    ) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            assign(.unknown)
            return
        }
        assign(.validating)
        let isValid = await TripPlaceResolver.isValidPlace(trimmed, mode: mode)
        assign(isValid ? .valid : .invalid)
    }

    private func persistCover(for tripId: String) {
        switch coverKind {
        case .custom:
            if let draftCoverImage {
                TripCoverImageStore.save(draftCoverImage, tripId: tripId)
            }
        case .automatic, .none:
            TripCoverImageStore.delete(tripId: tripId)
        }
        TripCoverImagePalette.invalidate(tripId: tripId)
    }

    private func finalizedTravelFriendIds() -> Set<String> {
        var friendIds = selectedTravelFriendIds
        for name in pendingTravelFriendNames {
            _ = store.addFriend(name: name)
            if let friend = store.friends.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                friendIds.insert(friend.id)
            }
        }
        return friendIds
    }

    private func save() {
        guard formIsReady else { return }
        guard canSave else {
            Haptics.warning()
            return
        }
        let companionIds = finalizedTravelFriendIds()
        let returnLoc = addReturn ? returnLocation : nil
        let retDate = addReturn ? returnDate : nil
        if let id = tripId {
            persistCover(for: id)
            store.updateTrip(
                id: id,
                origin: origin,
                destination: destination,
                departureDate: departureDate,
                returnLocation: returnLoc,
                returnDate: retDate,
                transportMode: activeMode,
                tripTitle: tripTitle,
                coverKind: coverKind,
                coverColor: coverColor
            )
            persistTicket(for: id)
            store.setTripCompanions(tripId: id, friendIds: companionIds, canEdit: travelFriendsCanEdit)
        } else {
            let newId = UUID().uuidString
            persistCover(for: newId)
            store.addTrip(
                origin: origin,
                destination: destination,
                departureDate: departureDate,
                returnLocation: returnLoc,
                returnDate: retDate,
                transportMode: activeMode,
                tripTitle: tripTitle,
                coverKind: coverKind,
                coverColor: coverColor,
                id: newId
            )
            persistTicket(for: newId)
            store.setTripCompanions(tripId: newId, friendIds: companionIds, canEdit: travelFriendsCanEdit)
        }
        Haptics.success()
        onSave()
    }
}

// Legacy alias
typealias NewTripScreen = TripFormScreen

struct FormField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var showsClearButton: Bool = false

    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)

            HStack(spacing: 0) {
                TextField(placeholder, text: $text)
                    .font(.tText(16))
                    .foregroundColor(.tText)
                    .textInputAutocapitalization(.words)
                    .padding(.leading, 18)
                    .padding(.trailing, showsClearButton && hasText ? 8 : 18)

                if showsClearButton, hasText {
                    Button {
                        text = ""
                        Haptics.selection()
                    } label: {
                        TIcon(glyph: .close, size: 14, stroke: .tTextMute)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(TripnestPressStyle())
                    .padding(.trailing, 6)
                }
            }
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: 0x1b0e34))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tBorderStrong, lineWidth: 1)
            )
        }
        .animation(.easeOut(duration: 0.12), value: hasText)
    }
}

struct FormOptionalDateField: View {
    let label: String
    var placeholder: String = "Ajouter une date"
    @Binding var date: Date?
    var minimumDate: Date = Calendar.current.startOfDay(for: Date())
    var includesTime: Bool = false
    var fieldID: String? = nil
    var onPickingChanged: ((Bool) -> Void)? = nil

    @State private var isPicking = false
    @State private var draftDate = Date()

    private static var frLocale: Locale { Locale(identifier: "fr_FR") }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)

            if isPicking {
                pickingView
            } else if let date {
                setView(date)
            } else {
                addButton
            }
        }
        .id(fieldID)
        .animation(TripnestAnimation.page, value: isPicking)
        .animation(TripnestAnimation.page, value: date)
        .onChange(of: isPicking) { _, picking in
            onPickingChanged?(picking)
        }
        .onChange(of: minimumDate) { _, _ in
            draftDate = clamped(draftDate)
            if let date, date < minimumDate {
                self.date = nil
            }
        }
    }

    private func clamped(_ value: Date) -> Date {
        max(value, minimumDate)
    }

    private func beginPicking(with seed: Date?) {
        if let seed {
            draftDate = clamped(seed)
        } else if includesTime {
            draftDate = max(Date(), minimumDate)
        } else {
            draftDate = clamped(minimumDate)
        }
        isPicking = true
        Haptics.selection()
    }

    private var addButton: some View {
        Button {
            beginPicking(with: nil)
        } label: {
            HStack(spacing: 10) {
                TIcon(glyph: .cal, size: 18, stroke: .tAccent2)
                Text(placeholder)
                    .font(.tText(15, weight: .semibold))
                    .foregroundColor(.tAccent2)
                Spacer()
                TIcon(glyph: .plus, size: 14, stroke: .tAccent2, strokeWidth: 2.5)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(fieldBackground)
        }
        .buttonStyle(TripnestPressStyle())
    }

    private func setView(_ value: Date) -> some View {
        HStack(spacing: 10) {
            Button {
                beginPicking(with: value)
            } label: {
                HStack(spacing: 10) {
                    TIcon(glyph: .cal, size: 18, stroke: .tAccent2)
                    Text(formattedValue(value))
                        .font(.tText(15, weight: .semibold))
                        .foregroundColor(.tText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text("Modifier")
                        .font(.tText(12, weight: .semibold))
                        .foregroundColor(.tAccent2)
                }
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            }
            .buttonStyle(TripnestPressStyle())

            Button {
                date = nil
                isPicking = false
                Haptics.selection()
            } label: {
                TIcon(glyph: .close, size: 16, stroke: .tTextMute)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: 0x1e113a))
                    )
            }
            .buttonStyle(TripnestPressStyle())
            .padding(.trailing, 8)
        }
        .background(fieldBackground)
    }

    private func formattedValue(_ value: Date) -> String {
        if includesTime {
            return value.formatted(
                .dateTime.day().month(.wide).year().hour().minute().locale(Self.frLocale)
            )
        }
        return value.formatted(.dateTime.day().month(.wide).year().locale(Self.frLocale))
    }

    private var pickingView: some View {
        VStack(spacing: 14) {
            DatePicker(
                "",
                selection: $draftDate,
                in: minimumDate...,
                displayedComponents: includesTime ? [.date, .hourAndMinute] : .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Self.frLocale)
            .frame(maxWidth: .infinity)
            .frame(height: includesTime ? 220 : 180)
            .clipped()
            .onChange(of: draftDate) { _, newValue in
                if newValue < minimumDate {
                    draftDate = minimumDate
                }
            }

            HStack(spacing: 10) {
                Button {
                    isPicking = false
                    Haptics.selection()
                } label: {
                    Text("Annuler")
                        .font(.tText(14, weight: .semibold))
                        .foregroundColor(.tTextMute)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: 0x1c0f36))
                        )
                }
                .buttonStyle(TripnestPressStyle())

                Button {
                    date = clamped(draftDate)
                    isPicking = false
                    Haptics.success()
                } label: {
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
        .padding(14)
        .background(fieldBackground)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(hex: 0x1b0e34))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tBorderStrong, lineWidth: 1)
            )
    }
}

struct FormDateField: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .font(.tText(16))
                .foregroundColor(.tText)
                .environment(\.locale, Locale(identifier: "fr_FR"))
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: 0x1b0e34))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.tBorderStrong, lineWidth: 1)
                )
        }
    }
}

struct TripCheckboxRow: View {
    let label: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
            Haptics.selection()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isOn ? Color.tAccent2 : Color.clear)
                        .frame(width: 24, height: 24)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isOn ? Color.tAccent2 : Color.tBorderStrong, lineWidth: isOn ? 0 : 1.5)
                        .frame(width: 24, height: 24)
                    if isOn {
                        TIcon(glyph: .check, size: 14, stroke: .white, strokeWidth: 2.5)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.tText(15, weight: .semibold))
                        .foregroundColor(.tText)
                    if let subtitle {
                        Text(subtitle)
                            .font(.tText(12))
                            .foregroundColor(.tTextMute)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gate de saisie du nom de profil (première arrivée dans l'app)

/// Écran bloquant et non-contournable : exige un nom de profil avant
/// de pouvoir utiliser l'app. Disparaît dès que le nom est enregistré.
private struct ProfileNameGate: View {
    @AppStorage("tripnest.profile.name") private var profileName: String = ""
    @AppStorage("tripnest.profile.memberSinceYear") private var memberSinceYear: Int = 0
    @State private var nameInput: String = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Color.tBg0.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 22) {
                    TripnestLogo(size: 84)

                    VStack(spacing: 10) {
                        Text("DERNIÈRE ÉTAPE")
                            .font(.tText(11, weight: .bold)).tracking(2.5)
                            .foregroundColor(.tAccent2)
                        (Text("Comment doit-on\nt'appeler ").font(.tDisplay(30)).tracking(-0.9)
                         + Text("?").font(.tDisplay(30)).tracking(-0.9).foregroundColor(.tAccent2))
                            .multilineTextAlignment(.center)
                        Text("Ton nom s'affichera sur ton accueil et ton profil.")
                            .font(.tText(14)).foregroundColor(.tTextMute)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    FormField(label: "Nom affiché", text: $nameInput, placeholder: "Ex. Lucas Martin")
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit(save)
                }

                Spacer(minLength: 0)

                CTA(label: "C'est parti →", action: save)
                    .opacity(trimmed.isEmpty ? 0.45 : 1)
                    .disabled(trimmed.isEmpty)
            }
            .padding(.horizontal, 28)
            .padding(.top, 40)
            .padding(.bottom, 36)
        }
        .tripnestPreferredColorScheme()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { focused = true }
        }
    }

    private func save() {
        let value = trimmed
        guard !value.isEmpty else { return }
        if memberSinceYear == 0 {
            memberSinceYear = Calendar.current.component(.year, from: Date())
        }
        Haptics.success()
        withAnimation(.easeOut(duration: 0.25)) {
            profileName = value
        }
    }
}
