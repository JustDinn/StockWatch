//
//  DeleteStockConditionUseCase.swift
//  StockWatch
//

/// 종목 전략 조건 삭제 UseCase 구현체
final class DeleteStockConditionUseCase: DeleteStockConditionUseCaseProtocol {

    private let repository: StockConditionRepositoryProtocol

    init(repository: StockConditionRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: String) async throws {
        try await repository.delete(id: id)
    }
}
