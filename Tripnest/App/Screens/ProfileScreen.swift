import SwiftUI
import UIKit
import UniformTypeIdentifiers
import StoreKit

struct ProfileScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onLogout: () -> Void = {}

    @AppStorage("tripnest.profile.name") private var profileName: String = ""
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"
    @AppStorage("tripnest.profile.memberSinceYear") private var memberSinceYear: Int = 0
    @State private var showEditProfile = false
    @State private var showCurrencyPicker = false
    @State private var showDocuments = false
    @State private var showSupport = false
    @State private var showSubscription = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationStatus: TripnestNotificationStatus = .notDetermined
    @EnvironmentObject private var avatarStore: ProfileImageStore
    @State private var showPhotoSourceDialog = false
    @State private var showCameraPicker = false
    @State private var showGalleryPicker = false
    @State private var pendingCrop: PendingImageCrop?
    @State private var showLanguageDialog = false
    @State private var showAddFriend = false
    @EnvironmentObject private var localizer: Localizer

    private var initials: String {
        let parts = profileName.trimmingCharacters(in: .whitespaces).split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "T"
        let last = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private var displayName: String {
        profileName.trimmingCharacters(in: .whitespaces).isEmpty ? L("Mon profil") : profileName
    }

    private var handle: String {
        let base = profileName.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces).joined().lowercased()
        return base.isEmpty ? "profil" : base
    }

    private var countriesCount: Int {
        Set(store.trips.compactMap { $0.country }
            .filter { !$0.isEmpty && $0 != "À définir" }).count
    }

    private enum AccAction { case documents, support, subscription, logout }
    private struct Acc { let label: String; let glyph: TIcon.Glyph; let action: AccAction }
    private let accs: [Acc] = [
        .init(label: L("Documents · passeport, ID"), glyph: .passport, action: .documents),
        .init(label: L("Aide & support"),            glyph: .bell,     action: .support),
        .init(label: L("Abonnement"),                glyph: .star,     action: .subscription),
        .init(label: L("Se déconnecter"),            glyph: .close,    action: .logout),
    ]

    var body: some View {
        ScreenShell(motif: false) {
            VStack(spacing: 0) {
                HStack {
                    Text(L("Profil")).font(.tDisplay(24)).tracking(-0.5)
                    Spacer()
                    Button(action: { showEditProfile = true }) {
                        IconBtn(glyph: .edit)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L("Modifier le profil"))
                }
                .padding(.horizontal, 22).padding(.top, 6).padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileCard
                            .padding(.bottom, 14)
                        sectionLabel(L("PRÉFÉRENCES")).padding(.bottom, 8)
                        TCard(padding: 4) {
                            VStack(spacing: 0) {
                                currencyRow
                                Rectangle().fill(Color.tBorder).frame(height: 1)
                                notificationsRow
                                Rectangle().fill(Color.tBorder).frame(height: 1)
                                languageRow
                            }
                        }
                        sectionLabel(L("COMPTE")).padding(.top, 20).padding(.bottom, 8)
                        TCard(padding: 4) {
                            VStack(spacing: 0) {
                                addFriendRow
                                Rectangle().fill(Color.tBorder).frame(height: 1)
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
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selected: $defaultCurrency, allCurrencies: CurrencyConverterSheet.allCurrencies)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(L("Langue"), isPresented: $showLanguageDialog, titleVisibility: .visible) {
            ForEach(AppLanguage.allCases, id: \.self) { lang in
                Button("\(lang.flag)  \(lang.label)") {
                    localizer.language = lang
                    Haptics.selection()
                }
            }
            Button(L("Annuler"), role: .cancel) {}
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet()
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert(L("Invitation acceptée"), isPresented: Binding(
            get: { !showAddFriend && store.friendAcceptedNotice != nil },
            set: { if !$0 { store.friendAcceptedNotice = nil } }
        )) {
            Button(L("OK"), role: .cancel) {}
        } message: {
            if let name = store.friendAcceptedNotice {
                Text(L("%@ a accepté ton invitation.", name))
            }
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
        .sheet(isPresented: $showSubscription) {
            SubscriptionSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(L("Photo de profil"), isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(L("Prendre une photo")) { showCameraPicker = true }
            }
            Button(L("Choisir dans la galerie")) { showGalleryPicker = true }
            if avatarStore.image != nil {
                Button(L("Supprimer la photo"), role: .destructive) { removeProfileImage() }
            }
            Button(L("Annuler"), role: .cancel) {}
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraImagePicker(
                onImage: { image in showCameraPicker = false; presentCrop(image) },
                onCancel: { showCameraPicker = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showGalleryPicker) {
            GalleryPhotoPicker(
                onImage: { image in showGalleryPicker = false; presentCrop(image) },
                onCancel: { showGalleryPicker = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $pendingCrop) { payload in
            ImageCropSheet(
                sourceImage: payload.image,
                aspectRatio: 1,
                isCircle: true,
                title: L("Recadrer la photo"),
                badge: nil,
                outputMaxPixel: 1024,
                onConfirm: { cropped in setProfileImage(cropped); pendingCrop = nil },
                onCancel: { pendingCrop = nil }
            )
        }
        .task { await refreshNotificationStatus() }
        .onAppear {
            if memberSinceYear == 0 {
                memberSinceYear = Calendar.current.component(.year, from: Date())
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshNotificationStatus() } }
        }
    }

    /// Présente le recadrage APRÈS la fermeture du picker (évite le conflit de
    /// présentation SwiftUI qui faisait « ramer » l'ouverture).
    private func presentCrop(_ image: UIImage) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            pendingCrop = PendingImageCrop(image: image)
        }
    }

    private func setProfileImage(_ image: UIImage) {
        avatarStore.save(image)
        Haptics.success()
    }

    private func removeProfileImage() {
        avatarStore.delete()
        Haptics.selection()
    }

    private var addFriendRow: some View {
        Button(action: { showAddFriend = true }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0x271943))
                    TIcon(glyph: .user, size: 16, stroke: .tAccent2)
                }
                .frame(width: 34, height: 34)
                Text(L("Ajouter un ami"))
                    .font(.tText(14, weight: .semibold))
                    .foregroundColor(.tText)
                Spacer()
                if store.friendsCount > 0 {
                    Text("\(store.friendsCount)")
                        .font(.tText(13)).foregroundColor(.tTextMute)
                }
                TIcon(glyph: .arrow, size: 14, stroke: .tTextDim)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 14).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var languageRow: some View {
        Button(action: { showLanguageDialog = true }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0x271943))
                    TIcon(glyph: .globe, size: 16, stroke: .tAccent2)
                }
                .frame(width: 34, height: 34)
                Text(L("Langue")).font(.tText(14, weight: .semibold))
                Spacer()
                Text(localizer.language.label)
                    .font(.tText(13)).foregroundColor(.tTextMute)
                TIcon(glyph: .arrow, size: 14, stroke: .tTextDim)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 14).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var notificationsRow: some View {
        Button(action: activateNotifications) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0x271943))
                    TIcon(glyph: .bell, size: 16, stroke: .tAccent2)
                }
                .frame(width: 34, height: 34)
                Text(L("Notifications")).font(.tText(14, weight: .semibold))
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
                Button(action: { showPhotoSourceDialog = true }) {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            if let profileImage = avatarStore.image {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Circle().fill(LinearGradient(
                                    colors: [.tAccent2, .tRose],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                Text(initials).font(.tDisplay(32)).foregroundColor(.white)
                            }
                        }
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.tBorderStrong, lineWidth: 3))
                        .background {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.tAccent2, .tRose],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 110, height: 110)
                                .blur(radius: 24)
                                .opacity(0.35)
                                .allowsHitTesting(false)
                        }
                        ZStack {
                            Circle().fill(Color.tAccent)
                            TIcon(glyph: .cam, size: 14, stroke: .white)
                        }
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.tBg1, lineWidth: 3))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("Changer la photo de profil"))
                Text(displayName).font(.tDisplay(22)).tracking(-0.4)
                VStack(spacing: 2) {
                    Text("@\(handle)")
                        .font(.tText(13, weight: .semibold)).foregroundColor(.tTextMute)
                    Text(L("Membre depuis %@", String(memberSinceYear == 0 ? Calendar.current.component(.year, from: Date()) : memberSinceYear)))
                        .font(.tText(12)).foregroundColor(.tTextMute)
                }
                HStack(spacing: 6) {
                    statPill("👥 \(store.friendsCount) \(L("amis"))")
                    statPill("🌎 \(countriesCount) pays")
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

    /// Pastille de statistique purement informative (aucun effet au tap).
    private func statPill(_ label: String) -> some View {
        Text(label)
            .font(.tText(13, weight: .semibold))
            .foregroundColor(.tText)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(Capsule().fill(Color(hex: 0x24173f)))
            .overlay(Capsule().stroke(Color.tAccent2.opacity(0.55), lineWidth: 1.2))
            .fixedSize(horizontal: true, vertical: false)
    }

    private var currencyRow: some View {
        Button(action: { showCurrencyPicker = true }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0x271943))
                    TIcon(glyph: .wallet, size: 16, stroke: .tAccent2)
                }
                .frame(width: 34, height: 34)
                Text(L("Devise par défaut")).font(.tText(14, weight: .semibold))
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
        if let c = CurrencyConverterSheet.allCurrencies.first(where: { $0.code == defaultCurrency }) {
            return "\(c.code) – \(c.name)"
        }
        return defaultCurrency
    }

    private func prefRow(label: String, value: String, glyph: TIcon.Glyph) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: 0x271943))
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
                case .subscription: showSubscription = true
                case .logout:    onLogout()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isDanger ? Color.tRose.opacity(0.10) : Color(hex: 0x271943))
                        TIcon(glyph: a.glyph, size: 16, stroke: isDanger ? .tRose : .tAccent2)
                    }
                    .frame(width: 34, height: 34)
                    Text(L(a.label))
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
    @AppStorage("tripnest.profile.nameLastChanged") private var nameLastChanged: Double = 0
    @State private var nameInput: String = ""

    private let cooldownSeconds: Double = 30 * 24 * 3600

    private var isOnCooldown: Bool {
        nameLastChanged > 0 && Date().timeIntervalSince1970 - nameLastChanged < cooldownSeconds
    }

    private var daysRemaining: Int {
        let remaining = cooldownSeconds - (Date().timeIntervalSince1970 - nameLastChanged)
        return max(1, Int(ceil(remaining / 86400)))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                VStack(spacing: 20) {
                    FormField(label: L("Nom affiché"), text: $nameInput, placeholder: L("Ex. Lucas Martin"))
                        .disabled(isOnCooldown)
                        .opacity(isOnCooldown ? 0.5 : 1)

                    if isOnCooldown {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.tGold)
                            Text(daysRemaining > 1 ? L("Prochain changement dans %d jours", daysRemaining) : L("Prochain changement dans %d jour", daysRemaining))
                                .font(.tText(13, weight: .semibold))
                                .foregroundColor(.tGold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.tGold.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.tGold.opacity(0.3), lineWidth: 1)
                        )
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.tTextMute)
                            Text(L("Après confirmation, tu devras attendre 30 jours avant de pouvoir changer ton nom à nouveau."))
                                .font(.tText(12))
                                .foregroundColor(.tTextMute)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        CTA(label: L("Enregistrer"), action: {
                            let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            profileName = trimmed
                            nameLastChanged = Date().timeIntervalSince1970
                            Haptics.success()
                            dismiss()
                        })
                        .opacity(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                        .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Spacer()
                }
                .padding(22)
            }
            .navigationTitle(L("Modifier le profil"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
            .onAppear { nameInput = profileName }
        }
        .tripnestPreferredColorScheme()
    }
}

