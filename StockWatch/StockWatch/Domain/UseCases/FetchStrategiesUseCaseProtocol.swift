//
//  FetchStrategiesUseCaseProtocol.swift
//  StockWatch
//

/// 전체 전략 목록 조회 UseCase 인터페이스
protocol FetchStrategiesUseCaseProtocol {
    /// 전체 전략 목록을 반환한다.
    func execute() async -> [Strategy]
}
