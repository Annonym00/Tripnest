import SwiftUI
import UIKit

extension View {
    /// Ajoute une barre « OK » au-dessus du clavier pour le refermer facilement.
    /// Indispensable sur les champs multilignes (notes / descriptions) où la touche
    /// Entrée insère un retour à la ligne au lieu de fermer le clavier.
    func keyboardDoneBar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
                .font(.tText(15, weight: .bold))
                .foregroundColor(.tAccent2)
            }
        }
    }
}

// MARK: - Background gradient & motif ──────────────────────────────────────

struct ScreenBackground: View {
    var body: some View {
        ZStack {
            Color.tBg0
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .tBg2, location: 0.0),
                    .init(color: .tBg1, location: 0.35),
                    .init(color: .tBg0, location: 1.0),
                ]),
                center: UnitPoint(x: 0.5, y: -0.1),
                startRadius: 0, endRadius: 600
            )
        }
    }
}

// Flying paper-plane background — port du composant RN PaperPlanesBackground.tsx
// Rendu via SF Symbol "paperplane.fill" (équivalent iOS d'Ionicons "paper-plane"),
// dessiné dans un Canvas pour les perfs (30 fps, allocations minimales).
enum PaperPlaneVariant { case dark, light }

private struct PlaneFlightConfig {
    let sx, sy, ex, ey: CGFloat
    let dur: Double
    let phase: Double
    let size: CGFloat
    let opacity: Double
    let w1Amp: CGFloat; let w1Freq: Double
    let w2Amp: CGFloat; let w2Freq: Double
    let darkColor: Color
    let lightColor: Color
}

// Tous les avions partagent la même couleur violette.
private let planePurple      = Color(red: 138/255, green: 92/255, blue: 252/255) // 0x8A5CFC
private let planePurpleLight = Color(red: 90/255,  green: 55/255, blue: 130/255).opacity(0.38)

// Ombre discrète : l'opacité du RN (0.3) noyait la couleur sur des glyphes <24pt.
private let planeShadowColor = Color.tAccent2.opacity(0.12)

private let allPlaneConfigs: [PlaneFlightConfig] = [
    .init(sx:-0.15,sy:0.12,ex:1.15,ey:0.08, dur:18,phase:0.00, size:10, opacity:0.78, w1Amp:20,w1Freq:0.6, w2Amp:0, w2Freq:0,  darkColor: planePurple, lightColor: planePurpleLight),
    .init(sx:-0.15,sy:0.55,ex:1.15,ey:0.53, dur:24,phase:0.30, size:13, opacity:0.62, w1Amp:26,w1Freq:0.5, w2Amp:0, w2Freq:0,  darkColor: planePurple, lightColor: planePurpleLight),
    .init(sx:-0.15,sy:0.30,ex:1.15,ey:0.28, dur:15,phase:0.62, size: 9, opacity:0.72, w1Amp:14,w1Freq:0.9, w2Amp:6, w2Freq:3.5,darkColor: planePurple, lightColor: planePurpleLight),
    .init(sx:1.15,sy:0.22,ex:-0.15,ey:0.18, dur:21,phase:0.15, size:11, opacity:0.68, w1Amp:18,w1Freq:0.7, w2Amp:0, w2Freq:0,  darkColor: planePurple, lightColor: planePurpleLight),
    .init(sx:1.15,sy:0.78,ex:-0.15,ey:0.74, dur:17,phase:0.55, size:10, opacity:0.74, w1Amp:16,w1Freq:0.8, w2Amp:6, w2Freq:3.2,darkColor: planePurple, lightColor: planePurpleLight),
    .init(sx:0.25,sy:-0.15,ex:0.32,ey:1.15, dur:20,phase:0.08, size:11, opacity:0.66, w1Amp:18,w1Freq:0.7, w2Amp:0, w2Freq:0,  darkColor: planePurple, lightColor: planePurpleLight),
    .init(sx:0.72,sy:1.15,ex:0.65,ey:-0.15, dur:22,phase:0.38, size: 9, opacity:0.70, w1Amp:14,w1Freq:0.7, w2Amp:5, w2Freq:3.0,darkColor: planePurple, lightColor: planePurpleLight),
    .init(sx:-0.12,sy:0.08,ex:1.12,ey:0.62, dur:26,phase:0.20, size:12, opacity:0.66, w1Amp:18,w1Freq:0.6, w2Amp:0, w2Freq:0,  darkColor: planePurple, lightColor: planePurpleLight),
]

// SF Symbol "paperplane.fill" pointe naturellement vers le coin haut-droit (~45°).
// On compense pour que le nez s'aligne sur la tangente de trajectoire.
private let planeIconOrientationOffset: CGFloat = .pi / 4

