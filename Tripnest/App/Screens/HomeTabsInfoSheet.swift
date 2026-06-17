import SwiftUI

struct HomeTabsInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(L("Petit rappel sur les onglets de Tripnest."))
                        .font(.tText(14))
                        .foregroundColor(.tTextMute)

                    infoCard(
                        title: "Accueil",
                        icon: .home,
                        description: L("Vue d’ensemble de ton voyage en cours : carte, résumé du trajet et accès rapide aux billets.")
                    )

                    infoCard(
                        title: "Voyages",
                        icon: .globe,
                        description: L("Tous tes voyages planifiés ou réalisés. Crée, modifie, archive et invite des amis pour qu’ils puissent voir et gérer le voyage avec toi.")
                    )

                    infoCard(
                        title: "Spots",
                        icon: .spot,
                        description: L("Tes lieux importants pour le voyage sélectionné : restaurants, hôtels, activités… Chaque spot est relié à un voyage.")
                    )

                    infoCard(
                        title: "Budget",
                        icon: .wallet,
                        description: L("Choisis un voyage en cours, définis ton budget puis suis tes dépenses par catégorie.")
                    )
                }
                .padding(18)
            }
            .background(Color.tBg0.ignoresSafeArea())
            .navigationTitle(L("Comment fonctionne Tripnest ?"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Fermer")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func infoCard(title: String, icon: TIcon.Glyph, description: String) -> some View {
        TCard(padding: 16) {
            HStack(alignment: .top, spacing: 12) {
                TIcon(glyph: icon, size: 22, stroke: .tAccent2)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.tText(15, weight: .bold))
                    Text(description)
                        .font(.tText(13))
                        .foregroundColor(.tTextMute)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
