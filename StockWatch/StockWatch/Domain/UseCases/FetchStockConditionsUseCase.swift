//
//  FetchStockConditionsUseCase.swift
//  StockWatch
//

/// 종목 전략 조건 조회 UseCase 구현체
final class FetchStockConditionsUseCase: FetchStockConditionsUseCaseProtocol {

    private let repository: StockConditionRepositoryProtocol

    init(repository: StockConditionRepositoryProtocol) {
        self.repository = repository
    }

    func executeAll() async -> [StockCondition] {
        await repository.fetchAll()
    }

    func execute(ticker: String) async -> [StockCondition] {
        await repository.fetch(ticker: ticker)
    }
}
