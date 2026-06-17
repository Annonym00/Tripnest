import Foundation
import UserNotifications

// MARK: - Préférences (planification uniquement)

enum TripPlanNotificationPrefs {
    static let leadMinutes = 60

    private static func key(tripId: String, _ suffix: String) -> String {
        "tripnest.plan.\(tripId).\(suffix)"
    }

    static func activitiesEnabled(tripId: String) -> Bool {
        UserDefaults.standard.object(forKey: key(tripId: tripId, "activities")) as? Bool ?? false
    }

    static func setActivitiesEnabled(_ value: Bool, tripId: String) {
        UserDefaults.standard.set(value, forKey: key(tripId: tripId, "activities"))
    }

    static func departureEnabled(tripId: String) -> Bool {
        UserDefaults.standard.object(forKey: key(tripId: tripId, "departure")) as? Bool ?? false
    }

    static func setDepartureEnabled(_ value: Bool, tripId: String) {
        UserDefaults.standard.set(value, forKey: key(tripId: tripId, "departure"))
    }
}

// MARK: - Planification des rappels locaux

@MainActor
enum TripPlanNotifications {
    private static let frLocale = Locale(identifier: "fr_FR")

    static func sync(trip: Trip, store: TripStore) async {
        await cancelAll(for: trip.id)

        let status = await TripnestNotifications.currentStatus()
        guard status.isEnabled else { return }

        if TripPlanNotificationPrefs.departureEnabled(tripId: trip.id) {
            scheduleDepartureReminder(for: trip)
        }

        if TripPlanNotificationPrefs.activitiesEnabled(tripId: trip.id) {
            let items = store.planItems.filter { $0.tripId == trip.id }
            for item in items {
                scheduleActivityReminder(item: item, trip: trip)
            }
        }
    }

    static func cancelAll(for tripId: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix("plan.\(tripId).") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func scheduleDepartureReminder(for trip: Trip) {
        guard let departure = trip.departureDate else { return }
        let fire = departure.addingTimeInterval(-Double(TripPlanNotificationPrefs.leadMinutes * 60))
        guard fire > Date() else { return }

        let dateLabel = departure.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(frLocale))
        let content = UNMutableNotificationContent()
        content.title = L("Départ dans 1 h")
        content.body = L("Ton voyage vers %@ · %@", trip.homeDestinationTitle, dateLabel.capitalized)
        content.sound = .default

        let id = "plan.\(trip.id).departure"
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fire
            ),
            repeats: false
        )
        centerAdd(id: id, content: content, trigger: trigger)
    }

    private static func scheduleActivityReminder(item: TripPlanItem, trip: Trip) {
        guard let day = TripPlanCalendar.date(from: item.dayKey),
              let activityDate = combine(day: day, time: item.time) else { return }

        let fire = activityDate.addingTimeInterval(-Double(TripPlanNotificationPrefs.leadMinutes * 60))
        guard fire > Date() else { return }

        let dayLabel = day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(frLocale))
        let content = UNMutableNotificationContent()
        content.title = L("Dans 1 h : %@", item.title)
        content.body = "\(trip.homeDestinationTitle) · \(dayLabel.capitalized)"
        if !item.notes.isEmpty {
            content.subtitle = String(item.notes.prefix(120))
        }
        content.sound = .default

        let id = "plan.\(trip.id).activity.\(item.id)"
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fire
            ),
            repeats: false
        )
        centerAdd(id: id, content: content, trigger: trigger)
    }

    private static func combine(day: Date, time: String) -> Date? {
        let parts = time.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    private static func centerAdd(id: String, content: UNMutableNotificationContent, trigger: UNNotificationTrigger) {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
