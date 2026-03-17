//
//  TickerRepository.swift
//  StockWatch
//

final class TickerRepository: TickerRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func search(query: String) async throws -> [SearchResult] {
        let router = YahooFinanceSearchRouter(query: query)
        let response = try await networkService.request(router: router, model: YahooFinanceSearchDTO.self)
        return response.quotes.map(YahooFinanceSearchResultMapper.map)
    }
}
