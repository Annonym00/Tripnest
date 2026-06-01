import SwiftUI
import UIKit

// MARK: - TripPhoto (fond voyage)

struct TripPhoto: View {
    let destination: String
    let country: String
    var hue: Double = 270
    var radius: CGFloat = 16
    var showBorder: Bool = true
    var coverKind: TripCoverKind = .none
    var tripId: String? = nil
    var previewImage: UIImage? = nil
    /// Couleur de fond pour un voyage sans photo personnalisée. `nil` → couleur dérivée de `hue`.
    var solidColor: Color? = nil
    var fallbackLeadingFlag: String = ""
    var fallbackTrailingFlag: String = ""

    @State private var storedCustomImage: UIImage?

    private var displayedImage: UIImage? {
        guard coverKind == .custom else { return nil }
        return previewImage ?? storedCustomImage
    }

    var body: some View {
        ZStack {
            colorCover

            if let img = displayedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .layoutPriority(-1)
            }

            DiagonalStripes()
                .opacity(coverKind == .custom ? 0.38 : 0.85)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            if showBorder {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.tBorder, lineWidth: 1)
            }
        }
        .task(id: customLoadKey) {
            await loadCustomImageIfNeeded()
        }
    }

    private var colorCover: some View {
        Rectangle().fill(
            LinearGradient(
                colors: coverGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var coverGradientColors: [Color] {
        if let solidColor {
            // Légère ombre en bas-droite pour donner du relief sans perdre l'identité de la couleur.
            return [solidColor, solidColor.opacity(0.78)]
        }
        let base = Color(hue: hue / 360, saturation: 0.72, brightness: 0.80)
        let deep = Color(hue: (hue + 14) / 360, saturation: 0.78, brightness: 0.66)
        return [base, deep]
    }

    private var customLoadKey: String {
        let id = tripId ?? ""
        let coverToken = coverKind == .custom ? TripCoverImageStore.modificationToken(tripId: id) : "none"
        return "\(coverKind.rawValue)|\(id)|\(coverToken)"
    }

    @MainActor
    private func loadCustomImageIfNeeded() async {
        guard coverKind == .custom, previewImage == nil, let tripId else {
            storedCustomImage = nil
            return
        }
        // Disk I/O on background — never block the main thread for image loads.
        let loaded = await Task.detached(priority: .userInitiated) {
            TripCoverImageStore.load(tripId: tripId)
        }.value
        storedCustomImage = loaded
    }
}

private struct RouteCountryColorWash: View {
    let leadingFlag: String
    let trailingFlag: String
    let hue: Double

    private var leadingPalette: RouteColorPalette {
        RouteColorPalette.palette(for: leadingFlag, fallbackHue: hue)
    }

    private var trailingPalette: RouteColorPalette {
        RouteColorPalette.palette(for: trailingFlag, fallbackHue: hue + 28)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base : diagonale claire entre les deux couleurs.
                LinearGradient(
                    stops: [
                        .init(color: leadingPalette.base, location: 0.00),
                        .init(color: leadingPalette.base, location: 0.18),
                        .init(color: trailingPalette.base, location: 0.82),
                        .init(color: trailingPalette.base, location: 1.00),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Couleur d'origine : marquée sur la gauche, s'efface au centre.
                LinearGradient(
                    stops: [
                        .init(color: leadingPalette.primary.opacity(0.95), location: 0.00),
                        .init(color: leadingPalette.primary.opacity(0.65), location: 0.20),
                        .init(color: leadingPalette.secondary.opacity(0.35), location: 0.40),
                        .init(color: .clear, location: 0.60),
                        .init(color: .clear, location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // Couleur destination : symétrique, marquée sur la droite.
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.00),
                        .init(color: .clear, location: 0.40),
                        .init(color: trailingPalette.secondary.opacity(0.35), location: 0.60),
                        .init(color: trailingPalette.primary.opacity(0.65), location: 0.80),
                        .init(color: trailingPalette.primary.opacity(0.95), location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                Ellipse()
                    .fill(leadingPalette.glow.opacity(0.50))
                    .frame(width: geo.size.width * 0.72, height: geo.size.height * 0.86)
                    .blur(radius: 36)
                    .offset(x: -geo.size.width * 0.28, y: -geo.size.height * 0.08)

                Ellipse()
                    .fill(trailingPalette.glow.opacity(0.50))
                    .frame(width: geo.size.width * 0.72, height: geo.size.height * 0.86)
                    .blur(radius: 36)
                    .offset(x: geo.size.width * 0.28, y: geo.size.height * 0.08)

                RadialGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        trailingPalette.secondary.opacity(0.12),
                        .clear
                    ],
                    center: UnitPoint(x: 0.62, y: 0.28),
                    startRadius: 8,
                    endRadius: geo.size.width * 0.52
                )
                .blendMode(.screen)

                LinearGradient(
                    colors: [
                        .clear,
                            Color.black.opacity(0.06),
                            trailingPalette.secondary.opacity(0.18),
                            Color.black.opacity(0.04),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.46)
                .blur(radius: 22)

                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.032))
                        .frame(width: geo.size.width * 0.11)
                        .rotationEffect(.degrees(-18))
                        .offset(x: -geo.size.width * 0.54 + CGFloat(index) * geo.size.width * 0.31)
                }

                LinearGradient(
                    stops: [
                            .init(color: Color.black.opacity(0.06), location: 0.00),
                            .init(color: .clear, location: 0.60),
                            .init(color: .clear, location: 1.00),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.16),
                        Color.white.opacity(0.04),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

private struct RouteColorPalette {
    let base: Color
    let primary: Color
    let secondary: Color
    let glow: Color

    static func palette(for flag: String, fallbackHue: Double) -> RouteColorPalette {
        switch flag {
        case "🇫🇷":
            return .init(base: c(0x2367C7), primary: c(0x4A93FF), secondary: c(0xF24D63), glow: c(0x82B8FF))
        case "🇺🇸":
            return .init(base: c(0x82385C), primary: c(0xEF4F73), secondary: c(0x5896D8), glow: c(0xFF7591))
        case "🇵🇹":
            return .init(base: c(0x1F8255), primary: c(0x18C677), secondary: c(0xEF3C45), glow: c(0xFF5F66))
        case "🇲🇦":
            return .init(base: c(0x9F2D3B), primary: c(0xEF4750), secondary: c(0x1FB67A), glow: c(0xFF6A72))
        case "🇯🇵":
            return .init(base: c(0x923D5E), primary: c(0xE7345A), secondary: c(0xFFE0E0), glow: c(0xFF4A72))
        case "🇮🇹":
            return .init(base: c(0x1C8C5B), primary: c(0x1FCE83), secondary: c(0xEF4854), glow: c(0x4BE49B))
        case "🇪🇸":
            return .init(base: c(0xC07418), primary: c(0xE94347), secondary: c(0xFCD345), glow: c(0xFFE066))
        case "🇬🇧":
            return .init(base: c(0x2A47A8), primary: c(0x4467D7), secondary: c(0xEF4564), glow: c(0x82A1FF))
        case "🇧🇷":
            return .init(base: c(0x1C8B42), primary: c(0x21D070), secondary: c(0xFCDE57), glow: c(0x42E689))
        case "🇨🇦":
            return .init(base: c(0xA2303A), primary: c(0xEF4F4A), secondary: c(0xFCE2E2), glow: c(0xFF6A5E))
        default:
            let base = Color(hue: fallbackHue / 360, saturation: 0.78, brightness: 0.52)
            let primary = Color(hue: fallbackHue / 360, saturation: 0.82, brightness: 0.70)
            let secondary = Color(hue: (fallbackHue + 34) / 360, saturation: 0.74, brightness: 0.62)
            return .init(base: base, primary: primary, secondary: secondary, glow: primary)
        }
    }

    private static func c(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

private enum RouteFlagSide {
    case leading, trailing, full
}

private struct RouteFlagArtwork: View {
    let flag: String
    let hue: Double
    var side: RouteFlagSide = .full

    private var code: String? { Self.regionCode(from: flag) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                artwork

                LinearGradient(
                    colors: [
                        .white.opacity(0.10),
                        .clear,
                        .black.opacity(0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.035))
                        .frame(width: geo.size.width * 0.12)
                        .rotationEffect(.degrees(-18))
                        .offset(x: -geo.size.width * 0.45 + CGFloat(index) * geo.size.width * 0.28)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
        .opacity(side == .trailing ? 0.88 : 1)
        .saturation(1.06)
        .contrast(1.04)
    }

    @ViewBuilder
    private var artwork: some View {
        switch code {
        case "FR": verticalBands([c(0x0055A4), .white, c(0xEF4135)])
        case "IT": verticalBands([c(0x009246), .white, c(0xCE2B37)])
        case "IE": verticalBands([c(0x169B62), .white, c(0xFF883E)])
        case "BE": verticalBands([c(0x111111), c(0xFFD90C), c(0xEF3340)])
        case "DE": horizontalBands([c(0x111111), c(0xDD0000), c(0xFFCE00)])
        case "NL": horizontalBands([c(0xAE1C28), .white, c(0x21468B)])
        case "ES": horizontalBands([c(0xAA151B), c(0xF1BF00), c(0xF1BF00), c(0xAA151B)])
        case "US": UnitedStatesFlag(cantonAlignment: side == .trailing ? .topTrailing : .topLeading)
        case "JP": circleFlag(background: .white, circle: c(0xBC002D), scale: 0.40)
        case "CA": verticalBands([c(0xD52B1E), .white, .white, c(0xD52B1E)])
        case "PT": portugalFlag
        case "MA": moroccoFlag
        case "CH": swissFlag
        case "GB": unionJackFlag
        case "BR": brazilFlag
        default: emojiFallback
        }
    }

    private func verticalBands(_ colors: [Color]) -> some View {
        HStack(spacing: 0) {
            ForEach(colors.indices, id: \.self) { index in
                colors[index]
            }
        }
    }

    private func horizontalBands(_ colors: [Color]) -> some View {
        VStack(spacing: 0) {
            ForEach(colors.indices, id: \.self) { index in
                colors[index]
            }
        }
    }

    private func circleFlag(background: Color, circle: Color, scale: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack {
                background
                Circle()
                    .fill(circle)
                    .frame(width: min(geo.size.width, geo.size.height) * scale)
            }
        }
    }

    private var portugalFlag: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                c(0x006600).frame(width: geo.size.width * 0.42)
                c(0xFF0000)
            }
            Circle()
                .fill(c(0xFFD100))
                .frame(width: min(geo.size.width, geo.size.height) * 0.24)
                .position(x: geo.size.width * 0.42, y: geo.size.height * 0.5)
                .opacity(0.92)
        }
    }

    private var moroccoFlag: some View {
        ZStack {
            c(0xC1272D)
            Image(systemName: "star")
                .font(.system(size: 58, weight: .regular))
                .foregroundColor(c(0x006233))
                .shadow(color: c(0x006233).opacity(0.35), radius: 6)
        }
    }

    private var swissFlag: some View {
        GeometryReader { geo in
            ZStack {
                c(0xD52B1E)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geo.size.width * 0.17, height: geo.size.height * 0.52)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geo.size.width * 0.50, height: geo.size.height * 0.18)
            }
        }
    }

    private var unionJackFlag: some View {
        GeometryReader { geo in
            ZStack {
                c(0x012169)
                diagonal(width: geo.size.height * 0.20, color: .white, angle: 28)
                diagonal(width: geo.size.height * 0.20, color: .white, angle: -28)
                diagonal(width: geo.size.height * 0.09, color: c(0xC8102E), angle: 28)
                diagonal(width: geo.size.height * 0.09, color: c(0xC8102E), angle: -28)
                Rectangle().fill(.white).frame(width: geo.size.width, height: geo.size.height * 0.24)
                Rectangle().fill(.white).frame(width: geo.size.width * 0.18, height: geo.size.height)
                Rectangle().fill(c(0xC8102E)).frame(width: geo.size.width, height: geo.size.height * 0.12)
                Rectangle().fill(c(0xC8102E)).frame(width: geo.size.width * 0.09, height: geo.size.height)
            }
        }
    }

    private func diagonal(width: CGFloat, color: Color, angle: Double) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 900, height: width)
            .rotationEffect(.degrees(angle))
    }

    private var brazilFlag: some View {
        GeometryReader { geo in
            ZStack {
                c(0x009B3A)
                Diamond()
                    .fill(c(0xFFDF00))
                    .frame(width: geo.size.width * 0.70, height: geo.size.height * 0.62)
                Circle()
                    .fill(c(0x002776))
                    .frame(width: min(geo.size.width, geo.size.height) * 0.34)
            }
        }
    }

    private var emojiFallback: some View {
        let base = Color(hue: hue / 360, saturation: 0.48, brightness: 0.54)
        let deep = Color(hue: (hue + 20) / 360, saturation: 0.54, brightness: 0.30)
        return ZStack {
            LinearGradient(colors: [base, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
            Text(flag)
                .font(.system(size: 118))
                .scaleEffect(1.25)
                .opacity(0.46)
                .accessibilityHidden(true)
        }
    }

    private static func regionCode(from flag: String) -> String? {
        let scalars = flag.unicodeScalars
        guard scalars.count == 2 else { return nil }
        let letters = scalars.compactMap { scalar -> UnicodeScalar? in
            let value = scalar.value
            guard (127462...127487).contains(value) else { return nil }
            return UnicodeScalar(value - 127397)
        }
        guard letters.count == 2 else { return nil }
        return String(String.UnicodeScalarView(letters))
    }

    private func c(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

private struct UnitedStatesFlag: View {
    var cantonAlignment: Alignment = .topLeading

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: cantonAlignment) {
                VStack(spacing: 0) {
                    ForEach(0..<13, id: \.self) { index in
                        (index.isMultiple(of: 2) ? Color(red: 0.64, green: 0.02, blue: 0.08) : Color.white.opacity(0.92))
                    }
                }

                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.03, green: 0.16, blue: 0.35),
                            Color(red: 0.05, green: 0.23, blue: 0.50)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    let rows = 5
                    let cols = 6
                    ForEach(0..<rows, id: \.self) { row in
                        ForEach(0..<cols, id: \.self) { col in
                            Image(systemName: "star.fill")
                                .font(.system(size: max(2.4, min(geo.size.width, geo.size.height) * 0.018), weight: .bold))
                                .foregroundColor(Color.white.opacity(0.94))
                                .position(
                                    x: CGFloat(col + 1) * geo.size.width * 0.36 / CGFloat(cols + 1),
                                    y: CGFloat(row + 1) * geo.size.height * 0.42 / CGFloat(rows + 1)
                                )
                        }
                    }
                }
                .frame(width: geo.size.width * 0.42, height: geo.size.height * 0.48)
                .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 8)
            }
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Cadre 16:9 (identique avec ou sans photo galerie)

/// Réserve toujours un rectangle 16:9 : le dégradé seul ne rétrécit plus sans image.
struct TripCoverAspectContainer<Content: View>: View {
    var maxHeight: CGFloat = 148
    var cornerRadius: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        Color.clear
            .aspectRatio(TripCoverLayout.aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: maxHeight)
            .overlay {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Carte hero accueil (layout fixe, indépendant du fond)

private enum TripHeroLayout {
    static let cardHeight: CGFloat = 220
    static let topBandHeight: CGFloat = 54
    static let bottomBandHeight: CGFloat = 96
    static let bottomBandHeightWithReturn: CGFloat = 108
}

/// Même logique que les puces « Mes voyages » : statut en haut, infos groupées en bas — sans `Spacer` central.
struct TripHomeHeroCard: View {
    let trip: Trip
    var height: CGFloat = TripHeroLayout.cardHeight
    var cornerRadius: CGFloat = Tk.radiusLg
    var onTap: () -> Void = {}

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                TripPhoto(
                    destination: trip.dest,
                    country: trip.country,
                    hue: trip.hue,
                    radius: 0,
                    showBorder: false,
                    coverKind: trip.coverKind,
                    tripId: trip.id,
                    solidColor: trip.resolvedCoverColor
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: height)
                .clipped()

                heroReadabilityScrim
                    .frame(height: height)

                heroTopChrome
                    .frame(height: TripHeroLayout.topBandHeight, alignment: .top)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    heroBottomChrome
                }
                .frame(height: height)
                .animation(.easeOut(duration: 0.2), value: trip.hasReturn)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .tripnestBubbleChrome(radius: cornerRadius)
            .shadow(color: Color.tBg0.opacity(0.45), radius: 18, x: 0, y: 14)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onTapGesture(perform: onTap)
        }
    }

    private var heroReadabilityScrim: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.58), location: 0),
                .init(color: .black.opacity(0.14), location: 0.38),
                .init(color: .black.opacity(0.48), location: 0.72),
                .init(color: .black.opacity(0.86), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var heroTopChrome: some View {
        HStack(alignment: .center) {
            Spacer(minLength: 8)

            TransportModeGlyph(mode: trip.transportMode, size: 22, stroke: .white)
                .frame(width: 28, height: 28)
                .padding(6)
                .background(Circle().fill(Color.black.opacity(0.34)))
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .zIndex(2)
    }

    /// Bloc infos calqué sur `tripChip` : titre + aller + retour + dates.
    private var heroBottomChrome: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(trip.homeDestinationTitle)
                .font(.tDisplay(22))
                .tracking(-0.4)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(trip.homeOutboundLine)
                .font(.tText(13, weight: .semibold))
                .foregroundColor(.white.opacity(0.94))
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.72)

            if let returnLine = trip.homeReturnLine {
                Text(returnLine)
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.88))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.72)
            }

            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                Text(trip.homeDateLine)
                    .font(.tText(11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(.white.opacity(0.88))
        }
        .frame(maxWidth: .infinity)
        .frame(
            height: trip.hasReturn ? TripHeroLayout.bottomBandHeightWithReturn : TripHeroLayout.bottomBandHeight,
            alignment: .bottomLeading
        )
        .clipped()
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
