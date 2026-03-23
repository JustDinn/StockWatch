//
//  FetchStockQuoteUseCaseProtocol.swift
//  StockWatch
//

/// StockQuote 도메인 UseCase 인터페이스
protocol FetchStockQuoteUseCaseProtocol {
    func execute(ticker: String) async throws -> StockQuote
}
