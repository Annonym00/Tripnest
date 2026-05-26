import SwiftUI

@main
struct TripnestApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .background(Color.tBg0.ignoresSafeArea())
        }
    }
}
