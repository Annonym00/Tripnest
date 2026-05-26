import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onLogout: () -> Void = {}

    @AppStorage("tripnest.profile.name") private var profileName: String = ""
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"
    @State private var showEditProfile = false
    @State private var showCurrencyPicker = false
    @State private var showDocuments = false
    @State private var showSupport = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationStatus: TripnestNotificationStatus = .notDetermined

    private var initials: String {
        let parts = profileName.trimmingCharacters(in: .whitespaces).split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "T"
        let last = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private var displayName: String {
        profileName.trimmingCharacters(in: .whitespaces).isEmpty ? "Mon profil" : profileName
    }

    private enum AccAction { case documents, support, logout }
    private struct Acc { let label: String; let glyph: TIcon.Glyph; let action: AccAction }
    private let accs: [Acc] = [
        .init(label: "Documents · passeport, ID", glyph: .passport, action: .documents),
        .init(label: "Aide & support",            glyph: .bell,     action: .support),
        .init(label: "Se déconnecter",            glyph: .close,    action: .logout),
    ]

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                HStack {
                    Text("Profil").font(.tDisplay(24)).tracking(-0.5)
                    Spacer()
                    Button(action: { showEditProfile = true }) {
                        IconBtn(glyph: .edit)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Modifier le profil")
                }
                .padding(.horizontal, 22).padding(.top, 6).padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileCard
                            .padding(.bottom, 14)
                        sectionLabel("PRÉFÉRENCES").padding(.bottom, 8)
                        TCard(padding: 4) {
                            VStack(spacing: 0) {
                                currencyRow
                                Rectangle().fill(Color.tBorder).frame(height: 1)
                                notificationsRow
                                Rectangle().fill(Color.tBorder).frame(height: 1)
                                prefRow(label: "Langue", value: "Français", glyph: .globe)
                            }
                        }
                        sectionLabel("COMPTE").padding(.top, 20).padding(.bottom, 8)
                        TCard(padding: 4) {
                            VStack(spacing: 0) {
                                ForEach(Array(accs.enumerated()), id: \.offset) { i, a in
                                    accRow(a, last: i == accs.count - 1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .tripnestTabBarScrollPadding()
                }
                .tripnestScrollBounceWhenNeeded()
            }
            .safeAreaInset(edge: .bottom) {
                TabBar(active: .profile, onChange: onNav)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(profileName: $profileName)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Devise par défaut", isPresented: $showCurrencyPicker, titleVisibility: .visible) {
            Button("EUR (€)") { defaultCurrency = "EUR" }
            Button("USD ($)") { defaultCurrency = "USD" }
            Button("JPY (¥)") { defaultCurrency = "JPY" }
            Button("GBP (£)") { defaultCurrency = "GBP" }
            Button("Annuler", role: .cancel) {}
        }
        .sheet(isPresented: $showDocuments) {
            DocumentsSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSupport) {
            SupportSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task { await refreshNotificationStatus() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshNotificationStatus() } }
        }
    }

    private var notificationsRow: some View {
        Button(action: activateNotifications) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0xa78bfa, opacity: 0.12))
                    TIcon(glyph: .bell, size: 16, stroke: .tAccent2)
                }
                .frame(width: 34, height: 34)
                Text("Notifications").font(.tText(14, weight: .semibold))
                Spacer()
                Text(notificationStatus.settingsLabel)
                    .font(.tText(13))
                    .foregroundColor(notificationStatus.isEnabled ? .tAccent2 : .tTextMute)
                TIcon(glyph: .arrow, size: 14, stroke: .tTextDim)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 14).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await TripnestNotifications.currentStatus()
    }

    private func activateNotifications() {
        Task {
            notificationStatus = await TripnestNotifications.activate()
            if notificationStatus.isEnabled { Haptics.success() }
        }
    }

    private var profileCard: some View {
        TCard(padding: 20) {
            VStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle().fill(LinearGradient(
                            colors: [.tAccent2, .tRose],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text(initials).font(.tDisplay(32)).foregroundColor(.white)
                    }
                    .frame(width: 88, height: 88)
                    .overlay(Circle().stroke(Color.tBorderStrong, lineWidth: 3))
                    Button(action: { showEditProfile = true }) {
                        ZStack {
                            Circle().fill(Color.tAccent)
                            TIcon(glyph: .cam, size: 14, stroke: .white)
                        }
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.tBg1, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                }
                Text(displayName).font(.tDisplay(22)).tracking(-0.4)
                Text("\(store.trips.count) voyage(s) · \(store.expenses.count) dépense(s)")
                    .font(.tText(13)).foregroundColor(.tTextMute)
                HStack(spacing: 6) {
                    TPill(label: "\(store.flights.count) vols")
                    TPill(label: "\(store.spots.count) spots")
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func sectionLabel(_ s: String) -> some View {
        HStack {
            Text(s).font(.tText(12, weight: .bold)).tracking(1.5).foregroundColor(.tTextMute)
            Spacer()
        }
    }

    private var currencyRow: some View {
        Button(action: { showCurrencyPicker = true }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0xa78bfa, opacity: 0.12))
                    TIcon(glyph: .wallet, size: 16, stroke: .tAccent2)
                }
                .frame(width: 34, height: 34)
                Text("Devise par défaut").font(.tText(14, weight: .semibold))
                Spacer()
                Text(currencyLabel).font(.tText(13)).foregroundColor(.tTextMute)
                TIcon(glyph: .arrow, size: 14, stroke: .tTextDim)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 14).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var currencyLabel: String {
        switch defaultCurrency {
        case "USD": return "USD ($)"
        case "JPY": return "JPY (¥)"
        case "GBP": return "GBP (£)"
        default: return "EUR (€)"
        }
    }

    private func prefRow(label: String, value: String, glyph: TIcon.Glyph) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: 0xa78bfa, opacity: 0.12))
                TIcon(glyph: glyph, size: 16, stroke: .tAccent2)
            }
            .frame(width: 34, height: 34)
            Text(label).font(.tText(14, weight: .semibold))
            Spacer()
            Text(value).font(.tText(13)).foregroundColor(.tTextMute)
            TIcon(glyph: .arrow, size: 14, stroke: .tTextDim)
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
    }

    private func accRow(_ a: Acc, last: Bool) -> some View {
        let isDanger = a.action == .logout
        return VStack(spacing: 0) {
            Button(action: {
                switch a.action {
                case .documents: showDocuments = true
                case .support:   showSupport = true
                case .logout:    onLogout()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isDanger ? Color.tRose.opacity(0.10) : Color(hex: 0xa78bfa, opacity: 0.12))
                        TIcon(glyph: a.glyph, size: 16, stroke: isDanger ? .tRose : .tAccent2)
                    }
                    .frame(width: 34, height: 34)
                    Text(a.label)
                        .font(.tText(14, weight: .semibold))
                        .foregroundColor(isDanger ? .tRose : .tText)
                    Spacer()
                    TIcon(glyph: .arrow, size: 14, stroke: .tTextDim)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14).padding(.vertical, 14)
            if !last { Rectangle().fill(Color.tBorder).frame(height: 1) }
        }
    }
}

