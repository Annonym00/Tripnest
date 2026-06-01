import CoreLocation
import MapKit
import SwiftUI

struct SpotsScreen: View {
    @EnvironmentObject private var store: TripStore
    @StateObject private var locationTracker = SpotsLocationTracker()
    var onNav: (AppRoute) -> Void = { _ in }
    var onBack: () -> Void = {}
    var showsSubpageBack: Bool = false
    @State private var category = "Tous"
    @State private var editingSpot: Spot? = nil
    @State private var spotToDelete: Spot? = nil
    @State private var searchText = ""
    @State private var showSearch = false
    @FocusState private var searchFocused: Bool

    @State private var globeMarkers: [EarthGlobeTripMarker] = []
    @State private var globeMarkersRevision = 0
    @State private var globeFlyTrigger = 0
    @State private var globeFlyLatitude: Double?
    @State private var globeFlyLongitude: Double?
    @State private var scrollToMapTrigger = 0

    private var tripSpots: [Spot] {
        guard let trip = store.activeTrip else { return [] }
        return store.spots(for: trip.id)
    }

    /// Signature qui change dès qu'un champ pertinent d'un spot évolue
    /// (nom, catégorie, statut, coordonnées) → recalcule les pins de la carte.
    private var spotsSignature: String {
        tripSpots.map {
            "\($0.id):\($0.name):\($0.category):\($0.toRedo ? 1 : 0):\($0.visited ? 1 : 0):\($0.latitude ?? 0):\($0.longitude ?? 0)"
        }.joined(separator: "|")
    }

    private var categories: [String] {
        ["Tous"] + Array(Set(tripSpots.map(\.category))).sorted()
    }

    private var filtered: [Spot] {
        var spots = tripSpots
        if category != "Tous" {
            spots = spots.filter { $0.category == category }
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            spots = spots.filter { spot in
                spot.name.lowercased().contains(query)
                    || spot.category.lowercased().contains(query)
                    || spot.address.lowercased().contains(query)
                    || spot.area.lowercased().contains(query)
            }
        }
        return spots
    }

    private var destinationName: String {
        store.activeTrip?.homeDestinationTitle ?? ""
    }

    private var subtitleLabel: String {
        let n = tripSpots.count
        let plural = n > 1 ? "s" : ""
        let dest = destinationName
        if dest.isEmpty {
            return "\(n) enregistré\(plural)"
        }
        return "\(n) enregistré\(plural) à \(dest)"
    }

