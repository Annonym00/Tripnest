import SwiftUI
import MapKit
import CoreLocation

// MARK: - Public card

private enum TripRouteMapLayout {
    static let mapHeight: CGFloat = 236
}

struct TripRouteMapCard: View {
    let trip: Trip

    @StateObject private var model = TripRouteMapModel()
    @State private var selectedLeg: RouteLegTab = .outbound
    @State private var isRouteAnimating = false
    @State private var routeAnimationStart: Date?
    @State private var animatingTab: RouteLegTab = .outbound
    @State private var outboundProgress: Double = 0
    @State private var returnProgress: Double = 0
    @State private var isRouteMapInteracting = false

    private let routeAnimationDuration: Double = 3.5

    private var hasReturnLeg: Bool { model.route?.returnLeg != nil }

    var body: some View {
        TCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                ZStack {
                    if let route = model.route {
                        preloadedLegMap(route.outbound, tab: .outbound, progress: outboundProgress)
                        if let returnLeg = route.returnLeg {
                            preloadedLegMap(returnLeg, tab: .returnTrip, progress: returnProgress)
                        }
                    } else if model.isLoading {
                        mapPlaceholder(message: "Chargement de la carte…", showsSpinner: true)
                    } else {
                        mapPlaceholder(message: "Carte indisponible", showsSpinner: false)
                    }
                }
                .frame(height: TripRouteMapLayout.mapHeight)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 12)
                .task(id: routeAnimationTaskID) {
                    await runRouteAnimationLoop()
                }

