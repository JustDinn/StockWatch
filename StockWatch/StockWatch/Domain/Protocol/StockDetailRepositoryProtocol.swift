//
//  StockDetailRepositoryProtocol.swift
//  StockWatch
//

/// StockDetail 도메인 Repository 인터페이스
/// Data 레이어에서 구현하며, Domain/Presentation은 이 Protocol에만 의존한다.
protocol StockDetailRepositoryProtocol {
    func fetchStockDetail(ticker: String) async throws -> StockDetail
}
