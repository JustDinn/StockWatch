//
//  ToggleSavedStrategyUseCase.swift
//  StockWatch
//

/// 전략 저장 토글 UseCase 구현체
/// 현재 저장 상태를 확인하여 저장 또는 삭제를 수행한다.
final class ToggleSavedStrategyUseCase: ToggleSavedStrategyUseCaseProtocol {

    private let repository: SavedStrategyRepositoryProtocol

    init(repository: SavedStrategyRepositoryProtocol) {
        self.repository = repository
    }

    func execute(strategyId: String) async throws -> Bool {
        let currentlySaved = await repository.isSaved(strategyId: strategyId)

        if currentlySaved {
            try await repository.remove(strategyId: strategyId)
            return false
        } else {
            try await repository.save(strategyId: strategyId)
            return true
        }
    }
}
