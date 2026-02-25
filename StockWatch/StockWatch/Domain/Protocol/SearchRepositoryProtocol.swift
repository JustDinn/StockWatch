//
//  SearchRepositoryProtocol.swift
//  StockWatch
//

/// 종목 검색 Repository 인터페이스
/// Data 레이어에서 구현하며, Domain/Presentation은 이 Protocol에만 의존한다.
protocol SearchRepositoryProtocol {
    func search(query: String) async throws -> [SearchResult]
}
