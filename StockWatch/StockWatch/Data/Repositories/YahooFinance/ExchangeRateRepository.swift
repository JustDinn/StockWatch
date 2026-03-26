//
//  ExchangeRateRepository.swift
//  StockWatch
//

import Foundation

/// 환율 도메인 Repository 구현체
/// Yahoo Finance API를 통해 USD 기준 환율을 조회한다.
final class ExchangeRateRepository: ExchangeRateRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func fetchRates(currencies: [String]) async throws -> [String: Double] {
        try await withThrowingTaskGroup(of: (String, Double).self) { group in
            for currency in currencies {
                group.addTask {
                    let dto = try await self.networkService.request(
                        router: YahooFinanceExchangeRateRouter(currency: currency),
                        model: YahooFinanceQuoteDTO.self
                    )
                    let rate = YahooFinanceExchangeRateMapper.map(currency: currency, dto: dto)
                    return (currency, rate)
                }
            }

            var rates: [String: Double] = [:]
            for try await (currency, rate) in group {
                rates[currency] = rate
            }
            return rates
        }
    }
}