                legTabs
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                tripInfoSection
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 14)
            }
            .padding(.bottom, 14)
        }
        .task(id: trip.routeMapLoadKey) {
            await model.load(trip: trip)
            selectedLeg = .outbound
            stopRouteAnimation()
            outboundProgress = 1
        }
        .onDisappear {
            stopRouteAnimation()
        }
    }

    @ViewBuilder
    private func preloadedLegMap(_ leg: TripRouteLeg, tab: RouteLegTab, progress: Double) -> some View {
        let isSelected = selectedLeg == tab
        let isAnimatingThisLeg = isRouteAnimating && animatingTab == tab
        let visibleProgress = isAnimatingThisLeg ? progress : (isSelected ? 1 : progress)
        TripLegMapView(
            leg: leg,
            progress: visibleProgress,
            showGlowDot: isAnimatingThisLeg && progress > 0,
            drawAnimatedTrail: isSelected || isAnimatingThisLeg,
            showWaypoints: isSelected,
            isInteractionPaused: isRouteMapInteracting,
            onInteractionChange: { isRouteMapInteracting = $0 }
        )
        .opacity(isSelected ? 1 : 0)
        .allowsHitTesting(isSelected)
        .accessibilityHidden(!isSelected)
    }

    private var routeAnimationTaskID: String {
        "\(isRouteAnimating)-\(routeAnimationStart?.timeIntervalSince1970 ?? 0)-\(animatingTab)"
    }

    @MainActor
    private func runRouteAnimationLoop() async {
        guard isRouteAnimating, let startDate = routeAnimationStart else { return }
        // 24 fps garde l'effet fluide tout en laissant MapKit respirer pendant les gestes.
        let frameDuration = 1.0 / 24.0

        while !Task.isCancelled && isRouteAnimating && routeAnimationStart == startDate {
            let elapsed = Date().timeIntervalSince(startDate)
            let linear = min(1, max(0, elapsed / routeAnimationDuration))
            let eased = RouteEasing.smoothstep(linear)
            switch animatingTab {
            case .outbound:
                outboundProgress = eased
            case .returnTrip:
                returnProgress = eased
            }

            if linear >= 1 {
                isRouteAnimating = false
                routeAnimationStart = nil
                switch animatingTab {
                case .outbound: outboundProgress = 1
                case .returnTrip: returnProgress = 1
                }
                break
            }

            try? await Task.sleep(for: .seconds(frameDuration))
        }
    }

    private var header: some View {
        HStack {
            Text("PLAN DU TRAJET")
                .font(.tText(11, weight: .bold))
                .tracking(1.4)
                .foregroundColor(.tTextMute)
            Spacer()
            Text(trip.transportMode.label.uppercased())
                .font(.tText(10, weight: .bold))
                .tracking(1)
                .foregroundColor(.tAccent2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.tAccent2.opacity(0.12)))
        }
    }

    private var tripInfoSection: some View {
        VStack(spacing: 14) {
            Text(selectedLeg == .outbound ? "TRAJET ALLER" : "TRAJET RETOUR")
                .font(.tText(10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(.tTextMute)

            VStack(spacing: 10) {
                ForEach(activeInfoRows, id: \.label) { row in
                    centeredInfoRow(label: row.label, value: row.value)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var activeInfoRows: [(label: String, value: String)] {
        switch selectedLeg {
        case .outbound:
            let dateValue: String = {
                if trip.departureDate != nil || trip.dates != "Dates à définir" {
                    return trip.displayDate
                }
                return "—"
            }()
            if trip.hasReturn {
                let returnPlace = trip.returnLocation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let returnDateValue: String = {
                    guard let returnDate = trip.returnDate else { return "—" }
                    return returnDate.formatted(
                        .dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "fr_FR"))
                    )
                }()
                return [
                    ("Départ", placeLabel(trip.origin, empty: "—")),
                    ("Destination", placeLabel(trip.dest, empty: "—")),
                    ("Date de départ", dateValue),
                    ("Retour vers", placeLabel(returnPlace, empty: "—")),
                    ("Date de retour", returnDateValue),
                ]
            }
            return [
                ("Départ", placeLabel(trip.origin, empty: "—")),
                ("Destination", placeLabel(trip.dest, empty: "—")),
                ("Date de départ", dateValue),
                ("Type", "Aller simple"),
            ]

        case .returnTrip:
            let returnDateValue: String = {
                guard let returnDate = trip.returnDate else { return "—" }
                return returnDate.formatted(
                    .dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "fr_FR"))
                )
            }()
            let returnPlace = trip.returnLocation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return [
                ("Départ", placeLabel(trip.dest, empty: "—")),
                ("Retour vers", placeLabel(returnPlace, empty: "—")),
                ("Date de retour", returnDateValue),
            ]
        }
    }

    private func placeLabel(_ raw: String, empty: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return empty }
        return Trip.routeDetailPlaceName(trimmed)
    }

    private var legTabs: some View {
        HStack(spacing: 8) {
            legTab(title: "Aller", tab: .outbound)
            if hasReturnLeg {
                legTab(title: "Retour", tab: .returnTrip)
            }
        }
    }

    private func legTab(title: String, tab: RouteLegTab) -> some View {
        let isSelected = selectedLeg == tab
        let isDisabled = tab == .returnTrip && !hasReturnLeg
        return Button {
            guard !isDisabled else { return }
            if selectedLeg != tab {
                selectedLeg = tab
                Haptics.selection()
            }
            playLegAnimation(for: tab)
        } label: {
            Text(title)
                .font(.tText(13, weight: .bold))
                .foregroundColor(isSelected ? .white : .tTextMute)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.tAccent : Color(hex: 0x8b5cf6, opacity: 0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color.tBorder, lineWidth: 1)
                )
        }
        .buttonStyle(TripnestPressStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }

    private func centeredInfoRow(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.tText(10, weight: .semibold))
                .foregroundColor(.tTextMute)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.tText(15, weight: .bold))
                .foregroundColor(.tText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .truncationMode(.tail)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func playLegAnimation(for tab: RouteLegTab) {
        guard let route = model.route else { return }
        let leg: TripRouteLeg?
        switch tab {
        case .outbound:
            leg = route.outbound
        case .returnTrip:
            leg = route.returnLeg
        }
        guard leg != nil else { return }

        selectedLeg = tab
        animatingTab = tab
        switch tab {
        case .outbound:
            outboundProgress = 0
        case .returnTrip:
            returnProgress = 0
        }
        routeAnimationStart = Date()
        isRouteAnimating = true
    }

    private func stopRouteAnimation() {
        isRouteAnimating = false
        routeAnimationStart = nil
        isRouteMapInteracting = false
        outboundProgress = 0
        returnProgress = 0
    }

    private func mapPlaceholder(message: String, showsSpinner: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: 0x8b5cf6, opacity: 0.08))
            VStack(spacing: 10) {
                if showsSpinner {
                    ProgressView().tint(.tAccent2)
                }
                Text(message)
                    .font(.tText(13, weight: .semibold))
                    .foregroundColor(.tTextMute)
            }
        }
    }
}

