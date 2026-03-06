//
//  CheckSavedStrategyUseCase.swift
//  StockWatch
//

/// 전략 저장 여부 확인 UseCase 구현체
final class CheckSavedStrategyUseCase: CheckSavedStrategyUseCaseProtocol {

    private let repository: SavedStrategyRepositoryProtocol

    init(repository: SavedStrategyRepositoryProtocol) {
        self.repository = repository
    }

    func execute(strategyId: String) async -> Bool {
        await repository.isSaved(strategyId: strategyId)
    }
}