struct FlyingPlanesLayer: View {
    /// Si nil, la variante suit l'apparence courante (sombre/clair).
    var variant: PaperPlaneVariant? = nil
    var dimmed: Bool = false
    var active: Bool = true

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.tripnestScreenActive) private var screenActive
    @Environment(\.colorScheme) private var colorScheme

    private var effectiveVariant: PaperPlaneVariant {
        variant ?? (colorScheme == .light ? .light : .dark)
    }

    var body: some View {
        if !active {
            EmptyView()
        } else {
            // Pausé si : app en background, OU onglet invisible (tripnestScreenActive = false).
            // Résultat : 1 seul Canvas actif à la fois au lieu de 4–6 en parallèle.
            let paused = scenePhase != .active || !screenActive
            // 30 fps suffit : les avions dérivent sur 15–26 s, donc le mouvement reste
            // parfaitement lisse à l'œil tout en divisant par deux le coût de rendu.
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { tl in
                Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: false) { ctx, canvasSize in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    let baseTransform = ctx.transform

                    for (index, cfg) in allPlaneConfigs.enumerated() {
                        let phase = (t / cfg.dur + cfg.phase).truncatingRemainder(dividingBy: 1)

                        let sx = canvasSize.width  * cfg.sx, sy = canvasSize.height * cfg.sy
                        let ex = canvasSize.width  * cfg.ex, ey = canvasSize.height * cfg.ey
                        let dx = ex - sx, dy = ey - sy
                        let fwd = max(1, sqrt(dx * dx + dy * dy))
                        let px = -dy / fwd, py = dx / fwd

                        let w = cfg.w1Amp * CGFloat(sin(phase * .pi * 2 * cfg.w1Freq))
                              + cfg.w2Amp * CGFloat(sin(phase * .pi * 2 * cfg.w2Freq))
                        let x = sx + dx * CGFloat(phase) + px * w
                        let y = sy + dy * CGFloat(phase) + py * w

                        let ph2 = (phase + 0.015).truncatingRemainder(dividingBy: 1)
                        let w2  = cfg.w1Amp * CGFloat(sin(ph2 * .pi * 2 * cfg.w1Freq))
                                + cfg.w2Amp * CGFloat(sin(ph2 * .pi * 2 * cfg.w2Freq))
                        let nx  = sx + dx * CGFloat(ph2) + px * w2
                        let ny  = sy + dy * CGFloat(ph2) + py * w2
                        let angle = CGFloat(atan2(Double(ny - y), Double(nx - x))) + planeIconOrientationOffset

                        guard let symbol = ctx.resolveSymbol(id: index) else { continue }

                        ctx.transform = baseTransform
                        ctx.translateBy(x: x, y: y)
                        ctx.rotate(by: .radians(angle))
                        ctx.opacity = cfg.opacity * (dimmed ? 0.22 : 1.0)
                        ctx.draw(symbol, at: .zero, anchor: .center)
                    }

                    ctx.transform = baseTransform
                    ctx.opacity = 1
                } symbols: {
                    ForEach(Array(allPlaneConfigs.enumerated()), id: \.offset) { index, cfg in
                        PaperPlaneGlyph(
                            size: cfg.size,
                            color: effectiveVariant == .light ? cfg.lightColor : cfg.darkColor
                        )
                        .tag(index)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct PaperPlaneGlyph: View {
    let size: CGFloat
    let color: Color
    var body: some View {
        Image(systemName: "paperplane.fill")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
            // Effet lumineux baked une seule fois dans le bitmap du symbol (zéro coût par frame).
            // Halo interne serré + bloom extérieur diffus → lueur violette néon.
            .shadow(color: planePurple.opacity(0.95), radius: size * 0.55, x: 0, y: 0)
            .shadow(color: planePurple.opacity(0.40), radius: size * 1.40, x: 0, y: 0)
    }
}

/// Avion en papier statique — partage le même glyphe que la couche animée.
struct PaperPlaneSilhouette: View {
    var fill: Color = .tAccent2
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Image(systemName: "paperplane.fill")
                .resizable()
                .scaledToFit()
                .frame(width: s, height: s)
                .foregroundStyle(fill)
                .shadow(color: planeShadowColor, radius: 3, x: 0, y: 1)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

// MARK: - Screen shell ──────────────────────────────────────────────────────

struct ScreenShell<Content: View>: View {
    var motif: Bool = true
    @ViewBuilder var content: () -> Content
    @Environment(\.tripnestSkipShellMotion) private var skipShellMotion
    @Environment(\.tripnestOnboardingEmbedded) private var onboardingEmbedded
    @State private var appeared = false

    var body: some View {
        Group {
            if onboardingEmbedded {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    ScreenBackground().ignoresSafeArea()
                    FlyingPlanesLayer().ignoresSafeArea()
                    content()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(appeared || skipShellMotion ? 1 : 0.94)
                        .offset(y: appeared || skipShellMotion ? 0 : 10)
                        .scaleEffect(appeared || skipShellMotion ? 1 : 0.992)
                }
                .onAppear { appeared = true }
                .onDisappear { appeared = false }
                .animation(skipShellMotion ? nil : TripnestAnimation.soft, value: appeared)
            }
        }
        .foregroundColor(.tText)
    }
}

// MARK: - Motion system ─────────────────────────────────────────────────────

enum TripnestAnimation {
    /// Changement d’écran principal (push / pop).
    static let page = Animation.easeOut(duration: 0.22)
    /// Onglets Accueil / Voyages / Budget / Profil (couche persistante, pas d’anim lourde).
    static let tab = Animation.easeOut(duration: 0.12)
    /// Formulaires modaux (nouveau / modifier voyage, dépense).
    static let modal = Animation.spring(response: 0.34, dampingFraction: 0.92, blendDuration: 0)
    static let progress = Animation.spring(response: 0.62, dampingFraction: 0.78, blendDuration: 0.1)
    static let soft = Animation.spring(response: 0.5, dampingFraction: 0.86)
    static let press = Animation.spring(response: 0.26, dampingFraction: 0.78)
    /// Dépense cochée / décochée — montants et anneau budget.
    static let budgetMoney = Animation.spring(response: 0.48, dampingFraction: 0.76, blendDuration: 0.08)
    static let budgetCheckbox = Animation.spring(response: 0.32, dampingFraction: 0.58)
}

enum OnboardingScreenTransition {
    static func push(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: PageMotionModifier(offsetX: forward ? 18 : -18, opacity: 0),
                identity: PageMotionModifier()
            ),
            removal: .modifier(
                active: PageMotionModifier(offsetX: forward ? -10 : 10, opacity: 0),
                identity: PageMotionModifier()
            )
        )
    }
}

private struct PageMotionModifier: ViewModifier {
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .offset(x: offsetX, y: offsetY)
            .opacity(opacity)
    }
}

enum TripnestPageTransition {
    static func horizontal(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: PageMotionModifier(offsetX: forward ? 10 : -10, opacity: 0),
                identity: PageMotionModifier()
            ),
            removal: .modifier(
                active: PageMotionModifier(offsetX: forward ? -6 : 6, opacity: 0),
                identity: PageMotionModifier()
            )
        )
    }

    static var tab: AnyTransition {
        .identity
    }

    static var modal: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: PageMotionModifier(offsetY: 16, opacity: 0),
                identity: PageMotionModifier()
            ),
            removal: .modifier(
                active: PageMotionModifier(offsetY: 10, opacity: 0),
                identity: PageMotionModifier()
            )
        )
    }
}

