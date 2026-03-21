//
//  StockQuoteRepository.swift
//  StockWatch
//

import Foundation

/// StockQuote 도메인 Repository 구현체
/// Yahoo Finance Quote API만 호출하여 현재가/등락률을 반환한다 (Finnhub 미사용)
final class StockQuoteRepository: StockQuoteRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func fetchStockQuote(ticker: String) async throws -> StockQuote {
        let quote = try await networkService.request(
            router: YahooFinanceQuoteRouter(symbol: ticker),
            model: YahooFinanceQuoteDTO.self
        )
        return YahooFinanceStockQuoteMapper.map(ticker: ticker, quote: quote)
    }
}
