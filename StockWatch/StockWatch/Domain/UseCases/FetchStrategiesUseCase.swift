//
//  FetchStrategiesUseCase.swift
//  StockWatch
//

/// 전체 전략 목록 조회 UseCase 구현체
final class FetchStrategiesUseCase: FetchStrategiesUseCaseProtocol {

    private let repository: StrategyRepositoryProtocol

    init(repository: StrategyRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async -> [Strategy] {
        await repository.fetchAllStrategies()
    }
}
