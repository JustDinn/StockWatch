//
//  RegisterAlertUseCase.swift
//  StockWatch
//

/// 알림 등록/해제 UseCase 구현체
final class RegisterAlertUseCase: RegisterAlertUseCaseProtocol {

    private let repository: AlertRegistrationRepositoryProtocol

    init(repository: AlertRegistrationRepositoryProtocol) {
        self.repository = repository
    }

    func register(condition: StockCondition, fcmToken: String) async throws {
        try await repository.register(condition: condition, fcmToken: fcmToken)
    }

    func unregister(conditionId: String) async throws {
        try await repository.unregister(conditionId: conditionId)
    }
}
