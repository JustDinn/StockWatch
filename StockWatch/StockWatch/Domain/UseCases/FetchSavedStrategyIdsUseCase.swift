//
//  FetchSavedStrategyIdsUseCase.swift
//  StockWatch
//

/// 저장된 전략 ID 목록 조회 UseCase 구현체
final class FetchSavedStrategyIdsUseCase: FetchSavedStrategyIdsUseCaseProtocol {

    private let repository: SavedStrategyRepositoryProtocol

    init(repository: SavedStrategyRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async -> [String] {
        await repository.fetchAllSavedIds()
    }
}
