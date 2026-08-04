import Foundation

enum Money {
    static func saved(quit: Quit, at date: Date = .now) -> Decimal {
        let days = date.timeIntervalSince(quit.startDate) / 86400
        guard days > 0 else { return 0 }
        return quit.costPerDay * Decimal(days)
    }

    /// Static approximate rates so currency cycling works offline. Not for financial precision.
    static let approximateRatesToUSD: [String: Double] = [
        "USD": 1.0, "EUR": 0.92, "GBP": 0.79, "JPY": 149.5,
        "CAD": 1.36, "AUD": 1.51, "CHF": 0.88, "CNY": 7.24,
    ]

    static func convert(_ amount: Decimal, from: String, to: String) -> Decimal {
        guard from != to,
              let fromRate = approximateRatesToUSD[from],
              let toRate = approximateRatesToUSD[to] else { return amount }
        let usd = (amount as NSDecimalNumber).doubleValue / fromRate
        return Decimal(usd * toRate)
    }

    static func format(_ amount: Decimal, currencyCode: String) -> String {
        amount.formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
    }

    static let cyclableCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY"]

    static func next(after code: String) -> String {
        guard let idx = cyclableCurrencies.firstIndex(of: code) else { return cyclableCurrencies[0] }
        return cyclableCurrencies[(idx + 1) % cyclableCurrencies.count]
    }
}