// MARK: - Voyage terminé (case à cocher)

enum TripDoneStatusStyle {
    case hero
    case card
    case detail
}

struct TripDoneStatusControl: View {
    var isDone: Bool
    var style: TripDoneStatusStyle = .card
    var onChange: (Bool) -> Void

    private var label: String { isDone ? "Voyage fait" : "En cours" }
    private var accent: Color { isDone ? .tGold : .tMint }

    var body: some View {
        Button {
            onChange(!isDone)
            Haptics.selection()
        } label: {
            HStack(spacing: style == .hero ? 6 : 8) {
                checkbox
                Text(label)
                    .font(.tText(fontSize, weight: .bold))
                    .tracking(style == .hero ? 1.2 : 0)
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(background)
            .overlay(overlay)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDone ? "Voyage terminé" : "Voyage en cours")
        .accessibilityValue(isDone ? "Coché" : "Non coché")
    }

    private var fontSize: CGFloat {
        switch style {
        case .hero: return 10
        case .card: return 11
        case .detail: return 10
        }
    }

    private var horizontalPadding: CGFloat {
        style == .hero || style == .detail ? 10 : 0
    }

    private var verticalPadding: CGFloat {
        style == .hero || style == .detail ? 6 : 0
    }

    private var textColor: Color {
        switch style {
        case .hero: return accent
        case .card: return accent
        case .detail: return accent
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .hero:
            Capsule().fill(Color.black.opacity(0.34))
        case .card:
            EmptyView()
        case .detail:
            Capsule().fill(accent.opacity(0.12))
        }
    }

    @ViewBuilder
    private var overlay: some View {
        if style == .detail {
            Capsule().stroke(accent.opacity(0.25), lineWidth: 1)
        }
    }

    private var checkbox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isDone ? accent : Color.clear)
                .frame(width: boxSize, height: boxSize)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(isDone ? accent : checkboxStroke, lineWidth: isDone ? 0 : 1.5)
                .frame(width: boxSize, height: boxSize)
            if isDone {
                TIcon(glyph: .check, size: checkSize, stroke: checkStroke, strokeWidth: 2.2)
            }
        }
    }

    private var boxSize: CGFloat { style == .hero ? 18 : 20 }
    private var checkSize: CGFloat { style == .hero ? 11 : 12 }
    private var checkStroke: Color { style == .hero ? .white : .white }

    private var checkboxStroke: Color {
        switch style {
        case .hero: return Color.white.opacity(0.55)
        case .card: return Color.tBorderStrong
        case .detail: return accent.opacity(0.45)
        }
    }
}

struct TripnestPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(TripnestAnimation.press, value: configuration.isPressed)
    }
}

private struct TripnestSkipShellMotionKey: EnvironmentKey {
    static let defaultValue = false
}

