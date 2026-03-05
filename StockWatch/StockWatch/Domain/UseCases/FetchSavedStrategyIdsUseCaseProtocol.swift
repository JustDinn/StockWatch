//
//  FetchSavedStrategyIdsUseCaseProtocol.swift
//  StockWatch
//

/// 저장된 전략 ID 목록 조회 UseCase 인터페이스
protocol FetchSavedStrategyIdsUseCaseProtocol {
    /// 저장된 모든 전략의 ID를 반환한다.
    func execute() async -> [String]
}
