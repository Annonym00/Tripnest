import SwiftUI

// Ordre du funnel : chaque valeur est l'identifiant d'un écran V2_xx.
// Réordonner ou retirer une valeur suffit à changer le parcours.
let onboardingFunnel: [Int] = [
    1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12,
    17, 18, 19, 20, 21, 23, 25, 26, 29
]

let OB_TOTAL = onboardingFunnel.count

final class OnboardingNavigator: ObservableObject {
    // DEBUG: TN_START_STEP permet de démarrer l'onboarding à une position donnée
    // pour itérer sur le design. À retirer avant la livraison.
    @Published var step: Int = {
        if let raw = ProcessInfo.processInfo.environment["TN_START_STEP"],
           let s = Int(raw) { return min(max(s, 1), OB_TOTAL) }
        return 1
    }()
    @Published var direction: Int = 1
    @Published var barProgress: CGFloat = 1 / CGFloat(OB_TOTAL)

    init() { barProgress = CGFloat(step) / CGFloat(OB_TOTAL) }

    var progress: CGFloat { barProgress }
}

enum OnboardingLabels {
    static func label(for step: Int) -> String? {
        switch step {
        case 4: return "Tu n'es pas seul·e"
        case 16: return "Tu as ce qu'il faut"
        case 17: return "Fonctions clés"
        case 18: return "Ton espace"
        case 19: return "On y est presque"
        case 20: return "Construction · 1/4"
        case 21: return "Construction · 2/4"
        case 22: return "Ton profil voyageur"
        case 23: return "Ton plan"
        case 24: return "Projection"
        case 25: return "Notifications"
        case 26: return "Sauvegarde"
        case 27: return "Récapitulatif"
        default: return nil
        }
    }
}

// MARK: - Fixed chrome (barre + retour) ───────────────────────────────────────

struct OnboardingChromeBar: View {
    @EnvironmentObject private var navigator: OnboardingNavigator
    @Environment(\.tripnestBackAction) private var backAction

    var body: some View {
        HStack(spacing: 0) {
            Button(action: backAction) {
                ZStack {
                    Circle().fill(Color.tSurface)
                        .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
                    TIcon(glyph: .back, size: 14, stroke: .tTextMute)
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(TripnestPressStyle())
            .opacity(navigator.step > 1 ? 1 : 0.35)
            .disabled(navigator.step <= 1)

            VStack(alignment: .leading, spacing: 6) {
                OBProgressTrack()
                Text(stepCaption)
                    .font(.tText(10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.tTextDim)
                    .contentTransition(.numericText())
                    .animation(TripnestAnimation.progress, value: navigator.step)
            }
            .padding(.horizontal, 14)

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private var stepCaption: String {
        let base = "Étape \(navigator.step) / \(OB_TOTAL)"
        let position = min(max(navigator.step, 1), OB_TOTAL)
        let screenID = onboardingFunnel[position - 1]
        guard let label = OnboardingLabels.label(for: screenID) else { return base }
        return "\(base) · \(label.uppercased())"
    }
}

struct OBProgressTrack: View {
    @EnvironmentObject private var navigator: OnboardingNavigator

    var body: some View {
        GeometryReader { geo in
            let fill = max(10, geo.size.width * navigator.barProgress)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: 0x291c47))
                    .frame(height: 5)
                Capsule()
                    .fill(LinearGradient(
                        colors: [.tAccent2, .tAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: fill, height: 5)
                    .shadow(color: Color.tAccent.opacity(0.35), radius: 4, y: 1)

                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.tAccent2.opacity(0.45), lineWidth: 1))
                    .shadow(color: Color.tAccent2.opacity(0.85), radius: 5, y: 1)
                    .offset(x: max(0, fill - 5))
            }
        }
        .frame(height: 10)
        .animation(TripnestAnimation.progress, value: navigator.barProgress)
    }
}

final class OnboardingState: ObservableObject {
    @Published var single: [Int: String] { didSet { save() } }
    @Published var multiple: [Int: Set<String>] { didSet { save() } }
    @Published var sliders: [Int: Double] { didSet { save() } }

    private let singleKey = "tripnest.onboarding.single"
    private let multipleKey = "tripnest.onboarding.multiple"
    private let slidersKey = "tripnest.onboarding.sliders"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.single = Self.load([Int: String].self, key: singleKey, defaults: defaults) ?? [:]
        let storedMultiple = Self.load([Int: [String]].self, key: multipleKey, defaults: defaults) ?? [:]
        self.multiple = storedMultiple.mapValues { Set($0) }
        self.sliders = Self.load([Int: Double].self, key: slidersKey, defaults: defaults) ?? [:]
    }

    func selectSingle(_ label: String, step: Int) {
        single[step] = label
    }

    func isSingleSelected(_ label: String, step: Int, fallback: Bool) -> Bool {
        if let selected = single[step] {
            return selected == label
        }
        return fallback
    }

    func toggleMultiple(_ label: String, step: Int) {
        var values = multiple[step] ?? []
        if values.contains(label) {
            values.remove(label)
        } else {
            values.insert(label)
        }
        multiple[step] = values
    }

    func isMultipleSelected(_ label: String, step: Int, fallback: Bool) -> Bool {
        if let values = multiple[step] {
            return values.contains(label)
        }
        return fallback
    }

    func setSlider(_ value: Double, step: Int) {
        sliders[step] = min(100, max(0, value))
    }

    func slider(step: Int, fallback: Double) -> Double {
        sliders[step] ?? fallback
    }

    private func save() {
        Self.save(single, key: singleKey, defaults: defaults)
        Self.save(multiple.mapValues { Array($0).sorted() }, key: multipleKey, defaults: defaults)
        Self.save(sliders, key: slidersKey, defaults: defaults)
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

// MARK: - Header with progress bar ──────────────────────────────────────────

struct OBHeader: View {
    @Environment(\.tripnestUsesExternalChrome) private var usesExternalChrome
    let step: Int
    var label: String? = nil

    var body: some View {
        if usesExternalChrome {
            Color.clear.frame(height: 2)
        } else {
            legacyHeader
        }
    }

    private var legacyHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 32, height: 32)
            Text("Étape \(step) / \(OB_TOTAL)\(label.map { " · \($0.uppercased())" } ?? "")")
                .font(.tText(10, weight: .bold))
                .tracking(1)
                .foregroundColor(.tTextDim)
                .frame(maxWidth: .infinity)
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 22).padding(.top, 6)
    }
}

