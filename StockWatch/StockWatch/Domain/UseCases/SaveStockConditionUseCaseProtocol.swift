//
//  SaveStockConditionUseCaseProtocol.swift
//  StockWatch
//

/// 종목 전략 조건 저장 UseCase 인터페이스
protocol SaveStockConditionUseCaseProtocol {
    /// 조건을 로컬에 저장한다.
    func execute(condition: StockCondition) async throws
}
