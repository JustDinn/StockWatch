//
//  MyAlertsView.swift
//  StockWatch
//

import SwiftUI
import SwiftData

/// 내 알림 화면 진입점 — 등록된 전략 조건 목록
struct MyAlertsView: View {

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        MyAlertsContentView(store: makeStore())
    }

    private func makeStore() -> MyAlertsStore {
        let conditionRepository = StockConditionRepository(modelContext: modelContext)
        let alertRepository = AlertRegistrationRepository()
        return MyAlertsStore(
            fetchStockConditionsUseCase: FetchStockConditionsUseCase(
                repository: conditionRepository
            ),
            deleteStockConditionUseCase: DeleteStockConditionUseCase(
                repository: conditionRepository,
                alertRepository: alertRepository
            ),
            toggleAlertUseCase: ToggleAlertUseCase(
                conditionRepository: conditionRepository,
                alertRepository: alertRepository
            ),
            fcmTokenProvider: { FCMTokenManager.shared.currentToken }
        )
    }
}

// MARK: - Content View

private struct MyAlertsContentView: View {

    @StateObject var store: MyAlertsStore

    var body: some View {
        NavigationStack {
            Group {
                if store.state.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.state.conditions.isEmpty {
                    emptyView
                } else {
                    conditionList
                }
            }
            .navigationTitle("내 알림")
            .task {
                store.action(.loadConditions)
            }
            .alert("알림 삭제", isPresented: Binding(
                get: { store.state.conditionToDelete != nil },
                set: { if !$0 { store.action(.cancelDeleteCondition) } }
            )) {
                Button("취소", role: .cancel) {
                    store.action(.cancelDeleteCondition)
                }
                Button("삭제", role: .destructive) {
                    store.action(.confirmDeleteCondition)
                }
            } message: {
                Text("이 알림을 삭제하시겠습니까?")
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("등록된 알림이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("종목 상세 화면에서\n전략을 적용하고 알림을 등록해보세요")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var conditionList: some View {
        List {
            ForEach(store.state.conditions) { condition in
                conditionRow(condition)
            }
        }
    }

    private func conditionRow(_ condition: StockCondition) -> some View {
        HStack(spacing: 12) {
            // 전략 뱃지
            Text(strategyShortName(condition.strategyId))
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(condition.ticker)
                    .font(.headline)

                Text(parametersDescription(condition.parameters))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 알림 토글
            Toggle("", isOn: Binding(
                get: { condition.isNotificationEnabled },
                set: { _ in store.action(.toggleNotification(condition: condition)) }
            ))
            .labelsHidden()

            Button {
                store.action(.requestDeleteCondition(id: condition.id))
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func strategyShortName(_ strategyId: String) -> String {
        switch strategyId {
        case "sma_cross": return "SMA"
        case "ema_cross": return "EMA"
        case "rsi": return "RSI"
        default: return strategyId.uppercased()
        }
    }

    private func parametersDescription(_ parameters: StrategyParameters) -> String {
        switch parameters {
        case let .sma(shortPeriod, longPeriod):
            return "단기 \(shortPeriod)일 / 장기 \(longPeriod)일"
        case let .ema(shortPeriod, longPeriod):
            return "단기 \(shortPeriod)일 / 장기 \(longPeriod)일"
        case let .rsi(period, oversoldThreshold, overboughtThreshold):
            return "기간 \(period)일 / 과매도 \(Int(oversoldThreshold)) / 과매수 \(Int(overboughtThreshold))"
        }
    }
}
