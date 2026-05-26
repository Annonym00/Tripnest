import CoreLocation
import MapKit

/// Géocodage et validation des lieux (formulaire + carte).
enum TripPlaceResolver {
    private actor CoordinateCache {
        private var storage: [String: CLLocationCoordinate2D] = [:]

        func value(for key: String) -> CLLocationCoordinate2D? {
            storage[key]
        }

        func store(_ coordinate: CLLocationCoordinate2D, for key: String) {
            storage[key] = coordinate
        }
    }

    private static let cache = CoordinateCache()
    private static let minimumResolveScore = 45

    static func isValidPlace(_ query: String, mode: TransportMode) async -> Bool {
        await coordinate(for: query, mode: mode) != nil
    }

    /// Centre approximatif du pays (vue planète « pays »).
    static func countryCoordinate(for country: String) async -> CLLocationCoordinate2D? {
        let trimmed = country.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let key = normalizeKey(trimmed)
        if key == "a definir" { return nil }

        let cacheKey = "country|\(key)"
        if let cached = await cache.value(for: cacheKey) { return cached }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first(where: { $0.placemark.country != nil }) ?? response.mapItems.first else {
                return nil
            }
            let coordinate = item.placemark.coordinate
            guard isValidCoordinate(coordinate) else { return nil }
            await cache.store(coordinate, for: cacheKey)
            return coordinate
        } catch {
            return nil
        }
    }

    static func coordinate(
        for query: String,
        mode: TransportMode,
        near anchor: CLLocationCoordinate2D? = nil
    ) async -> CLLocationCoordinate2D? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let cacheKey = "\(mode.rawValue)|\(normalizeKey(trimmed))"
        if let cached = await cache.value(for: cacheKey) { return cached }

        let catalogMatch = TransportPlaceCatalog.bestMatch(mode: mode, query: trimmed)
        let candidates = searchCandidates(query: trimmed, mode: mode, catalogMatch: catalogMatch)

        var bestCoordinate: CLLocationCoordinate2D?
        var bestScore = Int.min

        for candidate in candidates {
            let items = await localSearchItems(query: candidate, mode: mode, near: anchor)
            for item in items {
                let score = scoreMapItem(
                    item,
                    query: trimmed,
                    mode: mode,
                    catalogMatch: catalogMatch,
                    anchor: anchor
                )
                let coordinate = item.placemark.coordinate
                guard isValidCoordinate(coordinate), score > bestScore else { continue }
                bestScore = score
                bestCoordinate = coordinate
            }
            if bestScore >= 90 { break }
        }

        guard bestScore >= minimumResolveScore, let bestCoordinate else { return nil }
        await cache.store(bestCoordinate, for: cacheKey)
        return bestCoordinate
    }

    private static func searchCandidates(
        query: String,
        mode: TransportMode,
        catalogMatch: TransportPlace?
    ) -> [String] {
        var candidates: [String] = []
        func add(_ value: String) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !candidates.contains(trimmed) else { return }
            candidates.append(trimmed)
        }

        if let catalogMatch {
            for item in TransportPlaceCatalog.mapSearchQueries(for: catalogMatch) {
                add(item)
            }
        }

        add(query)
        let compact = Trip.compactPlaceName(query)
        if compact != query { add(compact) }

        if let mapped = TransportPlaceLocale.mapSearchQuery(mode: mode, query: query) {
            add(mapped)
        }

        switch mode {
        case .plane:
            let lower = query.lowercased()
            if !lower.contains("airport"), !lower.contains("aéroport"), !lower.contains("aeroport") {
                add("\(query) Airport")
            }
        case .boat:
            if !query.lowercased().contains("port") {
                add("Port de \(compact)")
            }
        case .train:
            let lower = query.lowercased()
            if !lower.contains("gare"), !lower.contains("station") {
                add("\(compact) Station")
            }
        case .car:
            break
        }

        return candidates
    }

    private static func localSearchItems(
        query: String,
        mode: TransportMode,
        near anchor: CLLocationCoordinate2D?
    ) async -> [MKMapItem] {
        if let items = await runLocalSearch(query: query, mode: mode, near: anchor, airportsOnly: mode == .plane),
           !items.isEmpty {
            return items
        }
        return await runLocalSearch(query: query, mode: mode, near: anchor, airportsOnly: false) ?? []
    }

    private static func runLocalSearch(
        query: String,
        mode: TransportMode,
        near anchor: CLLocationCoordinate2D?,
        airportsOnly: Bool
    ) async -> [MKMapItem]? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let anchor {
            request.region = MKCoordinateRegion(
                center: anchor,
                latitudinalMeters: 2_500_000,
                longitudinalMeters: 2_500_000
            )
        }
        if airportsOnly {
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.airport])
        }
        if mode == .car {
            request.resultTypes = [.address, .pointOfInterest]
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.isEmpty ? nil : response.mapItems
        } catch {
            return nil
        }
    }

    private static func scoreMapItem(
        _ item: MKMapItem,
        query: String,
        mode: TransportMode,
        catalogMatch: TransportPlace?,
        anchor: CLLocationCoordinate2D?
    ) -> Int {
        let q = normalizeKey(query)
        let name = normalizeKey(item.name ?? "")
        let title = normalizeKey(item.placemark.title ?? "")
        var score = 0

        if let catalogMatch {
            let catalogName = normalizeKey(catalogMatch.name)
            if name == catalogName || title.contains(catalogName) { score += 130 }
            let parts = catalogMatch.subtitle
                .split(separator: "·")
                .map { normalizeKey(String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
            if let city = parts.first, !city.isEmpty, name.contains(city) || title.contains(city) {
                score += 45
            }
            if parts.count >= 3, parts[2].count == 3, name.contains(parts[2]) || title.contains(parts[2]) {
                score += 40
            }
        }

        if name.contains(q) || title.contains(q) { score += 50 }
        if name.hasPrefix(q) { score += 25 }

        switch mode {
        case .plane:
            if item.pointOfInterestCategory == .airport { score += 55 }
            if name.contains("airport") || name.contains("aeroport") || name.contains("aéroport") { score += 35 }
        case .boat:
            if name.contains("port") || title.contains("port") { score += 35 }
        case .train:
            if name.contains("gare") || name.contains("station") { score += 35 }
        case .car:
            if item.placemark.locality != nil || item.placemark.country != nil { score += 30 }
            if item.placemark.thoroughfare != nil { score += 20 }
        }

        if let anchor {
            let result = CLLocation(
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude
            )
            let ref = CLLocation(latitude: anchor.latitude, longitude: anchor.longitude)
            let distance = result.distance(from: ref)
            if distance > 12_000_000 { score -= 100 }
            else if distance > 20_000 { score += 8 }
        }

        return score
    }

    private static func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard coordinate.latitude.isFinite, coordinate.longitude.isFinite else { return false }
        guard abs(coordinate.latitude) <= 90, abs(coordinate.longitude) <= 180 else { return false }
        guard abs(coordinate.latitude) > 0.0001 || abs(coordinate.longitude) > 0.0001 else { return false }
        return true
    }

    private static func normalizeKey(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: " ")
    }
}