    var body: some View {
        ScreenShell(motif: false) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                if showSearch {
                    searchBar
                        .padding(.horizontal, 22)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if store.activeTrip == nil {
                    Spacer()
                    emptySpotsCard(
                        title: "Aucun voyage sélectionné",
                        subtitle: "Choisis un voyage pour enregistrer tes spots."
                    )
                    .padding(.horizontal, 18)
                    Spacer()
                } else if tripSpots.isEmpty {
                    Spacer()
                    emptySpotsCard(action: { onNav(.newSpot) })
                        .padding(.horizontal, 18)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            mapPreviewCard
                                .frame(height: 240)
                                .padding(.horizontal, 18)
                                .id("spotsMapPreview")

                            categoryPills
                                .padding(.bottom, 2)

                            if filtered.isEmpty {
                                VStack(spacing: 6) {
                                    Text("Aucun résultat")
                                        .font(.tText(15, weight: .bold))
                                        .foregroundColor(.tText)
                                    Text("Essaie d'ajuster ta recherche ou ta catégorie.")
                                        .font(.tText(12))
                                        .foregroundColor(.tTextMute)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 32)
                                .padding(.top, 24)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(filtered) { spot in
                                        spotCard(spot)
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }
                        .padding(.top, 6)
                        .tripnestTabBarScrollPadding()
                    }
                    .tripnestScrollBounceWhenNeeded()
                    .onChange(of: scrollToMapTrigger) { _ in
                        withAnimation(TripnestAnimation.soft) {
                            proxy.scrollTo("spotsMapPreview", anchor: .top)
                        }
                    }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                TabBar(active: .trips, onChange: onNav)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .onAppear {
            locationTracker.start()
        }
        .onDisappear {
            locationTracker.stop()
        }
        .task(id: store.activeTrip?.id) {
            await refreshSpotMarkers()
        }
        .task(id: spotsSignature) {
            await refreshSpotMarkers()
        }
        .sheet(item: $editingSpot) { spot in
            AddSpotSheet(editingSpot: spot)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
        }
        .confirmationDialog(
            "Supprimer ce spot ?",
            isPresented: Binding(
                get: { spotToDelete != nil },
                set: { if !$0 { spotToDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: spotToDelete
        ) { spot in
            Button("Supprimer", role: .destructive) {
                Haptics.impact(.medium)
                store.deleteSpot(id: spot.id)
                spotToDelete = nil
            }
            Button("Annuler", role: .cancel) { spotToDelete = nil }
        } message: { spot in
            Text("« \(spot.name) » sera définitivement supprimé.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onBack) {
                IconBtn(glyph: .back)
            }
            .buttonStyle(TripnestPressStyle())
            .accessibilityLabel("Retour")

            VStack(alignment: .leading, spacing: 2) {
                Text("Spots")
                    .font(.tDisplay(32, weight: .heavy))
                    .tracking(-0.6)
                    .foregroundColor(.tText)
                Text(subtitleLabel)
                    .font(.tText(13))
                    .foregroundColor(.tTextMute)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                circleIconButton(systemName: "plus", accent: true) {
                    onNav(.newSpot)
                }
                .disabled(store.activeTrip == nil)
                .opacity(store.activeTrip == nil ? 0.45 : 1)
                .accessibilityLabel("Ajouter un spot")

                circleIconButton(systemName: "magnifyingglass") {
                    withAnimation(TripnestAnimation.soft) {
                        showSearch.toggle()
                    }
                    if showSearch {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            searchFocused = true
                        }
                    } else {
                        searchText = ""
                        searchFocused = false
                    }
                    Haptics.selection()
                }
                .accessibilityLabel(showSearch ? "Fermer la recherche" : "Rechercher")
            }
        }
    }

    private func circleIconButton(
        systemName: String,
        accent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(accent ? .white : .tText)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(accent ? Color.tAccent : Color.tSurface)
                )
                .overlay(
                    Circle().stroke(accent ? Color.clear : Color.tBorder, lineWidth: 1)
                )
        }
        .buttonStyle(TripnestPressStyle())
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.tTextMute)
            TextField("Rechercher un spot", text: $searchText)
                .font(.tText(14))
                .foregroundColor(.tText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($searchFocused)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    Haptics.selection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.tTextDim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.tSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.tBorder, lineWidth: 1)
        )
    }

    // MARK: - Map preview

    private var mapPreviewCard: some View {
        ZStack {
            SpotsFlatMap(
                markers: globeMarkers,
                flyToTrigger: globeFlyTrigger,
                flyToLatitude: globeFlyLatitude,
                flyToLongitude: globeFlyLongitude,
                onSelect: { marker in
                    if let spot = tripSpots.first(where: { $0.id == marker.id }) {
                        editingSpot = spot
                        Haptics.selection()
                    }
                }
            )

            VStack {
                HStack {
                    Spacer()
                    Button {
                        focusUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .overlay(Circle().stroke(Color.tAccent2.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(TripnestPressStyle())
                    .accessibilityLabel("Centrer sur ma position")
                }
                Spacer()
            }
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.tBorder, lineWidth: 1)
        )
    }

    // MARK: - Category pills

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { c in
                    let isActive = category == c
                    let pillColor = c == "Tous" ? Color.tAccent : SpotsFlatMap.categoryColor(c)
                    CategoryColorPill(label: c, color: pillColor, active: isActive) {
                        category = c
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 5)
        }
    }

    // MARK: - Spot card

    private func statusBadge(_ label: String, color: Color, systemImage: String) -> some View {
        HStack(spacing: 1.5) {
            Image(systemName: systemImage)
                .font(.system(size: 5, weight: .bold))
            Text(label)
                .font(.tText(6.5, weight: .bold))
                .lineLimit(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 4).padding(.vertical, 1.5)
        .background(Capsule().fill(color.opacity(0.14)))
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.7))
    }

