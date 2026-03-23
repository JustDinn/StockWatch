//
//  CompositeTickerRepository.swift
//  StockWatch
//

/// 한국어 쿼리는 로컬 딕셔너리에서, 그 외는 Yahoo Finance API에서 검색하는 복합 Repository.
final class CompositeTickerRepository: TickerRepositoryProtocol {
    private let yahooRepository: TickerRepositoryProtocol
    private let koreanSearchService: KoreanStockSearchService

    init(
        yahooRepository: TickerRepositoryProtocol = TickerRepository(),
        koreanSearchService: KoreanStockSearchService = KoreanStockSearchService()
    ) {
        self.yahooRepository = yahooRepository
        self.koreanSearchService = koreanSearchService
    }

    func search(query: String) async throws -> [SearchResult] {
        print("<< [CompositeTickerRepository] search called - query: '\(query)', containsKorean: \(query.containsKorean)")
        if query.containsKorean {
            let localResults = koreanSearchService.search(query: query).map(KoreanStockSearchResultMapper.map)
            print("<< [CompositeTickerRepository] Korean query - localResults count: \(localResults.count)")
            if !localResults.isEmpty {
                print("<< [CompositeTickerRepository] returning localResults")
                return localResults
            }
            print("<< [CompositeTickerRepository] no local results, falling back to Yahoo (errors suppressed)")
            // 한국어 쿼리로 Yahoo 검색 실패 시(예: 400 Bad Request) 에러 대신 빈 배열 반환
            return (try? await yahooRepository.search(query: query)) ?? []
        }
        print("<< [CompositeTickerRepository] non-Korean query, calling yahooRepository.search")
        return try await yahooRepository.search(query: query)
    }
}
