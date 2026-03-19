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

    func fetchCandlesticks(ticker: String) async throws -> CandlestickData {
        let dto = try await networkService.request(
            router: YahooFinanceCandlestickRouter(symbol: ticker),
            model: YahooFinanceCandlestickDTO.self
        )
        return mapper.map(dto: dto, ticker: ticker)
    }
}
