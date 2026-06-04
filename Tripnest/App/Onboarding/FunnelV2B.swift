import SwiftUI

// MARK: - 16 · TU AS CE QU'IL FAUT ───────────────────────────────────────────

struct V2_16: View {
    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 16, label: "Tu as ce qu'il faut")
                VStack(alignment: .leading, spacing: 0) {
                    Text("BONNE NOUVELLE")
                        .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tMint)
                    (Text("Tu as tout pour réussir\nton objectif").font(.tDisplay(30)).tracking(-0.9)
                     + Text(".").foregroundColor(.tMint).font(.tDisplay(30)))
                        .padding(.top, 8)
                    Text("Tes réponses vont servir à préparer ton espace.")
                        .font(.tText(14)).foregroundColor(.tTextMute).padding(.top, 8)

                    VStack(spacing: 10) {
                        infoCard(.filter, title: "Ton objectif",
                                 content: "Construire ", highlight: "ton budget", trailing: " de voyage",
                                 highlightColor: .tMint, color: .tMint, bg: Color(hex: 0x2a194f))
                        infoCard(.user, title: "Ton profil",
                                 content: "Profil voyageur à affiner",
                                 color: .tBlue, bg: Color.tBlue.opacity(0.18))
                        infoCard(.star, title: "Ta motivation",
                                 content: "Prête à organiser tes voyages",
                                 color: .tRose, bg: Color.tRose.opacity(0.18))
                        predictionCard
                    }
                    .padding(.top, 22)

                    Spacer(minLength: 0)
                    CTA(label: "Voir mon plan personnalisé →").padding(.top, 12)
                }
                .padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 28)
            }
        }
    }

    private func infoCard(_ glyph: TIcon.Glyph, title: String,
                          content: String, highlight: String = "", trailing: String = "",
                          highlightColor: Color = .tMint,
                          color: Color = .tAccent2,
                          bg: Color) -> some View {
        TCard(padding: 16) {
            HStack(spacing: 14) {
                IconBubble(glyph: glyph, color: color, size: 48)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.tText(13)).foregroundColor(.tTextMute)
                    if highlight.isEmpty {
                        Text(content).font(.tText(17, weight: .bold)).tracking(-0.3)
                    } else {
                        (Text(content).font(.tText(17, weight: .bold)).tracking(-0.3)
                         + Text(highlight).font(.tText(17, weight: .bold)).foregroundColor(highlightColor)
                         + Text(trailing).font(.tText(17, weight: .bold)).tracking(-0.3))
                    }
                }
                Spacer()
            }
        }
    }

    private var predictionCard: some View {
        TCard(padding: 16, bg: AnyShapeStyle(Color.tMint.opacity(0.06)), border: Color.tMint.opacity(0.18)) {
            HStack(alignment: .top, spacing: 14) {
                IconBubble(glyph: .star, color: .tMint, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ce qui compte").font(.tText(13, weight: .bold)).foregroundColor(.tMint)
                    (Text("Le plan se remplira avec ").font(.tText(14))
                     + Text("tes vrais voyages").font(.tText(14, weight: .bold)).foregroundColor(.tMint)
                     + Text(", tes dépenses et tes lieux sauvegardés.").font(.tText(14)))
                }
            }
        }
    }
}

// MARK: - 17 · TÉMOIGNAGES ──────────────────────────────────────────────────

struct V2_17: View {
    private struct T { let glyph: TIcon.Glyph; let title, detail: String; let color: Color }
    private let testimonials: [T] = [
        .init(glyph: .wallet, title: "Budget réel", detail: "Chaque dépense ajoutée met ton budget à jour.", color: .tRose),
        .init(glyph: .plane, title: "Voyages réels", detail: "Tes prochains voyages apparaissent dès que tu les crées.", color: .tBlue),
        .init(glyph: .spot, title: "Spots sauvegardés", detail: "Tes lieux favoris restent rattachés au bon voyage.", color: .tGold),
    ]

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 17, label: "Fonctions clés")
                VStack(alignment: .leading, spacing: 0) {
                    Text("CE QUE TU VAS UTILISER")
                        .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tAccent2)
                    Text("Des écrans branchés\nsur tes données.")
                        .font(.tDisplay(28)).tracking(-0.8)
                        .padding(.top, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(testimonials, id: \.title) { t in
                                testimonialCard(t)
                            }
                        }
                        .padding(.top, 22)
                    }

                    CTA(label: "Suivant →").padding(.top, 12)
                }
                .padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 28)
            }
        }
    }

    private func testimonialCard(_ t: T) -> some View {
        TCard(padding: 16) {
            HStack(alignment: .top, spacing: 12) {
                IconBubble(glyph: t.glyph, color: t.color, size: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text(t.title).font(.tText(14, weight: .bold))
                    Text(t.detail).font(.tText(13)).foregroundColor(.tTextMute).padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 64, alignment: .top)
        }
    }
}

// MARK: - 18 · COMMUNAUTÉ ───────────────────────────────────────────────────

struct V2_18: View {
    private let setupItems: [String] = [
        "Profil voyageur calibré",
        "Budget initialisé",
        "Style de voyage défini",
        "Espace local sécurisé",
    ]

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 18, label: "Ton espace")
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text("TON ESPACE EST PRÊT")
                            .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tMint)
                        Text("Tout est calibré\npour toi.")
                            .font(.tDisplay(30)).tracking(-0.9)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)

                    successBadge

                    TCard(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(setupItems, id: \.self) { item in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color.tMint.opacity(0.18))
                                            .overlay(Circle().stroke(Color.tMint.opacity(0.3), lineWidth: 1))
                                        TIcon(glyph: .check, size: 12, stroke: .tMint, strokeWidth: 3)
                                    }
                                    .frame(width: 22, height: 22)
                                    Text(item).font(.tText(14, weight: .semibold))
                                    Spacer()
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Color.tMint.opacity(0.18))
                            TIcon(glyph: .check, size: 10, stroke: .tMint, strokeWidth: 3)
                        }
                        .frame(width: 20, height: 20)
                        (Text("100 % local").font(.tText(12, weight: .bold)).foregroundColor(.tMint)
                         + Text(" — tes données restent sur ton appareil.").font(.tText(12)).foregroundColor(.tTextMute))
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.tMint.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.tMint.opacity(0.20), lineWidth: 1))

                    CTA(label: "Préparer mon espace →")
                }
                .padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 30)
            }
        }
    }

    private var successBadge: some View {
        ZStack {
            // Halo lumineux vert diffus
            Circle()
                .fill(RadialGradient(colors: [Color.tMint.opacity(0.16), .clear],
                                     center: .center, startRadius: 30, endRadius: 120))
                .frame(width: 240, height: 240)
                .blur(radius: 18)

            // Anneau extérieur fin et lumineux
            Circle()
                .stroke(Color.tMint.opacity(0.25), lineWidth: 1)
                .frame(width: 150, height: 150)

            // Disque principal — dégradé vertical pour le volume
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: 0x6ee7b7), Color(hex: 0x34d399), Color(hex: 0x10b981)],
                        startPoint: .top, endPoint: .bottom))

                // Reflet glossy en haut
                Circle()
                    .fill(RadialGradient(colors: [Color.white.opacity(0.45), .clear],
                                         center: .init(x: 0.5, y: 0.22),
                                         startRadius: 0, endRadius: 62))

                // Liseré clair sur le bord
                Circle().stroke(
                    LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0.05)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5)

                TIcon(glyph: .check, size: 54, stroke: .white, strokeWidth: 4.5)
                    .shadow(color: Color(hex: 0x065f46, opacity: 0.45), radius: 3, y: 2)
            }
            .frame(width: 124, height: 124)
            .shadow(color: Color.tMint.opacity(0.28), radius: 18, y: 6)
            .shadow(color: Color(hex: 0x10b981, opacity: 0.16), radius: 36, y: 0)
        }
        .frame(width: 240, height: 240)
    }
}

