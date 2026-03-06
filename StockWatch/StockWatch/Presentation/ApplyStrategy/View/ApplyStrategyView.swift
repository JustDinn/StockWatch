//
//  ApplyStrategyView.swift
//  StockWatch
//

import SwiftUI
import SwiftData

/// 전략 적용 화면 진입점 — 전략 선택 리스트
struct ApplyStrategyView: View {

    @Environment(\.modelContext) private var modelContext
    let ticker: String

    var body: some View {
        ApplyStrategyContentView(store: makeStore())
    }

    private func makeStore() -> ApplyStrategyStore {
        let conditionRepository = StockConditionRepository(modelContext: modelContext)
        let alertRepository = AlertRegistrationRepository()
        return ApplyStrategyStore(
            ticker: ticker,
            fetchStrategiesUseCase: FetchStrategiesUseCase(
                repository: StrategyRepository()
            ),
            evaluateStrategyUseCase: EvaluateStrategyUseCase(
                repository: StrategyEvaluationRepository()
            ),
            saveStockConditionUseCase: SaveStockConditionUseCase(
                repository: conditionRepository
            ),
            registerAlertUseCase: RegisterAlertUseCase(
                repository: alertRepository
            ),
            fcmTokenProvider: { FCMTokenManager.shared.currentToken }
        )
    }
}

// MARK: - Content View

private struct ApplyStrategyContentView: View {

    @StateObject var store: ApplyStrategyStore

    var body: some View {
        Group {
            if store.state.isLoading && store.state.strategies.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                strategyListView
            }
        }
        .navigationTitle("\(store.state.ticker) 전략 적용")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.action(.loadStrategies)
        }
        .navigationDestination(item: Binding(
            get: { store.state.selectedStrategy },
            set: { if $0 == nil { store.action(.deselectStrategy) } }
        )) { strategy in
            StrategyConfigView(store: store, strategy: strategy)
        }
    }

    private var strategyListView: some View {
        List(store.state.strategies) { strategy in
            Button {
                store.action(.selectStrategy(strategy))
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(strategy.shortName)
                                .font(.headline)
                                .foregroundStyle(.blue)

                            Text(strategy.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }

                        Text(strategy.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }
}
