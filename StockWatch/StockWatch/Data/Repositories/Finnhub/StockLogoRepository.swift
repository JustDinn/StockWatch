//
//  StockLogoRepository.swift
//  StockWatch
//

import Foundation

/// Finnhub /stock/profile2를 호출해 기업 로고 URL을 반환하는 Repository 구현체
final class StockLogoRepository: StockLogoRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let apiKey: String

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        apiKey: String = Bundle.main.infoDictionary?["FINNHUB_API_KEY"] as? String ?? ""
    ) {
        self.networkService = networkService
        self.apiKey = apiKey
    }

    func fetchLogoURL(ticker: String) async throws -> String {
        let profile = try await networkService.request(
            router: FinnhubStockProfileRouter(symbol: ticker, apiKey: apiKey),
            model: StockProfileDTO.self
        )
        return profile.logo ?? ""
    }
}
