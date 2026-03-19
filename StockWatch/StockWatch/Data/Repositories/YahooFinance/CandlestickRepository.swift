//
//  CandlestickRepository.swift
//  StockWatch
//

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
        return mapper.map(dto: dto, ticker: ticker)
    }

    func fetchCandlesticks(ticker: String, interval: String, period1: Int, period2: Int) async throws -> CandlestickData {
        let dto = try await networkService.request(
            router: YahooFinanceCandlestickPaginatedRouter(symbol: ticker, interval: interval, period1: period1, period2: period2),
            model: YahooFinanceCandlestickDTO.self
        )
        return mapper.map(dto: dto, ticker: ticker)
    }
}