// MARK: - 19 · 4 ÉTAPES ─────────────────────────────────────────────────────

struct V2_19: View {
    private struct Step { let n, label, detail: String; var done = false; var busy = false; var wait = false }
    private let steps: [Step] = [
        .init(n: "01", label: "Analyse de ton profil",     detail: "On croise tes 15 réponses",        done: true),
        .init(n: "02", label: "Calibrage de ton budget",   detail: "On ajuste avec tes réponses",  done: true),
        .init(n: "03", label: "Recommandations de spots",  detail: "Sélection adaptée à ton style",   busy: true),
        .init(n: "04", label: "Stratégie d'économie",      detail: "On prépare ton objectif", wait: true),
    ]

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 19, label: "On y est presque")
                VStack(alignment: .leading, spacing: 0) {
                    Text("DERNIÈRE LIGNE DROITE")
                        .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tAccent2)
                    (Text("On va construire ton plan\nen 4 étapes").font(.tDisplay(30)).tracking(-0.9)
                     + Text(".").foregroundColor(.tAccent2).font(.tDisplay(30)))
                        .padding(.top, 8)

                    VStack(spacing: 14) {
                        ForEach(steps, id: \.n) { s in
                            stepRow(s)
                        }
                    }
                    .padding(.top, 26)

                    Spacer()
                    CTA(label: "Lancer la construction →")
                }
                .padding(.horizontal, 26).padding(.top, 24).padding(.bottom, 30)
            }
        }
    }

    private func stepRow(_ s: Step) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(s.done ? Color.tMint : s.busy ? Color(hex: 0x2a194f) : Color.tSurface)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(s.done ? Color.tMint : s.busy ? Color.tAccent2 : Color.tBorder, lineWidth: 1))
                if s.done {
                    TIcon(glyph: .check, size: 20, stroke: .tBg0, strokeWidth: 3)
                } else {
                    Text(s.n).font(.tText(13, weight: .black))
                        .foregroundColor(s.busy ? .tAccent2 : .tTextDim)
                }
            }
            .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 1) {
                Text(s.label).font(.tText(15, weight: .bold))
                    .foregroundColor(s.wait ? .tTextMute : .tText)
                Text(s.detail).font(.tText(12)).foregroundColor(.tTextMute)
            }
            Spacer()
            if s.busy {
                Text("EN COURS")
                    .font(.tText(11, weight: .bold)).tracking(1).foregroundColor(.tAccent2)
            }
        }
    }
}

// MARK: - 20 · LOADING ANALYSE ──────────────────────────────────────────────

struct V2_20: View {
    @Environment(\.tripnestDefaultCTAAction) private var advance
    @State private var progress: Double = 12
    @State private var thirdLineDone = false
    @State private var loadingTask: Task<Void, Never>?

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 20, label: "Construction · 1/4")

                Spacer()

                VStack(spacing: 22) {
                    ZStack {
                        ProgressRing(value: progress, max: 100, size: 200, stroke: 6, color: .tAccent2) {
                            VStack(spacing: 0) {
                                Text("ANALYSE").font(.tText(11, weight: .bold)).tracking(1).foregroundColor(.tTextMute)
                                Text("\(Int(progress))%").font(.tDisplay(48)).tracking(-2)
                                    .contentTransition(.numericText())
                            }
                        }
                    }
                    .frame(width: 200, height: 200)

                    VStack(spacing: 6) {
                        Text("Analyse de ton profil…").font(.tDisplay(24)).tracking(-0.7)
                        Text("On croise tes 15 réponses pour construire un plan vraiment perso.")
                            .font(.tText(13)).foregroundColor(.tTextMute)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        stepLine("Préférences d'onboarding enregistrées", done: progress >= 35)
                        stepLine("Écrans principaux reliés", done: progress >= 65)
                        stepLine("Préparation de ton premier voyage…", done: thirdLineDone)
                    }
                    .frame(maxWidth: 280)
                }
                .padding(.horizontal, 26)

                Spacer()

                Text("Étape 1 sur 4 · ne ferme pas l'app")
                    .font(.tText(11)).foregroundColor(.tTextDim)
                    .padding(.bottom, 30)
            }
        }
        .onAppear { startLoading() }
        .onDisappear {
            loadingTask?.cancel()
            loadingTask = nil
        }
    }

    private func startLoading() {
        loadingTask?.cancel()
        progress = 12
        thirdLineDone = false

        loadingTask = OBLoadingRunner.start(duration: 2.9, onProgress: { pct in
            progress = pct
            if pct >= 88 { thirdLineDone = true }
        }, onComplete: advance)
    }

    private func stepLine(_ label: String, done: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(done ? Color.tMint : Color(hex: 0x2b1d49))
                if done {
                    TIcon(glyph: .check, size: 10, stroke: .tBg0, strokeWidth: 3)
                } else {
                    Circle().fill(Color.tAccent2).frame(width: 6, height: 6)
                }
            }
            .frame(width: 16, height: 16)
            Text(label).font(.tText(12)).foregroundColor(done ? .tText : .tTextMute)
            Spacer()
        }
    }
}

