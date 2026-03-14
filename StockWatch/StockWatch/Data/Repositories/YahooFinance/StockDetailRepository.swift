//
//  StockDetailRepository.swift
//  StockWatch
//

import Foundation

/// StockDetail 도메인 Repository 구현체
/// /quote + /stock/profile2 를 async let으로 병렬 호출하여 StockDetail 엔티티 반환
final class StockDetailRepository: StockDetailRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let apiKey: String

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        apiKey: String = Bundle.main.infoDictionary?["FINNHUB_API_KEY"] as? String ?? ""
    ) {
        self.networkService = networkService
        self.apiKey = apiKey
    }

    func fetchStockDetail(ticker: String) async throws -> StockDetail {
        async let quoteResponse = networkService.request(
            router: YahooFinanceQuoteRouter(symbol: ticker),
            model: YahooFinanceQuoteDTO.self
        )
        async let profileResponse = networkService.request(
            router: FinnhubStockProfileRouter(symbol: ticker, apiKey: apiKey),
            model: StockProfileDTO.self
        )

        let quote = try await quoteResponse
        let logoURL = (try? await profileResponse)?.logo ?? ""
        return YahooFinanceStockDetailMapper.map(ticker: ticker, quote: quote, logoURL: logoURL)
    }
}
