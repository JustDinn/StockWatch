//
//  SearchTickerUseCaseProtocol.swift
//  StockWatch
//

/// 종목 검색 UseCase 인터페이스
protocol SearchTickerUseCaseProtocol {
    func execute(query: String) async throws -> [SearchResult]
}
