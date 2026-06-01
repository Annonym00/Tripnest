import SwiftUI
import UIKit

/// Apparence choisie par l'utilisateur (clé AppStorage `tripnest.appearance`).
enum TripnestAppearance: String, CaseIterable {
    case dark, light

    var colorScheme: ColorScheme { self == .dark ? .dark : .light }
    var label: String { self == .dark ? "Sombre" : "Clair" }
}

private func tripnestUIColor(_ hex: UInt32, opacity: Double) -> UIColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255
    let g = CGFloat((hex >> 8) & 0xFF) / 255
    let b = CGFloat(hex & 0xFF) / 255
    return UIColor(red: r, green: g, blue: b, alpha: CGFloat(opacity))
}

extension Color {
    /// Correspondance teinte sombre → teinte claire pour les nombreuses couleurs
    /// codées en dur (fonds, surfaces, tuiles, textes lavande). Permet à TOUT
    /// l'app de basculer en mode clair sans réécrire chaque `Color(hex:)`.
    /// Les couleurs de marque/sémantiques (rouge suppression, vert succès, logo
    /// Google, drapeaux pays…) ne figurent PAS ici et restent identiques.
    static let darkToLightHex: [UInt32: UInt32] = [
        // Fonds profonds (dégradés d'arrière-plan, ombres internes)
        0x10071f: 0xe7e0f6,
        0x090315: 0xe2daf3,
        0x0f0523: 0xe2daf3,
        0x140925: 0xede7fb,
        // Surfaces (cartes, bulles, feuilles)
        0x1b0e34: 0xffffff,
        0x1c0f36: 0xffffff,
        0x1a0d32: 0xffffff,
        0x1a0d33: 0xffffff,
        0x1d1038: 0xfbf9ff,
        0x1e113a: 0xfbf9ff,
        // Tuiles / éléments surélevés (icon-tiles, champs, pastilles)
        0x271943: 0xf1ebfd,
        0x2b1d49: 0xece5fb,
        0x24173f: 0xf1ebfd,
        0x2a194f: 0xece5fb,
        0x21123e: 0xf1ebfd,
        0x21113f: 0xf1ebfd,
        0x271649: 0xf1ebfd,
        0x241342: 0xf1ebfd,
        0x2d1a53: 0xe7defb,
        0x1e1238: 0xece5fb,
        // Bordures sombres
        0x291c47: 0xe3dbf6,
    ]

    init(hex: UInt32, opacity: Double = 1) {
        if let light = Color.darkToLightHex[hex] {
            self = Color.adaptive(dark: hex, light: light,
                                  darkOpacity: opacity, lightOpacity: opacity)
            return
        }
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    /// Couleur adaptative : se résout selon le mode sombre/clair courant
    /// (piloté par `.preferredColorScheme`).
    static func adaptive(dark: UInt32, light: UInt32,
                         darkOpacity: Double = 1, lightOpacity: Double = 1) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .light
                ? tripnestUIColor(light, opacity: lightOpacity)
                : tripnestUIColor(dark, opacity: darkOpacity)
        })
    }

    static let tBg0          = Color.adaptive(dark: 0x0e0620, light: 0xf4f1fd)
    static let tBg1          = Color.adaptive(dark: 0x150a2a, light: 0xfbf9ff)
    static let tBg2          = Color.adaptive(dark: 0x1e1238, light: 0xece5fb)
    // Surfaces opaques — pré-composées (lavande tinté sur tBg1) pour que les
    // avions d'arrière-plan ne transparaissent pas à travers les cartes/bulles.
    static let tSurface      = Color.adaptive(dark: 0x1c0f36, light: 0xffffff)
    static let tSurfaceStrong = Color.adaptive(dark: 0x21123e, light: 0xf1ebfd)
    static let tBorder       = Color.adaptive(dark: 0x291c47, light: 0xe3dbf6)
    static let tBorderStrong = Color.adaptive(dark: 0xa78bfa, light: 0x8b5cf6, darkOpacity: 0.22, lightOpacity: 0.30)
    static let tText         = Color.adaptive(dark: 0xf5f0ff, light: 0x1b1033)
    static let tTextMute     = Color.adaptive(dark: 0xf5f0ff, light: 0x1b1033, darkOpacity: 0.62, lightOpacity: 0.60)
    static let tTextDim      = Color.adaptive(dark: 0xf5f0ff, light: 0x1b1033, darkOpacity: 0.38, lightOpacity: 0.40)
    static let tAccent       = Color.adaptive(dark: 0x8b5cf6, light: 0x7c3aed)
    static let tAccent2      = Color.adaptive(dark: 0xa78bfa, light: 0x7c3aed)
    static let tAccentDeep   = Color.adaptive(dark: 0x6d28d9, light: 0x6d28d9)
    static let tGold         = Color.adaptive(dark: 0xf5c150, light: 0xd99a00)
    static let tRose         = Color.adaptive(dark: 0xf472b6, light: 0xdb2777)
    static let tMint         = Color.adaptive(dark: 0x86efac, light: 0x16a34a)
    static let tBlue         = Color.adaptive(dark: 0x7dd3fc, light: 0x0284c7)

    // Bordures des bulles/cartes — nettement plus marquées en clair pour donner
    // du relief sur fond blanc (en sombre elles restent discrètes).
    static let tBubbleBorder       = Color.adaptive(dark: 0xa78bfa, light: 0x7c3aed,
                                                    darkOpacity: 0.26, lightOpacity: 0.55)
    static let tBubbleBorderStrong = Color.adaptive(dark: 0xa78bfa, light: 0x6d28d9,
                                                    darkOpacity: 0.40, lightOpacity: 0.75)
}

/// Épaisseur de bordure des bulles selon l'apparence (plus épaisse en clair).
extension ColorScheme {
    var tBubbleLineWidth: CGFloat { self == .light ? 1.4 : 0.8 }
}

private struct TripnestColorSchemeModifier: ViewModifier {
    @AppStorage("tripnest.appearance") private var appearanceRaw = TripnestAppearance.dark.rawValue
    func body(content: Content) -> some View {
        content.preferredColorScheme(
            TripnestAppearance(rawValue: appearanceRaw)?.colorScheme ?? .dark
        )
    }
}

extension View {
    /// Applique l'apparence choisie par l'utilisateur (sombre/clair).
    func tripnestPreferredColorScheme() -> some View {
        modifier(TripnestColorSchemeModifier())
    }
}

enum Tk {
    static let radius: CGFloat = 22
    static let radiusLg: CGFloat = 26
    static let radiusXl: CGFloat = 28
}

/// Espacements globaux (scroll, barre d’onglets).
enum TripnestLayout {
    /// Marge sous le contenu scrollable au-dessus de la TabBar (overlay).
    static let tabBarScrollBreathing: CGFloat = 90
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
