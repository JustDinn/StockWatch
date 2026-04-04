//
//  CandlestickRepository.swift
//  StockWatch
//

import Foundation

final class CandlestickRepository: CandlestickRepositoryProtocol {

    private let networkService: NetworkServiceProtocol
    private let mapper: YahooFinanceCandlestickMapper

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        mapper: YahooFinanceCandlestickMapper = YahooFinanceCandlestickMapper()
    ) {
        self.networkService = networkService
        self.mapper = mapper
    }

    func fetchCandlesticks(ticker: String, period: ChartPeriod) async throws -> CandlestickData {
        let dto = try await networkService.request(
            router: YahooFinanceCandlestickRouter(symbol: ticker, range: period.range, interval: period.interval),
            model: YahooFinanceCandlestickDTO.self
        )
        return mapper.map(dto: dto, ticker: ticker, interval: period.interval)
    }

    func fetchCandlesticks(ticker: String, interval: String, period1: Int, period2: Int) async throws -> CandlestickData {
        let dto = try await networkService.request(
            router: YahooFinanceCandlestickPaginatedRouter(symbol: ticker, interval: interval, period1: period1, period2: period2),
            model: YahooFinanceCandlestickDTO.self
        )
        return mapper.map(dto: dto, ticker: ticker, interval: interval)
    }

    func fetchCandlesticks(ticker: String, range: String, interval: String) async throws -> CandlestickData {
        let dto = try await networkService.request(
            router: YahooFinanceCandlestickRouter(symbol: ticker, range: range, interval: interval),
            model: YahooFinanceCandlestickDTO.self
        )
        return mapper.map(dto: dto, ticker: ticker, interval: interval)
    }
}
