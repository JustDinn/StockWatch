//
//  StrategyRepositoryProtocol.swift
//  StockWatch
//

/// 전략 목록 저장소 인터페이스
protocol StrategyRepositoryProtocol {
    /// 전체 전략 목록을 반환한다.
    func fetchAllStrategies() async -> [Strategy]
}