private enum RouteLegTab: Hashable {
    case outbound
    case returnTrip
}

private enum RouteEasing {
    /// Courbe douce début / fin pour un déplacement plus naturel.
    static func smoothstep(_ t: Double) -> Double {
        let x = max(0, min(1, t))
        return x * x * x * (x * (x * 6 - 15) + 10)
    }
}

// MARK: - Leg map

private struct TripLegMapView: View {
    let leg: TripRouteLeg
    let progress: Double
    var showGlowDot: Bool = false
    var drawAnimatedTrail: Bool = true
    var showWaypoints: Bool = true
    var isInteractionPaused: Bool = false
    var onInteractionChange: (Bool) -> Void = { _ in }

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraResetKey = ""
    @State private var isCameraMoving = false
    @State private var cameraMoveEndTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            let aspect = geometry.size.width / max(geometry.size.height, 1)
            let camera = TripRouteCameraFitter.position(
                path: leg.pathSamples,
                endpoints: leg.waypoints.map(\.coordinate),
                spanMeters: leg.spanMeters,
                aspectRatio: aspect
            )
            let resetKey = "\(leg.fromLabel)-\(leg.toLabel)-\(Int(geometry.size.width))x\(Int(geometry.size.height))"
            MapReader { proxy in
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    MapPolyline(coordinates: leg.routeLineCoordinates())
                        .stroke(Color.tAccent2.opacity(0.9), lineWidth: 3.5)

                    if showGlowDot {
                        Annotation("", coordinate: leg.coordinateOnLine(at: progress), anchor: .center) {
                            RouteGlowDotMarker()
                                .allowsHitTesting(false)
                        }
                    }

                    if showWaypoints {
                        ForEach(leg.waypoints) { waypoint in
                            Annotation("", coordinate: waypoint.coordinate, anchor: .center) {
                                RouteWaypointMapAnnotation(waypoint: waypoint)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                // Vue satellite : pas de noms de villes MapKit qui chevauchent le trajet.
                .mapStyle(.imagery(elevation: .flat))
                .mapControlVisibility(.hidden)
                .colorScheme(.dark)
                .overlay {
                    RouteMapSlideOverlay(
                        proxy: proxy,
                        leg: leg,
                        progress: progress,
                        showGlowDot: false,
                        drawAnimatedTrail: drawAnimatedTrail && !isCameraMoving && !isInteractionPaused,
                        showWaypoints: false
                    )
                }
                .overlay(mapTintOverlay)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in beginCameraMove() }
                        .onEnded { _ in finishCameraMove(after: 0.45) }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { _ in beginCameraMove() }
                        .onEnded { _ in finishCameraMove(after: 0.45) }
                )
                .onMapCameraChange(frequency: .onEnd) { _ in
                    finishCameraMove(after: 0.15)
                }
                .onAppear {
                    resetCameraIfNeeded(camera, key: resetKey)
                }
                .onChange(of: resetKey) { _, newKey in
                    resetCameraIfNeeded(camera, key: newKey)
                }
                .onDisappear {
                    cameraMoveEndTask?.cancel()
                }
            }
        }
    }

    private func resetCameraIfNeeded(_ camera: MapCameraPosition, key: String) {
        guard cameraResetKey != key else { return }
        cameraPosition = camera
        cameraResetKey = key
    }

    private func beginCameraMove() {
        if !isCameraMoving {
            isCameraMoving = true
            onInteractionChange(true)
        }
        cameraMoveEndTask?.cancel()
    }

    private func finishCameraMove(after delay: Double) {
        cameraMoveEndTask?.cancel()
        cameraMoveEndTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            await MainActor.run {
                isCameraMoving = false
                onInteractionChange(false)
            }
        }
    }

    private var mapTintOverlay: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.tBg0.opacity(0.22), Color.tBg0.opacity(0.08), Color.tBg0.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
    }
}