struct AddFriendSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss
    @State private var nameInput: String = ""
    @State private var errorMessage: String?

    private var trimmedName: String {
        nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var acceptedPopup: Binding<Bool> {
        Binding(
            get: { store.friendAcceptedNotice != nil },
            set: { if !$0 { store.friendAcceptedNotice = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    FormField(label: L("Nom de l'ami"), text: $nameInput, placeholder: L("Ex. Lucas Martin"))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.tText(12, weight: .semibold))
                            .foregroundColor(.tRose)
                    }

                    CTA(label: L("Envoyer l'invitation"), action: addFriend)
                        .opacity(trimmedName.isEmpty ? 0.45 : 1)
                        .disabled(trimmedName.isEmpty)

                    if !store.friends.isEmpty {
                        sectionLabel(L("MES AMIS"))
                            .padding(.top, 4)
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(store.friends) { friend in
                                    friendRow(friend)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(22)
            }
            .navigationTitle(L("Ajouter un ami"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
        }
        .tripnestPreferredColorScheme()
        .alert(L("Invitation acceptée"), isPresented: acceptedPopup) {
            Button(L("OK"), role: .cancel) {}
        } message: {
            if let name = store.friendAcceptedNotice {
                Text(L("%@ a accepté ton invitation.", name))
            }
        }
    }

    private func addFriend() {
        let result = store.addFriend(name: trimmedName)
        switch result {
        case .invited:
            nameInput = ""
            errorMessage = nil
            Haptics.success()
        case .notFound:
            errorMessage = L("Aucun utilisateur ne porte ce nom.")
            Haptics.warning()
        case .alreadyAdded:
            errorMessage = L("Cet ami est déjà dans ta liste.")
            Haptics.warning()
        case .empty:
            break
        }
    }

    private func friendRow(_ friend: Friend) -> some View {
        HStack(spacing: 12) {
            Avatar(initials: initials(for: friend.name))
            Text(friend.name)
                .font(.tText(15, weight: .semibold))
                .foregroundColor(.tText)
            Spacer()
            if friend.status == .pending {
                Text(L("En attente"))
                    .font(.tText(11, weight: .bold))
                    .foregroundColor(.tGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(Color.tGold.opacity(0.16))
                    )
            }
            Button(action: { store.removeFriend(id: friend.id); Haptics.selection() }) {
                TIcon(glyph: .close, size: 14, stroke: .tRose)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("Supprimer"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.tSurface)
        )
        .tripnestBubbleChrome(radius: 14)
    }

    private func initials(for name: String) -> String {
        let parts = name.trimmingCharacters(in: .whitespaces).split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "?"
        let last = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.tText(11, weight: .bold))
            .tracking(1.2)
            .foregroundColor(.tTextMute)
    }
}

// MARK: - Mes amis (vue dédiée : compteur + liste)

struct FriendsListSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss
    @State private var showAddFriend = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    countHeader

                    if store.friends.isEmpty {
                        emptyState
                    } else {
                        Text(L("MES AMIS"))
                            .font(.tText(11, weight: .bold)).tracking(1.2)
                            .foregroundColor(.tTextMute)
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(store.friends) { friend in
                                    friendRow(friend)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    CTA(label: L("Ajouter un ami"), action: { showAddFriend = true })
                }
                .padding(22)
            }
            .navigationTitle(L("Mes amis"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
        }
        .tripnestPreferredColorScheme()
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet()
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var countHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [.tAccent2, .tRose],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "person.2.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.friendsCount)")
                    .font(.tDisplay(30)).tracking(-0.8)
                Text(store.friendsCount > 1 ? L("amis") : L("ami"))
                    .font(.tText(13)).foregroundColor(.tTextMute)
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.tSurface))
        .tripnestBubbleChrome(radius: 18)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(L("Tu n'as pas encore d'amis."))
                .font(.tText(14, weight: .semibold)).foregroundColor(.tText)
            Text(L("Ajoute un ami pour le retrouver ici."))
                .font(.tText(12)).foregroundColor(.tTextMute)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func friendRow(_ friend: Friend) -> some View {
        HStack(spacing: 12) {
            Avatar(initials: initials(for: friend.name))
            Text(friend.name)
                .font(.tText(15, weight: .semibold))
                .foregroundColor(.tText)
            Spacer()
            if friend.status == .pending {
                Text(L("En attente"))
                    .font(.tText(11, weight: .bold))
                    .foregroundColor(.tGold)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color.tGold.opacity(0.16)))
            }
            Button(action: { store.removeFriend(id: friend.id); Haptics.selection() }) {
                TIcon(glyph: .close, size: 14, stroke: .tRose)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("Supprimer"))
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.tSurface))
        .tripnestBubbleChrome(radius: 14)
    }

    private func initials(for name: String) -> String {
        let parts = name.trimmingCharacters(in: .whitespaces).split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "?"
        let last = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }
}