private struct TripnestOnboardingEmbeddedKey: EnvironmentKey {
    static let defaultValue = false
}

private struct TripnestUsesExternalChromeKey: EnvironmentKey {
    static let defaultValue = false
}

// Signale aux FlyingPlanesLayer que l'écran courant est actif.
// Les onglets inactifs mettent cette clé à false → leur TimelineView est pausé.
private struct TripnestScreenActiveKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var tripnestSkipShellMotion: Bool {
        get { self[TripnestSkipShellMotionKey.self] }
        set { self[TripnestSkipShellMotionKey.self] = newValue }
    }

    var tripnestOnboardingEmbedded: Bool {
        get { self[TripnestOnboardingEmbeddedKey.self] }
        set { self[TripnestOnboardingEmbeddedKey.self] = newValue }
    }

    var tripnestUsesExternalChrome: Bool {
        get { self[TripnestUsesExternalChromeKey.self] }
        set { self[TripnestUsesExternalChromeKey.self] = newValue }
    }

    var tripnestScreenActive: Bool {
        get { self[TripnestScreenActiveKey.self] }
        set { self[TripnestScreenActiveKey.self] = newValue }
    }
}

// MARK: - Card ───────────────────────────────────────────────────────────────

struct TCard<Content: View>: View {
    var padding: CGFloat = 18
    var glow: Bool = false
    var radius: CGFloat = Tk.radius
    // Gradient pré-composé opaque (équivalent visuel de 0x8b5cf6 @ 10%/4% sur tBg1) :
    // bloque les avions d'arrière-plan tout en gardant le tint lavande des cartes.
    var bg: AnyShapeStyle = AnyShapeStyle(
        LinearGradient(colors: [
            Color(hex: 0x21123e),
            Color(hex: 0x1a0d32),
        ], startPoint: .top, endPoint: .bottom)
    )
    var border: Color = .tBubbleBorder
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(border, lineWidth: colorScheme.tBubbleLineWidth)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius - 1, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .light ? 0 : 0.03), lineWidth: 0.6)
                    .padding(1)
            )
            .shadow(color: Color.tAccent2.opacity(0.06), radius: 8, x: 0, y: 0)
            .shadow(color: glow ? Color(hex: 0x0f0523, opacity: 0.4) : .clear,
                    radius: glow ? 18 : 0, x: 0, y: glow ? 18 : 0)
    }
}

private struct BubbleChromeModifier: ViewModifier {
    let radius: CGFloat
    let border: Color?
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let strokeColor = border ?? .tBubbleBorder
        return content
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(strokeColor, lineWidth: colorScheme.tBubbleLineWidth)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius - 1, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .light ? 0 : 0.03), lineWidth: 0.6)
                    .padding(1)
            )
            .shadow(color: Color.tAccent2.opacity(colorScheme == .light ? 0.10 : 0.06),
                    radius: 8, x: 0, y: 0)
    }
}

extension View {
    /// `border == nil` ⇒ utilise `tBubbleBorder` (adaptatif, marqué en clair).
    func tripnestBubbleChrome(radius: CGFloat, border: Color? = nil) -> some View {
        modifier(BubbleChromeModifier(radius: radius, border: border))
    }
}

struct IconBubble: View {
    let glyph: TIcon.Glyph
    var color: Color = .tAccent2
    var size: CGFloat = 44
    var glyphScale: CGFloat = 0.46

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(color.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(color.opacity(0.28), lineWidth: 1)
                )
            TIcon(glyph: glyph, size: size * glyphScale, stroke: color, strokeWidth: 2)
        }
        .frame(width: size, height: size)
    }
}

func tripnestGlyph(for symbol: String?) -> TIcon.Glyph {
    switch symbol {
    case "wallet": return .wallet
    case "map", "globe": return .globe
    case "camera": return .cam
    case "gallery", "photos": return .gallery
    case "plane": return .plane
    case "list", "sheet", "notes", "calculator": return .trips
    case "user", "mind", "unknown", "calm": return .user
    case "calendar", "time", "weather": return .cal
    case "bell": return .bell
    case "spot": return .spot
    case "target": return .filter
    case "gift": return .gift
    case "star", "strong", "growth": return .star
    case "food": return .food
    case "hotel": return .hotel
    case "bus": return .bus
    case "ticket": return .ticket
    default: return .globe
    }
}

// MARK: - Pill ───────────────────────────────────────────────────────────────

struct TPill: View {
    let label: String
    var active: Bool = false
    var color: Color = .tAccent
    var action: (() -> Void)? = nil
    @State private var localActive: Bool

    init(label: String, active: Bool = false, color: Color = .tAccent, action: (() -> Void)? = nil) {
        self.label = label
        self.active = active
        self.color = color
        self.action = action
        self._localActive = State(initialValue: active)
    }

