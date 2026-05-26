import MapKit
import SwiftUI

/// Icône de transport dans un cadre fixe (même centrage pour avion, bateau, etc.).
struct TransportModeGlyph: View {
    let mode: TransportMode
    var size: CGFloat = 22
    var stroke: Color = .white
    var strokeWidth: CGFloat = 1.75

    var body: some View {
        glyph
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private var glyph: some View {
        switch mode {
        case .plane:
            Image(systemName: "airplane")
                .font(.system(size: size * 0.82, weight: .semibold))
                .foregroundStyle(stroke)
                .offset(y: 1)
        case .boat:
            Image(systemName: "ferry.fill")
                .font(.system(size: size * 0.82, weight: .semibold))
                .foregroundStyle(stroke)
                .offset(y: 1.5)
        case .train:
            Image(systemName: "tram.fill")
                .font(.system(size: size * 0.82, weight: .semibold))
                .foregroundStyle(stroke)
                .offset(y: 1.5)
        case .car:
            Image(systemName: "car.fill")
                .font(.system(size: size * 0.82, weight: .semibold))
                .foregroundStyle(stroke)
                .offset(y: 1.5)
        }
    }
}

enum TransportMode: String, Codable, CaseIterable, Identifiable {
    case plane, boat, train, car

    var id: String { rawValue }

    var label: String {
        switch self {
        case .plane: return "Avion"
        case .boat: return "Bateau"
        case .train: return "Train"
        case .car: return "Voiture"
        }
    }

    var subtitle: String {
        switch self {
        case .plane: return "Aéroports du monde entier"
        case .boat: return "Ports du monde entier"
        case .train: return "Gares du monde entier"
        case .car: return "Adresses du monde entier"
        }
    }

    var usesCatalogSuggestions: Bool { self != .car }
    var usesAddressAutocomplete: Bool { self == .car }
    var supportsTravelTicket: Bool { self != .car }

    var ticketNoun: String {
        switch self {
        case .plane: return "billet d'avion"
        case .boat: return "billet de ferry"
        case .train: return "billet de train"
        case .car: return ""
        }
    }

    /// Titre section / éditeur : « Ton billet d'avion », etc.
    var ticketSectionHeading: String {
        switch self {
        case .plane: return "Ton billet d'avion"
        case .boat: return "Ton billet de ferry"
        case .train: return "Ton billet de train"
        case .car: return ""
        }
    }

    var ticketCodeLabel: String {
        switch self {
        case .plane: return "Numéro de vol"
        case .boat: return "Numéro de traversée"
        case .train: return "Numéro de train"
        case .car: return ""
        }
    }

    var ticketCompanyLabel: String {
        switch self {
        case .plane: return "Compagnie aérienne"
        case .boat: return "Compagnie maritime"
        case .train: return "Compagnie ferroviaire"
        case .car: return ""
        }
    }

    var ticketHomeHeading: String {
        switch self {
        case .plane: return "PROCHAIN VOL"
        case .boat: return "PROCHAIN FERRY"
        case .train: return "PROCHAIN TRAJET"
        case .car: return ""
        }
    }

    var ticketScreenTitle: String {
        switch self {
        case .plane: return "Mes vols"
        case .boat: return "Mes ferries"
        case .train: return "Mes trains"
        case .car: return ""
        }
    }

    /// Titre écran détail billet (depuis l’accueil).
    var ticketDetailScreenTitle: String {
        switch self {
        case .plane: return "Mon billet d'avion"
        case .boat: return "Mon billet de ferry"
        case .train: return "Mon billet de train"
        case .car: return ""
        }
    }

    var originPlaceholder: String {
        switch self {
        case .plane: return "Ex. Lyon-Saint Exupéry"
        case .boat: return "Ex. Port de Shanghai"
        case .train: return "Ex. Tokyo Station"
        case .car: return "Ex. Paris"
        }
    }

    var destinationPlaceholder: String {
        switch self {
        case .plane: return "Ex. New York JFK"
        case .boat: return "Ex. Port de Singapour"
        case .train: return "Ex. London St Pancras"
        case .car: return "Ex. Lisbonne"
        }
    }
}

struct TransportPlace: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let subtitle: String
    let mode: TransportMode
    let keywords: [String]
}

