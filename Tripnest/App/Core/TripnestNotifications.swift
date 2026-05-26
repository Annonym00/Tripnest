import UIKit
import UserNotifications

enum TripnestNotificationStatus: Equatable {
    case notDetermined
    case denied
    case authorized

    var isEnabled: Bool { self == .authorized }

    var settingsLabel: String {
        switch self {
        case .notDetermined: return "À activer"
        case .denied: return "Désactivées"
        case .authorized: return "Activées"
        }
    }
}

@MainActor
enum TripnestNotifications {
    static func currentStatus() async -> TripnestNotificationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        default:
            return .notDetermined
        }
    }

    /// Demande l'autorisation iOS, ou ouvre Réglages si l'utilisateur a déjà refusé.
    @discardableResult
    static func activate() async -> TripnestNotificationStatus {
        let status = await currentStatus()
        if status == .denied {
            await openSettings()
            return await currentStatus()
        }
        if status == .authorized {
            return .authorized
        }
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted { return .authorized }
        } catch {}
        return await currentStatus()
    }

    private static func openSettings() async {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        await UIApplication.shared.open(url)
    }
}
