import Foundation
import RevenueCat

/// Configuration RevenueCat.
///
/// ⚠️ À FAIRE avant la prod :
/// 1. Crée un projet sur https://app.revenuecat.com
/// 2. Project Settings → API Keys → copie la **Public app-specific key (Apple)** (commence par `appl_`)
///    et colle-la dans `apiKey` ci-dessous.
/// 3. Crée un **Entitlement** (ex. `premium`) et reporte son identifiant dans `entitlementID`.
/// 4. Crée tes abonnements dans App Store Connect, ajoute-les comme **Products** dans RevenueCat,
///    puis attache-les à une **Offering** (l'app lit l'offering « current » automatiquement).
enum RevenueCatConfig {
    /// Clé API publique iOS RevenueCat (commence par `appl_`).
    static let apiKey = "appl_REPLACE_WITH_YOUR_KEY"

    /// Identifiant de l'entitlement premium défini dans RevenueCat → Entitlements.
    static let entitlementID = "premium"

    /// `true` une fois qu'une vraie clé a été renseignée.
    static var isConfigured: Bool {
        !apiKey.isEmpty && !apiKey.hasPrefix("appl_REPLACE")
    }
}

/// Source de vérité pour l'état d'abonnement, branchée sur RevenueCat.
///
/// Tant que `RevenueCatConfig.apiKey` n'est pas renseignée, le manager reste inerte
/// (aucun appel SDK, `isPremium == false`) — l'app continue de fonctionner normalement.
@MainActor
final class PurchasesManager: ObservableObject {
    static let shared = PurchasesManager()

    /// `true` si l'entitlement premium est actif.
    @Published private(set) var isPremium = false
    /// Offering courante (les packages à présenter dans le paywall).
    @Published private(set) var currentOffering: Offering?
    @Published private(set) var isLoadingOfferings = false
    @Published private(set) var purchaseInProgress = false
    /// Dernier message d'erreur lisible (à afficher éventuellement).
    @Published var lastError: String?

    /// `true` si le SDK est réellement actif (clé renseignée).
    var isLive: Bool { RevenueCatConfig.isConfigured }

    /// Prix localisé du package mis en avant (1er de l'offering), ou `nil` si indisponible.
    var primaryPriceString: String? {
        currentOffering?.availablePackages.first?.storeProduct.localizedPriceString
    }

    private init() {}

    /// Configure RevenueCat. À appeler une seule fois au lancement de l'app.
    static func configureIfNeeded() {
        guard RevenueCatConfig.isConfigured else { return }
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        Task { await shared.start() }
    }

    private func start() async {
        await refreshCustomerInfo()
        await loadOfferings()
        // Mises à jour en temps réel (achat, renouvellement, expiration…).
        for await info in Purchases.shared.customerInfoStream {
            apply(info)
        }
    }

    /// Recharge l'état d'abonnement depuis RevenueCat.
    func refreshCustomerInfo() async {
        guard RevenueCatConfig.isConfigured else { return }
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Charge l'offering courante (packages disponibles).
    func loadOfferings() async {
        guard RevenueCatConfig.isConfigured else { return }
        isLoadingOfferings = true
        defer { isLoadingOfferings = false }
        do {
            currentOffering = try await Purchases.shared.offerings().current
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Lance l'achat du package mis en avant (1er de l'offering courante).
    /// Renvoie `true` si l'utilisateur est premium après coup.
    @discardableResult
    func purchasePrimary() async -> Bool {
        guard RevenueCatConfig.isConfigured,
              let package = currentOffering?.availablePackages.first else { return false }
        return await purchase(package)
    }

    /// Lance l'achat d'un package. Renvoie `true` si l'utilisateur est premium après coup.
    @discardableResult
    func purchase(_ package: Package) async -> Bool {
        guard RevenueCatConfig.isConfigured else { return false }
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            guard !result.userCancelled else { return false }
            apply(result.customerInfo)
            return isPremium
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Restaure les achats précédents (obligatoire pour la review App Store).
    @discardableResult
    func restore() async -> Bool {
        guard RevenueCatConfig.isConfigured else { return false }
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        do {
            apply(try await Purchases.shared.restorePurchases())
            return isPremium
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    private func apply(_ info: CustomerInfo) {
        isPremium = info.entitlements[RevenueCatConfig.entitlementID]?.isActive == true
    }
}
