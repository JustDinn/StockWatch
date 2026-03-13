//
//  SearchTickerUseCaseProtocol.swift
//  StockWatch
//

/// Ticker 도메인 UseCase 인터페이스
protocol TickerUseCaseProtocol {
    func search(query: String) async throws -> [SearchResult]
}