// MARK: - 21 · LOADING CALIBRAGE ────────────────────────────────────────────

struct V2_21: View {
    @Environment(\.tripnestDefaultCTAAction) private var advance
    @State private var barReveal: CGFloat = 0.08
    @State private var progress: Double = 0
    @State private var loadingTask: Task<Void, Never>?

    private let bars: [(value: CGFloat, isYou: Bool)] = [
        (68, false), (90, false), (55, false),
        (78, false), (100, true), (82, false),
    ]

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 21, label: "Construction · 2/4")

                Spacer()

                VStack(spacing: 24) {
                    barsChart
                    VStack(spacing: 6) {
                        Text("Calibrage du budget…").font(.tDisplay(24)).tracking(-0.7)
                        Text("On prépare une base que tu pourras remplacer par tes vraies données.")
                            .font(.tText(13)).foregroundColor(.tTextMute)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                        Text("\(Int(progress))%")
                            .font(.tText(12, weight: .bold))
                            .foregroundColor(.tAccent2)
                            .contentTransition(.numericText())
                    }
                    TCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MICRO-INSIGHT")
                                .font(.tText(11, weight: .bold)).tracking(1).foregroundColor(.tTextMute)
                            (Text("Ton budget sera ").font(.tText(13))
                             + Text("basé sur tes saisies").font(.tText(13, weight: .bold)).foregroundColor(.tMint)
                             + Text(", pas sur des exemples.").font(.tText(13)))
                        }
                    }
                    .frame(maxWidth: 320)
                    .opacity(progress > 20 ? 1 : 0.4)
                }
                .padding(.horizontal, 26)

                Spacer()

                Text("Étape 2 sur 4 · ne ferme pas l'app")
                    .font(.tText(11)).foregroundColor(.tTextDim)
                    .padding(.bottom, 30)
            }
        }
        .onAppear { startLoading() }
        .onDisappear {
            loadingTask?.cancel()
            loadingTask = nil
        }
    }

    private func startLoading() {
        loadingTask?.cancel()
        barReveal = 0.08
        progress = 0

        withAnimation(.spring(response: 0.9, dampingFraction: 0.78)) {
            barReveal = 1
        }

        loadingTask = OBLoadingRunner.start(duration: 2.7, onProgress: { pct in
            progress = pct
        }, onComplete: advance)
    }

    private var barsChart: some View {
        ZStack {
            RadialGradient(colors: [Color.tGold.opacity(0.18), .clear],
                           center: .center, startRadius: 0, endRadius: 92)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, b in
                    VStack(spacing: 5) {
                        if b.isYou {
                            Text("TOI")
                                .font(.tText(9, weight: .black)).tracking(0.5)
                                .foregroundColor(.tBg0)
                                .fixedSize()
                                .padding(.horizontal, 7).padding(.vertical, 2.5)
                                .background(Capsule().fill(Color.tGold))
                                .shadow(color: Color.tGold.opacity(0.5), radius: 5, y: 1)
                                .opacity(barReveal > 0.85 ? 1 : 0)
                        }
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(b.isYou
                                  ? AnyShapeStyle(LinearGradient(colors: [.tGold, .tAccent2],
                                                                 startPoint: .top, endPoint: .bottom))
                                  : AnyShapeStyle(Color(hex: 0xa78bfa, opacity: 0.25)))
                            .frame(width: 22, height: max(8, b.value * 1.5 * barReveal))
                            .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(b.isYou ? Color.tGold : Color.tBorder, lineWidth: 1))
                            .shadow(color: b.isYou ? Color.tGold.opacity(0.4) : .clear, radius: 8)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(width: 244, height: 200)
    }
}

// MARK: - 22 · IDENTITÉ ─────────────────────────────────────────────────────

