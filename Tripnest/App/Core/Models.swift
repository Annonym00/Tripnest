import SwiftUI
import UIKit

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}

struct Trip: Identifiable, Hashable, Codable {
    enum Status: String, Codable { case active, planned, done }

    let id: String
    var origin: String
    var dest: String
    var country: String
    var flag: String
    var dates: String
    var departureDate: Date?
    var returnLocation: String?
    var returnDate: Date?
    var transportMode: TransportMode
    var days: Int
    var hue: Double
    var status: Status
    var budget: Int
    var spent: Int
    var emergencyFund: Int
    var emergencyFundEnabled: Bool
    var cover: String
    var tripTitle: String
    var coverKind: TripCoverKind
    var rating: Double
    var photoCount: Int

    var isOneWay: Bool { !hasReturn }

    var hasReturn: Bool {
        let loc = returnLocation?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (loc?.isEmpty == false) || returnDate != nil
    }

    /// Clé pour recharger la carte quand le trajet ou le retour change.
    var routeMapLoadKey: String {
        let ret = returnLocation ?? ""
        let retTime = returnDate?.timeIntervalSince1970 ?? -1
        let depTime = departureDate?.timeIntervalSince1970 ?? -1
        return "\(id)|\(origin)|\(dest)|\(ret)|\(retTime)|\(depTime)|\(transportMode.rawValue)"
    }

    private static let frLocale = Locale(identifier: "fr_FR")

