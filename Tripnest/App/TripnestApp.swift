import SwiftUI

@main
struct TripnestApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tripnestPreferredColorScheme()
                .background(Color.tBg0.ignoresSafeArea())
        }
    }
}