struct V2_22: View {
    @EnvironmentObject private var onboarding: OnboardingState
    private var insights: OnboardingInsights { OnboardingInsights(state: onboarding) }

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 22, label: "Ton profil voyageur")
                VStack(alignment: .leading, spacing: 0) {
                    Text("ANALYSE TERMINÉE")
                        .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tAccent2)
                    (Text("Tu es un\n").font(.tDisplay(30)).tracking(-0.9)
                     + Text(insights.profileType).font(.tDisplay(30)).foregroundColor(.tAccent2)
                     + Text(".").font(.tDisplay(30)))
                        .padding(.top, 8)
                    Text("Profil construit à partir de tes 15 réponses.")
                        .font(.tText(13)).foregroundColor(.tTextMute).padding(.top, 8)

                    identityCard.padding(.top, 18)

                    Spacer()
                    CTA(label: "Voir mon plan de voyage →")
                }
                .padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 28)
            }
        }
    }

    private var identityCard: some View {
        TCard(padding: 20) {
            VStack(spacing: 0) {
                ZStack {
                    RadialGradient(colors: [Color.tAccent.opacity(0.30), .clear],
                                   center: .center, startRadius: 0, endRadius: 80)
                        .frame(width: 128, height: 128)
                    Circle().fill(LinearGradient(colors: [.tAccent2, .tRose],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 96, height: 96)
                        .overlay(Circle().stroke(Color.tBorderStrong, lineWidth: 3))
                    TIcon(glyph: .globe, size: 44, stroke: .white, strokeWidth: 2.2)
                }
                Text("TYPE").font(.tText(12, weight: .bold)).tracking(1.5)
                    .foregroundColor(.tTextMute).padding(.top, 14)
                Text(insights.profileType).font(.tDisplay(22)).tracking(-0.5).padding(.top, 2)
                Text(insights.profileTagline)
                    .font(.tText(13)).foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6).padding(.horizontal, 10)

                HStack(spacing: 10) {
                    statChip("BUDGET MOYEN", insights.euros(insights.avgBudget), .tAccent2)
                    statChip("OBJECTIF", "−\(insights.euros(insights.savingsGoal))", .tMint)
                }
                .padding(.top, 18)
                if insights.dreamCount > 0 {
                    statChip("DESTINATIONS RÊVÉES", "\(insights.dreamCount) en tête", .tRose)
                        .padding(.top, 10)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func statChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.tText(10, weight: .bold)).tracking(0.5).foregroundColor(.tTextMute)
            Text(value).font(.tText(17, weight: .black)).tracking(-0.3).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - 23 · REVEAL PLAN ──────────────────────────────────────────────────

struct V2_23: View {
    @EnvironmentObject private var onboarding: OnboardingState
    @AppStorage("tripnest.onboarding.startDate") private var startDate = ""
    @AppStorage("tripnest.onboarding.endDate") private var endDate = ""
    private var insights: OnboardingInsights { OnboardingInsights(state: onboarding) }

    private let included: [(String, String)] = [
        ("Itinéraire",                       "À compléter avec tes étapes"),
        ("Spots sauvegardés",                "Tes vrais lieux à retrouver"),
        ("Vol à suivre",                     "Ajoute tes vrais billets"),
        ("Alertes budget intelligentes",     "On t'avertit avant 100%"),
        ("Souvenirs",                        "Tes voyages terminés"),
    ]

    private var planTitle: Text {
        if insights.hasRealDestination {
            return Text("Ton voyage à\n").font(.tDisplay(28)).tracking(-0.8)
                + Text(insights.destination).font(.tDisplay(28)).tracking(-0.8).foregroundColor(.tAccent2)
                + Text(",\ndéjà esquissé pour toi.").font(.tDisplay(28)).tracking(-0.8)
        } else {
            return Text("Ton prochain voyage\n").font(.tDisplay(28)).tracking(-0.8)
                + Text("déjà esquissé").font(.tDisplay(28)).tracking(-0.8).foregroundColor(.tAccent2)
                + Text(" pour toi.").font(.tDisplay(28)).tracking(-0.8)
        }
    }

    private var datesLabel: String {
        let s = startDate.trimmingCharacters(in: .whitespaces)
        let e = endDate.trimmingCharacters(in: .whitespaces)
        switch (s.isEmpty, e.isEmpty) {
        case (false, false): return "\(s) → \(e)"
        case (false, true):  return "À partir du \(s)"
        default:             return "Dates à définir"
        }
    }

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 23, label: "Ton plan")
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("TON PLAN PERSONNALISÉ")
                            .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tAccent2)
                        planTitle.padding(.top, 8)

                        coverBlock.padding(.top, 18)
                        statsCard.padding(.top, 12)

                        Text("INCLUS DANS TON PLAN")
                            .font(.tText(12, weight: .bold)).tracking(1).foregroundColor(.tTextMute)
                            .padding(.top, 12)
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(included, id: \.0) { item in
                                inclusionRow(item.0, item.1)
                            }
                        }
                        .padding(.top, 8)

                        CTA(label: "Continuer →").padding(.top, 18)
                    }
                    .padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 28)
                }
            }
        }
    }

    private var coverBlock: some View {
        ZStack(alignment: .topLeading) {
            DestPhoto(label: insights.destination, hue: 340, radius: 0)
                .frame(height: 170)
            LinearGradient(stops: [
                .init(color: Color.tBg0.opacity(0.1), location: 0),
                .init(color: Color.tBg0.opacity(0.85), location: 0.9),
            ], startPoint: .top, endPoint: .bottom)
            .frame(height: 170)
            Text("FAIT POUR TOI")
                .font(.tText(11, weight: .bold)).tracking(1).foregroundColor(.tGold)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.tGold.opacity(0.20)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tGold.opacity(0.4), lineWidth: 1))
                .padding(14)
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    Text(insights.destination).font(.tDisplay(26)).tracking(-0.8).foregroundColor(.white)
                    Text(datesLabel)
                        .font(.tText(12)).foregroundColor(.white.opacity(0.8))
                }
                .padding(14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.tBorderStrong, lineWidth: 1))
    }

    private var statsCard: some View {
        TCard(padding: 14) {
            HStack {
                statBlock("BUDGET", insights.euros(insights.avgBudget), .tAccent2)
                Spacer()
                statBlock("OBJECTIF", "−\(insights.euros(insights.savingsGoal))", .tMint)
                Spacer()
                statBlock("RÊVÉES", "\(insights.dreamCount)", .tRose)
            }
        }
    }

    private func statBlock(_ k: String, _ v: String, _ c: Color) -> some View {
        VStack(spacing: 2) {
            Text(k).font(.tText(10, weight: .semibold)).tracking(0.5).foregroundColor(.tTextMute)
            Text(v).font(.tText(18, weight: .black)).tracking(-0.4).foregroundColor(c)
        }
    }

    private func inclusionRow(_ l: String, _ d: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(Color.tMint.opacity(0.18))
                    .overlay(Circle().stroke(Color.tMint.opacity(0.3), lineWidth: 1))
                TIcon(glyph: .check, size: 11, stroke: .tMint, strokeWidth: 3)
            }
            .frame(width: 18, height: 18).padding(.top, 2)
            VStack(alignment: .leading, spacing: 1) {
                Text(l).font(.tText(13, weight: .semibold))
                Text(d).font(.tText(11)).foregroundColor(.tTextMute)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 24 · PROJECTION ───────────────────────────────────────────────────

struct V2_24: View {
    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 24, label: "Projection")
                VStack(alignment: .leading, spacing: 0) {
                    Text("PROJECTION SUR 12 MOIS")
                        .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tMint)
                    Text("Ton suivi va se baser\nsur tes dépenses.")
                        .font(.tDisplay(30)).tracking(-0.9)
                        .padding(.top, 8)

                    VStack(spacing: 6) {
                        Color.clear.frame(height: 26)
                        GradientNumber(text: "0€", size: 90, colors: [.tMint, .tAccent2])
                            .shadow(color: Color.tMint.opacity(0.5), radius: 40)
                        Text("avant d'ajouter tes vraies dépenses")
                            .font(.tText(13)).foregroundColor(.tTextMute)
                    }
                    .frame(maxWidth: .infinity)

                    graphCard.padding(.top, 22)
                    bonusCard.padding(.top, 12)

                    Spacer(minLength: 0)
                    CTA(label: "Sauvegarder mon plan →").padding(.top, 12)
                }
                .padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 28)
            }
        }
    }

    private var graphCard: some View {
        TCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Budget").font(.tText(11, weight: .semibold)).foregroundColor(.tTextMute)
                    Spacer()
                    Text("Dépenses").font(.tText(11, weight: .semibold)).foregroundColor(.tTextMute)
                }
                Canvas { ctx, rect in
                    let w = rect.width, h: CGFloat = 100
                    let mapX: (Double) -> CGFloat = { $0 * w / 300 }
                    let mapY: (Double) -> CGFloat = { $0 * h / 100 }

                    var roseLine = Path()
                    let rosePts: [(Double, Double)] = [(0, 30), (60, 35), (120, 25), (180, 40), (240, 35), (300, 50)]
                    for (i, p) in rosePts.enumerated() {
                        let pt = CGPoint(x: mapX(p.0), y: mapY(p.1))
                        i == 0 ? roseLine.move(to: pt) : roseLine.addLine(to: pt)
                    }
                    ctx.stroke(roseLine, with: .color(.tRose.opacity(0.7)),
                               style: StrokeStyle(lineWidth: 2.5, dash: [4, 4]))

                    var mintLine = Path()
                    let mintPts: [(Double, Double)] = [(0, 30), (60, 25), (120, 18), (180, 15), (240, 8), (300, 4)]
                    for (i, p) in mintPts.enumerated() {
                        let pt = CGPoint(x: mapX(p.0), y: mapY(p.1))
                        i == 0 ? mintLine.move(to: pt) : mintLine.addLine(to: pt)
                    }
                    ctx.stroke(mintLine, with: .color(.tMint), lineWidth: 2.5)
                    ctx.fill(Path(ellipseIn: CGRect(x: w - 6, y: mapY(4) - 5, width: 10, height: 10)),
                             with: .color(.tMint))
                }
                .frame(height: 100)
                HStack {
                    Text("Jan"); Spacer()
                    Text("Avr"); Spacer()
                    Text("Juil"); Spacer()
                    Text("Oct"); Spacer()
                    Text("Déc")
                }
                .font(.tText(11)).foregroundColor(.tTextMute)
            }
        }
    }

    private var bonusCard: some View {
        TCard(padding: 14, bg: AnyShapeStyle(Color.tMint.opacity(0.06)), border: Color.tMint.opacity(0.18)) {
            HStack(spacing: 12) {
                IconBubble(glyph: .gift, color: .tMint, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Démarre à 0€")
                        .font(.tText(12, weight: .bold)).foregroundColor(.tMint)
                    Text("Crée un voyage, ajoute tes dépenses, puis Tripnest calcule le reste.")
                        .font(.tText(13))
                }
            }
        }
    }
}