    var body: some View {
        let isActive = action == nil ? localActive : active
        Button(action: {
            if let action {
                action()
            } else {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                    localActive.toggle()
                }
            }
        }) {
            Text(label)
                .font(.tText(13, weight: .semibold))
                .foregroundColor(isActive ? .white : .tText)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(
                    Capsule().fill(isActive ? color : Color(hex: 0x24173f))
                )
                .overlay(
                    Capsule().stroke(isActive ? color : Color.tAccent2.opacity(0.55), lineWidth: 1.2)
                )
                .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isActive)
        }
        .buttonStyle(TripnestPressStyle())
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Progress Ring ──────────────────────────────────────────────────────

struct ProgressRing<Content: View>: View {
    let value: Double
    let max: Double
    var size: CGFloat = 130
    var stroke: CGFloat = 12
    var color: Color = .tAccent
    var trackColor: Color = Color(hex: 0x2b1d49)
    @ViewBuilder var content: () -> Content

    var body: some View {
        let pct = min(1, value / Swift.max(max, 0.001))
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: stroke)
            Circle()
                .trim(from: 0, to: pct)
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(TripnestAnimation.budgetMoney, value: pct)
            Circle()
                .fill(color)
                .frame(width: stroke * 1.55, height: stroke * 1.55)
                .shadow(color: color.opacity(0.75), radius: stroke * 0.9)
                .overlay {
                    Circle()
                        .stroke(color.opacity(0.35), lineWidth: 2)
                        .frame(width: stroke * 2.35, height: stroke * 2.35)
                        .scaleEffect(1.12)
                }
                .offset(y: -size / 2)
                .rotationEffect(.degrees(pct * 360))
                .animation(TripnestAnimation.budgetMoney, value: pct)
            content()
        }
        .frame(width: size, height: size)
        .animation(TripnestAnimation.budgetMoney, value: value)
    }
}

/// Montant entier animé (budget, dépenses).
struct AnimatedCurrencyAmount: View {
    let value: Int
    let symbol: String
    var font: Font = .tDisplay(26)
    var tracking: CGFloat = -0.6
    var color: Color = .tText
    var prefix: String = ""

    var body: some View {
        Text("\(prefix)\(value)\(symbol)")
            .font(font)
            .tracking(tracking)
            .foregroundColor(color)
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(value)))
            .animation(TripnestAnimation.budgetMoney, value: value)
    }
}

/// Badge flottant +/− lors d’un changement de dépense effectuée.
struct BudgetMoneyDeltaBadge: View {
    let amount: Int
    let symbol: String
    /// Dépensé qui augmente (coche « effectuée »).
    let spentIncreased: Bool

    var body: some View {
        let sign = spentIncreased ? "+" : "−"
        let tint: Color = spentIncreased ? .tRose : .tMint
        Text("\(sign)\(amount)\(symbol)")
            .font(.tText(14, weight: .bold))
            .foregroundColor(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.14)))
            .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
            .transition(
                .opacity.combined(with: .scale(scale: 0.85))
            )
    }
}

// MARK: - Destination photo placeholder ──────────────────────────────────────

struct DestPhoto: View {
    let label: String
    var hue: Double = 270
    var radius: CGFloat = 16

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(hue: hue / 360, saturation: 0.55, brightness: 0.55),
                    Color(hue: (hue + 20) / 360, saturation: 0.6, brightness: 0.28),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            DiagonalStripes()
                .opacity(0.5)
            HStack(spacing: 4) {
                TIcon(glyph: .cam, size: 12, stroke: .white.opacity(0.6))
                Text(label.uppercased())
                    .font(.tMono(10))
                    .tracking(0.5)
            }
            .foregroundColor(Color.white.opacity(0.6))
            .padding(.horizontal, 12).padding(.bottom, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.tBorder, lineWidth: 1)
        )
    }
}

struct DiagonalStripes: View {
    var body: some View {
        Canvas { ctx, rect in
            let spacing: CGFloat = 14
            let max = (rect.width + rect.height)
            ctx.rotate(by: .degrees(135))
            for x in stride(from: -max, to: max, by: spacing) {
                var p = Path()
                p.move(to: CGPoint(x: x, y: -max))
                p.addLine(to: CGPoint(x: x, y: max))
                ctx.stroke(p, with: .color(Color.white.opacity(0.04)), lineWidth: 1)
            }
        }
    }
}

// MARK: - Logo ───────────────────────────────────────────────────────────────

struct TripnestLogo: View {
    var size: CGFloat = 84
    var glow: Bool = true
    var body: some View {
        Image("AppLogo")
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(Color(hex: 0xa78bfa, opacity: 0.18), lineWidth: 1)
            )
            .shadow(color: glow ? Color(hex: 0x8b5cf6, opacity: 0.45) : .clear,
                    radius: 18, x: 0, y: 18)
    }
}

// MARK: - Dépense — cases statut

