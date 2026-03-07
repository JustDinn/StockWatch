//
//  DeleteStockConditionUseCase.swift
//  StockWatch
//

/// 종목 전략 조건 삭제 UseCase 구현체
final class DeleteStockConditionUseCase: DeleteStockConditionUseCaseProtocol {

    private let repository: StockConditionRepositoryProtocol
    private let alertRepository: AlertRegistrationRepositoryProtocol

    init(
        repository: StockConditionRepositoryProtocol,
        alertRepository: AlertRegistrationRepositoryProtocol
    ) {
        self.repository = repository
        self.alertRepository = alertRepository
    }

    func execute(id: String) async throws {
        try? await alertRepository.unregister(conditionId: id)
        try await repository.delete(id: id)
    }
}