// MARK: - 25 · NOTIFICATIONS ────────────────────────────────────────────────

struct V2_25: View {
    @Environment(\.tripnestDefaultCTAAction) private var advance
    private struct Notif { let label, detail: String; let glyph: TIcon.Glyph; let color: Color; let on: Bool }
    @State private var enabled: Set<String> = [
        "Alerte dépassement de budget",
        "Rappels avant tes vols",
        "Suggestion de spots à proximité",
    ]
    private let items: [Notif] = [
        .init(label: "Alerte dépassement de budget",     detail: "Avant que tu atteignes 100%", glyph: .wallet, color: .tGold, on: true),
        .init(label: "Rappels avant tes vols",            detail: "24h avant chaque départ",     glyph: .plane,  color: .tAccent2, on: true),
        .init(label: "Suggestion de spots à proximité",   detail: "Quand tu es sur place",        glyph: .spot,   color: .tRose, on: true),
        .init(label: "Bilan hebdo de tes économies",      detail: "Le lundi matin",               glyph: .sun,    color: .tBlue, on: false),
    ]

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 25, label: "Notifications")
                VStack(alignment: .leading, spacing: 0) {
                    Text("RAPPELS INTELLIGENTS")
                        .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tAccent2)
                    Text("On t'aide à tenir\ntes objectifs.")
                        .font(.tDisplay(26)).tracking(-0.8).padding(.top, 8)
                    Text("Autorise les alertes iOS pour tes rappels de budget, vols et spots.")
                        .font(.tText(13)).foregroundColor(.tTextMute).padding(.top, 6)

                    VStack(spacing: 8) {
                        ForEach(items, id: \.label) { n in
                            notifRow(n)
                        }
                    }
                    .padding(.top, 22)

                    Spacer()
                    CTA(label: "Activer les notifications", action: activateAndContinue)
                }
                .padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 28)
            }
        }
    }

    private func notifRow(_ n: Notif) -> some View {
        Button(action: {
            if enabled.contains(n.label) {
                enabled.remove(n.label)
            } else {
                enabled.insert(n.label)
            }
        }) {
            TCard(padding: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous).fill(n.color.opacity(0.13))
                        TIcon(glyph: n.glyph, size: 18, stroke: n.color)
                    }
                    .frame(width: 38, height: 38)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(n.label).font(.tText(14, weight: .bold))
                        Text(n.detail).font(.tText(11)).foregroundColor(.tTextMute)
                    }
                    Spacer()
                    toggle(on: enabled.contains(n.label))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func activateAndContinue() {
        Task {
            _ = await TripnestNotifications.activate()
            await MainActor.run { advance() }
        }
    }

    private func toggle(on: Bool) -> some View {
        ZStack(alignment: on ? .trailing : .leading) {
            Capsule().fill(on ? Color.tAccent : Color(hex: 0x2b1d49))
            Circle().fill(Color.white)
                .frame(width: 20, height: 20)
                .padding(2)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
        }
        .frame(width: 42, height: 26)
        .overlay(Capsule().stroke(on ? Color.tAccent : Color.tAccent2.opacity(0.55), lineWidth: 1.2))
    }
}

// MARK: - 26 · CRÉATION DE COMPTE ───────────────────────────────────────────

struct V2_26: View {
    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 26, label: "Sauvegarde")
                VStack(alignment: .leading, spacing: 0) {
                    Text("SAUVEGARDE TON PROFIL")
                        .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tAccent2)
                    Text("Ton espace local\nest prêt.")
                        .font(.tDisplay(26)).tracking(-0.8).padding(.top, 8)

                    summaryCard.padding(.top, 14)

                    TCard(padding: 16) {
                        HStack(spacing: 12) {
                            TIcon(glyph: .check, size: 20, stroke: .tMint)
                            Text("Aucun compte requis pour commencer. Les données créées dans l'app restent locales pour l'instant.")
                                .font(.tText(13))
                                .foregroundColor(.tTextMute)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
                    }
                    .padding(.top, 12)

                    Spacer(minLength: 0)
                    CTA(label: "Continuer").padding(.top, 12)
                    Text("Tu pourras ajouter tes voyages, dépenses et lieux dès l'écran d'accueil.")
                        .font(.tText(10))
                        .foregroundColor(.tTextDim)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 28)
            }
        }
    }

    private var summaryCard: some View {
        TCard(padding: 16,
              bg: AnyShapeStyle(Color(hex: 0x1e113a)),
              border: Color(hex: 0x8b5cf6, opacity: 0.22)) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(LinearGradient(colors: [.tAccent2, .tRose],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                        TIcon(glyph: .globe, size: 20, stroke: .white, strokeWidth: 2.2)
                    }
                    .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Profil prêt à sauvegarder").font(.tText(12)).foregroundColor(.tTextMute)
                        Text("Données locales").font(.tText(14, weight: .bold))
                    }
                }
                Spacer()
                Text("local")
                    .font(.tText(11, weight: .bold)).foregroundColor(.tMint)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.tMint.opacity(0.12)))
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
        }
    }
}

