//
//  FetchExchangeRateUseCase.swift
//  StockWatch
//

/// 환율 조회 UseCase 구현체
/// USD는 항상 1.0으로 포함하고, 나머지 통화는 Repository를 통해 조회한다.
final class FetchExchangeRateUseCase: FetchExchangeRateUseCaseProtocol {

    private let repository: ExchangeRateRepositoryProtocol

    init(repository: ExchangeRateRepositoryProtocol) {
        self.repository = repository
    }

    func execute(currencies: [String]) async throws -> [String: Double] {
        let nonUSD = currencies.filter { $0 != "USD" }
        var rates: [String: Double] = ["USD": 1.0]
        if !nonUSD.isEmpty {
            let fetched = try await repository.fetchRates(currencies: nonUSD)
            rates.merge(fetched) { _, new in new }
        }
        return rates
    }
}