// MARK: - Question screen template ──────────────────────────────────────────

struct OBQuestion<Content: View, Footer: View>: View {
    let step: Int
    var label: String? = nil
    var subtitle: String? = nil
    let title: AnyView
    var hint: String? = nil
    var cta: String = "Continuer"
    var secondary: String? = nil
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: step, label: label)
                VStack(alignment: .leading, spacing: 0) {
                    if let s = subtitle {
                        Text(s)
                            .font(.tText(11, weight: .bold)).tracking(2)
                            .foregroundColor(.tAccent2)
                    }
                    title
                        .font(.tDisplay(26))
                        .tracking(-0.8)
                        .padding(.top, 8)
                    if let h = hint {
                        Text(h).font(.tText(13))
                            .foregroundColor(.tTextMute).padding(.top, 6)
                    }
                    Spacer().frame(height: 20)
                    ScrollView(showsIndicators: false) {
                        content()
                    }
                    footer()
                    VStack(spacing: 6) {
                        if let s = secondary {
                            CTA(label: s, ghost: true)
                        }
                        CTA(label: cta)
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 26)
                .padding(.top, 20).padding(.bottom, 28)
            }
        }
    }
}

extension OBQuestion where Footer == EmptyView {
    init(step: Int, label: String? = nil, subtitle: String? = nil,
         title: AnyView, hint: String? = nil, cta: String = "Continuer",
         secondary: String? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.step = step
        self.label = label
        self.subtitle = subtitle
        self.title = title
        self.hint = hint
        self.cta = cta
        self.secondary = secondary
        self.content = content
        self.footer = { EmptyView() }
    }
}

// MARK: - Option cards ──────────────────────────────────────────────────────

struct OptCard: View {
    @EnvironmentObject private var onboarding: OnboardingState
    @Environment(\.tripnestOnboardingStep) private var step
    let emoji: String?
    let label: String
    var detail: String? = nil
    var active: Bool = false
    var color: Color = .tAccent2
    var action: (() -> Void)? = nil
    @State private var localActive: Bool

    init(emoji: String?, label: String, detail: String? = nil, active: Bool = false, color: Color = .tAccent2, action: (() -> Void)? = nil) {
        self.emoji = emoji
        self.label = label
        self.detail = detail
        self.active = active
        self.color = color
        self.action = action
        self._localActive = State(initialValue: active)
    }