struct ExpenseStatusCheckboxRow: View {
    let title: String
    let subtitle: String
    let isChecked: Bool
    var tint: Color = .tAccent2
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isChecked ? tint : Color.clear)
                        .frame(width: 24, height: 24)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isChecked ? tint : Color.tBorderStrong, lineWidth: isChecked ? 0 : 1.5)
                        .frame(width: 24, height: 24)
                    if isChecked {
                        TIcon(glyph: .check, size: 13, stroke: .white, strokeWidth: 2.5)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }
                }
                .scaleEffect(isChecked ? 1.08 : 1)
                .animation(TripnestAnimation.budgetCheckbox, value: isChecked)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.tText(15, weight: .semibold))
                        .foregroundColor(.tText)
                    Text(subtitle)
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab bar ────────────────────────────────────────────────────────────

enum AppRoute: String, Hashable, CaseIterable {
    case home, trips, completedTrips, add, newTrip, editTrip, budget, tripBudget, profile, trip, tripPlanning, tripSouvenirs, flights, spots, newSpot, memories, tripNotes

    var tabIndex: Int? {
        switch self {
        case .home: return 0
        case .trips: return 1
        case .budget: return 2
        case .profile: return 3
        default: return nil
        }
    }

    var isTabRoot: Bool { tabIndex != nil }
    var isModal: Bool { self == .add || self == .newTrip || self == .editTrip }
    var supportsSwipeBack: Bool {
        switch self {
        case .home, .trips, .budget, .profile, .add, .newTrip, .editTrip:
            return false
        case .newSpot:
            return false
        case .spots:
            return true
        case .tripBudget:
            return true
        default:
            return true
        }
    }
}

enum NavMotion: Equatable {
    case tab(forward: Bool)
    case push
    case pop
    case modal

    var transition: AnyTransition {
        switch self {
        case .tab:
            return TripnestPageTransition.tab
        case .push:
            return TripnestPageTransition.horizontal(forward: true)
        case .pop:
            return TripnestPageTransition.horizontal(forward: false)
        case .modal:
            return TripnestPageTransition.modal
        }
    }
}

enum AppNavigator {
    static func motion(from: AppRoute, to: AppRoute) -> NavMotion {
        if to.isModal || from.isModal { return .modal }
        if let fromTab = from.tabIndex, let toTab = to.tabIndex { return .tab(forward: toTab > fromTab) }
        if to.tabIndex != nil && !from.isTabRoot { return .pop }
        return .push
    }
}

struct SwipeBackModifier: ViewModifier {
    let enabled: Bool
    let onBack: () -> Void
    @State private var dragX: CGFloat = 0

    func body(content: Content) -> some View {
        let progress = min(1, max(0, dragX / 120))
        content
            .offset(x: enabled ? dragX : 0)
            .scaleEffect(enabled ? 1 - progress * 0.018 : 1, anchor: .leading)
            .opacity(enabled ? 1 - Double(progress) * 0.12 : 1)
            .gesture(
                DragGesture(minimumDistance: 14, coordinateSpace: .local)
                    .onChanged { value in
                        guard enabled, value.translation.width > 0,
                              abs(value.translation.width) > abs(value.translation.height) * 0.65 else { return }
                        dragX = min(value.translation.width, 140)
                    }
                    .onEnded { value in
                        guard enabled else { return }
                        if value.translation.width > 80 || value.predictedEndTranslation.width > 150 {
                            withAnimation(TripnestAnimation.page) {
                                dragX = 0
                                onBack()
                            }
                        } else {
                            withAnimation(TripnestAnimation.page) { dragX = 0 }
                        }
                    }
            )
    }
}

extension View {
    func swipeBack(enabled: Bool, onBack: @escaping () -> Void) -> some View {
        modifier(SwipeBackModifier(enabled: enabled, onBack: onBack))
    }

    /// Marge basse du contenu scrollable au-dessus d’une TabBar en `safeAreaInset`.
    func tripnestTabBarScrollPadding() -> some View {
        padding(.bottom, TripnestLayout.tabBarScrollBreathing)
    }

    /// Pas de rebond si le contenu tient dans l’écran (évite le vide scrollable en bas).
    func tripnestScrollBounceWhenNeeded() -> some View {
        scrollBounceBehavior(.basedOnSize, axes: .vertical)
    }
}

struct TabBar: View {
    let active: AppRoute
    var centerRoute: AppRoute = .newTrip
    var centerLabel: String = ""
    var centerAccessibilityLabel: String = "Nouveau voyage"
    var onChange: (AppRoute) -> Void = { _ in }

    private struct Tab { let id: AppRoute; let label: String; let glyph: TIcon.Glyph }
    private let tabs: [Tab] = [
        Tab(id: .home,    label: "Accueil",  glyph: .home),
        Tab(id: .trips,   label: "Voyages",  glyph: .globe),
        Tab(id: .add,     label: "",         glyph: .plus),
        Tab(id: .budget,  label: "Budget",   glyph: .wallet),
        Tab(id: .profile, label: "Profil",   glyph: .user),
    ]

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                let t = tabs[i]
                if t.id == .add {
                    Button(action: { Haptics.impact(.medium); onChange(centerRoute) }) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.tAccent.opacity(0.22))
                                    .frame(width: 70, height: 70)
                                    .blur(radius: 10)

