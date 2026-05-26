import Foundation

// Static formatters — DateFormatter creation costs ~1 ms; never recreate inside hot paths.
private enum TicketFormatters {
    static let frDate: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMMM yyyy"; return f
    }()
    static let time: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "HH:mm"; return f
    }()
    static let timeParser: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); return f
    }()
    static let dateParser: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); return f
    }()
}

struct TravelTicketDraft: Equatable {
    var code = ""
    var company = ""
    var from = ""
    var fromCity = ""
    var to = ""
    var toCity = ""
    var date = ""
    var departure = ""
    var arrival = ""
    var duration = ""
    var seat = ""
    var gate = ""
    var terminal = ""

    var hasMinimumInfo: Bool {
        !from.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !to.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var summaryLine: String {
        let dep = fromCity.isEmpty ? from : fromCity
        let arr = toCity.isEmpty ? to : toCity
        if dep.isEmpty && arr.isEmpty { return "Billet à compléter" }
        return "\(dep) → \(arr)"
    }

    init() {}

    init(flight: Flight) {
        code = flight.code
        company = flight.company
        from = flight.from
        fromCity = flight.fromCity
        to = flight.to
        toCity = flight.toCity
        date = flight.date
        departure = flight.departure
        arrival = flight.arrival
        duration = flight.duration
        seat = flight.seat
        gate = flight.gate
        terminal = flight.terminal
    }

    /// Remplit le formulaire voyage depuis le billet (écrase avec les infos billet quand présentes).
    func applyToTripForm(
        origin: inout String,
        destination: inout String,
        departureDate: inout Date?
    ) {
        if let dep = resolvedOriginLabel, !dep.isEmpty { origin = dep }
        if let arr = resolvedDestinationLabel, !arr.isEmpty { destination = arr }
        if let parsed = Self.parseDepartureDate(from: date) {
            departureDate = parsed
        }
    }

    /// Complète le brouillon billet avec le voyage déjà saisi (champs vides uniquement).
    mutating func prefillFromTrip(
        origin: String,
        destination: String,
        departureDate: Date?
    ) {
        let o = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        if fromCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           from.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !o.isEmpty {
            fromCity = o
        }
        if toCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           to.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !d.isEmpty {
            toCity = d
        }
        if date.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let departureDate {
            date = Self.formatDepartureDate(departureDate)
        }
    }

    var resolvedOriginLabel: String? {
        let city = fromCity.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = from.trimmingCharacters(in: .whitespacesAndNewlines)
        if !city.isEmpty { return city }
        if !code.isEmpty { return code }
        return nil
    }

    var resolvedDestinationLabel: String? {
        let city = toCity.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = to.trimmingCharacters(in: .whitespacesAndNewlines)
        if !city.isEmpty { return city }
        if !code.isEmpty { return code }
        return nil
    }

    static func formatDepartureDate(_ date: Date) -> String {
        TicketFormatters.frDate.string(from: date)
    }

    static func formatTime(_ date: Date) -> String {
        TicketFormatters.time.string(from: date)
    }

    static func formatDuration(hours: Int, minutes: Int) -> String {
        if hours <= 0 { return "\(minutes) min" }
        if minutes == 0 { return "\(hours)h" }
        return String(format: "%dh%02d", hours, minutes)
    }

    static func parseTime(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let df = TicketFormatters.timeParser
        for format in ["HH:mm", "H:mm", "HH'h'mm", "HH'h'"] {
            df.dateFormat = format
            if let d = df.date(from: trimmed) { return d }
        }
        return nil
    }

    static func parseDuration(_ raw: String) -> (hours: Int, minutes: Int)? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !t.isEmpty else { return nil }
        if let hIndex = t.firstIndex(of: "h") {
            let h = Int(t[..<hIndex].filter(\.isNumber)) ?? 0
            let rest = t[t.index(after: hIndex)...].filter(\.isNumber)
            let m = Int(rest) ?? 0
            return (h, m)
        }
        if t.contains("min"), let m = Int(t.filter(\.isNumber)) {
            return (0, m)
        }
        return nil
    }

    static func parseDepartureDate(from raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let df = TicketFormatters.dateParser
        for format in ["d MMMM yyyy", "d MMM yyyy", "dd/MM/yyyy", "d/MM/yyyy", "dd/MM/yy", "yyyy-MM-dd"] {
            df.dateFormat = format
            if let d = df.date(from: trimmed) {
                return Calendar.current.startOfDay(for: d)
            }
        }
        return nil
    }
}

extension Flight {
    enum CodingKeys: String, CodingKey {
        case id, tripId, transportMode, code, from, fromCity, to, toCity
        case date, departure, arrival, duration, seat, gate, terminal, company
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tripId = try c.decode(String.self, forKey: .tripId)
        transportMode = try c.decodeIfPresent(TransportMode.self, forKey: .transportMode) ?? .plane
        code = try c.decodeIfPresent(String.self, forKey: .code) ?? ""
        from = try c.decodeIfPresent(String.self, forKey: .from) ?? ""
        fromCity = try c.decodeIfPresent(String.self, forKey: .fromCity) ?? ""
        to = try c.decodeIfPresent(String.self, forKey: .to) ?? ""
        toCity = try c.decodeIfPresent(String.self, forKey: .toCity) ?? ""
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? ""
        departure = try c.decodeIfPresent(String.self, forKey: .departure) ?? ""
        arrival = try c.decodeIfPresent(String.self, forKey: .arrival) ?? ""
        duration = try c.decodeIfPresent(String.self, forKey: .duration) ?? ""
        seat = try c.decodeIfPresent(String.self, forKey: .seat) ?? ""
        gate = try c.decodeIfPresent(String.self, forKey: .gate) ?? ""
        terminal = try c.decodeIfPresent(String.self, forKey: .terminal) ?? ""
        company = try c.decodeIfPresent(String.self, forKey: .company) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(tripId, forKey: .tripId)
        try c.encode(transportMode, forKey: .transportMode)
        try c.encode(code, forKey: .code)
        try c.encode(from, forKey: .from)
        try c.encode(fromCity, forKey: .fromCity)
        try c.encode(to, forKey: .to)
        try c.encode(toCity, forKey: .toCity)
        try c.encode(date, forKey: .date)
        try c.encode(departure, forKey: .departure)
        try c.encode(arrival, forKey: .arrival)
        try c.encode(duration, forKey: .duration)
        try c.encode(seat, forKey: .seat)
        try c.encode(gate, forKey: .gate)
        try c.encode(terminal, forKey: .terminal)
        try c.encode(company, forKey: .company)
    }
}