    private func spotCard(_ spot: Spot) -> some View {
        Button(action: { editingSpot = spot; Haptics.selection() }) {
            TCard(padding: 12) {
                HStack(spacing: 8) {
                    SpotThumbnail(spot: spot)
                        .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(spot.name)
                            .font(.tText(15, weight: .bold))
                            .tracking(-0.2)
                            .foregroundColor(.tText)
                            .lineLimit(1)

                        let infoAddress = spot.address.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !infoAddress.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.tTextMute)
                                Text(infoAddress)
                                    .font(.tText(12))
                                    .foregroundColor(.tTextMute)
                                    .lineLimit(1)
                            }
                        }

                        HStack(spacing: 6) {
                            let sc = starColor(spot.rating)
                            TIcon(glyph: .star, size: 12, stroke: sc, fill: sc)
                            Text("\(spot.rating, specifier: "%.1f")")
                                .font(.tText(11, weight: .bold))
                                .foregroundColor(sc)
                        }

                        if spot.toRedo || spot.visited {
                            HStack(spacing: 6) {
                                if spot.toRedo {
                                    statusBadge("À refaire", color: .tRose, systemImage: "arrow.clockwise")
                                }
                                if spot.visited {
                                    statusBadge("Déjà visité", color: .tMint, systemImage: "checkmark")
                                }
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    let hasMarker = globeMarkers.contains(where: { $0.id == spot.id })
                    Button {
                        guard let marker = globeMarkers.first(where: { $0.id == spot.id }) else { return }
                        globeFlyLatitude = marker.lat
                        globeFlyLongitude = marker.lon
                        globeFlyTrigger += 1
                        scrollToMapTrigger += 1
                        Haptics.selection()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.tAccent2)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.tAccent2.opacity(0.14)))
                            .overlay(Circle().stroke(Color.tAccent2.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .opacity(hasMarker ? 1 : 0.32)
                    .disabled(!hasMarker)
                    .accessibilityLabel("Localiser ce spot sur la carte")

                    Button {
                        store.toggleSpotVisited(id: spot.id)
                        Haptics.impact(.light)
                    } label: {
                        Image(systemName: spot.visited ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(spot.visited ? .tMint : .tTextMute)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(spot.visited ? Color.tMint.opacity(0.14) : Color.tSurface))
                            .overlay(Circle().stroke(spot.visited ? Color.tMint.opacity(0.35) : Color.tBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(spot.visited ? "Marquer comme non visité" : "Marquer comme déjà fait")

                    Button {
                        store.toggleSpotSaved(id: spot.id)
                        Haptics.impact(.light)
                    } label: {
                        Image(systemName: spot.saved ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(spot.saved ? .tRose : .tTextMute)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(spot.saved ? Color.tRose.opacity(0.14) : Color.tSurface))
                            .overlay(Circle().stroke(spot.saved ? Color.tRose.opacity(0.35) : Color.tBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(spot.saved ? "Retirer des spots sauvés" : "Sauver ce spot")
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    Haptics.impact(.light)
                    spotToDelete = spot
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.tTextMute)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.tSurface))
                        .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .offset(x: 7, y: -7)
                .accessibilityLabel("Supprimer ce spot")
            }
        }
        .buttonStyle(TripnestPressStyle())
        .contextMenu {
            Button {
                store.toggleSpotSaved(id: spot.id)
                Haptics.selection()
            } label: {
                Label(spot.saved ? "Retirer des sauvés" : "Sauver", systemImage: spot.saved ? "heart.slash" : "heart")
            }
            Button(role: .destructive) {
                Haptics.impact(.medium)
                store.deleteSpot(id: spot.id)
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty state

    private func emptySpotsCard(
        title: String = "Aucun spot enregistré",
        subtitle: String = "Ajoute tes restaurants, hôtels ou activités pour les retrouver pendant ton voyage.",
        action: (() -> Void)? = nil
    ) -> some View {
        TCard(
            padding: 20,
            bg: AnyShapeStyle(
                LinearGradient(
                    colors: [Color(hex: 0x1a0d32), Color(hex: 0x10071f)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            ),
            border: .tBorderStrong
        ) {
            VStack(spacing: 12) {
                TIcon(glyph: .spot, size: 26, stroke: .tAccent2)
                Text(title)
                    .font(.tText(15, weight: .bold))
                    .foregroundColor(.tText)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.tText(13))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                if let action {
                    CTA(label: "Ajouter un spot", action: action)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func starColor(_ rating: Double) -> Color {
        if rating < 2.5 { return Color(hex: 0xff3b30) }
        if rating < 4   { return .tGold }
        return .tMint
    }

    // MARK: - Map markers

    private struct SpotGeoResult {
        var marker: EarthGlobeTripMarker
        var persistId: String?
        var lat: Double
        var lon: Double
    }

    private func refreshSpotMarkers() async {
        guard let trip = store.activeTrip else {
            await MainActor.run { globeMarkers = []; globeMarkersRevision += 1 }
            return
        }
        let spots = store.spots(for: trip.id).filter { !$0.address.isEmpty || $0.coordinate != nil }

        var markers: [EarthGlobeTripMarker] = []
        var toPersist: [(id: String, lat: Double, lon: Double)] = []

        await withTaskGroup(of: SpotGeoResult?.self) { group in
            for spot in spots {
                group.addTask {
                    let emoji = Self.spotEmoji(for: spot.category)
                    let status = Self.spotStatus(spot)
                    if let coord = spot.coordinate {
                        return SpotGeoResult(
                            marker: EarthGlobeTripMarker(
                                id: spot.id, lat: coord.latitude, lon: coord.longitude,
                                flag: emoji, title: spot.name, subtitle: spot.category, detail: status
                            ),
                            persistId: nil, lat: coord.latitude, lon: coord.longitude
                        )
                    }
                    guard let placemark = try? await CLGeocoder()
                        .geocodeAddressString(spot.address).first,
                          let loc = placemark.location else { return nil }
                    return SpotGeoResult(
                        marker: EarthGlobeTripMarker(
                            id: spot.id, lat: loc.coordinate.latitude, lon: loc.coordinate.longitude,
                            flag: emoji, title: spot.name, subtitle: spot.category, detail: status
                        ),
                        persistId: spot.id, lat: loc.coordinate.latitude, lon: loc.coordinate.longitude
                    )
                }
            }
            for await result in group {
                guard let r = result else { continue }
                markers.append(r.marker)
                if let pid = r.persistId { toPersist.append((pid, r.lat, r.lon)) }
            }
        }

        await MainActor.run {
            for entry in toPersist {
                store.setSpotCoordinate(id: entry.id, latitude: entry.lat, longitude: entry.lon)
            }
            globeMarkers = markers
            globeMarkersRevision += 1
        }
    }

    private func focusUserLocation() {
        locationTracker.start()
        guard let coordinate = locationTracker.coordinate else { return }
        globeFlyLatitude = coordinate.latitude
        globeFlyLongitude = coordinate.longitude
        globeFlyTrigger += 1
        Haptics.selection()
    }

    private static func spotStatus(_ spot: Spot) -> String {
        var parts: [String] = []
        if spot.toRedo { parts.append("redo") }
        if spot.visited { parts.append("visited") }
        return parts.joined(separator: ",")
    }

    private static func spotEmoji(for category: String) -> String {
        switch category {
        case "Restaurant": return "🍽️"
        case "Hôtel":      return "🏨"
        case "Activité":   return "🎯"
        default:           return "📍"
        }
    }
}

/// Vignette d'un spot : photo réelle (1re image) si disponible, sinon dégradé `DestPhoto`.
private struct SpotThumbnail: View {
    let spot: Spot
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                let catColor = SpotCategoryStyle.color(for: spot.category)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [catColor.opacity(0.9), catColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(spot.name.first.map(String.init)?.uppercased() ?? "•")
                            .font(.tDisplay(24, weight: .heavy))
                            .foregroundColor(.white.opacity(0.92))
                    )
            }
        }
        .task(id: spotPhotoKey) { await loadImage() }
    }

    private var spotPhotoKey: String { "\(spot.id)-\(spot.photoCount)" }

    private func loadImage() async {
        guard spot.photoCount > 0 else {
            if image != nil { image = nil }
            return
        }
        let id = spot.id
        let loaded = await Task.detached(priority: .utility) {
            SpotImageStore.load(spotId: id, index: 0)
        }.value
        await MainActor.run { image = loaded }
    }
}

/// Carte 2D MapKit — alternative au globe pour visualiser les spots à plat.
private struct SpotsFlatMap: View {
    let markers: [EarthGlobeTripMarker]
    let flyToTrigger: Int
    let flyToLatitude: Double?
    let flyToLongitude: Double?
    var onSelect: ((EarthGlobeTripMarker) -> Void)? = nil

    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $camera) {
            UserAnnotation()
            ForEach(markers) { marker in
                Annotation(
                    marker.title,
                    coordinate: CLLocationCoordinate2D(latitude: marker.lat, longitude: marker.lon)
                ) {
                    Button {
                        onSelect?(marker)
                    } label: {
                        pin(for: marker)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .all))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear { fitAll() }
        .onChange(of: flyToTrigger) { _, _ in recenter() }
        .onChange(of: markers) { _, _ in
            if camera == .automatic { fitAll() }
        }
    }

    static func categoryColor(_ category: String) -> Color {
        SpotCategoryStyle.color(for: category)
    }

    private func pin(for marker: EarthGlobeTripMarker) -> some View {
        let color = Self.categoryColor(marker.subtitle)
        let toRedo = marker.detail.contains("redo")
        let visited = marker.detail.contains("visited")
        return ZStack {
            // Halo lumineux léger en fonction de l'activité
            SpotPinShape()
                .fill(color)
                .frame(width: 22, height: 28)
                .blur(radius: 6)
                .opacity(0.7)

            // Corps du pin coloré
            SpotPinShape()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 20, height: 26)
                .overlay(
                    SpotPinShape().stroke(Color.white.opacity(0.92), lineWidth: 1.3)
                )
                .shadow(color: color.opacity(0.5), radius: 4, y: 1)

            // Petit point blanc dans la tête du pin
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 6, height: 6)
                .offset(y: -4)
        }
        .frame(width: 22, height: 28)
        // Badge « déjà visité » : flèche validée verte (à gauche du pin)
        .overlay(alignment: .topLeading) {
            if visited {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(Color(hex: 0x15803d))
                }
                .offset(x: -4, y: -3)
            }
        }
        // Badge « à refaire » : cœur rouge (à droite du pin)
        .overlay(alignment: .topTrailing) {
            if toRedo {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 6.5, weight: .bold))
                        .foregroundColor(.red)
                }
                .offset(x: 4, y: -3)
            }
        }
    }

    private func recenter() {
        guard let lat = flyToLatitude, let lon = flyToLongitude else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            camera = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            )
        }
    }

