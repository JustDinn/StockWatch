//
//  SavedStrategyRepositoryProtocol.swift
//  StockWatch
//

/// 저장된 전략 저장소 인터페이스
/// 구현체는 Data 레이어에 위치하며, Domain은 이 Protocol에만 의존한다.
protocol SavedStrategyRepositoryProtocol {
    /// 특정 전략이 저장되어 있는지 확인한다.
    func isSaved(strategyId: String) async -> Bool
    /// 전략을 저장한다.
    func save(strategyId: String) async throws
    /// 저장된 전략을 삭제한다.
    func remove(strategyId: String) async throws
    /// 저장된 모든 전략의 ID를 반환한다.
    func fetchAllSavedIds() async -> [String]
}
