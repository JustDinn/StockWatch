//
//  StrategyEvaluationRepositoryProtocol.swift
//  StockWatch
//

/// 전략 평가 저장소 인터페이스
/// 구현체는 Data 레이어에 위치하며, Domain은 이 Protocol에만 의존한다.
protocol StrategyEvaluationRepositoryProtocol {
    /// 주어진 파라미터로 전략을 평가하고 신호를 반환한다.
    func evaluate(ticker: String, parameters: StrategyParameters) async throws -> StrategySignal
}