private struct TransportPlacesFile: Codable {
    let places: [TransportPlace]
}

private struct IndexedTransportPlace {
    let place: TransportPlace
    let normalizedName: String
    let normalizedSubtitle: String
    let normalizedKeywords: [String]
    let bucketKeys: Set<Character>
}

// MARK: - Alias pays / langue (ex. « japon » → Japan)

enum TransportPlaceLocale {
    private static let countryAliases: [String: [String]] = [
        "japon": ["japan", "jp"],
        "chine": ["china", "cn"],
        "allemagne": ["germany", "de"],
        "espagne": ["spain", "es"],
        "italie": ["italy", "it"],
        "etats unis": ["united states", "usa", "us"],
        "etats-unis": ["united states", "usa", "us"],
        "royaume uni": ["united kingdom", "uk", "gb"],
        "angleterre": ["united kingdom", "uk"],
        "bresil": ["brazil", "br"],
        "mexique": ["mexico", "mx"],
        "inde": ["india", "in"],
        "australie": ["australia", "au"],
        "coree du sud": ["south korea", "kr"],
        "corée du sud": ["south korea", "kr"],
        "thailande": ["thailand", "th"],
        "thaïlande": ["thailand", "th"],
        "vietnam": ["viet nam", "vn"],
        "maroc": ["morocco", "ma"],
        "egypte": ["egypt", "eg"],
        "turquie": ["turkey", "tr"],
        "grece": ["greece", "gr"],
        "grèce": ["greece", "gr"],
        "pays bas": ["netherlands", "nl"],
        "belgique": ["belgium", "be"],
        "suisse": ["switzerland", "ch"],
        "autriche": ["austria", "at"],
        "pologne": ["poland", "pl"],
        "russie": ["russia", "ru"],
        "argentine": ["argentina", "ar"],
        "singapour": ["singapore", "sg"],
        "emirats arabes unis": ["united arab emirates", "ae"],
        "arabie saoudite": ["saudi arabia", "sa"],
    ]

    static func expandedQueries(for rawQuery: String) -> [String] {
        let base = TransportPlaceCatalog.normalize(rawQuery)
        guard !base.isEmpty else { return [] }
        var terms = Set([base])
        if let aliases = countryAliases[base] {
            for alias in aliases { terms.insert(TransportPlaceCatalog.normalize(alias)) }
        }
        for (localized, aliases) in countryAliases {
            if aliases.contains(where: { base.contains($0) || $0.contains(base) }) {
                terms.insert(TransportPlaceCatalog.normalize(localized))
            }
        }
        return Array(terms)
    }

    static func mapSearchQuery(mode: TransportMode, query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let terms = expandedQueries(for: trimmed)
        let english = terms.first { $0 == "japan" || $0 == "china" || $0.contains("united") } ?? terms.last
        switch mode {
        case .plane:
            if let english, english != TransportPlaceCatalog.normalize(trimmed) {
                return "\(english.capitalized) airport"
            }
            if !trimmed.lowercased().contains("airport"), !trimmed.lowercased().contains("aéroport") {
                return "\(trimmed) airport"
            }
        case .boat:
            if let english {
                return "Port \(english.capitalized)"
            }
            if !trimmed.lowercased().contains("port") {
                return "Port de \(trimmed)"
            }
        case .train:
            if let english {
                return "\(english.capitalized) station"
            }
            if !trimmed.lowercased().contains("gare"), !trimmed.lowercased().contains("station") {
                return "\(trimmed) station"
            }
        case .car:
            break
        }
        return nil
    }
}

enum TransportPlaceCatalog {
    private static let indexedByMode: [TransportMode: [IndexedTransportPlace]] = loadIndexed()
    private static let bucketsByMode: [TransportMode: [Character: [IndexedTransportPlace]]] = buildBuckets(from: indexedByMode)
    private static let searchLimit = 8

