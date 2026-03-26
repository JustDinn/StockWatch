//
//  ExchangeRateRepositoryProtocol.swift
//  StockWatch
//

/// 환율 도메인 Repository 인터페이스
/// Data 레이어에서 구현하며, Domain/Presentation은 이 Protocol에만 의존한다.
protocol ExchangeRateRepositoryProtocol {
    /// 주어진 통화 목록에 대해 USD 기준 환율을 조회한다.
    /// - Parameter currencies: 통화 코드 배열 (예: ["KRW", "JPY"])
    /// - Returns: [통화코드: 1 USD 대비 환율] (예: ["KRW": 1380.0, "JPY": 155.0])
    func fetchRates(currencies: [String]) async throws -> [String: Double]
}