    private static func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year().locale(frLocale))
    }

    private static func formatTime(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute().locale(frLocale))
    }

    private static func hasMeaningfulTime(_ date: Date) -> Bool {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) != 0 || (parts.minute ?? 0) != 0
    }

    private static func formatSchedule(_ date: Date) -> String {
        if hasMeaningfulTime(date) {
            return "\(formatDate(date)) · \(formatTime(date))"
        }
        return formatDate(date)
    }

    /// Trajet complet pour les listes Voyages / Voyages faits (sans troncature).
    var tripsListRouteLine: String {
        let from = Self.displayPlaceName(origin)
        let to = Self.displayPlaceName(dest)
        switch (from.isEmpty, to.isEmpty) {
        case (true, true): return "Trajet à définir"
        case (true, false): return to
        case (false, true): return from
        default:
            var line = "\(from) → \(to)"
            if hasReturn {
                let ret = returnLocation.map { Self.displayPlaceName($0) } ?? ""
                line += ret.isEmpty ? " · Retour" : " · Retour · \(ret)"
            }
            return line
        }
    }

    var tripsListDepartureLabel: String {
        guard let departureDate else {
            if dates != "Dates à définir" { return "Départ · \(dates)" }
            return "Départ · date à définir"
        }
        return "Départ · \(Self.formatSchedule(departureDate))"
    }

    var tripsListReturnLabel: String? {
        guard hasReturn else { return nil }
        guard let returnDate else { return "Retour · date à définir" }
        return "Retour · \(Self.formatSchedule(returnDate))"
    }

    var routeLine: String {
        let from = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let to = dest.trimmingCharacters(in: .whitespacesAndNewlines)
        if from.isEmpty { return to }
        if to.isEmpty { return from }
        return "\(from) → \(to)"
    }

    var displayDate: String {
        if let departureDate {
            return Self.formatDate(departureDate)
        }
        if dates != "Dates à définir" { return dates }
        return "Date à définir"
    }

    var tripSubtitle: String {
        var parts: [String] = []
        if departureDate != nil {
            parts.append(displayDate)
        } else if dates != "Dates à définir" {
            parts.append(dates)
        }
        if hasReturn {
            var retParts: [String] = []
            if let loc = returnLocation?.trimmingCharacters(in: .whitespacesAndNewlines), !loc.isEmpty {
                retParts.append(Self.compactPlaceName(loc))
            }
            if let returnDate {
                retParts.append(Self.formatDate(returnDate))
            }
            parts.append(retParts.isEmpty ? "Retour" : "Retour · \(retParts.joined(separator: " · "))")
        } else {
            parts.append("Aller simple")
        }
        return parts.joined(separator: " · ")
    }

    static let defaultTripTitle = "Titre du voyage"

    /// Titre personnalisé saisi, ou `nil` si vide / ancien remplissage auto (destination).
    var resolvedCustomTitle: String? {
        let custom = tripTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !custom.isEmpty else { return nil }
        let place = dest.trimmingCharacters(in: .whitespacesAndNewlines)
        if !place.isEmpty, custom == place || custom == Self.compactPlaceName(place) {
            return nil
        }
        return custom
    }

    /// Titre affiché dans l’app.
    var displayTitle: String {
        resolvedCustomTitle ?? Self.defaultTripTitle
    }

    /// Titre court pour les cartes Accueil.
    var homeDestinationTitle: String {
        displayTitle
    }

    var homeRouteLine: String? {
        let from = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !from.isEmpty else { return nil }
        return "\(Self.compactPlaceName(from)) → \(Self.compactPlaceName(dest))"
    }

    /// Aller : départ → destination (carte Accueil).
    var homeOutboundLine: String {
        let from = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let to = dest.trimmingCharacters(in: .whitespacesAndNewlines)
        let fromLabel = from.isEmpty ? "Départ ?" : Self.mapPlaceLabel(from)
        let toLabel = to.isEmpty ? "Arrivée ?" : Self.mapPlaceLabel(to)
        return "\(fromLabel) → \(toLabel)"
    }

    /// Retour : lieu de retour (carte Accueil), ligne dédiée.
    var homeReturnLine: String? {
        guard hasReturn else { return nil }
        let ret = returnLocation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !ret.isEmpty else { return "Retour" }
        return "Retour \(Self.routeDetailPlaceName(ret))"
    }

    /// Trajet compact pour la carte Accueil (départ → arrivée + retour éventuel).
    var homeItineraryLine: String {
        if let returnLine = homeReturnLine {
            return "\(homeOutboundLine) · \(returnLine)"
        }
        return homeOutboundLine
    }

    var homeDateLine: String {
        if let departureDate {
            if hasReturn {
                if let returnDate {
                    return "\(Self.formatDate(departureDate)) → \(Self.formatDate(returnDate))"
                }
                return "\(Self.formatDate(departureDate)) · Aller-retour"
            }
            return "\(Self.formatDate(departureDate)) · Aller simple"
        }
        if hasReturn, let returnDate {
            return "Retour \(Self.formatDate(returnDate))"
        }
        if dates != "Dates à définir" { return dates }
        return "Date à définir"
    }

    /// Sous-titre puce aller-retour : date + type (comme aller simple).
    var homeChipDateLine: String {
        guard hasReturn else { return homeDateLine }
        if let departureDate {
            return "\(Self.formatDate(departureDate)) · Aller-retour"
        }
        return "Aller-retour"
    }

    /// Libellé complet pour la fiche trajet (pas de troncature).
    static func displayPlaceName(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Nom de lieu lisible sous la carte (ex. « Lisboa Oriente »).
    static func routeDetailPlaceName(_ raw: String) -> String {
        var name = displayPlaceName(raw)
        if let comma = name.firstIndex(of: ",") {
            name = String(name[..<comma]).trimmingCharacters(in: .whitespaces)
        }
        if name.count > 40 {
            let end = name.index(name.startIndex, offsetBy: 38)
            return String(name[..<end]) + "…"
        }
        return name
    }

    /// Libellé court pour les cartes (même gabarit avion, train, bateau, voiture).
    static func mapPlaceLabel(_ raw: String) -> String {
        var name = displayPlaceName(raw)
        if let comma = name.firstIndex(of: ",") {
            name = String(name[..<comma]).trimmingCharacters(in: .whitespaces)
        }
        for separator in [" · ", " - ", " – ", " — "] {
            if let range = name.range(of: separator) {
                name = String(name[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        let suffixes = [
            " International Airport", " Intl Airport", " Airport",
            " Aéroport International", " Aéroport",
        ]
        for suffix in suffixes where name.hasSuffix(suffix) {
            name = String(name.dropLast(suffix.count))
        }
        let words = name.split(separator: " ").filter { !$0.isEmpty }
        if words.count > 3 {
            name = words.prefix(3).joined(separator: " ")
        }
        if name.count > 22 {
            let end = name.index(name.startIndex, offsetBy: 22)
            return String(name[..<end]).trimmingCharacters(in: .whitespaces) + "…"
        }
        return name
    }

    static func compactPlaceName(_ raw: String) -> String {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = [
            "Aéroport ", "Airport ", "Port de ", "Port d'", "Gare de ", "Gare du ",
            "Paris ", "London ", "Lyon ", "Lyon-",
        ]
        for prefix in prefixes where name.hasPrefix(prefix) {
            name = String(name.dropFirst(prefix.count))
        }
        if name.hasSuffix(" Airport") {
            name = String(name.dropLast(8))
        }
        if name.count > 32 {
            let end = name.index(name.startIndex, offsetBy: 30)
            return String(name[..<end]) + "…"
        }
        return name
    }

    enum CodingKeys: String, CodingKey {
        case id, origin, dest, country, flag, dates, departureDate, returnLocation, returnDate, transportMode
        case days, hue, status, budget, spent, emergencyFund, emergencyFundEnabled, cover, tripTitle, coverKind, rating, photoCount
    }

    init(
        id: String,
        origin: String = "",
        dest: String,
        country: String = "",
        flag: String = "",
        dates: String = "Dates à définir",
        departureDate: Date? = nil,
        returnLocation: String? = nil,
        returnDate: Date? = nil,
        transportMode: TransportMode = .car,
        days: Int = 1,
        hue: Double,
        status: Status,
        budget: Int = 0,
        spent: Int = 0,
        emergencyFund: Int = 0,
        emergencyFundEnabled: Bool = false,
        cover: String,
        tripTitle: String = "",
        coverKind: TripCoverKind = .none,
        rating: Double = 0,
        photoCount: Int = 0
    ) {
        self.id = id
        self.origin = origin
        self.dest = dest
        self.country = country
        self.flag = flag
        self.dates = dates
        self.departureDate = departureDate
        self.returnLocation = returnLocation
        self.returnDate = returnDate
        self.transportMode = transportMode
        self.days = days
        self.hue = hue
        self.status = status
        self.budget = budget
        self.spent = spent
        self.emergencyFund = emergencyFund
        self.emergencyFundEnabled = emergencyFundEnabled
        self.cover = cover
        self.tripTitle = tripTitle
        self.coverKind = coverKind
        self.rating = rating
        self.photoCount = photoCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        origin = try c.decodeIfPresent(String.self, forKey: .origin) ?? ""
        dest = try c.decode(String.self, forKey: .dest)
        country = try c.decodeIfPresent(String.self, forKey: .country) ?? ""
        flag = try c.decodeIfPresent(String.self, forKey: .flag) ?? ""
        dates = try c.decodeIfPresent(String.self, forKey: .dates) ?? "Dates à définir"
        departureDate = try c.decodeIfPresent(Date.self, forKey: .departureDate)
        returnLocation = try c.decodeIfPresent(String.self, forKey: .returnLocation)
        returnDate = try c.decodeIfPresent(Date.self, forKey: .returnDate)
        transportMode = try c.decodeIfPresent(TransportMode.self, forKey: .transportMode) ?? .car
        days = try c.decodeIfPresent(Int.self, forKey: .days) ?? 1
        hue = try c.decode(Double.self, forKey: .hue)
        status = try c.decode(Status.self, forKey: .status)
        budget = try c.decodeIfPresent(Int.self, forKey: .budget) ?? 0
        spent = try c.decodeIfPresent(Int.self, forKey: .spent) ?? 0
        emergencyFund = try c.decodeIfPresent(Int.self, forKey: .emergencyFund) ?? 0
        if let enabled = try c.decodeIfPresent(Bool.self, forKey: .emergencyFundEnabled) {
            emergencyFundEnabled = enabled
        } else {
            emergencyFundEnabled = emergencyFund > 0
        }
        cover = try c.decodeIfPresent(String.self, forKey: .cover) ?? dest
        tripTitle = try c.decodeIfPresent(String.self, forKey: .tripTitle) ?? dest
        coverKind = try c.decodeIfPresent(TripCoverKind.self, forKey: .coverKind) ?? .none
        rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        photoCount = try c.decodeIfPresent(Int.self, forKey: .photoCount) ?? 0
    }
}

enum ExpenseStatus: String, Codable, Hashable {
    case upcoming
    case completed
}

struct Expense: Identifiable, Hashable, Codable {
    let id: String
    var tripId: String
    var date: Date
    var label: String
    var category: String
    var amount: Int
    var currency: String?
    var location: String
    var notes: String
    var rating: Double
    var status: ExpenseStatus
    var paidWith: String

    enum CodingKeys: String, CodingKey {
        case id, tripId, date, label, category, amount, currency
        case location, notes, rating, status, paidWith
    }

    init(
        id: String,
        tripId: String,
        date: Date,
        label: String,
        category: String,
        amount: Int,
        currency: String? = "EUR",
        location: String = "",
        notes: String = "",
        rating: Double = 0,
        status: ExpenseStatus = .completed,
        paidWith: String = ""
    ) {
        self.id = id
        self.tripId = tripId
        self.date = date
        self.label = label
        self.category = category
        self.amount = amount
        self.currency = currency
        self.location = location
        self.notes = notes
        self.rating = rating
        self.status = status
        self.paidWith = paidWith
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tripId = try c.decode(String.self, forKey: .tripId)
        date = try c.decode(Date.self, forKey: .date)
        label = try c.decode(String.self, forKey: .label)
        category = try c.decode(String.self, forKey: .category)
        amount = try c.decode(Int.self, forKey: .amount)
        currency = try c.decodeIfPresent(String.self, forKey: .currency)
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        status = try c.decodeIfPresent(ExpenseStatus.self, forKey: .status) ?? .completed
        paidWith = try c.decodeIfPresent(String.self, forKey: .paidWith) ?? ""
    }

    var isUpcoming: Bool { status == .upcoming }
}

struct EmergencyFundEntry: Identifiable, Hashable, Codable {
    let id: String
    var tripId: String
    var amount: Int
    var cause: String
    var notes: String
    var date: Date

    enum CodingKeys: String, CodingKey {
        case id, tripId, amount, cause, notes, date
    }

    init(id: String = UUID().uuidString, tripId: String, amount: Int, cause: String, notes: String = "", date: Date = Date()) {
        self.id = id
        self.tripId = tripId
        self.amount = amount
        self.cause = cause
        self.notes = notes
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tripId = try c.decode(String.self, forKey: .tripId)
        amount = try c.decode(Int.self, forKey: .amount)
        cause = try c.decode(String.self, forKey: .cause)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        date = try c.decode(Date.self, forKey: .date)
    }
}

struct Flight: Identifiable, Hashable, Codable {
    let id: String
    var tripId: String
    var transportMode: TransportMode
    var code: String
    var from: String
    var fromCity: String
    var to: String
    var toCity: String
    var date: String
    var departure: String
    var arrival: String
    var duration: String
    var seat: String
    var gate: String
    var terminal: String
    var company: String
}

/// Activité planifiée pour un jour du voyage (clé calendrier `yyyy-MM-dd`).
struct TripPlanItem: Identifiable, Hashable, Codable {
    let id: String
    var tripId: String
    var dayKey: String
    var dayIndex: Int
    var time: String
    var title: String
    var location: String
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id, tripId, dayKey, dayIndex, time, title, location, notes
    }

    init(
        id: String,
        tripId: String,
        dayKey: String,
        dayIndex: Int = 0,
        time: String,
        title: String,
        location: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.tripId = tripId
        self.dayKey = dayKey
        self.dayIndex = dayIndex
        self.time = time
        self.title = title
        self.location = location
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tripId = try c.decode(String.self, forKey: .tripId)
        dayKey = try c.decodeIfPresent(String.self, forKey: .dayKey) ?? ""
        dayIndex = try c.decodeIfPresent(Int.self, forKey: .dayIndex) ?? 0
        time = try c.decodeIfPresent(String.self, forKey: .time) ?? ""
        title = try c.decode(String.self, forKey: .title)
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

/// Titre et description d’une photo souvenir (description max 150 lignes).
struct TripPhotoMemory: Codable, Hashable {
    var title: String = ""
    var caption: String = ""
    /// Date du souvenir (`yyyy-MM-dd`), vide si non renseignée.
    var photoDateKey: String = ""

    enum CodingKeys: String, CodingKey {
        case title, caption, photoDateKey
    }

    init(title: String = "", caption: String = "", photoDateKey: String = "") {
        self.title = title
        self.caption = caption
        self.photoDateKey = photoDateKey
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        caption = try c.decodeIfPresent(String.self, forKey: .caption) ?? ""
        photoDateKey = try c.decodeIfPresent(String.self, forKey: .photoDateKey) ?? ""
    }

    var photoDate: Date? {
        TripPlanCalendar.date(from: photoDateKey)
    }

    static let maxCaptionLines = 150

    static func clampedCaption(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        if lines.count > maxCaptionLines {
            lines = Array(lines.prefix(maxCaptionLines))
        }
        return lines.joined(separator: "\n")
    }

    static func lineCount(for text: String) -> Int {
        if text.isEmpty { return 0 }
        return text.components(separatedBy: "\n").count
    }
}

enum TripPlanCalendar {
    // Built once — DateFormatter creation costs ~1 ms; reuse eliminates per-call overhead.
    // Usage is exclusively on the main thread (SwiftUI views), so no lock needed.
    private static let _fmt: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(for date: Date) -> String {
        let day = Calendar.current.startOfDay(for: date)
        return _fmt.string(from: day)
    }

    static func date(from dayKey: String) -> Date? {
        _fmt.date(from: dayKey)
    }
}

extension Trip {
    /// Nombre de journées pour la planification.
    var planDayCount: Int {
        if let departureDate, let returnDate {
            let start = Calendar.current.startOfDay(for: departureDate)
            let end = Calendar.current.startOfDay(for: returnDate)
            let gap = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            return max(1, gap + 1)
        }
        return max(1, days)
    }

    func planDate(for dayIndex: Int) -> Date? {
        guard let departureDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: dayIndex, to: departureDate)
    }
}

struct Spot: Identifiable, Hashable, Codable {
    let id: String
    var tripId: String
    var name: String
    var category: String
    var area: String
    var address: String
    var spotDescription: String
    var rating: Double
    var saved: Bool
    var toRedo: Bool
    var photoCount: Int
    var hue: Double
    var x: Double
    var y: Double

    enum CodingKeys: String, CodingKey {
        case id, tripId, name, category, area, address, spotDescription, rating, saved, toRedo, photoCount, hue, x, y
    }

    init(
        id: String, tripId: String, name: String, category: String,
        area: String = "", address: String = "", spotDescription: String = "",
        rating: Double, saved: Bool, toRedo: Bool = false, photoCount: Int = 0,
        hue: Double, x: Double, y: Double
    ) {
        self.id = id; self.tripId = tripId; self.name = name
        self.category = category; self.area = area; self.address = address
        self.spotDescription = spotDescription
        self.rating = rating; self.saved = saved; self.toRedo = toRedo
        self.photoCount = photoCount; self.hue = hue; self.x = x; self.y = y
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tripId = try c.decode(String.self, forKey: .tripId)
        name = try c.decode(String.self, forKey: .name)
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "Autre"
        area = try c.decodeIfPresent(String.self, forKey: .area) ?? ""
        address = try c.decodeIfPresent(String.self, forKey: .address) ?? ""
        spotDescription = try c.decodeIfPresent(String.self, forKey: .spotDescription) ?? ""
        rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 4.5
        saved = try c.decodeIfPresent(Bool.self, forKey: .saved) ?? true
        toRedo = try c.decodeIfPresent(Bool.self, forKey: .toRedo) ?? false
        photoCount = try c.decodeIfPresent(Int.self, forKey: .photoCount) ?? 0
        hue = try c.decodeIfPresent(Double.self, forKey: .hue) ?? 180
        x = try c.decodeIfPresent(Double.self, forKey: .x) ?? 50
        y = try c.decodeIfPresent(Double.self, forKey: .y) ?? 50
    }
}

final class TripStore: ObservableObject {
    @Published var trips: [Trip] { didSet { save() } }
    @Published var expenses: [Expense] { didSet { save() } }
    @Published var emergencyFundEntries: [EmergencyFundEntry] { didSet { save() } }
    @Published var flights: [Flight] { didSet { save() } }
    @Published var spots: [Spot] { didSet { save() } }
    @Published var planItems: [TripPlanItem] { didSet { save() } }
    @Published var extraPlanDayKeys: [String: [String]] { didSet { save() } }
    @Published var selectedTripId: String? { didSet { defaults.set(selectedTripId, forKey: selectedTripKey) } }

    private let defaults: UserDefaults
    private let tripsKey = "tripnest.trips"
    private let expensesKey = "tripnest.expenses"
    private let emergencyFundKey = "tripnest.emergencyFundEntries"
    private let flightsKey = "tripnest.flights"
    private let spotsKey = "tripnest.spots"
    private let planItemsKey = "tripnest.planItems"
    private let extraPlanDaysKey = "tripnest.extraPlanDays"
    private let selectedTripKey = "tripnest.selectedTripId"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.trips = Self.load([Trip].self, key: tripsKey, defaults: defaults) ?? []
        self.expenses = Self.load([Expense].self, key: expensesKey, defaults: defaults) ?? []
        self.emergencyFundEntries = Self.load([EmergencyFundEntry].self, key: emergencyFundKey, defaults: defaults) ?? []
        self.flights = Self.load([Flight].self, key: flightsKey, defaults: defaults) ?? []
        self.spots = Self.load([Spot].self, key: spotsKey, defaults: defaults) ?? []
        self.planItems = Self.load([TripPlanItem].self, key: planItemsKey, defaults: defaults) ?? []
        self.extraPlanDayKeys = Self.load([String: [String]].self, key: extraPlanDaysKey, defaults: defaults) ?? [:]
        self.selectedTripId = defaults.string(forKey: selectedTripKey)
        migratePlanItemsIfNeeded()
        migrateEmergencyEntriesIfNeeded()
        syncAllTripSpentFromExpenses()
    }

    private func migrateEmergencyEntriesIfNeeded() {
        for trip in trips where trip.emergencyFund > 0 {
            guard !emergencyFundEntries.contains(where: { $0.tripId == trip.id }) else { continue }
            emergencyFundEntries.append(
                EmergencyFundEntry(
                    tripId: trip.id,
                    amount: trip.emergencyFund,
                    cause: "Fond d'urgence"
                )
            )
        }
    }

    func emergencyEntries(for tripId: String) -> [EmergencyFundEntry] {
        emergencyFundEntries
            .filter { $0.tripId == tripId }
            .sorted { $0.date > $1.date }
    }

    private func syncAllTripSpentFromExpenses() {
        for trip in trips {
            recalculateTripSpent(tripId: trip.id)
        }
    }

    var activeTrip: Trip? {
        if let id = selectedTripId, let trip = trips.first(where: { $0.id == id }) {
            return trip
        }
        return trips.first { $0.status == .active }
            ?? trips.first { $0.status == .done }
            ?? trips.first { $0.status == .planned }
            ?? trips.first
    }

    var pastTrips: [Trip] {
        trips.filter { $0.status == .done }
    }

    func selectTrip(id: String) {
        selectedTripId = id
    }

    func expenses(for tripId: String) -> [Expense] {
        expenses.filter { $0.tripId == tripId }.sorted { $0.date > $1.date }
    }

    func upcomingExpenses(for tripId: String) -> [Expense] {
        expenses
            .filter { $0.tripId == tripId && $0.status == .upcoming }
            .sorted { $0.date < $1.date }
    }

    func completedExpenses(for tripId: String) -> [Expense] {
        expenses
            .filter { $0.tripId == tripId && $0.status == .completed }
            .sorted { $0.date > $1.date }
    }

    func flights(for tripId: String) -> [Flight] {
        flights.filter { $0.tripId == tripId }
    }

    func tickets(for trip: Trip) -> [Flight] {
        flights.filter { $0.tripId == trip.id && $0.transportMode == trip.transportMode }
    }

    func primaryTicket(for trip: Trip) -> Flight? {
        tickets(for: trip).first
    }

    func spots(for tripId: String) -> [Spot] {
        spots.filter { $0.tripId == tripId }
    }

    func defaultPlanDates(for trip: Trip) -> [Date] {
        let start = trip.departureDate.map { Calendar.current.startOfDay(for: $0) }
            ?? Calendar.current.startOfDay(for: Date())
        return (0..<trip.planDayCount).compactMap { index in
            Calendar.current.date(byAdding: .day, value: index, to: start)
        }
    }

    func allPlanDayKeys(for tripId: String) -> [String] {
        guard let trip = trips.first(where: { $0.id == tripId }) else { return [] }
        var keys = Set<String>()
        for date in defaultPlanDates(for: trip) {
            keys.insert(TripPlanCalendar.dayKey(for: date))
        }
        for key in extraPlanDayKeys[tripId] ?? [] {
            keys.insert(key)
        }
        for item in planItems where item.tripId == tripId {
            keys.insert(item.dayKey)
        }
        return keys.sorted()
    }

    func registerPlanDay(tripId: String, date: Date) {
        let key = TripPlanCalendar.dayKey(for: date)
        var list = extraPlanDayKeys[tripId] ?? []
        if !list.contains(key) {
            list.append(key)
            extraPlanDayKeys[tripId] = list.sorted()
        }
    }

    func planItems(for tripId: String, dayKey: String) -> [TripPlanItem] {
        planItems
            .filter { $0.tripId == tripId && $0.dayKey == dayKey }
            .sorted { lhs, rhs in
                if lhs.time != rhs.time { return lhs.time < rhs.time }
                return lhs.title < rhs.title
            }
    }

    func addPlanItem(tripId: String, dayKey: String, time: String, title: String, location: String = "", notes: String = "") {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        registerPlanDay(tripId: tripId, date: TripPlanCalendar.date(from: dayKey) ?? Date())
        let dayIndex = planDayIndex(for: tripId, dayKey: dayKey)
        planItems.append(
            TripPlanItem(
                id: UUID().uuidString,
                tripId: tripId,
                dayKey: dayKey,
                dayIndex: dayIndex,
                time: time.trimmingCharacters(in: .whitespacesAndNewlines),
                title: cleaned,
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
    }

    private func planDayIndex(for tripId: String, dayKey: String) -> Int {
        let keys = allPlanDayKeys(for: tripId)
        return keys.firstIndex(of: dayKey) ?? 0
    }

    private func migratePlanItemsIfNeeded() {
        var changed = false
        for index in planItems.indices where planItems[index].dayKey.isEmpty {
            guard let trip = trips.first(where: { $0.id == planItems[index].tripId }) else { continue }
            let date = trip.planDate(for: planItems[index].dayIndex)
                ?? defaultPlanDates(for: trip).first
                ?? Date()
            planItems[index].dayKey = TripPlanCalendar.dayKey(for: date)
            changed = true
        }
        if changed { save() }
    }

    func deletePlanItem(id: String) {
        planItems.removeAll { $0.id == id }
    }

    func deletePlanDay(tripId: String, dayKey: String) {
        planItems.removeAll { $0.tripId == tripId && $0.dayKey == dayKey }
        if var list = extraPlanDayKeys[tripId] {
            list.removeAll { $0 == dayKey }
            if list.isEmpty {
                extraPlanDayKeys[tripId] = nil
            } else {
                extraPlanDayKeys[tripId] = list
            }
        }
    }

    func reschedulePlanDay(tripId: String, from oldKey: String, to newDate: Date) {
        let newKey = TripPlanCalendar.dayKey(for: newDate)
        guard oldKey != newKey else { return }
        for index in planItems.indices where planItems[index].tripId == tripId && planItems[index].dayKey == oldKey {
            planItems[index].dayKey = newKey
        }
        var list = extraPlanDayKeys[tripId] ?? []
        list.removeAll { $0 == oldKey }
        if !list.contains(newKey) {
            list.append(newKey)
        }
        extraPlanDayKeys[tripId] = list.sorted()
    }

    func updatePlanItem(id: String, time: String, title: String, location: String, notes: String) {
        guard let index = planItems.firstIndex(where: { $0.id == id }) else { return }
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        planItems[index].time = time.trimmingCharacters(in: .whitespacesAndNewlines)
        planItems[index].title = cleaned
        planItems[index].location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        planItems[index].notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @discardableResult
    func addTrip(
        origin: String,
        destination: String,
        departureDate: Date? = nil,
        returnLocation: String? = nil,
        returnDate: Date? = nil,
        transportMode: TransportMode = .car,
        tripTitle: String = "",
        coverKind: TripCoverKind = .none,
        id: String = UUID().uuidString
    ) -> String {
        let cleanedOrigin = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedDest = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        let placeTitle = cleanedDest.isEmpty ? "Nouveau voyage" : cleanedDest
        let cleanedReturn = returnLocation?.trimmingCharacters(in: .whitespacesAndNewlines)
        let storedReturn = (cleanedReturn?.isEmpty == false) ? cleanedReturn : nil
        let dateLabel = Self.tripDatesLabel(departure: departureDate, returnDate: returnDate)
        let storedTitle = tripTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trip = Trip(
            id: id,
            origin: cleanedOrigin,
            dest: placeTitle,
            country: "",
            flag: "",
            dates: dateLabel,
            departureDate: departureDate,
            returnLocation: storedReturn,
            returnDate: returnDate,
            transportMode: transportMode,
            days: 1,
            hue: Double(abs(placeTitle.hashValue % 300) + 20),
            status: trips.contains(where: { $0.status == .active }) ? .planned : .active,
            budget: 0,
            spent: 0,
            cover: placeTitle,
            tripTitle: storedTitle,
            coverKind: coverKind,
            rating: 0
        )
        trips.insert(trip, at: 0)
        selectTrip(id: trip.id)
        return trip.id
    }

    func addFlight(
        code: String,
        from: String,
        fromCity: String,
        to: String,
        toCity: String,
        date: String,
        departure: String,
        arrival: String,
        duration: String,
        company: String = "",
        seat: String = "",
        gate: String = "",
        terminal: String = "",
        tripId: String? = nil,
        transportMode: TransportMode? = nil
    ) {
        let resolvedTripId = tripId ?? activeTrip?.id
        guard let resolvedTripId else { return }
        let resolvedMode = transportMode ?? activeTrip?.transportMode ?? .plane
        flights.insert(
            Flight(
                id: UUID().uuidString,
                tripId: resolvedTripId,
                transportMode: resolvedMode,
                code: code.trimmingCharacters(in: .whitespacesAndNewlines),
                from: from.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                fromCity: fromCity.trimmingCharacters(in: .whitespacesAndNewlines),
                to: to.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                toCity: toCity.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date.trimmingCharacters(in: .whitespacesAndNewlines),
                departure: departure.trimmingCharacters(in: .whitespacesAndNewlines),
                arrival: arrival.trimmingCharacters(in: .whitespacesAndNewlines),
                duration: duration.trimmingCharacters(in: .whitespacesAndNewlines),
                seat: seat.trimmingCharacters(in: .whitespacesAndNewlines),
                gate: gate.trimmingCharacters(in: .whitespacesAndNewlines),
                terminal: terminal.trimmingCharacters(in: .whitespacesAndNewlines),
                company: company.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            at: 0
        )
    }

    func addSpot(
        name: String,
        category: String,
        area: String = "",
        address: String = "",
        spotDescription: String = "",
        toRedo: Bool = false,
        photoCount: Int = 0,
        rating: Double = 4.5,
        tripId: String? = nil
    ) {
        let resolvedTripId = tripId ?? activeTrip?.id
        guard let resolvedTripId, let trip = trips.first(where: { $0.id == resolvedTripId }) ?? activeTrip else { return }
        let label = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else { return }
        let hue = Double(abs(label.hashValue % 300) + 20)
        let resolvedArea = area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? trip.dest : area
        spots.insert(
            Spot(
                id: UUID().uuidString,
                tripId: resolvedTripId,
                name: label,
                category: category,
                area: resolvedArea,
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                spotDescription: spotDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                rating: rating,
                saved: true,
                toRedo: toRedo,
                photoCount: photoCount,
                hue: hue,
                x: Double.random(in: 18...82),
                y: Double.random(in: 22...78)
            ),
            at: 0
        )
    }

    func updateSpotPhotoCount(id: String, count: Int) {
        guard let index = spots.firstIndex(where: { $0.id == id }) else { return }
        spots[index].photoCount = count
    }

    func updateSpot(
        id: String,
        name: String,
        category: String,
        address: String,
        spotDescription: String,
        toRedo: Bool,
        photoCount: Int,
        rating: Double,
        tripId: String
    ) {
        guard let index = spots.firstIndex(where: { $0.id == id }) else { return }
        spots[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        spots[index].category = category
        spots[index].address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        spots[index].spotDescription = spotDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        spots[index].toRedo = toRedo
        spots[index].photoCount = photoCount
        spots[index].rating = rating
        spots[index].tripId = tripId
    }

    func toggleSpotSaved(id: String) {
        guard let index = spots.firstIndex(where: { $0.id == id }) else { return }
        spots[index].saved.toggle()
        if !spots[index].saved {
            spots[index].toRedo = false
        }
    }

    func updateBudget(tripId: String, budget: Int) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[idx].budget = max(0, budget)
    }

    func updateEmergencyFund(tripId: String, fund: Int) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[idx].emergencyFund = max(0, fund)
    }

    func setEmergencyFundEnabled(tripId: String, enabled: Bool) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[idx].emergencyFundEnabled = enabled
    }

    func addEmergencyFundEntry(tripId: String, amount: Int, cause: String, notes: String = "") {
        guard amount > 0, let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        let label = cause.trimmingCharacters(in: .whitespacesAndNewlines)
        emergencyFundEntries.insert(
            EmergencyFundEntry(
                tripId: tripId,
                amount: amount,
                cause: label.isEmpty ? "Fond d'urgence" : label,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            at: 0
        )
        trips[idx].emergencyFundEnabled = true
        syncEmergencyFundTotal(tripId: tripId)
    }

    func updateEmergencyFundEntry(id: String, amount: Int, cause: String, notes: String = "") {
        guard amount > 0, let entryIdx = emergencyFundEntries.firstIndex(where: { $0.id == id }) else { return }
        let tripId = emergencyFundEntries[entryIdx].tripId
        let label = cause.trimmingCharacters(in: .whitespacesAndNewlines)
        emergencyFundEntries[entryIdx].amount = amount
        emergencyFundEntries[entryIdx].cause = label.isEmpty ? "Fond d'urgence" : label
        emergencyFundEntries[entryIdx].notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        syncEmergencyFundTotal(tripId: tripId)
    }

    func deleteEmergencyFundEntry(id: String) {
        guard let entry = emergencyFundEntries.first(where: { $0.id == id }) else { return }
        emergencyFundEntries.removeAll { $0.id == id }
        syncEmergencyFundTotal(tripId: entry.tripId)
    }

    func withdrawEmergencyFundEntry(id: String, currency: String = "EUR") {
        guard let entry = emergencyFundEntries.first(where: { $0.id == id }) else { return }
        let tripId = entry.tripId
        let label = entry.cause.trimmingCharacters(in: .whitespacesAndNewlines)
        addExpense(
            label: label.isEmpty ? "Fond d'urgence" : label,
            category: "Urgence",
            amount: entry.amount,
            currency: currency,
            notes: entry.notes,
            status: .completed,
            tripId: tripId
        )
        emergencyFundEntries.removeAll { $0.id == id }
        syncEmergencyFundTotal(tripId: tripId)
    }

    private func syncEmergencyFundTotal(tripId: String) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[idx].emergencyFund = emergencyFundEntries
            .filter { $0.tripId == tripId }
            .reduce(0) { $0 + $1.amount }
    }

    func updateTrip(
        id: String,
        origin: String,
        destination: String,
        departureDate: Date? = nil,
        returnLocation: String? = nil,
        returnDate: Date? = nil,
        transportMode: TransportMode? = nil,
        tripTitle: String? = nil,
        coverKind: TripCoverKind? = nil
    ) {
        guard let index = trips.firstIndex(where: { $0.id == id }) else { return }
        let cleanedOrigin = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedDest = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        let placeTitle = cleanedDest.isEmpty ? trips[index].dest : cleanedDest
        let cleanedReturn = returnLocation?.trimmingCharacters(in: .whitespacesAndNewlines)
        let storedReturn = (cleanedReturn?.isEmpty == false) ? cleanedReturn : nil

        if !cleanedOrigin.isEmpty {
            trips[index].origin = cleanedOrigin
        }
        trips[index].dest = placeTitle
        trips[index].departureDate = departureDate
        trips[index].returnLocation = storedReturn
        trips[index].returnDate = returnDate
        trips[index].dates = Self.tripDatesLabel(
            departure: trips[index].departureDate,
            returnDate: trips[index].returnDate
        )
        if let transportMode { trips[index].transportMode = transportMode }
        trips[index].cover = placeTitle
        if let tripTitle {
            trips[index].tripTitle = tripTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let coverKind { trips[index].coverKind = coverKind }
    }

    private static func tripDatesLabel(departure: Date?, returnDate: Date?) -> String {
        let fr = Locale(identifier: "fr_FR")
        let fmt = { (d: Date) in d.formatted(.dateTime.day().month(.abbreviated).year().locale(fr)) }
        switch (departure, returnDate) {
        case let (dep?, ret?):
            return "\(fmt(dep)) → \(fmt(ret))"
        case let (dep?, nil):
            return fmt(dep)
        case let (nil, ret?):
            return "Retour \(fmt(ret))"
        case (nil, nil):
            return "Dates à définir"
        }
    }

    func markTripDone(id: String) {
        setTripCompleted(id: id, completed: true)
    }

    func setTripCompleted(id: String, completed: Bool) {
        guard let index = trips.firstIndex(where: { $0.id == id }) else { return }
        if completed {
            trips[index].status = .done
        } else {
            trips[index].status = .active
        }
    }

    func updateTripPhotoCount(tripId: String, count: Int) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[index].photoCount = max(0, count)
    }

    func deleteTrip(id: String) {
        TripCoverImageStore.delete(tripId: id)
        let photoCount = trips.first(where: { $0.id == id })?.photoCount ?? 0
        TripPhotoStore.deleteAll(tripId: id, count: max(photoCount, 1))
        trips.removeAll { $0.id == id }
        expenses.removeAll { $0.tripId == id }
        emergencyFundEntries.removeAll { $0.tripId == id }
        flights.removeAll { $0.tripId == id }
        spots.removeAll { $0.tripId == id }
        planItems.removeAll { $0.tripId == id }
        extraPlanDayKeys[id] = nil
        if selectedTripId == id {
            selectedTripId = trips.first?.id
        }
    }

    func deleteExpense(id: String) {
        guard let expense = expenses.first(where: { $0.id == id }) else { return }
        let tripId = expense.tripId
        expenses.removeAll { $0.id == id }
        recalculateTripSpent(tripId: tripId)
    }

    func markExpenseCompleted(id: String) {
        setExpenseStatus(id: id, status: .completed)
    }

    func setExpenseStatus(id: String, status: ExpenseStatus) {
        guard let index = expenses.firstIndex(where: { $0.id == id }) else { return }
        guard expenses[index].status != status else { return }
        expenses[index].status = status
        recalculateTripSpent(tripId: expenses[index].tripId)
    }

    func deleteFlight(id: String) {
        flights.removeAll { $0.id == id }
    }

    func replaceTicket(for tripId: String, mode: TransportMode, draft: TravelTicketDraft) {
        flights.removeAll { $0.tripId == tripId && $0.transportMode == mode }
        addFlight(
            code: draft.code,
            from: draft.from,
            fromCity: draft.fromCity,
            to: draft.to,
            toCity: draft.toCity,
            date: draft.date,
            departure: draft.departure,
            arrival: draft.arrival,
            duration: draft.duration,
            company: draft.company,
            seat: draft.seat,
            gate: draft.gate,
            terminal: draft.terminal,
            tripId: tripId,
            transportMode: mode
        )
    }

    func deleteSpot(id: String) {
        if let spot = spots.first(where: { $0.id == id }), spot.photoCount > 0 {
            SpotImageStore.deleteAll(spotId: id, count: spot.photoCount)
        }
        spots.removeAll { $0.id == id }
    }

    func addExpense(
        label: String,
        category: String,
        amount: Int,
        currency: String = "EUR",
        date: Date = Date(),
        location: String = "",
        notes: String = "",
        rating: Double = 0,
        status: ExpenseStatus = .completed,
        paidWith: String = "",
        tripId: String? = nil
    ) {
        guard let trip = tripId.flatMap({ id in trips.first(where: { $0.id == id }) }) ?? activeTrip else { return }
        expenses.insert(
            Expense(
                id: UUID().uuidString,
                tripId: trip.id,
                date: date,
                label: label,
                category: category,
                amount: amount,
                currency: currency,
                location: location,
                notes: notes,
                rating: rating,
                status: status,
                paidWith: paidWith
            ),
            at: 0
        )
        recalculateTripSpent(tripId: trip.id)
    }

    func updateExpense(
        id: String,
        label: String,
        category: String,
        amount: Int,
        currency: String,
        date: Date,
        location: String,
        notes: String,
        rating: Double,
        status: ExpenseStatus,
        paidWith: String
    ) {
        guard let index = expenses.firstIndex(where: { $0.id == id }) else { return }
        let tripId = expenses[index].tripId
        expenses[index].label = label
        expenses[index].category = category
        expenses[index].amount = amount
        expenses[index].currency = currency
        expenses[index].date = date
        expenses[index].location = location
        expenses[index].notes = notes
        expenses[index].rating = rating
        expenses[index].status = status
        expenses[index].paidWith = paidWith
        recalculateTripSpent(tripId: tripId)
    }

    func recalculateTripSpent(tripId: String) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[index].spent = expenses
            .filter { $0.tripId == tripId && $0.status == .completed }
            .reduce(0) { $0 + $1.amount }
    }

    private var saveWorkItem: DispatchWorkItem?

    private func save() {
        saveWorkItem?.cancel()
        // Snapshot value types on main thread (instant copy — no race condition possible)
        let trips = self.trips, expenses = self.expenses
        let emergencyEntries = self.emergencyFundEntries
        let flights = self.flights, spots = self.spots
        let planItems = self.planItems, extraKeys = self.extraPlanDayKeys
        let defaults = self.defaults
        let keys = (trips: tripsKey, expenses: expensesKey, emergency: emergencyFundKey, flights: flightsKey,
                    spots: spotsKey, plan: planItemsKey, extra: extraPlanDaysKey)

        let work = DispatchWorkItem {
            Self.save(trips,     key: keys.trips,    defaults: defaults)
            Self.save(expenses,  key: keys.expenses, defaults: defaults)
            Self.save(emergencyEntries, key: keys.emergency, defaults: defaults)
            Self.save(flights,   key: keys.flights,  defaults: defaults)
            Self.save(spots,     key: keys.spots,    defaults: defaults)
            Self.save(planItems, key: keys.plan,     defaults: defaults)
            Self.save(extraKeys, key: keys.extra,    defaults: defaults)
        }
        saveWorkItem = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func save<T: Encodable>(_ value: T, key: String, defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}

extension String {
    var currencySymbol: String {
        switch self {
        case "USD": return "$"
        case "JPY": return "¥"
        case "GBP": return "£"
        default: return "€"
        }
    }
}
