import Foundation
import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Configuration ──────────────────────────────────────────────────────

/// RevenueCat configuration.
///
/// ⚠️ Before shipping to the App Store:
/// 1. Create a project at https://app.revenuecat.com
/// 2. Project Settings → API Keys → copy the **Public app-specific key (Apple)**
///    (starts with `appl_`) and paste it into `apiKey` below. The `test_…` key
///    wired here is fine for sandbox / development.
/// 3. Create an **Entitlement** named `Tripnest Pro` (the identifier below must
///    match its identifier in the dashboard *exactly*, including the space).
/// 4. Create the three products in App Store Connect, import them into
///    RevenueCat → Products, then attach them to an **Offering** as packages:
///       • Lifetime  → package identifier `lifetime`  (a non-consuming purchase)
///       • Yearly    → package identifier `yearly`    (Annual / `$rc_annual`)
///       • Monthly   → package identifier `monthly`   (Monthly / `$rc_monthly`)
///    Mark that offering **current** — the app reads `offerings.current`.
enum RevenueCatConfig {
    /// Public RevenueCat SDK key. Production iOS keys start with `appl_`;
    /// this `test_…` key is used for sandbox/development.
    static let apiKey = "test_MexwkYjOwpvJqXnzPUQStlGhiiu"

    /// Identifier of the premium entitlement defined in RevenueCat → Entitlements.
    static let entitlementID = "Tripnest Pro"

    /// `true` once a real key has been provided (i.e. not the shipped placeholder).
    static var isConfigured: Bool {
        !apiKey.isEmpty && !apiKey.hasPrefix("appl_REPLACE")
    }
}

// MARK: - Manager ────────────────────────────────────────────────────────────

/// Single source of truth for subscription state, backed by RevenueCat.
///
/// As long as `RevenueCatConfig.apiKey` is the placeholder, the manager stays
/// inert (no SDK calls, `isPremium == false`) so the app keeps working offline.
@MainActor
final class PurchasesManager: ObservableObject {
    static let shared = PurchasesManager()

    /// `true` when the `Tripnest Pro` entitlement is active.
    @Published private(set) var isPremium = false
    /// Current offering (the packages presented in the paywall).
    @Published private(set) var currentOffering: Offering?
    /// Full customer info (entitlements, management URL, expiration dates…).
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var isLoadingOfferings = false
    @Published private(set) var purchaseInProgress = false
    /// Last human-readable error, if any.
    @Published var lastError: String?

    /// `true` when the SDK is actually live (a real key was provided).
    var isLive: Bool { RevenueCatConfig.isConfigured }

    private init() {}

    // MARK: Typed package accessors (Lifetime / Yearly / Monthly)

    /// The lifetime (non-consuming) package, if the current offering exposes one.
    var lifetimePackage: Package? {
        currentOffering?.lifetime ?? currentOffering?.package(identifier: "lifetime")
    }

    /// The yearly subscription package, if available.
    var annualPackage: Package? {
        currentOffering?.annual ?? currentOffering?.package(identifier: "yearly")
    }

    /// The monthly subscription package, if available.
    var monthlyPackage: Package? {
        currentOffering?.monthly ?? currentOffering?.package(identifier: "monthly")
    }

    /// Localized price of the highlighted package (annual first, else the first
    /// available package), or `nil` if offerings haven't loaded yet.
    var primaryPriceString: String? {
        (annualPackage ?? currentOffering?.availablePackages.first)?
            .storeProduct.localizedPriceString
    }

    // MARK: Lifecycle

    /// Configure RevenueCat. Call exactly once, at app launch.
    static func configureIfNeeded() {
        guard RevenueCatConfig.isConfigured else { return }
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        Task { await shared.start() }
    }

    private func start() async {
        await refreshCustomerInfo()
        await loadOfferings()
        // Real-time updates (purchase, renewal, expiration, refund…).
        for await info in Purchases.shared.customerInfoStream {
            apply(info)
        }
    }

    // MARK: Customer info

    /// Refresh subscription state from RevenueCat.
    func refreshCustomerInfo() async {
        guard isLive else { return }
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: Offerings

    /// Load the current offering (available packages).
    func loadOfferings() async {
        guard isLive else { return }
        isLoadingOfferings = true
        defer { isLoadingOfferings = false }
        do {
            currentOffering = try await Purchases.shared.offerings().current
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: Purchases

    /// Purchase the highlighted package (annual, else first available).
    /// Returns `true` if the user is premium afterwards.
    @discardableResult
    func purchasePrimary() async -> Bool {
        guard let package = annualPackage ?? currentOffering?.availablePackages.first
        else { return false }
        return await purchase(package)
    }

    /// Purchase a specific package. Returns `true` if premium afterwards.
    @discardableResult
    func purchase(_ package: Package) async -> Bool {
        guard isLive else { return false }
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

    /// Restore previous purchases (required for App Store review).
    @discardableResult
    func restore() async -> Bool {
        guard isLive else { return false }
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
        customerInfo = info
        isPremium = info.entitlements[RevenueCatConfig.entitlementID]?.isActive == true
    }
}

// MARK: - Paywall (RevenueCatUI) ─────────────────────────────────────────────

/// A ready-to-present RevenueCat paywall (the no-code template configured in the
/// dashboard, rendered from `offerings.current`).
///
/// It reports completion through `onClose`, refreshes the manager's customer info
/// on purchase/restore, and dismisses itself. Present it as a sheet:
///
/// ```swift
/// .sheet(isPresented: $showPaywall) {
///     TripnestPaywall { showPaywall = false }
/// }
/// ```
struct TripnestPaywall: View {
    @EnvironmentObject private var purchases: PurchasesManager
    /// Called after a successful purchase/restore or a manual dismiss.
    var onClose: () -> Void = {}

    var body: some View {
        // `displayCloseButton` gives users an exit even on a "hard" paywall.
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { _ in
                Task {
                    await purchases.refreshCustomerInfo()
                    onClose()
                }
            }
            .onRestoreCompleted { _ in
                Task {
                    await purchases.refreshCustomerInfo()
                    onClose()
                }
            }
            .onDisappear { onClose() }
    }
}

extension View {
    /// Presents the RevenueCat paywall automatically *only if* the user lacks the
    /// `Tripnest Pro` entitlement — the modern, recommended gating pattern.
    /// No-op when the entitlement is already active.
    ///
    /// ```swift
    /// SomeProFeature()
    ///     .presentTripnestPaywallIfNeeded()
    /// ```
    func presentTripnestPaywallIfNeeded() -> some View {
        presentPaywallIfNeeded(
            requiredEntitlementIdentifier: RevenueCatConfig.entitlementID
        )
    }
}

// MARK: - Customer Center (RevenueCatUI) ─────────────────────────────────────

/// RevenueCat's pre-built **Customer Center**: lets subscribers manage, cancel,
/// request refunds, restore purchases, and handle billing issues without leaving
/// the app. Present it as a sheet for premium users.
///
/// ```swift
/// .sheet(isPresented: $showCustomerCenter) {
///     TripnestCustomerCenter()
/// }
/// ```
struct TripnestCustomerCenter: View {
    @EnvironmentObject private var purchases: PurchasesManager

    var body: some View {
        CustomerCenterView()
            .onDisappear {
                // Reflect any cancellation/refund made inside the Customer Center.
                Task { await purchases.refreshCustomerInfo() }
            }
    }
}

