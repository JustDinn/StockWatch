//
//  FetchStockConditionsUseCaseProtocol.swift
//  StockWatch
//

/// 종목 전략 조건 조회 UseCase 인터페이스
protocol FetchStockConditionsUseCaseProtocol {
    /// 전체 조건 목록을 반환한다.
    func executeAll() async -> [StockCondition]
    /// 특정 종목의 조건 목록을 반환한다.
    func execute(ticker: String) async -> [StockCondition]
}
