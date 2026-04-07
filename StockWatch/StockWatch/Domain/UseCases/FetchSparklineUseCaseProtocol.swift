//
//  FetchSparklineUseCaseProtocol.swift
//  StockWatch
//

/// 스파크라인 데이터 조회 UseCase 인터페이스
protocol FetchSparklineUseCaseProtocol {
    func execute(ticker: String) async throws -> SparklineData
}
