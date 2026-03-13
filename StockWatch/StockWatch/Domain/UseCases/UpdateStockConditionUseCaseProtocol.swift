//
//  UpdateStockConditionUseCaseProtocol.swift
//  StockWatch
//

/// 종목 전략 조건 업데이트 UseCase 인터페이스
protocol UpdateStockConditionUseCaseProtocol {
    /// 기존 조건을 업데이트한다.
    func execute(condition: StockCondition) async throws
}