    static func search(mode: TransportMode, query: String, limit: Int = searchLimit) -> [TransportPlace] {
        guard mode != .car else { return [] }
        let terms = TransportPlaceLocale.expandedQueries(for: query)
        guard !terms.isEmpty else { return [] }
        guard let pool = indexedByMode[mode], !pool.isEmpty else { return [] }

        let candidates = candidatePool(mode: mode, queries: terms, fullPool: pool)
        var matches: [(TransportPlace, Int)] = []
        matches.reserveCapacity(searchLimit * 2)

        let scanCap = 2_500
        let scan = candidates.count > scanCap ? Array(candidates.prefix(scanCap)) : candidates
        for item in scan {
            if let best = terms.compactMap({ score(item: item, query: $0) }).max() {
                matches.append((item.place, best))
            }
        }

        var seen = Set<String>()
        return matches
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.name.localizedCaseInsensitiveCompare(rhs.0.name) == .orderedAscending
            }
            .filter { seen.insert($0.0.id).inserted }
            .prefix(limit)
            .map(\.0)
    }

    /// Meilleure entrée du catalogue pour un libellé saisi (aéroport, port, gare).
    static func bestMatch(mode: TransportMode, query: String) -> TransportPlace? {
        guard mode != .car else { return nil }
        let q = normalize(query)
        guard q.count >= 2 else { return nil }
        guard let pool = indexedByMode[mode] else { return nil }

        if let exact = pool.first(where: { $0.normalizedName == q }) {
            return exact.place
        }

        let results = search(mode: mode, query: query, limit: 5)
        guard let first = results.first,
              let item = pool.first(where: { $0.place.id == first.id }),
              let best = TransportPlaceLocale.expandedQueries(for: query)
                  .compactMap({ score(item: item, query: $0) })
                  .max(),
              best >= 55 else { return nil }
        return first
    }

    /// Requêtes MapKit dérivées d'une suggestion catalogue (ville, pays, code IATA).
    static func mapSearchQueries(for place: TransportPlace) -> [String] {
        var queries: [String] = []
        func add(_ value: String) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !queries.contains(trimmed) else { return }
            queries.append(trimmed)
        }

        add(place.name)
        let parts = place.subtitle
            .split(separator: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if parts.count >= 2 {
            add("\(parts[0]), \(parts[1])")
        }
        if parts.count >= 3, parts[2].count == 3, place.mode == .plane {
            add("\(parts[2]) Airport")
        }
        return queries
    }

    private static func candidatePool(
        mode: TransportMode,
        queries: [String],
        fullPool: [IndexedTransportPlace]
    ) -> [IndexedTransportPlace] {
        guard let buckets = bucketsByMode[mode] else { return fullPool }
        var seen = Set<String>()
        var result: [IndexedTransportPlace] = []
        var bucketKeys = Set<Character>()
        for query in queries {
            for key in query.prefix(4) { bucketKeys.insert(key) }
        }
        for key in bucketKeys {
            guard let bucket = buckets[key] else { continue }
            for item in bucket where seen.insert(item.place.id).inserted {
                result.append(item)
            }
        }
        if !result.isEmpty { return result }
        return fullPool.count > 12_000 ? Array(fullPool.prefix(12_000)) : fullPool
    }

    private static func buildBuckets(
        from indexed: [TransportMode: [IndexedTransportPlace]]
    ) -> [TransportMode: [Character: [IndexedTransportPlace]]] {
        var buckets: [TransportMode: [Character: [IndexedTransportPlace]]] = [:]
        for (mode, items) in indexed {
            var modeBuckets: [Character: [IndexedTransportPlace]] = [:]
            for item in items {
                for key in item.bucketKeys {
                    modeBuckets[key, default: []].append(item)
                }
            }
            buckets[mode] = modeBuckets
        }
        return buckets
    }

    private static func loadIndexed() -> [TransportMode: [IndexedTransportPlace]] {
        guard
            let url = Bundle.main.url(forResource: "TransportPlaces", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(TransportPlacesFile.self, from: data)
        else { return [:] }

        var grouped: [TransportMode: [IndexedTransportPlace]] = [:]
        grouped.reserveCapacity(3)

        for place in file.places where place.mode != .car {
            let normalizedName = normalize(place.name)
            let normalizedKeywords = place.keywords.map(normalize)
            var keys = Set<Character>()
            if let first = normalizedName.first { keys.insert(first) }
            for keyword in normalizedKeywords {
                if let first = keyword.first { keys.insert(first) }
            }
            let indexed = IndexedTransportPlace(
                place: place,
                normalizedName: normalizedName,
                normalizedSubtitle: normalize(place.subtitle),
                normalizedKeywords: normalizedKeywords,
                bucketKeys: keys
            )
            grouped[place.mode, default: []].append(indexed)
        }
        return grouped
    }

    private static func score(item: IndexedTransportPlace, query: String) -> Int? {
        if item.normalizedName.hasPrefix(query) { return 100 }
        if item.normalizedKeywords.contains(where: { $0.hasPrefix(query) }) { return 92 }
        if item.normalizedName.contains(query) { return 75 }
        if item.normalizedKeywords.contains(where: { $0.contains(query) }) { return 65 }
        if item.normalizedSubtitle.contains(query) { return 55 }
        if subsequenceMatch(text: item.normalizedName, query: query) { return 40 }
        return nil
    }

    private static func subsequenceMatch(text: String, query: String) -> Bool {
        guard query.count >= 2 else { return false }
        var remainder = query[...]
        for char in text {
            if char == remainder.first {
                remainder.removeFirst()
                if remainder.isEmpty { return true }
            }
        }
        return false
    }

    static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: " ")
    }
}

