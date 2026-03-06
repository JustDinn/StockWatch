//
//  MyAlertsStore.swift
//  StockWatch
//

import Foundation

/// MyAlerts 화면 Store
@MainActor
final class MyAlertsStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: MyAlertsState
    private let fetchStockConditionsUseCase: FetchStockConditionsUseCaseProtocol
    private let deleteStockConditionUseCase: DeleteStockConditionUseCaseProtocol
    private let toggleAlertUseCase: ToggleAlertUseCaseProtocol
    private let fcmTokenProvider: () -> String

    // MARK: - Init

    init(
        fetchStockConditionsUseCase: FetchStockConditionsUseCaseProtocol,
        deleteStockConditionUseCase: DeleteStockConditionUseCaseProtocol,
        toggleAlertUseCase: ToggleAlertUseCaseProtocol,
        fcmTokenProvider: @escaping () -> String = { "" }
    ) {
        self.state = MyAlertsState()
        self.fetchStockConditionsUseCase = fetchStockConditionsUseCase
        self.deleteStockConditionUseCase = deleteStockConditionUseCase
        self.toggleAlertUseCase = toggleAlertUseCase
        self.fcmTokenProvider = fcmTokenProvider
    }

    // MARK: - Action

    func action(_ intent: MyAlertsIntent) {
        switch intent {
        case .loadConditions:
            loadConditions()
        case .requestDeleteCondition(let id):
            requestDeleteCondition(id: id)
        case .confirmDeleteCondition:
            confirmDeleteCondition()
        case .cancelDeleteCondition:
            cancelDeleteCondition()
        case .toggleNotification(let condition):
            toggleNotification(condition: condition)
        }
    }
}

// MARK: - Private

extension MyAlertsStore {

    private func loadConditions() {
        state.isLoading = true
        Task {
            state.conditions = await fetchStockConditionsUseCase.executeAll()
            state.isLoading = false
        }
    }

    private func requestDeleteCondition(id: String) {
        state.conditionToDelete = id
    }

    private func confirmDeleteCondition() {
        guard let id = state.conditionToDelete else { return }
        state.conditionToDelete = nil

        Task {
            do {
                try await deleteStockConditionUseCase.execute(id: id)
                state.conditions.removeAll { $0.id == id }
            } catch {
                state.errorMessage = "삭제 중 오류가 발생했습니다: \(error.localizedDescription)"
            }
        }
    }

    private func cancelDeleteCondition() {
        state.conditionToDelete = nil
    }

    private func toggleNotification(condition: StockCondition) {
        let previousConditions = state.conditions
        // 낙관적 업데이트
        if let index = state.conditions.firstIndex(where: { $0.id == condition.id }) {
            state.conditions[index] = StockCondition(
                id: condition.id,
                ticker: condition.ticker,
                strategyId: condition.strategyId,
                parameters: condition.parameters,
                isNotificationEnabled: !condition.isNotificationEnabled,
                isActive: condition.isActive,
                createdAt: condition.createdAt
            )
        }

        Task {
            do {
                let fcmToken = fcmTokenProvider()
                _ = try await toggleAlertUseCase.execute(condition: condition, fcmToken: fcmToken)
            } catch {
                // 실패 시 롤백
                state.conditions = previousConditions
                state.errorMessage = "알림 설정 변경 중 오류가 발생했습니다: \(error.localizedDescription)"
            }
        }
    }
}
