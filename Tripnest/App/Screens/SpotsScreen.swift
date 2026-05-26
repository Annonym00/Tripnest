import CoreLocation
import SwiftUI

struct SpotsScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onBack: () -> Void = {}
    var showsSubpageBack: Bool = false
    @State private var category = "Tous"
    @State private var editingSpot: Spot? = nil

    @State private var globeMarkers: [EarthGlobeTripMarker] = []
    @State private var globeMarkersRevision = 0
    @State private var globeFlyTrigger = 0
    @State private var globeFlyLatitude: Double?
    @State private var globeFlyLongitude: Double?

    private var tripSpots: [Spot] {
        guard let trip = store.activeTrip else { return [] }
        return store.spots(for: trip.id)
    }

    private var categories: [String] {
        ["Tous"] + Array(Set(tripSpots.map(\.category))).sorted()
    }

    private var filtered: [Spot] {
        let spots = tripSpots
        return category == "Tous" ? spots : spots.filter { $0.category == category }
    }

    private var spotCountLabel: String { "\(tripSpots.count)" }

    var body: some View {
        ScreenShell(motif: false) {
            VStack(spacing: 0) {
                if showsSubpageBack {
                    TripSubpageTopBar(
                        title: "Spots",
                        subtitle: spotCountLabel,
                        onBack: onBack
                    )
                    HStack {
                        Spacer()
                        Button(action: { onNav(.newSpot) }) {
                            HStack(spacing: 6) {
                                TIcon(glyph: .plus, size: 14, stroke: .white, strokeWidth: 2.5)
                                Text("Ajouter").font(.tText(13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).frame(height: 36)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.tAccent))
                        }
                        .buttonStyle(.plain)
                        .disabled(store.activeTrip == nil)
                        .opacity(store.activeTrip == nil ? 0.45 : 1)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 8)
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Spots").font(.tDisplay(24)).tracking(-0.5)
                            Text(spotCountLabel)
                                .font(.tText(13, weight: .bold))
                                .foregroundColor(.tAccent2)
                                .monospacedDigit()
                        }
                        Spacer()
                        Button(action: { onNav(.newSpot) }) {
                            HStack(spacing: 6) {
                                TIcon(glyph: .plus, size: 14, stroke: .white, strokeWidth: 2.5)
                                Text("Ajouter").font(.tText(13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).frame(height: 36)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.tAccent))
                        }
                        .buttonStyle(.plain)
                        .disabled(store.activeTrip == nil)
                        .opacity(store.activeTrip == nil ? 0.45 : 1)
                    }
                    .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 12)
                }

                if store.activeTrip == nil {
                    Spacer()
                    emptySpots(
                        title: "Aucun voyage sélectionné",
                        subtitle: "Crée ou ouvre un voyage pour enregistrer des spots."
                    )
                    .padding(.horizontal, 18)
                    Spacer()
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .bottom) {
                            // Globe — 82%
                            VStack(spacing: 0) {
                                globe
                                    .frame(width: geo.size.width, height: geo.size.height * 0.82)
                                Color.tBg0
                                    .frame(maxHeight: .infinity)
                            }

                            // Panel — commence plus bas (~78%)
                            spotsPanel
                                .frame(width: geo.size.width, height: geo.size.height * 0.22)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if showsSubpageBack {
                    EmptyView().frame(height: 0)
                } else {
                    TabBar(active: .spots, onChange: onNav)
                }
            }
        }
        .swipeBack(enabled: false, onBack: onBack)
        .task(id: store.activeTrip?.id) {
            await refreshGlobeMarker()
        }
        .task(id: tripSpots.reduce(0) { $0 &+ $1.id.hashValue &+ $1.address.hashValue }) {
            await refreshGlobeMarker()
        }
        .sheet(item: $editingSpot) { spot in
            AddSpotSheet(editingSpot: spot)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
        }
    }

    private var globe: some View {
        ZStack {
            Color.tBg0
            EarthGlobeView(
                cameraDistance: 3.12,
                fieldOfView: 47,
                cameraYOffset: 0.1,
                flyToTrigger: globeFlyTrigger,
                flyToLatitude: globeFlyLatitude,
                flyToLongitude: globeFlyLongitude,
                tripMarkers: globeMarkers,
                markersRevision: globeMarkersRevision
            )
        }
    }

    @ViewBuilder
    private var spotsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fondu transparent → noir pour éliminer la coupure nette
            LinearGradient(
                colors: [Color.clear, Color.tBg0],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 72)

            if tripSpots.isEmpty {
                Spacer(minLength: 0)
                emptySpots(action: { onNav(.newSpot) })
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories, id: \.self) { c in
                            TPill(label: c, active: category == c, action: { category = c })
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.top, 8).padding(.bottom, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(filtered) { spot in
                            spotCard(spot)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                    .tripnestTabBarScrollPadding()
                }
                .tripnestScrollBounceWhenNeeded()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.clear, Color.tBg0],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 72)
                Color.tBg0
            }
        )
    }

    private func refreshGlobeMarker() async {
        guard let trip = store.activeTrip else {
            await MainActor.run { globeMarkers = []; globeMarkersRevision += 1 }
            return
        }

        let spots = store.spots(for: trip.id).filter { !$0.address.isEmpty }

        var markers: [EarthGlobeTripMarker] = []
        await withTaskGroup(of: EarthGlobeTripMarker?.self) { group in
            for spot in spots {
                group.addTask {
                    guard let placemark = try? await CLGeocoder()
                        .geocodeAddressString(spot.address).first,
                          let loc = placemark.location else { return nil }
                    return EarthGlobeTripMarker(
                        id: spot.id,
                        lat: loc.coordinate.latitude,
                        lon: loc.coordinate.longitude,
                        flag: Self.spotEmoji(for: spot.category),
                        title: spot.name,
                        subtitle: spot.category,
                        detail: ""
                    )
                }
            }
            for await result in group {
                if let m = result { markers.append(m) }
            }
        }

        // Centre la vue sur le premier spot géocodé
        await MainActor.run {
            globeMarkers = markers
            globeMarkersRevision += 1
            if let first = markers.first {
                globeFlyLatitude = first.lat
                globeFlyLongitude = first.lon
                globeFlyTrigger += 1
            }
        }
    }

    private static func spotEmoji(for category: String) -> String {
        switch category {
        case "Restaurant": return "🍽️"
        case "Hôtel":      return "🏨"
        case "Activité":   return "🎯"
        default:           return "📍"
        }
    }

    private func spotCard(_ spot: Spot) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: { editingSpot = spot; Haptics.selection() }) {
                TCard(padding: 12) {
                    HStack(spacing: 12) {
                        DestPhoto(label: spot.name, hue: spot.hue, radius: 12)
                            .frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(spot.name).font(.tText(15, weight: .bold)).tracking(-0.2)
                                if spot.toRedo {
                                    Text("À refaire")
                                        .font(.tText(10, weight: .bold))
                                        .foregroundColor(Color(hex: 0xff3b30))
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Capsule().fill(Color(hex: 0xff3b30).opacity(0.12)))
                                }
                            }
                            let displayArea = spot.address.isEmpty ? spot.area : spot.address
                            Text("\(spot.category) · \(displayArea)")
                                .font(.tText(12)).foregroundColor(.tTextMute).lineLimit(1)
                            HStack(spacing: 4) {
                                let sc = starColor(spot.rating)
                                TIcon(glyph: .star, size: 12, stroke: sc, fill: sc)
                                Text("\(spot.rating, specifier: "%.1f")")
                                    .font(.tText(11, weight: .bold))
                                    .foregroundColor(sc)
                            }
                            .padding(.top, 3)
                        }
                        Spacer()
                    }
                }
            }
            .buttonStyle(TripnestPressStyle())

            Button {
                if let marker = globeMarkers.first(where: { $0.id == spot.id }) {
                    globeFlyLatitude = marker.lat
                    globeFlyLongitude = marker.lon
                    globeFlyTrigger += 1
                    Haptics.selection()
                }
            } label: {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.tAccent2)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.tAccent2.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)

            Button {
                Haptics.impact(.medium)
                store.deleteSpot(id: spot.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: 0xff3b30))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: 0xff3b30).opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func emptySpots(
        title: String = "Aucun spot enregistré",
        subtitle: String = "Sauvegarde tes restaurants, hôtels et activités.",
        action: (() -> Void)? = nil
    ) -> some View {
        TCard(padding: 14) {
            HStack(spacing: 12) {
                TIcon(glyph: .spot, size: 20, stroke: .tAccent2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.tText(14, weight: .bold))
                        .foregroundColor(.tText)
                    Text(subtitle)
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if let action {
                    Button(action: action) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.tAccent))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func starColor(_ rating: Double) -> Color {
        if rating < 2.5 { return Color(hex: 0xff3b30) }
        if rating < 4   { return .tGold }
        return .tMint
    }

    private func glyph(for category: String) -> TIcon.Glyph {
        switch category {
        case "Restaurant": return .food
        case "Hôtel": return .hotel
        case "Activité": return .ticket
        default: return .spot
        }
    }

    private func color(for category: String) -> Color {
        switch category {
        case "Restaurant": return .tGold
        case "Hôtel": return .tBlue
        case "Activité": return .tMint
        default: return .tAccent2
        }
    }
}

struct AddSpotSheet: View {
    var editingSpot: Spot? = nil
    var onClose: (() -> Void)? = nil

    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss

    private func close() { onClose?() ?? { dismiss() }() }

    @State private var name: String
    @State private var address: String
    @FocusState private var addressFocused: Bool
    @State private var isDetectingLocation = false
    @State private var spotDescription: String
    @State private var category: String
    @State private var rating: Double
    @State private var toRedo: Bool
    @State private var photos: [UIImage] = []
    @State private var selectedTripId: String

    private let maxDescriptionChars = 150

    @State private var showGalleryPicker = false
    @State private var showCameraPicker = false
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var tripFilter: TripFilter = .ongoing

    private enum TripFilter { case ongoing, done }

    @StateObject private var addressCompleter = AddressSearchCompleter()
    @AppStorage("tripnest.spotCustomCategories") private var customCategoriesJSON: String = "[]"

    private let builtinCategories = ["Restaurant", "Hôtel", "Activité", "Autre"]
    private let maxPhotos = 5
    private var isEditing: Bool { editingSpot != nil }

    init(editingSpot: Spot? = nil, onClose: (() -> Void)? = nil) {
        self.editingSpot = editingSpot
        self.onClose = onClose
        _name             = State(initialValue: editingSpot?.name ?? "")
        _address          = State(initialValue: editingSpot?.address ?? "")
        _spotDescription  = State(initialValue: editingSpot?.spotDescription ?? "")
        _category         = State(initialValue: editingSpot?.category ?? "Restaurant")
        _rating           = State(initialValue: editingSpot?.rating ?? 4.5)
        _toRedo           = State(initialValue: editingSpot?.toRedo ?? false)
        _selectedTripId   = State(initialValue: editingSpot?.tripId ?? "")
    }

    private static let _catDecoder = JSONDecoder()
    private var customCategories: [String] {
        (try? Self._catDecoder.decode([String].self, from: Data(customCategoriesJSON.utf8))) ?? []
    }
    private var allCategories: [String] {
        builtinCategories + customCategories.filter { !builtinCategories.contains($0) }
    }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedTripId.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                    .onTapGesture { dismissKeyboard(); addressFocused = false }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        FormField(label: "Nom du lieu", text: $name, placeholder: "Ex. Time Out Market")
                        addressSection
                        descriptionSection
                        tripSection
                        photosSection
                        categorySection

                        // À refaire + Note
                        TCard(padding: 4) {
                            VStack(spacing: 0) {
                                Button {
                                    toRedo.toggle()
                                    Haptics.selection()
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(toRedo ? Color(hex: 0xff3b30) : Color.clear)
                                                .frame(width: 24, height: 24)
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(toRedo ? Color(hex: 0xff3b30) : Color.tBorderStrong, lineWidth: toRedo ? 0 : 1.5)
                                                .frame(width: 24, height: 24)
                                            if toRedo {
                                                TIcon(glyph: .check, size: 13, stroke: .white, strokeWidth: 2.5)
                                            }
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("À refaire")
                                                .font(.tText(15, weight: .semibold))
                                                .foregroundColor(.tText)
                                            Text("Marquer ce spot comme à revisiter")
                                                .font(.tText(12))
                                                .foregroundColor(.tTextMute)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                Divider().background(Color.tBorder).padding(.horizontal, 14)

                                Stepper(value: $rating, in: 1...5, step: 0.5) {
                                    HStack {
                                        Text("Note").font(.tText(14, weight: .semibold))
                                        Spacer()
                                        HStack(spacing: 4) {
                                            let sc = starColor(rating)
                                            TIcon(glyph: .star, size: 12, stroke: sc, fill: sc)
                                            Text("\(rating, specifier: "%.1f")")
                                                .font(.tText(14, weight: .bold)).foregroundColor(sc)
                                        }
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 14)
                            }
                        }

                        CTA(label: isEditing ? "Enregistrer les modifications" : "Enregistrer le spot", action: save)
                            .opacity(canSave ? 1 : 0.45)
                            .disabled(!canSave)

                        Spacer(minLength: 0)
                    }
                    .padding(22).padding(.bottom, 20)
                }
            }
            .navigationTitle(isEditing ? "Modifier le spot" : "Nouveau spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { close() }.foregroundColor(.tAccent2)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedTripId.isEmpty {
                selectedTripId = store.activeTrip?.id ?? store.trips.first?.id ?? ""
            }
            if let spot = editingSpot, spot.photoCount > 0 {
                photos = SpotImageStore.loadAll(spotId: spot.id, count: spot.photoCount)
            }
        }
        .sheet(isPresented: $showGalleryPicker) {
            GalleryPhotoPicker(
                onImage: { image in
                    showGalleryPicker = false
                    if photos.count < maxPhotos { photos.append(image) }
                },
                onCancel: { showGalleryPicker = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraImagePicker(
                onImage: { image in
                    showCameraPicker = false
                    if photos.count < maxPhotos { photos.append(image) }
                },
                onCancel: { showCameraPicker = false }
            )
        }
        .alert("Nouvelle catégorie", isPresented: $showAddCategory) {
            TextField("Nom de la catégorie", text: $newCategoryName)
            Button("Ajouter") { addCustomCategory() }
            Button("Annuler", role: .cancel) { newCategoryName = "" }
        }
    }

    // MARK: - Section voyage

    private var tripSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("VOYAGE LIÉ")
                    .font(.tText(12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.tTextMute)
                Spacer()
                if !store.trips.isEmpty {
                    tripFilterPill("En cours", filter: .ongoing)
                    tripFilterPill("Faits", filter: .done)
                }
            }

            if store.trips.isEmpty {
                Text("Aucun voyage disponible")
                    .font(.tText(14))
                    .foregroundColor(.tTextMute)
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: 0x8b5cf6, opacity: 0.05))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.tBorderStrong, lineWidth: 1))
            } else {
                let visibleTrips = store.trips.filter {
                    tripFilter == .ongoing
                        ? ($0.status == .active || $0.status == .planned)
                        : $0.status == .done
                }

                if visibleTrips.isEmpty {
                    Text(tripFilter == .ongoing ? "Aucun voyage en cours" : "Aucun voyage terminé")
                        .font(.tText(14))
                        .foregroundColor(.tTextMute)
                        .padding(.horizontal, 18)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hex: 0x8b5cf6, opacity: 0.05))
                        )
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.tBorderStrong, lineWidth: 1))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(visibleTrips) { trip in
                                let isSelected = selectedTripId == trip.id
                                Button {
                                    selectedTripId = trip.id
                                    Haptics.selection()
                                } label: {
                                    HStack(spacing: 6) {
                                        if !trip.flag.isEmpty {
                                            Text(trip.flag).font(.system(size: 14))
                                        }
                                        Text(trip.homeDestinationTitle)
                                            .font(.tText(13, weight: isSelected ? .bold : .semibold))
                                            .foregroundColor(isSelected ? .white : .tText)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 38)
                                    .background(
                                        Capsule().fill(isSelected ? Color.tAccent : Color(hex: 0x8b5cf6, opacity: 0.07))
                                    )
                                    .overlay(
                                        Capsule().stroke(isSelected ? Color.clear : Color.tBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tripFilterPill(_ label: String, filter: TripFilter) -> some View {
        let isActive = tripFilter == filter
        Button {
            tripFilter = filter
            Haptics.selection()
        } label: {
            Text(label)
                .font(.tText(12, weight: isActive ? .bold : .semibold))
                .foregroundColor(isActive ? .white : .tTextMute)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(Capsule().fill(isActive ? Color.tAccent2 : Color(hex: 0x8b5cf6, opacity: 0.07)))
                .overlay(Capsule().stroke(isActive ? Color.clear : Color.tBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sections

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DESCRIPTION")
                    .font(.tText(12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.tTextMute)
                Spacer()
                Text("\(spotDescription.count)/\(maxDescriptionChars)")
                    .font(.tText(11))
                    .foregroundColor(spotDescription.count >= maxDescriptionChars ? Color(hex: 0xff3b30) : .tTextMute)
            }

            ZStack(alignment: .topLeading) {
                if spotDescription.isEmpty {
                    Text("Ajoute une note, une impression, une anecdote…")
                        .font(.tText(15))
                        .foregroundColor(.tTextMute.opacity(0.5))
                        .padding(.top, 14)
                        .padding(.leading, 18)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $spotDescription)
                    .font(.tText(15))
                    .foregroundColor(.tText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90, maxHeight: 140)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .onChange(of: spotDescription) { _, newValue in
                        if newValue.count > maxDescriptionChars {
                            spotDescription = String(newValue.prefix(maxDescriptionChars))
                        }
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

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("ADRESSE")
                    .font(.tText(12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.tTextMute)
                Spacer()
                Button {
                    Task { await detectCurrentAddress() }
                } label: {
                    HStack(spacing: 5) {
                        if isDetectingLocation {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.tAccent2)
                                .frame(width: 13, height: 13)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.tAccent2)
                        }
                        Text("Adresse détectée")
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Capsule().fill(Color.tAccent2.opacity(0.10)))
                    .overlay(Capsule().stroke(Color.tAccent2.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isDetectingLocation)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    TextField("Ex. 1 Rue de Rivoli, Paris", text: $address)
                        .font(.tText(16))
                        .foregroundColor(.tText)
                        .autocorrectionDisabled()
                        .focused($addressFocused)
                        .padding(.leading, 18)
                        .padding(.trailing, address.isEmpty ? 18 : 8)

                    if !address.isEmpty {
                        Button {
                            address = ""
                            addressCompleter.clear()
                            addressFocused = true
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
                        .fill(Color(hex: 0x8b5cf6, opacity: 0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            addressFocused ? Color.tAccent2.opacity(0.45) : Color.tBorderStrong,
                            lineWidth: 1
                        )
                )

                if addressFocused && !addressCompleter.suggestions.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(addressCompleter.suggestions) { suggestion in
                            Button {
                                address = suggestion.fullAddress
                                addressCompleter.clear()
                                addressFocused = false
                                Haptics.selection()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.tAccent2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.title)
                                            .font(.tText(14, weight: .medium))
                                            .foregroundColor(.tText)
                                            .lineLimit(1)
                                        if !suggestion.subtitle.isEmpty {
                                            Text(suggestion.subtitle)
                                                .font(.tText(11))
                                                .foregroundColor(.tTextMute)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if suggestion.id != addressCompleter.suggestions.last?.id {
                                Divider().background(Color.tBorder.opacity(0.7))
                            }
                        }
                    }
                    .background(Color(hex: 0x8b5cf6, opacity: 0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .onChange(of: address) { _, newValue in
                addressCompleter.updateQuery(newValue)
            }
            .onChange(of: addressFocused) { _, focused in
                if focused {
                    addressCompleter.updateQuery(address)
                } else {
                    addressCompleter.clear()
                }
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHOTOS")
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(photos.indices, id: \.self) { i in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: photos[i])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Button {
                                photos.remove(at: i)
                                Haptics.impact(.light)
                            } label: {
                                ZStack {
                                    Circle().fill(Color.black.opacity(0.6)).frame(width: 22, height: 22)
                                    TIcon(glyph: .close, size: 10, stroke: .white, strokeWidth: 2.5)
                                }
                            }
                            .buttonStyle(.plain)
                            .offset(x: 6, y: -6)
                        }
                    }

                    if photos.count < maxPhotos {
                        Menu {
                            Button {
                                showGalleryPicker = true
                                Haptics.selection()
                            } label: {
                                Label("Galerie", systemImage: "photo.on.rectangle.angled")
                            }
                            Button {
                                showCameraPicker = true
                                Haptics.selection()
                            } label: {
                                Label("Appareil photo", systemImage: "camera.fill")
                            }
                        } label: {
                            VStack(spacing: 6) {
                                TIcon(glyph: .plus, size: 18, stroke: .tAccent2, strokeWidth: 2.5)
                                Text("Ajouter")
                                    .font(.tText(11, weight: .semibold))
                                    .foregroundColor(.tAccent2)
                            }
                            .frame(width: 90, height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.tAccent2.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                    .foregroundColor(Color.tAccent2.opacity(0.4))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CATÉGORIE")
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allCategories, id: \.self) { c in
                        TPill(label: c, active: category == c, action: { category = c })
                    }
                    Button {
                        newCategoryName = ""
                        showAddCategory = true
                        Haptics.selection()
                    } label: {
                        TIcon(glyph: .plus, size: 13, stroke: .tAccent2, strokeWidth: 2.5)
                            .frame(width: 36, height: 36)
                            .background(Capsule().fill(Color.tAccent2.opacity(0.10)))
                            .overlay(Capsule().stroke(Color.tAccent2.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Actions

    private func starColor(_ rating: Double) -> Color {
        if rating < 2.5 { return Color(hex: 0xff3b30) }
        if rating < 4   { return .tGold }
        return .tMint
    }

    @MainActor
    private func detectCurrentAddress() async {
        isDetectingLocation = true
        defer { isDetectingLocation = false }

        guard let coordinate = await EarthGlobeLocationFetcher.currentCoordinate() else { return }

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
        guard let placemark = placemarks?.first else { return }

        var parts: [String] = []
        if let number = placemark.subThoroughfare { parts.append(number) }
        if let street = placemark.thoroughfare     { parts.append(street) }
        if let city   = placemark.locality         { parts.append(city) }
        if let country = placemark.country         { parts.append(country) }

        let resolved = parts.joined(separator: ", ")
        if !resolved.isEmpty {
            address = resolved
            addressCompleter.clear()
            addressFocused = false
            dismissKeyboard()
            Haptics.success()
        }
    }

    private func addCustomCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !allCategories.contains(trimmed) else {
            newCategoryName = ""
            return
        }
        var current = customCategories
        current.append(trimmed)
        if let data = try? JSONEncoder().encode(current) {
            customCategoriesJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
        category = trimmed
        newCategoryName = ""
        Haptics.success()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedTripId.isEmpty else { return }

        if let spot = editingSpot {
            // Supprime les anciennes photos si le nombre a changé
            if spot.photoCount != photos.count {
                SpotImageStore.deleteAll(spotId: spot.id, count: spot.photoCount)
            }
            for (i, photo) in photos.enumerated() {
                SpotImageStore.save(photo, spotId: spot.id, index: i)
            }
            store.updateSpot(
                id: spot.id,
                name: trimmed,
                category: category,
                address: address,
                spotDescription: spotDescription,
                toRedo: toRedo,
                photoCount: photos.count,
                rating: rating,
                tripId: selectedTripId
            )
        } else {
            let spotId = UUID().uuidString
            for (i, photo) in photos.enumerated() {
                SpotImageStore.save(photo, spotId: spotId, index: i)
            }
            store.addSpot(
                name: trimmed,
                category: category,
                address: address,
                spotDescription: spotDescription,
                toRedo: toRedo,
                photoCount: photos.count,
                rating: rating,
                tripId: selectedTripId
            )
        }
        Haptics.success()
        close()
    }
}

struct AddSpotScreen: View {
    var onBack: () -> Void = {}

    var body: some View {
        AddSpotSheet(onClose: onBack)
            .preferredColorScheme(.dark)
    }
}
