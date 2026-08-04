import StoreKit
import Observation

@Observable
final class Store {
    static let themesProductID = "com.hudsonpaine.Queet.themes"

    private(set) var isProUnlocked = false
    private(set) var themesProduct: Product?
    private(set) var isLoading = false
    private(set) var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await load() }
    }

    deinit {
        updatesTask?.cancel()
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            themesProduct = try await Product.products(for: [Store.themesProductID]).first
        } catch {
            themesProduct = nil
        }
        await refreshEntitlements()
    }

    @MainActor
    func purchaseThemes() async {
        guard let product = themesProduct else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result {
                await handle(verification)
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    func restore() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    @MainActor
    private func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            await handle(result)
        }
    }

    @MainActor
    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Store.themesProductID {
            isProUnlocked = true
        }
        await transaction.finish()
    }
}
