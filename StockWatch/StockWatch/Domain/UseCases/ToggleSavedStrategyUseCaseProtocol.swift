//
//  ToggleSavedStrategyUseCaseProtocol.swift
//  StockWatch
//

/// 전략 저장 토글 UseCase 인터페이스
protocol ToggleSavedStrategyUseCaseProtocol {
    /// 현재 저장 상태에 따라 전략을 저장하거나 삭제한다.
    /// - Returns: 토글 후 새로운 isSaved 상태 (true = 저장됨, false = 삭제됨)
    func execute(strategyId: String) async throws -> Bool
}
