import SwiftUI

// MARK: - 01 · HOOK / WELCOME ────────────────────────────────────────────────

struct V2_01: View {
    var body: some View {
        ScreenShell(motif: false) {
            contentColumn
        }
    }

    private var contentColumn: some View {
        VStack(spacing: 0) {
            VStack(spacing: 22) {
                TripnestLogo(size: 120)
                VStack(spacing: 14) {
                    Text(L("BIENVENUE"))
                        .font(.tText(11, weight: .bold)).tracking(2.5)
                        .foregroundColor(.tAccent2)
                    (Text(L("Tes voyages\nau même endroit")).font(.tDisplay(38)).tracking(-1.4)
                     + Text(".").foregroundColor(.tAccent2).font(.tDisplay(38)).tracking(-1.4))
                        .multilineTextAlignment(.center)
                        .lineSpacing(0)
                    Text(L("On va te poser quelques questions.\n2 minutes pour préparer ton espace voyage."))
                        .font(.tText(15))
                        .foregroundColor(.tTextMute)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                trustStrip.padding(.top, 4)
            }
            .padding(.top, 30)
            .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 8) {
                CTA(label: L("Construire mon plan voyage"))
                CTA(label: L("J'ai déjà un compte"), ghost: true)
            }
            .padding(.horizontal, 28).padding(.bottom, 36)
        }
    }

    private var trustStrip: some View {
        HStack(spacing: 10) {
            HStack(spacing: -8) {
                ForEach(Array([Color.tRose, .tGold, .tMint, .tBlue].enumerated()), id: \.offset) { _, c in
                    Circle().fill(LinearGradient(colors: [c, .tAccentDeep],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Color.tBg1, lineWidth: 1.5))
                }
            }
            Text(L("Données locales · "))
                .font(.tText(11, weight: .semibold))
            TIcon(glyph: .check, size: 11, stroke: .tMint)
            Text(L("privées")).font(.tText(11, weight: .bold)).foregroundColor(.tMint)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(Color.tSurface))
        .overlay(Capsule().stroke(Color.tAccent2.opacity(0.55), lineWidth: 1.2))
    }
}

// MARK: - 02 · POURQUOI ──────────────────────────────────────────────────────

struct V2_02: View {
    var body: some View {
        OBQuestion(
            step: 2, label: L("Réflexion"),
            subtitle: L("POUR COMMENCER"),
            title: AnyView(Text(L("Pourquoi as-tu téléchargé\nTripnest aujourd'hui ?"))),
            hint: L("Une seule réponse — celle qui te ressemble le plus.")
        ) {
            VStack(spacing: 10) {
                OptCard(emoji: "wallet", label: L("Économiser sur mes voyages"),
                        detail: L("J'ai déjà dépassé mon budget une fois de trop"), active: true)
                OptCard(emoji: "map", label: "Mieux m'organiser",
                        detail: L("Mes voyages sont chaotiques"), color: .tRose)
                OptCard(emoji: "globe", label: "Voir plus du monde",
                        detail: L("J'ai des destinations en tête à concrétiser"), color: .tBlue)
                OptCard(emoji: "camera", label: L("Garder mes souvenirs"),
                        detail: L("Mes voyages partent dans l'oubli"), color: .tGold)
                OptCard(emoji: "plane", label: L("Tout ça à la fois"), color: .tMint)
            }
        }
    }
}

// MARK: - 03 · DÉFI ──────────────────────────────────────────────────────────

struct V2_03: View {
    var body: some View {
        OBQuestion(
            step: 3, label: L("Réflexion"),
            subtitle: L("TON DÉFI"),
            title: AnyView(Text(L("Quel est ton plus gros défi\nquand tu voyages ?"))),
            hint: L("Sois honnête — c'est ce qu'on va régler ensemble.")
        ) {
            VStack(spacing: 10) {
                OptCard(emoji: "wallet", label: L("Dépasser mon budget"),
                        detail: L("Je perds le contrôle vite"), active: true, color: .tGold)
                OptCard(emoji: "list", label: L("Oublier les détails"),
                        detail: L("Réservations, horaires, documents"), color: .tRose)
                OptCard(emoji: "mind", label: "Tout planifier en amont",
                        detail: "Trop d'onglets, trop d'apps", color: .tBlue)
                OptCard(emoji: "camera", label: L("Garder une trace propre"),
                        detail: L("Mes photos s'éparpillent"), color: .tMint)
            }
        }
    }
}