struct EditProfileSheet: View {
    @Binding var profileName: String
    @Environment(\.dismiss) private var dismiss
    @State private var nameInput: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                VStack(spacing: 20) {
                    FormField(label: "Nom affiché", text: $nameInput, placeholder: "Ex. Lucas Martin")
                    CTA(label: "Enregistrer", action: {
                        profileName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        Haptics.success()
                        dismiss()
                    })
                    .opacity(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                    .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Spacer()
                }
                .padding(22)
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
            .onAppear { nameInput = profileName }
        }
        .preferredColorScheme(.dark)
    }
}

struct DocumentsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Doc { let label: String; let glyph: TIcon.Glyph }
    private let docs: [Doc] = [
        .init(label: "Passeport", glyph: .passport),
        .init(label: "Carte d'identité", glyph: .passport),
        .init(label: "Visa / autorisation", glyph: .globe),
        .init(label: "Assurance voyage", glyph: .check),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Stocke ici tes documents de voyage importants.")
                        .font(.tText(14))
                        .foregroundColor(.tTextMute)
                        .padding(.horizontal, 22)
                    TCard(padding: 4) {
                        VStack(spacing: 0) {
                            ForEach(Array(docs.enumerated()), id: \.offset) { i, doc in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(hex: 0xa78bfa, opacity: 0.12))
                                        TIcon(glyph: doc.glyph, size: 16, stroke: .tAccent2)
                                    }
                                    .frame(width: 34, height: 34)
                                    Text(doc.label).font(.tText(14, weight: .semibold))
                                    Spacer()
                                    Text("Ajouter").font(.tText(12)).foregroundColor(.tAccent2)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 14)
                                if i < docs.count - 1 {
                                    Rectangle().fill(Color.tBorder).frame(height: 1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Mes documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SupportSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                VStack(spacing: 20) {
                    TCard(padding: 20) {
                        VStack(spacing: 12) {
                            TIcon(glyph: .bell, size: 36, stroke: .tAccent2)
                            Text("Aide & support")
                                .font(.tDisplay(22)).tracking(-0.4)
                            Text("Pour toute question ou problème, contacte-nous à :")
                                .font(.tText(14))
                                .foregroundColor(.tTextMute)
                                .multilineTextAlignment(.center)
                            Text("support@tripnest.app")
                                .font(.tText(15, weight: .bold))
                                .foregroundColor(.tAccent2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    Spacer()
                }
                .padding(22).padding(.top, 20)
            }
            .navigationTitle("Aide & support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