// MARK: - Complétion MapKit (monde entier, complète le catalogue)

@MainActor
final class TransportPlaceLiveSearch: NSObject, ObservableObject {
    @Published private(set) var suggestions: [TransportPlace] = []

    private let completer = MKLocalSearchCompleter()
    private var mode: TransportMode = .plane

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest, .query]
    }

    private var debounceTask: Task<Void, Never>?

    func update(mode: TransportMode, query: String) {
        self.mode = mode
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        debounceTask?.cancel()
        guard mode != .car, trimmed.count >= 2 else {
            suggestions = []
            completer.queryFragment = ""
            return
        }
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            completer.queryFragment = liveQueryFragment(mode: self.mode, query: trimmed)
        }
    }

    func clear() {
        suggestions = []
        completer.queryFragment = ""
    }

    private func liveQueryFragment(mode: TransportMode, query: String) -> String {
        if let mapped = TransportPlaceLocale.mapSearchQuery(mode: mode, query: query) {
            return mapped
        }
        return query
    }

    private func place(from completion: MKLocalSearchCompletion) -> TransportPlace {
        let title = completion.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let subtitle = completion.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = "live-\(mode.rawValue)-\(title.hashValue)-\(subtitle.hashValue)"
        return TransportPlace(
            id: id,
            name: title,
            subtitle: subtitle.isEmpty ? mode.label : subtitle,
            mode: mode,
            keywords: []
        )
    }
}

extension TransportPlaceLiveSearch: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            suggestions = results.prefix(6).map { place(from: $0) }
        }
    }

    nonisolated func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        Task { @MainActor in suggestions = [] }
    }
}

struct TransportModePickerView: View {
    var onSelect: (TransportMode) -> Void
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) { IconBtn(glyph: .close) }
                    .buttonStyle(TripnestPressStyle())
                Spacer()
                Text("Mode de transport")
                    .font(.tText(16, weight: .bold))
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Comment voyages-tu ?")
                        .font(.tDisplay(24))
                        .tracking(-0.5)
                    Text("On adaptera les suggestions de lieux selon ton choix.")
                        .font(.tText(14))
                        .foregroundColor(.tTextMute)

                    VStack(spacing: 10) {
                        ForEach(TransportMode.allCases) { mode in
                            Button {
                                Haptics.selection()
                                onSelect(mode)
                            } label: {
                                TransportModeRow(mode: mode)
                            }
                            .buttonStyle(TripnestPressStyle())
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, TripnestLayout.formScrollBreathing)
            }
        }
    }
}

private struct TransportModeRow: View {
    let mode: TransportMode

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.tAccent2.opacity(0.12))
                    .frame(width: 48, height: 48)
                transportIcon
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(mode.label)
                    .font(.tText(16, weight: .bold))
                    .foregroundColor(.tText)
                Text(mode.subtitle)
                    .font(.tText(12))
                    .foregroundColor(.tTextMute)
            }
            Spacer()
            TIcon(glyph: .arrow, size: 16, stroke: .tTextMute)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.tSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.tBorder, lineWidth: 1)
        )
    }

    private var transportIcon: some View {
        TransportModeGlyph(mode: mode, size: 22, stroke: .tAccent2)
    }
}

