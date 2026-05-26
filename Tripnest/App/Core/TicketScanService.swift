import UIKit
import Vision

enum TicketScanService {
    static func scan(image: UIImage, mode: TransportMode) async -> TravelTicketDraft? {
        guard let cgImage = image.cgImage else { return nil }
        let text = await recognizeText(from: cgImage)
        guard !text.isEmpty else { return nil }
        return parse(text: text, mode: mode)
    }

    private static func recognizeText(from image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let lines = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["fr-FR", "en-US"]

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    static func parse(text: String, mode: TransportMode) -> TravelTicketDraft {
        let upper = text.uppercased()
        let lines = text.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }

        var draft = TravelTicketDraft()

        if let code = firstMatch(in: upper, pattern: #"\b([A-Z]{2})\s?(\d{1,4}[A-Z]?)\b"#) {
            draft.code = code.replacingOccurrences(of: " ", with: "")
        } else if mode == .train,
                  let train = firstMatch(in: upper, pattern: #"\b(TGV|TER|ICE|AVE|OUIGO)[\s-]?(\d{1,4})\b"#) {
            draft.code = train.replacingOccurrences(of: " ", with: "")
        }

        let airportCodes = allMatches(in: upper, pattern: #"\b[A-Z]{3}\b"#)
            .filter { !reservedCodes.contains($0) }
        if airportCodes.count >= 2 {
            draft.from = airportCodes[0]
            draft.to = airportCodes[1]
        }

        let times = allMatches(in: text, pattern: #"\b([01]?\d|2[0-3])[:h\.]([0-5]\d)\b"#)
            .map { $0.replacingOccurrences(of: "H", with: ":").replacingOccurrences(of: ".", with: ":") }
        if let first = times.first { draft.departure = first }
        if times.count > 1 { draft.arrival = times[1] }

        if let duration = firstMatch(in: text, pattern: #"\b(\d{1,2}\s?h\s?\d{0,2})\b"#, options: .caseInsensitive) {
            draft.duration = duration.replacingOccurrences(of: " ", with: "")
        }

        if let seat = firstMatch(in: upper, pattern: #"\b([1-9][0-9]?[A-K])\b"#) {
            draft.seat = seat
        }
        if let gate = firstMatch(in: upper, pattern: #"\b(GATE|PORTE)\s*([A-Z]?\d{1,3}[A-Z]?)\b"#) {
            draft.gate = gate
        } else if let gateOnly = firstMatch(in: upper, pattern: #"\b([A-Z]?\d{1,2}[A-Z])\b"#) {
            draft.gate = gateOnly
        }
        if let terminal = firstMatch(in: upper, pattern: #"\b(TERMINAL|TERM\.?)\s*([0-9A-Z]{1,3})\b"#) {
            draft.terminal = terminal
        }

        draft.date = extractDateLine(from: lines) ?? ""

        let companies = airlineCompanies + ferryCompanies + trainCompanies
        for line in lines {
            let lineUp = line.uppercased()
            if let company = companies.first(where: { lineUp.contains($0) }) {
                draft.company = company.capitalized
                break
            }
        }

        if draft.fromCity.isEmpty, airportCodes.count >= 1 {
            draft.fromCity = cityLabel(for: draft.from, in: lines, fallback: "Départ")
        }
        if draft.toCity.isEmpty, airportCodes.count >= 2 {
            draft.toCity = cityLabel(for: draft.to, in: lines, fallback: "Arrivée")
        }

        if mode == .boat, draft.code.isEmpty,
           let ref = firstMatch(in: upper, pattern: #"\b(FERRY|TRAVERSEE|CROSSING)\s*#?(\w+)\b"#) {
            draft.code = ref
        }

        return draft
    }

    private static let reservedCodes: Set<String> = [
        "THE", "AND", "FOR", "VIA", "EST", "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"
    ]

    private static let airlineCompanies = [
        "AIR FRANCE", "RYANAIR", "EASYJET", "LUFTHANSA", "EMIRATES", "TAP", "TRANSAVIA",
        "BRITISH AIRWAYS", "IBERIA", "VUELING", "SWISS", "KLM", "DELTA", "UNITED"
    ]
    private static let ferryCompanies = [
        "BRITTANY FERRIES", "CORSICA FERRIES", "MOBY", "GRIMALDI", "DFDS", "STENA"
    ]
    private static let trainCompanies = [
        "SNCF", "TGV", "EUROSTAR", "THALYS", "OUIGO", "ITALO", "TRENITALIA", "DEUTSCHE BAHN"
    ]

    private static func extractDateLine(from lines: [String]) -> String? {
        for line in lines {
            if line.range(of: #"\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}"#, options: .regularExpression) != nil {
                return line
            }
            let lower = line.lowercased()
            if lower.contains("jan") || lower.contains("fév") || lower.contains("fev")
                || lower.contains("mar") || lower.contains("avr") || lower.contains("mai")
                || lower.contains("jun") || lower.contains("jui") || lower.contains("aoû")
                || lower.contains("aou") || lower.contains("sep") || lower.contains("oct")
                || lower.contains("nov") || lower.contains("déc") || lower.contains("dec"),
               line.range(of: #"\d"#, options: .regularExpression) != nil {
                return line
            }
        }
        return nil
    }

    private static func cityLabel(for code: String, in lines: [String], fallback: String) -> String {
        guard !code.isEmpty else { return fallback }
        for line in lines where line.uppercased().contains(code) {
            let cleaned = line.replacingOccurrences(of: code, with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.count > 2 { return cleaned }
        }
        return fallback
    }

    private static func firstMatch(
        in text: String,
        pattern: String,
        options: NSRegularExpression.Options = []
    ) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        if match.numberOfRanges > 1,
           let r = Range(match.range(at: 1), in: text) {
            var result = String(text[r])
            if match.numberOfRanges > 2, let r2 = Range(match.range(at: 2), in: text) {
                result += String(text[r2])
            }
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let r = Range(match.range, in: text) {
            return String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private static func allMatches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard let r = Range(match.range, in: text) else { return nil }
            return String(text[r])
        }
    }
}
