//
//  CheckSavedStrategyUseCaseProtocol.swift
//  StockWatch
//

/// 전략 저장 여부 확인 UseCase 인터페이스
protocol CheckSavedStrategyUseCaseProtocol {
    /// 특정 전략이 저장되어 있는지 반환한다.
    func execute(strategyId: String) async -> Bool
}
