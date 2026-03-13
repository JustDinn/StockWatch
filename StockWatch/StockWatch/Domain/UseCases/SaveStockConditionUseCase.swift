//
//  SaveStockConditionUseCase.swift
//  StockWatch
//

/// 종목 전략 조건 저장 UseCase 구현체
final class SaveStockConditionUseCase: SaveStockConditionUseCaseProtocol {

    private let repository: StockConditionRepositoryProtocol

    init(repository: StockConditionRepositoryProtocol) {
        self.repository = repository
    }

    func execute(condition: StockCondition) async throws {
        try await repository.save(condition)
    }
}