    var body: some View {
        let isActive = action == nil
            ? onboarding.isSingleSelected(label, step: step, fallback: localActive)
            : active
        Button(action: {
            if let action {
                action()
            } else {
                localActive = true
                onboarding.selectSingle(label, step: step)
            }
        }) {
            HStack(spacing: 14) {
                if let e = emoji {
                    IconBubble(glyph: tripnestGlyph(for: e), color: color, size: 42)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.tText(15, weight: .bold))
                    if let d = detail {
                        Text(d).font(.tText(12)).foregroundColor(.tTextMute)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isActive ? color : Color.clear)
                        .overlay(Circle().stroke(isActive ? color : Color.tBorder, lineWidth: 1.5))
                    if isActive {
                        TIcon(glyph: .check, size: 13, stroke: .white, strokeWidth: 3)
                    }
                }
                .frame(width: 22, height: 22)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isActive ? color.opacity(0.11) : Color.tSurface))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isActive ? color : Color.tBorder, lineWidth: isActive ? 1.5 : 1))
            .shadow(color: isActive ? color.opacity(0.2) : .clear, radius: 12, x: 0, y: 12)
        }
        .buttonStyle(.plain)
        .onAppear {
            if action == nil, active, onboarding.single[step] == nil {
                onboarding.selectSingle(label, step: step)
            }
        }
    }
}

struct MultiCard: View {
    @EnvironmentObject private var onboarding: OnboardingState
    @Environment(\.tripnestOnboardingStep) private var step
    let emoji: String?
    let label: String
    var detail: String? = nil
    var active: Bool = false
    var color: Color = .tAccent2
    var action: (() -> Void)? = nil
    @State private var localActive: Bool

    init(emoji: String?, label: String, detail: String? = nil, active: Bool = false, color: Color = .tAccent2, action: (() -> Void)? = nil) {
        self.emoji = emoji
        self.label = label
        self.detail = detail
        self.active = active
        self.color = color
        self.action = action
        self._localActive = State(initialValue: active)
    }

    var body: some View {
        let isActive = action == nil
            ? onboarding.isMultipleSelected(label, step: step, fallback: localActive)
            : active
        Button(action: {
            if let action {
                action()
            } else {
                localActive.toggle()
                onboarding.toggleMultiple(label, step: step)
            }
        }) {
            HStack(spacing: 12) {
                if let e = emoji {
                    IconBubble(glyph: tripnestGlyph(for: e), color: color, size: 38)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.tText(14, weight: .bold))
                    if let d = detail {
                        Text(d).font(.tText(11)).foregroundColor(.tTextMute)
                    }
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isActive ? color : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(isActive ? color : Color.tBorder, lineWidth: 1.5))
                    if isActive {
                        TIcon(glyph: .check, size: 13, stroke: .white, strokeWidth: 3)
                    }
                }
                .frame(width: 22, height: 22)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isActive ? color.opacity(0.11) : Color.tSurface))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isActive ? color : Color.tBorder, lineWidth: isActive ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .onAppear {
            if action == nil, active, onboarding.multiple[step]?.contains(label) != true {
                var values = onboarding.multiple[step] ?? []
                values.insert(label)
                onboarding.multiple[step] = values
            }
        }
    }
}

// MARK: - Slider ────────────────────────────────────────────────────────────

struct OBSlider: View {
    @EnvironmentObject private var onboarding: OnboardingState
    @Environment(\.tripnestOnboardingStep) private var step
    let pct: Double
    var trackColors: [Color] = [.tAccent2, .tAccent]
    var thumbBorder: Color = .tAccent
    @State private var localPct: Double?

    var body: some View {
        GeometryReader { geo in
            let value = min(100, max(0, localPct ?? onboarding.slider(step: step, fallback: pct)))
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0x2b1d49))
                    .frame(height: 8)
                Capsule().fill(LinearGradient(
                    colors: trackColors,
                    startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(value) / 100, height: 8)
                Circle().fill(Color.white)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(thumbBorder, lineWidth: 3))
                    .shadow(color: Color.tAccent.opacity(0.4), radius: 6)
                    .position(x: max(14, min(geo.size.width - 14,
                                             geo.size.width * CGFloat(value) / 100)),
                              y: 4)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let next = Double(gesture.location.x / max(1, geo.size.width) * 100)
                        localPct = min(100, max(0, next))
                        onboarding.setSlider(localPct ?? pct, step: step)
                    }
            )
        }
        .frame(height: 28)
        .onAppear {
            if onboarding.sliders[step] == nil {
                onboarding.setSlider(pct, step: step)
            }
        }
    }
}

