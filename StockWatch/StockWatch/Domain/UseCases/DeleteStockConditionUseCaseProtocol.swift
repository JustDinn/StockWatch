//
//  DeleteStockConditionUseCaseProtocol.swift
//  StockWatch
//

/// 종목 전략 조건 삭제 UseCase 인터페이스
protocol DeleteStockConditionUseCaseProtocol {
    /// 조건을 로컬에서 삭제한다.
    func execute(id: String) async throws
}