// MARK: - 27 · RÉCAP ────────────────────────────────────────────────────────

struct V2_27: View {
    private let summary: [(TIcon.Glyph, String, String)] = [
        (.globe, "Profil voyageur",     "À construire"),
        (.filter, "Objectif d'économie", "À définir"),
        (.plane, "Voyage planifié",     "À créer"),
        (.wallet, "Budget calibré",      "À définir"),
        (.spot, "Spots sélectionnés",  "0 lieu"),
        (.trips, "Projection",          "Selon tes dépenses"),
        (.bell, "Alertes",             "À activer"),
    ]

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                OBHeader(step: 27, label: "Récapitulatif")
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        TIcon(glyph: .check, size: 14, stroke: .tMint, strokeWidth: 3)
                        Text("PROFIL SAUVEGARDÉ")
                            .font(.tText(11, weight: .bold)).tracking(2).foregroundColor(.tMint)
                    }
                    Text("Ton plan complet\nest prêt à décoller.")
                        .font(.tDisplay(28)).tracking(-0.8)
                        .padding(.top, 8)
                    Text("Tu peux maintenant entrer dans l'app.")
                        .font(.tText(13)).foregroundColor(.tTextMute).padding(.top, 6)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(summary, id: \.1) { item in
                                recapRow(item.0, item.1, item.2)
                            }
                        }
                        .padding(.top, 18)
                    }

                    CTA(label: "Continuer →").padding(.top, 8)
                }
                .padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 28)
            }
        }
    }

    private func recapRow(_ glyph: TIcon.Glyph, _ k: String, _ v: String) -> some View {
        HStack(spacing: 12) {
            IconBubble(glyph: glyph, color: .tAccent2, size: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(k).font(.tText(11)).foregroundColor(.tTextMute)
                Text(v).font(.tText(14, weight: .bold))
            }
            Spacer()
            TIcon(glyph: .check, size: 16, stroke: .tMint, strokeWidth: 2.5)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.tSurface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
    }
}

// MARK: - 28 · PAYWALL (conversion) ──────────────────────────────────────────

enum PaywallPlan { case annual, monthly }

struct V2_28: View {
    @Environment(\.tripnestDefaultCTAAction) private var defaultAction
    @EnvironmentObject private var onboarding: OnboardingState

    @State private var plan: PaywallPlan = .annual
    @State private var showClose = false
    @State private var showLastChance = false

    // Prix d'affichage — à brancher sur StoreKit/RevenueCat plus tard.
    private let annualPrice = "29,99 €"
    private let annualPerMonth = "2,50 €"
    private let monthlyPrice = "4,99 €"
    private let annualPriceDiscount = "14,99 €" // offre de la dernière chance (−50 %)

    // Réponses du funnel renvoyées sur l'écran de paiement.
    private var insights: OnboardingInsights { OnboardingInsights(state: onboarding) }

    private let perks: [(TIcon.Glyph, String, Color)] = [
        (.wallet, "Budget & suivi des dépenses illimités",   .tGold),
        (.globe,  "Conversion multi-devises en temps réel",  .tBlue),
        (.spot,   "Spots & lieux favoris sans limite",        .tRose),
        (.plane,  "Suivi de vols et alertes de départ",       .tAccent2),
        (.bell,   "Alertes budget intelligentes",             .tMint),
        (.cam,    "Souvenirs & albums de voyage",             .tAccent2),
    ]

