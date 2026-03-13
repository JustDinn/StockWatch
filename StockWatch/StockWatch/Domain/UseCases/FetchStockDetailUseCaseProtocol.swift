//
//  FetchStockDetailUseCaseProtocol.swift
//  StockWatch
//

/// StockDetail 도메인 UseCase 인터페이스
protocol FetchStockDetailUseCaseProtocol {
    func execute(ticker: String) async throws -> StockDetail
}