// MARK: - Big gradient number ───────────────────────────────────────────────

struct GradientNumber: View {
    let text: String
    var size: CGFloat = 78
    var colors: [Color] = [.white, .tAccent2]

    var body: some View {
        Text(text)
            .font(.tDisplay(size))
            .tracking(-3.5)
            .foregroundStyle(
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            )
    }
}

// MARK: - Auto-advance loading steps (20–21) ────────────────────────────────

enum OBLoadingRunner {
    @MainActor
    static func start(
        duration: TimeInterval = 2.8,
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping () -> Void
    ) -> Task<Void, Never> {
        onProgress(0)
        return Task {
            let steps = 24
            let stepNanos = UInt64((duration / Double(steps)) * 1_000_000_000)
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: stepNanos)
                guard !Task.isCancelled else { return }
                let pct = Double(i) / Double(steps) * 100
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        onProgress(pct)
                    }
                }
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { onComplete() }
        }
    }
}

// MARK: - Insights dérivés des réponses (personnalisation = conversion) ───────
//
// Renvoie aux utilisateurs LEURS propres réponses sur les écrans-récompense.
// Aucune donnée inventée : tout vient de ce qu'ils ont saisi dans le funnel.

struct OnboardingInsights {
    let companion: String?          // étape 5
    let frequency: String?          // étape 6
    let objective: String?          // étape 11
    let overspentBefore: String?    // étape 7
    let dreamDestinations: [String] // étape 13
    let avgBudget: Int              // étape 12
    let savingsGoal: Int            // étape 15
    let overspend: Int              // étape 8
    private let destinationRaw: String // étape 14

    init(state: OnboardingState, defaults: UserDefaults = .standard) {
        companion = state.single[5]
        frequency = state.single[6]
        objective = state.single[11]
        overspentBefore = state.single[7]
        dreamDestinations = Array(state.multiple[13] ?? []).sorted()
        avgBudget = Int(500 + state.slider(step: 12, fallback: 25) / 100 * (6000 - 500))
        savingsGoal = Int(100 + state.slider(step: 15, fallback: 27) / 100 * (2000 - 100))
        overspend = Int(50 + state.slider(step: 8, fallback: 23) / 100 * (1500 - 50))
        destinationRaw = (defaults.string(forKey: "tripnest.onboarding.destination") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Voyages par an déduits de l'étape 6 — relie la fréquence au calcul de perte.
    var tripsPerYear: Int {
        switch frequency {
        case "Plusieurs fois par an":       return 4
        case "Une à deux fois par an":      return 2
        case "Un grand voyage par an":      return 1
        case "Plus rarement, mais je rêve": return 1
        default:                            return 4
        }
    }

    /// Perte annuelle = dépassement moyen (étape 8) × voyages par an (étape 6).
    var annualLoss: Int { overspend * tripsPerYear }

    var destination: String {
        if !destinationRaw.isEmpty { return destinationRaw }
        if let first = dreamDestinations.first(where: { $0 != "À définir" }) { return first }
        return "ton prochain voyage"
    }

    var hasRealDestination: Bool {
        !destinationRaw.isEmpty || dreamDestinations.contains { $0 != "À définir" }
    }

    var dreamCount: Int { dreamDestinations.count }

    /// Archétype voyageur dérivé du compagnon de voyage (payoff type quiz de perso).
    var profileType: String {
        switch companion {
        case "Solo":        return "Explorateur solo"
        case "En couple":   return "Duo aventurier"
        case "En famille":  return "Capitaine de famille"
        case "Entre amis":  return "Chef de bande"
        default:            return "Voyageur organisé"
        }
    }

    var profileTagline: String {
        switch companion {
        case "Solo":        return "Tu voyages en autonomie et tu veux garder la main sur chaque euro."
        case "En couple":   return "À deux, tu veux profiter sans exploser le budget commun."
        case "En famille":  return "Tu jongles avec tout — et tu veux enfin un budget qui tient."
        case "Entre amis":  return "Tu organises pour le groupe : clarté et zéro mauvaise surprise."
        default:            return "Tu aimes l'autonomie, mais tu veux garder le contrôle de ton budget."
        }
    }

    func euros(_ v: Int) -> String {
        "\(v.formatted(.number.locale(Locale(identifier: "fr_FR"))))\u{00a0}€"
    }
}
