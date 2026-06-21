import SwiftUI

@main
struct TripnestApp: App {
    @StateObject private var purchases = PurchasesManager.shared

    init() {
        PurchasesManager.configureIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(purchases)
                .tripnestPreferredColorScheme()
                .background(Color.tBg0.ignoresSafeArea())
        }
    }
}