// MARK: - 04 · 7/10 ──────────────────────────────────────────────────────────

struct V2_04: View {
    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 4, label: L("Tu n'es pas seul·e"))
                VStack(alignment: .leading, spacing: 0) {
                    Text(L("TU N'ES PAS SEUL·E"))
                        .font(.tText(11, weight: .bold)).tracking(2)
                        .foregroundColor(.tAccent2)
                    (Text(L("Garde le contrôle\nde ton budget")).font(.tDisplay(28)).tracking(-0.9)
                     + Text(".").foregroundColor(.tGold).font(.tDisplay(28)))
                        .padding(.top, 8)

                    Spacer()

                    statVisual
                    insightCard.padding(.top, 18)

                    Spacer()
                    CTA(label: L("Je veux garder le contrôle →"))
                }
                .padding(.horizontal, 26)
                .padding(.top, 20).padding(.bottom, 30)
            }
        }
    }

    private var statVisual: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(38), spacing: 6), count: 5), spacing: 6) {
                ForEach(0..<10) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(i < 7 ? Color.tSurface : Color.tGold.opacity(0.18))
                            .frame(width: 38, height: 56)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(i < 7 ? Color.tBorder : Color.tGold.opacity(0.4), lineWidth: 1.5))
                        if i < 7 {
                            Circle().fill(Color.tTextDim.opacity(0.55)).frame(width: 5, height: 5)
                        } else {
                            TIcon(glyph: .check, size: 18, stroke: .tGold, strokeWidth: 2.6)
                        }
                    }
                }
            }
            .frame(maxWidth: 280)
            Text(L("Un budget clair commence avec tes propres dépenses"))
                .font(.tText(11, weight: .semibold)).foregroundColor(.tTextMute)
        }
        .frame(maxWidth: .infinity)
    }

    private var insightCard: some View {
        TCard(padding: 16) {
            HStack(alignment: .top, spacing: 12) {
                IconBubble(glyph: .sun, color: .tGold, size: 46)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Le saviez-vous")).font(.tText(13, weight: .bold)).foregroundColor(.tGold)
                    Text(L("Suis tes dépenses en temps réel pour décider avec tes propres chiffres."))
                        .font(.tText(13))
                }
            }
        }
        .padding(.horizontal, -16)
    }
}

// MARK: - 05 · STYLE (grid 2x2) ──────────────────────────────────────────────

struct V2_05: View {
    @EnvironmentObject private var onboarding: OnboardingState
    private struct Opt { let glyph: TIcon.Glyph; let label, detail: String; let active: Bool; let color: Color }
    private let opts: [Opt] = [
        .init(glyph: .user, label: "Solo",        detail: L("Indépendant·e"), active: true,  color: .tAccent2),
        .init(glyph: .heart, label: "En couple",   detail: L("Voyage à deux"), active: false, color: .tRose),
        .init(glyph: .home, label: "En famille",  detail: L("Avec enfants"),  active: false, color: .tGold),
        .init(glyph: .trips, label: "Entre amis",  detail: "Groupe",        active: false, color: .tMint),
    ]