struct DocumentsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Doc: Identifiable {
        let id = UUID()
        let key: String
        let label: String
        let glyph: TIcon.Glyph
    }
    private let docs: [Doc] = [
        .init(key: "passeport", label: "Passeport", glyph: .passport),
        .init(key: "carte-identite", label: L("Carte d'identité"), glyph: .passport),
        .init(key: "visa", label: L("Visa / autorisation"), glyph: .globe),
        .init(key: "assurance", label: L("Assurance voyage"), glyph: .check),
    ]

    @State private var storedURLs: [String: URL] = [:]
    @State private var importKey: String?
    @State private var showImporter = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text(L("Stocke ici tes documents de voyage importants."))
                        .font(.tText(14))
                        .foregroundColor(.tTextMute)
                        .padding(.horizontal, 22)
                    TCard(padding: 4) {
                        VStack(spacing: 0) {
                            ForEach(Array(docs.enumerated()), id: \.offset) { i, doc in
                                docRow(doc)
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
            .navigationTitle(L("Mes documents"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
        }
        .tripnestPreferredColorScheme()
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .onAppear { reload() }
    }

    @ViewBuilder
    private func docRow(_ doc: Doc) -> some View {
        let stored = storedURLs[doc.key]
        HStack(spacing: 12) {
            Button {
                startImport(doc.key)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: 0x271943))
                        TIcon(glyph: doc.glyph, size: 16, stroke: .tAccent2)
                    }
                    .frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L(doc.label)).font(.tText(14, weight: .semibold))
                        if stored != nil {
                            Text(L("Ajouté · touche pour remplacer"))
                                .font(.tText(11)).foregroundColor(.tTextMute)
                        }
                    }
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let stored {
                ShareLink(item: stored) {
                    ZStack {
                        Circle().fill(Color.tAccent2.opacity(0.14))
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                    .frame(width: 34, height: 34)
                }
                .accessibilityLabel("\(L("Partager")) \(L(doc.label))")
            } else {
                Button { startImport(doc.key) } label: {
                    Text(L("Ajouter")).font(.tText(12)).foregroundColor(.tAccent2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
    }

    private func startImport(_ key: String) {
        importKey = key
        showImporter = true
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        defer { importKey = nil }
        guard let key = importKey,
              case .success(let urls) = result,
              let source = urls.first else { return }
        if let saved = ProfileDocumentStore.save(from: source, key: key) {
            storedURLs[key] = saved
            Haptics.success()
        }
    }

    private func reload() {
        let keys = docs.map(\.key)
        // Scan disque unique, hors main thread → ouverture du sheet sans hitch.
        Task {
            let all = await Task.detached(priority: .userInitiated) {
                ProfileDocumentStore.allExistingURLs()
            }.value
            var map: [String: URL] = [:]
            for key in keys where all[key] != nil {
                map[key] = all[key]
            }
            storedURLs = map
        }
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
                            Text(L("Aide & support"))
                                .font(.tDisplay(22)).tracking(-0.4)
                            Text(L("Pour toute question ou problème, contacte-nous à :"))
                                .font(.tText(14))
                                .foregroundColor(.tTextMute)
                                .multilineTextAlignment(.center)
                            Link(destination: URL(string: "mailto:contact@menify.fr")!) {
                                Text("contact@menify.fr")
                                    .font(.tText(15, weight: .bold))
                                    .foregroundColor(.tAccent2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    Spacer()
                }
                .padding(22).padding(.top, 20)
            }
            .navigationTitle(L("Aide & support"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
        }
        .tripnestPreferredColorScheme()
    }
}

struct SubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchases: PurchasesManager
    @State private var isOpeningManagement = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tBg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        subscriptionCard
                        manageButton
                        if purchases.isLive {
                            restoreButton
                        }
                        Text(L("L’annulation est confirmée par Apple. Ton accès reste actif jusqu’à la fin de la période déjà réglée."))
                            .font(.tText(11))
                            .foregroundColor(.tTextMute)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .padding(22)
                    .padding(.top, 8)
                }
            }
            .task { await purchases.refreshCustomerInfo() }
            .navigationTitle(L("Abonnement"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Fermer")) { dismiss() }
                        .foregroundColor(.tAccent2)
                }
            }
        }
        .tripnestPreferredColorScheme()
    }

    private var subscriptionCard: some View {
        TCard(
            padding: 18,
            bg: AnyShapeStyle(LinearGradient(
                colors: [Color.tAccent.opacity(0.18), Color.tSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )),
            border: Color.tAccent2.opacity(0.35)
        ) {
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.tAccent.opacity(0.16))
                    TIcon(glyph: .star, size: 27, stroke: .tAccent2, strokeWidth: 2.2)
                }
                .frame(width: 58, height: 58)

                VStack(spacing: 4) {
                    Text(L("TripNest Premium"))
                        .font(.tDisplay(22))
                    Text(L("Abonnement géré par l’App Store"))
                        .font(.tText(12))
                        .foregroundColor(.tTextMute)
                }

                HStack(spacing: 8) {
                    Circle().fill(Color.tMint).frame(width: 7, height: 7)
                    Text(purchases.isPremium ? L("Abonnement actif") : L("4 jours d’essai inclus"))
                        .font(.tText(12, weight: .bold))
                        .foregroundColor(.tMint)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.tMint.opacity(0.10)))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var manageButton: some View {
        Button(action: openSubscriptionManagement) {
            HStack(spacing: 9) {
                if isOpeningManagement {
                    ProgressView().tint(.white)
                } else {
                    TIcon(glyph: .close, size: 13, stroke: .white, strokeWidth: 2.5)
                }
                Text(L("Gérer ou annuler l’abonnement"))
                    .font(.tText(15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(Color.tRose)
            )
            .shadow(color: Color.tRose.opacity(0.24), radius: 10, y: 7)
        }
        .buttonStyle(TripnestPressStyle())
        .disabled(isOpeningManagement)
    }

    private var restoreButton: some View {
        Button {
            Task { await purchases.restore() }
        } label: {
            Text(L("Restaurer mes achats"))
                .font(.tText(14, weight: .bold))
                .foregroundColor(.tAccent2)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.tBorderStrong, lineWidth: 1)
                )
        }
        .buttonStyle(TripnestPressStyle())
        .disabled(purchases.purchaseInProgress)
    }

    private func openSubscriptionManagement() {
        guard !isOpeningManagement else { return }
        isOpeningManagement = true
        Task { @MainActor in
            defer { isOpeningManagement = false }
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    await UIApplication.shared.open(url)
                }
                return
            }
            do {
                try await AppStore.showManageSubscriptions(in: scene)
            } catch {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    await UIApplication.shared.open(url)
                }
            }
        }
    }
}