                                Circle()
                                    .fill(RadialGradient(
                                        colors: [
                                            Color.tAccent.opacity(0.34),
                                            Color.tAccent2.opacity(0.14),
                                            Color.clear,
                                        ],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 36
                                    ))
                                    .frame(width: 68, height: 68)

                                ZStack {
                                    Circle().fill(LinearGradient(
                                        colors: [.tAccent2, .tAccentDeep],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    Image(systemName: "plus")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 54, height: 54)
                                .overlay(Circle().stroke(Color.tBg1, lineWidth: 3))
                                .shadow(color: Color.tAccent.opacity(0.32), radius: 8, x: 0, y: 0)
                                .shadow(color: Color.tAccent2.opacity(0.22), radius: 14, x: 0, y: 6)
                            }
                            .frame(width: 68, height: 56)
                            .offset(y: -6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(TripnestPressStyle())
                    .accessibilityLabel(centerAccessibilityLabel)
                } else {
                    let isActive = active == t.id
                    Button(action: { if !isActive { Haptics.selection() }; onChange(t.id) }) {
                        VStack(spacing: 4) {
                            TIcon(glyph: t.glyph, size: 23,
                                  stroke: isActive ? .tAccent2 : .tTextMute,
                                  strokeWidth: isActive ? 2 : 1.6)
                            Text(L(t.label))
                                .font(.tText(10, weight: .semibold))
                                .tracking(0.2)
                                .foregroundColor(isActive ? .tAccent2 : .tTextMute)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(TripnestPressStyle())
                    .accessibilityLabel(L(t.label))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 0)
        .background(
            LinearGradient(stops: [
                .init(color: Color.tBg0.opacity(0), location: 0),
                .init(color: Color.tBg0.opacity(0.85), location: 0.4),
                .init(color: Color.tBg0.opacity(0.98), location: 1),
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
    }
}

// MARK: - Icon button ────────────────────────────────────────────────────────

/// Résumé complet d’un voyage (planification, etc.).
struct TripInfoSummaryCard: View {
    let trip: Trip
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"

    private var statusLabel: String {
        switch trip.status {
        case .active: return "En cours"
        case .planned: return "Planifié"
        case .done: return "Terminé"
        }
    }

    var body: some View {
        TCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    TripPhoto(
                        destination: trip.dest,
                        country: trip.country,
                        hue: trip.hue,
                        radius: 12,
                        coverKind: trip.coverKind,
                        tripId: trip.id,
                        solidColor: trip.resolvedCoverColor
                    )
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.displayTitle)
                            .font(.tText(17, weight: .bold))
                        Text(trip.homeDestinationTitle)
                            .font(.tText(13))
                            .foregroundColor(.tTextMute)
                        Text(statusLabel)
                            .font(.tText(11, weight: .bold))
                            .foregroundColor(.tAccent2)
                    }
                }

                Divider().background(Color.tBorder)

                infoRow("Trajet", trip.origin.isEmpty ? trip.dest : trip.routeLine)
                infoRow("Dates", trip.tripSubtitle)
                if trip.hasReturn, let ret = trip.homeReturnLine {
                    infoRow("Retour", ret)
                }
                infoRow("Transport", trip.transportMode.label)
                infoRow("Durée", "\(trip.days) jour\(trip.days > 1 ? "s" : "")")
                infoRow("Budget", "\(trip.spent)\(defaultCurrency.currencySymbol) / \(trip.budget)\(defaultCurrency.currencySymbol)")
                infoRow("Photos", "\(trip.photoCount) souvenir\(trip.photoCount > 1 ? "s" : "")")
                if !trip.country.isEmpty, trip.country != "À définir" {
                    infoRow("Pays", "\(trip.flag) \(trip.country)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.tText(12, weight: .semibold))
                .foregroundColor(.tTextMute)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.tText(13, weight: .medium))
                .foregroundColor(.tText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Barre sous-page : titre à gauche, réglages (optionnel) puis **Retour** en haut à droite.
struct TripSubpageTopBar: View {
    let title: String
    let subtitle: String
    var onSettings: (() -> Void)? = nil
    var onBack: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.tDisplay(24))
                    .tracking(-0.5)
                    .foregroundColor(.tText)
                Text(subtitle)
                    .font(.tText(13))
                    .foregroundColor(.tTextMute)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let onSettings {
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.tTextMute)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.tSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.tBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(TripnestPressStyle())
                .accessibilityLabel("Réglages")
            }
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Text("Retour")
                        .font(.tText(13, weight: .bold))
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.tText)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.tSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.tBorder, lineWidth: 1)
                )
            }
            .buttonStyle(TripnestPressStyle())
            .accessibilityLabel("Retour")
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

struct IconBtn: View {
    let glyph: TIcon.Glyph
    var dot: Bool = false
    var stroke: Color = .tText
    var strokeWidth: CGFloat = 1.75
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.tSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.tBorder, lineWidth: 1)
                    )
                TIcon(glyph: glyph, size: 20, stroke: stroke, strokeWidth: strokeWidth)
            }
            .frame(width: 40, height: 40)
            if dot {
                Circle()
                    .fill(Color.tRose)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.tBg1, lineWidth: 2))
                    .padding(.top, 8).padding(.trailing, 9)
            }
        }
    }
}

