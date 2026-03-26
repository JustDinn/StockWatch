//
//  FetchExchangeRateUseCaseProtocol.swift
//  StockWatch
//

/// 환율 조회 UseCase 인터페이스
protocol FetchExchangeRateUseCaseProtocol {
    /// 주어진 통화 목록에 대해 USD 기준 환율을 조회한다.
    /// USD는 자동으로 1.0으로 포함된다.
    func execute(currencies: [String]) async throws -> [String: Double]
}
