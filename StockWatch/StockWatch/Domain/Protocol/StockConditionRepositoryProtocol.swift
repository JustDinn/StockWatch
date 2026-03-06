//
//  StockConditionRepositoryProtocol.swift
//  StockWatch
//

/// 로컬 저장소 인터페이스 (SwiftData 기반)
/// 구현체는 Data 레이어에 위치하며, Domain은 이 Protocol에만 의존한다.
protocol StockConditionRepositoryProtocol {
    /// 전체 조건 목록을 조회한다.
    func fetchAll() async -> [StockCondition]
    /// 특정 종목의 조건 목록을 조회한다.
    func fetch(ticker: String) async -> [StockCondition]
    /// 조건을 저장한다.
    func save(_ condition: StockCondition) async throws
    /// 조건을 업데이트한다.
    func update(_ condition: StockCondition) async throws
    /// 조건을 삭제한다.
    func delete(id: String) async throws
}
