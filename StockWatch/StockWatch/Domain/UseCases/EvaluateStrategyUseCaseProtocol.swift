//
//  EvaluateStrategyUseCaseProtocol.swift
//  StockWatch
//

/// 전략 즉시 평가 UseCase 인터페이스
protocol EvaluateStrategyUseCaseProtocol {
    /// 현재 시점에서 전략 조건 충족 여부를 평가하고 신호를 반환한다.
    func execute(ticker: String, parameters: StrategyParameters) async throws -> StrategySignal
}
