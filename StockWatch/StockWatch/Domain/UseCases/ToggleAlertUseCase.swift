//
//  ToggleAlertUseCase.swift
//  StockWatch
//

/// 조건의 알림 활성/비활성 토글 UseCase 구현체
/// 현재 상태에 따라 Firestore 등록/해제 및 로컬 상태 업데이트를 수행한다.
final class ToggleAlertUseCase: ToggleAlertUseCaseProtocol {

    private let conditionRepository: StockConditionRepositoryProtocol
    private let alertRepository: AlertRegistrationRepositoryProtocol

    init(
        conditionRepository: StockConditionRepositoryProtocol,
        alertRepository: AlertRegistrationRepositoryProtocol
    ) {
        self.conditionRepository = conditionRepository
        self.alertRepository = alertRepository
    }

    func execute(condition: StockCondition, fcmToken: String) async throws -> Bool {
        let newState = !condition.isNotificationEnabled
        var updated = condition
        updated = StockCondition(
            id: condition.id,
            ticker: condition.ticker,
            companyName: condition.companyName,
            strategyId: condition.strategyId,
            parameters: condition.parameters,
            isNotificationEnabled: newState,
            notificationTime: condition.notificationTime,
            isActive: condition.isActive,
            createdAt: condition.createdAt
        )

        if newState {
            try await alertRepository.register(condition: updated, fcmToken: fcmToken)
        } else {
            try await alertRepository.unregister(conditionId: condition.id)
        }

        try await conditionRepository.update(updated)
        return newState
    }
}
