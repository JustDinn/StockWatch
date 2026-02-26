//
//  SearchRepositoryProtocol.swift
//  StockWatch
//

/// Ticker 도메인 Repository 인터페이스
/// Data 레이어에서 구현하며, Domain/Presentation은 이 Protocol에만 의존한다.
protocol TickerRepositoryProtocol {
    func search(query: String) async throws -> [SearchResult]
}