/// Ligne animée + point lumineux en overlay (carte MapKit fixe).
private struct RouteMapSlideOverlay: View {
    let proxy: MapProxy
    let leg: TripRouteLeg
    let progress: Double
    let showGlowDot: Bool
    var drawAnimatedTrail: Bool = true
    var showWaypoints: Bool = true
    var cameraRevision: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let trailPoints = drawAnimatedTrail ? screenTrail(in: geometry.size) : []
            let dotPoint = showGlowDot ? screenPoint(for: leg.coordinateOnLine(at: progress), in: geometry.size) : nil

            ZStack {
                if drawAnimatedTrail, trailPoints.count >= 2 {
                    Canvas { context, _ in
                        var path = Path()
                        path.move(to: trailPoints[0])
                        for point in trailPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                        let stroke = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)

                        context.stroke(
                            path,
                            with: .color(Color.tAccent2.opacity(0.3)),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                        context.stroke(
                            path,
                            with: .color(Color.tAccent2.opacity(0.88)),
                            style: stroke
                        )
                    }
                    .allowsHitTesting(false)
                }

                if showGlowDot, let dotPoint {
                    RouteGlowDotMarker()
                        .position(dotPoint)
                }

                if showWaypoints {
                    placedWaypointLabels(in: geometry.size)

                    ForEach(leg.waypoints) { waypoint in
                        if let markerPoint = screenPoint(for: waypoint.coordinate, in: geometry.size) {
                            RouteWaypointMarker(role: waypoint.role)
                                .position(markerPoint)
                                .zIndex(6)
                        }
                    }
                }
            }
        }
        .clipped()
        .allowsHitTesting(false)
    }

    private func screenTrail(in size: CGSize) -> [CGPoint] {
        let visibleProgress = drawAnimatedTrail ? max(progress, 0.001) : progress
        guard visibleProgress > 0 else { return [] }
        let coords = leg.overlayTrailCoordinates(for: visibleProgress)
        return coords.compactMap { screenPoint(for: $0, in: size) }
    }

    private func accentColor(for role: TripRouteWaypoint.Role) -> Color {
        switch role {
        case .origin: return .tMint
        case .destination: return .tAccent2
        case .return: return .tGold
        }
    }

    private func screenPoint(for coordinate: CLLocationCoordinate2D, in size: CGSize) -> CGPoint? {
        guard let point = proxy.convert(coordinate, to: .local) else { return nil }
        guard point.x.isFinite, point.y.isFinite else { return nil }
        let margin: CGFloat = 24
        guard point.x >= -margin, point.y >= -margin,
              point.x <= size.width + margin, point.y <= size.height + margin else {
            return nil
        }
        return point
    }

    @ViewBuilder
    private func placedWaypointLabels(in size: CGSize) -> some View {
        let pair = resolvedLabelPair(in: size)
        if let origin = pair.origin {
            labelView(
                name: origin.name,
                accent: origin.accent,
                marker: origin.marker,
                placement: origin.placement,
                in: size
            )
            .zIndex(5)
        }
        if let destination = pair.destination {
            labelView(
                name: destination.name,
                accent: destination.accent,
                marker: destination.marker,
                placement: destination.placement,
                in: size
            )
            .zIndex(5)
        }
    }

    private struct ResolvedMapLabel {
        let name: String
        let accent: Color
        let marker: CGPoint
        let placement: LabelPlacement
    }

    private struct ResolvedLabelPair {
        var origin: ResolvedMapLabel?
        var destination: ResolvedMapLabel?
    }

    /// Extrémités du trajet affiché (aller : origin→destination ; retour : destination→return).
    private func legLabelEndpoints() -> (start: TripRouteWaypoint, end: TripRouteWaypoint)? {
        guard leg.waypoints.count >= 2 else { return nil }
        return (leg.waypoints[0], leg.waypoints[leg.waypoints.count - 1])
    }

    private func resolvedLabelPair(in size: CGSize) -> ResolvedLabelPair {
        guard let endpoints = legLabelEndpoints(),
              let startPoint = screenPoint(for: endpoints.start.coordinate, in: size),
              let endPoint = screenPoint(for: endpoints.end.coordinate, in: size) else {
            var pair = ResolvedLabelPair()
            if let endpoints = legLabelEndpoints(),
               let startPoint = screenPoint(for: endpoints.start.coordinate, in: size) {
                pair.origin = ResolvedMapLabel(
                    name: Trip.mapPlaceLabel(endpoints.start.name),
                    accent: accentColor(for: endpoints.start.role),
                    marker: startPoint,
                    placement: labelPlacement(marker: startPoint, isLegStart: true, in: size)
                )
            }
            if let endpoints = legLabelEndpoints(),
               let endPoint = screenPoint(for: endpoints.end.coordinate, in: size) {
                pair.destination = ResolvedMapLabel(
                    name: Trip.mapPlaceLabel(endpoints.end.name),
                    accent: accentColor(for: endpoints.end.role),
                    marker: endPoint,
                    placement: labelPlacement(marker: endPoint, isLegStart: false, in: size)
                )
            }
            return pair
        }

        var startPlacement = labelPlacement(marker: startPoint, isLegStart: true, in: size)
        var endPlacement = labelPlacement(marker: endPoint, isLegStart: false, in: size)
        (startPlacement, endPlacement) = separatedPlacements(
            originMarker: startPoint,
            destinationMarker: endPoint,
            originPlacement: startPlacement,
            destinationPlacement: endPlacement,
            in: size
        )
        return ResolvedLabelPair(
            origin: ResolvedMapLabel(
                name: Trip.mapPlaceLabel(endpoints.start.name),
                accent: accentColor(for: endpoints.start.role),
                marker: startPoint,
                placement: startPlacement
            ),
            destination: ResolvedMapLabel(
                name: Trip.mapPlaceLabel(endpoints.end.name),
                accent: accentColor(for: endpoints.end.role),
                marker: endPoint,
                placement: endPlacement
            )
        )
    }

    private func labelView(
        name: String,
        accent: Color,
        marker: CGPoint,
        placement: LabelPlacement,
        in size: CGSize
    ) -> some View {
        RoutePlaceGlowLabel(name: name, accent: accent, alignment: placement.alignment)
            .frame(maxWidth: min(size.width * 0.44, 148), alignment: placement.frameAlignment)
            .position(marker)
            .offset(x: placement.offset.width, y: placement.offset.height)
    }

    private struct LabelPlacement {
        var offset: CGSize
        let alignment: HorizontalAlignment
        let frameAlignment: Alignment
        var estimatedCenter: CGPoint = .zero
    }

    private func labelPlacement(
        marker: CGPoint,
        isLegStart: Bool,
        in size: CGSize
    ) -> LabelPlacement {
        let logoBottom: CGFloat = 46
        let logoLeading: CGFloat = 72
        let margin: CGFloat = 10
        let estLabelW: CGFloat = min(size.width * 0.44, 148)
        let estLabelH: CGFloat = 30
        let halfW = estLabelW / 2

        var offset = labelOffsetFromMarker(marker: marker, isLegStart: isLegStart, in: size)
        var alignment: HorizontalAlignment = .center
        var frameAlignment: Alignment = .center

        if offset.width > 6 {
            alignment = .leading
            frameAlignment = .leading
        } else if offset.width < -6 {
            alignment = .trailing
            frameAlignment = .trailing
        }

        var center = CGPoint(x: marker.x + offset.width, y: marker.y + offset.height)
        center.x = min(max(center.x, margin + halfW), size.width - margin - halfW)
        center.y = min(max(center.y, margin + estLabelH / 2), size.height - logoBottom - estLabelH / 2)

        if center.x - halfW < logoLeading && center.y > size.height - logoBottom - estLabelH {
            center.y = size.height - logoBottom - estLabelH - 6
            center.x = max(center.x, logoLeading + halfW + 6)
            alignment = .leading
            frameAlignment = .leading
        }

        offset = CGSize(width: center.x - marker.x, height: center.y - marker.y)
        return LabelPlacement(
            offset: offset,
            alignment: alignment,
            frameAlignment: frameAlignment,
            estimatedCenter: center
        )
    }

    /// Décale le libellé près du marqueur (même logique aller / retour, sans lien à l’autre point).
    private func labelOffsetFromMarker(
        marker: CGPoint,
        isLegStart: Bool,
        in size: CGSize
    ) -> CGSize {
        let lateral: CGFloat = 34
        let radial: CGFloat = 26

        if marker.y < size.height * 0.34 {
            let side: CGFloat = isLegStart ? -lateral * 0.55 : lateral * 0.55
            return CGSize(width: side, height: radial)
        }
        if marker.y > size.height * 0.66 {
            let side: CGFloat = isLegStart ? -lateral * 0.55 : lateral * 0.55
            return CGSize(width: side, height: -radial)
        }
        if marker.x > size.width * 0.56 {
            return CGSize(width: -lateral, height: -radial * 0.9)
        }
        if marker.x < size.width * 0.44 {
            return CGSize(width: lateral, height: -radial * 0.9)
        }

        let side: CGFloat = isLegStart ? -lateral : lateral
        return CGSize(width: side, height: -radial * 0.85)
    }

    private func separatedPlacements(
        originMarker: CGPoint,
        destinationMarker: CGPoint,
        originPlacement: LabelPlacement,
        destinationPlacement: LabelPlacement,
        in size: CGSize
    ) -> (LabelPlacement, LabelPlacement) {
        var origin = originPlacement
        var destination = destinationPlacement
        let minDistance: CGFloat = 56
        let gap = hypot(
            origin.estimatedCenter.x - destination.estimatedCenter.x,
            origin.estimatedCenter.y - destination.estimatedCenter.y
        )
        guard gap < minDistance else { return (origin, destination) }

        var dx = originMarker.x - destinationMarker.x
        var dy = originMarker.y - destinationMarker.y
        let len = max(hypot(dx, dy), 1)
        dx /= len
        dy /= len
        let px = -dy * 14
        let py = dx * 14

        origin.offset = CGSize(
            width: origin.offset.width + px,
            height: origin.offset.height + py
        )
        destination.offset = CGSize(
            width: destination.offset.width - px,
            height: destination.offset.height - py
        )
        origin.estimatedCenter = CGPoint(
            x: originMarker.x + origin.offset.width,
            y: originMarker.y + origin.offset.height
        )
        destination.estimatedCenter = CGPoint(
            x: destinationMarker.x + destination.offset.width,
            y: destinationMarker.y + destination.offset.height
        )
        return (origin, destination)
    }
}