    var body: some View {
        OBQuestion(
            step: 5, label: "Personnalisation",
            subtitle: L("Q1 · TON STYLE"),
            title: AnyView(Text(L("Avec qui voyages-tu\nle plus souvent ?")))
        ) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)],
                      spacing: 10) {
                ForEach(opts, id: \.label) { o in
                    let isSelected = onboarding.isSingleSelected(o.label, step: 5, fallback: o.active)
                    Button(action: { onboarding.selectSingle(o.label, step: 5) }) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                IconBubble(glyph: o.glyph, color: o.color, size: 54)
                                Spacer()
                                if isSelected {
                                    ZStack {
                                        Circle().fill(o.color)
                                        TIcon(glyph: .check, size: 12, stroke: .white, strokeWidth: 3)
                                    }
                                    .frame(width: 22, height: 22)
                                }
                            }
                            Spacer()
                            Text(o.label).font(.tText(16, weight: .bold))
                            Text(o.detail).font(.tText(11)).foregroundColor(.tTextMute)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isSelected ? o.color.opacity(0.12) : Color.tSurface))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? o.color : Color.tBorder, lineWidth: isSelected ? 1.5 : 1))
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if o.active, onboarding.single[5] == nil {
                            onboarding.selectSingle(o.label, step: 5)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 06 · FRÉQUENCE ─────────────────────────────────────────────────────

struct V2_06: View {
    var body: some View {
        OBQuestion(
            step: 6, label: "Personnalisation",
            subtitle: L("Q2 · FRÉQUENCE"),
            title: AnyView(Text(L("À quelle fréquence\npars-tu en voyage ?")))
        ) {
            VStack(spacing: 8) {
                OptCard(emoji: "plane", label: "Plusieurs fois par an", detail: L("4+ voyages"), active: true)
                OptCard(emoji: "weather", label: L("Une à deux fois par an"), detail: L("1–2 voyages"))
                OptCard(emoji: "globe", label: L("Un grand voyage par an"), detail: L("Long séjour"))
                OptCard(emoji: "star", label: L("Plus rarement, mais je rêve"), detail: "")
            }
        }
    }
}

// MARK: - 07 · DÉJÀ DÉPASSÉ ? ────────────────────────────────────────────────

struct V2_07: View {
    var body: some View {
        OBQuestion(
            step: 7, label: L("Vérité"),
            subtitle: L("Q3 · MOMENT DE VÉRITÉ"),
            title: AnyView(Text(L("As-tu déjà dépassé ton\nbudget en voyage ?"))),
            hint: L("Pas de jugement. Juste pour calibrer ton plan.")
        ) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 10)
                OptCard(emoji: "wallet", label: "Oui, plusieurs fois",
                        detail: L("C'est même devenu une habitude"), active: true, color: .tGold)
                OptCard(emoji: "user", label: L("Oui, une fois ou deux"),
                        detail: L("Et c'est pour ça que je suis ici"))
                OptCard(emoji: "unknown", label: "Je ne sais pas",
                        detail: L("Je ne suis pas vraiment mon budget"))
                OptCard(emoji: "calm", label: "Non, jamais",
                        detail: L("Mais je veux optimiser quand même"))
            }
        }
    }
}

// MARK: - 08 · DE COMBIEN ────────────────────────────────────────────────────

struct V2_08: View {
    @EnvironmentObject private var onboarding: OnboardingState
    @Environment(\.tripnestOnboardingStep) private var step
    private var pct: Double { onboarding.slider(step: step, fallback: 23) }
    private var val: Int { Int(50 + pct / 100 * (1500 - 50)) }