// MARK: - Avatar ─────────────────────────────────────────────────────────────

struct Avatar: View {
    var initials: String = "?"
    var size: CGFloat = 40
    var image: UIImage? = nil

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle().fill(LinearGradient(
                    colors: [.tAccent2, .tRose],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                Text(initials)
                    .font(.tText(14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.tBorderStrong, lineWidth: 2))
    }
}

// MARK: - Field ──────────────────────────────────────────────────────────────

struct TField: View {
    let label: String
    let placeholder: String
    var value: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.tText(12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.tTextMute)
            HStack {
                Text(value.isEmpty ? placeholder : value)
                    .font(.tText(16))
                    .foregroundColor(value.isEmpty ? .tTextDim : .tText)
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: 0x1b0e34))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tBorderStrong, lineWidth: 1)
            )
        }
    }
}

// MARK: - CTA ────────────────────────────────────────────────────────────────

struct CTA: View {
    @Environment(\.tripnestDefaultCTAAction) private var defaultAction
    @Environment(\.tripnestCanAdvance) private var canAdvance

    let label: String
    var ghost: Bool = false
    var secondary: Bool = false
    var height: CGFloat = 56
    var fontSize: CGFloat = 16
    var action: (() -> Void)? = nil

    /// Une étape-question sans réponse bloque uniquement le bouton "avancer"
    /// (celui qui n'a pas d'action explicite).
    private var gated: Bool { action == nil && !canAdvance }

    var body: some View {
        if ghost {
            Button(action: { (action ?? defaultAction)() }) {
                Text(label)
                    .font(.tText(14, weight: .bold))
                    .foregroundColor(.tTextMute)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(TripnestPressStyle())
            .opacity(gated ? 0.4 : 1)
            .disabled(gated)
        } else {
            Button(action: { (action ?? defaultAction)() }) {
                Text(label)
                    .font(.tText(fontSize, weight: .bold))
                    .tracking(-0.2)
                    .foregroundColor(gated ? .tTextDim : (secondary ? .tText : .white))
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(gated || secondary
                                ? AnyShapeStyle(Color.tSurface)
                                : AnyShapeStyle(LinearGradient(
                                    colors: [.tAccent2, .tAccentDeep],
                                    startPoint: .top, endPoint: .bottom)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(gated || secondary ? Color.tBorderStrong : Color(hex: 0xa78bfa, opacity: 0.4),
                                    lineWidth: 1)
                    )
                    .shadow(color: (gated || secondary) ? .clear : Color.tAccent.opacity(0.35),
                            radius: 12, x: 0, y: 12)
            }
            .buttonStyle(TripnestPressStyle())
            .disabled(gated)
        }
    }
}

private struct TripnestDefaultCTAActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct TripnestBackActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct TripnestOnboardingStepKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

private struct TripnestCanAdvanceKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var tripnestDefaultCTAAction: () -> Void {
        get { self[TripnestDefaultCTAActionKey.self] }
        set { self[TripnestDefaultCTAActionKey.self] = newValue }
    }

    var tripnestBackAction: () -> Void {
        get { self[TripnestBackActionKey.self] }
        set { self[TripnestBackActionKey.self] = newValue }
    }

    var tripnestOnboardingStep: Int {
        get { self[TripnestOnboardingStepKey.self] }
        set { self[TripnestOnboardingStepKey.self] = newValue }
    }

    /// Faux uniquement sur une étape-question dont la réponse obligatoire manque.
    /// Vrai partout ailleurs (écrans informatifs, sliders, actions explicites).
    var tripnestCanAdvance: Bool {
        get { self[TripnestCanAdvanceKey.self] }
        set { self[TripnestCanAdvanceKey.self] = newValue }
    }
}

// MARK: - SocialBtn ──────────────────────────────────────────────────────────

struct SocialBtn: View {
    @Environment(\.tripnestDefaultCTAAction) private var defaultAction
    let label: String
    var dark: Bool = false

    var body: some View {
        Button(action: defaultAction) {
            HStack(spacing: 10) {
                if dark {
                    Image(systemName: "applelogo")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                } else {
                    ZStack {
                        Circle().fill(AngularGradient(
                            colors: [
                                Color(hex: 0xea4335), Color(hex: 0xfbbc05),
                                Color(hex: 0x34a853), Color(hex: 0x4285f4),
                                Color(hex: 0xea4335),
                            ],
                            center: .center
                        ))
                        Text("G")
                            .font(.tText(11, weight: .black))
                            .foregroundColor(.white)
                    }
                    .frame(width: 20, height: 20)
                }
                Text(label)
                    .font(.tText(15, weight: .bold))
            }
            .foregroundColor(dark ? .white : .tBg0)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(dark ? Color.black : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