// MARK: - Labels & markers

private struct RoutePlaceGlowLabel: View {
    let name: String
    let accent: Color
    var alignment: HorizontalAlignment = .center

    var body: some View {
        Text(name)
            .font(.tText(10, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(alignment == .leading ? .leading : (alignment == .trailing ? .trailing : .center))
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.28))
            )
            .shadow(color: accent.opacity(0.75), radius: 7)
            .shadow(color: accent.opacity(0.35), radius: 14)
            .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)
    }
}

private struct RouteWaypointMapAnnotation: View {
    let waypoint: TripRouteWaypoint

    private var accent: Color {
        switch waypoint.role {
        case .origin: return .tMint
        case .destination: return .tAccent2
        case .return: return .tGold
        }
    }

    var body: some View {
        ZStack {
            RouteWaypointMarker(role: waypoint.role)
            RoutePlaceGlowLabel(
                name: Trip.mapPlaceLabel(waypoint.name),
                accent: accent
            )
            .offset(y: 28)
        }
        .frame(width: 132, height: 72)
    }
}

private struct RouteWaypointMarker: View {
    let role: TripRouteWaypoint.Role

    private var color: Color {
        switch role {
        case .origin: return .tMint
        case .destination: return .tAccent2
        case .return: return .tGold
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.tBg0.opacity(0.82))
                .frame(width: 26, height: 26)

            Circle()
                .fill(color.opacity(0.72))
                .frame(width: 23, height: 23)

            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)