    var body: some View {
        ScreenShell {
            ZStack {
                VStack(spacing: 0) {
                    topBar
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            hero.padding(.top, 6)
                            ratingStrip.padding(.top, 14)
                            savingsCard.padding(.top, 16)
                            valueStack.padding(.top, 16)
                            testimonialCard.padding(.top, 14)
                            planSelector.padding(.top, 18)
                            if plan == .annual { trialTimeline.padding(.top, 14) }
                            ctaBlock.padding(.top, 16)
                            footerLinks.padding(.top, 14)
                        }
                        .padding(.horizontal, 24).padding(.bottom, 26)
                    }
                }

                if showLastChance {
                    lastChanceOverlay
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .zIndex(1)
                }
            }
        }
        .onAppear {
            // Le bouton fermer apparaît avec un léger délai (réduit l'abandon réflexe).
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                await MainActor.run { withAnimation(.easeIn(duration: 0.3)) { showClose = true } }
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: { withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { showLastChance = true } }) {
                TIcon(glyph: .close, size: 12, stroke: .tTextMute)
                    .frame(width: 24, height: 24)
                    .opacity(0.4)
            }
            .buttonStyle(.plain)
            .opacity(showClose ? 1 : 0)
            .disabled(!showClose)
        }
        .padding(.horizontal, 22).padding(.top, 8)
    }

    // MARK: Offre de la dernière chance (downsell au tap sur ✕)

    private var lastChanceOverlay: some View {
        ZStack {
            Color.tBg0.ignoresSafeArea()
            RadialGradient(colors: [Color.tGold.opacity(0.22), .clear],
                           center: .top, startRadius: 0, endRadius: 360)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 18) {
                    HStack(spacing: 8) {
                        TIcon(glyph: .gift, size: 12, stroke: .tGold)
                        Text("OFFRE UNIQUE · MAINTENANT")
                            .font(.tText(11, weight: .black)).tracking(1).foregroundColor(.tGold)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(Color.tGold.opacity(0.12)))
                    .overlay(Capsule().stroke(Color.tGold.opacity(0.35), lineWidth: 1))

                    VStack(spacing: 10) {
                        (Text("Attends — ").font(.tDisplay(32)).tracking(-1)
                         + Text("−50 %").font(.tDisplay(32)).tracking(-1)
                            .foregroundStyle(LinearGradient(colors: [.tGold, .tAccent2],
                                                            startPoint: .leading, endPoint: .trailing))
                         + Text("\npour toi.").font(.tDisplay(32)).tracking(-1))
                            .multilineTextAlignment(.center)
                        Text(lastChanceSubtitle)
                            .font(.tText(14)).foregroundColor(.tTextMute)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }

                    offerCard
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    CTA(label: "Activer −50 % et démarrer l'essai", height: 60, fontSize: 16, action: defaultAction)
                    Button(action: defaultAction) {
                        Text("Non merci, je laisse passer cette offre")
                            .font(.tText(13, weight: .semibold)).foregroundColor(.tTextDim)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    Text("Essai 7 jours, puis \(annualPriceDiscount) la 1ʳᵉ année (puis \(annualPrice)/an). Annule quand tu veux.")
                        .font(.tText(10)).foregroundColor(.tTextDim)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28).padding(.bottom, 30)
            }
        }
    }

    private var lastChanceSubtitle: String {
        insights.hasRealDestination
            ? "Tu étais à un pas de préparer ton voyage à \(insights.destination). On te facilite le départ."
            : "Tu étais à un pas de viser ton objectif de −\(insights.euros(insights.savingsGoal)). On te facilite le départ."
    }

    private var offerCard: some View {
        TCard(padding: 18, bg: AnyShapeStyle(Color.tMint.opacity(0.06)), border: Color.tGold.opacity(0.35)) {
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(annualPrice)
                        .font(.tText(18, weight: .bold)).foregroundColor(.tTextMute)
                        .strikethrough(true, color: .tTextMute)
                    Text(annualPriceDiscount)
                        .font(.tDisplay(34)).tracking(-1)
                        .foregroundStyle(LinearGradient(colors: [.tGold, .tAccent2],
                                                        startPoint: .top, endPoint: .bottom))
                    Text("/ 1ʳᵉ année")
                        .font(.tText(12)).foregroundColor(.tTextMute)
                }
                Rectangle().fill(Color.tBorder).frame(height: 1)
                HStack(spacing: 10) {
                    TIcon(glyph: .check, size: 14, stroke: .tMint, strokeWidth: 3)
                    Text("Tout Premium + essai 7 jours offert")
                        .font(.tText(13, weight: .semibold))
                    Spacer()
                    Text("−50 %")
                        .font(.tText(11, weight: .black)).foregroundColor(.tBg0)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 7).fill(Color.tGold))
                }
            }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 10) {
            TripnestLogo(size: 64)
            Text("ESSAI 7 JOURS · OFFERT")
                .font(.tText(11, weight: .black)).tracking(1.5).foregroundColor(.tGold)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Capsule().fill(Color.tGold.opacity(0.12)))
                .overlay(Capsule().stroke(Color.tGold.opacity(0.35), lineWidth: 1))
            heroTitle.multilineTextAlignment(.center)
            Text("Tout Tripnest pour viser ton objectif de −\(insights.euros(insights.savingsGoal)).")
                .font(.tText(13)).foregroundColor(.tTextMute)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
    }

    private var heroTitle: Text {
        let grad = LinearGradient(colors: [.tGold, .tAccent2],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        if insights.hasRealDestination {
            return Text("Cap sur\n").font(.tDisplay(28)).tracking(-1)
                + Text(insights.destination).font(.tDisplay(28)).tracking(-1).foregroundStyle(grad)
                + Text(".").font(.tDisplay(28)).tracking(-1)
        } else {
            return Text("Prépare ton\n").font(.tDisplay(28)).tracking(-1)
                + Text("prochain voyage").font(.tDisplay(28)).tracking(-1).foregroundStyle(grad)
                + Text(".").font(.tDisplay(28)).tracking(-1)
        }
    }

    // MARK: Preuve sociale

    private var ratingStrip: some View {
        HStack(spacing: 10) {
            HStack(spacing: -8) {
                ForEach(Array([Color.tRose, .tGold, .tMint, .tBlue].enumerated()), id: \.offset) { _, c in
                    Circle().fill(LinearGradient(colors: [c, .tAccentDeep],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.tBg1, lineWidth: 1.5))
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        TIcon(glyph: .star, size: 11, stroke: .tGold, strokeWidth: 2)
                    }
                    Text("4,9").font(.tText(11, weight: .black)).foregroundColor(.tGold).padding(.leading, 2)
                }
                Text("Adoré par les voyageurs organisés")
                    .font(.tText(10)).foregroundColor(.tTextMute)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.tSurface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
    }

    // MARK: Hook personnalisé

    private var savingsCard: some View {
        TCard(padding: 16, bg: AnyShapeStyle(Color.tMint.opacity(0.06)), border: Color.tMint.opacity(0.22)) {
            HStack(spacing: 14) {
                IconBubble(glyph: .filter, color: .tMint, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TON OBJECTIF").font(.tText(10, weight: .bold)).tracking(1).foregroundColor(.tMint)
                    (Text("Économiser ").font(.tText(15, weight: .bold))
                     + Text("−\(insights.euros(insights.savingsGoal))").font(.tText(15, weight: .black)).foregroundColor(.tMint)
                     + Text(" sur ton prochain voyage").font(.tText(15, weight: .bold)))
                    Text(insights.overspentBefore == "Non, jamais"
                         ? "Tu gardes déjà le contrôle. Premium t'aide à viser encore plus haut."
                         : "Sans suivi, tu dépassais d'environ \(insights.euros(insights.overspend)) par voyage. On t'aide à inverser ça.")
                        .font(.tText(11)).foregroundColor(.tTextMute).padding(.top, 1)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: Value stack

    private var valueStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TOUT CE QUE TU DÉBLOQUES")
                .font(.tText(11, weight: .bold)).tracking(1).foregroundColor(.tTextMute)
                .padding(.bottom, 10)
            VStack(spacing: 8) {
                ForEach(Array(perks.enumerated()), id: \.offset) { _, p in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(p.2.opacity(0.13))
                            TIcon(glyph: p.0, size: 16, stroke: p.2)
                        }
                        .frame(width: 34, height: 34)
                        Text(p.1).font(.tText(13, weight: .semibold))
                        Spacer()
                        TIcon(glyph: .check, size: 14, stroke: .tMint, strokeWidth: 3)
                    }
                }
            }
        }
    }

    // MARK: Témoignage (À REMPLACER par de vrais avis — marketing véridique requis)

    private var testimonialCard: some View {
        TCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        TIcon(glyph: .star, size: 12, stroke: .tGold, strokeWidth: 2)
                    }
                }
                Text("« J'ai tenu mon budget pour la première fois — et il me restait même de la marge au retour. »")
                    .font(.tText(14, weight: .semibold)).italic()
                HStack(spacing: 10) {
                    Circle().fill(LinearGradient(colors: [.tRose, .tAccentDeep],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.tBorder, lineWidth: 1))
                    Text("Léa · voyageuse Tripnest")
                        .font(.tText(11, weight: .bold)).foregroundColor(.tTextMute)
                }
            }
        }
    }

    // MARK: Sélecteur de plan

    private var planSelector: some View {
        VStack(spacing: 10) {
            planRow(
                plan: .annual,
                title: "Annuel",
                price: "\(annualPrice) / an",
                sub: "soit \(annualPerMonth) / mois · essai 7 jours offert",
                badge: "ÉCONOMISE 50 %",
                highlight: true
            )
            planRow(
                plan: .monthly,
                title: "Mensuel",
                price: "\(monthlyPrice) / mois",
                sub: "sans engagement, annule quand tu veux",
                badge: nil,
                highlight: false
            )
        }
    }

    private func planRow(plan target: PaywallPlan, title: String, price: String,
                         sub: String, badge: String?, highlight: Bool) -> some View {
        let selected = plan == target
        return Button(action: { withAnimation(.easeOut(duration: 0.18)) { plan = target } }) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(selected ? Color.tAccent : Color.clear)
                            .overlay(Circle().stroke(selected ? Color.tAccent : Color.tBorder, lineWidth: 2))
                        if selected { Circle().fill(Color.white).frame(width: 8, height: 8) }
                    }
                    .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.tText(16, weight: .black))
                        Text(price).font(.tText(13, weight: .bold)).foregroundColor(.tAccent2)
                        Text(sub).font(.tText(11)).foregroundColor(.tTextMute)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected
                          ? AnyShapeStyle(LinearGradient(colors: [
                                Color(hex: 0x8b5cf6, opacity: 0.20),
                                Color(hex: 0x8b5cf6, opacity: 0.06),
                            ], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color.tSurface)))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? Color.tAccent : Color.tBorder, lineWidth: selected ? 2 : 1))
                .shadow(color: selected ? Color.tAccent.opacity(0.28) : .clear, radius: 16, x: 0, y: 14)

                if let badge {
                    Text(badge)
                        .font(.tText(10, weight: .black)).tracking(0.5).foregroundColor(.tBg0)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.tGold))
                        .offset(x: -14, y: -9)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Frise d'essai

    private var trialTimeline: some View {
        TCard(padding: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text("COMMENT FONCTIONNE TON ESSAI")
                    .font(.tText(11, weight: .bold)).tracking(1).foregroundColor(.tTextMute)
                HStack(spacing: 8) {
                    timelineStep("Aujourd'hui", "Accès complet débloqué", .tMint, isLast: false)
                    timelineStep("Jour 5", "Rappel avant la fin", .tGold, isLast: false)
                    timelineStep("Jour 7", "L'abonnement commence", .tAccent2, isLast: true)
                }
                .padding(.top, 12)
            }
        }
    }

    private func timelineStep(_ date: String, _ label: String, _ color: Color, isLast: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if !isLast {
                    GeometryReader { _ in
                        Rectangle().fill(Color.tBorder)
                            .frame(height: 1)
                            .offset(x: 14)
                    }
                    .frame(height: 1)
                    .offset(y: 5)
                }
                Circle().fill(color).frame(width: 10, height: 10)
            }
            Text(date).font(.tText(10, weight: .bold))
            Text(label).font(.tText(9)).foregroundColor(.tTextMute)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: CTA + réassurance

    private var ctaBlock: some View {
        VStack(spacing: 10) {
            CTA(label: ctaLabel, height: 60, fontSize: 17)
            HStack(spacing: 6) {
                TIcon(glyph: .check, size: 11, stroke: .tMint)
                Text(plan == .annual ? "Annule à tout moment avant le jour 7 · aucun frais"
                                     : "Sans engagement · annule quand tu veux")
                    .font(.tText(11)).foregroundColor(.tTextMute)
            }
            Text(priceRecap)
                .font(.tText(10)).foregroundColor(.tTextDim)
                .multilineTextAlignment(.center)
        }
    }

    private var ctaLabel: String {
        plan == .annual ? "Commencer mon essai gratuit" : "S'abonner · \(monthlyPrice)/mois"
    }

    private var priceRecap: String {
        plan == .annual
            ? "Essai gratuit de 7 jours, puis \(annualPrice)/an. Sans engagement."
            : "Facturé \(monthlyPrice)/mois. Sans engagement."
    }

    private var footerLinks: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Button("Restaurer", action: defaultAction)
                Text("·").foregroundColor(.tTextDim)
                Button("Conditions", action: {})
                Text("·").foregroundColor(.tTextDim)
                Button("Confidentialité", action: {})
            }
            .font(.tText(11, weight: .semibold))
            .foregroundColor(.tTextMute)
            .buttonStyle(.plain)

            Text("Paiement non actif dans cette version.")
                .font(.tText(9)).foregroundColor(.tTextDim)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 29 · SUCCESS ──────────────────────────────────────────────────────

