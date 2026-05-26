import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    static let tBg0          = Color(hex: 0x0e0620)
    static let tBg1          = Color(hex: 0x150a2a)
    static let tBg2          = Color(hex: 0x1e1238)
    static let tSurface      = Color(hex: 0x8b5cf6, opacity: 0.06)
    static let tSurfaceStrong = Color(hex: 0x8b5cf6, opacity: 0.10)
    static let tBorder       = Color(hex: 0xa78bfa, opacity: 0.14)
    static let tBorderStrong = Color(hex: 0xa78bfa, opacity: 0.22)
    static let tText         = Color(hex: 0xf5f0ff)
    static let tTextMute     = Color(hex: 0xf5f0ff, opacity: 0.62)
    static let tTextDim      = Color(hex: 0xf5f0ff, opacity: 0.38)
    static let tAccent       = Color(hex: 0x8b5cf6)
    static let tAccent2      = Color(hex: 0xa78bfa)
    static let tAccentDeep   = Color(hex: 0x6d28d9)
    static let tGold         = Color(hex: 0xf5c150)
    static let tRose         = Color(hex: 0xf472b6)
    static let tMint         = Color(hex: 0x86efac)
    static let tBlue         = Color(hex: 0x7dd3fc)
}

enum Tk {
    static let radius: CGFloat = 22
    static let radiusLg: CGFloat = 26
    static let radiusXl: CGFloat = 28
}

/// Espacements globaux (scroll, barre d’onglets).
enum TripnestLayout {
    /// Marge sous le contenu scrollable : la TabBar est déjà réservée via `safeAreaInset`.
    static let tabBarScrollBreathing: CGFloat = 16
    /// Bas de formulaire plein écran sans TabBar.
    static let formScrollBreathing: CGFloat = 28
}

extension Font {
    static func tDisplay(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func tText(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func tMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension View {
    @inlinable func kerning(_ k: CGFloat) -> some View { self.tracking(k) }
}

struct LetterSpacing: ViewModifier {
    let value: CGFloat
    func body(content: Content) -> some View { content.tracking(value) }
}
