import CoreLocation

struct TripGlobeSchedule {
    let departureTime: String
    let arrivalTime: String
    let duration: String
    let dateLine: String?

    static func from(trip: Trip, ticket: Flight?) -> TripGlobeSchedule {
        if let ticket {
            let dep = ticket.departure.trimmingCharacters(in: .whitespacesAndNewlines)
            let arr = ticket.arrival.trimmingCharacters(in: .whitespacesAndNewlines)
            let dur = ticket.duration.trimmingCharacters(in: .whitespacesAndNewlines)
            let date = ticket.date.trimmingCharacters(in: .whitespacesAndNewlines)
            if !dep.isEmpty || !arr.isEmpty || !dur.isEmpty {
                return TripGlobeSchedule(
                    departureTime: dep.isEmpty ? "—" : dep,
                    arrivalTime: arr.isEmpty ? "—" : arr,
                    duration: dur.isEmpty ? "—" : dur,
                    dateLine: date.isEmpty ? trip.displayDate : date
                )
            }
        }
        return TripGlobeSchedule(
            departureTime: "—",
            arrivalTime: "—",
            duration: "—",
            dateLine: trip.homeDateLine
        )
    }

    /// Heure « en vol » interpolée entre départ et arrivée (progress 0…1).
    func timeLabel(at progress: Double) -> String? {
        guard let dep = TravelTicketDraft.parseTime(departureTime),
              let arr = TravelTicketDraft.parseTime(arrivalTime) else { return nil }
        let cal = Calendar.current
        let depMinutes = cal.component(.hour, from: dep) * 60 + cal.component(.minute, from: dep)
        var arrMinutes = cal.component(.hour, from: arr) * 60 + cal.component(.minute, from: arr)
        if arrMinutes < depMinutes { arrMinutes += 24 * 60 }
        let p = max(0, min(1, progress))
        let current = depMinutes + Int(Double(arrMinutes - depMinutes) * p)
        let hour = (current / 60) % 24
        let minute = current % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    var hasClock: Bool {
        TravelTicketDraft.parseTime(departureTime) != nil
            && TravelTicketDraft.parseTime(arrivalTime) != nil
    }
}

enum TripRouteGeometry {
    /// Arc grand cercle entre deux points (même logique que la carte trajet).
    static func greatCirclePath(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        let steps = min(96, max(48, Int(distance / 40_000)))
        return greatCircleCoordinates(from: start, to: end, steps: steps)
    }

    static func greatCircleCoordinates(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        steps: Int
    ) -> [CLLocationCoordinate2D] {
        guard steps > 1 else { return [start, end] }

        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180

        let delta = 2 * asin(
            min(
                1,
                sqrt(
                    pow(sin((lat2 - lat1) / 2), 2)
                        + cos(lat1) * cos(lat2) * pow(sin((lon2 - lon1) / 2), 2)
                )
            )
        )

        guard delta > 0.000_001 else { return [start, end] }

        var samples: [CLLocationCoordinate2D] = []
        samples.reserveCapacity(steps)

        for step in 0..<steps {
            let t = Double(step) / Double(steps - 1)
            if step == 0 {
                samples.append(start)
                continue
            }
            if step == steps - 1 {
                samples.append(end)
                continue
            }

            let a = sin((1 - t) * delta) / sin(delta)
            let b = sin(t * delta) / sin(delta)
            let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
            let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
            let z = a * sin(lat1) + b * sin(lat2)
            let lat = atan2(z, sqrt(x * x + y * y))
            let lon = atan2(y, x)
            samples.append(
                CLLocationCoordinate2D(
                    latitude: lat * 180 / .pi,
                    longitude: lon * 180 / .pi
                )
            )
        }

        return samples
    }

    /// Durée estimée pour l’affichage globe quand aucun billet n’a d’horaires.
    static func estimatedDurationLabel(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        mode: TransportMode
    ) -> String {
        let meters = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        let speedKmh: Double = switch mode {
        case .plane: 780
        case .train: 140
        case .boat: 45
        case .car: 90
        }
        let hours = meters / 1000 / speedKmh
        let totalMinutes = max(15, Int(hours * 60))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return TravelTicketDraft.formatDuration(hours: h, minutes: m)
    }
}

// MARK: - Durée de trajet (listes Voyages)

enum TripTravelDuration {
    static func durationFromClockTimes(_ departure: String, _ arrival: String) -> String? {
        guard let dep = TravelTicketDraft.parseTime(departure),
              let arr = TravelTicketDraft.parseTime(arrival) else { return nil }
        let cal = Calendar.current
        let depMinutes = cal.component(.hour, from: dep) * 60 + cal.component(.minute, from: dep)
        var arrMinutes = cal.component(.hour, from: arr) * 60 + cal.component(.minute, from: arr)
        if arrMinutes <= depMinutes { arrMinutes += 24 * 60 }
        let total = arrMinutes - depMinutes
        guard total > 0 else { return nil }
        return TravelTicketDraft.formatDuration(hours: total / 60, minutes: total % 60)
    }

    static func outboundLeg(trip: Trip, ticket: Flight?) async -> String? {
        if let ticket {
            let stored = ticket.duration.trimmingCharacters(in: .whitespacesAndNewlines)
            if !stored.isEmpty { return stored }
            if let computed = durationFromClockTimes(ticket.departure, ticket.arrival) {
                return computed
            }
        }
        let origin = trip.origin.trimmingCharacters(in: .whitespacesAndNewlines)
        let dest = trip.dest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !origin.isEmpty, !dest.isEmpty,
              let from = await TripPlaceResolver.coordinate(for: origin, mode: trip.transportMode),
              let to = await TripPlaceResolver.coordinate(for: dest, mode: trip.transportMode, near: from)
        else { return nil }
        return TripRouteGeometry.estimatedDurationLabel(from: from, to: to, mode: trip.transportMode)
    }

    static func returnLeg(trip: Trip) async -> String? {
        guard trip.hasReturn else { return nil }
        let dest = trip.dest.trimmingCharacters(in: .whitespacesAndNewlines)
        let retName = trip.returnLocation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !dest.isEmpty, !retName.isEmpty,
              let from = await TripPlaceResolver.coordinate(for: dest, mode: trip.transportMode),
              let to = await TripPlaceResolver.coordinate(for: retName, mode: trip.transportMode, near: from)
        else { return nil }
        return TripRouteGeometry.estimatedDurationLabel(from: from, to: to, mode: trip.transportMode)
    }
}