struct V2_29: View {
    var body: some View {
        ScreenShell(motif: false) {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 18) {
                ZStack {
                    RadialGradient(colors: [Color.tAccent.opacity(0.5), .clear],
                                   center: .center, startRadius: 0, endRadius: 120)
                        .frame(width: 260, height: 260)
                    TripnestLogo(size: 130)
                    Circle().fill(Color.tMint)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.tBg0, lineWidth: 4))
                        .overlay(TIcon(glyph: .check, size: 22, stroke: .tBg0, strokeWidth: 3))
                        .offset(x: 50, y: 50)
                }
                .frame(height: 200)

                VStack(spacing: 10) {
                    Text("BIENVENUE DANS TRIPNEST")
                        .font(.tText(11, weight: .bold)).tracking(2.5).foregroundColor(.tAccent2)
                    Text("Décollage\nimminent.")
                        .font(.tDisplay(42)).tracking(-1.6)
                        .multilineTextAlignment(.center)
                    Text("Ton espace Tripnest t'attend.\nL'aventure commence maintenant.")
                        .font(.tText(15)).foregroundColor(.tTextMute)
                        .multilineTextAlignment(.center)
                }

                TCard(padding: 12, bg: AnyShapeStyle(Color.tGold.opacity(0.06)), border: Color.tGold.opacity(0.18)) {
                    HStack(spacing: 12) {
                        IconBubble(glyph: .gift, color: .tGold, size: 42)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Espace local · activé")
                                .font(.tText(12, weight: .bold)).foregroundColor(.tGold)
                            Text("Crée ton premier voyage pour démarrer")
                                .font(.tText(10)).foregroundColor(.tTextMute)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            Spacer()
            VStack(spacing: 8) {
                CTA(label: "Entrer dans Tripnest →")
                CTA(label: "Partager avec un·e ami·e", ghost: true)
            }
            .padding(.horizontal, 28).padding(.bottom, 36)
        }
    }
}