    private func fitAll() {
        guard !markers.isEmpty else { return }
        let lats = markers.map(\.lat)
        let lons = markers.map(\.lon)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.05, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.05, (maxLon - minLon) * 1.5)
        )
        camera = .region(MKCoordinateRegion(center: center, span: span))
    }
}

/// Forme de pin (goutte) : tête circulaire qui se resserre en pointe vers le bas.
private struct SpotPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r = w / 2
        let cx = rect.midX

        // Tête circulaire (demi-cercle supérieur)
        path.addArc(
            center: CGPoint(x: cx, y: r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        // Côté droit qui descend vers la pointe
        path.addQuadCurve(
            to: CGPoint(x: cx, y: h),
            control: CGPoint(x: w, y: r + (h - r) * 0.38)
        )
        // Côté gauche qui remonte vers la tête
        path.addQuadCurve(
            to: CGPoint(x: 0, y: r),
            control: CGPoint(x: 0, y: r + (h - r) * 0.38)
        )
        path.closeSubpath()
        return path
    }
}

/// Pill de catégorie teintée avec sa couleur de base (rose, bleu…), version atténuée.
/// Optionnellement munie d'une croix de suppression.
private struct CategoryColorPill: View {
    let label: String
    let color: Color
    let active: Bool
    var onTap: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 7) {
            Button(action: onTap) {
                Text(label)
                    .font(.tText(13, weight: .semibold))
                    .foregroundColor(active ? .white : color)
            }
            .buttonStyle(.plain)

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(active ? .white.opacity(0.9) : color.opacity(0.85))
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(active ? Color.white.opacity(0.18) : color.opacity(0.16)))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Supprimer la catégorie \(label)")
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, onDelete == nil ? 14 : 7)
        .padding(.vertical, 7)
        .background(Capsule().fill(active ? color.opacity(0.8) : color.opacity(0.14)))
        .overlay(Capsule().stroke(color.opacity(active ? 0.8 : 0.4), lineWidth: 1.2))
        .fixedSize(horizontal: true, vertical: false)
    }
}