// MARK: - Validation des lieux (formulaire)

enum LocationFieldValidation: Equatable {
    case unknown
    case validating
    case valid
    case invalid
}

// MARK: - Adresses voiture (autocomplétion mondiale)

struct AddressSuggestion: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String

    var fullAddress: String {
        let parts = [title, subtitle]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }
}

@MainActor
final class AddressSearchCompleter: NSObject, ObservableObject {
    @Published private(set) var suggestions: [AddressSuggestion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        // Monde entier : on retire toute région restreinte
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
        )
    }

    func updateQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            suggestions = []
            completer.queryFragment = ""
            return
        }
        completer.queryFragment = trimmed
    }

    func clear() {
        suggestions = []
        completer.queryFragment = ""
    }
}

extension AddressSearchCompleter: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let mapped = completer.results.prefix(6).map { completion in
            AddressSuggestion(
                id: "\(completion.title)|\(completion.subtitle)",
                title: completion.title,
                subtitle: completion.subtitle
            )
        }
        Task { @MainActor in
            suggestions = Array(mapped)
        }
    }

    nonisolated func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            suggestions = []
        }
    }
}

struct FormLocationField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    @Binding var validation: LocationFieldValidation
    var transportMode: TransportMode
    var showsClearButton: Bool = true

    @FocusState private var focused: Bool
    @StateObject private var addressSearch = AddressSearchCompleter()
    @StateObject private var livePlaceSearch = TransportPlaceLiveSearch()
    @State private var validateTask: Task<Void, Never>?
    @State private var suggestTask: Task<Void, Never>?
    @State private var catalogResults: [TransportPlace] = []
    @State private var pickedFromCatalog = false

    private var mergedPlaceSuggestions: [TransportPlace] {
        guard focused else { return [] }
        var seen = Set<String>()
        var merged: [TransportPlace] = []
        for place in catalogResults + livePlaceSearch.suggestions {
            guard seen.insert(place.id).inserted else { continue }
            merged.append(place)
            if merged.count >= 8 { break }
        }
        return merged
    }

    private var addressSuggestions: [AddressSuggestion] {
        guard transportMode.usesAddressAutocomplete, focused else { return [] }
        return addressSearch.suggestions
    }

    private var showPlaceSuggestions: Bool { !mergedPlaceSuggestions.isEmpty }
    private var showAddressSuggestions: Bool { !addressSuggestions.isEmpty }
    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var showsInvalidHint: Bool {
        validation == .invalid && !focused && hasText
    }

    private var fieldStrokeColor: Color {
        if validation == .invalid, hasText {
            return Color.tRose.opacity(0.55)
        }
        if focused {
            return Color.tAccent2.opacity(0.35)
        }
        return Color.tBorderStrong
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)

            HStack(spacing: 0) {
                TextField(placeholder, text: $text)
                    .font(.tText(16))
                    .foregroundColor(.tText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(transportMode == .car)
                    .focused($focused)
                    .padding(.leading, 18)
                    .padding(.trailing, showsClearButton && hasText ? 8 : 18)

                if showsClearButton, hasText {
                    Button {
                        text = ""
                        validation = .unknown
                        addressSearch.clear()
                        livePlaceSearch.clear()
                        cancelValidation()
                        focused = true
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
                    .stroke(fieldStrokeColor, lineWidth: 1)
            )

            if showsInvalidHint {
                Text(invalidLocationMessage)
                    .font(.tText(11, weight: .medium))
                    .foregroundColor(.tRose)
            }

            if showPlaceSuggestions {
                suggestionList(mergedPlaceSuggestions)
            } else if showAddressSuggestions {
                addressSuggestionList
            }
        }
        .onChange(of: text) { _, newValue in
            if pickedFromCatalog {
                pickedFromCatalog = false
                return
            }
            if transportMode.usesAddressAutocomplete {
                addressSearch.updateQuery(newValue)
            }
            scheduleSuggestions(for: newValue)
            if !focused {
                scheduleValidation()
            }
        }
        .onChange(of: focused) { _, isFocused in
            if isFocused, transportMode.usesAddressAutocomplete {
                addressSearch.updateQuery(text)
            } else {
                addressSearch.clear()
            }
            if isFocused {
                scheduleSuggestions(for: text)
            } else {
                suggestTask?.cancel()
                catalogResults = []
                livePlaceSearch.clear()
                scheduleValidation()
            }
        }
        .onChange(of: transportMode) { _, newMode in
            suggestTask?.cancel()
            catalogResults = []
            livePlaceSearch.clear()
            if focused, newMode.usesCatalogSuggestions {
                scheduleSuggestions(for: text)
            }
            if !focused {
                scheduleValidation()
            }
        }
        .onDisappear {
            cancelValidation()
            suggestTask?.cancel()
            catalogResults = []
            livePlaceSearch.clear()
        }
    }

    private var invalidLocationMessage: String {
        switch transportMode {
        case .car:
            return "Adresse non reconnue. Choisis une suggestion ou une adresse complète."
        default:
            return "Lieu non reconnu. Choisis une suggestion dans la liste."
        }
    }

    private func markValid() {
        cancelValidation()
        validation = .valid
    }

    private func scheduleSuggestions(for raw: String) {
        suggestTask?.cancel()
        guard transportMode.usesCatalogSuggestions, focused else {
            catalogResults = []
            livePlaceSearch.clear()
            return
        }
        let mode = transportMode
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            catalogResults = []
            livePlaceSearch.clear()
            return
        }

        suggestTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled, focused else { return }

            let catalog = await Task.detached(priority: .userInitiated) {
                TransportPlaceCatalog.search(mode: mode, query: trimmed, limit: 8)
            }.value
            guard !Task.isCancelled, focused else { return }
            catalogResults = catalog

            if catalog.count < 3 {
                livePlaceSearch.update(mode: mode, query: trimmed)
            } else {
                livePlaceSearch.clear()
            }
        }
    }

    private func scheduleValidation() {
        cancelValidation()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validation = .unknown
            return
        }
        if validation == .valid, TransportPlaceCatalog.bestMatch(mode: transportMode, query: trimmed) != nil {
            return
        }

        validateTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            if let match = TransportPlaceCatalog.bestMatch(mode: transportMode, query: trimmed) {
                await MainActor.run {
                    guard text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed else { return }
                    validation = .valid
                }
                return
            }
            await MainActor.run { validation = .validating }
            let isValid = await TripPlaceResolver.isValidPlace(trimmed, mode: transportMode)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                let stillSame = text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed
                guard stillSame else { return }
                validation = isValid ? .valid : .invalid
            }
        }
    }

    private func cancelValidation() {
        validateTask?.cancel()
        validateTask = nil
    }

    private func applyCatalogSuggestion(_ place: TransportPlace) {
        pickedFromCatalog = true
        suggestTask?.cancel()
        cancelValidation()
        text = place.name
        validation = .valid
        catalogResults = []
        livePlaceSearch.clear()
        focused = false
        Haptics.selection()
    }

    private func suggestionList(_ places: [TransportPlace]) -> some View {
        VStack(spacing: 0) {
            ForEach(places) { place in
                Button {
                    applyCatalogSuggestion(place)
                } label: {
                    suggestionRow(title: place.name, subtitle: place.subtitle)
                }
                .buttonStyle(.plain)

                if place.id != places.last?.id {
                    Divider().background(Color.tBorder.opacity(0.7))
                }
            }
        }
        .background(Color(hex: 0x8b5cf6, opacity: 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var addressSuggestionList: some View {
        VStack(spacing: 0) {
            ForEach(addressSuggestions) { suggestion in
                Button {
                    text = suggestion.fullAddress
                    markValid()
                    addressSearch.clear()
                    focused = false
                    Haptics.selection()
                } label: {
                    suggestionRow(title: suggestion.title, subtitle: suggestion.subtitle)
                }
                .buttonStyle(.plain)

                if suggestion.id != addressSuggestions.last?.id {
                    Divider().background(Color.tBorder.opacity(0.7))
                }
            }
        }
        .background(Color(hex: 0x8b5cf6, opacity: 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func suggestionRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.tText(14, weight: .medium))
                .foregroundColor(.tText)
                .lineLimit(2)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.tText(11))
                    .foregroundColor(.tTextMute)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }
}