            Circle()
                .fill(color)
                .frame(width: 9, height: 9)

            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 13, height: 13)
        }
        .shadow(color: color.opacity(0.85), radius: 8)
    }
}

private struct RouteGlowDotMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.tAccent2.opacity(0.25))
                .frame(width: 26, height: 26)
                .blur(radius: 2)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tAccent2.opacity(0.9),
                            Color.tAccent2.opacity(0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 13
                    )
                )
                .frame(width: 24, height: 24)

            Circle()
                .fill(Color.white)
                .frame(width: 7, height: 7)
                .shadow(color: Color.tAccent2.opacity(0.95), radius: 6)

            Circle()
                .fill(Color.tAccent2)
                .frame(width: 5, height: 5)
        }
    }
}

// MARK: - Data model

struct TripRouteWaypoint: Identifiable {
    enum Role {
        case origin, destination, `return`
    }

    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let role: Role
}

struct TripRouteLeg {
    let waypoints: [TripRouteWaypoint]
    /// Ligne du départ à l'arrivée (extrémités = coordonnées des points du trajet).
    let pathSamples: [CLLocationCoordinate2D]
    let fromLabel: String
    let toLabel: String
    let spanMeters: Double
    var isLongHaul: Bool { spanMeters >= 1_200_000 }

    init(
        waypoints: [TripRouteWaypoint],
        pathSamples: [CLLocationCoordinate2D],
        fromLabel: String,
        toLabel: String
    ) {
        self.waypoints = waypoints
        self.pathSamples = pathSamples
        self.spanMeters = Self.routeSpanMeters(for: pathSamples + waypoints.map(\.coordinate))
        self.fromLabel = fromLabel
        self.toLabel = toLabel
    }