// MARK: - Profile photo storage

/// Source de vérité partagée pour la photo de profil.
/// Les écrans observent `image` (@Published) ⇒ toute modification se propage
/// instantanément à l'Accueil, au Profil et à tout autre écran abonné.
@MainActor
final class ProfileImageStore: ObservableObject {
    static let shared = ProfileImageStore()

    @Published private(set) var image: UIImage?
    private var generation = 0

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("profile_avatar.jpg")
    }

    private init() {
        reload()
    }

    @discardableResult
    func save(_ newImage: UIImage) -> Bool {
        generation += 1
        let token = generation
        let url = fileURL
        Task {
            let prepared = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                let square = newImage.profile_orientedUp()
                    .profile_squareCropped()
                    .profile_resized(to: CGSize(width: 512, height: 512))
                guard let data = square.jpegData(compressionQuality: 0.9),
                      (try? data.write(to: url, options: .atomic)) != nil else { return nil }
                return square.preparingForDisplay() ?? square
            }.value
            guard token == generation, let prepared else { return }
            image = prepared
        }
        return true
    }

    func delete() {
        generation += 1
        let url = fileURL
        image = nil
        Task.detached(priority: .utility) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Recharge depuis le disque (utile si le fichier a pu changer hors de l'app).
    func reload() {
        generation += 1
        let token = generation
        let url = fileURL
        Task {
            let loaded = await Self.loadFromDisk(url: url)
            guard token == generation else { return }
            image = loaded
        }
    }

    private static func loadFromDisk(url: URL) async -> UIImage? {
        await Task.detached(priority: .utility) {
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else { return nil }
            return image.preparingForDisplay() ?? image
        }.value
    }
}

// MARK: - Profile documents storage

enum ProfileDocumentStore {
    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("ProfileDocs", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func existingURL(key: String) -> URL? {
        let items = (try? FileManager.default.contentsOfDirectory(
            at: directoryURL, includingPropertiesForKeys: nil)) ?? []
        return items.first { $0.deletingPathExtension().lastPathComponent == key }
    }

    /// Un SEUL scan du dossier → dictionnaire [clé: url]. Évite N scans disque
    /// (un par document) lors du rechargement de la liste.
    static func allExistingURLs() -> [String: URL] {
        let items = (try? FileManager.default.contentsOfDirectory(
            at: directoryURL, includingPropertiesForKeys: nil)) ?? []
        var map: [String: URL] = [:]
        for url in items {
            map[url.deletingPathExtension().lastPathComponent] = url
        }
        return map
    }

    @discardableResult
    static func save(from source: URL, key: String) -> URL? {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }
        let ext = source.pathExtension.isEmpty ? "dat" : source.pathExtension
        let dest = directoryURL.appendingPathComponent("\(key).\(ext)")
        if let old = existingURL(key: key) { try? FileManager.default.removeItem(at: old) }
        do {
            try FileManager.default.copyItem(at: source, to: dest)
            return dest
        } catch {
            return nil
        }
    }

    static func delete(key: String) {
        if let url = existingURL(key: key) { try? FileManager.default.removeItem(at: url) }
    }
}

private extension UIImage {
    func profile_orientedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func profile_squareCropped() -> UIImage {
        let side = min(size.width, size.height)
        let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
        let rect = CGRect(origin: origin, size: CGSize(width: side, height: side)).integral
        guard let cg = cgImage?.cropping(to: rect) else { return self }
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }

    func profile_resized(to target: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
