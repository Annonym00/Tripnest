import SwiftUI

struct LoginScreen: View {
    var onLogin: () -> Void = {}

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {

                VStack(spacing: 18) {
                    TripnestLogo(size: 108)
                        .padding(.top, 28)
                    Text("Tripnest")
                        .font(.tDisplay(38))
                        .tracking(-1.2)
                    Text("Bon retour !")
                        .font(.tText(17))
                        .foregroundColor(.tTextMute)
                        .padding(.top, -16)
                }
                .padding(.top, 40)
                .padding(.horizontal, 28)

                VStack(spacing: 18) {
                    TCard(padding: 26, radius: Tk.radiusXl) {
                        VStack(alignment: .leading, spacing: 0) {
                            TField(label: "IDENTIFIANT", placeholder: "Identifiant")
                            Spacer().frame(height: 22)
                            TField(label: "MOT DE PASSE", placeholder: "Mot de passe")

                            HStack {
                                Spacer()
                                Text("Mot de passe oublié")
                                    .font(.tText(13, weight: .semibold))
                                    .foregroundColor(.tText)
                            }
                            .padding(.top, 14)

                            CTA(label: "Se connecter", fontSize: 17, action: onLogin)
                                .padding(.top, 18)

                            Button(action: onLogin) {
                                Text("Création de compte")
                                    .font(.tText(15, weight: .bold))
                                    .foregroundColor(.tAccent2)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 22)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()
            }
        }
    }
}
