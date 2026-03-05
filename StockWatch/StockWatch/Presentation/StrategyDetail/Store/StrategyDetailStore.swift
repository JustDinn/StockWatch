//
//  StrategyDetailStore.swift
//  StockWatch
//

import Foundation

/// StrategyDetail 화면 Store
@MainActor
final class StrategyDetailStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: StrategyDetailState
    private let toggleSavedStrategyUseCase: ToggleSavedStrategyUseCaseProtocol
    private let checkSavedStrategyUseCase: CheckSavedStrategyUseCaseProtocol

    // MARK: - Init

    init(
        strategy: Strategy,
        toggleSavedStrategyUseCase: ToggleSavedStrategyUseCaseProtocol,
        checkSavedStrategyUseCase: CheckSavedStrategyUseCaseProtocol
    ) {
        self.state = StrategyDetailState(strategy: strategy)
        self.toggleSavedStrategyUseCase = toggleSavedStrategyUseCase
        self.checkSavedStrategyUseCase = checkSavedStrategyUseCase
    }

    // MARK: - Action

    func action(_ intent: StrategyDetailIntent) {
        switch intent {
        case .loadSavedStatus:
            loadSavedStatus()
        case .toggleSaved:
            persistToggleSaved()
        }
    }
}

// MARK: - Private

extension StrategyDetailStore {

    private func loadSavedStatus() {
        Task {
            state.isSaved = await checkSavedStrategyUseCase.execute(
                strategyId: state.strategy.id
            )
        }
    }

    /// 낙관적 UI 업데이트 후 SwiftData에 영구 저장
    /// 저장 실패 시 원래 상태로 롤백한다.
    private func persistToggleSaved() {
        let previousState = state.isSaved
        state.isSaved.toggle()

        Task {
            do {
                let newState = try await toggleSavedStrategyUseCase.execute(
                    strategyId: state.strategy.id
                )
                state.isSaved = newState
            } catch {
                state.isSaved = previousState
            }
        }
    }
}
