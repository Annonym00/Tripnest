import SwiftUI

struct RootView: View {
    @StateObject private var store = TripStore()
    @StateObject private var localizer = Localizer.shared
    @StateObject private var avatarStore = ProfileImageStore.shared
    @AppStorage("tripnest.didFinishOnboarding") private var didFinishOnboarding = false

    var body: some View {
        Group {
            if didFinishOnboarding {
                MainApp(onLogout: resetApp)
            } else {
                OnboardingFlow {
                    didFinishOnboarding = true
                }
            }
        }
        .environmentObject(store)
        .environmentObject(localizer)
        .environmentObject(avatarStore)
        .environment(\.locale, localizer.language.locale)
        .id(localizer.language)
        .task {
            TransportPlaceCatalog.warmUp()
        }
    }

    private func resetApp() {
        didFinishOnboarding = false
    }
}

struct OnboardingFlow: View {
    @EnvironmentObject private var store: TripStore
    var onFinish: () -> Void = {}
    @StateObject private var onboarding = OnboardingState()
    @StateObject private var navigator = OnboardingNavigator()

    var body: some View {
        ZStack {
            ScreenBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingChromeBar()

                ZStack {
                    screen(for: navigator.step)
                        .id(navigator.step)
                        .transition(.identity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
        }
        .environmentObject(navigator)
        .environmentObject(onboarding)
        .environment(\.tripnestOnboardingEmbedded, true)
        .environment(\.tripnestUsesExternalChrome, true)
        .environment(\.tripnestSkipShellMotion, true)
        .environment(\.tripnestDefaultCTAAction, advance)
        .environment(\.tripnestBackAction, goBack)
        .environment(\.tripnestOnboardingStep, navigator.step)
    }

    private func advance() {
        if navigator.step >= OB_TOTAL {
            createTripFromOnboardingIfNeeded()
            onFinish()
            return
        }
        let next = navigator.step + 1
        navigator.direction = 1
        withAnimation(TripnestAnimation.progress) {
            navigator.barProgress = CGFloat(next) / CGFloat(OB_TOTAL)
        }
        navigator.step = next
    }

    private func goBack() {
        guard navigator.step > 1 else { return }
        let previous = navigator.step - 1
        navigator.direction = -1
        withAnimation(TripnestAnimation.progress) {
            navigator.barProgress = CGFloat(previous) / CGFloat(OB_TOTAL)
        }
        navigator.step = previous
    }

    private func createTripFromOnboardingIfNeeded() {
        let defaults = UserDefaults.standard
        let destination = defaults.string(forKey: "tripnest.onboarding.destination")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !destination.isEmpty, store.trips.isEmpty else { return }

        let startDate = defaults.string(forKey: "tripnest.onboarding.startDate")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let departure = parseOnboardingDate(startDate)
        store.addTrip(
            origin: "",
            destination: destination,
            departureDate: departure,
            returnLocation: nil,
            returnDate: nil,
            transportMode: .plane
        )
    }

    private static let _onboardingDateFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); return f
    }()

    private func parseOnboardingDate(_ text: String) -> Date? {
        guard !text.isEmpty else { return nil }
        let f = Self._onboardingDateFmt
        for format in ["d MMM yyyy", "dd/MM/yyyy", "yyyy-MM-dd"] {
            f.dateFormat = format
            if let date = f.date(from: text) { return date }
        }
        return nil
    }

    @ViewBuilder
    private func screen(for step: Int) -> some View {
        let position = min(max(step, 1), OB_TOTAL)
        let screenID = onboardingFunnel[position - 1]
        switch screenID {
        case 1: V2_01(); case 2: V2_02(); case 3: V2_03()
        case 4: V2_04(); case 5: V2_05(); case 6: V2_06()
        case 7: V2_07(); case 8: V2_08(); case 9: V2_09()
        case 10: V2_10(); case 11: V2_11(); case 12: V2_12()
        case 13: V2_13(); case 14: V2_14(); case 15: V2_15()
        case 16: V2_16(); case 17: V2_17(); case 18: V2_18()
        case 19: V2_19(); case 20: V2_20(); case 21: V2_21()
        case 22: V2_22(); case 23: V2_23(); case 24: V2_24()
        case 25: V2_25(); case 26: V2_26(); case 27: V2_27()
        case 28: V2_28(); default: V2_29()
        }
    }
}