    var body: some View {
        OBQuestion(
            step: 8, label: L("Vérité"),
            subtitle: L("Q4 · DE COMBIEN"),
            title: AnyView(Text(L("De combien as-tu dépassé\nen moyenne ?")))
        ) {
            VStack(spacing: 26) {
                Color.clear.frame(height: 20)
                VStack(spacing: 6) {
                    GradientNumber(text: "~\(val)€", size: 84, colors: [.tGold, .tAccent])
                    Text(L("par voyage en moyenne"))
                        .font(.tText(13)).foregroundColor(.tTextMute)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 14) {
                    OBSlider(pct: pct, trackColors: [.tGold, .tAccent], thumbBorder: .tAccent)
                    HStack {
                        Text(L("moins de 100€")); Spacer()
                        Text("500€"); Spacer()
                        Text("1500€+")
                    }
                    .font(.tText(11)).foregroundColor(.tTextMute)
                }
                .padding(.horizontal, 6)
                TCard(padding: 12) {
                    (Text(L("Sur 4 voyages par an, ça fait ")).font(.tText(12))
                     + Text(L("1 520€ par an")).font(.tText(12, weight: .bold)).foregroundColor(.tRose)
                     + Text(L(" de perte.")).font(.tText(12)))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - 09 · OUTILS ACTUELS ────────────────────────────────────────────────

struct V2_09: View {
    var body: some View {
        OBQuestion(
            step: 9, label: L("État des lieux"),
            subtitle: L("Q5 · TES OUTILS"),
            title: AnyView(Text(L("Comment t'organises-tu\naujourd'hui ?"))),
            hint: "Plusieurs choix possibles."
        ) {
            VStack(spacing: 8) {
                MultiCard(emoji: "sheet", label: L("Une feuille Excel / Google Sheets"),
                          detail: L("Toujours obsolète, jamais à jour"), active: true)
                MultiCard(emoji: "notes", label: "L'app Notes",
                          detail: "Tout est en vrac", active: true, color: .tRose)
                MultiCard(emoji: "wallet", label: L("L'app de ma banque"),
                          detail: L("Catégories pas adaptées au voyage"))
                MultiCard(emoji: "unknown", label: L("Rien de précis"),
                          detail: "Je fais au feeling", color: .tGold)
                MultiCard(emoji: "calculator", label: L("Une autre app"),
                          detail: L("Mais ça ne me convient pas"), color: .tBlue)
            }
        }
    }
}

// MARK: - 10 · FRUSTRATIONS ─────────────────────────────────────────────────

struct V2_10: View {
    var body: some View {
        OBQuestion(
            step: 10, label: L("État des lieux"),
            subtitle: L("Q6 · CE QUI TE FRUSTRE"),
            title: AnyView(Text(L("Qu'est-ce qui te frustre\nle plus avec ces outils ?"))),
            hint: "Plusieurs choix possibles."
        ) {
            VStack(spacing: 8) {
                MultiCard(emoji: "time", label: L("Trop de temps à saisir"),
                          detail: L("Je finis par ne plus le faire"), active: true)
                MultiCard(emoji: "wallet", label: L("Les conversions de devises"),
                          detail: L("Je ne sais jamais où j'en suis"), active: true, color: .tGold)
                MultiCard(emoji: "bell", label: "Pas de mode hors-ligne",
                          detail: L("Inutile en plein voyage"))
                MultiCard(emoji: "globe", label: L("Aucune vision d'ensemble"),
                          detail: L("Je découvre les dégâts au retour"), active: true, color: .tRose)
                MultiCard(emoji: "spot", label: L("Je perds les lieux découverts"),
                          detail: L("Adresses oubliées, restos perdus"), color: .tBlue)
            }
        }
    }
}

// MARK: - 11 · OBJECTIF #1 ──────────────────────────────────────────────────

struct V2_11: View {
    var body: some View {
        OBQuestion(
            step: 11, label: L("Ton objectif"),
            subtitle: L("OBJECTIF PRINCIPAL"),
            title: AnyView(Text(L("Quel est ton objectif\nnuméro 1 cette année ?")))
        ) {
            VStack(spacing: 10) {
                OptCard(emoji: "wallet", label: L("Économiser 500€+ sur mes voyages"),
                        detail: "Plus de marge, moins de stress", active: true, color: .tGold)
                OptCard(emoji: "map", label: L("Visiter 3 nouvelles destinations"),
                        detail: L("Sortir de ma zone"), color: .tRose)
                OptCard(emoji: "calendar", label: L("Mieux planifier mes vacances"),
                        detail: "Anticiper, ne plus subir", color: .tBlue)
                OptCard(emoji: "globe", label: L("Faire le voyage de ma vie"),
                        detail: L("Cette année, c'est la bonne"), color: .tMint)
            }
        }
    }
}

// MARK: - 12 · BUDGET MOYEN ─────────────────────────────────────────────────

struct V2_12: View {
    @EnvironmentObject private var onboarding: OnboardingState
    @Environment(\.tripnestOnboardingStep) private var step
    @State private var style = "Confort"
    private var pct: Double { onboarding.slider(step: step, fallback: 25) }
    private var v: Int { Int(500 + pct / 100 * (6000 - 500)) }

    var body: some View {
        OBQuestion(
            step: 12, label: L("Ton objectif"),
            subtitle: L("TON BUDGET MOYEN"),
            title: AnyView(Text(L("Combien dépenses-tu\npar voyage en moyenne ?"))),
            hint: "Hors transport longue distance. Estime au mieux."
        ) {
            VStack(spacing: 30) {
                Color.clear.frame(height: 10)
                VStack(spacing: 4) {
                    GradientNumber(text: "\(v.formatted(.number.locale(Locale(identifier: "fr_FR"))))€",
                                  size: 78, colors: [.white, .tAccent2])
                    Text(L("≈ 230€ / jour pour 8 jours"))
                        .font(.tText(13)).foregroundColor(.tTextMute)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 14) {
                    OBSlider(pct: pct)
                    HStack {
                        Text("500€"); Spacer()
                        Text("1500€"); Spacer()
                        Text("3000€"); Spacer()
                        Text("6000€+")
                    }
                    .font(.tText(11)).foregroundColor(.tTextMute)
                }
                .padding(.horizontal, 6)
                HStack(spacing: 8) {
                    TPill(label: "Backpack", active: style == "Backpack", action: { style = "Backpack" })
                    TPill(label: "Confort", active: style == "Confort", action: { style = "Confort" })
                    TPill(label: "Luxe", active: style == "Luxe", action: { style = "Luxe" })
                }
            }
        }
    }
}

// MARK: - 13 · DESTINATIONS RÊVÉES ──────────────────────────────────────────

struct V2_13: View {
    @EnvironmentObject private var onboarding: OnboardingState
    private struct Dest { let glyph: TIcon.Glyph; let name: String; let hue: Double; let on: Bool }
    private let dests: [Dest] = [
        .init(glyph: .globe, name: "Japon",    hue: 340, on: true),
        .init(glyph: .globe, name: "Maroc",    hue: 50,  on: true),
        .init(glyph: .globe, name: "Mexique",  hue: 20,  on: false),
        .init(glyph: .search, name: L("À définir"), hue: 160, on: true),
        .init(glyph: .globe, name: "Islande",  hue: 220, on: false),
        .init(glyph: .globe, name: "Portugal", hue: 25,  on: false),
        .init(glyph: .globe, name: "Vietnam",  hue: 130, on: false),
        .init(glyph: .globe, name: "Italie",   hue: 15,  on: false),
        .init(glyph: .globe, name: L("Pérou"),    hue: 90,  on: true),
    ]

    var body: some View {
        OBQuestion(
            step: 13, label: "Inspiration",
            subtitle: L("DESTINATIONS RÊVÉES"),
            title: AnyView(Text(L("Où as-tu envie d'aller\nen priorité ?"))),
            hint: L("Choisis au moins 3 destinations."),
            cta: "Continuer (\(selectedCount) choisie\(selectedCount > 1 ? "s" : ""))"
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                      spacing: 8) {
                ForEach(dests, id: \.name) { d in
                    destTile(d)
                }
            }
        }
    }

    private func destTile(_ d: Dest) -> some View {
        let isSelected = onboarding.isMultipleSelected(d.name, step: 13, fallback: d.on)
        return ZStack(alignment: .topLeading) {
            DestPhoto(label: d.name, hue: d.hue, radius: 0)
                .aspectRatio(1, contentMode: .fill)
            LinearGradient(
                colors: isSelected
                ? [Color.tAccent.opacity(0.15), Color.tBg0.opacity(0.85)]
                : [Color.clear, Color.tBg0.opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            )
            IconBubble(glyph: d.glyph, color: .white.opacity(0.85), size: 28).padding(6)
            if isSelected {
                HStack {
                    Spacer()
                    ZStack {
                        Circle().fill(Color.tAccent2)
                        TIcon(glyph: .check, size: 11, stroke: .white, strokeWidth: 3)
                    }
                    .frame(width: 20, height: 20).padding(6)
                }
            }
            VStack {
                Spacer()
                HStack {
                    Text(d.name).font(.tText(12, weight: .bold)).foregroundColor(.white)
                    Spacer()
                }
                .padding(6)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            onboarding.toggleMultiple(d.name, step: 13)
        }
        .onAppear {
            if d.on, onboarding.multiple[13]?.contains(d.name) != true {
                var values = onboarding.multiple[13] ?? []
                values.insert(d.name)
                onboarding.multiple[13] = values
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(isSelected ? Color.tAccent2 : Color.tBorder, lineWidth: isSelected ? 2 : 1))
        .shadow(color: isSelected ? Color.tAccent.opacity(0.35) : .clear, radius: 10, x: 0, y: 10)
    }

    private var selectedCount: Int {
        onboarding.multiple[13]?.count ?? dests.filter(\.on).count
    }
}

// MARK: - 14 · PROCHAIN VOYAGE (data entry) ─────────────────────────────────

struct V2_14: View {
    @Environment(\.tripnestDefaultCTAAction) private var defaultAction
    @AppStorage("tripnest.onboarding.destination") private var destination = ""
    var body: some View {
        OBQuestion(
            step: 14, label: "Engagement",
            subtitle: L("TON PROCHAIN VOYAGE"),
            title: AnyView(Text(L("Où as-tu envie\nd'aller ?"))),
            hint: L("On l'utilise pour construire ton premier plan. Tu pourras ajouter les dates plus tard."),
            cta: L("Construire mon plan")
        ) {
            VStack(spacing: 16) {
                fieldBox("DESTINATION") {
                    HStack(spacing: 10) {
                        TIcon(glyph: .plane, size: 22, stroke: .tAccent2)
                        TextField(L("Destination à définir"), text: $destination)
                            .font(.tText(16, weight: .semibold))
                            .foregroundColor(.tText)
                    }
                }
                Button(action: defaultAction) {
                    Text(L("Je n'ai pas encore de plan précis →"))
                        .font(.tText(13, weight: .semibold))
                        .foregroundColor(.tTextMute)
                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func fieldBox<V: View>(_ label: String, @ViewBuilder content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.tText(11, weight: .bold)).tracking(1.5).foregroundColor(.tTextMute)
            content()
                .padding(.horizontal, 16).frame(height: 54)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.tSurface))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tBorderStrong, lineWidth: 1.5))
        }
    }
}

// MARK: - 15 · OBJECTIF ÉCONOMIE ─────────────────────────────────────────────

struct V2_15: View {
    @EnvironmentObject private var onboarding: OnboardingState
    @Environment(\.tripnestOnboardingStep) private var step
    private var pct: Double { onboarding.slider(step: step, fallback: 27) }
    private var save: Int { Int(100 + pct / 100 * (2000 - 100)) }

    var body: some View {
        OBQuestion(
            step: 15, label: "Engagement",
            subtitle: L("TON OBJECTIF D'ÉCONOMIE"),
            title: AnyView(Text(L("Combien veux-tu économiser\nsur ton prochain voyage ?"))),
            hint: L("Sois ambitieux·se. On va t'y aider.")
        ) {
            VStack(spacing: 26) {
                Color.clear.frame(height: 10)
                VStack(spacing: 6) {
                    Text(L("OBJECTIF"))
                        .font(.tText(12, weight: .bold)).tracking(2).foregroundColor(.tMint)
                    GradientNumber(text: "−\(save)€", size: 78, colors: [.tMint, .tAccent2])
                    Text(L("selon ton budget réel"))
                        .font(.tText(13)).foregroundColor(.tTextMute)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 14) {
                    OBSlider(pct: pct, trackColors: [.tMint, .tAccent2], thumbBorder: .tMint)
                    HStack {
                        Text("100€"); Spacer()
                        Text("500€"); Spacer()
                        Text("1000€"); Spacer()
                        Text("2000€")
                    }
                    .font(.tText(11)).foregroundColor(.tTextMute)
                }
                .padding(.horizontal, 6)

                TCard(padding: 14) {
                    HStack(spacing: 12) {
                        IconBubble(glyph: .filter, color: .tMint, size: 46)
                        (Text(L("Réaliste")).font(.tText(13, weight: .bold)).foregroundColor(.tMint)
                         + Text(L(" — il sera ajusté avec tes vraies dépenses dans l'app."))
                            .font(.tText(13)))
                    }
                }
            }
        }
    }
}
