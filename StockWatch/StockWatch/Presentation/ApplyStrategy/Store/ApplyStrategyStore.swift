//
//  ApplyStrategyStore.swift
//  StockWatch
//

import Foundation

/// ApplyStrategy 화면 Store
@MainActor
final class ApplyStrategyStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: ApplyStrategyState
    private let fetchStrategiesUseCase: FetchStrategiesUseCaseProtocol
    private let evaluateStrategyUseCase: EvaluateStrategyUseCaseProtocol
    private let saveStockConditionUseCase: SaveStockConditionUseCaseProtocol
    private let registerAlertUseCase: RegisterAlertUseCaseProtocol
    private let fcmTokenProvider: () -> String

    // MARK: - Init

    init(
        ticker: String,
        fetchStrategiesUseCase: FetchStrategiesUseCaseProtocol,
        evaluateStrategyUseCase: EvaluateStrategyUseCaseProtocol,
        saveStockConditionUseCase: SaveStockConditionUseCaseProtocol,
        registerAlertUseCase: RegisterAlertUseCaseProtocol,
        fcmTokenProvider: @escaping () -> String = { "" }
    ) {
        self.state = ApplyStrategyState(ticker: ticker)
        self.fetchStrategiesUseCase = fetchStrategiesUseCase
        self.evaluateStrategyUseCase = evaluateStrategyUseCase
        self.saveStockConditionUseCase = saveStockConditionUseCase
        self.registerAlertUseCase = registerAlertUseCase
        self.fcmTokenProvider = fcmTokenProvider
        observeFCMToken()
    }

    // MARK: - Action

    func action(_ intent: ApplyStrategyIntent) {
        switch intent {
        case .loadStrategies:
            loadStrategies()
        case .selectStrategy(let strategy):
            selectStrategy(strategy)
        case .updateShortPeriod(let value):
            state.shortPeriod = value
            state.signal = nil
        case .updateLongPeriod(let value):
            state.longPeriod = value
            state.signal = nil
        case .updateRSIPeriod(let value):
            state.rsiPeriod = value
            state.signal = nil
        case .updateOversoldThreshold(let value):
            state.oversoldThreshold = value
            state.signal = nil
        case .updateOverboughtThreshold(let value):
            state.overboughtThreshold = value
            state.signal = nil
        case .evaluate:
            evaluate()
        case .toggleNotification:
            state.isNotificationEnabled.toggle()
        case .updateNotificationTime(let date):
            state.notificationTime = date
        case .saveCondition:
            saveCondition()
        case .deselectStrategy:
            state.selectedStrategy = nil
            state.signal = nil
            state.isSaved = false
        }
    }
}

// MARK: - Private

extension ApplyStrategyStore {

    private func observeFCMToken() {
        Task {
            for await token in FCMTokenManager.shared.$currentToken.values {
                state.isFCMTokenReady = !token.isEmpty
            }
        }
    }

    private func loadStrategies() {
        state.isLoading = true
        Task {
            state.strategies = await fetchStrategiesUseCase.execute()
            state.isLoading = false
        }
    }

    private func selectStrategy(_ strategy: Strategy) {
        state.selectedStrategy = strategy
        state.signal = nil
        // 전략 선택 시 기본 파라미터로 초기화
        if let defaults = StrategyParameters.defaultParameters(for: strategy.id) {
            switch defaults {
            case let .sma(shortPeriod, longPeriod):
                state.shortPeriod = shortPeriod
                state.longPeriod = longPeriod
            case let .ema(shortPeriod, longPeriod):
                state.shortPeriod = shortPeriod
                state.longPeriod = longPeriod
            case let .rsi(period, oversoldThreshold, overboughtThreshold):
                state.rsiPeriod = period
                state.oversoldThreshold = oversoldThreshold
                state.overboughtThreshold = overboughtThreshold
            }
        }
    }

    private func evaluate() {
        guard let parameters = state.currentParameters else { return }
        state.isEvaluating = true
        state.errorMessage = nil

        Task {
            do {
                let signal = try await evaluateStrategyUseCase.execute(
                    ticker: state.ticker,
                    parameters: parameters
                )
                state.signal = signal
            } catch {
                state.errorMessage = "평가 중 오류가 발생했습니다: \(error.localizedDescription)"
            }
            state.isEvaluating = false
        }
    }

    private func saveCondition() {
        guard let parameters = state.currentParameters else { return }
        state.isLoading = true
        state.errorMessage = nil

        let condition = StockCondition(
            id: UUID().uuidString,
            ticker: state.ticker,
            strategyId: parameters.strategyId,
            parameters: parameters,
            isNotificationEnabled: state.isNotificationEnabled,
            notificationTime: state.notificationTime,
            isActive: true,
            createdAt: Date()
        )

        Task {
            do {
                try await saveStockConditionUseCase.execute(condition: condition)

                if state.isNotificationEnabled {
                    let fcmToken = fcmTokenProvider()
                    if !fcmToken.isEmpty {
                        try await registerAlertUseCase.register(condition: condition, fcmToken: fcmToken)
                    }
                }

                state.isSaved = true
            } catch {
                state.errorMessage = "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
            }
            state.isLoading = false
        }
    }
}
