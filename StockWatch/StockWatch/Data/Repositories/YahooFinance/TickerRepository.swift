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
        print("<< [TickerRepository] search called - query: '\(query)'")
        let router = YahooFinanceSearchRouter(query: query)
        print("<< [TickerRepository] calling networkService.request - URL: \(router.urlString)")
        do {
            let response = try await networkService.request(router: router, model: YahooFinanceSearchDTO.self)
            print("<< [TickerRepository] networkService.request succeeded - quotes count: \(response.quotes.count)")
            return response.quotes.map(YahooFinanceSearchResultMapper.map)
        } catch {
            print("<< [TickerRepository] networkService.request failed - error: \(error)")
            throw error
        }
    }
}
