//
//  StrategyStore.swift
//  StockWatch
//

import SwiftUI

/// Strategy 카탈로그 화면 Store
@MainActor
final class StrategyStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: StrategyState
    private let fetchStrategiesUseCase: FetchStrategiesUseCaseProtocol
    private let fetchSavedStrategyIdsUseCase: FetchSavedStrategyIdsUseCaseProtocol

    // MARK: - Init

    init(
        fetchStrategiesUseCase: FetchStrategiesUseCaseProtocol,
        fetchSavedStrategyIdsUseCase: FetchSavedStrategyIdsUseCaseProtocol,
        state: StrategyState = StrategyState()
    ) {
        self.fetchStrategiesUseCase = fetchStrategiesUseCase
        self.fetchSavedStrategyIdsUseCase = fetchSavedStrategyIdsUseCase
        self.state = state
    }

    // MARK: - Action

    func action(_ intent: StrategyIntent) {
        switch intent {
        case .loadStrategies:
            loadStrategies()
        case .selectSegment(let segment):
            state.selectedSegment = segment
        case .selectStrategy(let strategy):
            state.selectedStrategy = strategy
        }
    }

    // MARK: - Navigation Binding

    var selectedStrategyBinding: Binding<Strategy?> {
        Binding(
            get: { self.state.selectedStrategy },
            set: { self.state.selectedStrategy = $0 }
        )
    }
}

// MARK: - Private

extension StrategyStore {

    private func loadStrategies() {
        state.isLoading = true

        Task {
            async let strategies = fetchStrategiesUseCase.execute()
            async let savedIds = fetchSavedStrategyIdsUseCase.execute()

            state.allStrategies = await strategies
            state.savedStrategyIds = Set(await savedIds)
            state.isLoading = false
        }
    }
}