    func coordinateOnLine(at progress: Double) -> CLLocationCoordinate2D {
        guard pathSamples.count >= 2 else { return pathSamples.first ?? CLLocationCoordinate2D() }
        let p = max(0, min(1, progress)) * Double(pathSamples.count - 1)
        let index = Int(p)
        let fraction = p - Double(index)
        guard index < pathSamples.count - 1 else { return pathSamples.last ?? pathSamples[0] }
        let a = pathSamples[index]
        let b = pathSamples[index + 1]
        return CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * fraction,
            longitude: a.longitude + (b.longitude - a.longitude) * fraction
        )
    }

    func routeLineCoordinates(endpointInset: Double = 0.025) -> [CLLocationCoordinate2D] {
        guard pathSamples.count >= 4 else { return pathSamples }
        let startInset = max(0, min(0.12, endpointInset))
        let endInset = 1 - startInset
        let lastIndex = Double(pathSamples.count - 1)
        let startIndex = Int(ceil(startInset * lastIndex))
        let endIndex = Int(floor(endInset * lastIndex))
        guard startIndex < endIndex else { return pathSamples }

        var coordinates = [coordinateOnLine(at: startInset)]
        if startIndex <= endIndex {
            coordinates.append(contentsOf: pathSamples[startIndex...endIndex])
        }
        coordinates.append(coordinateOnLine(at: endInset))
        return coordinates
    }

    func trailCoordinates(for progress: Double) -> [CLLocationCoordinate2D] {
        guard progress > 0, pathSamples.count >= 2 else { return [] }
        let scaled = max(0, min(1, progress)) * Double(pathSamples.count - 1)
        let index = Int(scaled)
        var trail = Array(pathSamples.prefix(index + 1))
        let tip = coordinateOnLine(at: progress)
        if let last = trail.last,
           abs(last.latitude - tip.latitude) > 0.000001 || abs(last.longitude - tip.longitude) > 0.000001 {
            trail.append(tip)
        } else if trail.isEmpty {
            trail = [tip]
        }
        return trail.count >= 2 ? trail : []
    }

    func overlayTrailCoordinates(for progress: Double) -> [CLLocationCoordinate2D] {
        let trail = trailCoordinates(for: progress)
        guard trail.count > 28 else { return trail }
        let step = max(1, trail.count / 24)
        var sampled: [CLLocationCoordinate2D] = []
        for (index, coordinate) in trail.enumerated() where index % step == 0 {
            sampled.append(coordinate)
        }
        if let last = trail.last, sampled.last?.latitude != last.latitude || sampled.last?.longitude != last.longitude {
            sampled.append(last)
        }
        return sampled.count >= 2 ? sampled : trail
    }

    private static func routeSpanMeters(for coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count >= 2 else { return 0 }
        var minLat = coordinates[0].latitude
        var maxLat = minLat
        var minLon = coordinates[0].longitude
        var maxLon = minLon
        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        let center = CLLocation(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let sw = CLLocation(latitude: minLat, longitude: minLon)
        let ne = CLLocation(latitude: maxLat, longitude: maxLon)
        return max(center.distance(from: sw), center.distance(from: ne))
    }
}

