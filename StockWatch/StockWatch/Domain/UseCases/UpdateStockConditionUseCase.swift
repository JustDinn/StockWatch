//
//  UpdateStockConditionUseCase.swift
//  StockWatch
//

/// 종목 전략 조건 업데이트 UseCase 구현체
final class UpdateStockConditionUseCase: UpdateStockConditionUseCaseProtocol {

    private let repository: StockConditionRepositoryProtocol

    init(repository: StockConditionRepositoryProtocol) {
        self.repository = repository
    }

    func execute(condition: StockCondition) async throws {
        try await repository.update(condition)
    }
}
