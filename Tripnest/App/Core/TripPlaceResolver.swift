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
        // Region bias only for short-distance modes. For plane/boat the
        // destination is often on the other side of the planet — a 2 500 km
        // window around the origin would silently force the wrong match.
        if let anchor, mode == .car || mode == .train {
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
            // Hard country gate: when the catalog tells us the destination
            // country, drop any MKLocalSearch hit landing in a different
            // country. Otherwise a generic "Aéroport X" in Italy outscores
            // the real airport in Japan because both match "aéroport".
            if parts.count >= 2 {
                let expected = parts[1]
                let actual = normalizeKey(item.placemark.country ?? "")
                let actualCode = normalizeKey(item.placemark.isoCountryCode ?? "")
                if !expected.isEmpty, !actual.isEmpty,
                   !countryMatches(expected: expected, actual: actual, actualCode: actualCode) {
                    score -= 250
                }
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

        if let anchor, mode == .car || mode == .train {
            // Proximity bias only makes sense for short-distance modes. For a
            // flight from Lyon to Atsugi (Japan ~9 700 km) the destination is
            // *expected* to be far from the origin — penalising distance there
            // forced the search onto random nearby look-alikes.
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

    private static let countryAliases: [String: Set<String>] = [
        "japan":         ["japon", "nippon", "jp"],
        "united states": ["usa", "us", "united states of america", "etats unis", "états unis"],
        "united kingdom":["uk", "great britain", "britain", "gb", "england", "angleterre", "royaume uni"],
        "france":        ["fr"],
        "germany":       ["allemagne", "deutschland", "de"],
        "spain":         ["espagne", "espana", "españa", "es"],
        "italy":         ["italie", "italia", "it"],
        "portugal":      ["pt"],
        "netherlands":   ["pays bas", "holland", "nl"],
        "switzerland":   ["suisse", "ch"],
        "belgium":       ["belgique", "be"],
        "china":         ["chine", "cn"],
        "south korea":   ["coree du sud", "corée du sud", "korea", "kr"],
        "morocco":       ["maroc", "ma"],
        "indonesia":     ["indonesie", "indonésie", "id"],
        "thailand":      ["thailande", "thaïlande", "th"],
        "vietnam":       ["viet nam", "vn"],
        "iceland":       ["islande", "is"],
        "ireland":       ["irlande", "ie"],
        "greece":        ["grece", "grèce", "gr"],
        "turkey":        ["turquie", "tr"],
        "mexico":        ["mexique", "mx"],
        "canada":        ["ca"],
        "brazil":        ["bresil", "brésil", "br"],
        "argentina":     ["argentine", "ar"],
        "australia":     ["australie", "au"],
        "new zealand":   ["nouvelle zelande", "nouvelle zélande", "nz"],
        "egypt":         ["egypte", "égypte", "eg"],
    ]

    private static func countryMatches(expected: String, actual: String, actualCode: String) -> Bool {
        if expected == actual { return true }
        if !actualCode.isEmpty, expected == actualCode { return true }
        if let aliases = countryAliases[expected],
           aliases.contains(actual) || aliases.contains(actualCode) {
            return true
        }
        for (canonical, aliases) in countryAliases {
            if (aliases.contains(expected) || canonical == expected),
               canonical == actual || aliases.contains(actual) || aliases.contains(actualCode) {
                return true
            }
        }
        return false
    }

    private static func normalizeKey(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: " ")
    }
}

// MARK: - TripRouteFlagResolver (réintégré depuis HomeScreen lors de la fusion du 2026-06-02)

enum TripRouteFlagResolver {
    private static let aliases: [String: String] = [
        "usa": "US",
        "us": "US",
        "united states": "US",
        "etats unis": "US",
        "etats-unis": "US",
        "royaume uni": "GB",
        "royaume-uni": "GB",
        "uk": "GB",
        "united kingdom": "GB",
        "angleterre": "GB",
        "emirats arabes unis": "AE",
        "emirats-arabes-unis": "AE",
        "united arab emirates": "AE",
        "coree du sud": "KR",
        "corée du sud": "KR",
        "south korea": "KR",
        "pays bas": "NL",
        "pays-bas": "NL",
        "netherlands": "NL"
    ]

    static func flag(
        for place: String,
        mode: TransportMode,
        fallbackCountry: String = "",
        fallbackFlag: String = ""
    ) -> String {
        // Ordre de fiabilité (valable pour tous les pays) :
        // 1. Catalogue de lieux curaté (aéroports/gares/ports) : pays connu de
        //    façon sûre, contrairement au géocodage qui peut confondre un nom
        //    ambigu (« ... Air Base ») avec un autre pays.
        // 2. Pays explicite du voyage.
        // 3. Texte libre de la destination.
        let trimmedFallback = fallbackCountry.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [
            countryFromCatalog(place: place, mode: mode),
            trimmedFallback.isEmpty || trimmedFallback == "À définir" ? nil : trimmedFallback,
            countryFromText(place)
        ]

        for candidate in candidates {
            if let candidate, let flag = flag(forCountryOrCode: candidate) {
                return flag
            }
        }
        return fallbackFlag
    }

    private static func countryFromCatalog(place: String, mode: TransportMode) -> String? {
        let trimmed = place.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }

        var modes: [TransportMode] = mode == .car ? [] : [mode]
        for fallbackMode in [TransportMode.plane, .train, .boat] where !modes.contains(fallbackMode) {
            modes.append(fallbackMode)
        }

        for mode in modes {
            if let match = TransportPlaceCatalog.bestMatch(mode: mode, query: trimmed),
               let country = countryFromSubtitle(match.subtitle) {
                return country
            }
        }
        return nil
    }

    private static func countryFromSubtitle(_ subtitle: String) -> String? {
        let parts = subtitle
            .split(separator: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard parts.count >= 2 else { return nil }

        if let last = parts.last {
            let upper = last.uppercased()
            if upper.count == 2, upper.allSatisfy(\.isLetter) {
                return upper
            }
            if upper.count == 3, upper.allSatisfy(\.isLetter), parts.count >= 3 {
                return parts[parts.count - 2]
            }
            return last
        }
        return nil
    }

    private static func countryFromText(_ text: String) -> String? {
        let separators = CharacterSet(charactersIn: ",;|/()[]{}")
        let pieces = text
            .components(separatedBy: separators)
            .flatMap { $0.components(separatedBy: "·") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for piece in pieces.reversed() {
            if flag(forCountryOrCode: piece) != nil {
                return piece
            }
        }
        return nil
    }

    private static func flag(forCountryOrCode value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let upper = trimmed.uppercased()
        if upper.count == 2, upper.allSatisfy(\.isLetter) {
            return emojiFlag(forRegionCode: upper)
        }

        let normalized = normalizeCountry(trimmed)
        if let aliasCode = aliases[normalized] {
            return emojiFlag(forRegionCode: aliasCode)
        }

        for region in Locale.Region.isoRegions {
            let code = region.identifier
            guard code.count == 2 else { continue }
            let fr = Locale(identifier: "fr_FR").localizedString(forRegionCode: code).map(normalizeCountry)
            let en = Locale(identifier: "en_US").localizedString(forRegionCode: code).map(normalizeCountry)
            let current = Locale.current.localizedString(forRegionCode: code).map(normalizeCountry)
            if [fr, en, current].contains(where: { $0 == normalized }) {
                return emojiFlag(forRegionCode: code)
            }
        }
        return nil
    }

    static func flag(forISOCode code: String) -> String? {
        emojiFlag(forRegionCode: code)
    }

    /// Pays (nom ou code ISO) déduit du catalogue de lieux curaté (aéroports,
    /// gares, ports). Source plus fiable que le géocodage pour les noms ambigus
    /// (ex. « ... Air Base » que le géocodeur confond avec une base US).
    static func country(forPlace place: String, mode: TransportMode) -> String? {
        countryFromCatalog(place: place, mode: mode) ?? countryFromText(place)
    }

    /// Drapeau emoji pour un nom de pays ou un code ISO (accès public).
    static func flag(forCountry value: String) -> String? {
        flag(forCountryOrCode: value)
    }

    private static func emojiFlag(forRegionCode code: String) -> String? {
        let upper = code.uppercased()
        guard upper.count == 2, upper.allSatisfy(\.isLetter) else { return nil }
        let scalars = upper.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }
        guard scalars.count == 2 else { return nil }
        return String(String.UnicodeScalarView(scalars))
    }

    private static func normalizeCountry(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: " ")
            .replacingOccurrences(of: "’", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