// MARK: - Cadrage auto (proche = zoom, lointain = dézoom)

private enum TripRouteCameraFitter {
    static func position(
        path: [CLLocationCoordinate2D],
        endpoints: [CLLocationCoordinate2D],
        spanMeters: Double,
        aspectRatio: CGFloat
    ) -> MapCameraPosition {
        var coords = path
        coords.append(contentsOf: endpoints)
        guard let first = coords.first else { return .automatic }
        if coords.count == 1 {
            return .region(MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            ))
        }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        for coordinate in coords.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        var latDelta = max(maxLat - minLat, 0.0008)
        var lonDelta = max(maxLon - minLon, 0.0008)

        // Lieux proches : zoom minimum.
        latDelta = max(latDelta, 0.07)
        lonDelta = max(lonDelta, 0.07)

        let padding = paddingMultiplier(spanMeters: spanMeters)
        latDelta *= padding
        lonDelta *= padding

        // Adapter au rectangle visible de la carte (évite points hors cadre).
        let viewAspect = max(aspectRatio, 0.9)
        if lonDelta / latDelta < viewAspect {
            lonDelta = latDelta * viewAspect
        } else {
            latDelta = lonDelta / viewAspect
        }

        // Marge pour arc, pastilles et libellés.
        latDelta *= 1.42
        lonDelta *= 1.42

        return .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: min(latDelta, 160),
                longitudeDelta: min(lonDelta, 320)
            )
        ))
    }

    private static func paddingMultiplier(spanMeters: Double) -> Double {
        switch spanMeters {
        case ..<6_000: return 1.65
        case ..<30_000: return 1.75
        case ..<150_000: return 1.85
        case ..<700_000: return 1.95
        case ..<2_000_000: return 2.1
        default: return 2.35
        }
    }
}

struct TripRouteData {
    let outbound: TripRouteLeg
    let returnLeg: TripRouteLeg?
}

@MainActor
final class TripRouteMapModel: ObservableObject {
    @Published var route: TripRouteData?
    @Published var isLoading = false

    func load(trip: Trip) async {
        isLoading = true
        defer { isLoading = false }

        guard let origin = await TripPlaceResolver.coordinate(
            for: trip.origin,
            mode: trip.transportMode
        ),
        let destination = await TripPlaceResolver.coordinate(
            for: trip.dest,
            mode: trip.transportMode,
            near: origin
        ) else {
            route = nil
            return
        }

        let outboundSamples = TripRouteGeometry.greatCirclePath(from: origin, to: destination)
        let outbound = TripRouteLeg(
            waypoints: [
                TripRouteWaypoint(id: "o", name: trip.origin, coordinate: origin, role: .origin),
                TripRouteWaypoint(id: "d", name: trip.dest, coordinate: destination, role: .destination),
            ],
            pathSamples: outboundSamples,
            fromLabel: Trip.compactPlaceName(trip.origin),
            toLabel: Trip.compactPlaceName(trip.dest)
        )

        var returnLeg: TripRouteLeg?
        if trip.hasReturn,
           let retName = trip.returnLocation?.trimmingCharacters(in: .whitespacesAndNewlines),
           !retName.isEmpty,
           let retCoord = await TripPlaceResolver.coordinate(
               for: retName,
               mode: trip.transportMode,
               near: destination
           ) {
            let returnSamples = TripRouteGeometry.greatCirclePath(from: destination, to: retCoord)
            returnLeg = TripRouteLeg(
                waypoints: [
                    TripRouteWaypoint(id: "d2", name: trip.dest, coordinate: destination, role: .destination),
                    TripRouteWaypoint(id: "r", name: retName, coordinate: retCoord, role: .return),
                ],
                pathSamples: returnSamples,
                fromLabel: Trip.compactPlaceName(trip.dest),
                toLabel: Trip.compactPlaceName(retName)
            )
        }

        route = TripRouteData(outbound: outbound, returnLeg: returnLeg)
    }

}
