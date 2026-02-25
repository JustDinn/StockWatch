//
//  SearchRepository.swift
//  StockWatch
//

import Foundation

/// 종목 검색 Repository 구현체
/// NetworkService를 통해 Finnhub API를 호출하고, DTO를 Entity로 변환하여 반환한다.
final class SearchRepository: SearchRepositoryProtocol {

    private let networkService: NetworkServiceProtocol
    private let apiKey: String
    
    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        apiKey: String = Bundle.main.infoDictionary?["FINNHUB_API_KEY"] as? String ?? ""
    ) {
        self.networkService = networkService
        self.apiKey = apiKey
    }
    
    func search(query: String) async throws -> [SearchResult] {
        let router = FinnhubSearchRouter(query: query, apiKey: apiKey)
        let response = try await networkService.request(router: router, model: TickerSearchResponseDTO.self)
        return response.result.map(SearchResultMapper.map)
    }
}