@MainActor
private final class SpotsLocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var coordinate: CLLocationCoordinate2D?
    @Published private(set) var revision = 0

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        // Suivi réactif : on rafraîchit dès ~8 m de déplacement.
        manager.distanceFilter = 8
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        self.coordinate = coordinate
        revision += 1
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

/// Couleurs des catégories de spots : intégrées + personnalisées (palette de 10).
enum SpotCategoryStyle {
    /// Palette proposée à l'utilisateur (10 couleurs max).
    static let palette: [UInt32] = [
        0xf472b6, // rose
        0x7dd3fc, // bleu
        0x86efac, // menthe
        0xf5c150, // or
        0xa78bfa, // violet
        0xfb7185, // corail
        0x38bdf8, // cyan
        0x34d399, // émeraude
        0xfb923c, // orange
        0xc084fc, // lilas
    ]

    private static let storageKey = "tripnest.spotCategoryColors"

    static func customColors() -> [String: UInt32] {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let data = raw.data(using: .utf8),
              let map = try? JSONDecoder().decode([String: UInt32].self, from: data)
        else { return [:] }
        return map
    }

    static func setColor(_ hex: UInt32, for category: String) {
        var map = customColors()
        map[category] = hex
        if let data = try? JSONEncoder().encode(map),
           let str = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(str, forKey: storageKey)
        }
    }

    static func color(for category: String) -> Color {
        switch category {
        case "Restaurant": return .tRose
        case "Hôtel":      return .tBlue
        case "Activité":   return .tMint
        default: break
        }
        if let hex = customColors()[category] {
            return Color(hex: hex)
        }
        return .tAccent2
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
    @State private var budget: String
    @State private var toRedo: Bool
    @State private var visited: Bool
    @State private var photos: [UIImage] = []
    @State private var selectedTripId: String

    private let maxDescriptionChars = 150

    @State private var showGalleryPicker = false
    @State private var showCameraPicker = false
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryColor: UInt32 = SpotCategoryStyle.palette[0]
    @State private var categoryToDelete: String? = nil
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
        _budget           = State(initialValue: editingSpot?.budget ?? "")
        _toRedo           = State(initialValue: editingSpot?.toRedo ?? false)
        _visited          = State(initialValue: editingSpot?.visited ?? false)
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
                        photosSection
                        categorySection

                        budgetSection

                        // Note
                        TCard(padding: 4) {
                            VStack(spacing: 0) {
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
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter", action: save)
                        .font(.tText(15, weight: .bold))
                        .foregroundColor(canSave ? .tAccent2 : .tTextMute)
                        .disabled(!canSave)
                }
            }
        }
        .tripnestPreferredColorScheme()
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
        .sheet(isPresented: $showAddCategory) {
            addCategorySheet
        }
        .confirmationDialog(
            "Supprimer cette catégorie ?",
            isPresented: Binding(
                get: { categoryToDelete != nil },
                set: { if !$0 { categoryToDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: categoryToDelete
        ) { name in
            Button("Supprimer", role: .destructive) {
                deleteCustomCategory(name)
                categoryToDelete = nil
            }
            Button("Annuler", role: .cancel) { categoryToDelete = nil }
        } message: { name in
            Text("La catégorie « \(name) » sera supprimée.")
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
                            .fill(Color(hex: 0x1b0e34))
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
                                .fill(Color(hex: 0x1b0e34))
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
                                        Capsule().fill(isSelected ? Color.tAccent : Color(hex: 0x1d1038))
                                    )
                                    .overlay(
                                        Capsule().stroke(isSelected ? Color.clear : Color.tAccent2.opacity(0.55), lineWidth: 1.2)
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
                .background(Capsule().fill(isActive ? Color.tAccent2 : Color(hex: 0x1d1038)))
                .overlay(Capsule().stroke(isActive ? Color.clear : Color.tAccent2.opacity(0.55), lineWidth: 1.2))
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
                    .keyboardDoneBar()
                    .onChange(of: spotDescription) { _, newValue in
                        if newValue.count > maxDescriptionChars {
                            spotDescription = String(newValue.prefix(maxDescriptionChars))
                        }
                    }
            }
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
                        .fill(Color(hex: 0x1b0e34))
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
                    .background(Color(hex: 0x1a0d32))
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

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BUDGET")
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.tGold.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: "eurosign")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.tGold)
                }
                TextField("Ex. 25 € / pers", text: $budget)
                    .font(.tText(15, weight: .semibold))
                    .foregroundColor(.tText)
                    .keyboardType(.default)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.tSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tBorder, lineWidth: 1)
            )
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
                        let pillColor = SpotCategoryStyle.color(for: c)
                        if builtinCategories.contains(c) {
                            CategoryColorPill(label: c, color: pillColor, active: category == c) {
                                category = c
                                Haptics.selection()
                            }
                        } else {
                            CategoryColorPill(label: c, color: pillColor, active: category == c, onTap: {
                                category = c
                                Haptics.selection()
                            }, onDelete: {
                                Haptics.impact(.light)
                                categoryToDelete = c
                            })
                        }
                    }
                    Button {
                        newCategoryName = ""
                        newCategoryColor = SpotCategoryStyle.palette[0]
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
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
                .padding(.trailing, 4)
            }
        }
    }

    // MARK: - Nouvelle catégorie

    private var canAddCategory: Bool {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !allCategories.contains(trimmed)
    }

    private var addCategorySheet: some View {
        NavigationStack {
            ZStack {
                Color.tBg1.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOM")
                            .font(.tText(12, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.tTextMute)
                        TextField("Ex. Bar, Café, Musée…", text: $newCategoryName)
                            .font(.tText(15))
                            .foregroundColor(.tText)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.tSurface))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("COULEUR")
                            .font(.tText(12, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.tTextMute)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 14) {
                            ForEach(SpotCategoryStyle.palette, id: \.self) { hex in
                                let isSelected = newCategoryColor == hex
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 46, height: 46)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .heavy))
                                            .foregroundColor(.white)
                                            .opacity(isSelected ? 1 : 0)
                                    )
                                    .shadow(color: Color(hex: hex).opacity(isSelected ? 0.65 : 0), radius: 8, y: 1)
                                    .scaleEffect(isSelected ? 1.08 : 1)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
                                    .onTapGesture {
                                        newCategoryColor = hex
                                        Haptics.selection()
                                    }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(22)
            }
            .navigationTitle("Nouvelle catégorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        showAddCategory = false
                        newCategoryName = ""
                    }
                    .foregroundColor(.tAccent2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") { addCustomCategory() }
                        .font(.tText(15, weight: .bold))
                        .foregroundColor(canAddCategory ? .tAccent2 : .tTextMute)
                        .disabled(!canAddCategory)
                }
            }
        }
        .presentationDetents([.medium])
        .tripnestPreferredColorScheme()
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
            showAddCategory = false
            return
        }
        var current = customCategories
        current.append(trimmed)
        if let data = try? JSONEncoder().encode(current) {
            customCategoriesJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
        SpotCategoryStyle.setColor(newCategoryColor, for: trimmed)
        category = trimmed
        newCategoryName = ""
        showAddCategory = false
        Haptics.success()
    }

    private func deleteCustomCategory(_ name: String) {
        var current = customCategories
        current.removeAll { $0 == name }
        if let data = try? JSONEncoder().encode(current) {
            customCategoriesJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
        if category == name { category = "Restaurant" }
        Haptics.impact(.medium)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedTripId.isEmpty else { return }

        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)

        if let spot = editingSpot {
            // Supprime les anciennes photos si le nombre a changé
            if spot.photoCount != photos.count {
                SpotImageStore.deleteAll(spotId: spot.id, count: spot.photoCount)
            }
            for (i, photo) in photos.enumerated() {
                SpotImageStore.save(photo, spotId: spot.id, index: i)
            }
            let addressChanged = trimmedAddress != spot.address
            store.updateSpot(
                id: spot.id,
                name: trimmed,
                category: category,
                address: address,
                spotDescription: spotDescription,
                budget: budget,
                toRedo: toRedo,
                photoCount: photos.count,
                rating: rating,
                tripId: selectedTripId,
                visited: visited
            )
            // Re-géocode uniquement si l'adresse a changé.
            if addressChanged && !trimmedAddress.isEmpty {
                geocodeInBackground(spotId: spot.id, address: trimmedAddress)
            }
        } else {
            guard let spotId = store.addSpot(
                name: trimmed,
                category: category,
                address: address,
                spotDescription: spotDescription,
                budget: budget,
                toRedo: toRedo,
                photoCount: photos.count,
                rating: rating,
                tripId: selectedTripId,
                visited: visited
            ) else { return }
            for (i, photo) in photos.enumerated() {
                SpotImageStore.save(photo, spotId: spotId, index: i)
            }
            if !trimmedAddress.isEmpty {
                geocodeInBackground(spotId: spotId, address: trimmedAddress)
            }
        }
        Haptics.success()
        close()
    }

    /// Géocode l'adresse en arrière-plan et met en cache les coordonnées sur le spot.
    private func geocodeInBackground(spotId: String, address: String) {
        Task { @MainActor in
            guard let placemark = try? await CLGeocoder().geocodeAddressString(address).first,
                  let loc = placemark.location else { return }
            store.setSpotCoordinate(id: spotId, latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        }
    }
}

struct AddSpotScreen: View {
    var onBack: () -> Void = {}

    var body: some View {
        AddSpotSheet(onClose: onBack)
            .tripnestPreferredColorScheme()
    }
}
